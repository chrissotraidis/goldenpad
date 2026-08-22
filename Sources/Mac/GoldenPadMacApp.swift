import AppKit
import SwiftUI

@_silgen_name("goldenpad_recomp_stop_game")
private func goldenPadRecompStopGame()

enum RecompMacResolutionMode: String, CaseIterable, Identifiable {
    case native
    case double
    case automatic

    var id: String { rawValue }

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

final class GoldenPadMacDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = icon
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) {
        goldenPadRecompStopGame()
    }
}

@main
struct GoldenPadMacApp: App {
    @NSApplicationDelegateAdaptor(GoldenPadMacDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var surface = RecompMacSurface()
    @StateObject private var input = RecompMacInput()
    @StateObject private var audio = RecompMacAudio()
    @StateObject private var romStore = RecompMacROMStore()

    @AppStorage("recomp.msaaEnabled") private var msaaEnabled = true
    @AppStorage("recomp.resolutionMode") private var resolutionMode = RecompMacResolutionMode.automatic.rawValue
    @AppStorage("recomp.threePointFiltering") private var threePointFiltering = true
    @AppStorage("recomp.invertAimY") private var invertAimY = false
    @AppStorage("recomp.reticleEnabled") private var reticleEnabled = false
    @AppStorage("recomp.unlockAllMissions") private var unlockAllMissions = false
    @AppStorage("recomp.macMouseSensitivity") private var mouseSensitivity = 2.25
    @AppStorage("recomp.macMouseTuningVersion") private var mouseTuningVersion = 0

    var body: some Scene {
        WindowGroup("GoldenPad") {
            ZStack {
                Color.black
                RecompMacMetalCanvas(
                    surface: surface,
                    input: input,
                    romURL: romStore.romURL,
                    supportURL: romStore.supportURL,
                    msaaEnabled: msaaEnabled,
                    resolutionMode: RecompMacResolutionMode(rawValue: resolutionMode) ?? .automatic,
                    threePointFiltering: threePointFiltering
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if reticleEnabled, romStore.romURL != nil {
                    RecompMacReticle()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                }

                if romStore.romURL == nil {
                    RecompMacSetupView(store: romStore)
                }

            }
            .background(Color.black)
            .preferredColorScheme(.dark)
            .onAppear {
                migrateMacMouseTuningIfNeeded()
                configureInput()
                surface.setAppActive(true)
                audio.activate()
            }
            .onChange(of: invertAimY) { _ in configureInput() }
            .onChange(of: unlockAllMissions) { _ in configureInput() }
            .onChange(of: mouseSensitivity) { _ in configureInput() }
            .onChange(of: scenePhase) { phase in
                switch phase {
                case .active:
                    surface.setAppActive(true)
                    audio.activate()
                case .inactive, .background:
                    input.releaseAllInput()
                    audio.deactivate()
                    surface.setAppActive(false)
                @unknown default:
                    input.releaseAllInput()
                    audio.deactivate()
                    surface.setAppActive(false)
                }
            }
        }
        .defaultSize(width: 1280, height: 720)
        .windowStyle(.titleBar)
        .commands {
            CommandMenu("Game") {
                Button("Return to Main Menu") {
                    input.requestReturnToMainMenu()
                }
                .disabled(romStore.romURL == nil)
                Divider()
                Button("Import GoldenEye TLBFREE Input…") { romStore.chooseROM() }
                Button("Release Mouse") { input.releaseMouseCapture() }
                    .disabled(!input.mouseCaptured)
            }
        }

        Settings {
            RecompMacSettingsView(
                surface: surface,
                input: input,
                audio: audio,
                romStore: romStore
            )
        }
    }

    private func configureInput() {
        input.configureInvertAimY(invertAimY)
        input.configureUnlockAllMissions(unlockAllMissions)
        input.configureMouseSensitivity(mouseSensitivity)
    }

    private func migrateMacMouseTuningIfNeeded() {
        guard mouseTuningVersion < 1 else { return }
        if mouseSensitivity == 2.5 {
            mouseSensitivity = 2.25
        }
        mouseTuningVersion = 1
    }
}

private struct RecompMacSetupView: View {
    @ObservedObject var store: RecompMacROMStore

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)
            Text("GoldenPad for Mac")
                .font(.largeTitle.bold())
            Text(store.status)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 520)
            Button("Choose GoldenEye_TLBFREE.z64…") { store.chooseROM() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            Text("No ROM or save data is included with GoldenPad.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(42)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct RecompMacReticle: View {
    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.75), lineWidth: 1).frame(width: 18, height: 18)
            Rectangle().fill(.white.opacity(0.75)).frame(width: 1, height: 26)
            Rectangle().fill(.white.opacity(0.75)).frame(width: 26, height: 1)
        }
        .shadow(color: .black, radius: 1)
        .accessibilityHidden(true)
    }
}

