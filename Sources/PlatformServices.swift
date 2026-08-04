import AVFAudio
import Foundation
import SwiftUI

@_silgen_name("goldenpad_mgb64_audio_render")
private func goldenPadMGB64AudioRender(
    _ left: UnsafeMutablePointer<Float>?,
    _ right: UnsafeMutablePointer<Float>?,
    _ frames: UInt32
) -> UInt32

@_silgen_name("goldenpad_mgb64_eeprom_load")
private func goldenPadMGB64EEPROMLoad(
    _ bytes: UnsafePointer<UInt8>?, _ size: UInt32
) -> Int32

@_silgen_name("goldenpad_mgb64_eeprom_snapshot")
private func goldenPadMGB64EEPROMSnapshot(
    _ bytes: UnsafeMutablePointer<UInt8>?, _ size: UInt32
) -> UInt32

@_silgen_name("goldenpad_mgb64_set_fps_overlay")
private func goldenPadMGB64SetFPSOverlay(_ enabled: Int32)

enum ControlPreset: String, Codable, Sendable, CaseIterable {
    case classic
    case modern
    case southpaw
}

enum TouchAimBehavior: String, Codable, Sendable, CaseIterable {
    case toggle
    case hold
}

struct HostSettings: Codable, Equatable, Sendable {
    static let currentSchema = 4

    var schemaVersion = currentSchema
    var controlPreset: ControlPreset = .modern
    var lookSensitivity = 1.0
    var touchOpacity = 0.72
    var touchScale = 1.0
    var stickDeadZone = 0.12
    var gyroEnabled = false
    var touchAimBehavior: TouchAimBehavior = .toggle
    var touchControlsAutoHide = true
    var performanceHUDEnabled = false
    var touchLayoutOverrides: [String: TouchLayoutOverrides] = [:]

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case controlPreset
        case lookSensitivity
        case touchOpacity
        case touchScale
        case stickDeadZone
        case gyroEnabled
        case touchAimBehavior
        case touchControlsAutoHide
        case performanceHUDEnabled
        case touchLayoutOverrides
    }

    init() {}

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        controlPreset = try values.decodeIfPresent(ControlPreset.self, forKey: .controlPreset) ?? .modern
        lookSensitivity = try values.decodeIfPresent(Double.self, forKey: .lookSensitivity) ?? 1
        touchOpacity = try values.decodeIfPresent(Double.self, forKey: .touchOpacity) ?? 0.72
        touchScale = try values.decodeIfPresent(Double.self, forKey: .touchScale) ?? 1
        stickDeadZone = try values.decodeIfPresent(Double.self, forKey: .stickDeadZone) ?? 0.12
        gyroEnabled = try values.decodeIfPresent(Bool.self, forKey: .gyroEnabled) ?? false
        touchAimBehavior = try values.decodeIfPresent(
            TouchAimBehavior.self,
            forKey: .touchAimBehavior
        ) ?? .toggle
        touchControlsAutoHide = try values.decodeIfPresent(
            Bool.self,
            forKey: .touchControlsAutoHide
        ) ?? true
        performanceHUDEnabled = try values.decodeIfPresent(
            Bool.self,
            forKey: .performanceHUDEnabled
        ) ?? false
        touchLayoutOverrides = try values.decodeIfPresent(
            [String: TouchLayoutOverrides].self,
            forKey: .touchLayoutOverrides
        ) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(schemaVersion, forKey: .schemaVersion)
        try values.encode(controlPreset, forKey: .controlPreset)
        try values.encode(lookSensitivity, forKey: .lookSensitivity)
        try values.encode(touchOpacity, forKey: .touchOpacity)
        try values.encode(touchScale, forKey: .touchScale)
        try values.encode(stickDeadZone, forKey: .stickDeadZone)
        try values.encode(gyroEnabled, forKey: .gyroEnabled)
        try values.encode(touchAimBehavior, forKey: .touchAimBehavior)
        try values.encode(touchControlsAutoHide, forKey: .touchControlsAutoHide)
        try values.encode(performanceHUDEnabled, forKey: .performanceHUDEnabled)
        try values.encode(touchLayoutOverrides, forKey: .touchLayoutOverrides)
    }

    func sanitized() -> HostSettings {
        var copy = self
        copy.schemaVersion = Self.currentSchema
        copy.lookSensitivity = copy.lookSensitivity.clamped(to: 0.25...3.0)
        copy.touchOpacity = copy.touchOpacity.clamped(to: 0.25...1.0)
        copy.touchScale = copy.touchScale.clamped(to: 0.7...1.4)
        copy.stickDeadZone = copy.stickDeadZone.clamped(to: 0.0...0.4)
        copy.touchLayoutOverrides = copy.touchLayoutOverrides.mapValues { overrides in
            TouchLayoutOverrides(placements: overrides.placements.map { $0.sanitized() })
        }
        return copy
    }

    static func layoutKey(
        deviceClass: TouchDeviceClass,
        preset: ControlPreset
    ) -> String {
        "\(deviceClass.rawValue).\(preset.rawValue)-v4"
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

struct PlatformPaths {
    let root: URL
    let derivedCache: URL
    let saves: URL
    let settings: URL
    let gameEEPROM: URL

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
            settings: root.appendingPathComponent("settings.json"),
            gameEEPROM: saves.appendingPathComponent("goldeneye-us.eep")
        )
    }
}

