import Foundation
import GameController
import SwiftUI
import simd

@_silgen_name("goldenpad_recomp_set_controller_state")
private func goldenPadRecompSetControllerState(
    _ buttons: UInt32,
    _ stickX: Int32,
    _ stickY: Int32
)

@_silgen_name("goldenpad_recomp_set_right_analog")
private func goldenPadRecompSetRightAnalog(_ x: Int32, _ y: Int32)

@_silgen_name("goldenpad_recomp_set_controller_connected")
private func goldenPadRecompSetControllerConnected(_ connected: Int32)

@_silgen_name("goldenpad_recomp_queue_touch_look")
private func goldenPadRecompQueueTouchLook(_ x: Int32, _ y: Int32)

@_silgen_name("goldenpad_recomp_request_crouch_toggle")
private func goldenPadRecompRequestCrouchToggle()

@_silgen_name("goldenpad_recomp_set_invert_aim_y")
private func goldenPadRecompSetInvertAimY(_ enabled: Int32)

@_silgen_name("goldenpad_recomp_set_unlock_all_missions")
private func goldenPadRecompSetUnlockAllMissions(_ enabled: Int32)

enum RecompPrototypeAimBehavior: String, CaseIterable {
    case toggle
    case hold

    var title: String {
        switch self {
        case .toggle: "Toggle"
        case .hold: "Hold"
        }
    }
}

enum RecompPrototypeControllerLookMode: String, CaseIterable {
    case analog
    case classic
    case off

    var title: String {
        switch self {
        case .analog: "Modern analog (experimental)"
        case .classic: "Original N64 C-buttons"
        case .off: "Off"
        }
    }
}

@MainActor
final class RecompPrototypeInput: ObservableObject {
    private enum N64 {
        static let a: UInt16 = 0x8000
        static let b: UInt16 = 0x4000
        static let z: UInt16 = 0x2000
        static let start: UInt16 = 0x1000
        static let dpadUp: UInt16 = 0x0800
        static let dpadDown: UInt16 = 0x0400
        static let dpadLeft: UInt16 = 0x0200
        static let dpadRight: UInt16 = 0x0100
        static let l: UInt16 = 0x0020
        static let r: UInt16 = 0x0010
        static let cUp: UInt16 = 0x0008
        static let cDown: UInt16 = 0x0004
        static let cLeft: UInt16 = 0x0002
        static let cRight: UInt16 = 0x0001
    }

    @Published private(set) var externalControllerName: String?
    @Published private(set) var touchAimActive = false
    @Published private(set) var aimBehavior = RecompPrototypeAimBehavior.toggle
    @Published private(set) var controllerLookMode = RecompPrototypeControllerLookMode.analog
    private var touchButtons: UInt16 = 0
    private var touchMovement = SIMD2<Float>.zero
    private var touchLook = SIMD2<Float>.zero
    private var touchCrouchIsPressed = false
    private var controllerCrouchWasPressed = false
    private var lookSensitivity: Float = 4.0
    private var controller: GCController?
    private var observers: [NSObjectProtocol] = []
    private var ticker: Timer?

