#include "gui/rt64_inspector.h"

namespace RT64 {
    struct VulkanContext {};

    Inspector::Inspector(
        RenderDevice *device,
        const RenderSwapChain *swapChain,
        UserConfiguration::GraphicsAPI graphicsAPI,
        SDL_Window *sdlWindow
    ) : device(device), swapChain(swapChain), graphicsAPI(graphicsAPI), sdlWindow(sdlWindow) {}

    Inspector::~Inspector() = default;

    void Inspector::setIniPath(const std::filesystem::path &path) {
        (void)path;
    }

    void Inspector::newFrame(RenderWorker *worker) {
        (void)worker;
    }

    void Inspector::endFrame() {}

    void Inspector::draw(RenderCommandList *commandList) {
        (void)commandList;
    }

    bool Inspector::handleSdlEvent(SDL_Event *event) {
        (void)event;
        return false;
    }
}
