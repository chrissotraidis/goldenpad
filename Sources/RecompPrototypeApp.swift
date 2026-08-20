import Foundation
import SwiftUI
import UIKit

enum RecompPrototypeResolutionMode: String, CaseIterable {
    case native
    case double
    case automatic

    var title: String {
        switch self {
        case .native: "Native N64"
        case .double: "2×"
        case .automatic: "Automatic high resolution"
        }
    }

    var nativeValue: Int32 {
        switch self {
        case .native: 0
        case .double: 1
        case .automatic: 2
        }
    }
}

@main
struct GoldenPadRecompPrototypeApp: App {
    @StateObject private var surface = RecompPrototypeSurface()
    @StateObject private var input = RecompPrototypeInput()
    @StateObject private var audio = RecompPrototypeAudio()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("recomp.lookSensitivity") private var lookSensitivity = 4.0
    @AppStorage("recomp.aimBehavior") private var aimBehavior = RecompPrototypeAimBehavior.toggle.rawValue
    @AppStorage("recomp.controllerLookMode") private var controllerLookMode = RecompPrototypeControllerLookMode.analog.rawValue
    @AppStorage("recomp.invertAimY") private var invertAimY = false
    @AppStorage("recomp.reticleEnabled") private var reticleEnabled = false
    @AppStorage("recomp.msaaEnabled") private var msaaEnabled = true
    @AppStorage("recomp.resolutionMode") private var resolutionMode = RecompPrototypeResolutionMode.automatic.rawValue
    @AppStorage("recomp.threePointFiltering") private var threePointFiltering = true
    @AppStorage("recomp.unlockAllMissions") private var unlockAllMissions = false
    @State private var presentedSheet: RecompPrototypeSheet?

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .topTrailing) {
                Color.black
                    .ignoresSafeArea()
                RecompPrototypeMetalCanvas(
                    surface: surface,
                    msaaEnabled: msaaEnabled,
                    resolutionMode: RecompPrototypeResolutionMode(rawValue: resolutionMode) ?? .automatic,
                    threePointFiltering: threePointFiltering
                )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
                if reticleEnabled {
                    RecompPrototypeReticle()
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                if input.externalControllerName == nil {
                    RecompPrototypeTouchControls(input: input)
                        .ignoresSafeArea()
                }
                utilityMenu
                    .padding(.top, 10)
                    .padding(.trailing, 14)
            }
            .onAppear {
                input.configureLookSensitivity(lookSensitivity)
                input.configureAimBehavior(aimBehavior)
                input.configureControllerLookMode(controllerLookMode)
                input.configureInvertAimY(invertAimY)
                input.configureUnlockAllMissions(unlockAllMissions)
                surface.setAppActive(true)
                audio.activate()
            }
            .onChange(of: lookSensitivity) { _, value in
                input.configureLookSensitivity(value)
            }
            .onChange(of: aimBehavior) { _, value in
                input.configureAimBehavior(value)
            }
            .onChange(of: controllerLookMode) { _, value in
                input.configureControllerLookMode(value)
            }
            .onChange(of: invertAimY) { _, value in
                input.configureInvertAimY(value)
            }
            .onChange(of: unlockAllMissions) { _, value in
                input.configureUnlockAllMissions(value)
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    surface.setAppActive(true)
                    audio.activate()
                case .inactive, .background:
                    audio.deactivate()
                    surface.setAppActive(false)
                @unknown default:
                    audio.deactivate()
                    surface.setAppActive(false)
                }
            }
            .sheet(item: $presentedSheet) { sheet in
                switch sheet.content {
                case .settings:
                    RecompPrototypeSettingsView(
                        lookSensitivity: Binding(
                            get: { lookSensitivity },
                            set: { lookSensitivity = $0 }
                        ),
                        aimBehavior: $aimBehavior,
                        controllerLookMode: $controllerLookMode,
                        invertAimY: $invertAimY,
                        reticleEnabled: $reticleEnabled,
                        msaaEnabled: $msaaEnabled,
                        resolutionMode: $resolutionMode,
                        threePointFiltering: $threePointFiltering,
                        unlockAllMissions: $unlockAllMissions,
                        runtimeStatus: surface.status,
                        audioStatus: audio.status,
                        controllerName: input.externalControllerName
                    )
                case let .share(url):
                    RecompPrototypeShareSheet(items: [url])
                }
            }
        }
    }

    private var utilityMenu: some View {
        Menu {
            Button("Settings", systemImage: "gearshape") {
                presentedSheet = RecompPrototypeSheet(content: .settings)
            }
            Button("Share Diagnostics & Logs…", systemImage: "square.and.arrow.up") {
                let url = RecompPrototypeDiagnostics.makeReport(
                    runtimeStatus: surface.status,
                    audioStatus: audio.status,
                    controllerName: input.externalControllerName,
                    lookSensitivity: lookSensitivity,
                    aimBehavior: aimBehavior,
                    controllerLookMode: controllerLookMode,
                    invertAimY: invertAimY,
                    reticleEnabled: reticleEnabled,
                    msaaEnabled: msaaEnabled,
                    resolutionMode: resolutionMode,
                    threePointFiltering: threePointFiltering,
                    unlockAllMissions: unlockAllMissions
                )
                presentedSheet = RecompPrototypeSheet(content: .share(url))
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.62), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.34), lineWidth: 1))
        }
        .accessibilityLabel("GoldenPad menu")
    }
}