    init() {
        refreshController()
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refreshController() }
        })
        observers.append(center.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refreshController() }
        })
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.publish() }
        }
        publish()
    }

    deinit {
        ticker?.invalidate()
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func setMovement(_ value: SIMD2<Float>) {
        touchMovement = clamp(value)
        publish()
    }

    func configureLookSensitivity(_ value: Double) {
        lookSensitivity = Float(min(max(value, 0.5), 8.0))
    }

    func configureAimBehavior(_ rawValue: String) {
        let next = RecompPrototypeAimBehavior(rawValue: rawValue) ?? .toggle
        guard aimBehavior != next else { return }
        aimBehavior = next
        touchAimActive = false
        setButton(N64.r, pressed: false)
    }

    func configureControllerLookMode(_ rawValue: String) {
        controllerLookMode = RecompPrototypeControllerLookMode(rawValue: rawValue) ?? .analog
        publish()
    }

    func configureInvertAimY(_ enabled: Bool) {
        goldenPadRecompSetInvertAimY(enabled ? 1 : 0)
    }

    func configureUnlockAllMissions(_ enabled: Bool) {
        goldenPadRecompSetUnlockAllMissions(enabled ? 1 : 0)
    }

    func setLook(_ value: SIMD2<Float>) {
        // Preserve GoldenPad's tuned relative-look path: amplify each swipe
        // delta by 1.5x and accumulate until the next 60 Hz publication.
        guard value != .zero else { return }
        touchLook = clamp(touchLook + value * 1.5)
    }

    func setCrouchPressed(_ pressed: Bool) {
        if pressed && !touchCrouchIsPressed {
            goldenPadRecompRequestCrouchToggle()
        }
        touchCrouchIsPressed = pressed
    }

    func toggleAim() {
        touchAimActive.toggle()
        setButton(N64.r, pressed: touchAimActive)
    }

    func setAimPressed(_ pressed: Bool) {
        touchAimActive = pressed
        setButton(N64.r, pressed: pressed)
    }

    func setButton(_ button: UInt16, pressed: Bool) {
        if pressed {
            touchButtons |= button
        } else {
            touchButtons &= ~button
        }
        publish()
    }

    func releaseTouchInput() {
        touchButtons = 0
        touchAimActive = false
        touchMovement = .zero
        touchLook = .zero
        touchCrouchIsPressed = false
        publish()
    }

    private func refreshController() {
        controller = GCController.controllers().first(where: { $0.extendedGamepad != nil })
        controllerCrouchWasPressed = false
        externalControllerName = controller.map { $0.vendorName ?? "External controller" }
        if controller != nil {
            releaseTouchInput()
        }
        goldenPadRecompSetControllerConnected(controller == nil ? 0 : 1)
        publish()
    }

    private func publish() {
        var buttons = touchButtons
        var stick = touchMovement
        let queuedTouchLook = clamp(touchLook * lookSensitivity)
        touchLook = .zero
        var controllerLook = SIMD2<Float>.zero

        if let gamepad = controller?.extendedGamepad {
            stick = merge(stick, SIMD2(gamepad.leftThumbstick.xAxis.value, gamepad.leftThumbstick.yAxis.value))
            controllerLook = SIMD2(
                gamepad.rightThumbstick.xAxis.value,
                gamepad.rightThumbstick.yAxis.value
            )
                .applyingRadialDeadZone(0.15)
                .applyingResponseCurve(1.5)
            if gamepad.rightTrigger.value > 0.25 { buttons |= N64.z }
            if gamepad.leftTrigger.value > 0.25 { buttons |= N64.r }
            if gamepad.buttonA.isPressed || gamepad.buttonY.isPressed { buttons |= N64.a }
            if gamepad.buttonB.isPressed || gamepad.buttonX.isPressed { buttons |= N64.b }
            if gamepad.rightShoulder.isPressed { buttons |= N64.a }
            let controllerCrouchIsPressed = gamepad.leftShoulder.isPressed
            if controllerCrouchIsPressed && !controllerCrouchWasPressed {
                goldenPadRecompRequestCrouchToggle()
            }
            controllerCrouchWasPressed = controllerCrouchIsPressed
            if gamepad.buttonMenu.isPressed { buttons |= N64.start }
            if gamepad.dpad.up.isPressed { buttons |= N64.dpadUp }
            if gamepad.dpad.down.isPressed { buttons |= N64.dpadDown }
            if gamepad.dpad.left.isPressed { buttons |= N64.dpadLeft }
            if gamepad.dpad.right.isPressed { buttons |= N64.dpadRight }
        }

        switch controllerLookMode {
        case .analog:
            break
        case .classic:
            let threshold: Float = 0.30
            if controllerLook.y > threshold { buttons |= N64.cUp }
            if controllerLook.y < -threshold { buttons |= N64.cDown }
            if controllerLook.x < -threshold { buttons |= N64.cLeft }
            if controllerLook.x > threshold { buttons |= N64.cRight }
            controllerLook = .zero
        case .off:
            controllerLook = .zero
        }

        // The saved 4x tuning belongs to relative touch deltas. A physical
        // right stick is an absolute value published every frame; multiplying
        // it by 4x saturated the camera at roughly one-quarter stick travel.
        // Keep the post-dead-zone controller value normalized instead.
        goldenPadRecompSetControllerState(
            UInt32(buttons),
            Int32((clamp(stick).x * 80).rounded()),
            Int32((clamp(stick).y * 80).rounded())
        )
        goldenPadRecompSetRightAnalog(
            Int32((controllerLook.x * 32_767).rounded()),
            Int32((controllerLook.y * 32_767).rounded())
        )
        if queuedTouchLook != .zero {
            goldenPadRecompQueueTouchLook(
                Int32((queuedTouchLook.x * 32_767).rounded()),
                Int32((queuedTouchLook.y * 32_767).rounded())
            )
        }
    }

    private func merge(_ lhs: SIMD2<Float>, _ rhs: SIMD2<Float>) -> SIMD2<Float> {
        simd_length_squared(rhs) > simd_length_squared(lhs) ? rhs : lhs
    }

    private func clamp(_ value: SIMD2<Float>) -> SIMD2<Float> {
        let magnitude = simd_length(value)
        return magnitude > 1 ? value / magnitude : value
    }
}

