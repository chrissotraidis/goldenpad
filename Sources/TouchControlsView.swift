import SwiftUI
import simd

struct GameplayTouchControls: View {
    @EnvironmentObject private var input: InputCoordinator
    @EnvironmentObject private var platform: PlatformCoordinator
    @EnvironmentObject private var renderSurface: AppleRenderSurface
    @State private var isSettingsPresented = false

    private var deviceClass: TouchDeviceClass {
        UIDevice.current.userInterfaceIdiom == .pad ? .tablet : .phone
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if input.shouldShowTouchControls {
                TouchControlCanvas(
                    placements: platform.touchLayout(deviceClass: deviceClass),
                    opacity: platform.settings.touchOpacity,
                    globalScale: platform.settings.touchScale,
                    input: input,
                    showsBackground: false,
                    showsMoveGuide: platform.settings.moveGuideVisible,
                    showsLookGuide: platform.settings.lookGuideVisible
                )
                .ignoresSafeArea()
            }

            if input.playerVitals.isVisible {
                PlayerVitalsHUD(vitals: input.playerVitals)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.top, 20)
                    .padding(.leading, 24)
                    .allowsHitTesting(false)
            }

            HStack(alignment: .center, spacing: 10) {
                if input.shouldShowTouchControls,
                   platform.settings.controlPreset != .classic {
                    TouchControlVisual(
                        id: .pause,
                        input: input,
                        editing: false,
                        selected: false,
                        showsGuide: true
                    )
                    .frame(width: 50, height: 50)
                    .opacity(platform.settings.touchOpacity)
                    .accessibilityLabel("Pause")
                }

                Button { isSettingsPresented = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 42, height: 42)
                        .background(.black.opacity(0.46), in: Circle())
                }
                .foregroundStyle(.white)
                .accessibilityLabel("Open game settings")
            }
            .padding(.top, 14)
            .padding(.trailing, 50)
        }
        .sheet(isPresented: $isSettingsPresented) {
            GameplaySettingsView(deviceClass: deviceClass)
                .environmentObject(input)
                .environmentObject(platform)
        }
        .onChange(of: isSettingsPresented) { _, presented in
            input.releaseTouchInput()
            renderSurface.setSystemOverlayPresented(presented)
        }
        .onDisappear {
            input.releaseTouchInput()
            renderSurface.setSystemOverlayPresented(false)
        }
    }
}

private struct PlayerVitalsHUD: View {
    let vitals: PlayerVitals

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VitalBar(label: "HEALTH", value: vitals.health, tint: .green)
            if vitals.armor > 0.001 {
                VitalBar(label: "ARMOR", value: vitals.armor, tint: .cyan)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(.black.opacity(0.48), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct VitalBar: View {
    let label: String
    let value: Double
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .frame(width: 42, alignment: .leading)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.16))
                    Capsule()
                        .fill(tint)
                        .frame(width: geometry.size.width * value)
                }
            }
            .frame(width: 90, height: 7)
            Text("\(Int((value * 100).rounded()))%")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .frame(width: 34, alignment: .trailing)
        }
        .foregroundStyle(.white.opacity(0.9))
    }
}