private struct RecompMacSettingsView: View {
    @ObservedObject var surface: RecompMacSurface
    @ObservedObject var input: RecompMacInput
    @ObservedObject var audio: RecompMacAudio
    @ObservedObject var romStore: RecompMacROMStore

    @AppStorage("recomp.msaaEnabled") private var msaaEnabled = true
    @AppStorage("recomp.resolutionMode") private var resolutionMode = RecompMacResolutionMode.automatic.rawValue
    @AppStorage("recomp.threePointFiltering") private var threePointFiltering = true
    @AppStorage("recomp.invertAimY") private var invertAimY = false
    @AppStorage("recomp.reticleEnabled") private var reticleEnabled = false
    @AppStorage("recomp.unlockAllMissions") private var unlockAllMissions = false
    @AppStorage("recomp.macMouseSensitivity") private var mouseSensitivity = 2.25
    @AppStorage("recomp.macKey.moveForward") private var moveForwardKey = Int(RecompMacBindableKey.w.rawValue)
    @AppStorage("recomp.macKey.moveBackward") private var moveBackwardKey = Int(RecompMacBindableKey.s.rawValue)
    @AppStorage("recomp.macKey.moveLeft") private var moveLeftKey = Int(RecompMacBindableKey.a.rawValue)
    @AppStorage("recomp.macKey.moveRight") private var moveRightKey = Int(RecompMacBindableKey.d.rawValue)
    @AppStorage("recomp.macKey.fire") private var fireKey = Int(RecompMacBindableKey.unassigned.rawValue)
    @AppStorage("recomp.macKey.aim") private var aimKey = Int(RecompMacBindableKey.shift.rawValue)
    @AppStorage("recomp.macKey.action") private var actionKey = Int(RecompMacBindableKey.e.rawValue)
    @AppStorage("recomp.macKey.changeWeapon") private var changeWeaponKey = Int(RecompMacBindableKey.q.rawValue)
    @AppStorage("recomp.macKey.reload") private var reloadKey = Int(RecompMacBindableKey.r.rawValue)
    @AppStorage("recomp.macKey.crouch") private var crouchKey = Int(RecompMacBindableKey.c.rawValue)
    @AppStorage("recomp.macKey.start") private var startKey = Int(RecompMacBindableKey.escape.rawValue)

