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
#include <condition_variable>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <exception>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <mutex>
#include <os/log.h>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

extern RspUcodeFunc aspMain;
gpr get_entrypoint_address();

#if !defined(GOLDENPAD_RECOMP_MAC)
extern "C" uint64_t goldenpad_rt64_depth_format_rebuild_stats(
    uint64_t *widthChanges,
    uint64_t *sizeChanges,
    uint64_t *rdramChanges,
    uint32_t *latestAddress);
#endif

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
std::array<std::atomic<int64_t>, kControllerPorts> queuedMouseLookX{};
std::array<std::atomic<int64_t>, kControllerPorts> queuedMouseLookY{};
std::array<std::atomic<bool>, kControllerPorts> mouseCameraAimActive{};
std::array<std::atomic<bool>, kControllerPorts> crouchToggleRequested{};
std::array<std::atomic<int32_t>, kControllerPorts> inventorySlotRequested{-1, -1, -1, -1};
std::array<std::atomic<bool>, kControllerPorts> reloadRequested{};
std::atomic<bool> prototypeMsaaEnabled = true;
std::atomic<int32_t> prototypeResolutionMode = 2;
std::atomic<bool> prototypeThreePointFiltering = true;
std::atomic<bool> invertAimY = false;
std::atomic<bool> unlockAllMissions = false;
std::atomic<bool> returnToTitleRequested = false;
std::atomic<bool> appActive = true;
std::atomic<bool> controllerConnected = false;
std::atomic<int32_t> touchInputPort = -1;
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
std::atomic<bool> lifecycleProbeEnabled = false;
std::atomic<bool> audioProbeEnabled = false;
std::atomic<bool> depthRebuildProbeEnabled = false;
std::atomic<bool> determinismProbeEnabled = false;
std::atomic<bool> netplayEnabled = false;
std::atomic<bool> netplayFaulted = false;
std::atomic<int32_t> netplayAssignedSlot = -1;
std::atomic<uint64_t> netplayRoomSeed = 0;
std::atomic<uint64_t> netplayReceivedFrame = 0;
std::atomic<uint64_t> netplayConsumedFrame = 0;
std::atomic<uint64_t> netplayMissingFrames = 0;
std::atomic<uint64_t> netplayChecksumFrame = 0;
std::atomic<uint64_t> netplayChecksum = 0;
std::atomic<bool> netplaySeedApplied = false;
std::atomic<bool> netplayMatchInitialized = false;
std::atomic<bool> determinismProbeComplete = false;
std::atomic<uint64_t> determinismPollCount = 0;
std::atomic<uint64_t> determinismMatchFrame = 0;
std::atomic<uint64_t> determinismViCount = 0;
std::atomic<uint64_t> determinismClockReads = 0;
std::atomic<uint64_t> determinismRoomStartVi = 0;
std::array<std::atomic<uint32_t>, kControllerPorts> determinismButtons{};
std::array<std::atomic<int32_t>, kControllerPorts> determinismStickX{};
std::array<std::atomic<int32_t>, kControllerPorts> determinismStickY{};
std::atomic<uint32_t> audioRequestedFrequency = 0;
std::atomic<uint32_t> audioHostSourceFrequency = 0;
std::atomic<uint32_t> audioHostSessionFrequency = 0;
std::atomic<uint32_t> audioHostMixerFrequency = 0;
std::atomic<uint64_t> audioProbeObservedFrames = 0;
std::atomic<uint64_t> audioProbeLargeJumps = 0;
std::atomic<uint64_t> audioProbeSequenceErrors = 0;
std::atomic<uint64_t> lifecycleProgressSequence = 0;
std::atomic<uint64_t> lifecycleProgressStartedMs = 0;
std::atomic<uint64_t> lifecycleProgressBaselineDisplayLists = 0;
std::atomic<uint64_t> lifecycleProgressBaselineScreenUpdates = 0;
std::atomic<uint64_t> lifecycleProgressBaselinePresented = 0;
std::atomic<int32_t> lifecycleProgressKind = 0;
std::atomic<int32_t> gameplayInputModeReported = -1;
std::atomic<uint64_t> fireRateProbeSimulationTicks = 0;
std::atomic<uint32_t> fireRateProbeRawGuardSamples = 0;
std::mutex statusMutex;
std::mutex diagnosticsMutex;
std::string runtimeStatus = "AOT runtime: waiting for imported user ROM";
std::filesystem::path diagnosticsLogPath;
std::filesystem::path diagnosticsSessionMarkerPath;
std::filesystem::path determinismTracePath;
std::mutex determinismTraceMutex;
std::atomic<bool> previousSessionEndedUnexpectedly = false;
constexpr uintmax_t kDiagnosticsLogLimit = 4 * 1024 * 1024;

constexpr size_t kDeterminismRdramBytes = 8 * 1024 * 1024;
constexpr size_t kDeterminismRegionCount = 8;
constexpr size_t kDeterminismRegionBytes =
    kDeterminismRdramBytes / kDeterminismRegionCount;
constexpr size_t kDeterminismPageBytes = 64 * 1024;
constexpr size_t kDeterminismPageCount =
    kDeterminismRdramBytes / kDeterminismPageBytes;
constexpr size_t kDeterminismBlockBytes = 4 * 1024;
constexpr std::array<size_t, 4> kDeterminismHotPages{2, 5, 6, 59};
constexpr size_t kDeterminismBlocksPerPage =
    kDeterminismPageBytes / kDeterminismBlockBytes;
constexpr size_t kDeterminismHotBlockCount =
    kDeterminismHotPages.size() * kDeterminismBlocksPerPage;
constexpr uint64_t kN64CountTicksPerGamePoll = 781'250;
constexpr uint64_t kDeterminismMaxPoll = 16'000;
constexpr uint64_t kDeterminismInputDelayFrames = 3;
constexpr uint16_t kN64ButtonStart = 0x1000;
constexpr uint16_t kN64ButtonZ = 0x2000;
constexpr uint16_t kN64ButtonCRight = 0x0001;

struct DeterminismInput {
    uint16_t buttons = 0;
    int32_t stickX = 0;
    int32_t stickY = 0;

    bool operator==(const DeterminismInput &) const = default;
};

struct NetplayInput {
    uint16_t buttons = 0;
    int16_t stickX = 0;
    int16_t stickY = 0;
    int16_t lookX = 0;
    int16_t lookY = 0;
    int16_t touchLookX = 0;
    int16_t touchLookY = 0;
    uint16_t crouchSequence = 0;
};

struct NetplayFrame {
    uint64_t number = 0;
    std::array<NetplayInput, kControllerPorts> inputs{};
    bool valid = false;
};

constexpr size_t kNetplayFrameCapacity = 512;
std::array<NetplayFrame, kNetplayFrameCapacity> netplayFrames{};
std::mutex netplayFrameMutex;
std::condition_variable netplayFrameCondition;
std::array<uint16_t, kControllerPorts> netplayCrouchSequences{};

using DeterminismRegionHashes =
    std::array<uint64_t, kDeterminismRegionCount>;
using DeterminismPageHashes =
    std::array<uint64_t, kDeterminismPageCount>;
using DeterminismHotBlockHashes =
    std::array<uint64_t, kDeterminismHotBlockCount>;
using DeterminismInputs = std::array<DeterminismInput, kControllerPorts>;

struct CanonicalStateHashes {
    uint64_t all = 0;
    uint64_t globals = 0;
    uint64_t players = 0;
    uint64_t props = 0;
    int32_t playerCount = 0;
    bool valid = false;
    bool activeMatch = false;

    bool operator==(const CanonicalStateHashes &) const = default;
};

constexpr std::array<uint32_t, 19> kCanonicalGlobalAddresses{
    0x8002A6C0, 0x80023FA8, 0x80048164,
    0x80024260, 0x80024264, 0x8002B340,
    0x80048174, 0x80048178, 0x8004817C,
    0x80048198, 0x8004819C, 0x80048194,
    0x80048180, 0x800481B0, 0x80079EB8,
    0x8008C500, 0x8008C504, 0x8002CA64, 0x8002CA68,
};

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
bool audioProbeHasLastOutput = false;
float audioProbeLastLeft = 0.0f;
float audioProbeLastRight = 0.0f;

constexpr float kAudioProbeJumpThreshold = 0.05f;

uint64_t queryDepthFormatRebuildStats(
    uint64_t *widthChanges,
    uint64_t *sizeChanges,
    uint64_t *rdramChanges,
    uint32_t *latestAddress) {
#if defined(GOLDENPAD_RECOMP_MAC)
    *widthChanges = 0;
    *sizeChanges = 0;
    *rdramChanges = 0;
    *latestAddress = 0;
    return 0;
#else
    return goldenpad_rt64_depth_format_rebuild_stats(
        widthChanges, sizeChanges, rdramChanges, latestAddress);
#endif
}

int16_t audioProbeSample(uint64_t frame) {
    // A 200-frame triangle stays continuous across its wrap and is cheap
    // enough not to perturb the producer/consumer timing being measured.
    constexpr uint64_t period = 200;
    constexpr uint64_t halfPeriod = period / 2;
    constexpr int32_t amplitude = 16'000;
    constexpr int32_t step = amplitude * 2 / static_cast<int32_t>(halfPeriod);
    const uint64_t phase = frame % period;
    const int32_t value = phase < halfPeriod
        ? -amplitude + static_cast<int32_t>(phase) * step
        : amplitude - static_cast<int32_t>(phase - halfPeriod) * step;
    return static_cast<int16_t>(value);
}