private struct GameplaySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var input: InputCoordinator
    @EnvironmentObject private var platform: PlatformCoordinator

    let deviceClass: TouchDeviceClass

    var body: some View {
        NavigationStack {
            Form {
                Section("Control Setup") {
                    Picker("Preset", selection: presetBinding) {
                        ForEach(ControlPreset.allCases, id: \.self) { preset in
                            Text(preset.title).tag(preset)
                        }
                    }
                    NavigationLink {
                        TouchSettingsView(deviceClass: deviceClass)
                            .environmentObject(input)
                            .environmentObject(platform)
                    } label: {
                        HStack {
                            Label("Touch Controls", systemImage: "hand.tap")
                            Spacer()
                            Text(deviceClass == .tablet ? "iPad" : "iPhone")
                                .foregroundStyle(.secondary)
                        }
                    }
                    NavigationLink {
                        PhysicalControllerSettingsView()
                            .environmentObject(input)
                            .environmentObject(platform)
                    } label: {
                        Label("Physical Controllers", systemImage: "gamecontroller")
                    }
                }

                Section("Aiming") {
                    LabeledSlider(
                        title: "Look sensitivity",
                        value: settingBinding(\.lookSensitivity),
                        range: 0.25...8,
                        valueLabel: String(format: "%.2fx", platform.settings.lookSensitivity)
                    )
                    Text("Higher values reach full turn speed with a smaller thumb movement.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Display") {
                    Picker("Rendering", selection: resolutionBinding) {
                        ForEach(RenderResolution.allCases, id: \.self) { resolution in
                            Text(resolution.title).tag(resolution)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("Scene resolution relative to screen points. Higher levels are sharper but increase GPU cost; 4× draws 16 times as many pixels as 1×.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle(
                        "Performance HUD",
                        isOn: boolSettingBinding(\.performanceHUDEnabled)
                    )
                    Text("Shows produced game FPS, frame time and 1% low over the game.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Game Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var presetBinding: Binding<ControlPreset> {
        Binding(
            get: { platform.settings.controlPreset },
            set: { preset in platform.updateSettings { $0.controlPreset = preset } }
        )
    }

    private var resolutionBinding: Binding<RenderResolution> {
        Binding(
            get: { platform.settings.renderResolution },
            set: { resolution in
                platform.updateSettings { $0.renderResolution = resolution }
            }
        )
    }

    private func settingBinding(
        _ keyPath: WritableKeyPath<HostSettings, Double>
    ) -> Binding<Double> {
        Binding(
            get: { platform.settings[keyPath: keyPath] },
            set: { value in
                platform.updateSettings { $0[keyPath: keyPath] = value }
            }
        )
    }

    private func boolSettingBinding(
        _ keyPath: WritableKeyPath<HostSettings, Bool>
    ) -> Binding<Bool> {
        Binding(
            get: { platform.settings[keyPath: keyPath] },
            set: { value in
                platform.updateSettings { $0[keyPath: keyPath] = value }
            }
        )
    }
}

private extension RenderResolution {
    var title: String {
        switch self {
        case .x1: "1×"
        case .x2: "2×"
        case .x3: "3×"
        case .x4: "4×"
        }
    }
}

private struct TouchSettingsView: View {
    @EnvironmentObject private var input: InputCoordinator
    @EnvironmentObject private var platform: PlatformCoordinator

    let deviceClass: TouchDeviceClass

    @State private var isEditorPresented = false

    var body: some View {
        Form {
            Section("Aiming") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Aim button")
                        .font(.subheadline)
                    Picker("Aim button", selection: aimBehaviorBinding) {
                        ForEach(TouchAimBehavior.allCases, id: \.self) { behavior in
                            Text(behavior.title).tag(behavior)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Aim button behavior")
                }

                Toggle("Gyroscope aiming", isOn: boolSettingBinding(\.gyroEnabled))
            }

            Section("Overlay") {
                LabeledSlider(
                    title: "Opacity",
                    value: settingBinding(\.touchOpacity),
                    range: 0.25...1,
                    valueLabel: "\(Int((platform.settings.touchOpacity * 100).rounded()))%"
                )
                LabeledSlider(
                    title: "Control size",
                    value: settingBinding(\.touchScale),
                    range: 0.70...1.40,
                    valueLabel: "\(Int((platform.settings.touchScale * 100).rounded()))%"
                )
                Toggle(
                    "Hide when a controller connects",
                    isOn: boolSettingBinding(\.touchControlsAutoHide)
                )
                Toggle("Show movement guide", isOn: boolSettingBinding(\.moveGuideVisible))
                Toggle("Show look guide", isOn: boolSettingBinding(\.lookGuideVisible))
            }

            Section("Layout") {
                Button { isEditorPresented = true } label: {
                    HStack {
                        Label("Edit touch layout", systemImage: "hand.draw")
                        Spacer()
                        Text(deviceClass == .tablet ? "iPad" : "iPhone")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)
            }
        }
        .navigationTitle("Touch Controls")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditorPresented) {
            TouchLayoutEditor(deviceClass: deviceClass)
                .environmentObject(input)
                .environmentObject(platform)
        }
    }

    private var aimBehaviorBinding: Binding<TouchAimBehavior> {
        Binding(
            get: { platform.settings.touchAimBehavior },
            set: { behavior in
                platform.updateSettings { $0.touchAimBehavior = behavior }
            }
        )
    }

    private func settingBinding(
        _ keyPath: WritableKeyPath<HostSettings, Double>
    ) -> Binding<Double> {
        Binding(
            get: { platform.settings[keyPath: keyPath] },
            set: { value in
                platform.updateSettings { $0[keyPath: keyPath] = value }
            }
        )
    }

    private func boolSettingBinding(
        _ keyPath: WritableKeyPath<HostSettings, Bool>
    ) -> Binding<Bool> {
        Binding(
            get: { platform.settings[keyPath: keyPath] },
            set: { value in
                platform.updateSettings { $0[keyPath: keyPath] = value }
            }
        )
    }
}

private struct PhysicalControllerSettingsView: View {
    @EnvironmentObject private var input: InputCoordinator
    @EnvironmentObject private var platform: PlatformCoordinator

    var body: some View {
        Form {
            Section("Player Assignments") {
                ForEach(input.controllerAssignments) { assignment in
                    HStack(spacing: 12) {
                        Image(systemName: assignment.player == 0 ? "hand.tap" : "gamecontroller")
                            .foregroundStyle(
                                assignment.controllerName == nil && assignment.player != 0
                                    ? Color.secondary
                                    : Color.accentColor
                            )
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(assignment.playerTitle)
                            Text(assignment.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if assignment.controllerName != nil {
                            Menu {
                                ForEach(0..<4, id: \.self) { destination in
                                    Button("Player \(destination + 1)") {
                                        input.moveController(
                                            from: assignment.player,
                                            to: destination
                                        )
                                    }
                                    .disabled(destination == assignment.player)
                                }
                            } label: {
                                Label("Move", systemImage: "arrow.left.arrow.right")
                                    .labelStyle(.iconOnly)
                            }
                            .accessibilityLabel(
                                "Move controller from \(assignment.playerTitle)"
                            )
                        }
                    }
                }
                if playerTwoHasController {
                    Label("Two-player touch + gamepad is ready", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("To enable Multiplayer with touch + one gamepad, move the gamepad to Player 2.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("Moving into an occupied slot swaps the two controllers.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Stick Response") {
                LabeledSlider(
                    title: "Dead zone",
                    value: settingBinding(\.stickDeadZone),
                    range: 0...0.40,
                    valueLabel: "\(Int((platform.settings.stickDeadZone * 100).rounded()))%"
                )
            }
            Section("Button Mapping") {
                LabeledContent("Aim / Fire", value: "LT / RT")
                LabeledContent("Confirm / Action", value: "A / B or X")
                LabeledContent("Crouch / Weapon", value: "LB / Y or RB")
                LabeledContent("Pause / Watch", value: "Menu")
            }
        }
        .navigationTitle("Controllers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var playerTwoHasController: Bool {
        input.controllerAssignments.first { $0.player == 1 }?.controllerName != nil
    }

    private func settingBinding(
        _ keyPath: WritableKeyPath<HostSettings, Double>
    ) -> Binding<Double> {
        Binding(
            get: { platform.settings[keyPath: keyPath] },
            set: { value in
                platform.updateSettings { $0[keyPath: keyPath] = value }
            }
        )
    }
}

struct TouchInputLab: View {
    @EnvironmentObject private var input: InputCoordinator
    @EnvironmentObject private var platform: PlatformCoordinator
    @State private var isSettingsPresented = false

    private var deviceClass: TouchDeviceClass {
        UIDevice.current.userInterfaceIdiom == .pad ? .tablet : .phone
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("CONTROL LAB")
                        .font(.caption2.weight(.bold))
                        .tracking(1.4)
                    Text("N64 masks and modern dual-stick share one input frame.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                }
                Spacer()
                Button("Settings") { isSettingsPresented = true }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Open game settings")
            }

            Picker("Control preset", selection: presetBinding) {
                ForEach(ControlPreset.allCases, id: \.self) { preset in
                    Text(preset.title).tag(preset)
                }
            }
            .pickerStyle(.segmented)

            if input.shouldShowTouchControls {
                TouchControlCanvas(
                    placements: platform.touchLayout(deviceClass: deviceClass),
                    opacity: platform.settings.touchOpacity,
                    globalScale: platform.settings.touchScale,
                    input: input
                )
                .frame(height: deviceClass == .tablet ? 250 : 220)
            } else {
                ContentUnavailableView(
                    "External controller active",
                    systemImage: "gamecontroller.fill",
                    description: Text("Touch controls are auto-hidden. Customize to change this behavior.")
                )
                .frame(height: 180)
            }
        }
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
        .sheet(isPresented: $isSettingsPresented) {
            GameplaySettingsView(deviceClass: deviceClass)
                .environmentObject(input)
                .environmentObject(platform)
        }
    }

    private var presetBinding: Binding<ControlPreset> {
        Binding(
            get: { platform.settings.controlPreset },
            set: { preset in platform.updateSettings { $0.controlPreset = preset } }
        )
    }
}

private struct TouchLayoutEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @EnvironmentObject private var input: InputCoordinator
    @EnvironmentObject private var platform: PlatformCoordinator

    let deviceClass: TouchDeviceClass

    @State private var placements: [TouchControlPlacement] = []
    @State private var selectedID: TouchControlID?
    @State private var hasPlacementChanges = false

    private var selectedIndex: Int? {
        placements.firstIndex { $0.id == selectedID }
    }

    private var editorCanvasHeight: CGFloat {
        if verticalSizeClass == .compact {
            return 220
        }
        return deviceClass == .tablet ? 390 : 300
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("INPUT PRESET")
                            .font(.caption2.weight(.bold))
                            .tracking(1.3)
                            .foregroundStyle(.secondary)
                        Picker("Control preset", selection: presetBinding) {
                            ForEach(ControlPreset.allCases, id: \.self) { preset in
                                Text(preset.title).tag(preset)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    TouchControlCanvas(
                        placements: placements,
                        opacity: platform.settings.touchOpacity,
                        globalScale: platform.settings.touchScale,
                        input: input,
                        editing: true,
                        selectedID: selectedID,
                        onSelect: { selectedID = $0 },
                        onMove: updatePlacement
                    )
                    .frame(minHeight: editorCanvasHeight)

                    if let index = selectedIndex {
                        selectedControlPanel(index: index)
                    } else {
                        Text("Tap a control to select it, then drag to move.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                }
                .padding(20)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("\(deviceClass == .tablet ? "iPad" : "iPhone") touch layout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") { resetLayout() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { saveAndDismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                input.releaseTouchInput()
                reloadLayout()
            }
            .onDisappear { input.releaseTouchInput() }
        }
    }

    private func selectedControlPanel(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(placements[index].id.label)
                    .font(.headline)
                Spacer()
                if placements[index].id.canHide {
                    Button(placements[index].isHidden ? "Show" : "Hide") {
                        placements[index].isHidden.toggle()
                        hasPlacementChanges = true
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("\(placements[index].isHidden ? "Show" : "Hide") selected control")
                }
            }
            LabeledSlider(
                title: "Control size",
                value: Binding(
                    get: { placements[index].scale },
                    set: {
                        placements[index].scale = $0
                        hasPlacementChanges = true
                    }
                ),
                range: 0.70...1.50,
                valueLabel: "\(Int((placements[index].scale * 100).rounded()))%"
            )
            HStack(spacing: 10) {
                Text("Position")
                    .font(.subheadline)
                Spacer()
                ForEach([
                    ("arrow.left", -0.025, 0.0),
                    ("arrow.up", 0.0, -0.025),
                    ("arrow.down", 0.0, 0.025),
                    ("arrow.right", 0.025, 0.0),
                ], id: \.0) { item in
                    Button {
                        nudgeSelected(dx: item.1, dy: item.2)
                    } label: {
                        Image(systemName: item.0)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Move selected \(item.0.replacingOccurrences(of: "arrow.", with: ""))")
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var presetBinding: Binding<ControlPreset> {
        Binding(
            get: { platform.settings.controlPreset },
            set: { preset in
                let previousPreset = platform.settings.controlPreset
                if hasPlacementChanges {
                    platform.saveTouchLayout(
                        placements,
                        deviceClass: deviceClass,
                        preset: previousPreset
                    )
                }
                platform.updateSettings { $0.controlPreset = preset }
                reloadLayout()
            }
        )
    }

    private func updatePlacement(_ placement: TouchControlPlacement) {
        guard let index = placements.firstIndex(where: { $0.id == placement.id }) else { return }
        placements[index] = placement.sanitized()
        hasPlacementChanges = true
    }

    private func nudgeSelected(dx: Double, dy: Double) {
        guard let index = selectedIndex else { return }
        placements[index].x += dx
        placements[index].y += dy
        placements[index] = placements[index].sanitized()
        hasPlacementChanges = true
    }

    private func reloadLayout() {
        placements = platform.touchLayout(deviceClass: deviceClass)
        selectedID = placements.first?.id
        hasPlacementChanges = false
    }

    private func resetLayout() {
        platform.resetTouchLayout(deviceClass: deviceClass)
        reloadLayout()
    }

    private func saveAndDismiss() {
        if hasPlacementChanges {
            platform.saveTouchLayout(placements, deviceClass: deviceClass)
        }
        dismiss()
    }
}

private struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let valueLabel: String

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(valueLabel)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.subheadline)
            Slider(value: $value, in: range)
                .accessibilityLabel(title)
        }
    }
}

private struct TouchControlCanvas: View {
    let placements: [TouchControlPlacement]
    let opacity: Double
    let globalScale: Double
    let input: InputCoordinator
    var showsBackground = true
    var showsMoveGuide = true
    var showsLookGuide = true
    var editing = false
    var selectedID: TouchControlID?
    var onSelect: ((TouchControlID) -> Void)?
    var onMove: ((TouchControlPlacement) -> Void)?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if showsBackground {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.black.opacity(0.86))
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(editing ? 0.15 : 0), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .padding(12)
                }

                ForEach(placements) { placement in
                    if editing || !placement.isHidden {
                        control(placement, in: geometry.size)
                    }
                }
            }
            .coordinateSpace(name: "touch-canvas")
            .clipped()
        }
    }

    @ViewBuilder
    private func control(_ placement: TouchControlPlacement, in size: CGSize) -> some View {
        let controlScale = CGFloat(placement.scale * globalScale) * canvasScale(for: size)
        let baseSize = controlBaseSize(placement.id, editing: editing)
        let control = TouchControlVisual(
            id: placement.id,
            input: input,
            editing: editing,
            selected: selectedID == placement.id,
            showsGuide: placement.id == .move
                ? showsMoveGuide
                : placement.id == .look ? showsLookGuide : true
        )
        .frame(
            width: baseSize.width * controlScale,
            height: baseSize.height * controlScale
        )
        .opacity(editing && placement.isHidden ? 0.28 : opacity)
        .position(x: size.width * placement.x, y: size.height * placement.y)

        if editing {
            control
                .onTapGesture { onSelect?(placement.id) }
                .highPriorityGesture(
                    DragGesture(minimumDistance: 2, coordinateSpace: .named("touch-canvas"))
                .onChanged { value in
                    onSelect?(placement.id)
                    var moved = placement
                    moved.x = value.location.x / max(size.width, 1)
                    moved.y = value.location.y / max(size.height, 1)
                    onMove?(moved.sanitized())
                }
                )
                .accessibilityLabel(placement.id.label)
                .accessibilityValue(placement.isHidden ? "Hidden" : "Visible")
        } else {
            control
                .accessibilityLabel(placement.id.label)
        }
    }

    private func canvasScale(for size: CGSize) -> CGFloat {
        min(max(size.width / 720, 0.62), 1.18)
    }

    private func controlBaseSize(_ id: TouchControlID, editing: Bool) -> CGSize {
        switch id {
        case .move:
            // The live movement surface is a generous bottom-corner zone. The
            // editor keeps a compact marker so it remains easy to reposition.
            editing
                ? CGSize(width: 128, height: 128)
                : CGSize(width: 300, height: 260)
        case .look: CGSize(width: 320, height: 220)
        case .pause, .n64Start, .weapon, .crouch, .n64L, .n64R:
            CGSize(width: 64, height: 64)
        case .n64CUp, .n64CDown, .n64CLeft, .n64CRight,
             .n64DUp, .n64DDown, .n64DLeft, .n64DRight:
            CGSize(width: 48, height: 48)
        default: CGSize(width: 70, height: 70)
        }
    }
}

private struct TouchControlVisual: View {
    let id: TouchControlID
    @ObservedObject var input: InputCoordinator
    let editing: Bool
    let selected: Bool
    let showsGuide: Bool

    var body: some View {
        Group {
            if editing {
                EditorControlFace(id: id, tint: tint)
            } else if id == .move {
                VirtualStick(
                    title: id.label,
                    systemImage: "figure.walk",
                    showsGuide: showsGuide
                ) {
                    input.updateMovement($0)
                }
            } else if id == .look {
                LookSurface(showsGuide: showsGuide) { input.updateLook($0) }
            } else if id == .aim, input.touchAimBehavior == .toggle {
                ToggleAction(
                    title: id.label,
                    tint: tint,
                    isOn: input.isTouchButtonPressed(.aim)
                ) {
                    input.toggleTouchButton(.aim)
                }
            } else {
                MomentaryAction(title: id.label, tint: tint) {
                    guard let button = id.inputButton else { return }
                    input.setTouchButton(button, pressed: $0)
                }
            }
        }
        .overlay {
            if selected {
                if id == .look {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.yellow, lineWidth: 3)
                        .padding(-4)
                } else {
                    Circle().stroke(.yellow, lineWidth: 3).padding(-4)
                }
            }
        }
    }

    private var tint: Color {
        switch id {
        case .fire, .n64Z: .orange
        case .aim, .n64R: .mint
        case .n64A: .blue
        case .n64B: .green
        case .pause, .n64Start: .red
        case .n64CUp, .n64CDown, .n64CLeft, .n64CRight: .yellow
        default: .cyan
        }
    }
}

private struct EditorControlFace: View {
    let id: TouchControlID
    let tint: Color

    var body: some View {
        ZStack {
            if id == .look {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.black.opacity(0.40))
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.36), lineWidth: 1)
                Image(systemName: "scope")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.60))
                Text("DRAG TO LOOK")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.68))
                    .offset(y: 30)
            } else {
                Circle().fill(.black.opacity(0.58))
                Circle().stroke(.white.opacity(0.42), lineWidth: 1)
            }
            if id == .move {
                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: id == .move ? "figure.walk" : "eye")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.82))
                Text(id.label)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .offset(y: 34)
            } else {
                Text(id.label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(tint)
                    .padding(4)
            }
        }
    }
}

