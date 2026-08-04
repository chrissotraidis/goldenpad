import MetalKit
import SwiftUI

@_silgen_name("platformFrameStatsTick")
private func goldenPadFrameStatsTick()

@_silgen_name("goldenpad_mgb64_frame_stats_snapshot")
private func goldenPadFrameStatsSnapshot(
    _ fps: UnsafeMutablePointer<Float>?,
    _ frameMilliseconds: UnsafeMutablePointer<Float>?,
    _ low1FPS: UnsafeMutablePointer<Float>?,
    _ generation: UnsafeMutablePointer<UInt32>?
) -> Int32

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
        private var didReportFrameStats = false

        init(surface: AppleRenderSurface, input: InputCoordinator) {
            self.surface = surface
            self.input = input
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            surface.drawableSizeDidChange(in: view)
        }

        func draw(in view: MTKView) {
            goldenPadFrameStatsTick()
            reportFrameStatsWhenReady()
            input.publishToCore()
            surface.drawFoundationFrame(in: view)
        }

        private func reportFrameStatsWhenReady() {
            guard !didReportFrameStats else { return }
            var fps: Float = 0
            var frameMilliseconds: Float = 0
            var low1FPS: Float = 0
            var generation: UInt32 = 0
            guard goldenPadFrameStatsSnapshot(
                &fps, &frameMilliseconds, &low1FPS, &generation
            ) == 1, generation >= 16 else { return }
            didReportFrameStats = true
            print(
                String(
                    format: "[GoldenPad] Presentation cadence: PASS %.1f FPS " +
                        "%.2f ms 1%% low %.1f generation=%u",
                    fps, frameMilliseconds, low1FPS, generation
                )
            )
        }
    }
}
