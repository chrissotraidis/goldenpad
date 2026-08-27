import Foundation
import GameController
import SwiftUI
import simd

@_silgen_name("goldenpad_recomp_set_controller_state")
private func goldenPadRecompSetControllerState(
    _ controller: Int32,
    _ buttons: UInt32,
    _ stickX: Int32,
    _ stickY: Int32
)

@_silgen_name("goldenpad_recomp_set_right_analog")
private func goldenPadRecompSetRightAnalog(_ controller: Int32, _ x: Int32, _ y: Int32)

@_silgen_name("goldenpad_recomp_set_controller_connected")
private func goldenPadRecompSetControllerConnected(_ connected: Int32)

@_silgen_name("goldenpad_recomp_set_touch_input_port")
private func goldenPadRecompSetTouchInputPort(_ port: Int32)

@_silgen_name("goldenpad_recomp_set_two_player_test_mode")
private func goldenPadRecompSetTwoPlayerTestMode(_ enabled: Int32)

@_silgen_name("goldenpad_recomp_set_four_player_test_mode")
private func goldenPadRecompSetFourPlayerTestMode(_ enabled: Int32)

@_silgen_name("goldenpad_recomp_queue_touch_look")
private func goldenPadRecompQueueTouchLook(_ controller: Int32, _ x: Int32, _ y: Int32)

@_silgen_name("goldenpad_recomp_request_crouch_toggle")
private func goldenPadRecompRequestCrouchToggle(_ controller: Int32)

@_silgen_name("goldenpad_recomp_set_invert_aim_y")
private func goldenPadRecompSetInvertAimY(_ enabled: Int32)

@_silgen_name("goldenpad_recomp_set_unlock_all_missions")
private func goldenPadRecompSetUnlockAllMissions(_ enabled: Int32)

@_silgen_name("goldenpad_recomp_request_return_to_title")
private func goldenPadRecompRequestReturnToTitle()

@_silgen_name("goldenpad_recomp_set_fire_rate_probe_enabled")
private func goldenPadRecompSetFireRateProbeEnabled(_ enabled: Int32)

@_silgen_name("goldenpad_recomp_gameplay_input_active")
private func goldenPadRecompGameplayInputActive() -> Int32

@_silgen_name("goldenpad_recomp_get_input_context")
private func goldenPadRecompGetInputContext(
    _ controller: Int32,
    _ gameplayActive: UnsafeMutablePointer<Int32>,
    _ controlStyle: UnsafeMutablePointer<Int32>,
    _ aiming: UnsafeMutablePointer<Int32>,
    _ tankState: UnsafeMutablePointer<Int32>,
    _ nativeLookUpright: UnsafeMutablePointer<Int32>
)

@_silgen_name("goldenpad_recomp_set_sidestep_probe_enabled")
private func goldenPadRecompSetSidestepProbeEnabled(_ enabled: Int32)

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

enum RecompPrototypeControllerAction: String, CaseIterable {
    case fire
    case aim
    case action
    case weapon
    case duck
    case none

    var title: String {
        switch self {
        case .fire: "Fire"
        case .aim: "Aim"
        case .action: "Action"
        case .weapon: "Change weapon"
        case .duck: "Duck"
        case .none: "Unassigned"
        }
    }
}

enum RecompPrototypeControllerControl: String, CaseIterable, Identifiable {
    case buttonA
    case buttonB
    case buttonX
    case buttonY
    case leftShoulder
    case rightShoulder
    case leftTrigger
    case rightTrigger

    var id: String { rawValue }

    var title: String {
        switch self {
        case .buttonA: "A button"
        case .buttonB: "B button"
        case .buttonX: "X button"
        case .buttonY: "Y button"
        case .leftShoulder: "Left bumper"
        case .rightShoulder: "Right bumper"
        case .leftTrigger: "Left trigger"
        case .rightTrigger: "Right trigger"
        }
    }

