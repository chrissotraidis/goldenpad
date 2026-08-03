import Foundation
import GameController

struct InputButtons: OptionSet, Equatable, Sendable {
    let rawValue: UInt32

    static let fire = InputButtons(rawValue: 1 << 0)
    static let aim = InputButtons(rawValue: 1 << 1)
    static let interact = InputButtons(rawValue: 1 << 2)
    static let reload = InputButtons(rawValue: 1 << 3)
    static let crouch = InputButtons(rawValue: 1 << 4)
    static let nextWeapon = InputButtons(rawValue: 1 << 5)
    static let pause = InputButtons(rawValue: 1 << 6)
    static let confirm = InputButtons(rawValue: 1 << 7)
    static let cancel = InputButtons(rawValue: 1 << 8)
    static let dpadUp = InputButtons(rawValue: 1 << 9)
    static let dpadDown = InputButtons(rawValue: 1 << 10)
    static let dpadLeft = InputButtons(rawValue: 1 << 11)
    static let dpadRight = InputButtons(rawValue: 1 << 12)
}

struct InputSnapshot: Equatable, Sendable {
    var movement = SIMD2<Float>.zero
    var look = SIMD2<Float>.zero
    var leftTrigger: Float = 0
    var rightTrigger: Float = 0
    var buttons: InputButtons = []

    static let neutral = InputSnapshot()

    func merging(_ other: InputSnapshot) -> InputSnapshot {
        InputSnapshot(
            movement: movement.mergingByMagnitude(other.movement),
            look: look.mergingByMagnitude(other.look),
            leftTrigger: max(leftTrigger, other.leftTrigger),
            rightTrigger: max(rightTrigger, other.rightTrigger),
            buttons: buttons.union(other.buttons)
        )
    }
}

private extension SIMD2 where Scalar == Float {
    func mergingByMagnitude(_ other: SIMD2<Float>) -> SIMD2<Float> {
        SIMD2(
            abs(x) >= abs(other.x) ? x : other.x,
            abs(y) >= abs(other.y) ? y : other.y
        )
    }
}

@MainActor
final class InputCoordinator: ObservableObject {
    @Published private(set) var diagnosticSummary = "input: neutral • controllers: 0"

    private var touch = InputSnapshot.neutral
    private var controllerSlots: [GCController?] = Array(repeating: nil, count: 4)
    private var lastActivity: String?
    private var observers: [NSObjectProtocol] = []

    init() {
        assignInitialControllers()

        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                guard let controller = notification.object as? GCController else { return }
                self?.assign(controller)
            }
        })
        observers.append(center.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                guard let controller = notification.object as? GCController else { return }
                self?.remove(controller)
            }
        })

        runAutomationProbeIfRequested()
        refreshSummary()
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func updateMovement(_ value: SIMD2<Float>) {
        touch.movement = value.clampedUnitSquare()
        refreshSummary()
    }

    func updateLook(_ value: SIMD2<Float>) {
        touch.look = value.clampedUnitSquare()
        refreshSummary()
    }

    func setTouchButton(_ button: InputButtons, pressed: Bool) {
        if pressed {
            touch.buttons.insert(button)
        } else {
            touch.buttons.remove(button)
        }
        refreshSummary()
    }

    func snapshot(player: Int) -> InputSnapshot {
        guard controllerSlots.indices.contains(player) else { return .neutral }
        let controller = controllerSlots[player].map(controllerSnapshot) ?? .neutral
        return player == 0 ? controller.merging(touch) : controller
    }

    private func assignInitialControllers() {
        let controllers = GCController.controllers().sorted {
            controllerKey($0) < controllerKey($1)
        }
        for controller in controllers {
            assign(controller)
        }
    }

    private func assign(_ controller: GCController) {
        guard !controllerSlots.contains(where: { $0 === controller }) else { return }
        guard let slot = controllerSlots.firstIndex(where: { $0 == nil }) else { return }
        controllerSlots[slot] = controller
        controller.playerIndex = playerIndex(for: slot)
        refreshSummary()
    }

    private func remove(_ controller: GCController) {
        guard let slot = controllerSlots.firstIndex(where: { $0 === controller }) else { return }
        controllerSlots[slot] = nil
        refreshSummary()
    }

    private func controllerKey(_ controller: GCController) -> String {
        "\(controller.vendorName ?? "")|\(controller.productCategory)"
    }

    private func playerIndex(for slot: Int) -> GCControllerPlayerIndex {
        switch slot {
        case 0: .index1
        case 1: .index2
        case 2: .index3
        case 3: .index4
        default: .indexUnset
        }
    }

    private func controllerSnapshot(_ controller: GCController) -> InputSnapshot {
        guard let gamepad = controller.extendedGamepad else { return .neutral }
        var buttons: InputButtons = []

        if gamepad.rightTrigger.isPressed { buttons.insert(.fire) }
        if gamepad.leftTrigger.isPressed { buttons.insert(.aim) }
        if gamepad.buttonA.isPressed { buttons.formUnion([.interact, .confirm]) }
        if gamepad.buttonB.isPressed { buttons.formUnion([.reload, .cancel]) }
        if gamepad.leftShoulder.isPressed { buttons.insert(.crouch) }
        if gamepad.rightShoulder.isPressed { buttons.insert(.nextWeapon) }
        if gamepad.buttonMenu.isPressed { buttons.insert(.pause) }
        if gamepad.dpad.up.isPressed { buttons.insert(.dpadUp) }
        if gamepad.dpad.down.isPressed { buttons.insert(.dpadDown) }
        if gamepad.dpad.left.isPressed { buttons.insert(.dpadLeft) }
        if gamepad.dpad.right.isPressed { buttons.insert(.dpadRight) }

        return InputSnapshot(
            movement: SIMD2(gamepad.leftThumbstick.xAxis.value, gamepad.leftThumbstick.yAxis.value),
            look: SIMD2(gamepad.rightThumbstick.xAxis.value, gamepad.rightThumbstick.yAxis.value),
            leftTrigger: gamepad.leftTrigger.value,
            rightTrigger: gamepad.rightTrigger.value,
            buttons: buttons
        )
    }

    private func runAutomationProbeIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("--input-probe") else { return }
        touch = InputSnapshot(
            movement: SIMD2(0.5, -0.75),
            look: SIMD2(-0.25, 1.0),
            rightTrigger: 1,
            buttons: [.fire, .interact]
        )
    }

    private func refreshSummary() {
        let current = snapshot(player: 0)
        let controllerCount = controllerSlots.compactMap { $0 }.count
        let actions = current.buttons.isEmpty ? "none" : "0x\(String(current.buttons.rawValue, radix: 16))"
        let activity = String(
            format: "input: move %.2f %.2f • look %.2f %.2f • actions %@ • controllers: %d",
            current.movement.x,
            current.movement.y,
            current.look.x,
            current.look.y,
            actions,
            controllerCount
        )

        if current != .neutral {
            lastActivity = activity
            diagnosticSummary = activity
        } else if let lastActivity {
            diagnosticSummary = "input: neutral • last \(lastActivity.dropFirst("input: ".count))"
        } else {
            diagnosticSummary = activity
        }
    }
}

private extension SIMD2 where Scalar == Float {
    func clampedUnitSquare() -> SIMD2<Float> {
        SIMD2(
            Swift.min(Swift.max(x, -1), 1),
            Swift.min(Swift.max(y, -1), 1)
        )
    }
}