bool audioProbeStepIsLarge(float previous, float current) {
    return std::abs(current - previous) > kAudioProbeJumpThreshold;
}

bool audioProbeDetectorSelfTestPasses() {
    return !audioProbeStepIsLarge(0.10f, 0.12f) &&
        audioProbeStepIsLarge(-0.45f, 0.45f);
}

void observeAudioProbeOutput(const float *left, const float *right, uint32_t frames) {
    if (!audioProbeEnabled.load(std::memory_order_relaxed)) { return; }
    uint64_t jumps = 0;
    for (uint32_t frame = 0; frame < frames; ++frame) {
        if (audioProbeHasLastOutput &&
            (audioProbeStepIsLarge(audioProbeLastLeft, left[frame]) ||
                audioProbeStepIsLarge(audioProbeLastRight, right[frame]))) {
            ++jumps;
        }
        audioProbeHasLastOutput = true;
        audioProbeLastLeft = left[frame];
        audioProbeLastRight = right[frame];
    }
    audioProbeObservedFrames.fetch_add(frames, std::memory_order_relaxed);
    audioProbeLargeJumps.fetch_add(jumps, std::memory_order_relaxed);
}

enum class LifecycleProgressState {
    noRuntimeProgress,
    presentationStalled,
    recovered,
};

LifecycleProgressState classifyLifecycleProgress(
    uint64_t displayListDelta,
    uint64_t screenUpdateDelta,
    uint64_t presentedDelta
) {
    if (presentedDelta != 0) {
        return LifecycleProgressState::recovered;
    }
    if (displayListDelta != 0 || screenUpdateDelta != 0) {
        return LifecycleProgressState::presentationStalled;
    }
    return LifecycleProgressState::noRuntimeProgress;
}

bool lifecycleProgressClassifierProbePasses() {
    return classifyLifecycleProgress(0, 0, 0) == LifecycleProgressState::noRuntimeProgress &&
        classifyLifecycleProgress(0, 12, 0) == LifecycleProgressState::presentationStalled &&
        classifyLifecycleProgress(12, 12, 12) == LifecycleProgressState::recovered;
}

const char *lifecycleProgressStateName(LifecycleProgressState state) {
    switch (state) {
    case LifecycleProgressState::noRuntimeProgress: return "no-runtime-progress";
    case LifecycleProgressState::presentationStalled: return "presentation-stalled";
    case LifecycleProgressState::recovered: return "recovered";
    }
    return "unknown";
}

uint64_t monotonicMilliseconds() {
    return static_cast<uint64_t>(std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::steady_clock::now().time_since_epoch()).count());
}

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

int32_t readGameWord(uint8_t *rdram, uint32_t address);

DeterminismInputs determinismInputsForStep(uint64_t poll, uint64_t matchFrame) {
    DeterminismInputs inputs{};

    // This is ordinary controller input only. Start traverses the stock front
    // end, negative Y selects Multiplayer, and Start launches the stock default
    // four-player match. The schedule never reads game state, so every process
    // receives exactly the same four port streams even after a divergence.
    if (poll >= 60 && poll <= 780 && (poll - 60) % 120 < 2) {
        inputs[0].buttons |= kN64ButtonStart;
    }
    if (poll >= 820 && poll < 880) {
        inputs[0].stickY = -64;
    }
    if ((poll >= 900 && poll < 902) || (poll >= 1'020 && poll < 1'022)) {
        inputs[0].buttons |= kN64ButtonStart;
    }

    // Distinct, overlapping gameplay windows prove that all four logical ports
    // affect the same simulation rather than merely reporting as connected.
    if (matchFrame >= 360 && matchFrame < 840) {
        inputs[0].stickY = 64;
    }
    if (matchFrame >= 600 && matchFrame < 1'080) {
        inputs[1].stickY = 48;
        inputs[1].stickX = 32;
    }
    if (matchFrame >= 840 && matchFrame < 1'320) {
        inputs[2].stickY = -48;
        inputs[2].stickX = -32;
    }
    if (matchFrame >= 1'080 && matchFrame < 1'560) {
        inputs[3].stickY = 40;
        inputs[3].stickX = -40;
    }
    if (matchFrame >= 960 && matchFrame < 1'080) {
        inputs[0].buttons |= kN64ButtonCRight;
    }
    if (matchFrame >= 1'320 && matchFrame < 1'440) {
        inputs[1].buttons |= kN64ButtonCRight;
    }
    if (matchFrame >= 1'680 && matchFrame < 1'740) {
        inputs[0].buttons |= kN64ButtonZ;
        inputs[2].buttons |= kN64ButtonZ;
    }
    return inputs;
}

DeterminismInputs determinismBufferedInputsForStep(
    uint64_t poll, uint64_t matchFrame) {
    if (matchFrame == 0) {
        return determinismInputsForStep(poll, 0);
    }
    const uint64_t sourceFrame = matchFrame > kDeterminismInputDelayFrames
        ? matchFrame - kDeterminismInputDelayFrames
        : 0;
    return determinismInputsForStep(poll, sourceFrame);
}

void appendCanonicalWord(std::vector<uint8_t> &output, uint8_t *rdram, uint32_t address) {
    const uint32_t value = static_cast<uint32_t>(readGameWord(rdram, address));
    for (uint32_t shift = 0; shift < 32; shift += 8) {
        output.push_back(static_cast<uint8_t>(value >> shift));
    }
}

bool appendCanonicalRange(
    std::vector<uint8_t> &output,
    const uint8_t *rdram,
    uint32_t address,
    size_t length
) {
    if (address < 0x80000000 || address >= 0x80800000) {
        return false;
    }
    const size_t offset = static_cast<size_t>(address - 0x80000000);
    if (length > kDeterminismRdramBytes - offset) {
        return false;
    }
    output.insert(output.end(), rdram + offset, rdram + offset + length);
    return true;
}

CanonicalStateHashes hashCanonicalState(uint8_t *rdram) {
    // Version 1 is intentionally conservative: it contains source-owned game
    // state and excludes RT64 buffers, audio queues, OS/runtime bookkeeping,
    // and PropRecord::zDepth (a renderer-computed field).
    constexpr std::array<uint32_t, 39> playerWordOffsets{
        0x000, 0x004, 0x008, 0x00C, 0x010, 0x014, 0x018,
        0x01C, 0x020, 0x024, 0x028, 0x02C, 0x030,
        0x038, 0x03C, 0x040, 0x044, 0x048, 0x04C,
        0x050, 0x054, 0x058, 0x09C, 0x0A0, 0x0A8,
        0x0D8, 0x0DC, 0x0E0, 0x148, 0x158,
        0x16C, 0x170, 0x174, 0x178, 0x3B4, 0x3B8,
        0x408, 0x414, 0x418,
    };
    constexpr uint32_t playerPointersAddress = 0x80079CE0;
    constexpr uint32_t playerDataAddress = 0x80079CF0;
    constexpr size_t playerDataBytes = 4 * 0x70;
    constexpr uint32_t propsAddress = 0x80069A38;
    constexpr size_t propCount = 600;
    constexpr size_t propBytes = 0x34;

    std::vector<uint8_t> globals;
    std::vector<uint8_t> players;
    std::vector<uint8_t> props;
    globals.reserve(kCanonicalGlobalAddresses.size() * sizeof(uint32_t));
    players.reserve(playerDataBytes + 4 * playerWordOffsets.size() * sizeof(uint32_t));
    props.reserve(propCount * (propBytes - sizeof(uint32_t)));

    for (const uint32_t address : kCanonicalGlobalAddresses) {
        appendCanonicalWord(globals, rdram, address);
    }

    CanonicalStateHashes result{};
    result.valid = appendCanonicalRange(players, rdram, playerDataAddress, playerDataBytes);
    for (size_t port = 0; port < kControllerPorts; ++port) {
        const uint32_t playerAddress = static_cast<uint32_t>(
            readGameWord(rdram, playerPointersAddress + static_cast<uint32_t>(port * 4)));
        if (playerAddress == 0) {
            continue;
        }
        ++result.playerCount;
        if (playerAddress < 0x80000000 || playerAddress > 0x807FD580) {
            result.valid = false;
            continue;
        }
        for (const uint32_t offset : playerWordOffsets) {
            appendCanonicalWord(players, rdram, playerAddress + offset);
        }
    }
    for (size_t prop = 0; prop < propCount; ++prop) {
        const uint32_t address = propsAddress + static_cast<uint32_t>(prop * propBytes);
        result.valid = appendCanonicalRange(props, rdram, address, 0x18) && result.valid;
        result.valid = appendCanonicalRange(props, rdram, address + 0x1C, 0x18) && result.valid;
    }

    result.globals = XXH3_64bits(globals.data(), globals.size());
    result.players = XXH3_64bits(players.data(), players.size());
    result.props = XXH3_64bits(props.data(), props.size());
    const std::array<uint64_t, 3> componentHashes{
        result.globals, result.players, result.props,
    };
    result.all = XXH3_64bits(componentHashes.data(), sizeof(componentHashes));
    const int32_t menu = readGameWord(rdram, 0x8002A6C0);
    const int32_t stage = readGameWord(rdram, 0x80023FA8);
    const int32_t pending = readGameWord(rdram, 0x80048164);
    result.activeMatch = result.valid && menu == 11 && stage != 90 &&
        pending == stage && result.playerCount >= 2;
    return result;
}

