#include "funcs.h"
#include "librecomp/game.hpp"
#include "librecomp/helpers.hpp"
#include "librecomp/overlays.hpp"
#include "librecomp/rsp.hpp"
#include "ultramodern/config.hpp"
#include "ultramodern/ultramodern.hpp"
#include "xxHash/xxh3.h"
#include "zelda_render.h"

#include <algorithm>
#include <atomic>
#include <array>
#include <bit>
#include <chrono>
#include <cmath>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <exception>
#include <filesystem>
#include <fstream>
#include <mutex>
#include <os/log.h>
#include <string>
#include <thread>
#include <vector>

extern RspUcodeFunc aspMain;
gpr get_entrypoint_address();

namespace zelda64 {
void register_overlays();
void register_patches();
}

namespace {
constexpr uint64_t kGoldenEyeTlbFreeHash = 0xd49fb2a8d6d3bd65ULL;
constexpr std::streamsize kGoldenEyeTlbFreeSize = 0xC11460;
const std::u8string kGameID = u8"ge007.us";

std::atomic<bool> runtimeStarted = false;
std::atomic<uint8_t *> activeRdram = nullptr;
constexpr size_t kControllerPorts = 4;
std::array<std::atomic<uint32_t>, kControllerPorts> controllerButtons{};
std::array<std::atomic<int32_t>, kControllerPorts> controllerStickX{};
std::array<std::atomic<int32_t>, kControllerPorts> controllerStickY{};
std::array<std::atomic<int32_t>, kControllerPorts> controllerLookX{};
std::array<std::atomic<int32_t>, kControllerPorts> controllerLookY{};
std::array<std::atomic<uint32_t>, kControllerPorts> controllerLookSamples{};
std::array<std::atomic<uint32_t>, kControllerPorts> controllerButtonTransitions{};
std::array<std::atomic<uint32_t>, kControllerPorts> controllerRumbleTransitions{};
std::array<std::atomic<int32_t>, kControllerPorts> queuedTouchLookX{};
std::array<std::atomic<int32_t>, kControllerPorts> queuedTouchLookY{};
std::array<std::atomic<bool>, kControllerPorts> crouchToggleRequested{};
std::atomic<bool> prototypeMsaaEnabled = true;
std::atomic<int32_t> prototypeResolutionMode = 2;
std::atomic<bool> prototypeThreePointFiltering = true;
std::atomic<bool> invertAimY = false;
std::atomic<bool> unlockAllMissions = false;
std::atomic<bool> returnToTitleRequested = false;
std::atomic<bool> appActive = true;
std::atomic<bool> controllerConnected = false;
std::atomic<bool> twoPlayerTestMode = false;
std::atomic<bool> fourPlayerTestMode = false;
std::atomic<uint64_t> rt64DisplayListCount = 0;
std::atomic<uint64_t> rt64ScreenUpdateCount = 0;
std::atomic<uint64_t> rt64PresentedCount = 0;
std::atomic<uint8_t> controllerPortsReported = 0;
std::atomic<bool> inputPollReported = false;
std::atomic<uint8_t> inputStateReported = 0;
std::atomic<bool> audioCallbackReported = false;
std::atomic<bool> stateProbeStarted = false;
std::atomic<uint8_t> invalidInputPortsReported = 0;
std::atomic<bool> fireRateProbeEnabled = false;
std::atomic<bool> sidestepProbeEnabled = false;
std::atomic<int32_t> gameplayInputModeReported = -1;
std::atomic<uint64_t> fireRateProbeSimulationTicks = 0;
std::atomic<uint32_t> fireRateProbeRawGuardSamples = 0;
std::mutex statusMutex;
std::mutex diagnosticsMutex;
std::string runtimeStatus = "AOT runtime: waiting for imported user ROM";
std::filesystem::path diagnosticsLogPath;
std::filesystem::path diagnosticsSessionMarkerPath;
std::atomic<bool> previousSessionEndedUnexpectedly = false;
constexpr uintmax_t kDiagnosticsLogLimit = 4 * 1024 * 1024;

// Match the working GoldenPad host: the game/audio thread is the sole producer
// and AVAudioEngine is the sole consumer of a bounded stereo PCM ring.
constexpr uint64_t kAudioRingFrames = 65'536;
constexpr uint64_t kAudioPrebufferFrames = 1'024;
constexpr uint32_t kAudioFadeFrames = 32;
std::array<int16_t, kAudioRingFrames * 2> audioRing{};
std::atomic<uint64_t> audioReadFrame = 0;
std::atomic<uint64_t> audioWriteFrame = 0;
std::atomic<uint64_t> audioDroppedFrames = 0;
std::atomic<uint64_t> audioUnderrunFrames = 0;
std::atomic<uint64_t> audioUnderrunCallbacks = 0;
std::atomic<uint64_t> audioRenderedFrames = 0;
std::atomic<uint64_t> audioNonzeroSamples = 0;
// These fields are used only by AVAudioEngine's single render thread.
bool audioPlaybackPrimed = false;
uint32_t audioFadeInFramesRemaining = 0;
float audioLastLeft = 0.0f;
float audioLastRight = 0.0f;

void logEvent(const char *event, const char *format, ...) {
    char detail[768];
    va_list arguments;
    va_start(arguments, format);
    std::vsnprintf(detail, sizeof(detail), format, arguments);
    va_end(arguments);
    char line[896];
    std::snprintf(line, sizeof(line), "[GoldenPadRecomp] %s: %s", event, detail);
    std::fprintf(stderr, "%s\n", line);
    os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEFAULT, "%{public}s", line);
    std::lock_guard diagnosticsLock(diagnosticsMutex);
    if (!diagnosticsLogPath.empty()) {
        std::error_code error;
        const uintmax_t size = std::filesystem::file_size(diagnosticsLogPath, error);
        if (!error && size > kDiagnosticsLogLimit) {
            std::ofstream reset(diagnosticsLogPath, std::ios::trunc);
            reset << "[GoldenPadRecomp] diagnostics: earlier log text was rotated\n";
        }
        std::ofstream log(diagnosticsLogPath, std::ios::app);
        log << line << '\n';
    }
}

void configureDiagnostics(const std::filesystem::path &configPath) {
    std::lock_guard lock(diagnosticsMutex);
    const std::filesystem::path directory = configPath / "Logs";
    const std::filesystem::path latest = directory / "goldenpad-recomp-latest.log";
    const std::filesystem::path previous = directory / "goldenpad-recomp-previous.log";
    diagnosticsSessionMarkerPath = directory / "active-session.marker";
    std::error_code error;
    std::filesystem::create_directories(directory, error);
    const bool unexpectedPreviousEnd = std::filesystem::exists(diagnosticsSessionMarkerPath, error);
    previousSessionEndedUnexpectedly.store(unexpectedPreviousEnd, std::memory_order_relaxed);
    error.clear();
    std::filesystem::remove(previous, error);
    error.clear();
    if (std::filesystem::exists(latest, error)) {
        std::filesystem::rename(latest, previous, error);
    }
    diagnosticsLogPath = latest;
    gameplayInputModeReported.store(-1, std::memory_order_relaxed);
    std::ofstream log(diagnosticsLogPath, std::ios::trunc);
    log << "[GoldenPadRecomp] diagnostics: private current-session log started\n";
    if (unexpectedPreviousEnd) {
        log << "[GoldenPadRecomp] diagnostics: previous foreground session ended unexpectedly; inspect the previous log and iPadOS crash report\n";
    }
    std::ofstream marker(diagnosticsSessionMarkerPath, std::ios::trunc);
    marker << "GoldenPad foreground session active\n";
}