private struct LookSurface: View {
    let showsGuide: Bool
    let onChange: (SIMD2<Float>) -> Void

    @State private var normalized = SIMD2<Float>.zero
    @State private var isTracking = false
    @State private var lastLocation: CGPoint?

    var body: some View {
        GeometryReader { geometry in
            let responseDistance = max(min(geometry.size.width, geometry.size.height) * 0.05, 10)

            ZStack {
                // Keep a real rendered surface in the hierarchy even when the
                // guide is hidden. An empty ZStack has no hit-testable content,
                // so contentShape alone cannot receive the drag gesture.
                Rectangle()
                    .fill(.white.opacity(0.001))
                if showsGuide {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.black.opacity(isTracking ? 0.16 : 0.08))
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(isTracking ? 0.24 : 0.12), lineWidth: 1)
                    Image(systemName: "scope")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(isTracking ? 0.72 : 0.34))
                        .offset(
                            x: CGFloat(normalized.x) * 18,
                            y: CGFloat(-normalized.y) * 18
                        )
                    Text("LOOK")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.36))
                        .offset(y: 30)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isTracking = true
                        guard let previous = lastLocation else {
                            lastLocation = value.location
                            return
                        }
                        var vector = SIMD2<Float>(
                            Float((value.location.x - previous.x) / responseDistance),
                            Float((previous.y - value.location.y) / responseDistance)
                        )
                        lastLocation = value.location
                        let magnitude = simd_length(vector)
                        if magnitude > 1 { vector /= magnitude }
                        normalized = vector
                        onChange(vector)
                    }
                    .onEnded { _ in
                        isTracking = false
                        lastLocation = nil
                        normalized = .zero
                        onChange(.zero)
                    }
            )
        }
        .accessibilityLabel("Look")
        .accessibilityHint("Swipe anywhere in this area to aim")
    }
}

