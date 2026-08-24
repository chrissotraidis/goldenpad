import AppKit
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

@_silgen_name("goldenpad_recomp_set_two_player_test_mode")
private func goldenPadRecompSetTwoPlayerTestMode(_ enabled: Int32)

@_silgen_name("goldenpad_recomp_queue_touch_look")
private func goldenPadRecompQueueRelativeLook(_ controller: Int32, _ x: Int32, _ y: Int32)

@_silgen_name("goldenpad_recomp_queue_mouse_look")
private func goldenPadRecompQueueMouseLook(_ controller: Int32, _ x: Int64, _ y: Int64)

@_silgen_name("goldenpad_recomp_request_crouch_toggle")
private func goldenPadRecompRequestCrouchToggle(_ controller: Int32)

@_silgen_name("goldenpad_recomp_request_inventory_slot")
private func goldenPadRecompRequestInventorySlot(_ controller: Int32, _ slot: Int32)

@_silgen_name("goldenpad_recomp_request_reload")
private func goldenPadRecompRequestReload(_ controller: Int32)

@_silgen_name("goldenpad_recomp_set_invert_aim_y")
private func goldenPadRecompSetInvertAimY(_ enabled: Int32)

@_silgen_name("goldenpad_recomp_set_unlock_all_missions")
private func goldenPadRecompSetUnlockAllMissions(_ enabled: Int32)

@_silgen_name("goldenpad_recomp_request_return_to_title")
private func goldenPadRecompRequestReturnToTitle()

@_silgen_name("goldenpad_recomp_frontend_input_active")
private func goldenPadRecompFrontEndInputActive() -> Int32

@_silgen_name("goldenpad_recomp_get_input_context")
private func goldenPadRecompGetInputContext(
    _ controller: Int32,
    _ gameplayActive: UnsafeMutablePointer<Int32>,
    _ controlStyle: UnsafeMutablePointer<Int32>,
    _ aiming: UnsafeMutablePointer<Int32>,
    _ tankState: UnsafeMutablePointer<Int32>,
    _ nativeLookUpright: UnsafeMutablePointer<Int32>
)

enum RecompMacBindableKey: UInt16, CaseIterable, Identifiable {
    case a = 0, s = 1, d = 2, f = 3, h = 4, g = 5
    case z = 6, x = 7, c = 8, v = 9, b = 11
    case q = 12, w = 13, e = 14, r = 15, y = 16, t = 17
    case one = 18, two = 19, three = 20, four = 21, six = 22, five = 23
    case nine = 25, seven = 26, eight = 28, zero = 29
    case o = 31, u = 32, i = 34, p = 35, returnKey = 36
    case l = 37, j = 38, k = 40, n = 45, m = 46
    case tab = 48, space = 49, escape = 53, shift = 56, control = 59
    case leftArrow = 123, rightArrow = 124, downArrow = 125, upArrow = 126
    case unassigned = 65_535

    var id: UInt16 { rawValue }

    var title: String {
        switch self {
        case .one: "1"
        case .two: "2"
        case .three: "3"
        case .four: "4"
        case .five: "5"
        case .six: "6"
        case .seven: "7"
        case .eight: "8"
        case .nine: "9"
        case .zero: "0"
        case .returnKey: "Return"
        case .tab: "Tab"
        case .space: "Space"
        case .escape: "Escape"
        case .shift: "Shift"
        case .control: "Control"
        case .leftArrow: "Left Arrow"
        case .rightArrow: "Right Arrow"
        case .downArrow: "Down Arrow"
        case .upArrow: "Up Arrow"
        case .unassigned: "Unassigned"
        default: String(describing: self).uppercased()
        }
    }
}

enum RecompMacKeyboardAction: String, CaseIterable {
    case moveForward, moveBackward, moveLeft, moveRight
    case fire, aim, action, changeWeapon, reload, crouch, start

