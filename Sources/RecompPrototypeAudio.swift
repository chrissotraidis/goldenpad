import AVFAudio
import Foundation

@_silgen_name("goldenpad_recomp_audio_render")
private func goldenPadRecompAudioRender(
    _ left: UnsafeMutablePointer<Float>?,
    _ right: UnsafeMutablePointer<Float>?,
    _ frames: UInt32
) -> UInt32

@_silgen_name("goldenpad_recomp_audio_stats")
private func goldenPadRecompAudioStats(
    _ queuedFrames: UnsafeMutablePointer<UInt64>?,
    _ renderedFrames: UnsafeMutablePointer<UInt64>?,
    _ nonzeroSamples: UnsafeMutablePointer<UInt64>?,
    _ droppedFrames: UnsafeMutablePointer<UInt64>?,
    _ underrunFrames: UnsafeMutablePointer<UInt64>?,
    _ underrunCallbacks: UnsafeMutablePointer<UInt64>?
)

@MainActor
final class RecompPrototypeAudio: ObservableObject {
    @Published private(set) var status = "audio: inactive"

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var observers: [NSObjectProtocol] = []
    private var statsTimer: Timer?

    init() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in self?.handleInterruption(notification) }
        })
        observers.append(center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.activate() }
        })
    }

    deinit {
        statsTimer?.invalidate()
        engine.stop()
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func activate() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)
            try startEngine()
            status = "audio: native PCM ready"
            startStatsPolling()
            print("[GoldenPadRecomp] audio: AVAudioEngine active at \(session.sampleRate) Hz")
        } catch {
            status = "audio: unavailable"
            print("[GoldenPadRecomp] audio: activation failed: \(error.localizedDescription)")
        }
    }

    func deactivate() {
        engine.pause()
        statsTimer?.invalidate()
        statsTimer = nil
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
        status = "audio: inactive"
    }

    private func startEngine() throws {
        if sourceNode == nil {
            guard let format = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 22_050,
                channels: 2,
                interleaved: false
            ) else {
                throw NSError(domain: "GoldenPadRecomp.Audio", code: 1)
            }
            let source = AVAudioSourceNode(format: format) {
                _, _, frameCount, audioBufferList -> OSStatus in
                let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
                guard buffers.count >= 2,
                      let leftData = buffers[0].mData,
                      let rightData = buffers[1].mData else {
                    return noErr
                }
                _ = goldenPadRecompAudioRender(
                    leftData.assumingMemoryBound(to: Float.self),
                    rightData.assumingMemoryBound(to: Float.self),
                    UInt32(frameCount)
                )
                return noErr
            }
            engine.attach(source)
            engine.connect(source, to: engine.mainMixerNode, format: format)
            sourceNode = source
            engine.prepare()
        }
        if !engine.isRunning {
            try engine.start()
        }
    }

    private func startStatsPolling() {
        statsTimer?.invalidate()
        statsTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                var queued: UInt64 = 0
                var rendered: UInt64 = 0
                var nonzero: UInt64 = 0
                var dropped: UInt64 = 0
                var underrunFrames: UInt64 = 0
                var underrunCallbacks: UInt64 = 0
                goldenPadRecompAudioStats(
                    &queued, &rendered, &nonzero, &dropped,
                    &underrunFrames, &underrunCallbacks
                )
                if rendered > 0 && nonzero > 0 {
                    self.status = "audio: playing"
                }
                print(
                    "[GoldenPadRecomp] audio: queued=\(queued) rendered=\(rendered) " +
                    "nonzero=\(nonzero) dropped=\(dropped) " +
                    "underrunFrames=\(underrunFrames) underrunCallbacks=\(underrunCallbacks)"
                )
            }
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawType)
        else { return }
        switch type {
        case .began:
            status = "audio: interrupted"
        case .ended:
            activate()
        @unknown default:
            status = "audio: interrupted"
        }
    }
}