void markDiagnosticsSessionActive() {
    std::lock_guard lock(diagnosticsMutex);
    if (!diagnosticsSessionMarkerPath.empty()) {
        std::ofstream marker(diagnosticsSessionMarkerPath, std::ios::trunc);
        marker << "GoldenPad foreground session active\n";
    }
}

void markDiagnosticsSessionClean() {
    std::lock_guard lock(diagnosticsMutex);
    if (!diagnosticsSessionMarkerPath.empty()) {
        std::error_code error;
        std::filesystem::remove(diagnosticsSessionMarkerPath, error);
    }
}

void queueClampedAxis(std::atomic<int32_t> &axis, int32_t delta) {
    int32_t current = axis.load(std::memory_order_relaxed);
    while (!axis.compare_exchange_weak(
        current,
        std::clamp<int64_t>(static_cast<int64_t>(current) + delta, -32'767, 32'767),
        std::memory_order_relaxed)) {}
}

void configurePrototypeGraphics() {
    ultramodern::renderer::GraphicsConfig graphics{};
    // Match GoldenEye64Recomp's intended remastered defaults. The zero-filled
    // config previously selected original N64 resolution, original aspect,
    // and no MSAA, which explains the visibly coarse physical-iPad output.
    switch (prototypeResolutionMode.load(std::memory_order_relaxed)) {
    case 0:
        graphics.res_option = ultramodern::renderer::Resolution::Original;
        break;
    case 1:
        graphics.res_option = ultramodern::renderer::Resolution::Original2x;
        break;
    default:
        graphics.res_option = ultramodern::renderer::Resolution::Auto;
        break;
    }
    graphics.wm_option = ultramodern::renderer::WindowMode::Fullscreen;
    graphics.hr_option = ultramodern::renderer::HUDRatioMode::Clamp16x9;
    graphics.api_option = ultramodern::renderer::GraphicsApi::Metal;
    graphics.ar_option = ultramodern::renderer::AspectRatio::Expand;
    const bool msaaEnabled = prototypeMsaaEnabled.load(std::memory_order_relaxed);
    graphics.msaa_option = msaaEnabled
        ? ultramodern::renderer::Antialiasing::MSAA2X
        : ultramodern::renderer::Antialiasing::None;
    // Display-rate interpolation can expose incompatible transforms as
    // intermittent geometry shimmer. Preserve high resolution and MSAA while
    // using the game's original presentation rate for a stable baseline.
    graphics.rr_option = ultramodern::renderer::RefreshRate::Original;
    graphics.hpfb_option = ultramodern::renderer::HighPrecisionFramebuffer::Auto;
    graphics.rr_manual_value = 60;
    graphics.ds_option = 1;
    graphics.developer_mode = false;
    ultramodern::renderer::set_graphics_config(graphics);
    const char *resolution = graphics.res_option == ultramodern::renderer::Resolution::Original
        ? "native resolution"
        : graphics.res_option == ultramodern::renderer::Resolution::Original2x
            ? "2x resolution"
            : "automatic high resolution";
    logEvent("graphics", "Metal %s, expanded aspect, %s, %s, original refresh",
        resolution,
        msaaEnabled ? "2x MSAA" : "MSAA off",
        prototypeThreePointFiltering.load(std::memory_order_relaxed)
            ? "three-point filtering" : "linear filtering");
}

void setStatus(const std::string &message) {
    {
        std::lock_guard lock(statusMutex);
        runtimeStatus = message;
    }
    logEvent("status", "%s", message.c_str());
}

void debugMonitorStub(uint8_t *, recomp_context *ctx) {
    ctx->r2 = 0;
}

int32_t readGameWord(uint8_t *rdram, uint32_t address) {
    return MEM_W(0, static_cast<gpr>(static_cast<int32_t>(address)));
}

void writeGameWord(uint8_t *rdram, uint32_t address, int32_t value) {
    MEM_W(0, static_cast<gpr>(static_cast<int32_t>(address))) = value;
}

float readGameFloat(uint8_t *rdram, uint32_t address) {
    return std::bit_cast<float>(static_cast<uint32_t>(readGameWord(rdram, address)));
}

constexpr uint32_t kFireRateWindowTicks = 100;
constexpr uint32_t kFireRateProbeRunLimit = 3;
constexpr uint8_t kKf7SovietItem = 8;
constexpr uint8_t kKf7SovietRawRate = 3;

struct PlayerFireRateWindow {
    bool active = false;
    uint32_t runs = 0;
    uint32_t ticks = 0;
    int32_t lastWeapon = -1;
    int32_t lastAmmo = -1;
    int32_t player = -1;
    int32_t weapon = -1;
    int32_t startingAmmo = -1;
    int32_t endingAmmo = -1;
    int32_t startingCounter = -1;
    int32_t endingCounter = -1;
    uint32_t shotEvents = 0;
};

struct GuardFireRateWindow {
    bool active = false;
    uint32_t runs = 0;
    uint32_t guardKey = 0;
    uint64_t startingTick = 0;
    uint8_t startingCounter = 0;
    uint8_t endingCounter = 0;
    uint32_t shotEvents = 0;
};

PlayerFireRateWindow playerFireRateWindow;
GuardFireRateWindow guardFireRateWindow;

bool isAutomaticPlayerWeapon(int32_t weapon) {
    // GoldenEye's full-auto group runs from the Skorpion through the RC-P90.
    return weapon >= 7 && weapon <= 14;
}

void completeGuardFireRateWindow(uint64_t simulationTick) {
    if (!guardFireRateWindow.active ||
        simulationTick - guardFireRateWindow.startingTick < kFireRateWindowTicks) {
        return;
    }
    logEvent("fire-rate-probe",
        "guard run=%u complete ticks=%u item=%u rawRate=%u events=%u counter=%u->%u",
        guardFireRateWindow.runs + 1,
        kFireRateWindowTicks,
        kKf7SovietItem,
        kKf7SovietRawRate,
        guardFireRateWindow.shotEvents,
        guardFireRateWindow.startingCounter,
        guardFireRateWindow.endingCounter);
    ++guardFireRateWindow.runs;
    guardFireRateWindow.active = false;
}

size_t getQueuedFrames();