private struct RecompPrototypeSheet: Identifiable {
    enum Content {
        case settings
        case share(URL)
    }

    let id = UUID()
    let content: Content
}

private struct RecompPrototypeSettingsView: View {
    @Binding var lookSensitivity: Double
    @Binding var aimBehavior: String
    @Binding var controllerLookMode: String
    @Binding var invertAimY: Bool
    @Binding var reticleEnabled: Bool
    @Binding var msaaEnabled: Bool
    @Binding var resolutionMode: String
    @Binding var threePointFiltering: Bool
    @Binding var unlockAllMissions: Bool
    let runtimeStatus: String
    let audioStatus: String
    let controllerName: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Graphics") {
                    Picker("Resolution", selection: $resolutionMode) {
                        ForEach(RecompPrototypeResolutionMode.allCases, id: \.rawValue) { mode in
                            Text(mode.title).tag(mode.rawValue)
                        }
                    }
                    Toggle("2× anti-aliasing", isOn: $msaaEnabled)
                    Toggle("N64 three-point texture filtering", isOn: $threePointFiltering)
                    Text("Graphics changes apply on the next app launch. No HD texture pack is installed; these options change how RT64 renders the original ROM assets.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    LabeledContent("Presentation", value: "Original rate (stable)")
                    LabeledContent("Renderer", value: "RT64 Metal")
                }
                Section("Controls") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Touch look sensitivity")
                            Spacer()
                            Text(String(format: "%.2f×", lookSensitivity))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $lookSensitivity, in: 0.5...8.0, step: 0.25)
                    }
                    Text("GoldenPad touch tuning keeps the old 1.5× swipe accumulation and 4.0× default. Experimental analog uses the old controller's 0.15 dead zone, 1.5 response curve, and slower aim rate; C-buttons bypasses the modern camera patch.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Picker("Aim button", selection: $aimBehavior) {
                        ForEach(RecompPrototypeAimBehavior.allCases, id: \.rawValue) { behavior in
                            Text(behavior.title).tag(behavior.rawValue)
                        }
                    }
                    Picker("Controller right stick", selection: $controllerLookMode) {
                        ForEach(RecompPrototypeControllerLookMode.allCases, id: \.rawValue) { mode in
                            Text(mode.title).tag(mode.rawValue)
                        }
                    }
                    Toggle("Invert vertical while aiming", isOn: $invertAimY)
                    Toggle("Center reticle", isOn: $reticleEnabled)
                    LabeledContent("Duck", value: "Toggle")
                    LabeledContent("Xbox / MFi", value: "LT aim • RT fire")
                    Text("Left stick moves; right stick replaces the N64 C-button look controls. A/Y changes weapon, B/X acts, LB ducks, RB changes weapon, and Menu is Start.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Cheats & Testing") {
                    Toggle("Unlock all missions", isOn: $unlockAllMissions)
                    Text("Changes mission-select availability only. It does not mark missions complete or modify GoldenEye save data.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Runtime") {
                    LabeledContent("Game", value: runtimeStatus)
                    LabeledContent("Audio", value: audioStatus)
                    LabeledContent("Controller", value: controllerName ?? "Touch")
                }
            }
            .navigationTitle("GoldenPad Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct RecompPrototypeShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private enum RecompPrototypeDiagnostics {
    private static let sharedTailLimit = 512 * 1024

    static func makeReport(
        runtimeStatus: String,
        audioStatus: String,
        controllerName: String?,
        lookSensitivity: Double,
        aimBehavior: String,
        controllerLookMode: String,
        invertAimY: Bool,
        reticleEnabled: Bool,
        msaaEnabled: Bool,
        resolutionMode: String,
        threePointFiltering: Bool,
        unlockAllMissions: Bool
    ) -> URL {
        let manager = FileManager.default
        let support = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GoldenPadRecomp", isDirectory: true)
        let logs = support.appendingPathComponent("Logs", isDirectory: true)
        let latest = logs.appendingPathComponent("goldenpad-recomp-latest.log")
        let previous = logs.appendingPathComponent("goldenpad-recomp-previous.log")
        let destination = manager.temporaryDirectory
            .appendingPathComponent("GoldenPad-Recomp-Diagnostics.txt")
        let home = NSHomeDirectory()
        let report = """
        GoldenPad Recomp Diagnostics
        ============================
        Runtime: \(runtimeStatus)
        Audio: \(audioStatus)
        Input: \(controllerName ?? "Touch")
        Look sensitivity: \(String(format: "%.2f", lookSensitivity))x
        Aim behavior: \(aimBehavior)
        Controller right stick: \((RecompPrototypeControllerLookMode(rawValue: controllerLookMode) ?? .analog).title)
        Invert vertical while aiming: \(invertAimY ? "On" : "Off")
        Center reticle: \(reticleEnabled ? "On" : "Off")
        Unlock all missions: \(unlockAllMissions ? "On (mission select only; EEPROM unchanged)" : "Off")
        Graphics: RT64 Metal, \((RecompPrototypeResolutionMode(rawValue: resolutionMode) ?? .automatic).title), \(msaaEnabled ? "2x MSAA" : "MSAA off"), \(threePointFiltering ? "three-point filtering" : "linear filtering"), original presentation rate
        Device: \(UIDevice.current.model) / iOS \(UIDevice.current.systemVersion)

        Previous Session
        ----------------
        \(tail(of: previous, home: home))

        Current Session
        ---------------
        \(tail(of: latest, home: home))
        """
        try? report.write(to: destination, atomically: true, encoding: .utf8)
        return destination
    }

    private static func tail(of url: URL, home: String) -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return "No log was available."
        }
        defer { try? handle.close() }
        let length = (try? handle.seekToEnd()) ?? 0
        if length > UInt64(sharedTailLimit) {
            try? handle.seek(toOffset: length - UInt64(sharedTailLimit))
        } else {
            try? handle.seek(toOffset: 0)
        }
        guard let data = try? handle.readToEnd() else {
            return "The log could not be read."
        }
        return String(decoding: data, as: UTF8.self)
            .replacingOccurrences(of: home, with: "<HOME>")
            .replacingOccurrences(of: NSTemporaryDirectory(), with: "<TEMP>/")
    }
}

private struct RecompPrototypeReticle: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.88), lineWidth: 1)
                .frame(width: 12, height: 12)
            Rectangle()
                .fill(.white.opacity(0.88))
                .frame(width: 1, height: 22)
            Rectangle()
                .fill(.white.opacity(0.88))
                .frame(width: 22, height: 1)
            Circle()
                .fill(.white.opacity(0.92))
                .frame(width: 2, height: 2)
        }
        .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 1)
    }
}
