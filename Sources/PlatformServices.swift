import AVFAudio
import Foundation
import SwiftUI

struct PlatformPaths {
    let root: URL
    let derivedCache: URL
    let saves: URL
    let settings: URL

    static func bootstrap(fileManager: FileManager = .default) throws -> PlatformPaths {
        let support = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let root = support.appendingPathComponent("GoldenPad", isDirectory: true)
        let derivedCache = root.appendingPathComponent("DerivedCache", isDirectory: true)
        let saves = root.appendingPathComponent("Saves", isDirectory: true)

        for directory in [root, derivedCache, saves] {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        var cacheValues = URLResourceValues()
        cacheValues.isExcludedFromBackup = true
        var mutableCache = derivedCache
        try mutableCache.setResourceValues(cacheValues)

        return PlatformPaths(
            root: root,
            derivedCache: derivedCache,
            saves: saves,
            settings: root.appendingPathComponent("settings.json")
        )
    }
}

@MainActor
final class PlatformCoordinator: ObservableObject {
    @Published private(set) var storageState = "storage: starting"
    @Published private(set) var audioState = "audio: inactive"

    private(set) var paths: PlatformPaths?
    private var observers: [NSObjectProtocol] = []

    var statusSummary: String {
        "\(storageState)  •  \(audioState)"
    }

    init() {
        do {
            paths = try PlatformPaths.bootstrap()
            storageState = "storage: sandbox ready"
        } catch {
            storageState = "storage: unavailable"
            print("[GoldenPad] Sandbox bootstrap failed: \(error.localizedDescription)")
        }

        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleAudioInterruption(notification)
            }
        })
        observers.append(center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.audioState = "audio: route changed"
            }
        })
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func handle(scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            activateAudioSession()
        case .inactive, .background:
            deactivateAudioSession()
        @unknown default:
            deactivateAudioSession()
        }
    }

    private func activateAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)
            audioState = "audio: session ready"
            print("[GoldenPad] Audio session active at \(session.sampleRate) Hz")
        } catch {
            audioState = "audio: unavailable"
            print("[GoldenPad] Audio activation failed: \(error.localizedDescription)")
        }
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
            audioState = "audio: inactive"
        } catch {
            audioState = "audio: deactivate failed"
            print("[GoldenPad] Audio deactivation failed: \(error.localizedDescription)")
        }
    }

    private func handleAudioInterruption(_ notification: Notification) {
        guard
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawType)
        else { return }

        switch type {
        case .began:
            audioState = "audio: interrupted"
        case .ended:
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            if options.contains(.shouldResume) {
                activateAudioSession()
            } else {
                audioState = "audio: inactive"
            }
        @unknown default:
            audioState = "audio: interrupted"
        }
    }
}