void monitorGameState(uint8_t *rdram) {
    int32_t previousMenu = INT32_MIN;
    int32_t previousStage = INT32_MIN;
    int32_t previousPendingStage = INT32_MIN;
    uint64_t previousDisplayLists = 0;
    uint64_t previousScreenUpdates = 0;
    uint64_t previousPresented = 0;
    int stalledActiveSamples = 0;
    int heartbeat = 0;
    while (runtimeStarted.load(std::memory_order_relaxed)) {
        const int32_t menu = readGameWord(rdram, 0x8002A6C0);
        const int32_t stage = readGameWord(rdram, 0x80023FA8);
        const int32_t pendingStage = readGameWord(rdram, 0x80048164);
        if (menu != previousMenu || stage != previousStage || pendingStage != previousPendingStage || heartbeat == 0) {
            logEvent("game-state",
                "menu=%d stage=%d pending=%d timer=%d update=%d firstLegal=%d firstMain=%d",
                menu, stage, pendingStage,
                readGameWord(rdram, 0x8002A6CC),
                readGameWord(rdram, 0x8002A6C4),
                readGameWord(rdram, 0x8002A72C),
                readGameWord(rdram, 0x8002A730));
            previousMenu = menu;
            previousStage = stage;
            previousPendingStage = pendingStage;
        }
        const uint64_t displayLists = rt64DisplayListCount.load(std::memory_order_relaxed);
        const uint64_t screenUpdates = rt64ScreenUpdateCount.load(std::memory_order_relaxed);
        const uint64_t presented = rt64PresentedCount.load(std::memory_order_relaxed);
        const bool active = appActive.load(std::memory_order_relaxed);
        if (heartbeat == 0) {
            const uint32_t player = static_cast<uint32_t>(readGameWord(rdram, 0x80079EB0));
            const bool playerValid = player >= 0x80000000u && player < 0xA0000000u;
            float viewX = playerValid ? readGameFloat(rdram, player + 0x4C4) : 0.0f;
            float viewY = playerValid ? readGameFloat(rdram, player + 0x4C8) : 0.0f;
            float viewZ = playerValid ? readGameFloat(rdram, player + 0x4CC) : 0.0f;
            float upX = playerValid ? readGameFloat(rdram, player + 0x4D0) : 0.0f;
            float upY = playerValid ? readGameFloat(rdram, player + 0x4D4) : 0.0f;
            float upZ = playerValid ? readGameFloat(rdram, player + 0x4D8) : 0.0f;
            const float viewLengthSquared = viewX * viewX + viewY * viewY + viewZ * viewZ;
            const float upLengthSquared = upX * upX + upY * upY + upZ * upZ;
            const bool basisValid = stage != 90 && std::isfinite(viewLengthSquared) &&
                std::isfinite(upLengthSquared) && viewLengthSquared > 0.25f &&
                viewLengthSquared < 4.0f && upLengthSquared > 0.25f && upLengthSquared < 4.0f;
            if (!basisValid) {
                viewX = viewY = viewZ = 0.0f;
                upX = upY = upZ = 0.0f;
            }
            logEvent("health",
                "app=%s dl=%llu vi=%llu presented=%llu audioQueued=%zu audioRendered=%llu audioDropped=%llu audioUnderrunFrames=%llu audioUnderrunCallbacks=%llu input=%s p1look=(%d,%d) p2look=(%d,%d) player=0x%08X pos=(%.2f,%.2f,%.2f) model=(%.2f,%.2f,%.2f) room=(%.2f,%.2f,%.2f) yaw=%.2f pitch=%.2f basis=%s view=(%.3f,%.3f,%.3f) up=(%.3f,%.3f,%.3f)",
                active ? "active" : "inactive",
                static_cast<unsigned long long>(displayLists),
                static_cast<unsigned long long>(screenUpdates),
                static_cast<unsigned long long>(presented),
                getQueuedFrames(),
                static_cast<unsigned long long>(audioRenderedFrames.load(std::memory_order_relaxed)),
                static_cast<unsigned long long>(audioDroppedFrames.load(std::memory_order_relaxed)),
                static_cast<unsigned long long>(audioUnderrunFrames.load(std::memory_order_relaxed)),
                static_cast<unsigned long long>(audioUnderrunCallbacks.load(std::memory_order_relaxed)),
                fourPlayerTestMode.load(std::memory_order_relaxed) ? "external-p1+touch-p2+neutral-p3/p4" :
                    (twoPlayerTestMode.load(std::memory_order_relaxed) ? "external-p1+touch-p2" :
                        (controllerConnected.load(std::memory_order_relaxed) ? "external-p1" : "touch-p1")),
                controllerLookX[0].load(std::memory_order_relaxed),
                controllerLookY[0].load(std::memory_order_relaxed),
                controllerLookX[1].load(std::memory_order_relaxed),
                controllerLookY[1].load(std::memory_order_relaxed),
                player,
                playerValid ? readGameFloat(rdram, player + 0x04) : 0.0f,
                playerValid ? readGameFloat(rdram, player + 0x08) : 0.0f,
                playerValid ? readGameFloat(rdram, player + 0x0C) : 0.0f,
                playerValid ? readGameFloat(rdram, player + 0x38) : 0.0f,
                playerValid ? readGameFloat(rdram, player + 0x3C) : 0.0f,
                playerValid ? readGameFloat(rdram, player + 0x40) : 0.0f,
                playerValid ? readGameFloat(rdram, player + 0x50) : 0.0f,
                playerValid ? readGameFloat(rdram, player + 0x54) : 0.0f,
                playerValid ? readGameFloat(rdram, player + 0x58) : 0.0f,
                playerValid ? readGameFloat(rdram, player + 0x148) : 0.0f,
                playerValid ? readGameFloat(rdram, player + 0x158) : 0.0f,
                basisValid ? "valid" : "unavailable",
                viewX, viewY, viewZ, upX, upY, upZ);
        }
        const bool rendererHadStarted = displayLists != 0 || screenUpdates != 0;
        const bool rendererAdvanced = displayLists != previousDisplayLists ||
            screenUpdates != previousScreenUpdates || presented != previousPresented;
        if (active && rendererHadStarted && !rendererAdvanced) {
            ++stalledActiveSamples;
            if (stalledActiveSamples == 5) {
                logEvent("watchdog",
                    "RT64 made no progress for 10 seconds while active (dl=%llu vi=%llu presented=%llu)",
                    static_cast<unsigned long long>(displayLists),
                    static_cast<unsigned long long>(screenUpdates),
                    static_cast<unsigned long long>(presented));
            }
        } else {
            stalledActiveSamples = 0;
        }
        previousDisplayLists = displayLists;
        previousScreenUpdates = screenUpdates;
        previousPresented = presented;
        heartbeat = (heartbeat + 1) % 5;
#if defined(GOLDENPAD_RECOMP_MAC)
        // Keep release diagnostics available without polling shared game state
        // frequently enough to perturb the desktop runtime.
        std::this_thread::sleep_for(std::chrono::seconds(10));
#else
        std::this_thread::sleep_for(std::chrono::seconds(2));
#endif
    }
}

void installGoldenEyeRuntimeStubs(uint8_t *rdram, recomp_context *) {
    activeRdram.store(rdram, std::memory_order_release);
    // The retail unlock check reads this debug global directly. Initialize it
    // when RDRAM becomes available so a setting restored at app launch works
    // before the first mission-select screen without touching save data.
    writeGameWord(rdram, 0x80036DB4,
        unlockAllMissions.load(std::memory_order_relaxed) ? 1 : 0);
    // Overlay initialization clears its dynamic dispatch map immediately before
    // the game threads begin. Install GoldenEye's unused rmon monitor stubs at
    // thread creation so indirect calls see them after that reset.
    constexpr uint32_t monitorStubs[] = {
        0x8000CCA0, 0x8000CCA8, 0x8000CCB0, 0x8000CCB8,
        0x8000CCC0, 0x8000CCC8, 0x8000CCD0, 0x8000CCD8,
        0x8000CCE0,
    };
    for (const uint32_t address : monitorStubs) {
        recomp::overlays::add_loaded_function(static_cast<int32_t>(address), debugMonitorStub);
    }
    if (!stateProbeStarted.exchange(true, std::memory_order_relaxed)) {
        std::thread(monitorGameState, rdram).detach();
    }
}

RspUcodeFunc *getRspMicrocode(const OSTask *task) {
    return task->t.type == M_AUDTASK ? aspMain : nullptr;
}