    var title: String {
        switch self {
        case .moveForward: "Move forward"
        case .moveBackward: "Move backward"
        case .moveLeft: "Move / menu left"
        case .moveRight: "Move / menu right"
        case .fire: "Fire"
        case .aim: "Aim"
        case .action: "Action"
        case .changeWeapon: "Change weapon"
        case .reload: "Reload"
        case .crouch: "Crouch"
        case .start: "Start / pause"
        }
    }

    var defaultKey: RecompMacBindableKey {
        switch self {
        case .moveForward: .w
        case .moveBackward: .s
        case .moveLeft: .a
        case .moveRight: .d
        case .fire: .unassigned
        case .aim: .shift
        case .action: .e
        case .changeWeapon: .q
        case .reload: .r
        case .crouch: .c
        case .start: .escape
        }
    }

    var storageKey: String { "recomp.macKey.\(rawValue)" }
}

struct RecompMacKeyboardBindings {
    private var codes: [RecompMacKeyboardAction: UInt16]
    private static let bindingVersionKey = "recomp.macKeyBindingsVersion"
    private static let currentBindingVersion = 2

    static func load(from defaults: UserDefaults = .standard) -> Self {
        if defaults.integer(forKey: bindingVersionKey) < currentBindingVersion {
            let crouchKey = RecompMacKeyboardAction.crouch.storageKey
            let previous = defaults.object(forKey: crouchKey) as? NSNumber
            let previousCode = previous.map { UInt16(truncating: $0) }
            if previousCode == nil || previousCode == RecompMacBindableKey.control.rawValue {
                defaults.set(RecompMacBindableKey.c.rawValue, forKey: crouchKey)
            }
            let fireKey = RecompMacKeyboardAction.fire.storageKey
            let previousFire = defaults.object(forKey: fireKey) as? NSNumber
            let previousFireCode = previousFire.map { UInt16(truncating: $0) }
            if previousFireCode == nil || previousFireCode == RecompMacBindableKey.space.rawValue {
                defaults.set(RecompMacBindableKey.unassigned.rawValue, forKey: fireKey)
            }
            defaults.set(currentBindingVersion, forKey: bindingVersionKey)
        }
        var codes: [RecompMacKeyboardAction: UInt16] = [:]
        for action in RecompMacKeyboardAction.allCases {
            let stored = defaults.object(forKey: action.storageKey) as? NSNumber
            let candidate = UInt16(truncating: stored ?? NSNumber(value: action.defaultKey.rawValue))
            codes[action] = RecompMacBindableKey(rawValue: candidate) == nil
                ? action.defaultKey.rawValue
                : candidate
        }
        return Self(codes: codes)
    }

    func key(for action: RecompMacKeyboardAction) -> UInt16 {
        codes[action] ?? action.defaultKey.rawValue
    }

    var summary: String {
        RecompMacKeyboardAction.allCases.map { action in
            let key = RecompMacBindableKey(rawValue: key(for: action))?.title ?? "Unknown"
            return "\(action.title): \(key)"
        }.joined(separator: ", ")
    }
}

@MainActor
final class RecompMacInput: ObservableObject {
    private enum Key {
        static let delete: UInt16 = 51
        static let escape: UInt16 = 53
        static let leftShift: UInt16 = 56
        static let rightShift: UInt16 = 60
        static let leftControl: UInt16 = 59
        static let rightControl: UInt16 = 62
    }

    @Published private(set) var externalControllerName: String?
    @Published private(set) var mouseCaptured = false

