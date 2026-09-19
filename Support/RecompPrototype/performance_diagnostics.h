#pragma once
#include <cstdint>

// Stable numeric hook ABI shared with the pinned runtime and Metal backend.
// Durations are wall time, not CPU utilization. Never perform I/O in hooks.
extern "C" void goldenpad_diagnostics_sample(uint32_t kind, uint64_t nanoseconds, uint64_t value);
extern "C" void goldenpad_diagnostics_progress(uint64_t dl, uint64_t vi, uint64_t submitted,
    uint64_t audioRendered, uint64_t audioDropped, uint64_t audioUnderruns, uint64_t audioQueued,
    int32_t active, int32_t stage, int32_t menu);
extern "C" void goldenpad_diagnostics_start(const char *logPath);
extern "C" void goldenpad_diagnostics_flush();
void goldenpad_diagnostics_event(const char *event, const char *detail);

extern "C" void goldenpad_recomp_prepare_diagnostics(const char *supportPath);
