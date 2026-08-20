import MetalKit
import SwiftUI

@_silgen_name("goldenpad_recomp_rt64_initialize")
private func goldenPadRecompRT64Initialize(
    _ window: UnsafeMutableRawPointer,
    _ view: UnsafeMutableRawPointer
) -> UnsafePointer<CChar>?

@_silgen_name("goldenpad_recomp_rt64_shutdown")
private func goldenPadRecompRT64Shutdown()

@MainActor
final class RecompPrototypeSurface: ObservableObject {
    @Published private(set) var status = "RT64 prototype: preparing Metal surface"
    private weak var metalView: MTKView?
    private var commandQueue: MTLCommandQueue?

    func attach(to view: MTKView) {
        metalView = view
        commandQueue = view.device?.makeCommandQueue()
        guard let layer = view.layer as? CAMetalLayer else {
            status = "RT64 prototype: CAMetalLayer unavailable"
            return
        }
        let window = Unmanaged.passUnretained(view).toOpaque()
        let metalLayer = Unmanaged.passUnretained(layer).toOpaque()
        if let message = goldenPadRecompRT64Initialize(window, metalLayer) {
            status = String(cString: message)
        } else {
            status = "RT64 prototype: surface-only host; verified archives are required"
        }
    }

    func detach(from view: MTKView) {
        guard metalView === view else { return }
        goldenPadRecompRT64Shutdown()
        metalView = nil
        commandQueue = nil
        status = "RT64 prototype: stopped"
    }

    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let buffer = commandQueue?.makeCommandBuffer(),
              let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }
}

struct RecompPrototypeMetalCanvas: UIViewRepresentable {
    let surface: RecompPrototypeSurface

    func makeCoordinator() -> Renderer { Renderer(surface: surface) }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0.025, green: 0.075, blue: 0.105, alpha: 1)
        view.preferredFramesPerSecond = 60
        view.delegate = context.coordinator
        surface.attach(to: view)
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {}

    static func dismantleUIView(_ view: MTKView, coordinator: Renderer) {
        coordinator.surface.detach(from: view)
    }

    final class Renderer: NSObject, MTKViewDelegate {
        let surface: RecompPrototypeSurface
        init(surface: RecompPrototypeSurface) { self.surface = surface }
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        func draw(in view: MTKView) { surface.draw(in: view) }
    }
}