void queueSamples(int16_t *samples, size_t sampleCount) {
    if (!audioCallbackReported.exchange(true)) {
        logEvent("audio", "game submitted audio to the GoldenPad PCM ring");
    }
    if (samples == nullptr || sampleCount < 2) {
        return;
    }
    uint64_t incomingFrames = sampleCount / 2;
    if (incomingFrames > kAudioRingFrames) {
        samples += (incomingFrames - kAudioRingFrames) * 2;
        incomingFrames = kAudioRingFrames;
    }

    const uint64_t readFrame = audioReadFrame.load(std::memory_order_acquire);
    uint64_t writeFrame = audioWriteFrame.load(std::memory_order_relaxed);
    const uint64_t queuedFrames = std::min(writeFrame - std::min(writeFrame, readFrame), kAudioRingFrames);
    const uint64_t availableFrames = kAudioRingFrames - queuedFrames;
    if (incomingFrames > availableFrames) {
        const uint64_t discard = incomingFrames - availableFrames;
        samples += discard * 2;
        incomingFrames -= discard;
        audioDroppedFrames.fetch_add(discard, std::memory_order_relaxed);
    }
    for (uint64_t frame = 0; frame < incomingFrames; ++frame) {
        const uint64_t destination = ((writeFrame + frame) % kAudioRingFrames) * 2;
        // Match GoldenEye64Recomp's reference host: N64ModernRuntime's RDRAM
        // address XOR leaves each interleaved stereo pair in reversed order.
        audioRing[destination] = samples[frame * 2 + 1];
        audioRing[destination + 1] = samples[frame * 2];
    }
    audioWriteFrame.store(writeFrame + incomingFrames, std::memory_order_release);
}
size_t getQueuedFrames() {
    const uint64_t readFrame = audioReadFrame.load(std::memory_order_acquire);
    const uint64_t writeFrame = audioWriteFrame.load(std::memory_order_acquire);
    return static_cast<size_t>(std::min(writeFrame - std::min(writeFrame, readFrame), kAudioRingFrames));
}
size_t getFramesRemaining() {
    // AVAudioSourceNode can pull a larger resampled block than the game's
    // per-VI producer chunk. Keep a small host reserve out of the value the
    // game sees so its next audio task is scheduled before that pull arrives.
    const size_t queued = getQueuedFrames();
    return queued > kAudioPrebufferFrames ? queued - kAudioPrebufferFrames : 0;
}
void setFrequency(uint32_t frequency) {
    logEvent("audio", "game requested %u Hz output", frequency);
}
void pollInput() {
    if (!inputPollReported.exchange(true)) {
        logEvent("input", "game began polling the prototype controller bridge");
    }
}
bool getInput(int controllerNum, uint16_t *buttons, float *x, float *y) {
    const bool portAvailable = controllerNum == 0 ||
        (controllerNum == 1 && twoPlayerTestMode.load(std::memory_order_relaxed)) ||
        (controllerNum >= 2 && controllerNum < 4 && fourPlayerTestMode.load(std::memory_order_relaxed));
    if (!portAvailable || buttons == nullptr || x == nullptr || y == nullptr) {
        const uint8_t reportBit = controllerNum >= 0 && controllerNum < 4
            ? static_cast<uint8_t>(1u << controllerNum)
            : static_cast<uint8_t>(1u << 4);
        if ((invalidInputPortsReported.fetch_or(reportBit) & reportBit) == 0) {
            logEvent("input", "controller port %d has no prototype input source", controllerNum + 1);
        }
        return false;
    }
    const size_t port = static_cast<size_t>(controllerNum);
    *buttons = static_cast<uint16_t>(controllerButtons[port].load(std::memory_order_relaxed));
    *x = static_cast<float>(controllerStickX[port].load(std::memory_order_relaxed)) / 80.0f;
    *y = static_cast<float>(controllerStickY[port].load(std::memory_order_relaxed)) / 80.0f;
    const uint8_t reportBit = static_cast<uint8_t>(1u << controllerNum);
    if ((inputStateReported.fetch_or(reportBit) & reportBit) == 0) {
        logEvent("input", "controller port %d state is available", controllerNum + 1);
    }
    return true;
}
void setRumble(int controllerNum, bool enabled) {
    if (controllerNum >= 0 && controllerNum < static_cast<int>(kControllerPorts)) {
        const uint32_t transition = controllerRumbleTransitions[controllerNum].fetch_add(1) + 1;
        if (transition <= 4 || transition % 60 == 0) {
            logEvent("input", "controller %d rumble %s (not implemented; sampled transition %u)",
                controllerNum + 1, enabled ? "requested" : "stopped", transition);
        }
    }
}
ultramodern::input::connected_device_info_t getConnectedDeviceInfo(int controllerNum) {
    const bool portAvailable = controllerNum == 0 ||
        (controllerNum == 1 && twoPlayerTestMode.load(std::memory_order_relaxed)) ||
        (controllerNum >= 2 && controllerNum < 4 && fourPlayerTestMode.load(std::memory_order_relaxed));
    if (portAvailable) {
        const uint8_t reportBit = static_cast<uint8_t>(1u << controllerNum);
        if ((controllerPortsReported.fetch_or(reportBit) & reportBit) == 0) {
            logEvent("input", "advertising a normal controller in port %d", controllerNum + 1);
        }
        return {ultramodern::input::Device::Controller, ultramodern::input::Pak::None};
    }
    return {ultramodern::input::Device::None, ultramodern::input::Pak::None};
}
void reportRuntimeError(const char *message) {
    setStatus(std::string("AOT runtime error: ") + message);
    logEvent("error", "%s", message);
}
std::string gameThreadName(const OSThread *) { return "GE game"; }

void runRuntime(ultramodern::renderer::WindowHandle window, std::filesystem::path romPath, std::filesystem::path configPath) {
    try {
        configureDiagnostics(configPath);
        logEvent("runtime", "worker started");
        if (fireRateProbeEnabled.load(std::memory_order_acquire)) {
            logEvent("fire-rate-probe",
                "enabled; observation only, %u-tick windows, maximum %u player and guard runs",
                kFireRateWindowTicks,
                kFireRateProbeRunLimit);
        }
        std::filesystem::create_directories(configPath);
        recomp::register_config_path(std::move(configPath));
        configurePrototypeGraphics();

        recomp::GameEntry game{};
        game.rom_hash = kGoldenEyeTlbFreeHash;
        game.internal_name = "GOLDENEYE";
        game.game_id = kGameID;
        game.save_type = recomp::SaveType::Eep4k;
        game.is_enabled = true;
        game.entrypoint_address = get_entrypoint_address();
        game.entrypoint = recomp_entrypoint;
        game.thread_create_callback = installGoldenEyeRuntimeStubs;
        recomp::register_game(game);
        zelda64::register_overlays();
        zelda64::register_patches();
        logEvent("runtime", "registered GoldenEye game, overlays, and upstream recomp patches");

        std::u8string gameID = kGameID;
        if (recomp::select_rom(romPath, gameID) != recomp::RomValidationError::Good) {
            setStatus("AOT runtime: the imported ROM is not the expected GoldenEye NTSC-U TLBFREE input");
            logEvent("runtime", "ROM validation failed");
            runtimeStarted = false;
            return;
        }
        logEvent("runtime", "ROM validation passed");

        recomp::rsp::callbacks_t rspCallbacks{.get_rsp_microcode = getRspMicrocode};
        ultramodern::renderer::callbacks_t rendererCallbacks{.create_render_context = zelda64::renderer::create_render_context};
        ultramodern::audio_callbacks_t audioCallbacks{
            .queue_samples = queueSamples,
            .get_frames_remaining = getFramesRemaining,
            .set_frequency = setFrequency,
        };
        ultramodern::input::callbacks_t inputCallbacks{
            .poll_input = pollInput,
            .get_input = getInput,
            .set_rumble = setRumble,
            .get_connected_device_info = getConnectedDeviceInfo,
        };
        ultramodern::gfx_callbacks_t gfxCallbacks{};
        ultramodern::events::callbacks_t eventCallbacks{};
        ultramodern::error_handling::callbacks_t errorCallbacks{.message_box = reportRuntimeError};
        ultramodern::threads::callbacks_t threadCallbacks{.get_game_thread_name = gameThreadName};

        setStatus("AOT runtime: starting GoldenEye game thread");
        logEvent("runtime", "starting GoldenEye runtime");
        recomp::start_game(kGameID);
        setStatus("AOT runtime: GoldenEye loop active");
        recomp::start({0, 0, 1, "-prototype"}, window, rspCallbacks, rendererCallbacks,
            audioCallbacks, inputCallbacks, gfxCallbacks, eventCallbacks, errorCallbacks, threadCallbacks);
        setStatus("AOT runtime: stopped");
    } catch (const std::exception &error) {
        reportRuntimeError(error.what());
    }
    logEvent("runtime", "worker stopped");
    runtimeStarted = false;
}
}