DeterminismRegionHashes hashDeterminismRegions(const uint8_t *rdram) {
    DeterminismRegionHashes hashes{};
    for (size_t region = 0; region < hashes.size(); ++region) {
        hashes[region] = XXH3_64bits(
            rdram + region * kDeterminismRegionBytes,
            kDeterminismRegionBytes);
    }
    return hashes;
}

DeterminismPageHashes hashDeterminismPages(const uint8_t *rdram) {
    DeterminismPageHashes hashes{};
    for (size_t page = 0; page < hashes.size(); ++page) {
        hashes[page] = XXH3_64bits(
            rdram + page * kDeterminismPageBytes,
            kDeterminismPageBytes);
    }
    return hashes;
}

DeterminismHotBlockHashes hashDeterminismHotBlocks(const uint8_t *rdram) {
    DeterminismHotBlockHashes hashes{};
    size_t output = 0;
    for (const size_t page : kDeterminismHotPages) {
        for (size_t block = 0; block < kDeterminismBlocksPerPage; ++block) {
            const size_t offset = page * kDeterminismPageBytes +
                block * kDeterminismBlockBytes;
            hashes[output++] = XXH3_64bits(
                rdram + offset, kDeterminismBlockBytes);
        }
    }
    return hashes;
}

uint64_t foldDeterminismRegions(const DeterminismRegionHashes &hashes) {
    return XXH3_64bits(hashes.data(), hashes.size() * sizeof(hashes[0]));
}

bool shouldSampleDeterminismPoll(
    uint64_t poll,
    uint64_t matchFrame,
    const DeterminismInputs &inputs,
    const DeterminismInputs &previousInputs
) {
    return poll <= 240 || (matchFrame != 0 &&
        (matchFrame <= 120 || matchFrame % 30 == 0)) ||
        (matchFrame == 0 && poll % 30 == 0) || inputs != previousInputs ||
        poll == kDeterminismMaxPoll;
}

void writeDeterminismSample(
    uint64_t poll,
    uint64_t matchFrame,
    const DeterminismInputs &inputs,
    uint8_t *rdram
) {
    if (rdram == nullptr || determinismTracePath.empty()) {
        return;
    }

    // Two immediate reads distinguish a cross-run mismatch from an unsafe
    // observation seam that changed while it was being hashed.
    const CanonicalStateHashes canonicalFirst = hashCanonicalState(rdram);
    const DeterminismRegionHashes first = hashDeterminismRegions(rdram);
    const DeterminismPageHashes pages = hashDeterminismPages(rdram);
    const DeterminismHotBlockHashes hotBlocks = hashDeterminismHotBlocks(rdram);
    const DeterminismRegionHashes second = hashDeterminismRegions(rdram);
    const CanonicalStateHashes canonicalSecond = hashCanonicalState(rdram);
    const bool memoryStable = first == second;
    const bool stable = canonicalFirst == canonicalSecond;
    const uint64_t stateHash = foldDeterminismRegions(second);
    const uint64_t vi = determinismViCount.load(std::memory_order_acquire);
    const int32_t menu = readGameWord(rdram, 0x8002A6C0);
    const int32_t stage = readGameWord(rdram, 0x80023FA8);
    const int32_t pending = readGameWord(rdram, 0x80048164);

    std::ostringstream line;
    line << "SAMPLE poll=" << std::dec << poll
         << " match_frame=" << matchFrame
         << " vi=" << vi
         << " clock_reads="
         << determinismClockReads.load(std::memory_order_acquire)
         << " stable=" << (stable ? 1 : 0)
         << " memory_stable=" << (memoryStable ? 1 : 0)
         << " inputs=";
    for (size_t port = 0; port < inputs.size(); ++port) {
        if (port != 0) {
            line << ';';
        }
        line << std::hex << std::setw(4) << std::setfill('0')
             << inputs[port].buttons << std::dec
             << ',' << inputs[port].stickX << ',' << inputs[port].stickY;
    }
    line << " players=" << canonicalSecond.playerCount
         << " canonical_valid=" << (canonicalSecond.valid ? 1 : 0)
         << " active_match=" << (canonicalSecond.activeMatch ? 1 : 0)
         << " menu=" << menu
         << " stage=" << stage
         << " pending=" << pending
         << " canonical=" << std::hex << std::setw(16) << std::setfill('0')
         << canonicalSecond.all
         << " canonical_globals=" << std::setw(16) << canonicalSecond.globals
         << " canonical_players=" << std::setw(16) << canonicalSecond.players
         << " canonical_props=" << std::setw(16) << canonicalSecond.props
         << " global_words=";
    for (size_t index = 0; index < kCanonicalGlobalAddresses.size(); ++index) {
        if (index != 0) {
            line << ',';
        }
        line << std::hex << std::setw(8) << std::setfill('0')
             << static_cast<uint32_t>(readGameWord(
                    rdram, kCanonicalGlobalAddresses[index]));
    }
    line
         << " hash=" << std::hex << std::setw(16) << std::setfill('0')
         << stateHash
         << " regions=";
    for (size_t region = 0; region < second.size(); ++region) {
        if (region != 0) {
            line << ',';
        }
        line << std::hex << std::setw(16) << std::setfill('0') << second[region];
    }
    line << " pages=";
    for (size_t page = 0; page < pages.size(); ++page) {
        if (page != 0) {
            line << ',';
        }
        line << std::hex << std::setw(16) << std::setfill('0') << pages[page];
    }
    line << " hotblocks=";
    for (size_t block = 0; block < hotBlocks.size(); ++block) {
        if (block != 0) {
            line << ',';
        }
        line << std::hex << std::setw(16) << std::setfill('0') << hotBlocks[block];
    }

    std::lock_guard lock(determinismTraceMutex);
    std::ofstream trace(determinismTracePath, std::ios::app);
    trace << line.str() << '\n';
}

void completeDeterminismTrace(uint64_t poll) {
    if (determinismProbeComplete.exchange(true, std::memory_order_acq_rel) ||
        determinismTracePath.empty()) {
        return;
    }
    {
        std::lock_guard lock(determinismTraceMutex);
        std::ofstream trace(determinismTracePath, std::ios::app);
        trace << "COMPLETE poll=" << poll << '\n';
    }
    logEvent("determinism-probe",
        "complete poll=%llu vi=%llu trace=%s",
        static_cast<unsigned long long>(poll),
        static_cast<unsigned long long>(
            determinismViCount.load(std::memory_order_relaxed)),
        determinismTracePath.filename().string().c_str());
}