struct RecompPrototypeTouchControls: View {
    @ObservedObject var input: RecompPrototypeInput

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // This is the production GoldenPad modern schema: the same
                // movement/look zones, action rail, labels, and iPad-relative
                // placement. Only the final N64 masks differ in this isolated
                // runtime bridge.
                ForEach(RecompTouchPlacement.productionSchema) { placement in
                    control(placement, canvas: geometry.size)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .onDisappear { input.releaseTouchInput() }
    }

    @ViewBuilder
    private func control(_ placement: RecompTouchPlacement, canvas: CGSize) -> some View {
        let scale = min(max(canvas.width / 720, 0.62), 1.18) * placement.scale
        Group {
            switch placement.id {
            case .move:
                RecompStick(title: placement.id.label, symbol: "figure.walk") { input.setMovement($0) }
                    .frame(width: 300 * scale, height: 260 * scale)
            case .look:
                RecompLookSurface { input.setLook($0) }
                    .frame(width: 320 * scale, height: 220 * scale)
            case .aim:
                if input.aimBehavior == .toggle {
                    RecompToggleButton(
                        title: placement.id.label,
                        tint: placement.id.tint,
                        activeTint: .yellow,
                        isOn: input.touchAimActive
                    ) {
                        input.toggleAim()
                    }
                    .frame(width: 70 * scale, height: 70 * scale)
                } else {
                    RecompMomentaryButton(
                        title: placement.id.label,
                        tint: placement.id.tint,
                        pressedTint: .yellow
                    ) {
                        input.setAimPressed($0)
                    }
                    .frame(width: 70 * scale, height: 70 * scale)
                }
            default:
                RecompMomentaryButton(
                    title: placement.id.label,
                    tint: placement.id.tint
                ) {
                    if placement.id == .crouch {
                        input.setCrouchPressed($0)
                    } else {
                        input.setButton(placement.id.n64Mask, pressed: $0)
                    }
                }
                .frame(width: placement.id == .pause ? 64 * scale : 70 * scale,
                       height: placement.id == .pause ? 64 * scale : 70 * scale)
            }
        }
        .opacity(0.72)
        .position(x: canvas.width * placement.x, y: canvas.height * placement.y)
        .accessibilityLabel(placement.id.label)
    }
}

private enum RecompTouchControlID: String {
    case move, look, fire, aim, action, crouch, weapon, pause

    var label: String {
        switch self {
        case .move: "MOVE"
        case .look: "LOOK"
        case .fire: "FIRE"
        case .aim: "AIM"
        case .action: "ACTION"
        case .crouch: "DUCK"
        case .weapon: "WEAPON"
        case .pause: "START"
        }
    }

    var n64Mask: UInt16 {
        switch self {
        case .move, .look: 0
        case .fire: 0x2000       // Z trigger
        case .aim: 0x0010        // R trigger
        case .action: 0x4000     // B
        case .crouch: 0           // Native edge-triggered crouch toggle
        case .weapon: 0x8000     // A
        case .pause: 0x1000      // Start
        }
    }

    var tint: Color {
        switch self {
        // GoldenEye uses Z to fire and R to aim, so those triggers stay
        // neutral grey. The face-button actions use the N64 A/B colors.
        case .fire: .gray
        case .aim: .gray
        case .weapon: .blue
        case .action: .green
        case .crouch: .yellow
        case .pause: .red
        default: .cyan
        }
    }
}

private extension SIMD2 where Scalar == Float {
    func applyingRadialDeadZone(_ deadZone: Float) -> SIMD2<Float> {
        let magnitude = simd_length(self)
        guard magnitude > deadZone else { return .zero }
        guard magnitude > 0 else { return .zero }
        return (self / magnitude) * Swift.min((magnitude - deadZone) / (1 - deadZone), 1)
    }

    func applyingResponseCurve(_ exponent: Float) -> SIMD2<Float> {
        let magnitude = simd_length(self)
        guard magnitude > 0 else { return .zero }
        return (self / magnitude) * pow(magnitude, exponent)
    }
}

private struct RecompTouchPlacement: Identifiable {
    let id: RecompTouchControlID
    let x: CGFloat
    let y: CGFloat
    let scale: CGFloat