extern "C" void goldenpad_recomp_set_msaa_enabled(int32_t enabled) {
    if (!runtimeStarted.load(std::memory_order_relaxed)) {
        prototypeMsaaEnabled.store(enabled != 0, std::memory_order_relaxed);
    }
}

extern "C" void goldenpad_recomp_set_resolution_mode(int32_t mode) {
    if (!runtimeStarted.load(std::memory_order_relaxed)) {
        prototypeResolutionMode.store(std::clamp(mode, 0, 2), std::memory_order_relaxed);
    }
}

extern "C" void goldenpad_recomp_set_three_point_filtering(int32_t enabled) {
    if (!runtimeStarted.load(std::memory_order_relaxed)) {
        prototypeThreePointFiltering.store(enabled != 0, std::memory_order_relaxed);
    }
}

extern "C" int32_t goldenpad_recomp_three_point_filtering_enabled() {
    return prototypeThreePointFiltering.load(std::memory_order_relaxed) ? 1 : 0;
}

extern "C" const char *goldenpad_recomp_start_game(void *window, void *view, const char *romPath, const char *configPath) {
    if (window == nullptr || view == nullptr || romPath == nullptr || configPath == nullptr) {
        logEvent("launch", "rejected incomplete launch arguments");
        return "AOT runtime: missing launch input";
    }
    if (runtimeStarted.exchange(true)) {
        logEvent("launch", "ignored duplicate launch request");
        return "AOT runtime: already running";
    }
    setStatus("AOT runtime: validating imported user ROM");
    std::thread(runRuntime, ultramodern::renderer::WindowHandle{window, view},
        std::filesystem::path(romPath), std::filesystem::path(configPath)).detach();
    return "AOT runtime: launch requested";
}

extern "C" int32_t goldenpad_recomp_validate_tlbfree_rom(const char *romPath) {
    if (romPath == nullptr) {
        return 0;
    }
    std::ifstream input(std::filesystem::path(romPath), std::ios::binary | std::ios::ate);
    if (!input.good()) {
        return 0;
    }
    const std::streamsize size = input.tellg();
    if (size != kGoldenEyeTlbFreeSize) {
        return 0;
    }
    input.seekg(0, std::ios::beg);
    std::vector<uint8_t> bytes(static_cast<size_t>(size));
    if (!input.read(reinterpret_cast<char *>(bytes.data()), size)) {
        return 0;
    }
    return XXH3_64bits(bytes.data(), bytes.size()) == kGoldenEyeTlbFreeHash ? 1 : 0;
}

extern "C" const char *goldenpad_recomp_game_status() {
    thread_local std::string statusSnapshot;
    std::lock_guard lock(statusMutex);
    statusSnapshot = runtimeStatus;
    return statusSnapshot.c_str();
}

extern "C" void goldenpad_recomp_set_controller_state(int32_t controllerNum, uint32_t buttons, int32_t stickX, int32_t stickY) {
    if (controllerNum < 0 || controllerNum >= static_cast<int32_t>(kControllerPorts)) {
        return;
    }
    const size_t port = static_cast<size_t>(controllerNum);
    const uint32_t normalizedButtons = buttons & 0xFFFFu;
    const uint32_t previousButtons = controllerButtons[port].exchange(normalizedButtons, std::memory_order_relaxed);
    if (sidestepProbeEnabled.load(std::memory_order_relaxed) &&
        (normalizedButtons & 0x0003u) != 0 &&
        (previousButtons & 0x0003u) == 0) {
        logEvent("sidestep-probe", "controller=%d buttons=0x%04X stick=(%d,%d)",
            controllerNum + 1, normalizedButtons, stickX, stickY);
    }
    if (previousButtons != normalizedButtons) {
        const uint32_t transition = controllerButtonTransitions[port].fetch_add(1) + 1;
        if (transition <= 12 || transition % 120 == 0) {
            logEvent("input", "controller %d buttons 0x%04X (sampled transition %u)",
                controllerNum + 1, normalizedButtons, transition);
        }
    }
    controllerStickX[port].store(std::clamp(stickX, -80, 80), std::memory_order_relaxed);
    controllerStickY[port].store(std::clamp(stickY, -80, 80), std::memory_order_relaxed);
}

extern "C" void goldenpad_recomp_set_right_analog(int32_t controllerNum, int32_t lookX, int32_t lookY) {
    if (controllerNum < 0 || controllerNum >= static_cast<int32_t>(kControllerPorts)) {
        return;
    }
    const size_t port = static_cast<size_t>(controllerNum);
    const int32_t normalizedX = std::clamp(lookX, -32'767, 32'767);
    const int32_t normalizedY = std::clamp(lookY, -32'767, 32'767);
    const int32_t previousX = controllerLookX[port].exchange(normalizedX, std::memory_order_relaxed);
    const int32_t previousY = controllerLookY[port].exchange(normalizedY, std::memory_order_relaxed);
    const bool wasActive = std::abs(previousX) > 2'048 || std::abs(previousY) > 2'048;
    const bool isActive = std::abs(normalizedX) > 2'048 || std::abs(normalizedY) > 2'048;
    if (wasActive != isActive) {
        logEvent("input", "controller %d right stick %s at (%d,%d)",
            controllerNum + 1, isActive ? "active" : "neutral", normalizedX, normalizedY);
    }
    const uint32_t sample = controllerLookSamples[port].fetch_add(1, std::memory_order_relaxed) + 1;
    if (isActive && sample % 600 == 1) {
        logEvent("input", "controller %d right stick sample (%d,%d)",
            controllerNum + 1, normalizedX, normalizedY);
    }
}

extern "C" void goldenpad_recomp_set_controller_connected(int32_t connected) {
    const bool next = connected != 0;
    const bool previous = controllerConnected.exchange(next, std::memory_order_relaxed);
    if (!next) {
        twoPlayerTestMode.store(false, std::memory_order_relaxed);
        fourPlayerTestMode.store(false, std::memory_order_relaxed);
    }
    if (previous != next) {
        logEvent("input", "external controller %s; touch overlay %s",
            next ? "connected" : "disconnected",
            next && !twoPlayerTestMode.load(std::memory_order_relaxed) ? "hidden" : "visible");
    }
}

