#include "hle/rt64_application_window.h"

#include <cassert>
#include <cstdio>

namespace RT64 {
    ApplicationWindow *ApplicationWindow::HookedApplicationWindow = nullptr;

    ApplicationWindow::ApplicationWindow() = default;
    ApplicationWindow::~ApplicationWindow() = default;

    void ApplicationWindow::setup(RenderWindow window, Listener *listener, uint32_t threadId) {
        (void)threadId;
        assert(listener != nullptr);
        assert(window.window != nullptr);
        assert(window.view != nullptr);

        this->listener = listener;
        windowHandle = window;
        windowWrapper = std::make_unique<CocoaWindow>(window.window);
    }

    void ApplicationWindow::setup(const char *windowTitle, Listener *listener) {
        (void)windowTitle;
        (void)listener;
        std::fputs("RT64 embedded Apple builds require a host-owned RenderWindow.\n", stderr);
        assert(false && "Missing host-owned RenderWindow");
    }

    void ApplicationWindow::setFullScreen(bool newFullScreen) {
        if (windowWrapper != nullptr) {
            windowWrapper->toggleFullscreen();
        }
        fullScreen = newFullScreen;
    }

    void ApplicationWindow::makeResizable() {
        // The UIKit/AppKit host owns resizing, rotation, and window lifetime.
    }

    void ApplicationWindow::detectRefreshRate() {
        refreshRate = (windowWrapper != nullptr) ? windowWrapper->getRefreshRate() : 0;
    }

    uint32_t ApplicationWindow::getRefreshRate() const {
        return refreshRate;
    }

    bool ApplicationWindow::detectWindowMoved() {
        if (windowWrapper == nullptr) {
            return false;
        }

        CocoaWindowAttributes attributes;
        windowWrapper->getWindowAttributes(&attributes);
        if ((windowLeft == attributes.x) && (windowTop == attributes.y)) {
            return false;
        }

        windowLeft = attributes.x;
        windowTop = attributes.y;
        return true;
    }

    void ApplicationWindow::sdlCheckFilterInstallation() {
        // Input is supplied by the Apple host, not SDL.
    }

    int ApplicationWindow::sdlEventFilter(void *userdata, SDL_Event *event) {
        (void)userdata;
        (void)event;
        return 1;
    }
}