enum PlatformStorageError: Error {
    case invalidSaveSlot(Int)
    case unsupportedSettingsSchema(Int)
}

struct PlatformStorage {
    private static let saveSlotRange = 0..<4

    let paths: PlatformPaths
    private let fileManager: FileManager

    init(paths: PlatformPaths, fileManager: FileManager = .default) {
        self.paths = paths
        self.fileManager = fileManager
    }

    func loadSettings() throws -> HostSettings {
        guard fileManager.fileExists(atPath: paths.settings.path) else {
            return HostSettings()
        }

        let stored = try JSONDecoder().decode(
            HostSettings.self,
            from: Data(contentsOf: paths.settings)
        )
        guard stored.schemaVersion > 0, stored.schemaVersion <= HostSettings.currentSchema else {
            throw PlatformStorageError.unsupportedSettingsSchema(stored.schemaVersion)
        }
        return stored.sanitized()
    }

    func saveSettings(_ settings: HostSettings) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(settings.sanitized())
        try data.write(to: paths.settings, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    func loadSave(slot: Int) throws -> Data? {
        let url = try saveURL(slot: slot)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url, options: [.mappedIfSafe])
    }

    func saveGameData(_ data: Data, slot: Int) throws {
        let url = try saveURL(slot: slot)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    func loadGameEEPROM() throws -> Data? {
        guard fileManager.fileExists(atPath: paths.gameEEPROM.path) else { return nil }
        let data = try Data(contentsOf: paths.gameEEPROM)
        return data.count == 2_048 ? data : nil
    }

    func saveGameEEPROM(_ data: Data) throws {
        guard data.count == 2_048 else { return }
        try data.write(
            to: paths.gameEEPROM,
            options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        )
    }

    private func saveURL(slot: Int) throws -> URL {
        guard Self.saveSlotRange.contains(slot) else {
            throw PlatformStorageError.invalidSaveSlot(slot)
        }
        return paths.saves.appendingPathComponent("player-\(slot + 1).sav")
    }
}

@MainActor
final class PlatformCoordinator: ObservableObject {
    @Published private(set) var storageState = "storage: starting"
    @Published private(set) var audioState = "audio: inactive"
    @Published private(set) var settings = HostSettings()

    private(set) var paths: PlatformPaths?
    private var storage: PlatformStorage?
    private var observers: [NSObjectProtocol] = []
    private let audioEngine = AVAudioEngine()
    private var audioSourceNode: AVAudioSourceNode?
    private var persistedEEPROMGeneration: UInt32 = 0

    var statusSummary: String {
        "\(storageState)  •  \(audioState)"
    }

