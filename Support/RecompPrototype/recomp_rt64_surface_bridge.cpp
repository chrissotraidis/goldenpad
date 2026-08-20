#include "plume_render_interface.h"

#include <memory>
#include <string>

namespace plume {
std::unique_ptr<RenderInterface> CreateMetalInterface();
}

namespace {
struct MetalContext {
    std::unique_ptr<plume::RenderInterface> renderInterface;
    std::unique_ptr<plume::RenderDevice> device;
    std::unique_ptr<plume::RenderCommandQueue> commandQueue;
    std::unique_ptr<plume::RenderSwapChain> swapChain;
    std::string status;
};

std::unique_ptr<MetalContext> context;
}

extern "C" const char *goldenpad_recomp_rt64_initialize(void *window, void *view) {
    if (window == nullptr || view == nullptr) {
        return nullptr;
    }
    auto candidate = std::make_unique<MetalContext>();
    candidate->renderInterface = plume::CreateMetalInterface();
    if (candidate->renderInterface == nullptr) {
        return nullptr;
    }
    candidate->device = candidate->renderInterface->createDevice();
    candidate->commandQueue = candidate->device->createCommandQueue(plume::RenderCommandListType::DIRECT);
    const plume::RenderWindow renderWindow = {window, view};
    candidate->swapChain = candidate->commandQueue->createSwapChain(
        plume::RenderSwapChainDesc(renderWindow, plume::RenderFormat::B8G8R8A8_UNORM, 3));
    if (candidate->swapChain == nullptr || !candidate->swapChain->resize()) {
        return nullptr;
    }
    candidate->status = "RT64 prototype: Metal " + candidate->device->getDescription().name +
        " " + std::to_string(candidate->swapChain->getWidth()) + "x" +
        std::to_string(candidate->swapChain->getHeight()) +
        "; awaiting private AOT GoldenEye output";
    context = std::move(candidate);
    return context->status.c_str();
}

extern "C" void goldenpad_recomp_rt64_shutdown() {
    context.reset();
}
