import AppKit
import MetalKit
import SwiftUI

@_silgen_name("goldenpad_recomp_rt64_initialize")
private func goldenPadRecompRT64Initialize(
    _ window: UnsafeMutableRawPointer,
    _ view: UnsafeMutableRawPointer
) -> UnsafePointer<CChar>?

@_silgen_name("goldenpad_recomp_rt64_shutdown")
private func goldenPadRecompRT64Shutdown()

@_silgen_name("goldenpad_recomp_set_msaa_enabled")
private func goldenPadRecompSetMSAAEnabled(_ enabled: Int32)

@_silgen_name("goldenpad_recomp_set_resolution_mode")
private func goldenPadRecompSetResolutionMode(_ mode: Int32)

@_silgen_name("goldenpad_recomp_set_three_point_filtering")
private func goldenPadRecompSetThreePointFiltering(_ enabled: Int32)

@_silgen_name("goldenpad_recomp_set_app_active")
private func goldenPadRecompSetAppActive(_ active: Int32)

@_silgen_name("goldenpad_recomp_start_game")
private func goldenPadRecompStartGame(
    _ window: UnsafeMutableRawPointer,
    _ view: UnsafeMutableRawPointer,
    _ romPath: UnsafePointer<CChar>,
    _ configPath: UnsafePointer<CChar>
) -> UnsafePointer<CChar>?

@_silgen_name("goldenpad_recomp_game_status")
private func goldenPadRecompGameStatus() -> UnsafePointer<CChar>?

@MainActor
final class RecompMacSurface: ObservableObject {
    @Published private(set) var status = "RT64: preparing native Mac surface"

    private weak var metalView: MTKView?
    private weak var window: NSWindow?
    private var commandQueue: MTLCommandQueue?
    private var romURL: URL?
    private var supportURL: URL?
    private var rendererInitialized = false
    private var gameLaunchRequested = false
    private var statusTimer: Timer?

    func attach(to view: MTKView, window: NSWindow) {
        metalView = view
        self.window = window
        commandQueue = view.device?.makeCommandQueue()
        initializeRendererIfPossible()
    }

    func configure(
        romURL: URL?,
        supportURL: URL,
        msaaEnabled: Bool,
        resolutionMode: RecompMacResolutionMode,
        threePointFiltering: Bool
    ) {
        self.romURL = romURL
        self.supportURL = supportURL
        if !gameLaunchRequested {
            goldenPadRecompSetMSAAEnabled(msaaEnabled ? 1 : 0)
            goldenPadRecompSetResolutionMode(resolutionMode.nativeValue)
            goldenPadRecompSetThreePointFiltering(threePointFiltering ? 1 : 0)
        }
        initializeRendererIfPossible()
        requestGameLaunchIfPossible()
    }

    func setAppActive(_ active: Bool) {
        goldenPadRecompSetAppActive(active ? 1 : 0)
    }

    func detach(from view: MTKView) {
        guard metalView === view else { return }
        statusTimer?.invalidate()
        statusTimer = nil
        metalView = nil
        window = nil
        commandQueue = nil
        if !gameLaunchRequested {
            goldenPadRecompRT64Shutdown()
            rendererInitialized = false
        }
    }

    func drawHostFrame(in view: MTKView) {
        initializeRendererIfPossible()
        if gameLaunchRequested { return }
        guard let descriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let buffer = commandQueue?.makeCommandBuffer(),
              let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }

    private func initializeRendererIfPossible() {
        guard !rendererInitialized,
              let view = metalView,
              let window,
              let layer = view.layer as? CAMetalLayer else { return }
        let windowHandle = Unmanaged.passUnretained(window).toOpaque()
        let layerHandle = Unmanaged.passUnretained(layer).toOpaque()
        guard let message = goldenPadRecompRT64Initialize(windowHandle, layerHandle) else {
            status = "RT64: native Metal initialization failed"
            return
        }
        rendererInitialized = true
        status = String(cString: message)
        requestGameLaunchIfPossible()
    }

    private func requestGameLaunchIfPossible() {
        guard rendererInitialized,
              !gameLaunchRequested,
              let view = metalView,
              let window,
              let layer = view.layer as? CAMetalLayer,
              let romURL,
              let supportURL else { return }
        do {
            try FileManager.default.createDirectory(at: supportURL, withIntermediateDirectories: true)
        } catch {
            status = "AOT runtime: cannot create Application Support directory"
            return
        }
        let windowHandle = Unmanaged.passUnretained(window).toOpaque()
        let layerHandle = Unmanaged.passUnretained(layer).toOpaque()
        let launchStatus = romURL.path.withCString { romPath in
            supportURL.path.withCString { configPath in
                goldenPadRecompStartGame(windowHandle, layerHandle, romPath, configPath)
            }
        }
        if let launchStatus {
            gameLaunchRequested = true
            status = String(cString: launchStatus)
            view.isPaused = true
            startStatusPolling()
        }
    }