extern "C" void goldenpad_recomp_set_fire_rate_probe_enabled(int32_t enabled) {
    const bool next = enabled != 0;
    fireRateProbeEnabled.store(next, std::memory_order_release);
    if (next) {
        fireRateProbeSimulationTicks.store(0, std::memory_order_relaxed);
        fireRateProbeRawGuardSamples.store(0, std::memory_order_relaxed);
        playerFireRateWindow = {};
        guardFireRateWindow = {};
    }
}

extern "C" void goldenpad_recomp_set_sidestep_probe_enabled(int32_t enabled) {
    sidestepProbeEnabled.store(enabled != 0, std::memory_order_relaxed);
}

extern "C" void goldenpad_recomp_fire_rate_player_sample(
    uint8_t *rdram, recomp_context *ctx) {
    if (!fireRateProbeEnabled.load(std::memory_order_acquire)) {
        return;
    }
    const int32_t player = _arg<0, int32_t>(rdram, ctx);
    const int32_t weapon = _arg<1, int32_t>(rdram, ctx);
    const int32_t ammo = _arg<2, int32_t>(rdram, ctx);
    const int32_t counter = _arg<3, int32_t>(rdram, ctx);
    if (player != 0) {
        return;
    }

    const uint64_t simulationTick =
        fireRateProbeSimulationTicks.fetch_add(1, std::memory_order_relaxed) + 1;
    completeGuardFireRateWindow(simulationTick);

    if (!isAutomaticPlayerWeapon(weapon)) {
        playerFireRateWindow.active = false;
        playerFireRateWindow.lastWeapon = weapon;
        playerFireRateWindow.lastAmmo = ammo;
        return;
    }
    const int32_t previousAmmo = playerFireRateWindow.lastAmmo;
    const uint32_t shotEvents = playerFireRateWindow.lastWeapon == weapon &&
        previousAmmo > ammo ? static_cast<uint32_t>(previousAmmo - ammo) : 0;
    playerFireRateWindow.lastWeapon = weapon;
    playerFireRateWindow.lastAmmo = ammo;
    if (!playerFireRateWindow.active) {
        if (shotEvents == 0 ||
            playerFireRateWindow.runs >= kFireRateProbeRunLimit) {
            return;
        }
        playerFireRateWindow.active = true;
        playerFireRateWindow.ticks = 1;
        playerFireRateWindow.player = player;
        playerFireRateWindow.weapon = weapon;
        playerFireRateWindow.startingAmmo = previousAmmo;
        playerFireRateWindow.endingAmmo = ammo;
        playerFireRateWindow.startingCounter = counter;
        playerFireRateWindow.endingCounter = counter;
        playerFireRateWindow.shotEvents = shotEvents;
        logEvent("fire-rate-probe",
            "player run=%u begin ticks=%u weapon=%d ammo=%d counter=%d",
            playerFireRateWindow.runs + 1,
            kFireRateWindowTicks,
            weapon,
            previousAmmo,
            counter);
        return;
    }
    if (playerFireRateWindow.weapon != weapon) {
        playerFireRateWindow.active = false;
        return;
    }
    playerFireRateWindow.shotEvents += shotEvents;
    playerFireRateWindow.endingAmmo = ammo;
    playerFireRateWindow.endingCounter = counter;
    ++playerFireRateWindow.ticks;
    if (playerFireRateWindow.ticks >= kFireRateWindowTicks) {
        logEvent("fire-rate-probe",
            "player run=%u complete ticks=%u weapon=%d events=%u ammo=%d->%d counter=%d->%d",
            playerFireRateWindow.runs + 1,
            playerFireRateWindow.ticks,
            playerFireRateWindow.weapon,
            playerFireRateWindow.shotEvents,
            playerFireRateWindow.startingAmmo,
            playerFireRateWindow.endingAmmo,
            playerFireRateWindow.startingCounter,
            playerFireRateWindow.endingCounter);
        ++playerFireRateWindow.runs;
        playerFireRateWindow.active = false;
    }
}

extern "C" void goldenpad_recomp_fire_rate_guard_sample(
    uint8_t *rdram, recomp_context *ctx) {
    if (!fireRateProbeEnabled.load(std::memory_order_acquire)) {
        return;
    }
    const int32_t item = _arg<0, int32_t>(rdram, ctx);
    const uint8_t before = static_cast<uint8_t>(_arg<1, int32_t>(rdram, ctx));
    const uint8_t after = static_cast<uint8_t>(_arg<2, int32_t>(rdram, ctx));
    const uint32_t guardKey = _arg<3, uint32_t>(rdram, ctx);
    const uint32_t rawSample =
        fireRateProbeRawGuardSamples.fetch_add(1, std::memory_order_relaxed);
    if (rawSample < 8) {
        logEvent("fire-rate-probe",
            "guard raw=%u item=%d counter=%u->%u key=0x%08X",
            rawSample + 1,
            item,
            before,
            after,
            guardKey);
    }
    const bool committedGate = item == kKf7SovietItem &&
        after == static_cast<uint8_t>(before + 1u) &&
        after % kKf7SovietRawRate == 0;
    if (!committedGate) {
        return;
    }

    if (!guardFireRateWindow.active && guardFireRateWindow.runs < kFireRateProbeRunLimit) {
        guardFireRateWindow.active = true;
        guardFireRateWindow.guardKey = guardKey;
        guardFireRateWindow.startingTick =
            fireRateProbeSimulationTicks.load(std::memory_order_relaxed);
        guardFireRateWindow.startingCounter = after;
        guardFireRateWindow.endingCounter = after;
        guardFireRateWindow.shotEvents = 1;
        logEvent("fire-rate-probe",
            "guard run=%u begin ticks=%u item=%d rawRate=%u counter=%u",
            guardFireRateWindow.runs + 1,
            kFireRateWindowTicks,
            item,
            kKf7SovietRawRate,
            after);
    } else if (guardFireRateWindow.active &&
        guardFireRateWindow.guardKey == guardKey) {
        ++guardFireRateWindow.shotEvents;
        guardFireRateWindow.endingCounter = after;
    }
}

extern "C" void goldenpad_recomp_set_two_player_test_mode(int32_t enabled) {
    const bool next = enabled != 0 && controllerConnected.load(std::memory_order_relaxed);
    const bool previous = twoPlayerTestMode.exchange(next, std::memory_order_relaxed);
    if (!next) {
        fourPlayerTestMode.store(false, std::memory_order_relaxed);
    }
    if (previous != next) {
        controllerPortsReported.store(0, std::memory_order_relaxed);
        inputStateReported.store(0, std::memory_order_relaxed);
        invalidInputPortsReported.store(0, std::memory_order_relaxed);
        logEvent("input", "two-player test mode %s; external=P1 touch=P2",
            next ? "enabled" : "disabled");
    }
}

extern "C" void goldenpad_recomp_set_four_player_test_mode(int32_t enabled) {
    const bool next = enabled != 0 &&
        controllerConnected.load(std::memory_order_relaxed) &&
        twoPlayerTestMode.load(std::memory_order_relaxed);
    const bool previous = fourPlayerTestMode.exchange(next, std::memory_order_relaxed);
    if (previous != next) {
        controllerPortsReported.store(0, std::memory_order_relaxed);
        inputStateReported.store(0, std::memory_order_relaxed);
        invalidInputPortsReported.store(0, std::memory_order_relaxed);
        logEvent("input", "four-player render test %s; external=P1 touch=P2 neutral=P3/P4",
            next ? "enabled" : "disabled");
    }
}

