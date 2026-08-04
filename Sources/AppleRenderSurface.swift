import MetalKit
import UIKit

@_silgen_name("goldenpad_rt64_initialize")
private func goldenPadRT64Initialize(
    _ window: UnsafeMutableRawPointer,
    _ view: UnsafeMutableRawPointer
) -> UnsafePointer<CChar>?

@_silgen_name("goldenpad_rt64_shutdown")
private func goldenPadRT64Shutdown()

@_silgen_name("goldenpad_mgb64_set_metal_layer")
private func goldenPadMGB64SetMetalLayer(_ layer: UnsafeMutableRawPointer?)

@_silgen_name("goldenpad_mgb64_has_metal_layer")
private func goldenPadMGB64HasMetalLayer() -> Int32

@_silgen_name("goldenpad_mgb64_renderer_initialize")
private func goldenPadMGB64RendererInitialize() -> Int32

@_silgen_name("goldenpad_mgb64_renderer_draw_frame")
private func goldenPadMGB64RendererDrawFrame(_ width: UInt32, _ height: UInt32) -> Int32

@_silgen_name("goldenpad_mgb64_set_external_retrace_active")
private func goldenPadMGB64SetExternalRetraceActive(_ active: Int32)

@_silgen_name("goldenpad_mgb64_frame_stats_set_active")
private func goldenPadMGB64FrameStatsSetActive(_ active: Int32)

struct RT64MetalWindowHandle {
    let window: UnsafeMutableRawPointer
    let view: UnsafeMutableRawPointer
}

@MainActor
final class AppleRenderSurface: ObservableObject {
    @Published private(set) var status = "renderer: waiting for Metal surface"

    private weak var metalView: MTKView?
    private var commandQueue: MTLCommandQueue?
    private var sceneIsActive = true
    private var isSystemOverlayPresented = false
    private var lastAppliedPresentationState: Bool?
    private var lastReportedSize = CGSize.zero
    private var lastReportedRefreshRate = 0

    private var shouldPresentFrames: Bool {
        sceneIsActive && !isSystemOverlayPresented
    }

    func attach(to view: MTKView) {
        metalView = view
        commandQueue = view.device?.makeCommandQueue()
        if let metalLayer = view.layer as? CAMetalLayer {
            goldenPadMGB64SetMetalLayer(Unmanaged.passUnretained(metalLayer).toOpaque())
            if goldenPadMGB64RendererInitialize() == 1 {
                applyPresentationState()
                print("[GoldenPad] MGB64 Fast3D/Metal renderer initialized")
            }
        }
        view.isPaused = !shouldPresentFrames
        refreshStatus(for: view)
    }

    func detach(from view: MTKView) {
        guard metalView === view else { return }
        goldenPadMGB64SetExternalRetraceActive(0)
        goldenPadMGB64FrameStatsSetActive(0)
        goldenPadRT64Shutdown()
        goldenPadMGB64SetMetalLayer(nil)
        metalView = nil
        commandQueue = nil
        status = "renderer: waiting for Metal surface"
    }

    func setActive(_ active: Bool) {
        sceneIsActive = active
        applyPresentationState()
    }

    func setSystemOverlayPresented(_ presented: Bool) {
        isSystemOverlayPresented = presented
        applyPresentationState()
    }

    func drawableSizeDidChange(in view: MTKView) {
        refreshStatus(for: view)
    }

    func drawFoundationFrame(in view: MTKView) {
        refreshStatus(for: view)
        var size = view.drawableSize
        if size.width <= 0 || size.height <= 0 {
            size = CGSize(
                width: view.bounds.width * view.contentScaleFactor,
                height: view.bounds.height * view.contentScaleFactor
            )
        }
        if shouldPresentFrames,
           size.width > 0,
           size.height > 0,
           goldenPadMGB64RendererDrawFrame(UInt32(size.width), UInt32(size.height)) == 1 {
            return
        }
        guard
            shouldPresentFrames,
            let descriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let buffer = commandQueue?.makeCommandBuffer(),
            let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }

    private func applyPresentationState() {
        let active = shouldPresentFrames
        if metalView != nil {
            goldenPadMGB64SetExternalRetraceActive(active ? 1 : 0)
            goldenPadMGB64FrameStatsSetActive(active ? 1 : 0)
            if lastAppliedPresentationState != active {
                print(
                    "[GoldenPad] Game presentation \(active ? "resumed" : "paused") " +
                    "scene=\(sceneIsActive ? 1 : 0) overlay=\(isSystemOverlayPresented ? 1 : 0)"
                )
                lastAppliedPresentationState = active
            }
        }
        metalView?.isPaused = !active
    }

    func rt64WindowHandle() -> RT64MetalWindowHandle? {
        guard
            let metalView,
            let metalLayer = metalView.layer as? CAMetalLayer
        else { return nil }

        return RT64MetalWindowHandle(
            window: Unmanaged.passUnretained(metalView).toOpaque(),
            view: Unmanaged.passUnretained(metalLayer).toOpaque()
        )
    }

    private func refreshStatus(for view: MTKView) {
        guard rt64WindowHandle() != nil, goldenPadMGB64HasMetalLayer() == 1 else {
            status = "renderer: Metal layer unavailable"
            return
        }

        var size = view.drawableSize
        if size.width <= 0 || size.height <= 0 {
            size = CGSize(
                width: view.bounds.width * view.contentScaleFactor,
                height: view.bounds.height * view.contentScaleFactor
            )
        }
        let refreshRate = view.window?.screen.maximumFramesPerSecond
            ?? UIScreen.main.maximumFramesPerSecond
        guard size != lastReportedSize || refreshRate != lastReportedRefreshRate else { return }
        lastReportedSize = size
        lastReportedRefreshRate = refreshRate
        let foundationStatus = "renderer: Metal \(Int(size.width))×\(Int(size.height)) @ \(refreshRate) Hz"
        if let handle = rt64WindowHandle(),
           let message = goldenPadRT64Initialize(handle.window, handle.view) {
            status = String(cString: message)
            print("[GoldenPad] \(status)")
        } else {
            status = foundationStatus
        }
        print("[GoldenPad] MGB64 Metal surface ready")
        print("[GoldenPad] RT64 surface ready: \(Int(size.width))x\(Int(size.height)) @ \(refreshRate) Hz")
    }
}