    var body: some View {
        Form {
            Section("Graphics") {
                Picker("Resolution", selection: $resolutionMode) {
                    ForEach(RecompMacResolutionMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                Toggle("2× anti-aliasing", isOn: $msaaEnabled)
                Toggle("N64 three-point texture filtering", isOn: $threePointFiltering)
                Text("Graphics changes are saved immediately and apply after quitting and reopening GoldenPad.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("Controls") {
                HStack {
                    Text("Mouse look sensitivity")
                    Slider(value: $mouseSensitivity, in: 0.5...6.0, step: 0.25)
                        .onChange(of: mouseSensitivity) { value in
                            input.configureMouseSensitivity(value)
                        }
                    Text(String(format: "%.2f×", mouseSensitivity))
                        .monospacedDigit()
                        .frame(width: 52, alignment: .trailing)
                }
                Toggle("Invert vertical aim", isOn: $invertAimY)
                    .onChange(of: invertAimY) { value in input.configureInvertAimY(value) }
                Toggle("Center reticle", isOn: $reticleEnabled)
                LabeledContent("Controller", value: input.externalControllerName ?? "Keyboard and mouse")
                DisclosureGroup("Keyboard bindings") {
                    RecompMacKeyBindingRow(title: "Move forward", keyCode: $moveForwardKey, input: input)
                    RecompMacKeyBindingRow(title: "Move backward", keyCode: $moveBackwardKey, input: input)
                    RecompMacKeyBindingRow(title: "Move / menu left", keyCode: $moveLeftKey, input: input)
                    RecompMacKeyBindingRow(title: "Move / menu right", keyCode: $moveRightKey, input: input)
                    RecompMacKeyBindingRow(title: "Fire", keyCode: $fireKey, input: input)
                    RecompMacKeyBindingRow(title: "Aim", keyCode: $aimKey, input: input)
                    RecompMacKeyBindingRow(title: "Action", keyCode: $actionKey, input: input)
                    RecompMacKeyBindingRow(title: "Change weapon", keyCode: $changeWeaponKey, input: input)
                    RecompMacKeyBindingRow(title: "Reload", keyCode: $reloadKey, input: input)
                    RecompMacKeyBindingRow(title: "Crouch", keyCode: $crouchKey, input: input)
                    RecompMacKeyBindingRow(title: "Start / pause", keyCode: $startKey, input: input)
                }
                Text("Left mouse fires; right mouse performs Action; middle click and the wheel cycle weapons. Number keys select owned inventory slots. Escape opens GoldenEye's pause menu; Delete releases captured mouse input. Menu navigation follows the four movement bindings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("Cheats & Testing") {
                Toggle("Unlock all missions", isOn: $unlockAllMissions)
                    .onChange(of: unlockAllMissions) { value in input.configureUnlockAllMissions(value) }
                Text("Off by default. Multiplayer is not enabled in the first Mac preview.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("Runtime") {
                LabeledContent("Renderer", value: "RT64 Metal")
                LabeledContent("Game", value: surface.status)
                LabeledContent("Audio", value: audio.status)
                LabeledContent("Input", value: romStore.romURL == nil ? "TLBFREE input required" : "Ready")
                Button("Import or Replace TLBFREE Input…") { romStore.chooseROM() }
            }
            Section("Diagnostics") {
                Button("Export Diagnostics & Logs…") {
                    RecompMacDiagnostics.exportReport(
                        supportURL: romStore.supportURL,
                        runtimeStatus: surface.status,
                        audioStatus: audio.status,
                        controllerName: input.externalControllerName,
                        resolutionMode: RecompMacResolutionMode(rawValue: resolutionMode) ?? .automatic,
                        msaaEnabled: msaaEnabled,
                        threePointFiltering: threePointFiltering,
                        mouseSensitivity: mouseSensitivity,
                        keyboardSummary: input.keyboardSummary,
                        invertAimY: invertAimY,
                        reticleEnabled: reticleEnabled,
                        unlockAllMissions: unlockAllMissions
                    )
                }
                Button("Show Logs in Finder") {
                    RecompMacDiagnostics.showLogs(in: romStore.supportURL)
                }
                Text("GoldenPad keeps a bounded current-session log and the previous session log in Application Support.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 620, height: 620)
    }
}

private struct RecompMacKeyBindingRow: View {
    let title: String
    @Binding var keyCode: Int
    @ObservedObject var input: RecompMacInput

    var body: some View {
        Picker(title, selection: $keyCode) {
            ForEach(RecompMacBindableKey.allCases) { key in
                Text(key.title).tag(Int(key.rawValue))
            }
        }
        .onChange(of: keyCode) { _ in input.reloadKeyboardBindings() }
    }
}
