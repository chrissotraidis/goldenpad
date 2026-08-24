import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

@_silgen_name("goldenpad_recomp_previous_session_ended_unexpectedly")
private func goldenPadRecompPreviousSessionEndedUnexpectedly() -> Int32

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
struct GoldenPadApp: App {
    @StateObject private var romStore = RecompPrototypeROMStore()
    @StateObject private var surface = RecompPrototypeSurface()
    @StateObject private var input = RecompPrototypeInput()
    @StateObject private var audio = RecompPrototypeAudio()
    @StateObject private var touchLayout = RecompTouchLayoutStore()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("recomp.lookSensitivity") private var lookSensitivity = 4.0
    @AppStorage("recomp.aimBehavior") private var aimBehavior = RecompPrototypeAimBehavior.toggle.rawValue
    @AppStorage("recomp.controllerLookMode") private var controllerLookMode = RecompPrototypeControllerLookMode.analog.rawValue
    @AppStorage("recomp.controllerMap.buttonA") private var controllerButtonA = RecompPrototypeControllerControl.buttonA.defaultAction.rawValue
    @AppStorage("recomp.controllerMap.buttonB") private var controllerButtonB = RecompPrototypeControllerControl.buttonB.defaultAction.rawValue
    @AppStorage("recomp.controllerMap.buttonX") private var controllerButtonX = RecompPrototypeControllerControl.buttonX.defaultAction.rawValue
    @AppStorage("recomp.controllerMap.buttonY") private var controllerButtonY = RecompPrototypeControllerControl.buttonY.defaultAction.rawValue
    @AppStorage("recomp.controllerMap.leftShoulder") private var controllerLeftShoulder = RecompPrototypeControllerControl.leftShoulder.defaultAction.rawValue
    @AppStorage("recomp.controllerMap.rightShoulder") private var controllerRightShoulder = RecompPrototypeControllerControl.rightShoulder.defaultAction.rawValue
    @AppStorage("recomp.controllerMap.leftTrigger") private var controllerLeftTrigger = RecompPrototypeControllerControl.leftTrigger.defaultAction.rawValue
    @AppStorage("recomp.controllerMap.rightTrigger") private var controllerRightTrigger = RecompPrototypeControllerControl.rightTrigger.defaultAction.rawValue
    @AppStorage("recomp.invertAimY") private var invertAimY = false
    @AppStorage("recomp.reticleEnabled") private var reticleEnabled = false
    @AppStorage("recomp.msaaEnabled") private var msaaEnabled = true
    @AppStorage("recomp.resolutionMode") private var resolutionMode = RecompPrototypeResolutionMode.automatic.rawValue
    @AppStorage("recomp.threePointFiltering") private var threePointFiltering = true
    @AppStorage("recomp.unlockAllMissions") private var unlockAllMissions = false
    @AppStorage("recomp.twoPlayerTestMode") private var twoPlayerTestMode = false
    @AppStorage("recomp.fourPlayerTestMode") private var fourPlayerTestMode = false
    @State private var presentedSheet: RecompPrototypeSheet?
    @State private var showReturnToMenuConfirmation = false
    @State private var isEditingTouchLayout = false
    @State private var isUtilityMenuPresented = false