    private var controller: GCController?
    private var gameplayInputActive = false
    private var heldKeys = Set<UInt16>()
    private var keyPulseFrames: [UInt16: Int] = [:]
    private var mouseFirePulseFrames = 0
    private var mouseActionPulseFrames = 0
    private var menuConfirmPulseFrames = 0
    private var menuBackPulseFrames = 0
    private var pendingWeaponWheelSteps = 0
    private var weaponWheelPulseFrames = 0
    private var weaponWheelNeutralFrames = 0
    private var weaponWheelDirection = 0
    private var menuMouseStep = SIMD2<Float>.zero
    private var menuMouseStepFrames = 0
    private var menuMouseNeutralFrames = 0
    private var menuStickLatch = RecompMenuStickLatch()
    private var viewMouseFireHeld = false
    private var viewMouseActionHeld = false
    private var pendingMouseDelta = SIMD2<Float>.zero
    private var pendingMenuMouseDelta = SIMD2<Float>.zero
    private var mouseSensitivity: Float = 3.0
    private var invertAimY = false
    private let mouseClampProbeEnabled = ProcessInfo.processInfo.arguments.contains(
        "--mouse-clamp-probe"
    )
    private var keyboardBindings = RecompMacKeyboardBindings.load()
    private var observers: [NSObjectProtocol] = []
    private var ticker: Timer?