    init() {
        do {
            let paths = try PlatformPaths.bootstrap()
            let storage = PlatformStorage(paths: paths)
            let settings = try storage.loadSettings()

            self.paths = paths
            self.storage = storage
            self.settings = settings
            applyRuntimeSettings()
            try storage.saveSettings(settings)
            try restoreGameEEPROM(from: storage)
            storageState = "storage: sandbox ready"
            runStorageProbeIfRequested()
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
        audioEngine.stop()
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func handle(scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            activateAudioSession()
        case .inactive, .background:
            persistGameEEPROM()
            persistSettings()
            deactivateAudioSession()
        @unknown default:
            deactivateAudioSession()
        }
    }

    func updateSettings(_ update: (inout HostSettings) -> Void) {
        update(&settings)
        settings = settings.sanitized()
        applyRuntimeSettings()
        persistSettings()
    }

    func touchLayout(
        deviceClass: TouchDeviceClass,
        preset: ControlPreset? = nil
    ) -> [TouchControlPlacement] {
        let preset = preset ?? settings.controlPreset
        let key = HostSettings.layoutKey(deviceClass: deviceClass, preset: preset)
        return TouchLayoutDefaults.resolved(
            preset: preset,
            deviceClass: deviceClass,
            overrides: settings.touchLayoutOverrides[key]
        )
    }

    func saveTouchLayout(
        _ placements: [TouchControlPlacement],
        deviceClass: TouchDeviceClass,
        preset: ControlPreset? = nil
    ) {
        let preset = preset ?? settings.controlPreset
        let key = HostSettings.layoutKey(deviceClass: deviceClass, preset: preset)
        let defaults = Dictionary(
            uniqueKeysWithValues: TouchLayoutDefaults
                .placements(preset: preset, deviceClass: deviceClass)
                .map { ($0.id, $0.sanitized()) }
        )
        let changed = placements
            .map { $0.sanitized() }
            .filter { defaults[$0.id] != $0 }
        updateSettings {
            if changed.isEmpty {
                $0.touchLayoutOverrides.removeValue(forKey: key)
            } else {
                $0.touchLayoutOverrides[key] = TouchLayoutOverrides(placements: changed)
            }
        }
    }

    func resetTouchLayout(
        deviceClass: TouchDeviceClass,
        preset: ControlPreset? = nil
    ) {
        let preset = preset ?? settings.controlPreset
        let key = HostSettings.layoutKey(deviceClass: deviceClass, preset: preset)
        updateSettings { $0.touchLayoutOverrides.removeValue(forKey: key) }
    }

    private func persistSettings() {
        do {
            try storage?.saveSettings(settings)
        } catch {
            storageState = "storage: settings write failed"
            print("[GoldenPad] Settings persistence failed: \(error.localizedDescription)")
        }
    }

    private func applyRuntimeSettings() {
        goldenPadMGB64SetFPSOverlay(settings.performanceHUDEnabled ? 1 : 0)
    }

    private func restoreGameEEPROM(from storage: PlatformStorage) throws {
        guard let data = try storage.loadGameEEPROM() else { return }
        let loaded = data.withUnsafeBytes { bytes in
            goldenPadMGB64EEPROMLoad(
                bytes.bindMemory(to: UInt8.self).baseAddress,
                UInt32(data.count)
            )
        }
        if loaded == 1 {
            persistedEEPROMGeneration = 0
            print("[GoldenPad] Game EEPROM restored from Application Support")
        }
    }

    private func persistGameEEPROM(force: Bool = false) {
        guard let storage else { return }
        var data = Data(count: 2_048)
        let size: UInt32 = 2_048
        let generation = data.withUnsafeMutableBytes { bytes in
            goldenPadMGB64EEPROMSnapshot(
                bytes.bindMemory(to: UInt8.self).baseAddress,
                size
            )
        }
        guard generation != UInt32.max,
              force || generation != persistedEEPROMGeneration else { return }
        do {
            try storage.saveGameEEPROM(data)
            persistedEEPROMGeneration = generation
            print("[GoldenPad] Game EEPROM persisted atomically")
        } catch {
            storageState = "storage: EEPROM write failed"
            print("[GoldenPad] EEPROM persistence failed: \(error.localizedDescription)")
        }
    }

    private func runStorageProbeIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments
        let probeBytes = Data("GOLDENPAD_PLATFORM_SAVE_PROBE_V1".utf8)
        let eepromProbe = Data((0..<2_048).map { UInt8(truncatingIfNeeded: $0 ^ 0x47) })

        do {
            if arguments.contains("--eeprom-probe-write") {
                let loaded = eepromProbe.withUnsafeBytes { bytes in
                    goldenPadMGB64EEPROMLoad(
                        bytes.bindMemory(to: UInt8.self).baseAddress,
                        UInt32(eepromProbe.count)
                    )
                }
                guard loaded == 1 else {
                    storageState = "storage: EEPROM probe load failed"
                    return
                }
                persistGameEEPROM(force: true)
                storageState = "storage: EEPROM probe written"
            } else if arguments.contains("--eeprom-probe-verify") {
                var restored = Data(count: 2_048)
                let size: UInt32 = 2_048
                let generation = restored.withUnsafeMutableBytes { bytes in
                    goldenPadMGB64EEPROMSnapshot(
                        bytes.bindMemory(to: UInt8.self).baseAddress,
                        size
                    )
                }
                storageState = generation != UInt32.max && restored == eepromProbe
                    ? "storage: EEPROM relaunch verified"
                    : "storage: EEPROM relaunch failed"
            } else if arguments.contains("--storage-probe-write") {
                settings.lookSensitivity = 1.37
                settings.touchOpacity = 0.62
                settings.touchAimBehavior = .hold
                settings.performanceHUDEnabled = true
                try storage?.saveSettings(settings)
                try storage?.saveGameData(probeBytes, slot: 0)
                storageState = "storage: probe written"
            } else if arguments.contains("--storage-probe-verify") {
                guard
                    let storage,
                    settings.lookSensitivity == 1.37,
                    settings.touchOpacity == 0.62,
                    settings.touchAimBehavior == .hold,
                    settings.performanceHUDEnabled,
                    try storage.loadSave(slot: 0) == probeBytes
                else {
                    storageState = "storage: relaunch failed"
                    return
                }
                storageState = "storage: relaunch verified"
            }
        } catch {
            storageState = "storage: probe failed"
            print("[GoldenPad] Storage probe failed: \(error.localizedDescription)")
        }
    }