void determinismViCallback() {
    if (determinismProbeEnabled.load(std::memory_order_relaxed) ||
        netplayEnabled.load(std::memory_order_relaxed)) {
        determinismViCount.fetch_add(1, std::memory_order_release);
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
    if (lifecycleProbeEnabled.load(std::memory_order_relaxed)) {
        log << "[GoldenPadRecomp] lifecycle-probe: classifier="
            << (lifecycleProgressClassifierProbePasses() ? "PASS" : "FAIL") << '\n';
    }
    if (audioProbeEnabled.load(std::memory_order_relaxed)) {
        log << "[GoldenPadRecomp] audio-probe: detector="
            << (audioProbeDetectorSelfTestPasses() ? "PASS" : "FAIL") << '\n';
    }
    if (depthRebuildProbeEnabled.load(std::memory_order_relaxed)) {
        uint64_t widthChanges = 0;
        uint64_t sizeChanges = 0;
        uint64_t rdramChanges = 0;
        uint32_t latestAddress = 0;
        const uint64_t rebuilds = queryDepthFormatRebuildStats(
            &widthChanges, &sizeChanges, &rdramChanges, &latestAddress);
        log << "[GoldenPadRecomp] depth-rebuild-probe: counter=READY"
            << " baseline=" << rebuilds
            << " causes=(width=" << widthChanges
            << " size=" << sizeChanges
            << " rdram=" << rdramChanges << ')'
            << " latest=0x" << std::hex << latestAddress << std::dec << '\n';
    }
    if (determinismProbeEnabled.load(std::memory_order_relaxed)) {
        determinismTracePath = directory / "goldenpad-determinism-trace-v14.log";
        determinismPollCount.store(0, std::memory_order_relaxed);
        determinismMatchFrame.store(0, std::memory_order_relaxed);
        determinismViCount.store(0, std::memory_order_relaxed);
        determinismClockReads.store(0, std::memory_order_relaxed);
        determinismRoomStartVi.store(0, std::memory_order_relaxed);
        determinismProbeComplete.store(false, std::memory_order_relaxed);
        for (size_t port = 0; port < kControllerPorts; ++port) {
            determinismButtons[port].store(0, std::memory_order_relaxed);
            determinismStickX[port].store(0, std::memory_order_relaxed);
            determinismStickY[port].store(0, std::memory_order_relaxed);
        }
        std::lock_guard traceLock(determinismTraceMutex);
        std::ofstream trace(determinismTracePath, std::ios::trunc);
        trace << "GOLDENPAD_DETERMINISM_TRACE_V14"
              << " base_bytes=" << kDeterminismRdramBytes
              << " region_bytes=" << kDeterminismRegionBytes
              << " regions=" << kDeterminismRegionCount
              << " page_bytes=" << kDeterminismPageBytes
              << " pages=" << kDeterminismPageCount
              << " hot_pages=2,5,6,59"
              << " hot_block_bytes=" << kDeterminismBlockBytes
              << " script=stock-four-player-fixed-delay-v8"
              << " canonical=ge-source-owned-v1"
              << " clock=room-relative-vi-v8"
              << " scheduler=fixed-game-frame-direct-input-v8"
              << " input_delay_frames=" << kDeterminismInputDelayFrames
              << " max_poll=" << kDeterminismMaxPoll << '\n';
        log << "[GoldenPadRecomp] determinism-probe: READY read-only=1 "
            << "liveInputOverride=1 maxPoll=" << kDeterminismMaxPoll << '\n';
    } else {
        determinismTracePath.clear();
    }
}

void startLifecycleProgressWindow(int32_t kind, const char *kindName) {
    if (!lifecycleProbeEnabled.load(std::memory_order_relaxed)) { return; }
    const uint64_t displayLists = rt64DisplayListCount.load(std::memory_order_relaxed);
    const uint64_t screenUpdates = rt64ScreenUpdateCount.load(std::memory_order_relaxed);
    const uint64_t presented = rt64PresentedCount.load(std::memory_order_relaxed);
    lifecycleProgressBaselineDisplayLists.store(displayLists, std::memory_order_relaxed);
    lifecycleProgressBaselineScreenUpdates.store(screenUpdates, std::memory_order_relaxed);
    lifecycleProgressBaselinePresented.store(presented, std::memory_order_relaxed);
    lifecycleProgressStartedMs.store(monotonicMilliseconds(), std::memory_order_relaxed);
    lifecycleProgressKind.store(kind, std::memory_order_relaxed);
    const uint64_t sequence = lifecycleProgressSequence.fetch_add(1, std::memory_order_release) + 1;
    logEvent("lifecycle-progress",
        "sequence=%llu transition=%s baseline=(dl=%llu vi=%llu presented=%llu)",
        static_cast<unsigned long long>(sequence), kindName,
        static_cast<unsigned long long>(displayLists),
        static_cast<unsigned long long>(screenUpdates),
        static_cast<unsigned long long>(presented));
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
constexpr uint32_t kFireRateMinimumMagazineEvents = 15;
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

void completePlayerFireRateWindow(const char *reason) {
    logEvent("fire-rate-probe",
        "player run=%u complete reason=%s ticks=%u weapon=%d events=%u ammo=%d->%d counter=%d->%d",
        playerFireRateWindow.runs + 1,
        reason,
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
    uint64_t observedLifecycleSequence = 0;
    uint64_t nextLifecycleSampleMs = 0;
    int lifecycleProgressSamples = 0;
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
        if (lifecycleProbeEnabled.load(std::memory_order_relaxed) && active) {
            const uint64_t sequence = lifecycleProgressSequence.load(std::memory_order_acquire);
            if (sequence != observedLifecycleSequence) {
                observedLifecycleSequence = sequence;
                lifecycleProgressSamples = 0;
                nextLifecycleSampleMs = lifecycleProgressStartedMs.load(
                    std::memory_order_relaxed) + 2'000;
            }
            const uint64_t nowMs = monotonicMilliseconds();
            if (sequence != 0 && lifecycleProgressSamples < 5 &&
                nowMs >= nextLifecycleSampleMs) {
                const uint64_t displayListDelta = displayLists -
                    lifecycleProgressBaselineDisplayLists.load(std::memory_order_relaxed);
                const uint64_t screenUpdateDelta = screenUpdates -
                    lifecycleProgressBaselineScreenUpdates.load(std::memory_order_relaxed);
                const uint64_t presentedDelta = presented -
                    lifecycleProgressBaselinePresented.load(std::memory_order_relaxed);
                const LifecycleProgressState progress = classifyLifecycleProgress(
                    displayListDelta, screenUpdateDelta, presentedDelta);
                const int32_t kind = lifecycleProgressKind.load(std::memory_order_relaxed);
                const uint64_t ageMs = nowMs -
                    lifecycleProgressStartedMs.load(std::memory_order_relaxed);
                logEvent("lifecycle-progress",
                    "sequence=%llu transition=%s ageMs=%llu delta=(dl=%llu vi=%llu presented=%llu) state=%s sample=%d/5",
                    static_cast<unsigned long long>(sequence),
                    kind == 1 ? "transient-inactive" : "foreground-resume",
                    static_cast<unsigned long long>(ageMs),
                    static_cast<unsigned long long>(displayListDelta),
                    static_cast<unsigned long long>(screenUpdateDelta),
                    static_cast<unsigned long long>(presentedDelta),
                    lifecycleProgressStateName(progress), lifecycleProgressSamples + 1);
                ++lifecycleProgressSamples;
                nextLifecycleSampleMs += 2'000;
                if (progress == LifecycleProgressState::recovered || ageMs >= 10'000) {
                    lifecycleProgressSamples = 5;
                }
            }
        }
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
                        (controllerConnected.load(std::memory_order_relaxed) ? "external-p1" :
                            (touchInputPort.load(std::memory_order_relaxed) == 0 ?
                                "touch-p1" : "neutral-awaiting-controller"))),
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
            if (audioProbeEnabled.load(std::memory_order_relaxed)) {
                logEvent("audio-probe",
                    "observedFrames=%llu largeJumps=%llu sequenceErrors=%llu",
                    static_cast<unsigned long long>(
                        audioProbeObservedFrames.load(std::memory_order_relaxed)),
                    static_cast<unsigned long long>(
                        audioProbeLargeJumps.load(std::memory_order_relaxed)),
                    static_cast<unsigned long long>(
                        audioProbeSequenceErrors.load(std::memory_order_relaxed)));
            }
            if (depthRebuildProbeEnabled.load(std::memory_order_relaxed)) {
                uint64_t widthChanges = 0;
                uint64_t sizeChanges = 0;
                uint64_t rdramChanges = 0;
                uint32_t latestAddress = 0;
                const uint64_t rebuilds = queryDepthFormatRebuildStats(
                    &widthChanges, &sizeChanges, &rdramChanges, &latestAddress);
                logEvent("depth-rebuild-probe",
                    "total=%llu causes=(width=%llu size=%llu rdram=%llu) latest=0x%08X",
                    static_cast<unsigned long long>(rebuilds),
                    static_cast<unsigned long long>(widthChanges),
                    static_cast<unsigned long long>(sizeChanges),
                    static_cast<unsigned long long>(rdramChanges), latestAddress);
            }
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
    const bool probeEnabled = audioProbeEnabled.load(std::memory_order_relaxed);
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
        if (probeEnabled) {
            const int16_t probeSample = audioProbeSample(writeFrame + frame);
            audioRing[destination] = probeSample;
            audioRing[destination + 1] = static_cast<int16_t>(-probeSample);
        } else {
            audioRing[destination] = samples[frame * 2 + 1];
            audioRing[destination + 1] = samples[frame * 2];
        }
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
    audioRequestedFrequency.store(frequency, std::memory_order_relaxed);
    logEvent("audio", "game requested %u Hz output", frequency);
    const uint32_t source = audioHostSourceFrequency.load(std::memory_order_relaxed);
    if (source != 0) {
        logEvent("audio-rates", "requested=%u source=%u session=%u mixer=%u",
            frequency, source,
            audioHostSessionFrequency.load(std::memory_order_relaxed),
            audioHostMixerFrequency.load(std::memory_order_relaxed));
    }
}
bool determinismMatchIsReady(uint8_t *rdram) {
    if (rdram == nullptr || readGameWord(rdram, 0x8002A6C0) != 11 ||
        readGameWord(rdram, 0x80023FA8) == 90 ||
        readGameWord(rdram, 0x80048164) != readGameWord(rdram, 0x80023FA8)) {
        return false;
    }
    int players = 0;
    for (uint32_t port = 0; port < kControllerPorts; ++port) {
        if (readGameWord(rdram, 0x80079CE0 + port * 4) != 0) {
            ++players;
        }
    }
    return players >= 2;
}

void applyNetplayRoomSeed(uint8_t *rdram) {
    if (rdram == nullptr || netplaySeedApplied.exchange(true)) {
        return;
    }
    const uint64_t seed = netplayRoomSeed.load(std::memory_order_acquire);
    uint32_t first = static_cast<uint32_t>(seed);
    uint32_t second = static_cast<uint32_t>(seed >> 32);
    if (first == 0) {
        first = 1;
    }
    if (second == 0) {
        second = first ^ 0xD872B41C;
    }
    writeGameWord(rdram, 0x80024260, static_cast<int32_t>(first));
    writeGameWord(rdram, 0x80024264, static_cast<int32_t>(second));
    logEvent("netplay", "applied synchronized room seed");
}

void initializeNetplayMatchClock(uint8_t *rdram) {
    if (!determinismMatchIsReady(rdram) || netplayMatchInitialized.exchange(true)) {
        return;
    }
    const uint64_t roomStartVi = determinismViCount.load(std::memory_order_acquire);
    determinismRoomStartVi.store(roomStartVi, std::memory_order_release);
    constexpr uint32_t roomEpochCount = static_cast<uint32_t>(
        4'096 * kN64CountTicksPerGamePoll);
    writeGameWord(rdram, 0x80048290, -1);
    writeGameWord(rdram, 0x80048294, 0);
    writeGameWord(rdram, 0x80048298, 1);
    writeGameWord(rdram, 0x8004829C, -1);
    writeGameWord(rdram, 0x800482A0, 0);
    writeGameWord(rdram, 0x800482A4, 0);
    writeGameWord(rdram, 0x800482A8, 0);
    writeGameWord(rdram, 0x800482AC, roomEpochCount);
    writeGameWord(rdram, 0x800482B0, roomEpochCount);
    writeGameWord(rdram, 0x800482B4, 1);
    writeGameWord(rdram, 0x80048194, 0);
    writeGameWord(rdram, 0x800481A4, 0);
    writeGameWord(rdram, 0x800481A8, 0);
    writeGameWord(rdram, 0x800481AC, 0);
    writeGameWord(rdram, 0x800481B0, 0);
    writeGameWord(rdram, 0x800481B4, 0);
    logEvent("netplay", "stock multiplayer match clock synchronized");
}

void pollNetplayInput(uint8_t *rdram) {
    if (netplayFaulted.load(std::memory_order_acquire)) {
        return;
    }
    applyNetplayRoomSeed(rdram);
    initializeNetplayMatchClock(rdram);

    const uint64_t expected =
        netplayConsumedFrame.load(std::memory_order_acquire) + 1;
    NetplayFrame ordered{};
    {
        std::unique_lock lock(netplayFrameMutex);
        const bool available = netplayFrameCondition.wait_for(
            lock, std::chrono::seconds(2), [expected] {
                const NetplayFrame &candidate =
                    netplayFrames[expected % kNetplayFrameCapacity];
                return !netplayEnabled.load(std::memory_order_acquire) ||
                    (candidate.valid && candidate.number == expected &&
                     netplayReceivedFrame.load(std::memory_order_acquire) >=
                        expected + kDeterminismInputDelayFrames);
            });
        if (!netplayEnabled.load(std::memory_order_acquire)) {
            return;
        }
        NetplayFrame &candidate = netplayFrames[expected % kNetplayFrameCapacity];
        if (!available || !candidate.valid || candidate.number != expected) {
            netplayMissingFrames.fetch_add(1, std::memory_order_relaxed);
            netplayFaulted.store(true, std::memory_order_release);
            logEvent("netplay", "missing authoritative frame %llu; simulation paused",
                static_cast<unsigned long long>(expected));
            return;
        }
        ordered = candidate;
        candidate.valid = false;
    }

    if (rdram != nullptr && expected % 30 == 0) {
        const CanonicalStateHashes canonical = hashCanonicalState(rdram);
        if (canonical.valid) {
            netplayChecksum.store(canonical.all, std::memory_order_release);
            netplayChecksumFrame.store(expected, std::memory_order_release);
        }
    }
    for (size_t port = 0; port < kControllerPorts; ++port) {
        const NetplayInput &input = ordered.inputs[port];
        controllerButtons[port].store(input.buttons, std::memory_order_release);
        controllerStickX[port].store(input.stickX, std::memory_order_release);
        controllerStickY[port].store(input.stickY, std::memory_order_release);
        controllerLookX[port].store(input.lookX, std::memory_order_release);
        controllerLookY[port].store(input.lookY, std::memory_order_release);
        queuedTouchLookX[port].store(input.touchLookX, std::memory_order_release);
        queuedTouchLookY[port].store(input.touchLookY, std::memory_order_release);
        if (input.crouchSequence != 0 &&
            input.crouchSequence != netplayCrouchSequences[port]) {
            netplayCrouchSequences[port] = input.crouchSequence;
            crouchToggleRequested[port].store(true, std::memory_order_release);
        }
    }
    netplayConsumedFrame.store(expected, std::memory_order_release);
}

void pollInput() {
    if (!inputPollReported.exchange(true)) {
        logEvent("input", "game began polling the prototype controller bridge");
    }
    if (netplayEnabled.load(std::memory_order_acquire)) {
        pollNetplayInput(activeRdram.load(std::memory_order_acquire));
        return;
    }
    if (!determinismProbeEnabled.load(std::memory_order_acquire) ||
        determinismProbeComplete.load(std::memory_order_relaxed)) {
        return;
    }

    static DeterminismInputs previousInputs{};
    const uint64_t poll =
        determinismPollCount.fetch_add(1, std::memory_order_acq_rel) + 1;
    uint8_t *rdram = activeRdram.load(std::memory_order_acquire);
    if (poll == 1'020 && rdram != nullptr &&
        readGameWord(rdram, 0x8002A6C0) == 14) {
        // This is the synchronized room-launch boundary, immediately before
        // the scripted Start edge asks stock GoldenEye to create the match.
        writeGameWord(rdram, 0x80024260, 0x00000001);
        writeGameWord(rdram, 0x80024264, 0xD872B41C);
        const uint64_t roomStartVi = determinismViCount.load(
            std::memory_order_acquire);
        determinismRoomStartVi.store(roomStartVi, std::memory_order_release);
        constexpr uint32_t roomEpochCount = static_cast<uint32_t>(
            4'096 * kN64CountTicksPerGamePoll);
        writeGameWord(rdram, 0x80048290, -1); // lastFrameCounter
        writeGameWord(rdram, 0x80048294, 0);  // currentFrameCounter
        writeGameWord(rdram, 0x80048298, 1);  // speedgraphframes
        writeGameWord(rdram, 0x8004829C, -1); // previousFrameCounter
        writeGameWord(rdram, 0x800482A0, 0);  // halfFrameCounter
        writeGameWord(rdram, 0x800482A4, 0);  // isFrameCounterOdd
        writeGameWord(rdram, 0x800482A8, 0);  // halfMinusPreviousCounter
        writeGameWord(rdram, 0x800482AC, roomEpochCount);
        writeGameWord(rdram, 0x800482B0, roomEpochCount);
        writeGameWord(rdram, 0x800482B4, 1);  // frameDelay
        writeGameWord(rdram, 0x80048194, 0);  // multiplayer seconds ticks
        writeGameWord(rdram, 0x800481A4, 0);  // displayed seconds
        writeGameWord(rdram, 0x800481A8, 0);  // multiplayer minutes ticks
        writeGameWord(rdram, 0x800481AC, 0);  // displayed minutes
        writeGameWord(rdram, 0x800481B0, 0);  // active stage ticks
        writeGameWord(rdram, 0x800481B4, 0);  // displayed stage time
    }
    uint64_t matchFrame = 0;
    if (determinismMatchIsReady(rdram)) {
        // pollInput runs immediately before lvlManageMpGame consumes this
        // controller sample. g_GlobalTimer is therefore the completed logical
        // frame count, and +1 identifies the simulation frame these inputs
        // will drive. Host poll cadence is deliberately not part of the room
        // protocol.
        const int32_t completedFrame = readGameWord(rdram, 0x8004817C);
        matchFrame = completedFrame >= 0
            ? static_cast<uint64_t>(completedFrame) + 1
            : 1;
        determinismMatchFrame.store(matchFrame, std::memory_order_release);
    }
    const DeterminismInputs inputs = determinismBufferedInputsForStep(poll, matchFrame);
    for (size_t port = 0; port < kControllerPorts; ++port) {
        determinismButtons[port].store(inputs[port].buttons, std::memory_order_release);
        determinismStickX[port].store(inputs[port].stickX, std::memory_order_release);
        determinismStickY[port].store(inputs[port].stickY, std::memory_order_release);
    }

    if (shouldSampleDeterminismPoll(poll, matchFrame, inputs, previousInputs)) {
        writeDeterminismSample(
            poll, matchFrame, inputs, rdram);
    }
    previousInputs = inputs;
    if (poll >= kDeterminismMaxPoll) {
        completeDeterminismTrace(poll);
    }
}
bool getInput(int controllerNum, uint16_t *buttons, float *x, float *y) {
    const bool portAvailable = controllerNum >= 0 && controllerNum < 4 &&
        (netplayEnabled.load(std::memory_order_relaxed) ||
            determinismProbeEnabled.load(std::memory_order_relaxed) ||
            controllerNum == 0 ||
            (controllerNum == 1 && twoPlayerTestMode.load(std::memory_order_relaxed)) ||
            (controllerNum >= 2 && fourPlayerTestMode.load(std::memory_order_relaxed)));
    if (!portAvailable || buttons == nullptr || x == nullptr || y == nullptr) {
        const uint8_t reportBit = controllerNum >= 0 && controllerNum < 4
            ? static_cast<uint8_t>(1u << controllerNum)
            : static_cast<uint8_t>(1u << 4);
        if ((invalidInputPortsReported.fetch_or(reportBit) & reportBit) == 0) {
            logEvent("input", "controller port %d has no prototype input source", controllerNum + 1);
        }
        return false;
    }
    if (determinismProbeEnabled.load(std::memory_order_acquire)) {
        const size_t port = static_cast<size_t>(controllerNum);
        DeterminismInputs inputs{};
        uint8_t *rdram = activeRdram.load(std::memory_order_acquire);
        if (determinismMatchIsReady(rdram)) {
            const int32_t completedFrame = readGameWord(rdram, 0x8004817C);
            const uint64_t logicalFrame = completedFrame >= 0
                ? static_cast<uint64_t>(completedFrame) + 1
                : 1;
            inputs = determinismBufferedInputsForStep(
                determinismPollCount.load(std::memory_order_acquire),
                logicalFrame);
            *buttons = inputs[port].buttons;
            *x = static_cast<float>(inputs[port].stickX) / 80.0f;
            *y = static_cast<float>(inputs[port].stickY) / 80.0f;
        } else {
            *buttons = static_cast<uint16_t>(
                determinismButtons[port].load(std::memory_order_acquire));
            *x = static_cast<float>(
                determinismStickX[port].load(std::memory_order_acquire)) / 80.0f;
            *y = static_cast<float>(
                determinismStickY[port].load(std::memory_order_acquire)) / 80.0f;
        }
        return true;
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
    const bool portAvailable = controllerNum >= 0 && controllerNum < 4 &&
        (netplayEnabled.load(std::memory_order_relaxed) ||
            determinismProbeEnabled.load(std::memory_order_relaxed) ||
            controllerNum == 0 ||
            (controllerNum == 1 && twoPlayerTestMode.load(std::memory_order_relaxed)) ||
            (controllerNum >= 2 && fourPlayerTestMode.load(std::memory_order_relaxed)));
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
        ultramodern::events::callbacks_t eventCallbacks{
            .vi_callback = determinismViCallback,
        };
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
    const int32_t normalizedStickX = std::clamp(stickX, -80, 80);
    const int32_t normalizedStickY = std::clamp(stickY, -80, 80);
    const int32_t previousStickX = controllerStickX[port].exchange(
        normalizedStickX, std::memory_order_relaxed);
    const int32_t previousStickY = controllerStickY[port].exchange(
        normalizedStickY, std::memory_order_relaxed);
    const bool stickWasActive = std::abs(previousStickX) > 8 || std::abs(previousStickY) > 8;
    const bool stickIsActive = std::abs(normalizedStickX) > 8 || std::abs(normalizedStickY) > 8;
    if (stickWasActive != stickIsActive) {
        logEvent("input", "controller %d left stick %s at (%d,%d)",
            controllerNum + 1, stickIsActive ? "active" : "neutral",
            normalizedStickX, normalizedStickY);
    }
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

extern "C" void goldenpad_recomp_set_touch_input_port(int32_t port) {
    const int32_t normalizedPort = port >= 0 && port < static_cast<int32_t>(kControllerPorts)
        ? port : -1;
    const int32_t previousPort = touchInputPort.exchange(
        normalizedPort, std::memory_order_relaxed);
    if (previousPort != normalizedPort) {
        if (normalizedPort < 0) {
            logEvent("input-ownership", "touch is neutral and owns no player port");
        } else {
            logEvent("input-ownership", "touch owns player %d", normalizedPort + 1);
        }
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

extern "C" void goldenpad_recomp_set_determinism_probe_enabled(int32_t enabled) {
    if (runtimeStarted.load(std::memory_order_relaxed)) {
        return;
    }
    determinismProbeEnabled.store(enabled != 0, std::memory_order_release);
}

extern "C" void goldenpad_recomp_netplay_configure(
    int32_t enabled, int32_t assignedSlot, uint64_t roomSeed) {
    {
        std::lock_guard lock(netplayFrameMutex);
        for (NetplayFrame &frame : netplayFrames) {
            frame = {};
        }
        netplayCrouchSequences.fill(0);
    }
    netplayAssignedSlot.store(
        assignedSlot >= 0 && assignedSlot < static_cast<int32_t>(kControllerPorts)
            ? assignedSlot : -1,
        std::memory_order_release);
    netplayRoomSeed.store(roomSeed, std::memory_order_release);
    netplayReceivedFrame.store(0, std::memory_order_release);
    netplayConsumedFrame.store(0, std::memory_order_release);
    netplayMissingFrames.store(0, std::memory_order_release);
    netplayChecksumFrame.store(0, std::memory_order_release);
    netplayChecksum.store(0, std::memory_order_release);
    netplaySeedApplied.store(false, std::memory_order_release);
    netplayMatchInitialized.store(false, std::memory_order_release);
    netplayFaulted.store(false, std::memory_order_release);
    netplayEnabled.store(enabled != 0, std::memory_order_release);
    netplayFrameCondition.notify_all();
    if (enabled != 0) {
        logEvent("netplay", "configured LAN room as player %d", assignedSlot + 1);
    }
}

extern "C" void goldenpad_recomp_netplay_submit_frame(
    uint64_t frame, const uint8_t *bytes, int32_t byteCount) {
    constexpr int32_t bytesPerPort = 16;
    constexpr int32_t requiredBytes =
        bytesPerPort * static_cast<int32_t>(kControllerPorts);
    if (!netplayEnabled.load(std::memory_order_acquire) || bytes == nullptr ||
        byteCount != requiredBytes || frame == 0) {
        return;
    }
    auto read16 = [bytes](size_t offset) {
        return static_cast<uint16_t>(bytes[offset]) |
            (static_cast<uint16_t>(bytes[offset + 1]) << 8);
    };
    NetplayFrame ordered{};
    ordered.number = frame;
    ordered.valid = true;
    for (size_t port = 0; port < kControllerPorts; ++port) {
        const size_t base = port * bytesPerPort;
        NetplayInput &input = ordered.inputs[port];
        input.buttons = read16(base);
        input.stickX = static_cast<int16_t>(read16(base + 2));
        input.stickY = static_cast<int16_t>(read16(base + 4));
        input.lookX = static_cast<int16_t>(read16(base + 6));
        input.lookY = static_cast<int16_t>(read16(base + 8));
        input.touchLookX = static_cast<int16_t>(read16(base + 10));
        input.touchLookY = static_cast<int16_t>(read16(base + 12));
        input.crouchSequence = read16(base + 14);
    }
    {
        std::lock_guard lock(netplayFrameMutex);
        NetplayFrame &destination = netplayFrames[frame % kNetplayFrameCapacity];
        if (destination.valid && destination.number != frame) {
            netplayMissingFrames.fetch_add(1, std::memory_order_relaxed);
            netplayFaulted.store(true, std::memory_order_release);
            return;
        }
        destination = ordered;
    }
    uint64_t previous = netplayReceivedFrame.load(std::memory_order_relaxed);
    while (previous < frame && !netplayReceivedFrame.compare_exchange_weak(
        previous, frame, std::memory_order_release, std::memory_order_relaxed)) {}
    netplayFrameCondition.notify_all();
}

extern "C" void goldenpad_recomp_netplay_status(
    uint64_t *consumedFrame,
    uint64_t *receivedFrame,
    uint64_t *missingFrames,
    uint64_t *checksumFrame,
    uint64_t *checksum) {
    if (consumedFrame != nullptr) {
        *consumedFrame = netplayConsumedFrame.load(std::memory_order_acquire);
    }
    if (receivedFrame != nullptr) {
        *receivedFrame = netplayReceivedFrame.load(std::memory_order_acquire);
    }
    if (missingFrames != nullptr) {
        *missingFrames = netplayMissingFrames.load(std::memory_order_acquire);
    }
    if (checksumFrame != nullptr) {
        *checksumFrame = netplayChecksumFrame.load(std::memory_order_acquire);
    }
    if (checksum != nullptr) {
        *checksum = netplayChecksum.load(std::memory_order_acquire);
    }
}

extern "C" void goldenpad_recomp_netplay_pause() {
    if (netplayEnabled.load(std::memory_order_acquire)) {
        netplayFaulted.store(true, std::memory_order_release);
        netplayFrameCondition.notify_all();
    }
}

extern "C" void goldenpad_recomp_performance_counters(
    uint64_t *displayLists,
    uint64_t *screenUpdates,
    uint64_t *presented,
    uint64_t *vis) {
    if (displayLists != nullptr) {
        *displayLists = rt64DisplayListCount.load(std::memory_order_acquire);
    }
    if (screenUpdates != nullptr) {
        *screenUpdates = rt64ScreenUpdateCount.load(std::memory_order_acquire);
    }
    if (presented != nullptr) {
        *presented = rt64PresentedCount.load(std::memory_order_acquire);
    }
    if (vis != nullptr) {
        *vis = determinismViCount.load(std::memory_order_acquire);
    }
}

extern "C" int32_t goldenpad_recomp_netplay_match_active() {
    return netplayEnabled.load(std::memory_order_acquire) &&
        netplayMatchInitialized.load(std::memory_order_acquire) ? 1 : 0;
}

extern "C" int32_t goldenpad_recomp_deterministic_clock_enabled() {
    return (determinismProbeEnabled.load(std::memory_order_acquire) ||
        netplayEnabled.load(std::memory_order_acquire)) ? 1 : 0;
}

extern "C" uint64_t goldenpad_recomp_deterministic_clock_ticks(uint32_t caller) {
    (void)caller;
    determinismClockReads.fetch_add(1, std::memory_order_relaxed);
    const uint64_t vi = determinismViCount.load(std::memory_order_acquire);
    const uint64_t roomStartVi = determinismRoomStartVi.load(
        std::memory_order_acquire);
    constexpr uint64_t roomEpochVi = 4'096;
    const uint64_t logicalVi = roomStartVi == 0
        ? vi
        : roomEpochVi + (vi - roomStartVi);
    return logicalVi *
        kN64CountTicksPerGamePoll;
}

extern "C" void goldenpad_recomp_deterministic_frame_step(
    uint8_t *rdram, recomp_context *ctx) {
    if (rdram == nullptr || ctx == nullptr ||
        (!determinismProbeEnabled.load(std::memory_order_acquire) &&
         !netplayEnabled.load(std::memory_order_acquire))) {
        if (ctx != nullptr) {
            ctx->r2 = 0;
        }
        return;
    }

    if (netplayFaulted.load(std::memory_order_acquire)) {
        ctx->r2 = 0;
        return;
    }

    // The stock wait routine derives deltaFrames from host wake-up timing.
    // Simulator scheduling can therefore produce 5 in one process and 6 in
    // another even when their inputs and RNG seed match. For this isolated
    // experiment, advance exactly one GoldenEye logical frame while keeping
    // the source-owned timing globals internally consistent.
    const int32_t currentFrame = readGameWord(rdram, 0x80048294);
    const int32_t previousHalf = readGameWord(rdram, 0x800482A0);
    const int32_t nextFrame = currentFrame + 1;
    const int32_t nextHalf = nextFrame / 2;
    const uint32_t currentCount = static_cast<uint32_t>(
        goldenpad_recomp_deterministic_clock_ticks(0));

    writeGameWord(rdram, 0x80048290, currentFrame);       // lastFrameCounter
    writeGameWord(rdram, 0x80048294, nextFrame);          // currentFrameCounter
    writeGameWord(rdram, 0x80048298, 1);                  // speedgraphframes
    writeGameWord(rdram, 0x8004829C, previousHalf);       // previousFrameCounter
    writeGameWord(rdram, 0x800482A0, nextHalf);           // halfFrameCounter
    writeGameWord(rdram, 0x800482A4, nextFrame & 1);      // isFrameCounterOdd
    writeGameWord(rdram, 0x800482A8, nextHalf - previousHalf);
    writeGameWord(rdram, 0x800482AC, currentCount);
    writeGameWord(rdram, 0x800482B0, currentCount);
    writeGameWord(rdram, 0x800482B4, 1);                  // frameDelay
    ctx->r2 = 1;
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

    if (playerFireRateWindow.active &&
        playerFireRateWindow.lastWeapon == weapon &&
        previousAmmo >= 0 && ammo > previousAmmo) {
        logEvent("fire-rate-probe",
            "player run=%u abort reason=reload ticks=%u weapon=%d ammo=%d->%d",
            playerFireRateWindow.runs + 1,
            playerFireRateWindow.ticks,
            weapon,
            previousAmmo,
            ammo);
        playerFireRateWindow.active = false;
    }
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
    if (playerFireRateWindow.endingAmmo == 0 &&
        playerFireRateWindow.shotEvents >= kFireRateMinimumMagazineEvents) {
        completePlayerFireRateWindow("magazine-empty");
    } else if (playerFireRateWindow.ticks >= kFireRateWindowTicks) {
        completePlayerFireRateWindow("fixed-window");
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
            startLifecycleProgressWindow(2, "foreground-resume");
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
    if (appActive.load(std::memory_order_relaxed)) {
        startLifecycleProgressWindow(1, "transient-inactive");
    }
}

extern "C" void goldenpad_recomp_set_lifecycle_probe_enabled(int32_t enabled) {
    lifecycleProbeEnabled.store(enabled != 0, std::memory_order_relaxed);
}

extern "C" void goldenpad_recomp_set_audio_probe_enabled(int32_t enabled) {
    audioProbeEnabled.store(enabled != 0, std::memory_order_relaxed);
}

extern "C" void goldenpad_recomp_set_depth_rebuild_probe_enabled(int32_t enabled) {
    depthRebuildProbeEnabled.store(enabled != 0, std::memory_order_relaxed);
}

extern "C" void goldenpad_recomp_note_audio_host_rates(
    uint32_t source, uint32_t session, uint32_t mixer
) {
    audioHostSourceFrequency.store(source, std::memory_order_relaxed);
    audioHostSessionFrequency.store(session, std::memory_order_relaxed);
    audioHostMixerFrequency.store(mixer, std::memory_order_relaxed);
    logEvent("audio-rates", "requested=%u source=%u session=%u mixer=%u",
        audioRequestedFrequency.load(std::memory_order_relaxed), source, session, mixer);
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

extern "C" void goldenpad_recomp_queue_mouse_look(int32_t controllerNum, int64_t lookX, int64_t lookY) {
    if (controllerNum < 0 || controllerNum >= static_cast<int32_t>(kControllerPorts)) {
        return;
    }
    const size_t port = static_cast<size_t>(controllerNum);
    queuedMouseLookX[port].fetch_add(lookX, std::memory_order_relaxed);
    queuedMouseLookY[port].fetch_add(lookY, std::memory_order_relaxed);
}

extern "C" void goldenpad_recomp_set_mouse_camera_aim_active(int32_t controllerNum, int32_t active) {
    if (controllerNum >= 0 && controllerNum < static_cast<int32_t>(kControllerPorts)) {
        mouseCameraAimActive[static_cast<size_t>(controllerNum)].store(
            active != 0, std::memory_order_relaxed);
    }
}

extern "C" void goldenpad_recomp_mouse_camera_aim_active(uint8_t *rdram, recomp_context *ctx) {
    const int32_t controllerNum = _arg<0, int32_t>(rdram, ctx);
    ctx->r2 = controllerNum >= 0 && controllerNum < static_cast<int32_t>(kControllerPorts) &&
        mouseCameraAimActive[static_cast<size_t>(controllerNum)].load(std::memory_order_relaxed)
        ? 1 : 0;
}

extern "C" int32_t goldenpad_recomp_previous_session_ended_unexpectedly() {
    return previousSessionEndedUnexpectedly.load(std::memory_order_relaxed) ? 1 : 0;
}

extern "C" void goldenpad_recomp_request_crouch_toggle(int32_t controllerNum) {
    if (controllerNum >= 0 && controllerNum < static_cast<int32_t>(kControllerPorts)) {
        crouchToggleRequested[controllerNum].store(true, std::memory_order_release);
    }
}

extern "C" void goldenpad_recomp_request_inventory_slot(int32_t controllerNum, int32_t slot) {
    if (controllerNum >= 0 && controllerNum < static_cast<int32_t>(kControllerPorts) &&
        slot >= 0 && slot < 10) {
        inventorySlotRequested[controllerNum].store(slot, std::memory_order_release);
    }
}

extern "C" void goldenpad_recomp_request_reload(int32_t controllerNum) {
    if (controllerNum >= 0 && controllerNum < static_cast<int32_t>(kControllerPorts)) {
        reloadRequested[controllerNum].store(true, std::memory_order_release);
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

extern "C" int32_t goldenpad_recomp_frontend_input_active() {
    uint8_t *rdram = activeRdram.load(std::memory_order_acquire);
    if (!runtimeStarted.load(std::memory_order_relaxed) || rdram == nullptr) {
        return 0;
    }
    constexpr int32_t kTitleStage = 90;
    return readGameWord(rdram, 0x80023FA8) == kTitleStage ? 1 : 0;
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

extern "C" void goldenpad_recomp_get_input_context(
    int32_t controllerNum,
    int32_t *gameplayActiveOut,
    int32_t *controlStyleOut,
    int32_t *aimingOut,
    int32_t *tankStateOut,
    int32_t *nativeLookUprightOut
) {
    int32_t gameplayActive = 0;
    int32_t controlStyle = -1;
    int32_t aiming = 0;
    int32_t tankState = -1;
    int32_t nativeLookUpright = 0;

    uint8_t *rdram = activeRdram.load(std::memory_order_acquire);
    if (runtimeStarted.load(std::memory_order_relaxed) && rdram != nullptr &&
        controllerNum >= 0 && controllerNum < static_cast<int32_t>(kControllerPorts)) {
        constexpr uint32_t kTitleStage = 90;
        constexpr uint32_t kStageAddress = 0x80023FA8;
        constexpr uint32_t kPlayerPointersAddress = 0x80079CE0;
        constexpr uint32_t kInsightAimModeOffset = 0x124;
        constexpr uint32_t kWatchAnimationStateOffset = 0x1C8;
        constexpr uint32_t kOutsideWatchMenuOffset = 0x1CC;
        constexpr uint32_t kOpenCloseSoloWatchMenuOffset = 0x1D0;
        constexpr uint32_t kControlStyleOffset = 0x2A58;
        constexpr uint32_t kPlayerIsInTankAddress = 0x80036248;
        constexpr uint32_t kPlayerTankPropAddress = 0x80036250;
        constexpr uint32_t kEnterTankStateAddress = 0x800797B8;
        // game_options_entries[PLAYER_OPTION_LOOK].current_value:
        // 0 is Reverse and 1 is Upright in GoldenEye's own menu.
        constexpr uint32_t kNativeLookOptionAddress = 0x80040884;

        const uint32_t playerAddress = static_cast<uint32_t>(readGameWord(
            rdram, kPlayerPointersAddress + static_cast<uint32_t>(controllerNum) * 4));
        if (readGameWord(rdram, kStageAddress) != static_cast<int32_t>(kTitleStage) &&
            playerAddress >= 0x80000000 && playerAddress <= 0x9FFFFFFF) {
            const int32_t style = readGameWord(rdram, playerAddress + kControlStyleOffset);
            controlStyle = style >= 0 && style <= 3 ? style : -1;
            aiming = readGameWord(rdram, playerAddress + kInsightAimModeOffset) != 0 ? 1 : 0;
            nativeLookUpright = readGameWord(rdram, kNativeLookOptionAddress) == 1 ? 1 : 0;
            gameplayActive =
                readGameWord(rdram, playerAddress + kWatchAnimationStateOffset) == 0 &&
                readGameWord(rdram, playerAddress + kOutsideWatchMenuOffset) != 0 &&
                readGameWord(rdram, playerAddress + kOpenCloseSoloWatchMenuOffset) == 0 ? 1 : 0;

            // GoldenEye exposes one mission tank through global state. It exists
            // only in the single-player Runway and Streets setups, so associate
            // it with Player 1 and require both the flag and live prop pointer.
            if (controllerNum == 0 && readGameWord(rdram, kPlayerIsInTankAddress) == 1) {
                const uint32_t tankProp = static_cast<uint32_t>(
                    readGameWord(rdram, kPlayerTankPropAddress));
                if (tankProp >= 0x80000000 && tankProp <= 0x9FFFFFFF) {
                    const int32_t candidateState = readGameWord(rdram, kEnterTankStateAddress);
                    tankState = candidateState >= 0 && candidateState <= 2
                        ? candidateState : 0;
                }
            }
        }
    }

    if (gameplayActiveOut != nullptr) { *gameplayActiveOut = gameplayActive; }
    if (controlStyleOut != nullptr) { *controlStyleOut = controlStyle; }
    if (aimingOut != nullptr) { *aimingOut = aiming; }
    if (tankStateOut != nullptr) { *tankStateOut = tankState; }
    if (nativeLookUprightOut != nullptr) { *nativeLookUprightOut = nativeLookUpright; }

    if (controllerNum >= 0 && controllerNum < static_cast<int32_t>(kControllerPorts)) {
        static std::array<std::atomic<uint32_t>, kControllerPorts> reported{};
        const uint32_t encoded = 0x80000000u |
            (static_cast<uint32_t>(gameplayActive) << 12) |
            (static_cast<uint32_t>(controlStyle + 1) << 8) |
            (static_cast<uint32_t>(aiming) << 4) |
            (static_cast<uint32_t>(nativeLookUpright) << 3) |
            static_cast<uint32_t>(tankState + 1);
        const uint32_t previous = reported[static_cast<size_t>(controllerNum)].exchange(
            encoded, std::memory_order_relaxed);
        if (previous != encoded) {
            const char *tankLabel = tankState < 0 ? "outside" :
                tankState == 0 ? "entering" : tankState == 1 ? "starting" : "running";
            logEvent("input-context", "player=%d gameplay=%d style=%d aim=%d look=%s tank=%s",
                controllerNum + 1, gameplayActive, controlStyle, aiming,
                nativeLookUpright != 0 ? "upright" : "reverse", tankLabel);
        }
    }
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
    int32_t aimingValue = 0;
    goldenpad_recomp_get_input_context(
        controllerNum, nullptr, nullptr, &aimingValue, nullptr, nullptr);
    const bool aiming = aimingValue != 0;
    // Physical testing accepted the MGB64-derived 1.56 degree baseline, then
    // requested one final 20 percent increase. Raise only absolute controller
    // look while preserving relative touch, mouse input, the 0.15 dead zone,
    // and the existing response curve.
    constexpr float kControllerHipDegreesPerFrame = 1.872f;
    // Modern right-stick Aim must retain the accepted normal-look response.
    // The game patch multiplies Aim samples by 1 and hip samples by 3, so the
    // bridge compensates for that implementation detail while producing the
    // same final 1.872 degrees per frame in both states.
    constexpr float kControllerAimDegreesPerFrame = kControllerHipDegreesPerFrame;
    const float controllerScale = aiming
        ? (kControllerAimDegreesPerFrame / 1.0f)
        : (kControllerHipDegreesPerFrame / 3.0f);
    float x = static_cast<float>(controllerLookX[port].load(std::memory_order_relaxed)) /
            32'767.0f * controllerScale +
        static_cast<float>(queuedTouchLookX[port].exchange(0, std::memory_order_acq_rel)) / 32'767.0f;
    float y = static_cast<float>(controllerLookY[port].load(std::memory_order_relaxed)) /
            32'767.0f * controllerScale +
        static_cast<float>(queuedTouchLookY[port].exchange(0, std::memory_order_acq_rel)) / 32'767.0f;
    // Desktop mouse deltas are relative rather than bounded stick positions.
    // Preserve every queued unit and compensate for the patch's lower Aim
    // multiplier so the configured mouse sensitivity remains consistent.
    const float mouseAimCompensation = aiming ? 3.0f : 1.0f;
    x += static_cast<float>(queuedMouseLookX[port].exchange(0, std::memory_order_acq_rel)) /
        32'767.0f * mouseAimCompensation;
    y += static_cast<float>(queuedMouseLookY[port].exchange(0, std::memory_order_acq_rel)) /
        32'767.0f * mouseAimCompensation;
    x = std::clamp(x, -1.0f, 1.0f);
    y = std::clamp(y, -1.0f, 1.0f);
    // Relative touch and mouse look use the same host setting on every target.
    // External gamepads use GoldenEye's native manual-sight path while aiming.
    if (aiming && invertAimY.load(std::memory_order_relaxed)) {
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

extern "C" void goldenpad_recomp_consume_inventory_slot(uint8_t *rdram, recomp_context *ctx) {
    const int32_t controllerNum = _arg<0, int32_t>(rdram, ctx);
    if (controllerNum < 0 || controllerNum >= static_cast<int32_t>(kControllerPorts)) {
        ctx->r2 = -1;
        return;
    }
    ctx->r2 = inventorySlotRequested[controllerNum].exchange(-1, std::memory_order_acq_rel);
}

extern "C" void goldenpad_recomp_consume_reload(uint8_t *rdram, recomp_context *ctx) {
    const int32_t controllerNum = _arg<0, int32_t>(rdram, ctx);
    if (controllerNum < 0 || controllerNum >= static_cast<int32_t>(kControllerPorts)) {
        ctx->r2 = 0;
        return;
    }
    ctx->r2 = reloadRequested[controllerNum].exchange(false, std::memory_order_acq_rel) ? 1 : 0;
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
    const bool probeEnabled = audioProbeEnabled.load(std::memory_order_relaxed);
    const uint64_t queued = std::min(
        writeFrame - std::min(writeFrame, readFrame), kAudioRingFrames);
    if (!audioPlaybackPrimed) {
        if (queued < kAudioPrebufferFrames) {
            std::fill(left, left + frames, 0.0f);
            std::fill(right, right + frames, 0.0f);
            observeAudioProbeOutput(left, right, frames);
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
        observeAudioProbeOutput(left, right, frames);
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
        if (probeEnabled) {
            const int16_t expected = audioProbeSample(readFrame + frame);
            if (audioRing[source] != expected ||
                audioRing[source + 1] != static_cast<int16_t>(-expected)) {
                audioProbeSequenceErrors.fetch_add(1, std::memory_order_relaxed);
            }
        }
    }
    audioLastLeft = left[produced - 1];
    audioLastRight = right[produced - 1];
    audioReadFrame.store(readFrame + produced, std::memory_order_release);
    audioRenderedFrames.fetch_add(produced, std::memory_order_relaxed);
    audioNonzeroSamples.fetch_add(nonzero, std::memory_order_relaxed);
    observeAudioProbeOutput(left, right, produced);
    return produced;
}

extern "C" void goldenpad_recomp_audio_probe_stats(
    uint64_t *observedFrames, uint64_t *largeJumps, uint64_t *sequenceErrors
) {
    if (observedFrames != nullptr) {
        *observedFrames = audioProbeObservedFrames.load(std::memory_order_relaxed);
    }
    if (largeJumps != nullptr) {
        *largeJumps = audioProbeLargeJumps.load(std::memory_order_relaxed);
    }
    if (sequenceErrors != nullptr) {
        *sequenceErrors = audioProbeSequenceErrors.load(std::memory_order_relaxed);
    }
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