private extension TouchControlID {
    var inputButton: InputButtons? {
        switch self {
        case .move, .look: nil
        case .fire: .fire
        case .aim: .aim
        case .interact: .interact
        case .reload: .reload
        case .crouch: .crouch
        case .weapon: .nextWeapon
        case .pause: .pause
        case .n64A: .n64A
        case .n64B: .n64B
        case .n64Z: .n64Z
        case .n64L: .n64L
        case .n64R: .n64R
        case .n64Start: .n64Start
        case .n64CUp: .n64CUp
        case .n64CDown: .n64CDown
        case .n64CLeft: .n64CLeft
        case .n64CRight: .n64CRight
        case .n64DUp: .dpadUp
        case .n64DDown: .dpadDown
        case .n64DLeft: .dpadLeft
        case .n64DRight: .dpadRight
        }
    }
}

private extension ControlPreset {
    var title: String {
        switch self {
        case .classic: "N64"
        case .modern: "Modern"
        case .southpaw: "Southpaw"
        }
    }
}

private extension TouchAimBehavior {
    var title: String {
        switch self {
        case .toggle: "Toggle"
        case .hold: "Hold"
        }
    }
}

private struct VirtualStick: View {
    let title: String
    let systemImage: String
    let showsGuide: Bool
    let onChange: (SIMD2<Float>) -> Void