    init() {
        let center = NotificationCenter.default
        for name in [Notification.Name.GCControllerDidConnect, .GCControllerDidDisconnect] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.refreshDevices() }
            })
        }
        observers.append(center.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.releaseAllInput() }
        })
        observers.append(center.addObserver(
            forName: NSWindow.didMiniaturizeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.releaseAllInput() }
        })

        refreshDevices()
        let inputTimer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.publish() }
        }
        RunLoop.main.add(inputTimer, forMode: .common)
        ticker = inputTimer
        publish()
    }

    deinit {
        ticker?.invalidate()
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func captureMouse() {
        guard gameplayInputActive, !mouseCaptured else { return }
        mouseCaptured = true
        NSCursor.hide()
        CGAssociateMouseAndMouseCursorPosition(0)
    }

    func releaseMouseCapture() {
        pendingMouseDelta = .zero
        if mouseCaptured {
            mouseCaptured = false
            CGAssociateMouseAndMouseCursorPosition(1)
            NSCursor.unhide()
        }
    }

    func handleMouseMotion(deltaX: CGFloat, deltaY: CGFloat) {
        if gameplayInputActive {
            guard mouseCaptured else { return }
            pendingMouseDelta += SIMD2(Float(deltaX), Float(deltaY))
        } else {
            guard menuMouseStepFrames == 0, menuMouseNeutralFrames == 0 else {
                pendingMenuMouseDelta = .zero
                return
            }
            pendingMenuMouseDelta += SIMD2(Float(deltaX), Float(deltaY))
        }
    }

    func handleMouseButton(_ button: Int, pressed: Bool) {
        if !gameplayInputActive {
            guard pressed else { return }
            if button == 0 { menuConfirmPulseFrames = 3 }
            if button == 1 { menuBackPulseFrames = 3 }
            return
        }

        if pressed { captureMouse() }
        switch button {
        case 0:
            viewMouseFireHeld = pressed
            if pressed { mouseFirePulseFrames = 3 }
        case 1:
            viewMouseActionHeld = pressed
            if pressed { mouseActionPulseFrames = 3 }
        case 2:
            if pressed {
                pendingWeaponWheelSteps = min(6, pendingWeaponWheelSteps + 1)
            }
        default:
            break
        }
    }

    func handleMouseWheel(deltaY: CGFloat) {
        guard gameplayInputActive, abs(deltaY) > 0.01 else { return }
        // Wheel up selects the previous weapon (A+Z in GoldenEye); wheel down
        // selects the next weapon (A). Queue bounded, separated pulses so a
        // fast physical wheel still produces distinct N64 button edges.
        pendingWeaponWheelSteps = max(-6, min(6,
            pendingWeaponWheelSteps + (deltaY > 0 ? -1 : 1)))
    }

    func handleKey(_ keyCode: UInt16, pressed: Bool) {
        let wasPressed = heldKeys.contains(keyCode)
        if pressed { heldKeys.insert(keyCode) } else { heldKeys.remove(keyCode) }
        if pressed, !wasPressed {
            keyPulseFrames[keyCode] = 3
        }
        if keyCode == Key.delete, pressed, !wasPressed {
            releaseMouseCapture()
        }
        if pressed, !wasPressed, gameplayInputActive,
           keyMatches(.crouch, keyCode: keyCode) {
            pendingMouseDelta.y = 0
            goldenPadRecompRequestCrouchToggle(0)
        }
        if pressed, !wasPressed, gameplayInputActive,
           let slot = inventorySlot(for: keyCode) {
            goldenPadRecompRequestInventorySlot(0, slot)
        }
        if pressed, !wasPressed, gameplayInputActive,
           keyMatches(.reload, keyCode: keyCode) {
            goldenPadRecompRequestReload(0)
        }
    }

    func releaseAllInput() {
        heldKeys.removeAll()
        keyPulseFrames.removeAll()
        mouseFirePulseFrames = 0
        mouseActionPulseFrames = 0
        menuConfirmPulseFrames = 0
        menuBackPulseFrames = 0
        pendingWeaponWheelSteps = 0
        weaponWheelPulseFrames = 0
        weaponWheelNeutralFrames = 0
        weaponWheelDirection = 0
        menuMouseStep = .zero
        menuMouseStepFrames = 0
        menuMouseNeutralFrames = 0
        menuStickLatch.reset()
        viewMouseFireHeld = false
        viewMouseActionHeld = false
        pendingMouseDelta = .zero
        pendingMenuMouseDelta = .zero
        releaseMouseCapture()
        publishNeutral()
    }

    func configureInvertAimY(_ enabled: Bool) {
        invertAimY = enabled
        goldenPadRecompSetInvertAimY(enabled ? 1 : 0)
    }

    func configureUnlockAllMissions(_ enabled: Bool) {
        goldenPadRecompSetUnlockAllMissions(enabled ? 1 : 0)
    }

    func configureMouseSensitivity(_ sensitivity: Double) {
        mouseSensitivity = Float(max(0.5, min(6.0, sensitivity)))
    }

    func reloadKeyboardBindings() {
        keyboardBindings = .load()
        releaseAllInput()
    }

    var keyboardSummary: String { keyboardBindings.summary }

    func requestReturnToMainMenu() {
        releaseAllInput()
        goldenPadRecompRequestReturnToTitle()
    }

    private func refreshDevices() {
        controller = GCController.controllers().first(where: { $0.extendedGamepad != nil })
        externalControllerName = controller.map { $0.vendorName ?? "External controller" }
        goldenPadRecompSetControllerConnected(controller == nil ? 0 : 1)
        goldenPadRecompSetTwoPlayerTestMode(0)
    }

    private func publish() {
        var context = runtimeInputContext(port: 0)
        refreshRuntimeInputMode(context: context)
        let frontEndInputActive = goldenPadRecompFrontEndInputActive() != 0
        let mapping = RecompControlMapping(runtimeStyle: context.runtimeStyle)
        var buttons: UInt16 = 0
        var movement = gameplayMovement(includeHorizontal: true)
        var controllerManualAimStick: SIMD2<Float>?
        var rightStick = SIMD2<Float>.zero
        var fireActive = actionIsActive(.fire)
        var aimActive = actionIsActive(.aim)
        var actionActive = actionIsActive(.action)
        var weaponActive = actionIsActive(.changeWeapon)
        let startActive = actionIsActive(.start)

        if gameplayInputActive {
            beginWeaponWheelPulseIfNeeded()
            if weaponWheelPulseFrames > 0 {
                weaponActive = true
                if weaponWheelDirection < 0 { fireActive = true }
            }
            if mouseCaptured {
                fireActive = fireActive || viewMouseFireHeld || mouseFirePulseFrames > 0
                actionActive = actionActive || viewMouseActionHeld || mouseActionPulseFrames > 0
            }
        } else {
            // Menu/watch navigation is digital and edge-triggered by the game.
            // Full analog W/S crossed GoldenEye's repeat threshold every tick,
            // allowing a short key press to skip 1.2 and 1.3 entirely.
            if actionIsActive(.changeWeapon) || menuConfirmPulseFrames > 0 {
                buttons |= RecompN64Button.a
            }
            if actionIsActive(.action) || menuBackPulseFrames > 0 {
                buttons |= RecompN64Button.b
            }
            if startActive { buttons |= RecompN64Button.start }

            let keyboardOwnsNavigation = actionIsActive(.moveForward)
                || actionIsActive(.moveBackward)
                || actionIsActive(.moveLeft)
                || actionIsActive(.moveRight)
            if keyboardOwnsNavigation {
                pendingMenuMouseDelta = .zero
                menuMouseStep = .zero
                menuMouseStepFrames = 0
                menuMouseNeutralFrames = 0
            } else {
                movement = nextMenuMouseMovement()
            }
        }

        if let gamepad = controller?.extendedGamepad {
            let controllerMovement = SIMD2(gamepad.leftThumbstick.xAxis.value, gamepad.leftThumbstick.yAxis.value)
            controllerManualAimStick = controllerMovement
            if simd_length(controllerMovement) > 0.08 {
                movement = controllerMovement
            }
            if gameplayInputActive {
                rightStick = SIMD2(gamepad.rightThumbstick.xAxis.value, gamepad.rightThumbstick.yAxis.value)
                    .applyingRadialDeadZone(0.15)
                    .applyingResponseCurve(1.5)
                weaponActive = weaponActive || gamepad.buttonA.isPressed
                    || gamepad.buttonY.isPressed || gamepad.rightShoulder.isPressed
                actionActive = actionActive || gamepad.buttonB.isPressed || gamepad.buttonX.isPressed
                aimActive = aimActive || gamepad.leftTrigger.value > 0.25
                fireActive = fireActive || gamepad.rightTrigger.value > 0.25
            } else {
                if gamepad.buttonA.isPressed || gamepad.buttonY.isPressed || gamepad.rightShoulder.isPressed {
                    buttons |= RecompN64Button.a
                }
                if gamepad.buttonB.isPressed || gamepad.buttonX.isPressed {
                    buttons |= RecompN64Button.b
                }
            }
            if gamepad.buttonMenu.isPressed { buttons |= RecompN64Button.start }
            if gamepad.dpad.up.isPressed { buttons |= RecompN64Button.dpadUp }
            if gamepad.dpad.down.isPressed { buttons |= RecompN64Button.dpadDown }
            if gamepad.dpad.left.isPressed { buttons |= RecompN64Button.dpadLeft }
            if gamepad.dpad.right.isPressed { buttons |= RecompN64Button.dpadRight }
        }

        if gameplayInputActive {
            buttons |= mapping.gameplayButtons(
                fire: fireActive,
                aim: aimActive,
                action: actionActive,
                weapon: weaponActive,
                start: startActive
            )
            // Suppress synthesized movement immediately on the frame Aim is
            // requested, before GoldenEye updates insightaimmode.
            context.aiming = context.aiming || aimActive
            let mouseManualAimStick = consumeGameplayMouse(
                mapping: mapping,
                context: context
            )
            let resolved = mapping.movement(
                buttons: buttons,
                stick: movement,
                modern: true,
                context: context
            )
            buttons = resolved.buttons
            movement = resolved.stick
            if let mouseManualAimStick {
                movement = mouseManualAimStick
                rightStick = .zero
            } else if let controllerManualAimStick,
               let manualAimStick = mapping.manualAimStick(
                   stick: controllerManualAimStick,
                   invertVertical: invertAimY,
                   context: context) {
                movement = manualAimStick
                rightStick = .zero
            }
            menuStickLatch.reset()
        } else {
            let navigation = menuStickLatch.navigation(
                for: movement,
                frontEndActive: frontEndInputActive
            )
            buttons |= navigation.buttons
            movement = navigation.stick
        }

        if !gameplayInputActive {
            rightStick = .zero
        }

        publishController(buttons: buttons, movement: movement, rightStick: rightStick)
        keyPulseFrames = keyPulseFrames.compactMapValues { frames in frames > 1 ? frames - 1 : nil }
        mouseFirePulseFrames = Swift.max(0, mouseFirePulseFrames - 1)
        mouseActionPulseFrames = Swift.max(0, mouseActionPulseFrames - 1)
        menuConfirmPulseFrames = Swift.max(0, menuConfirmPulseFrames - 1)
        menuBackPulseFrames = Swift.max(0, menuBackPulseFrames - 1)
        advanceWeaponWheelPulse()
    }

    private func refreshRuntimeInputMode(context: RecompRuntimeInputContext) {
        let nextGameplayInputActive = context.gameplayActive
        guard nextGameplayInputActive != gameplayInputActive else { return }
        gameplayInputActive = nextGameplayInputActive
        pendingMouseDelta = .zero
        pendingMenuMouseDelta = .zero
        menuMouseStep = .zero
        menuMouseStepFrames = 0
        menuMouseNeutralFrames = 0
        menuStickLatch.reset()
        if gameplayInputActive {
            // A mission transition should immediately hand the pointer to
            // camera look. Requiring a click after every load left motion in
            // menu mode even though live gameplay had already started.
            captureMouse()
        } else {
            releaseMouseCapture()
        }
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

    private func keyIsActive(_ code: UInt16) -> Bool {
        heldKeys.contains(code) || (keyPulseFrames[code] ?? 0) > 0
    }

    private func inventorySlot(for keyCode: UInt16) -> Int32? {
        switch keyCode {
        case RecompMacBindableKey.one.rawValue: 0
        case RecompMacBindableKey.two.rawValue: 1
        case RecompMacBindableKey.three.rawValue: 2
        case RecompMacBindableKey.four.rawValue: 3
        case RecompMacBindableKey.five.rawValue: 4
        case RecompMacBindableKey.six.rawValue: 5
        case RecompMacBindableKey.seven.rawValue: 6
        case RecompMacBindableKey.eight.rawValue: 7
        case RecompMacBindableKey.nine.rawValue: 8
        case RecompMacBindableKey.zero.rawValue: 9
        default: nil
        }
    }

    private func keyMatches(_ action: RecompMacKeyboardAction, keyCode: UInt16) -> Bool {
        let configured = keyboardBindings.key(for: action)
        if configured == RecompMacBindableKey.shift.rawValue {
            return keyCode == Key.leftShift || keyCode == Key.rightShift
        }
        if configured == RecompMacBindableKey.control.rawValue {
            return keyCode == Key.leftControl || keyCode == Key.rightControl
        }
        return keyCode == configured
    }

    private func actionIsActive(_ action: RecompMacKeyboardAction) -> Bool {
        let configured = keyboardBindings.key(for: action)
        if configured == RecompMacBindableKey.shift.rawValue {
            return keyIsActive(Key.leftShift) || keyIsActive(Key.rightShift)
        }
        if configured == RecompMacBindableKey.control.rawValue {
            return keyIsActive(Key.leftControl) || keyIsActive(Key.rightControl)
        }
        return keyIsActive(configured)
    }

    private func gameplayMovement(includeHorizontal: Bool) -> SIMD2<Float> {
        var movement = SIMD2<Float>.zero
        if actionIsActive(.moveForward) { movement.y += 1 }
        if actionIsActive(.moveBackward) { movement.y -= 1 }
        if includeHorizontal {
            if actionIsActive(.moveLeft) { movement.x -= 1 }
            if actionIsActive(.moveRight) { movement.x += 1 }
        }
        return movement.clampedToUnitCircle()
    }

    private func publishController(buttons: UInt16, movement: SIMD2<Float>, rightStick: SIMD2<Float>) {
        let stick = movement.clampedToUnitCircle()
        goldenPadRecompSetControllerState(
            0,
            UInt32(buttons),
            Int32((stick.x * 80).rounded()),
            Int32((stick.y * 80).rounded())
        )
        goldenPadRecompSetRightAnalog(
            0,
            Int32((rightStick.x * 32_767).rounded()),
            Int32((rightStick.y * 32_767).rounded())
        )
    }

    private func consumeGameplayMouse(
        mapping: RecompControlMapping,
        context: RecompRuntimeInputContext
    ) -> SIMD2<Float>? {
        guard gameplayInputActive, mouseCaptured, pendingMouseDelta != .zero else {
            return nil
        }
        let delta = pendingMouseDelta
        pendingMouseDelta = .zero
        if let manualAimStick = mapping.mouseManualAimStick(
            delta: delta,
            sensitivity: mouseSensitivity,
            invertVertical: invertAimY,
            context: context
        ) {
            return manualAimStick
        }
        // The previous desktop rate remained too slow in physical play. Keep
        // the setting adjustable while doubling the actual mouse response.
        let scale = 1_680 * mouseSensitivity
        let x = Int64((Double(delta.x) * Double(scale)).rounded())
        let y = Int64((Double(-delta.y) * Double(scale)).rounded())
        goldenPadRecompQueueMouseLook(0, x, y)
        return nil
    }

    private func nextMenuMouseMovement() -> SIMD2<Float> {
        if menuMouseStepFrames > 0 {
            menuMouseStepFrames -= 1
            return menuMouseStep
        }
        if menuMouseNeutralFrames > 0 {
            menuMouseNeutralFrames -= 1
            return .zero
        }

        let threshold: Float = 18
        let delta = pendingMenuMouseDelta
        guard max(abs(delta.x), abs(delta.y)) >= threshold else { return .zero }
        if abs(delta.x) > abs(delta.y) {
            menuMouseStep = SIMD2(delta.x < 0 ? -1 : 1, 0)
        } else {
            // Match the observed GoldenEye menu convention: upward pointer
            // travel must emit the same positive menu axis as Move Forward.
            menuMouseStep = SIMD2(0, delta.y < 0 ? 1 : -1)
        }
        pendingMenuMouseDelta = .zero
        menuMouseStepFrames = 2
        menuMouseNeutralFrames = 2
        return nextMenuMouseMovement()
    }

    private func beginWeaponWheelPulseIfNeeded() {
        guard weaponWheelPulseFrames == 0, weaponWheelNeutralFrames == 0,
              pendingWeaponWheelSteps != 0 else { return }
        weaponWheelDirection = pendingWeaponWheelSteps < 0 ? -1 : 1
        pendingWeaponWheelSteps -= weaponWheelDirection
        weaponWheelPulseFrames = 2
    }

    private func advanceWeaponWheelPulse() {
        if weaponWheelPulseFrames > 0 {
            weaponWheelPulseFrames -= 1
            if weaponWheelPulseFrames == 0 { weaponWheelNeutralFrames = 2 }
        } else if weaponWheelNeutralFrames > 0 {
            weaponWheelNeutralFrames -= 1
        }
    }

    private func publishNeutral() {
        goldenPadRecompSetControllerState(0, 0, 0, 0)
        goldenPadRecompSetRightAnalog(0, 0, 0)
    }
}

private extension SIMD2 where Scalar == Float {
    func clampedToUnitCircle() -> SIMD2<Float> {
        let magnitude = simd_length(self)
        return magnitude > 1 ? self / magnitude : self
    }

    func applyingRadialDeadZone(_ deadZone: Float) -> SIMD2<Float> {
        let magnitude = simd_length(self)
        guard magnitude > deadZone else { return .zero }
        let normalizedMagnitude = Swift.min((magnitude - deadZone) / (1 - deadZone), 1)
        return (self / magnitude) * normalizedMagnitude
    }

    func applyingResponseCurve(_ exponent: Float) -> SIMD2<Float> {
        let magnitude = simd_length(self)
        guard magnitude > 0 else { return .zero }
        return (self / magnitude) * pow(magnitude, exponent)
    }
}
