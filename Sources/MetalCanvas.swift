import MetalKit
import SwiftUI

struct MetalCanvas: UIViewRepresentable {
    let surface: AppleRenderSurface
    let input: InputCoordinator

    func makeCoordinator() -> Renderer {
        Renderer(surface: surface, input: input)
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0.025, green: 0.075, blue: 0.105, alpha: 1)
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.delegate = context.coordinator
        surface.attach(to: view)
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {}

    static func dismantleUIView(_ view: MTKView, coordinator: Renderer) {
        coordinator.surface.detach(from: view)
    }

    @MainActor
    final class Renderer: NSObject, MTKViewDelegate {
        let surface: AppleRenderSurface
        let input: InputCoordinator

        init(surface: AppleRenderSurface, input: InputCoordinator) {
            self.surface = surface
            self.input = input
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            surface.drawableSizeDidChange(in: view)
        }

        func draw(in view: MTKView) {
            input.publishToCore()
            surface.drawFoundationFrame(in: view)
        }
    }
}
