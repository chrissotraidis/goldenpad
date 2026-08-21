import AppKit
import Foundation
import UniformTypeIdentifiers

@_silgen_name("goldenpad_recomp_previous_session_ended_unexpectedly")
private func goldenPadRecompPreviousSessionEndedUnexpectedly() -> Int32

enum RecompMacDiagnostics {
    private static let sharedTailLimit = 512 * 1024

    static func exportReport(
        supportURL: URL,
        runtimeStatus: String,
        audioStatus: String,
        controllerName: String?,
        resolutionMode: RecompMacResolutionMode,
        msaaEnabled: Bool,
        threePointFiltering: Bool,
        mouseSensitivity: Double,
        keyboardSummary: String,
        invertAimY: Bool,
        reticleEnabled: Bool,
        unlockAllMissions: Bool
    ) {
        let panel = NSSavePanel()
        panel.title = "Export GoldenPad Diagnostics"
        panel.nameFieldStringValue = "GoldenPad-Mac-Diagnostics.txt"
        panel.allowedContentTypes = [.plainText]
        guard panel.runModal() == .OK, let destination = panel.url else { return }

        let logs = supportURL.appendingPathComponent("Logs", isDirectory: true)
        let latest = logs.appendingPathComponent("goldenpad-recomp-latest.log")
        let previous = logs.appendingPathComponent("goldenpad-recomp-previous.log")
        let report = """
        GoldenPad Mac Diagnostics
        =========================
        Runtime: \(runtimeStatus)
        Audio: \(audioStatus)
        Previous session ended unexpectedly: \(goldenPadRecompPreviousSessionEndedUnexpectedly() != 0 ? "Yes" : "No")
        Input: \(controllerName ?? "Keyboard and mouse")
        Keyboard bindings: \(keyboardSummary)
        Mouse: \(String(format: "%.2f× sensitivity", mouseSensitivity)); left click fire; right click action; wheel changes weapon
        Graphics: RT64 Metal, \(resolutionMode.title), \(msaaEnabled ? "2x MSAA" : "MSAA off"), \(threePointFiltering ? "three-point filtering" : "linear filtering")
        Invert vertical aim: \(invertAimY ? "On" : "Off")
        Center reticle: \(reticleEnabled ? "On" : "Off")
        Unlock all missions: \(unlockAllMissions ? "On (EEPROM unchanged)" : "Off")
        System: \(ProcessInfo.processInfo.operatingSystemVersionString)

        Previous Session
        ----------------
        \(tail(of: previous))

        Current Session
        ---------------
        \(tail(of: latest))
        """
        try? report.write(to: destination, atomically: true, encoding: .utf8)
    }

    static func showLogs(in supportURL: URL) {
        let logs = supportURL.appendingPathComponent("Logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
        NSWorkspace.shared.open(logs)
    }

    private static func tail(of url: URL) -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return "No log was available."
        }
        defer { try? handle.close() }
        let length = (try? handle.seekToEnd()) ?? 0
        try? handle.seek(toOffset: length > UInt64(sharedTailLimit)
            ? length - UInt64(sharedTailLimit)
            : 0)
        guard let data = try? handle.readToEnd() else {
            return "The log could not be read."
        }
        return String(decoding: data, as: UTF8.self)
            .replacingOccurrences(of: NSHomeDirectory(), with: "<HOME>")
            .replacingOccurrences(of: NSTemporaryDirectory(), with: "<TEMP>/")
    }
}
