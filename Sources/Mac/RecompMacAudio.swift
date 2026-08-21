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
final class RecompMacAudio: ObservableObject {
    @Published private(set) var status = "audio: inactive"

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var observer: NSObjectProtocol?
    private var statsTimer: Timer?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: Notification.Name.AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.restartAfterConfigurationChange() }
        }
    }

    deinit {
        statsTimer?.invalidate()
        engine.stop()
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    func activate() {
        do {
            try startEngine()
            status = "audio: native PCM ready"
            startStatsPolling()
            print("[GoldenPadMac] audio: AVAudioEngine active")
        } catch {
            status = "audio: unavailable"
            print("[GoldenPadMac] audio: activation failed: \(error.localizedDescription)")
        }
    }

    func deactivate() {
        engine.pause()
        statsTimer?.invalidate()
        statsTimer = nil
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
                throw NSError(domain: "GoldenPadMac.Audio", code: 1)
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
        if !engine.isRunning { try engine.start() }
    }

    private func restartAfterConfigurationChange() {
        engine.stop()
        do {
            try startEngine()
            status = "audio: native PCM ready"
        } catch {
            status = "audio: unavailable"
            print("[GoldenPadMac] audio: restart failed: \(error.localizedDescription)")
        }
    }

    private func startStatsPolling() {
        statsTimer?.invalidate()
        let timer = Timer(timeInterval: 5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshStats() }
        }
        RunLoop.main.add(timer, forMode: .common)
        statsTimer = timer
    }

    private func refreshStats() {
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
        if rendered > 0 && nonzero > 0 && status != "audio: playing" {
            status = "audio: playing"
        }
    }
}
