#include "recomp.h"
#include "librecomp/addresses.hpp"
#include "librecomp/game.hpp"
#include "librecomp/overlays.hpp"

#include <algorithm>
#include <atomic>
#include <cstdint>
#include <cstdio>

extern "C" void boot_osPiRawStartDma(uint8_t *rdram, recomp_context *ctx) {
    // The TLBFREE boot patch only performs synchronous ROM reads.
    if (static_cast<uint32_t>(ctx->r4) == 0) {
        recomp::do_rom_read(
            rdram,
            ctx->r6,
            static_cast<uint32_t>(ctx->r5) + recomp::rom_base,
            static_cast<uint32_t>(ctx->r7));
    }
}

extern "C" void recomp_load_overlays(uint8_t *, recomp_context *ctx) {
    load_overlays(
        static_cast<uint32_t>(ctx->r4),
        static_cast<int32_t>(ctx->r5),
        static_cast<uint32_t>(ctx->r6));
}

extern "C" void recomp_puts(uint8_t *rdram, recomp_context *ctx) {
    static std::atomic<uint32_t> loggedBytes = 0;
    static std::atomic<bool> reportedSuppression = false;
    const gpr stringAddress = ctx->r4;
    const uint32_t length = static_cast<uint32_t>(ctx->r5);
    constexpr uint32_t kPatchLogLimit = 4096;
    const uint32_t previousBytes = loggedBytes.fetch_add(length, std::memory_order_relaxed);
    if (previousBytes >= kPatchLogLimit) {
        if (!reportedSuppression.exchange(true, std::memory_order_relaxed)) {
            std::fputs(
                "[GoldenPadRecomp] patch-log: suppressed high-frequency legacy scheduler trace\n",
                stderr);
        }
        return;
    }
    const uint32_t printableLength = std::min(length, kPatchLogLimit - previousBytes);
    for (uint32_t index = 0; index < printableLength; ++index) {
        std::fputc(MEM_B(index, stringAddress), stdout);
    }
}

extern "C" void osDpGetCounters_recomp(uint8_t *, recomp_context *) {}
extern "C" void osPiReadIo_recomp(uint8_t *, recomp_context *) {}

extern "C" void osPfsInit_recomp(uint8_t *, recomp_context *ctx) {
    // GoldenEye treats an unavailable Controller Pak as non-fatal.
    ctx->r2 = 1;
}

extern "C" void osUnmapTLB_recomp(uint8_t *, recomp_context *) {}
extern "C" void __osGetTLBHi_recomp(uint8_t *, recomp_context *ctx) {
    ctx->r2 = 0;
}

extern "C" void __f_to_ll_recomp(uint8_t *, recomp_context *ctx) {
    const int64_t value = static_cast<int64_t>(ctx->f12.fl);
    ctx->r2 = static_cast<uint32_t>(value >> 32);
    ctx->r3 = static_cast<uint32_t>(value);
}

extern "C" void __ll_to_d_recomp(uint8_t *, recomp_context *ctx) {
    const int64_t value = (static_cast<int64_t>(static_cast<int32_t>(ctx->r4)) << 32) |
        static_cast<uint32_t>(ctx->r5);
    ctx->f0.d = static_cast<double>(value);
}