extern "C" void goldenpad_recomp_set_app_active(int32_t active) {
    const bool next = active != 0;
    const bool previous = appActive.exchange(next, std::memory_order_relaxed);
    if (previous != next) {
        uint64_t discardedAudioFrames = 0;
        if (next) {
            const uint64_t writeFrame = audioWriteFrame.load(std::memory_order_acquire);
            const uint64_t readFrame = audioReadFrame.exchange(writeFrame, std::memory_order_acq_rel);
            discardedAudioFrames = writeFrame - std::min(writeFrame, readFrame);
            audioPlaybackPrimed = false;
            audioFadeInFramesRemaining = 0;
            audioLastLeft = 0.0f;
            audioLastRight = 0.0f;
        }
        if (next) {
            markDiagnosticsSessionActive();
        }
        logEvent("lifecycle", "host became %s; RT64 presentation %s",
            next ? "active" : "inactive", next ? "resumed" : "suspended");
        if (!next) {
            markDiagnosticsSessionClean();
        }
        if (discardedAudioFrames != 0) {
            logEvent("audio", "discarded %llu stale queued frames after foregrounding",
                static_cast<unsigned long long>(discardedAudioFrames));
        }
    }
}

extern "C" void goldenpad_recomp_note_transient_inactive() {
    logEvent("lifecycle", "transient inactive state observed; RT64 presentation kept active");
}

extern "C" int32_t goldenpad_recomp_is_app_active() {
    return appActive.load(std::memory_order_relaxed) ? 1 : 0;
}

extern "C" void goldenpad_recomp_note_display_list(uint64_t count) {
    rt64DisplayListCount.store(count, std::memory_order_relaxed);
}

extern "C" void goldenpad_recomp_note_screen_progress(uint64_t updates, uint64_t presented) {
    rt64ScreenUpdateCount.store(updates, std::memory_order_relaxed);
    rt64PresentedCount.store(presented, std::memory_order_relaxed);
}

extern "C" void goldenpad_recomp_queue_touch_look(int32_t controllerNum, int32_t lookX, int32_t lookY) {
    if (controllerNum < 0 || controllerNum >= static_cast<int32_t>(kControllerPorts)) {
        return;
    }
    const size_t port = static_cast<size_t>(controllerNum);
    queueClampedAxis(queuedTouchLookX[port], lookX);
    queueClampedAxis(queuedTouchLookY[port], lookY);
}

extern "C" int32_t goldenpad_recomp_previous_session_ended_unexpectedly() {
    return previousSessionEndedUnexpectedly.load(std::memory_order_relaxed) ? 1 : 0;
}

extern "C" void goldenpad_recomp_request_crouch_toggle(int32_t controllerNum) {
    if (controllerNum >= 0 && controllerNum < static_cast<int32_t>(kControllerPorts)) {
        crouchToggleRequested[controllerNum].store(true, std::memory_order_release);
    }
}

extern "C" void goldenpad_recomp_set_invert_aim_y(int32_t enabled) {
    invertAimY.store(enabled != 0, std::memory_order_relaxed);
}

extern "C" void goldenpad_recomp_set_unlock_all_missions(int32_t enabled) {
    const bool next = enabled != 0;
    const bool previous = unlockAllMissions.exchange(next, std::memory_order_relaxed);
    if (uint8_t *rdram = activeRdram.load(std::memory_order_acquire); rdram != nullptr) {
        writeGameWord(rdram, 0x80036DB4, next ? 1 : 0);
    }
    if (previous != next) {
        logEvent("progression", "unlock all missions %s; EEPROM unchanged", next ? "enabled" : "disabled");
    }
}

extern "C" void goldenpad_recomp_request_return_to_title() {
    returnToTitleRequested.store(true, std::memory_order_release);
    logEvent("navigation", "return to main menu requested");
}

extern "C" int32_t goldenpad_recomp_gameplay_input_active() {
    const auto reportMode = [](int32_t active) {
        const int32_t previous = gameplayInputModeReported.exchange(
            active, std::memory_order_relaxed);
        if (previous != active) {
            logEvent("input-mode", "mobile mapping uses %s semantics",
                active != 0 ? "live-gameplay strafe" : "menu/watch stick");
        }
        return active;
    };

    uint8_t *rdram = activeRdram.load(std::memory_order_acquire);
    if (!runtimeStarted.load(std::memory_order_relaxed) || rdram == nullptr) {
        return reportMode(0);
    }

    constexpr int32_t kTitleStage = 90;
    const int32_t stage = readGameWord(rdram, 0x80023FA8);
    if (stage == kTitleStage) {
        return reportMode(0);
    }

    const uint32_t playerAddress = static_cast<uint32_t>(
        readGameWord(rdram, 0x80079EB0));
    if (playerAddress < 0x80000000 || playerAddress > 0x9FFFFFFF) {
        return reportMode(0);
    }

    // These are GoldenEye's own watch-state fields. Switch away from gameplay
    // semantics as soon as a watch transition begins; waiting for
    // outside_watch_menu to clear allowed the first watch-navigation sample to
    // leak through as a strafe during the opening animation.
    const int32_t watchAnimationState = readGameWord(rdram, playerAddress + 0x1C8);
    const int32_t outsideWatchMenu = readGameWord(rdram, playerAddress + 0x1CC);
    const int32_t openCloseSoloWatchMenu = readGameWord(rdram, playerAddress + 0x1D0);
    return reportMode(
        watchAnimationState == 0 &&
        outsideWatchMenu != 0 &&
        openCloseSoloWatchMenu == 0 ? 1 : 0);
}

extern "C" int32_t goldenpad_recomp_desktop_gameplay_active() {
#if defined(GOLDENPAD_RECOMP_MAC)
    uint8_t *rdram = activeRdram.load(std::memory_order_acquire);
    if (!runtimeStarted.load(std::memory_order_relaxed) || rdram == nullptr) {
        return 0;
    }

    constexpr int32_t kTitleStage = 90;
    const int32_t stage = readGameWord(rdram, 0x80023FA8);
    if (stage == kTitleStage) {
        return 0;
    }

    const int32_t player = readGameWord(rdram, 0x80079EB0);
    const uint32_t playerAddress = static_cast<uint32_t>(player);
    if (playerAddress < 0x80000000 || playerAddress > 0x9FFFFFFF) {
        return 0;
    }

    const int32_t watchLeft = readGameWord(rdram, playerAddress + 0x1C8);
    const int32_t watchOutside = readGameWord(rdram, playerAddress + 0x1CC);
    const int32_t watchRight = readGameWord(rdram, playerAddress + 0x1D0);
    return watchLeft != 0 || watchOutside != 0 || watchRight != 0 ? 1 : 0;
#else
    return 1;
#endif
}

