import MetalKit
import SwiftUI

struct MetalCanvas: UIViewRepresentable {
    func makeCoordinator() -> Renderer {
        Renderer()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0.025, green: 0.075, blue: 0.105, alpha: 1)
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.delegate = context.coordinator
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {}

    final class Renderer: NSObject, MTKViewDelegate {
        private var commandQueue: MTLCommandQueue?

        func attach(to view: MTKView) {
            commandQueue = view.device?.makeCommandQueue()
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard
                let descriptor = view.currentRenderPassDescriptor,
                let drawable = view.currentDrawable,
                let buffer = commandQueue?.makeCommandBuffer(),
                let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor)
            else { return }

            encoder.endEncoding()
            buffer.present(drawable)
            buffer.commit()
        }
    }
}
