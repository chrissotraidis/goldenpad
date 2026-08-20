#include <memory>
#include <string>

#if defined(GOLDENPAD_RECOMP_AOT_LINKED)
extern "C" uint32_t goldenpad_recomp_aot_entrypoint_address();
#endif

namespace {
struct MetalContext {
    std::string status;
};

std::unique_ptr<MetalContext> context;
std::string failureStatus;

const char *fail(const char *stage) {
    failureStatus = "RT64 prototype: Metal initialization failed at ";
    failureStatus += stage;
    return failureStatus.c_str();
}
}

extern "C" const char *goldenpad_recomp_rt64_initialize(void *window, void *view) {
    if (window == nullptr || view == nullptr) {
        return fail("window handle");
    }
    auto candidate = std::make_unique<MetalContext>();
    // GoldenPad's working mobile renderer has one owner for each CAMetalLayer.
    // RT64 creates the actual device/queue/swap chain after the AOT game starts,
    // so this bridge must only validate the host surface, never claim it first.
    candidate->status = "RT64 prototype: host Metal surface ready";
#if defined(GOLDENPAD_RECOMP_AOT_LINKED)
    candidate->status += "; AOT entry 0x" + std::to_string(goldenpad_recomp_aot_entrypoint_address());
#else
    candidate->status += "; awaiting private AOT GoldenEye output";
#endif
    context = std::move(candidate);
    return context->status.c_str();
}

extern "C" void goldenpad_recomp_rt64_shutdown() {
    context.reset();
}
