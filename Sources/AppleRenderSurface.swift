import MetalKit
import UIKit

struct RT64MetalWindowHandle {
    let window: UnsafeMutableRawPointer
    let view: UnsafeMutableRawPointer
}

@MainActor
final class AppleRenderSurface: ObservableObject {
    @Published private(set) var status = "renderer: waiting for Metal surface"

    private weak var metalView: MTKView?
    private var commandQueue: MTLCommandQueue?
    private var isActive = true
    private var lastReportedSize = CGSize.zero
    private var lastReportedRefreshRate = 0

    func attach(to view: MTKView) {
        metalView = view
        commandQueue = view.device?.makeCommandQueue()
        view.isPaused = !isActive
        refreshStatus(for: view)
    }

    func detach(from view: MTKView) {
        guard metalView === view else { return }
        metalView = nil
        commandQueue = nil
        status = "renderer: waiting for Metal surface"
    }

    func setActive(_ active: Bool) {
        isActive = active
        metalView?.isPaused = !active
    }

    func drawableSizeDidChange(in view: MTKView) {
        refreshStatus(for: view)
    }

    func drawFoundationFrame(in view: MTKView) {
        refreshStatus(for: view)
        guard
            isActive,
            let descriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable,
            let buffer = commandQueue?.makeCommandBuffer(),
            let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
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
        guard rt64WindowHandle() != nil else {
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
        status = "renderer: Metal \(Int(size.width))×\(Int(size.height)) @ \(refreshRate) Hz"
        print("[GoldenPad] RT64 surface ready: \(Int(size.width))x\(Int(size.height)) @ \(refreshRate) Hz")
    }
}