    static let productionSchema: [RecompTouchPlacement] = [
        .init(id: .move, x: 0.13, y: 0.82, scale: 1.14),
        .init(id: .look, x: 0.78, y: 0.72, scale: 1),
        .init(id: .fire, x: 0.91, y: 0.71, scale: 1.16),
        .init(id: .aim, x: 0.91, y: 0.58, scale: 1),
        .init(id: .action, x: 0.91, y: 0.84, scale: 0.94),
        .init(id: .crouch, x: 0.81, y: 0.89, scale: 0.82),
        .init(id: .weapon, x: 0.71, y: 0.89, scale: 0.82),
        .init(id: .pause, x: 0.972, y: 0.14, scale: 0.78),
    ]
}

private struct RecompStick: View {
    let title: String
    let symbol: String
    let onChange: (SIMD2<Float>) -> Void
    @State private var anchor: CGPoint?
    @State private var value = SIMD2<Float>.zero

    var body: some View {
        GeometryReader { geometry in
            let center = anchor ?? CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let diameter = min(geometry.size.width, geometry.size.height) * 0.56
            ZStack {
                Rectangle().fill(.white.opacity(0.001))
                Circle().fill(.black.opacity(0.33)).frame(width: diameter, height: diameter).position(center)
                Circle().stroke(.white.opacity(0.34), lineWidth: 1).frame(width: diameter, height: diameter).position(center)
                Circle().fill(.white.opacity(0.18)).frame(width: diameter * 0.44, height: diameter * 0.44)
                    .overlay(Image(systemName: symbol).foregroundStyle(.white.opacity(0.8)))
                    .position(x: center.x + CGFloat(value.x) * diameter * 0.25, y: center.y - CGFloat(value.y) * diameter * 0.25)
                Text(title).font(.system(size: 9, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.white.opacity(0.6)).position(x: center.x, y: center.y + diameter * 0.36)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { gesture in
                if anchor == nil { anchor = gesture.location }
                let origin = anchor ?? gesture.location
                let radius = max(diameter * 0.325, 1)
                var next = SIMD2<Float>(Float((gesture.location.x - origin.x) / radius), Float((origin.y - gesture.location.y) / radius))
                if simd_length(next) > 1 { next /= simd_length(next) }
                value = next
                onChange(next)
            }.onEnded { _ in
                anchor = nil
                value = .zero
                onChange(.zero)
            })
        }
        .accessibilityLabel(title)
    }
}

private struct RecompLookSurface: View {
    let onChange: (SIMD2<Float>) -> Void
    @State private var lastLocation: CGPoint?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(.black.opacity(0.10))
                RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.14), lineWidth: 1)
                VStack(spacing: 6) {
                    Image(systemName: "scope").foregroundStyle(.white.opacity(0.42))
                    Text("LOOK").font(.system(size: 9, weight: .bold, design: .rounded)).tracking(1).foregroundStyle(.white.opacity(0.42))
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { gesture in
                guard let previous = lastLocation else { lastLocation = gesture.location; return }
                let scale = max(min(geometry.size.width, geometry.size.height) * 0.05, 10)
                var next = SIMD2<Float>(Float((gesture.location.x - previous.x) / scale), Float((previous.y - gesture.location.y) / scale))
                if simd_length(next) > 1 { next /= simd_length(next) }
                lastLocation = gesture.location
                onChange(next)
            }.onEnded { _ in
                lastLocation = nil
                onChange(.zero)
            })
        }
        .accessibilityLabel("Look")
    }
}

private struct RecompMomentaryButton: View {
    let title: String
    let tint: Color
    let pressedTint: Color
    let onChange: (Bool) -> Void
    @State private var pressed = false

    init(
        title: String,
        tint: Color,
        pressedTint: Color? = nil,
        onChange: @escaping (Bool) -> Void
    ) {
        self.title = title
        self.tint = tint
        self.pressedTint = pressedTint ?? tint
        self.onChange = onChange
    }

    var body: some View {
        Text(title)
            .font(.system(size: title == "START" ? 8 : 12, weight: .bold, design: .rounded))
            .foregroundStyle(pressed ? .black : .white.opacity(0.96))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(pressed ? pressedTint : tint.opacity(0.56), in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.52), lineWidth: 1))
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { _ in
                guard !pressed else { return }
                pressed = true
                onChange(true)
            }.onEnded { _ in
                pressed = false
                onChange(false)
            })
            .accessibilityLabel(title)
    }
}

private struct RecompToggleButton: View {
    let title: String
    let tint: Color
    let activeTint: Color
    let isOn: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(isOn ? .black : .white.opacity(0.96))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isOn ? activeTint : tint.opacity(0.56), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.52), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "Locked" : "Off")
        .accessibilityHint("Tap to lock aim so look and fire remain available")
    }
}
