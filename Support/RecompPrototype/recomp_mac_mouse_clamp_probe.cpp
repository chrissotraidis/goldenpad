#include <atomic>
#include <cstddef>
#include <cmath>
#include <cstdint>
#include <cstdlib>

#include <os/log.h>

namespace {

std::atomic<bool> probeEnabled = false;
std::atomic<uint64_t> publishSamples = 0;
std::atomic<uint64_t> saturatedAxes = 0;
std::atomic<uint64_t> lostUnits = 0;
std::atomic<uint64_t> maxRawAxis = 0;

void updateMaximum(std::atomic<uint64_t> &maximum, uint64_t candidate) {
    uint64_t current = maximum.load(std::memory_order_relaxed);
    while (current < candidate && !maximum.compare_exchange_weak(
        current, candidate, std::memory_order_relaxed)) {}
}

uint64_t axisMagnitude(float value) {
    if (!std::isfinite(value)) {
        return 0;
    }
    return static_cast<uint64_t>(std::fabs(static_cast<double>(value)));
}

uint64_t axisLoss(float raw, int32_t published) {
    const uint64_t rawMagnitude = axisMagnitude(raw);
    const uint64_t publishedMagnitude = static_cast<uint64_t>(
        std::abs(static_cast<int64_t>(published)));
    return rawMagnitude > publishedMagnitude ? rawMagnitude - publishedMagnitude : 0;
}

bool axisWasClamped(float raw, int32_t published) {
    return std::isfinite(raw) &&
        std::fabs(static_cast<double>(raw)) >
            std::abs(static_cast<int64_t>(published));
}

bool detectorSelfTestPasses() {
    return axisLoss(42'000.0f, 32'767) == 9'233 &&
        axisLoss(-42'000.0f, -32'767) == 9'233 &&
        axisLoss(42.0f, 42) == 0 &&
        axisWasClamped(32'767.5f, 32'767) &&
        !axisWasClamped(42.0f, 42);
}

void logSnapshot(uint64_t samples) {
    os_log_with_type(
        OS_LOG_DEFAULT,
        OS_LOG_TYPE_INFO,
        "[GoldenPad] mouse-clamp-probe: publishSamples=%{public}llu saturatedAxes=%{public}llu lostUnits=%{public}llu maxRawAxis=%{public}llu",
        static_cast<unsigned long long>(samples),
        static_cast<unsigned long long>(saturatedAxes.load(std::memory_order_relaxed)),
        static_cast<unsigned long long>(lostUnits.load(std::memory_order_relaxed)),
        static_cast<unsigned long long>(maxRawAxis.load(std::memory_order_relaxed)));
}

} // namespace

extern "C" void goldenpad_recomp_set_mac_mouse_clamp_probe_enabled(int32_t enabled) {
    const bool shouldEnable = enabled != 0;
    publishSamples.store(0, std::memory_order_relaxed);
    saturatedAxes.store(0, std::memory_order_relaxed);
    lostUnits.store(0, std::memory_order_relaxed);
    maxRawAxis.store(0, std::memory_order_relaxed);
    probeEnabled.store(shouldEnable, std::memory_order_release);
    if (shouldEnable) {
        os_log_with_type(
            OS_LOG_DEFAULT,
            OS_LOG_TYPE_INFO,
            "[GoldenPad] mouse-clamp-probe: detector=%{public}s behavior=unchanged stage=swift-publish limit=32767",
            detectorSelfTestPasses() ? "PASS" : "FAIL");
    }
}

extern "C" void goldenpad_recomp_note_mac_mouse_publish(
    float rawX, float rawY, int32_t publishedX, int32_t publishedY) {
    if (!probeEnabled.load(std::memory_order_acquire)) {
        return;
    }

    bool saturated = false;
    const float rawAxes[] = {rawX, rawY};
    const int32_t publishedAxes[] = {publishedX, publishedY};
    for (size_t index = 0; index < 2; ++index) {
        if (!std::isfinite(rawAxes[index])) {
            continue;
        }
        const uint64_t rawMagnitude = axisMagnitude(rawAxes[index]);
        const uint64_t lost = axisLoss(rawAxes[index], publishedAxes[index]);
        updateMaximum(maxRawAxis, rawMagnitude);
        if (axisWasClamped(rawAxes[index], publishedAxes[index])) {
            saturated = true;
            saturatedAxes.fetch_add(1, std::memory_order_relaxed);
            lostUnits.fetch_add(lost, std::memory_order_relaxed);
        }
    }

    const uint64_t samples = publishSamples.fetch_add(1, std::memory_order_relaxed) + 1;
    if ((saturated && saturatedAxes.load(std::memory_order_relaxed) == 1) || samples % 120 == 0) {
        logSnapshot(samples);
    }
}