    private func startStatusPolling() {
        statusTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let nativeStatus = goldenPadRecompGameStatus() else { return }
                let nextStatus = String(cString: nativeStatus)
                if self.status != nextStatus { self.status = nextStatus }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        statusTimer = timer
    }
}

struct RecompMacMetalCanvas: NSViewRepresentable {
    @ObservedObject var surface: RecompMacSurface
    @ObservedObject var input: RecompMacInput
    let romURL: URL?
    let supportURL: URL
    let msaaEnabled: Bool
    let resolutionMode: RecompMacResolutionMode
    let threePointFiltering: Bool

    func makeCoordinator() -> Renderer { Renderer(surface: surface) }

    func makeNSView(context: Context) -> RecompMacMetalView {
        let view = RecompMacMetalView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.wantsLayer = true
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.colorPixelFormat = .bgra8Unorm
        view.autoResizeDrawable = true
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.preferredFramesPerSecond = 60
        view.focusRingType = .none
        view.delegate = context.coordinator
        view.mouseButtonChanged = { button, pressed in input.handleMouseButton(button, pressed: pressed) }
        view.mouseMoved = { deltaX, deltaY in input.handleMouseMotion(deltaX: deltaX, deltaY: deltaY) }
        view.mouseWheelChanged = { deltaY in input.handleMouseWheel(deltaY: deltaY) }
        view.keyChanged = { keyCode, pressed in input.handleKey(keyCode, pressed: pressed) }
        view.windowAvailable = { window in surface.attach(to: view, window: window) }
        if let layer = view.layer as? CAMetalLayer {
            layer.backgroundColor = NSColor.black.cgColor
            layer.allowsNextDrawableTimeout = true
        }
        return view
    }

    func updateNSView(_ view: RecompMacMetalView, context: Context) {
        surface.configure(
            romURL: romURL,
            supportURL: supportURL,
            msaaEnabled: msaaEnabled,
            resolutionMode: resolutionMode,
            threePointFiltering: threePointFiltering
        )
        if let window = view.window { surface.attach(to: view, window: window) }
        if input.mouseCaptured, !context.coordinator.mouseCaptureWasActive {
            view.claimKeyboardFocus()
        }
        context.coordinator.mouseCaptureWasActive = input.mouseCaptured
    }

    static func dismantleNSView(_ view: RecompMacMetalView, coordinator: Renderer) {
        coordinator.surface.detach(from: view)
    }

    final class Renderer: NSObject, MTKViewDelegate {
        let surface: RecompMacSurface
        var mouseCaptureWasActive = false
        init(surface: RecompMacSurface) { self.surface = surface }
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        func draw(in view: MTKView) { surface.drawHostFrame(in: view) }
    }
}

final class RecompMacMetalView: MTKView {
    var mouseButtonChanged: ((Int, Bool) -> Void)?
    var mouseMoved: ((CGFloat, CGFloat) -> Void)?
    var mouseWheelChanged: ((CGFloat) -> Void)?
    var keyChanged: ((UInt16, Bool) -> Void)?
    var windowAvailable: ((NSWindow) -> Void)?

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window {
            window.acceptsMouseMovedEvents = true
            windowAvailable?(window)
            DispatchQueue.main.async { [weak self, weak window] in
                guard let self, let window else { return }
                window.makeFirstResponder(self)
            }
        }
    }

    func claimKeyboardFocus() {
        guard let window, window.isKeyWindow, window.firstResponder !== self else { return }
        window.makeFirstResponder(self)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        mouseButtonChanged?(0, true)
    }

    override func mouseUp(with event: NSEvent) {
        mouseButtonChanged?(0, false)
    }

    override func rightMouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        mouseButtonChanged?(1, true)
    }

    override func rightMouseUp(with event: NSEvent) {
        mouseButtonChanged?(1, false)
    }

    override func mouseMoved(with event: NSEvent) {
        mouseMoved?(event.deltaX, event.deltaY)
    }

    override func mouseDragged(with event: NSEvent) {
        mouseMoved?(event.deltaX, event.deltaY)
    }

    override func rightMouseDragged(with event: NSEvent) {
        mouseMoved?(event.deltaX, event.deltaY)
    }

    override func scrollWheel(with event: NSEvent) {
        mouseWheelChanged?(event.scrollingDeltaY)
    }

    override func keyDown(with event: NSEvent) {
        keyChanged?(event.keyCode, true)
    }

    override func keyUp(with event: NSEvent) {
        keyChanged?(event.keyCode, false)
    }

    override func flagsChanged(with event: NSEvent) {
        if event.keyCode == 56 || event.keyCode == 60 {
            keyChanged?(event.keyCode, event.modifierFlags.contains(.shift))
        } else if event.keyCode == 59 || event.keyCode == 62 {
            keyChanged?(event.keyCode, event.modifierFlags.contains(.control))
        } else {
            super.flagsChanged(with: event)
        }
    }
}