extern "C" void recomp_get_camera_inputs(uint8_t *rdram, recomp_context *ctx) {
    const int32_t controllerNum = _arg<0, int32_t>(rdram, ctx);
    float *xOut = _arg<1, float *>(rdram, ctx);
    float *yOut = _arg<2, float *>(rdram, ctx);
    if (controllerNum < 0 || controllerNum >= static_cast<int32_t>(kControllerPorts)) {
        *xOut = 0.0f;
        *yOut = 0.0f;
        return;
    }
    const size_t port = static_cast<size_t>(controllerNum);
    const bool aiming = (controllerButtons[port].load(std::memory_order_relaxed) & 0x0010u) != 0;
    // Port the working MGB64 controller rate exactly while leaving the tuned
    // relative-touch path unchanged. MGB64 resolves to 1.2 degrees/frame at
    // full hip-fire deflection and about 0.133 degrees/frame while aiming;
    // the recomp gameplay patch applies 3 and 1 degrees respectively.
    const float controllerScale = aiming ? (0.13333334f / 1.0f) : (1.2f / 3.0f);
    float x = static_cast<float>(controllerLookX[port].load(std::memory_order_relaxed)) /
            32'767.0f * controllerScale +
        static_cast<float>(queuedTouchLookX[port].exchange(0, std::memory_order_acq_rel)) / 32'767.0f;
    float y = static_cast<float>(controllerLookY[port].load(std::memory_order_relaxed)) /
            32'767.0f * controllerScale +
        static_cast<float>(queuedTouchLookY[port].exchange(0, std::memory_order_acq_rel)) / 32'767.0f;
    x = std::clamp(x, -1.0f, 1.0f);
    y = std::clamp(y, -1.0f, 1.0f);
    // GoldenEye's sight-aim camera applies the opposite vertical convention
    // from normal free look. Normalize that by default, while retaining an
    // explicit setting for players who prefer inverted aiming.
#if defined(GOLDENPAD_RECOMP_MAC)
    // On Mac the native setting follows its label: normal vertical aim is the
    // default, and enabling "Invert vertical aim" performs the inversion.
    if (aiming && invertAimY.load(std::memory_order_relaxed)) {
#else
    // Preserve the already tuned iPhone/iPad behavior.
    if (aiming && !invertAimY.load(std::memory_order_relaxed)) {
#endif
        y = -y;
    }
    *xOut = x;
    *yOut = y;
}

extern "C" void goldenpad_recomp_consume_crouch_toggle(uint8_t *rdram, recomp_context *ctx) {
    const int32_t controllerNum = _arg<0, int32_t>(rdram, ctx);
    if (controllerNum < 0 || controllerNum >= static_cast<int32_t>(kControllerPorts)) {
        ctx->r2 = 0;
        return;
    }
    ctx->r2 = crouchToggleRequested[controllerNum].exchange(false, std::memory_order_acq_rel) ? 1 : 0;
}

extern "C" void goldenpad_recomp_unlock_all_missions_enabled(uint8_t *, recomp_context *ctx) {
    ctx->r2 = unlockAllMissions.load(std::memory_order_relaxed) ? 1 : 0;
}

extern "C" void goldenpad_recomp_consume_return_to_title(uint8_t *, recomp_context *ctx) {
    const bool requested = returnToTitleRequested.exchange(false, std::memory_order_acq_rel);
    if (requested) {
        logEvent("navigation", "return to main menu consumed on game thread");
    }
    ctx->r2 = requested ? 1 : 0;
}

extern "C" uint32_t goldenpad_recomp_audio_render(float *left, float *right, uint32_t frames) {
    if (left == nullptr || right == nullptr) {
        return 0;
    }
    const uint64_t readFrame = audioReadFrame.load(std::memory_order_relaxed);
    const uint64_t writeFrame = audioWriteFrame.load(std::memory_order_acquire);
    const uint64_t queued = std::min(
        writeFrame - std::min(writeFrame, readFrame), kAudioRingFrames);
    if (!audioPlaybackPrimed) {
        if (queued < kAudioPrebufferFrames) {
            std::fill(left, left + frames, 0.0f);
            std::fill(right, right + frames, 0.0f);
            return 0;
        }
        audioPlaybackPrimed = true;
        audioFadeInFramesRemaining = kAudioFadeFrames;
    }

    if (queued < frames) {
        const uint64_t renderedBefore = audioRenderedFrames.load(std::memory_order_relaxed);
        if (renderedBefore > 0) {
            audioUnderrunFrames.fetch_add(frames - queued, std::memory_order_relaxed);
            audioUnderrunCallbacks.fetch_add(1, std::memory_order_relaxed);
        }
        const uint32_t fadeFrames = std::min(frames, kAudioFadeFrames);
        for (uint32_t frame = 0; frame < fadeFrames; ++frame) {
            const float gain = 1.0f - static_cast<float>(frame + 1) / static_cast<float>(fadeFrames);
            left[frame] = audioLastLeft * gain;
            right[frame] = audioLastRight * gain;
        }
        std::fill(left + fadeFrames, left + frames, 0.0f);
        std::fill(right + fadeFrames, right + frames, 0.0f);
        audioLastLeft = 0.0f;
        audioLastRight = 0.0f;
        audioPlaybackPrimed = false;
        return 0;
    }

    const uint32_t produced = frames;
    uint64_t nonzero = 0;
    for (uint32_t frame = 0; frame < produced; ++frame) {
        const uint64_t source = ((readFrame + frame) % kAudioRingFrames) * 2;
        float gain = 1.0f;
        if (audioFadeInFramesRemaining > 0) {
            gain = 1.0f - static_cast<float>(audioFadeInFramesRemaining) /
                static_cast<float>(kAudioFadeFrames);
            --audioFadeInFramesRemaining;
        }
        left[frame] = static_cast<float>(audioRing[source]) / 32768.0f * gain;
        right[frame] = static_cast<float>(audioRing[source + 1]) / 32768.0f * gain;
        nonzero += audioRing[source] != 0;
        nonzero += audioRing[source + 1] != 0;
    }
    audioLastLeft = left[produced - 1];
    audioLastRight = right[produced - 1];
    audioReadFrame.store(readFrame + produced, std::memory_order_release);
    audioRenderedFrames.fetch_add(produced, std::memory_order_relaxed);
    audioNonzeroSamples.fetch_add(nonzero, std::memory_order_relaxed);
    return produced;
}

extern "C" void goldenpad_recomp_audio_stats(
    uint64_t *queuedFrames, uint64_t *renderedFrames,
    uint64_t *nonzeroSamples, uint64_t *droppedFrames,
    uint64_t *underrunFrames, uint64_t *underrunCallbacks) {
    if (queuedFrames != nullptr) {
        *queuedFrames = getQueuedFrames();
    }
    if (renderedFrames != nullptr) {
        *renderedFrames = audioRenderedFrames.load(std::memory_order_relaxed);
    }
    if (nonzeroSamples != nullptr) {
        *nonzeroSamples = audioNonzeroSamples.load(std::memory_order_relaxed);
    }
    if (droppedFrames != nullptr) {
        *droppedFrames = audioDroppedFrames.load(std::memory_order_relaxed);
    }
    if (underrunFrames != nullptr) {
        *underrunFrames = audioUnderrunFrames.load(std::memory_order_relaxed);
    }
    if (underrunCallbacks != nullptr) {
        *underrunCallbacks = audioUnderrunCallbacks.load(std::memory_order_relaxed);
    }
}

extern "C" void goldenpad_recomp_stop_game() {
#if defined(GOLDENPAD_RECOMP_MAC)
    // N64ModernRuntime's graceful quit path can unmap RDRAM before every
    // emulated OSThread has left game code, while a normal C++ exit runs
    // destructors for process-lifetime joinable runtime threads. Close the
    // diagnostic session, then use the OS process boundary without running
    // either unsafe teardown path.
    logEvent("lifecycle", "native Mac host is terminating");
    markDiagnosticsSessionClean();
    std::fflush(nullptr);
    std::_Exit(EXIT_SUCCESS);
#else
    if (runtimeStarted.load()) {
        logEvent("runtime", "stop requested by UIKit host");
        ultramodern::quit();
    }
#endif
}