    var defaultAction: RecompPrototypeControllerAction {
        switch self {
        case .buttonA, .buttonY, .rightShoulder: .weapon
        case .buttonB, .buttonX: .action
        case .leftShoulder: .duck
        case .leftTrigger: .aim
        case .rightTrigger: .fire
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

    private struct InputOwnershipRoute: Equatable {
        var externalPort: Int32?
        var touchPort: Int32?
        var twoPlayerActive: Bool
    }

    private enum InputOwnershipRouter {
        static func route(
            controllerPresent: Bool,
            twoPlayerRequested: Bool
        ) -> InputOwnershipRoute {
            if controllerPresent {
                return InputOwnershipRoute(
                    externalPort: 0,
                    touchPort: twoPlayerRequested ? 1 : nil,
                    twoPlayerActive: twoPlayerRequested
                )
            }
            return InputOwnershipRoute(
                externalPort: nil,
                touchPort: twoPlayerRequested ? nil : 0,
                twoPlayerActive: false
            )
        }

        static var disconnectProbePasses: Bool {
            let touchOnly = route(controllerPresent: false, twoPlayerRequested: false)
            let externalOnly = route(controllerPresent: true, twoPlayerRequested: false)
            let paired = route(controllerPresent: true, twoPlayerRequested: true)
            let disconnected = route(controllerPresent: false, twoPlayerRequested: true)
            let reconnected = route(controllerPresent: true, twoPlayerRequested: true)
            let explicitCollapse = route(controllerPresent: false, twoPlayerRequested: false)
            return touchOnly == InputOwnershipRoute(
                externalPort: nil, touchPort: 0, twoPlayerActive: false
            ) && externalOnly == InputOwnershipRoute(
                externalPort: 0, touchPort: nil, twoPlayerActive: false
            ) && paired == InputOwnershipRoute(
                externalPort: 0, touchPort: 1, twoPlayerActive: true
            ) && disconnected == InputOwnershipRoute(
                externalPort: nil, touchPort: nil, twoPlayerActive: false
            ) && reconnected == paired && explicitCollapse == touchOnly
        }

        static func retainedController<ID: Equatable>(
            current: ID?,
            available: [ID]
        ) -> ID? {
            if let current, available.contains(current) { return current }
            return available.first
        }

        static var orderingProbePasses: Bool {
            let controllerA = retainedController(current: nil, available: ["A"])
            let afterBConnect = retainedController(current: controllerA, available: ["B", "A"])
            let afterADisconnect = retainedController(current: afterBConnect, available: ["B"])
            let afterAReconnect = retainedController(
                current: afterADisconnect,
                available: ["A", "B"]
            )
            return controllerA == "A" && afterBConnect == "A" &&
                afterADisconnect == "B" && afterAReconnect == "B"
        }
    }

    private enum InputSuspensionRouter {
        static func isSuspended(overlay: Bool, scene: Bool) -> Bool {
            overlay || scene
        }

        static var lifecycleProbePasses: Bool {
            !isSuspended(overlay: false, scene: false) &&
                isSuspended(overlay: true, scene: false) &&
                isSuspended(overlay: false, scene: true) &&
                isSuspended(overlay: true, scene: true)
        }
    }

    private enum ControllerActivationGuard {
        static func waitingForNeutral(
            current: Bool,
            controllerChanged: Bool,
            controllerPresent: Bool,
            inputIsNeutral: Bool
        ) -> Bool {
            if controllerChanged { return controllerPresent }
            if current && inputIsNeutral { return false }
            return current
        }

        static var lifecycleProbePasses: Bool {
            let afterConnect = waitingForNeutral(
                current: false,
                controllerChanged: true,
                controllerPresent: true,
                inputIsNeutral: false
            )
            let whileHeld = waitingForNeutral(
                current: afterConnect,
                controllerChanged: false,
                controllerPresent: true,
                inputIsNeutral: false
            )
            let afterRelease = waitingForNeutral(
                current: whileHeld,
                controllerChanged: false,
                controllerPresent: true,
                inputIsNeutral: true
            )
            return afterConnect && whileHeld && !afterRelease
        }
    }

    @Published private(set) var externalControllerName: String?
    @Published private(set) var touchAimActive = false
    @Published private(set) var aimBehavior = RecompPrototypeAimBehavior.toggle
    @Published private(set) var controllerLookMode = RecompPrototypeControllerLookMode.analog
    @Published private(set) var activeControlStyle: Int32 = -1
    @Published private(set) var twoPlayerTestModeActive = false
    @Published private(set) var fourPlayerTestModeActive = false
    @Published private(set) var touchControlsVisible = true
    private var touchButtons: UInt16 = 0
    private var touchFireState = RecompTouchFireState()
    private var touchMovement = SIMD2<Float>.zero
    private var touchLook = SIMD2<Float>.zero
    private var touchCrouchIsPressed = false
    private var controllerCrouchWasPressed = false
    private var twoPlayerTestModeRequested = false
    private var fourPlayerTestModeRequested = false
    private var overlayInputSuspended = false
    private var sceneInputSuspended = false
    private var controllerRequiresNeutralRelease = false
    private var invertAimY = false
    private let fourPlayerRenderProbeForcesFourPlayer = ProcessInfo.processInfo.arguments.contains(
        "--four-player-render-probe"
    )
    private let ownershipProbeForcesTwoPlayer =
        ProcessInfo.processInfo.arguments.contains("--controller-ownership-probe") ||
        ProcessInfo.processInfo.arguments.contains("--four-player-render-probe")
    private var lookSensitivity: Float = 4.0
    private var controller: GCController?
    private var controllerMapping = Dictionary(
        uniqueKeysWithValues: RecompPrototypeControllerControl.allCases.map { ($0, $0.defaultAction) }
    )
    private var observers: [NSObjectProtocol] = []
    private var ticker: Timer?
    #if targetEnvironment(simulator)
    private var simulatorKeyboardHeldButtons: UInt16 = 0
    private var simulatorKeyboardPulseFrames: [UInt16: Int] = [:]
    private var simulatorKeyboardHeldStick: UInt8 = 0
    private var simulatorKeyboardStickPulseFrames: [UInt8: Int] = [:]
    #endif

    init() {
        let sidestepProbeEnabled = ProcessInfo.processInfo.arguments.contains("--sidestep-probe")
        let ownershipProbeEnabled = ownershipProbeForcesTwoPlayer
        goldenPadRecompSetSidestepProbeEnabled(sidestepProbeEnabled ? 1 : 0)
        if ownershipProbeEnabled {
            NSLog(
                "[GoldenPad] Controller ownership lifecycle probe: " +
                (InputOwnershipRouter.disconnectProbePasses &&
                    InputOwnershipRouter.orderingProbePasses &&
                    InputSuspensionRouter.lifecycleProbePasses &&
                    ControllerActivationGuard.lifecycleProbePasses ? "PASS" : "FAIL")
            )
        }
        goldenPadRecompSetFireRateProbeEnabled(
            ProcessInfo.processInfo.arguments.contains("--fire-rate-probe") ? 1 : 0
        )
        refreshController()
        if ownershipProbeEnabled {
            // Exercise the real integration route without changing AppStorage:
            // controller Player 1 plus touch Player 2 for this launch only.
            configureTwoPlayerTestMode(true)
        }
        if fourPlayerRenderProbeForcesFourPlayer {
            // Extend the launch-only route with neutral Players 3/4. The normal
            // AppStorage-backed toggle remains unchanged.
            configureFourPlayerTestMode(true)
        }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refreshController() }
        })
        observers.append(center.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refreshController() }
        })
        #if targetEnvironment(simulator)
        observers.append(center.addObserver(forName: .GCKeyboardDidConnect, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.configureSimulatorKeyboard() }
        })
        configureSimulatorKeyboard()
        #endif
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
        let next = RecompPrototypeControllerLookMode(rawValue: rawValue) ?? .analog
        guard next != controllerLookMode else { return }
        controllerLookMode = next
        // Give the game one neutral publication when changing semantics so a
        // held stick cannot carry an old-mode turn/strafe into the new mode.
        publishController(port: 0, buttons: 0, stick: .zero, look: .zero)
    }

    func configureControllerMapping(_ rawValues: [RecompPrototypeControllerControl: String]) {
        controllerMapping = Dictionary(
            uniqueKeysWithValues: RecompPrototypeControllerControl.allCases.map { control in
                let action = rawValues[control]
                    .flatMap(RecompPrototypeControllerAction.init(rawValue:))
                    ?? control.defaultAction
                return (control, action)
            }
        )
        publish()
    }

    func setHostInputSuspended(_ suspended: Bool) {
        updateInputSuspension(overlay: suspended)
    }

    func setSceneInputSuspended(_ suspended: Bool) {
        updateInputSuspension(scene: suspended)
    }

    private var hostInputSuspended: Bool {
        InputSuspensionRouter.isSuspended(
            overlay: overlayInputSuspended,
            scene: sceneInputSuspended
        )
    }

    private func updateInputSuspension(
        overlay: Bool? = nil,
        scene: Bool? = nil
    ) {
        let wasSuspended = hostInputSuspended
        if let overlay { overlayInputSuspended = overlay }
        if let scene { sceneInputSuspended = scene }
        guard wasSuspended != hostInputSuspended else { return }
        if hostInputSuspended {
            clearTouchInputState()
            controllerCrouchWasPressed = false
        }
        publish()
    }

    func configureInvertAimY(_ enabled: Bool) {
        invertAimY = enabled
        goldenPadRecompSetInvertAimY(enabled ? 1 : 0)
    }

    func configureUnlockAllMissions(_ enabled: Bool) {
        goldenPadRecompSetUnlockAllMissions(enabled ? 1 : 0)
    }

    func configureTwoPlayerTestMode(_ enabled: Bool) {
        let previousOwnership = ownershipRoute
        twoPlayerTestModeRequested = ownershipProbeForcesTwoPlayer || enabled
        updateTestModes(previousOwnership: previousOwnership)
    }

    func configureFourPlayerTestMode(_ enabled: Bool) {
        fourPlayerTestModeRequested = fourPlayerRenderProbeForcesFourPlayer || enabled
        updateTestModes()
    }

    private var ownershipRoute: InputOwnershipRoute {
        InputOwnershipRouter.route(
            controllerPresent: controller != nil,
            twoPlayerRequested: twoPlayerTestModeRequested
        )
    }

    private func updateTestModes(
        previousOwnership: InputOwnershipRoute? = nil,
        controllerChanged: Bool = false
    ) {
        let nextOwnership = ownershipRoute
        if controllerChanged || previousOwnership.map({ $0 != nextOwnership }) == true {
            // Route changes publish a neutral boundary before any new owner can
            // write a held button or stick into a different player port.
            clearTouchInputState()
            publishNeutralControllers()
        }
        twoPlayerTestModeActive = nextOwnership.twoPlayerActive
        fourPlayerTestModeActive = twoPlayerTestModeActive && fourPlayerTestModeRequested
        touchControlsVisible = nextOwnership.touchPort != nil
        goldenPadRecompSetControllerConnected(controller == nil ? 0 : 1)
        goldenPadRecompSetTouchInputPort(nextOwnership.touchPort ?? -1)
        goldenPadRecompSetTwoPlayerTestMode(twoPlayerTestModeActive ? 1 : 0)
        goldenPadRecompSetFourPlayerTestMode(fourPlayerTestModeActive ? 1 : 0)
        publish()
    }

    func requestReturnToMainMenu() {
        releaseTouchInput()
        goldenPadRecompRequestReturnToTitle()
    }

    func setLook(_ value: SIMD2<Float>) {
        // Preserve GoldenPad's tuned relative-look path: amplify each swipe
        // delta by 1.5x and accumulate until the next 60 Hz publication.
        guard value != .zero else { return }
        touchLook = clamp(touchLook + value * 1.5)
    }

    func setCrouchPressed(_ pressed: Bool) {
        if pressed && !touchCrouchIsPressed, let touchPort = ownershipRoute.touchPort {
            goldenPadRecompRequestCrouchToggle(touchPort)
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

    func setFirePressed(_ pressed: Bool, source: RecompTouchFireSource) {
        touchFireState.setPressed(pressed, source: source)
        setButton(N64.z, pressed: touchFireState.isPressed)
    }

    func releaseTouchInput() {
        clearTouchInputState()
        publish()
    }

    private func clearTouchInputState() {
        touchButtons = 0
        touchFireState.reset()
        touchAimActive = false
        touchMovement = .zero
        touchLook = .zero
        touchCrouchIsPressed = false
    }

    private func refreshController() {
        let previousOwnership = ownershipRoute
        let previousController = controller
        let availableControllers = GCController.controllers().filter { $0.extendedGamepad != nil }
        if let previousController,
           availableControllers.contains(where: { $0 === previousController }) {
            controller = previousController
        } else {
            controller = availableControllers.first
        }
        controllerCrouchWasPressed = false
        externalControllerName = controller.map { $0.vendorName ?? "External controller" }
        controllerRequiresNeutralRelease = ControllerActivationGuard.waitingForNeutral(
            current: controllerRequiresNeutralRelease,
            controllerChanged: previousController !== controller,
            controllerPresent: controller != nil,
            inputIsNeutral: false
        )
        updateTestModes(
            previousOwnership: previousOwnership,
            controllerChanged: previousController !== controller
        )
    }

    private func publish() {
        if hostInputSuspended {
            touchLook = .zero
            publishNeutralControllers()
            return
        }

        let queuedTouchLook = clamp(touchLook * lookSensitivity)
        touchLook = .zero
        var externalButtons: UInt16 = 0
        var externalStick = SIMD2<Float>.zero
        var controllerLook = SIMD2<Float>.zero
        var controllerCrouchIsPressed = false
        var externalFireActive = false
        var externalAimActive = false
        var externalActionActive = false
        var externalWeaponActive = false

        if let gamepad = controller?.extendedGamepad {
            externalStick = SIMD2(gamepad.leftThumbstick.xAxis.value, gamepad.leftThumbstick.yAxis.value)
            controllerLook = SIMD2(
                gamepad.rightThumbstick.xAxis.value,
                gamepad.rightThumbstick.yAxis.value
            )
                .applyingRadialDeadZone(0.15)
                .applyingResponseCurve(1.5)
            let pressedControls: [(RecompPrototypeControllerControl, Bool)] = [
                (.buttonA, gamepad.buttonA.isPressed),
                (.buttonB, gamepad.buttonB.isPressed),
                (.buttonX, gamepad.buttonX.isPressed),
                (.buttonY, gamepad.buttonY.isPressed),
                (.leftShoulder, gamepad.leftShoulder.isPressed),
                (.rightShoulder, gamepad.rightShoulder.isPressed),
                (.leftTrigger, gamepad.leftTrigger.value > 0.25),
                (.rightTrigger, gamepad.rightTrigger.value > 0.25),
            ]
            for (control, isPressed) in pressedControls where isPressed {
                switch controllerMapping[control] ?? control.defaultAction {
                case .fire: externalFireActive = true
                case .aim: externalAimActive = true
                case .action: externalActionActive = true
                case .weapon: externalWeaponActive = true
                case .duck: controllerCrouchIsPressed = true
                case .none: break
                }
            }
            if gamepad.buttonMenu.isPressed { externalButtons |= N64.start }
            if gamepad.dpad.up.isPressed { externalButtons |= N64.dpadUp }
            if gamepad.dpad.down.isPressed { externalButtons |= N64.dpadDown }
            if gamepad.dpad.left.isPressed { externalButtons |= N64.dpadLeft }
            if gamepad.dpad.right.isPressed { externalButtons |= N64.dpadRight }
        }

        #if targetEnvironment(simulator)
        let simulatorButtons = consumeSimulatorKeyboardButtons()
        externalButtons |= simulatorButtons
        if simulatorButtons & N64.dpadUp != 0 { externalStick.y = 1 }
        if simulatorButtons & N64.dpadDown != 0 { externalStick.y = -1 }
        if simulatorButtons & N64.dpadLeft != 0 { externalStick.x = -1 }
        if simulatorButtons & N64.dpadRight != 0 { externalStick.x = 1 }
        let simulatorStick = consumeSimulatorKeyboardStick()
        if simulatorStick != .zero { externalStick = simulatorStick }
        #endif

        let controllerInputIsNeutral = externalButtons == 0 &&
            !externalFireActive && !externalAimActive &&
            !externalActionActive && !externalWeaponActive &&
            simd_length(externalStick) <= 0.15 &&
            controllerLook == .zero &&
            !controllerCrouchIsPressed
        let wasWaitingForNeutral = controllerRequiresNeutralRelease
        controllerRequiresNeutralRelease = ControllerActivationGuard.waitingForNeutral(
            current: controllerRequiresNeutralRelease,
            controllerChanged: false,
            controllerPresent: controller != nil,
            inputIsNeutral: controllerInputIsNeutral
        )
        if wasWaitingForNeutral {
            // A newly selected or reconnected controller stays neutral until
            // every held input has been released. This prevents a button held
            // through disconnect from becoming a fresh press on a new owner.
            externalButtons = 0
            externalStick = .zero
            controllerLook = .zero
            controllerCrouchIsPressed = false
            externalFireActive = false
            externalAimActive = false
            externalActionActive = false
            externalWeaponActive = false
        }
        if controllerCrouchIsPressed && !controllerCrouchWasPressed {
            // The external controller remains Player 1 in both normal and
            // two-player test modes. Touch is the only input routed to P2.
            goldenPadRecompRequestCrouchToggle(0)
        }
        controllerCrouchWasPressed = controllerCrouchIsPressed

        switch controllerLookMode {
        case .analog:
            break
        case .classic:
            let threshold: Float = 0.30
            if controllerLook.y > threshold { externalButtons |= N64.cUp }
            if controllerLook.y < -threshold { externalButtons |= N64.cDown }
            if controllerLook.x < -threshold { externalButtons |= N64.cLeft }
            if controllerLook.x > threshold { externalButtons |= N64.cRight }
            controllerLook = .zero
        case .off:
            controllerLook = .zero
        }

        let route = ownershipRoute
        let gameplayActive = goldenPadRecompGameplayInputActive() != 0

        if !gameplayActive {
            activeControlStyle = -1
            // Preserve the physically working Preview 3/P4 menu path exactly.
            // GoldenEye owns analog menu repeat and button edges; no style,
            // tank, Aim, or menu-latch translation belongs in this branch.
            if externalFireActive { externalButtons |= N64.z }
            if externalAimActive { externalButtons |= N64.r }
            if externalActionActive { externalButtons |= N64.b }
            if externalWeaponActive { externalButtons |= N64.a }
            for port in 0..<4 {
                let resolvedPort = Int32(port)
                if route.externalPort == resolvedPort {
                    publishController(
                        port: resolvedPort,
                        buttons: externalButtons,
                        stick: externalStick,
                        look: controllerLook
                    )
                } else if route.touchPort == resolvedPort {
                    publishController(
                        port: resolvedPort,
                        buttons: touchButtons,
                        stick: touchMovement,
                        look: .zero
                    )
                } else {
                    publishController(port: resolvedPort, buttons: 0, stick: .zero, look: .zero)
                }
            }
            if queuedTouchLook != .zero, let touchPort = route.touchPort {
                goldenPadRecompQueueTouchLook(
                    touchPort,
                    Int32((queuedTouchLook.x * 32_767).rounded()),
                    Int32((queuedTouchLook.y * 32_767).rounded())
                )
            }
            return
        }

        var externalContext = route.externalPort.map(runtimeInputContext) ?? inactiveInputContext
        var touchContext = route.touchPort.map(runtimeInputContext) ?? inactiveInputContext
        activeControlStyle = route.externalPort != nil
            ? externalContext.runtimeStyle : touchContext.runtimeStyle
        externalContext.gameplayActive = true
        touchContext.gameplayActive = true
        let externalMapping = RecompControlMapping(runtimeStyle: externalContext.runtimeStyle)
        let touchMapping = RecompControlMapping(runtimeStyle: touchContext.runtimeStyle)

        // Use the requested semantic Aim as an immediate safety boundary as
        // well as the authoritative game state. This prevents a one-frame
        // synthesized C-button lean before insightaimmode updates.
        externalContext.aiming = externalContext.aiming || externalAimActive
        let touchFireActive = touchButtons & N64.z != 0
        let touchAimRequested = touchButtons & N64.r != 0
        let touchActionActive = touchButtons & N64.b != 0
        let touchWeaponActive = touchButtons & N64.a != 0
        let touchStartActive = touchButtons & N64.start != 0
        touchContext.aiming = touchContext.aiming || touchAimRequested

        externalButtons |= externalMapping.gameplayButtons(
            fire: externalFireActive,
            aim: externalAimActive,
            action: externalActionActive,
            weapon: externalWeaponActive,
            start: externalButtons & N64.start != 0
        )
        let resolvedTouchButtons = touchMapping.gameplayButtons(
            fire: touchFireActive,
            aim: touchAimRequested,
            action: touchActionActive,
            weapon: touchWeaponActive,
            start: touchStartActive
        )

        var externalMovement = externalMapping.movement(
            buttons: externalButtons,
            stick: externalStick,
            modern: controllerLookMode == .analog,
            context: externalContext
        )
        var publishedControllerLook = controllerLook
        if controllerLookMode == .analog,
           let manualAimStick = externalMapping.manualAimStick(
               stick: externalStick,
               invertVertical: invertAimY,
               context: externalContext) {
            // GoldenEye's original manual-sight path owns damping, reticle
            // position, and weapon orientation. Aim mode interprets this N64
            // stick as sight movement rather than character movement.
            externalMovement.stick = manualAimStick
            publishedControllerLook = .zero
        }
        let mappedTouchMovement = touchMapping.movement(
            buttons: resolvedTouchButtons,
            stick: touchMovement,
            modern: true,
            context: touchContext
        )

        for port in 0..<4 {
            let resolvedPort = Int32(port)
            if route.externalPort == resolvedPort {
                publishController(
                    port: resolvedPort,
                    buttons: externalMovement.buttons,
                    stick: externalMovement.stick,
                    look: publishedControllerLook
                )
            } else if route.touchPort == resolvedPort {
                publishController(
                    port: resolvedPort,
                    buttons: mappedTouchMovement.buttons,
                    stick: mappedTouchMovement.stick,
                    look: .zero
                )
            } else {
                publishController(port: resolvedPort, buttons: 0, stick: .zero, look: .zero)
            }
        }
        if queuedTouchLook != .zero, let touchPort = route.touchPort {
            goldenPadRecompQueueTouchLook(
                touchPort,
                Int32((queuedTouchLook.x * 32_767).rounded()),
                Int32((queuedTouchLook.y * 32_767).rounded())
            )
        }
    }

    private var inactiveInputContext: RecompRuntimeInputContext {
        RecompRuntimeInputContext(
            gameplayActive: false,
            runtimeStyle: -1,
            aiming: false,
            tankState: -1,
            nativeLookUpright: false
        )
    }

    private func runtimeInputContext(port: Int32) -> RecompRuntimeInputContext {
        var gameplayActive: Int32 = 0
        var controlStyle: Int32 = -1
        var aiming: Int32 = 0
        var tankState: Int32 = -1
        var nativeLookUpright: Int32 = 0
        goldenPadRecompGetInputContext(
            port, &gameplayActive, &controlStyle, &aiming, &tankState,
            &nativeLookUpright)
        return RecompRuntimeInputContext(
            gameplayActive: gameplayActive != 0,
            runtimeStyle: controlStyle,
            aiming: aiming != 0,
            tankState: tankState,
            nativeLookUpright: nativeLookUpright != 0
        )
    }

    private func publishController(
        port: Int32,
        buttons: UInt16,
        stick: SIMD2<Float>,
        look: SIMD2<Float>
    ) {
        let clampedStick = clamp(stick)
        goldenPadRecompSetControllerState(
            port,
            UInt32(buttons),
            Int32((clampedStick.x * 80).rounded()),
            Int32((clampedStick.y * 80).rounded())
        )
        goldenPadRecompSetRightAnalog(
            port,
            Int32((look.x * 32_767).rounded()),
            Int32((look.y * 32_767).rounded())
        )
    }

    private func publishNeutralControllers() {
        for port in 0..<4 {
            publishController(port: Int32(port), buttons: 0, stick: .zero, look: .zero)
        }
    }

    private func clamp(_ value: SIMD2<Float>) -> SIMD2<Float> {
        let magnitude = simd_length(value)
        return magnitude > 1 ? value / magnitude : value
    }

    #if targetEnvironment(simulator)
    private func configureSimulatorKeyboard() {
        GCKeyboard.coalesced?.keyboardInput?.keyChangedHandler = { [weak self] _, _, keyCode, pressed in
            Task { @MainActor in
                self?.handleSimulatorKey(keyCode, pressed: pressed)
            }
        }
    }

    private func handleSimulatorKey(_ keyCode: GCKeyCode, pressed: Bool) {
        if let stick = simulatorStickBit(for: keyCode) {
            if pressed {
                simulatorKeyboardHeldStick |= stick
                simulatorKeyboardStickPulseFrames[stick] = 4
            } else {
                simulatorKeyboardHeldStick &= ~stick
            }
            return
        }
        guard let button = simulatorButton(for: keyCode) else { return }
        if pressed {
            simulatorKeyboardHeldButtons |= button
            // Computer-driven taps can be shorter than one 60 Hz publication.
            // Retain a short pulse so GoldenEye's 30 Hz poll sees the edge.
            simulatorKeyboardPulseFrames[button] = 4
        } else {
            simulatorKeyboardHeldButtons &= ~button
        }
    }

    private func consumeSimulatorKeyboardButtons() -> UInt16 {
        var buttons = simulatorKeyboardHeldButtons
        for (button, frames) in Array(simulatorKeyboardPulseFrames) {
            buttons |= button
            if frames <= 1 {
                simulatorKeyboardPulseFrames.removeValue(forKey: button)
            } else {
                simulatorKeyboardPulseFrames[button] = frames - 1
            }
        }
        return buttons
    }

    private func consumeSimulatorKeyboardStick() -> SIMD2<Float> {
        var stick = simulatorKeyboardHeldStick
        for (direction, frames) in Array(simulatorKeyboardStickPulseFrames) {
            stick |= direction
            if frames <= 1 {
                simulatorKeyboardStickPulseFrames.removeValue(forKey: direction)
            } else {
                simulatorKeyboardStickPulseFrames[direction] = frames - 1
            }
        }
        return SIMD2(
            (stick & 0x08 != 0 ? 1 : 0) - (stick & 0x04 != 0 ? 1 : 0),
            (stick & 0x01 != 0 ? 1 : 0) - (stick & 0x02 != 0 ? 1 : 0)
        )
    }

    private func simulatorStickBit(for keyCode: GCKeyCode) -> UInt8? {
        switch keyCode {
        case .keyI: 0x01
        case .keyK: 0x02
        case .keyJ: 0x04
        case .keyL: 0x08
        default: nil
        }
    }

    private func simulatorButton(for keyCode: GCKeyCode) -> UInt16? {
        switch keyCode {
        case .upArrow: N64.dpadUp
        case .downArrow: N64.dpadDown
        case .leftArrow: N64.dpadLeft
        case .rightArrow: N64.dpadRight
        case .keyA: N64.a
        case .keyB: N64.b
        case .keyS: N64.start
        case .keyZ: N64.z
        case .keyR: N64.r
        default: nil
        }
    }
    #endif
}

struct RecompPrototypeTouchControls: View {
    @ObservedObject var input: RecompPrototypeInput
    let placements: [RecompTouchPlacement]
    let deviceClass: RecompTouchDeviceClass

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(placements.filter(\.isEnabled)) { placement in
                    control(placement, canvas: geometry.size)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .onDisappear { input.releaseTouchInput() }
    }

    @ViewBuilder
    private func control(_ placement: RecompTouchPlacement, canvas: CGSize) -> some View {
        // Saved editor placements are constrained before persistence. Keep the
        // established iPad defaults unchanged, including the intentionally
        // generous movement surface that reaches slightly past the edge.
        let resolved = placement.sanitized()
        let size = RecompTouchLayoutGeometry.renderedSize(
            for: resolved,
            canvas: canvas,
            deviceClass: deviceClass
        )
        Group {
            switch placement.id {
            case .move:
                RecompStick(title: placement.id.label, symbol: "figure.walk") { input.setMovement($0) }
                    .frame(width: size.width, height: size.height)
            case .look:
                RecompLookSurface { input.setLook($0) }
                    .frame(width: size.width, height: size.height)
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
                    .frame(width: size.width, height: size.height)
                } else {
                    RecompMomentaryButton(
                        title: placement.id.label,
                        tint: placement.id.tint,
                        pressedTint: .yellow
                    ) {
                        input.setAimPressed($0)
                    }
                    .frame(width: size.width, height: size.height)
                }
            default:
                RecompMomentaryButton(
                    title: placement.id.label,
                    tint: placement.id.tint
                ) {
                    if placement.id == .crouch {
                        input.setCrouchPressed($0)
                    } else if let fireSource = placement.id.fireSource {
                        input.setFirePressed($0, source: fireSource)
                    } else {
                        input.setButton(placement.id.n64Mask, pressed: $0)
                    }
                }
                .frame(width: size.width, height: size.height)
            }
        }
        .opacity(resolved.resolvedOpacity)
        .position(x: canvas.width * resolved.x, y: canvas.height * resolved.y)
        .accessibilityLabel(placement.id.accessibilityLabel)
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

struct RecompStick: View {
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
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .foregroundStyle(.white.opacity(0.6))
                    .position(x: center.x, y: center.y + diameter * 0.36)
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

struct RecompLookSurface: View {
    let onChange: (SIMD2<Float>) -> Void
    @State private var lastLocation: CGPoint?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(.black.opacity(0.10))
                RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.14), lineWidth: 1)
                VStack(spacing: 6) {
                    Image(systemName: "scope").foregroundStyle(.white.opacity(0.42))
                    Text("LOOK")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .foregroundStyle(.white.opacity(0.42))
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

struct RecompMomentaryButton: View {
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
            .lineLimit(1)
            .minimumScaleFactor(0.42)
            .allowsTightening(true)
            .padding(.horizontal, 4)
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

struct RecompToggleButton: View {
    let title: String
    let tint: Color
    let activeTint: Color
    let isOn: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.42)
                .allowsTightening(true)
                .padding(.horizontal, 4)
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