    private func activateAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)
            try startAudioEngine()
            audioState = "audio: native PCM ready"
            print("[GoldenPad] Audio session active at \(session.sampleRate) Hz")
        } catch {
            audioState = "audio: unavailable"
            print("[GoldenPad] Audio activation failed: \(error.localizedDescription)")
        }
    }

    private func deactivateAudioSession() {
        do {
            audioEngine.pause()
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
            audioState = "audio: inactive"
            print("[GoldenPad] Audio session inactive")
        } catch {
            audioState = "audio: deactivate failed"
            print("[GoldenPad] Audio deactivation failed: \(error.localizedDescription)")
        }
    }

    private func startAudioEngine() throws {
        if audioSourceNode == nil {
            guard let format = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 22_050,
                channels: 2,
                interleaved: false
            ) else {
                throw NSError(domain: "GoldenPad.Audio", code: 1)
            }
            let source = AVAudioSourceNode(format: format) {
                _, _, frameCount, audioBufferList -> OSStatus in
                let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
                guard buffers.count >= 2,
                      let leftData = buffers[0].mData,
                      let rightData = buffers[1].mData else {
                    return noErr
                }
                let left = leftData.assumingMemoryBound(to: Float.self)
                let right = rightData.assumingMemoryBound(to: Float.self)
                _ = goldenPadMGB64AudioRender(left, right, UInt32(frameCount))
                return noErr
            }
            audioEngine.attach(source)
            audioEngine.connect(source, to: audioEngine.mainMixerNode, format: format)
            audioSourceNode = source
            audioEngine.prepare()
        }
        if !audioEngine.isRunning {
            try audioEngine.start()
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