    var body: some Scene {
        WindowGroup {
            Group {
                if romStore.isReady {
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
                // The CAMetalLayer can leave a two-physical-pixel sampling
                // seam at the display's far edge. One opaque point masks that
                // host seam without changing RT64's drawable or viewport.
                Color.black
                    .frame(width: 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                if reticleEnabled {
                    RecompPrototypeReticle()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                if isEditingTouchLayout {
                    RecompPrototypeLiveTouchLayoutEditor(
                        store: touchLayout,
                        deviceClass: touchDeviceClass,
                        onCancel: { isEditingTouchLayout = false },
                        onDone: { isEditingTouchLayout = false }
                    )
                    .ignoresSafeArea()
                } else if input.externalControllerName == nil || input.twoPlayerTestModeActive {
                    RecompPrototypeTouchControls(
                        input: input,
                        placements: touchLayout.placements(for: touchDeviceClass),
                        deviceClass: touchDeviceClass
                    )
                        .ignoresSafeArea()
                }
                GeometryReader { geometry in
                    ZStack(alignment: .topLeading) {
                        if isUtilityMenuPresented {
                            Color.black.opacity(0.001)
                                .contentShape(Rectangle())
                                .onTapGesture { isUtilityMenuPresented = false }
                            utilityMenuPanel
                                .frame(width: 280)
                                .position(
                                    x: utilityMenuPanelX(in: geometry.size),
                                    y: 184
                                )
                                .zIndex(1)
                        }
                        utilityMenuButton
                            .position(
                                x: utilityMenuX(in: geometry.size),
                                y: 48
                            )
                            .zIndex(2)
                    }
                }
                .ignoresSafeArea()
            }
            .onAppear {
                input.configureLookSensitivity(lookSensitivity)
                input.configureAimBehavior(aimBehavior)
                input.configureControllerLookMode(controllerLookMode)
                input.configureControllerMapping(controllerMapping)
                input.configureInvertAimY(invertAimY)
                input.configureUnlockAllMissions(unlockAllMissions)
                input.configureTwoPlayerTestMode(twoPlayerTestMode)
                input.configureFourPlayerTestMode(fourPlayerTestMode)
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
            .onChange(of: controllerMappingRawValues) { _, _ in
                input.configureControllerMapping(controllerMapping)
            }
            .onChange(of: invertAimY) { _, value in
                input.configureInvertAimY(value)
            }
            .onChange(of: unlockAllMissions) { _, value in
                input.configureUnlockAllMissions(value)
            }
            .onChange(of: twoPlayerTestMode) { _, value in
                input.configureTwoPlayerTestMode(value)
            }
            .onChange(of: fourPlayerTestMode) { _, value in
                input.configureFourPlayerTestMode(value)
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    surface.setAppActive(true)
                    audio.activate()
                case .inactive:
                    // Screenshots and system overlays briefly make the scene
                    // inactive without backgrounding it. Suspending RT64 here
                    // can strand an in-flight drawable acquisition.
                    input.releaseTouchInput()
                    surface.noteTransientInactive()
                case .background:
                    input.releaseTouchInput()
                    audio.deactivate()
                    surface.setAppActive(false)
                @unknown default:
                    input.releaseTouchInput()
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
                        controllerButtonA: $controllerButtonA,
                        controllerButtonB: $controllerButtonB,
                        controllerButtonX: $controllerButtonX,
                        controllerButtonY: $controllerButtonY,
                        controllerLeftShoulder: $controllerLeftShoulder,
                        controllerRightShoulder: $controllerRightShoulder,
                        controllerLeftTrigger: $controllerLeftTrigger,
                        controllerRightTrigger: $controllerRightTrigger,
                        invertAimY: $invertAimY,
                        reticleEnabled: $reticleEnabled,
                        msaaEnabled: $msaaEnabled,
                        resolutionMode: $resolutionMode,
                        threePointFiltering: $threePointFiltering,
                        unlockAllMissions: $unlockAllMissions,
                        twoPlayerTestMode: $twoPlayerTestMode,
                        fourPlayerTestMode: $fourPlayerTestMode,
                        touchLayoutStore: touchLayout,
                        touchDeviceClass: touchDeviceClass,
                        onEditTouchLayout: beginTouchLayoutEditing,
                        runtimeStatus: surface.status,
                        audioStatus: audio.status,
                        controllerName: input.externalControllerName,
                        activeControlStyle: input.activeControlStyle
                    )
                case let .share(url):
                    RecompPrototypeShareSheet(items: [url])
                }
            }
            .confirmationDialog(
                "Return to Main Menu?",
                isPresented: $showReturnToMenuConfirmation,
                titleVisibility: .visible
            ) {
                Button("Return to Main Menu", role: .destructive) {
                    input.requestReturnToMainMenu()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Current mission progress since the last save will be discarded.")
                    }
                } else {
                    RecompPrototypeROMSetupView(store: romStore)
                }
            }
            .fileImporter(
                isPresented: $romStore.isImporterPresented,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                romStore.handleSelection(result.flatMap { urls in
                    guard let url = urls.first else {
                        return .failure(CocoaError(.fileNoSuchFile))
                    }
                    return .success(url)
                })
            }
            .onOpenURL { url in
                romStore.handleOpenURL(url)
            }
        }
    }

    private var utilityMenuButton: some View {
        Button {
            input.releaseTouchInput()
            isUtilityMenuPresented.toggle()
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.62), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.34), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .frame(width: 44, height: 44)
        .contentShape(Circle())
        .accessibilityLabel("GoldenPad menu")
    }

