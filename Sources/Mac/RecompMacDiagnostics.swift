import AppKit
import Foundation
import UniformTypeIdentifiers

@_silgen_name("goldenpad_recomp_previous_session_ended_unexpectedly")
private func goldenPadRecompPreviousSessionEndedUnexpectedly() -> Int32

enum RecompMacDiagnostics {

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

        let report = """
        GoldenPad Mac Diagnostics
        =========================
        Runtime: \(runtimeStatus)
        Audio: \(audioStatus)
        Previous session ended unexpectedly: \(goldenPadRecompPreviousSessionEndedUnexpectedly() != 0 ? "Yes" : "No")
        Input: \(controllerName ?? "Keyboard and mouse")
        Keyboard bindings: \(keyboardSummary)
        Mouse: \(String(format: "%.2f× sensitivity", mouseSensitivity)); left click fire; right click action; wheel changes weapon
        Requested graphics (apply after restart): RT64 Metal, \(resolutionMode.title), \(msaaEnabled ? "2x MSAA" : "MSAA off"), \(threePointFiltering ? "three-point filtering" : "linear filtering")
        Invert vertical aim: \(invertAimY ? "On" : "Off")
        Center reticle: \(reticleEnabled ? "On" : "Off")
        Unlock all missions: \(unlockAllMissions ? "On (EEPROM unchanged)" : "Off")
        System: \(ProcessInfo.processInfo.operatingSystemVersionString)

        """
        do {
            try GoldenPadDiagnostics.report(context: report, support: supportURL)
                .write(to: destination, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not export diagnostics"
            alert.informativeText = "Choose a writable location and try again."
            alert.runModal()
        }
    }

    static func showLogs(in supportURL: URL) {
        let logs = supportURL.appendingPathComponent("Logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
        NSWorkspace.shared.open(logs)
    }

}