    @State private var normalized = SIMD2<Float>.zero
    @State private var isTracking = false
    @State private var anchor: CGPoint?

    var body: some View {
        GeometryReader { geometry in
            let diameter = min(min(geometry.size.width, geometry.size.height) * 0.52, 150)
            let travel = diameter * 0.27
            let center = anchor ?? CGPoint(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )

            ZStack {
                // Visually invisible, but intentionally nonzero-alpha so the
                // movement zone continues to participate in hit testing.
                Rectangle()
                    .fill(.white.opacity(0.001))
                if showsGuide || isTracking {
                    Circle()
                        .fill(.black.opacity(0.42))
                        .frame(width: diameter, height: diameter)
                        .position(center)
                    Circle()
                        .stroke(.white.opacity(0.34), lineWidth: 1)
                        .frame(width: diameter, height: diameter)
                        .position(center)
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: diameter * 0.46, height: diameter * 0.46)
                        .overlay {
                            Image(systemName: systemImage)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .position(
                            x: center.x + CGFloat(normalized.x) * travel,
                            y: center.y - CGFloat(normalized.y) * travel
                        )
                    Text(title)
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.6))
                        .position(x: center.x, y: center.y + diameter * 0.38)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isTracking {
                            isTracking = true
                            anchor = value.location
                            normalized = .zero
                            onChange(.zero)
                            return
                        }
                        let activeCenter = anchor ?? value.startLocation
                        // Reach a full N64 stick before the thumb reaches the
                        // edge of the touch zone, making running practical.
                        let radius = max(diameter * 0.325, 1)
                        var vector = SIMD2<Float>(
                            Float((value.location.x - activeCenter.x) / radius),
                            Float((activeCenter.y - value.location.y) / radius)
                        )
                        let magnitude = simd_length(vector)
                        if magnitude > 1 { vector /= magnitude }
                        normalized = vector
                        onChange(vector)
                    }
                    .onEnded { _ in
                        isTracking = false
                        anchor = nil
                        normalized = .zero
                        onChange(.zero)
                    }
            )
        }
        .accessibilityLabel("Move")
        .accessibilityHint("Touch anywhere in the lower-left area, then drag to move")
    }
}

private struct MomentaryAction: View {
    let title: String
    let tint: Color
    let onChange: (Bool) -> Void

    @State private var pressed = false

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .minimumScaleFactor(0.65)
            .foregroundStyle(pressed ? .black : .white.opacity(0.88))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                pressed ? tint : .black.opacity(0.46),
                in: Circle()
            )
            .overlay { Circle().stroke(.white.opacity(0.34), lineWidth: 1) }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !pressed else { return }
                        pressed = true
                        onChange(true)
                    }
                    .onEnded { _ in
                        pressed = false
                        onChange(false)
                    }
            )
            .accessibilityAddTraits(.isButton)
    }
}

private struct ToggleAction: View {
    let title: String
    let tint: Color
    let isOn: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.65)
                .foregroundStyle(isOn ? .black : .white.opacity(0.88))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isOn ? tint : .black.opacity(0.46), in: Circle())
                .overlay { Circle().stroke(.white.opacity(0.34), lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityValue(isOn ? "On" : "Off")
    }
}