    private var utilityMenuPanel: some View {
        VStack(spacing: 0) {
            utilityMenuRow(
                "Return to Main Menu",
                systemImage: "arrow.uturn.backward",
                role: .destructive
            ) {
                showReturnToMenuConfirmation = true
            }
            Divider().padding(.horizontal, 12)
            utilityMenuRow("Settings", systemImage: "gearshape") {
                presentedSheet = RecompPrototypeSheet(content: .settings)
            }
            Divider().padding(.horizontal, 12)
            utilityMenuRow("Edit Touch Controls", systemImage: "hand.draw") {
                beginTouchLayoutEditing()
            }
            Divider().padding(.horizontal, 12)
            utilityMenuRow(
                "Share Diagnostics & Logs…",
                systemImage: "square.and.arrow.up"
            ) {
                shareDiagnostics()
            }
        }
        .padding(6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
    }

    private func utilityMenuRow(
        _ title: String,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role) {
            isUtilityMenuPresented = false
            action()
        } label: {
            Label(title, systemImage: systemImage)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .padding(.horizontal, 12)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(role == .destructive ? Color.red : Color.primary)
    }

    private var touchDeviceClass: RecompTouchDeviceClass {
        RecompTouchDeviceClass.current
    }

    private func utilityMenuX(in canvas: CGSize) -> CGFloat {
        let pause = touchLayout.placements(for: touchDeviceClass)
            .first(where: { $0.id == .pause })
        return canvas.width * (pause?.sanitized().x ?? 0.95)
    }

    private func utilityMenuPanelX(in canvas: CGSize) -> CGFloat {
        let halfWidth: CGFloat = 140
        let desired = utilityMenuX(in: canvas) - 118
        return min(max(halfWidth, desired), canvas.width - halfWidth)
    }

    private func shareDiagnostics() {
        let url = RecompPrototypeDiagnostics.makeReport(
            runtimeStatus: surface.status,
            audioStatus: audio.status,
            controllerName: input.externalControllerName,
            lookSensitivity: lookSensitivity,
            aimBehavior: aimBehavior,
            controllerLookMode: controllerLookMode,
            activeControlStyle: input.activeControlStyle,
            controllerMapping: controllerMapping,
            invertAimY: invertAimY,
            reticleEnabled: reticleEnabled,
            msaaEnabled: msaaEnabled,
            resolutionMode: resolutionMode,
            threePointFiltering: threePointFiltering,
            unlockAllMissions: unlockAllMissions,
            twoPlayerTestMode: twoPlayerTestMode,
            fourPlayerTestMode: fourPlayerTestMode
        )
        presentedSheet = RecompPrototypeSheet(content: .share(url))
    }

    private func beginTouchLayoutEditing() {
        input.releaseTouchInput()
        presentedSheet = nil
        isEditingTouchLayout = true
    }

    private var controllerMapping: [RecompPrototypeControllerControl: String] {
        [
            .buttonA: controllerButtonA,
            .buttonB: controllerButtonB,
            .buttonX: controllerButtonX,
            .buttonY: controllerButtonY,
            .leftShoulder: controllerLeftShoulder,
            .rightShoulder: controllerRightShoulder,
            .leftTrigger: controllerLeftTrigger,
            .rightTrigger: controllerRightTrigger,
        ]
    }

    private var controllerMappingRawValues: [String] {
        RecompPrototypeControllerControl.allCases.map {
            controllerMapping[$0] ?? $0.defaultAction.rawValue
        }
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
    @Binding var controllerButtonA: String
    @Binding var controllerButtonB: String
    @Binding var controllerButtonX: String
    @Binding var controllerButtonY: String
    @Binding var controllerLeftShoulder: String
    @Binding var controllerRightShoulder: String
    @Binding var controllerLeftTrigger: String
    @Binding var controllerRightTrigger: String
    @Binding var invertAimY: Bool
    @Binding var reticleEnabled: Bool
    @Binding var msaaEnabled: Bool
    @Binding var resolutionMode: String
    @Binding var threePointFiltering: Bool
    @Binding var unlockAllMissions: Bool
    @Binding var twoPlayerTestMode: Bool
    @Binding var fourPlayerTestMode: Bool
    @ObservedObject var touchLayoutStore: RecompTouchLayoutStore
    let touchDeviceClass: RecompTouchDeviceClass
    let onEditTouchLayout: () -> Void
    let runtimeStatus: String
    let audioStatus: String
    let controllerName: String?
    let activeControlStyle: Int32
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
                    Text("These settings are saved immediately, but they change the renderer only after fully quitting and reopening GoldenPad. To restore the original look, select Native N64 and turn off both enhancements before restarting the app.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    LabeledContent("Presentation", value: "Original rate (stable)")
                    LabeledContent("Renderer", value: "RT64 Metal")
                }
                Section("Touch Controls") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Touch look sensitivity")
                            Spacer()
                            Text(String(format: "%.2f×", lookSensitivity))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $lookSensitivity, in: 0.5...8.0, step: 0.25)
                    }
                    Text("GoldenPad keeps the tuned 1.5× swipe accumulation and 4.0× default sensitivity from the original touch build.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Picker("Touch aim button behavior", selection: $aimBehavior) {
                        ForEach(RecompPrototypeAimBehavior.allCases, id: \.rawValue) { behavior in
                            Text(behavior.title).tag(behavior.rawValue)
                        }
                    }
                    LabeledContent("GoldenPad crouch toggle", value: "Toggle")
                    Button {
                        dismiss()
                        DispatchQueue.main.async { onEditTouchLayout() }
                    } label: {
                        HStack {
                            Text("Edit touch layout")
                            Spacer()
                            Text(touchLayoutStore.hasCustomLayout(for: touchDeviceClass)
                                ? "Custom \(touchDeviceClass.title)"
                                : touchDeviceClass.title)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                    Text("Move and resize every touch control. iPhone and iPad layouts are saved separately.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("GoldenEye Controls") {
                    LabeledContent("Active in-game style", value: controlStyleTitle(activeControlStyle))
                    Text("GoldenPad follows GoldenEye's active 1.1-1.4 control style automatically. The game's own control style and aim options remain in the watch menu.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Controller") {
                    Picker("Right stick", selection: $controllerLookMode) {
                        ForEach(RecompPrototypeControllerLookMode.allCases, id: \.rawValue) { mode in
                            Text(mode.title).tag(mode.rawValue)
                        }
                    }
                    NavigationLink {
                        RecompPrototypeControllerMappingView(
                            buttonA: $controllerButtonA,
                            buttonB: $controllerButtonB,
                            buttonX: $controllerButtonX,
                            buttonY: $controllerButtonY,
                            leftShoulder: $controllerLeftShoulder,
                            rightShoulder: $controllerRightShoulder,
                            leftTrigger: $controllerLeftTrigger,
                            rightTrigger: $controllerRightTrigger
                        )
                    } label: {
                        LabeledContent("Button mapping", value: "Customize")
                    }
                    Text("The left stick, directional pad, and Menu/Start button keep their standard roles. Face buttons, bumpers, and triggers can be reassigned.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Shared Controls") {
                    Toggle("Invert GoldenPad direct aim", isOn: $invertAimY)
                    Toggle("GoldenPad center marker", isOn: $reticleEnabled)
                    Text("These options apply to both touch controls and connected controllers.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Cheats & Testing") {
                    Toggle("Unlock all missions", isOn: $unlockAllMissions)
                    Text("Changes mission-select availability only. It does not mark missions complete or modify GoldenEye save data.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Toggle("Experimental two-player input test", isOn: $twoPlayerTestMode)
                        .disabled(controllerName == nil && !twoPlayerTestMode)
                    Text(controllerName == nil
                        ? (twoPlayerTestMode
                            ? "The test is inactive while the controller is disconnected. Turn it off or reconnect the controller."
                            : "Connect an Xbox or MFi controller to enable this test.")
                        : "The connected controller remains Player 1 and touch controls become Player 2. Turn this off to hide touch controls and restore normal controller-only play.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Toggle("Experimental four-player render test", isOn: $fourPlayerTestMode)
                        .disabled(!twoPlayerTestMode || controllerName == nil)
                    Text("Advertises neutral Players 3 and 4 while keeping controller Player 1 and touch Player 2. This tests four-way rendering only, not four independent inputs.")
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

private struct RecompPrototypeControllerMappingView: View {
    @Binding var buttonA: String
    @Binding var buttonB: String
    @Binding var buttonX: String
    @Binding var buttonY: String
    @Binding var leftShoulder: String
    @Binding var rightShoulder: String
    @Binding var leftTrigger: String
    @Binding var rightTrigger: String

    var body: some View {
        Form {
            Section {
                ForEach(RecompPrototypeControllerControl.allCases) { control in
                    Picker(control.title, selection: binding(for: control)) {
                        ForEach(RecompPrototypeControllerAction.allCases, id: \.rawValue) { action in
                            Text(action.title).tag(action.rawValue)
                        }
                    }
                }
            } header: {
                Text("Buttons")
            } footer: {
                Text("Multiple buttons may use the same action. The sticks, directional pad, and Menu/Start button are fixed.")
            }
            Section {
                Button("Restore Default Mapping") {
                    restoreDefaults()
                }
            }
        }
        .navigationTitle("Button Mapping")
    }

    private func binding(for control: RecompPrototypeControllerControl) -> Binding<String> {
        switch control {
        case .buttonA: $buttonA
        case .buttonB: $buttonB
        case .buttonX: $buttonX
        case .buttonY: $buttonY
        case .leftShoulder: $leftShoulder
        case .rightShoulder: $rightShoulder
        case .leftTrigger: $leftTrigger
        case .rightTrigger: $rightTrigger
        }
    }

    private func restoreDefaults() {
        for control in RecompPrototypeControllerControl.allCases {
            binding(for: control).wrappedValue = control.defaultAction.rawValue
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
        activeControlStyle: Int32,
        controllerMapping: [RecompPrototypeControllerControl: String],
        invertAimY: Bool,
        reticleEnabled: Bool,
        msaaEnabled: Bool,
        resolutionMode: String,
        threePointFiltering: Bool,
        unlockAllMissions: Bool,
        twoPlayerTestMode: Bool,
        fourPlayerTestMode: Bool
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
        Previous foreground session ended unexpectedly: \(goldenPadRecompPreviousSessionEndedUnexpectedly() != 0 ? "Yes — inspect Previous Session and the iPadOS crash report" : "No")
        Input: \(controllerName ?? "Touch")
        Look sensitivity: \(String(format: "%.2f", lookSensitivity))x
        Aim behavior: \(aimBehavior)
        Controller right stick: \((RecompPrototypeControllerLookMode(rawValue: controllerLookMode) ?? .analog).title)
        Active GoldenEye control style: \(controlStyleTitle(activeControlStyle))
        Controller mapping: \(controllerMappingSummary(controllerMapping))
        Invert vertical while aiming: \(invertAimY ? "On" : "Off")
        Center reticle: \(reticleEnabled ? "On" : "Off")
        Unlock all missions: \(unlockAllMissions ? "On (mission select only; EEPROM unchanged)" : "Off")
        Two-player input test: \(twoPlayerTestMode ? "Requested (external P1 + touch P2)" : "Off")
        Four-player render test: \(fourPlayerTestMode ? "Requested (neutral P3/P4)" : "Off")
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

    private static func controllerMappingSummary(
        _ mapping: [RecompPrototypeControllerControl: String]
    ) -> String {
        RecompPrototypeControllerControl.allCases.map { control in
            let action = mapping[control]
                .flatMap(RecompPrototypeControllerAction.init(rawValue:))
                ?? control.defaultAction
            return "\(control.title)=\(action.title)"
        }.joined(separator: ", ")
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

private func controlStyleTitle(_ style: Int32) -> String {
    switch style {
    case -2: "Per-player styles; adapter paused"
    case 0: "1.1 Honey"
    case 1: "1.2 Solitaire"
    case 2: "1.3 Kissy"
    case 3: "1.4 Goodnight"
    case 4: "2.1 Plenty"
    case 5: "2.2 Galore"
    case 6: "2.3 Domino"
    case 7: "2.4 Goodhead"
    default: "Unavailable outside a mission"
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
