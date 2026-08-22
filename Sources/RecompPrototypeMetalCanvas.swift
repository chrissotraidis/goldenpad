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

@_silgen_name("goldenpad_recomp_note_transient_inactive")
private func goldenPadRecompNoteTransientInactive()

@_silgen_name("goldenpad_recomp_set_lifecycle_probe_enabled")
private func goldenPadRecompSetLifecycleProbeEnabled(_ enabled: Int32)

#if GOLDENPAD_RECOMP_AOT_LINKED
@_silgen_name("goldenpad_recomp_start_game")
private func goldenPadRecompStartGame(
    _ window: UnsafeMutableRawPointer,
    _ view: UnsafeMutableRawPointer,
    _ romPath: UnsafePointer<CChar>,
    _ configPath: UnsafePointer<CChar>
) -> UnsafePointer<CChar>?

@_silgen_name("goldenpad_recomp_game_status")
private func goldenPadRecompGameStatus() -> UnsafePointer<CChar>?
#endif

@MainActor
final class RecompPrototypeSurface: ObservableObject {
    @Published private(set) var status = "RT64 prototype: preparing Metal surface"
    private weak var metalView: MTKView?
    private var commandQueue: MTLCommandQueue?
    private var rendererInitialized = false
    private var gameLaunchRequested = false
    private var statusTimer: Timer?

    init() {
        goldenPadRecompSetLifecycleProbeEnabled(
            ProcessInfo.processInfo.arguments.contains("--lifecycle-probe") ? 1 : 0
        )
    }

    func attach(to view: MTKView) {
        metalView = view
        commandQueue = view.device?.makeCommandQueue()
    }

    func setAppActive(_ active: Bool) {
        goldenPadRecompSetAppActive(active ? 1 : 0)
        guard let view = metalView else { return }
        view.isPaused = !active
        if active {
            view.setNeedsLayout()
            view.draw()
        }
    }

    func noteTransientInactive() {
        goldenPadRecompNoteTransientInactive()
    }

    private func initializeRendererIfPossible(for view: MTKView) {
        guard !rendererInitialized else { return }
        guard let layer = view.layer as? CAMetalLayer else {
            status = "RT64 prototype: CAMetalLayer unavailable"
            return
        }
        let window = Unmanaged.passUnretained(view).toOpaque()
        let metalLayer = Unmanaged.passUnretained(layer).toOpaque()
        if let message = goldenPadRecompRT64Initialize(window, metalLayer) {
            status = String(cString: message)
            rendererInitialized = true
            requestStagedGameLaunch(window: window, layer: metalLayer)
        } else {
            status = "RT64 prototype: renderer initialization pending"
        }
    }

    private func requestStagedGameLaunch(window: UnsafeMutableRawPointer, layer: UnsafeMutableRawPointer) {
        #if GOLDENPAD_RECOMP_AOT_LINKED
        guard !gameLaunchRequested else { return }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let romURL = documents.appendingPathComponent("GoldenEye_TLBFREE.z64")
        guard FileManager.default.fileExists(atPath: romURL.path) else { return }
        let configURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GoldenPadRecomp", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: configURL, withIntermediateDirectories: true)
        } catch {
            status = "AOT runtime: cannot create private support directory"
            return
        }
        let launchStatus = romURL.path.withCString { romPath in
            configURL.path.withCString { configPath in
                goldenPadRecompStartGame(window, layer, romPath, configPath)
            }
        }
        if let launchStatus {
            status = String(cString: launchStatus)
            gameLaunchRequested = true
            startStatusPolling()
        }
        #endif
    }

    private func startStatusPolling() {
        statusTimer?.invalidate()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                #if GOLDENPAD_RECOMP_AOT_LINKED
                if let nativeStatus = goldenPadRecompGameStatus() {
                    let nextStatus = String(cString: nativeStatus)
                    if nextStatus != self.status {
                        self.status = nextStatus
                    }
                }
                #endif
            }
        }
    }

    func detach(from view: MTKView) {
        guard metalView === view else { return }
        goldenPadRecompRT64Shutdown()
        statusTimer?.invalidate()
        statusTimer = nil
        rendererInitialized = false
        gameLaunchRequested = false
        metalView = nil
        commandQueue = nil
        status = "RT64 prototype: stopped"
    }

    func draw(in view: MTKView) {
        initializeRendererIfPossible(for: view)
        if gameLaunchRequested { return }
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
    let msaaEnabled: Bool
    let resolutionMode: RecompPrototypeResolutionMode
    let threePointFiltering: Bool

    func makeCoordinator() -> Renderer { Renderer(surface: surface) }

    func makeUIView(context: Context) -> MTKView {
        goldenPadRecompSetMSAAEnabled(msaaEnabled ? 1 : 0)
        goldenPadRecompSetResolutionMode(resolutionMode.nativeValue)
        goldenPadRecompSetThreePointFiltering(threePointFiltering ? 1 : 0)
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.colorPixelFormat = .bgra8Unorm
        // Keep any sub-pixel surface edge neutral. The old blue clear color
        // made a one-pixel host seam look like part of GoldenEye's sky.
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.backgroundColor = .black
        view.isOpaque = true
        view.preferredFramesPerSecond = 60
        if let layer = view.layer as? CAMetalLayer {
            // Do not let a backgrounded surface wait forever for a drawable.
            layer.allowsNextDrawableTimeout = true
        }
        view.delegate = context.coordinator
        surface.attach(to: view)
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        // This is consumed before RT64 starts. Changes made from Settings are
        // persisted for the next app launch because rebuilding the live swap
        // chain in-place is not yet a safe operation in the prototype.
        goldenPadRecompSetMSAAEnabled(msaaEnabled ? 1 : 0)
        goldenPadRecompSetResolutionMode(resolutionMode.nativeValue)
        goldenPadRecompSetThreePointFiltering(threePointFiltering ? 1 : 0)
    }

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
