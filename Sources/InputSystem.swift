import CoreMotion
import Foundation
import GameController

@_silgen_name("goldenpad_mgb64_set_controller_state")
private func goldenPadMGB64SetControllerState(
    _ player: Int32,
    _ stickX: Int32,
    _ stickY: Int32,
    _ buttons: UInt32,
    _ rightX: Int32,
    _ rightY: Int32,
    _ connected: Int32
)

@_silgen_name("goldenpad_mgb64_controller_input_probe")
private func goldenPadMGB64ControllerInputProbe() -> Int32

@_silgen_name("goldenpad_mgb64_runtime_state")
private func goldenPadMGB64RuntimeState(
    _ menu: UnsafeMutablePointer<Int32>?,
    _ stage: UnsafeMutablePointer<Int32>?,
    _ pendingStage: UnsafeMutablePointer<Int32>?,
    _ selectedStage: UnsafeMutablePointer<Int32>?,
    _ hoverFolder: UnsafeMutablePointer<Int32>?,
    _ cursorX: UnsafeMutablePointer<Int32>?,
    _ cursorY: UnsafeMutablePointer<Int32>?
)

@_silgen_name("goldenpad_mgb64_gameplay_state")
private func goldenPadMGB64GameplayState(
    _ ready: UnsafeMutablePointer<Int32>?,
    _ viewMode: UnsafeMutablePointer<Int32>?,
    _ playerX: UnsafeMutablePointer<Int32>?,
    _ playerZ: UnsafeMutablePointer<Int32>?,
    _ yaw: UnsafeMutablePointer<Int32>?,
    _ pitch: UnsafeMutablePointer<Int32>?,
    _ aimMode: UnsafeMutablePointer<Int32>?,
    _ weapon: UnsafeMutablePointer<Int32>?,
    _ ammo: UnsafeMutablePointer<Int32>?,
    _ triggerTimer: UnsafeMutablePointer<Int32>?,
    _ watchState: UnsafeMutablePointer<Int32>?,
    _ outsideWatch: UnsafeMutablePointer<Int32>?,
    _ pausing: UnsafeMutablePointer<Int32>?
)

@_silgen_name("goldenpad_mgb64_request_scripted_mission_success")
private func goldenPadMGB64RequestScriptedMissionSuccess()

@_silgen_name("goldenpad_mgb64_progression_state")
private func goldenPadMGB64ProgressionState(
    _ ready: UnsafeMutablePointer<Int32>?,
    _ damAgentCompleted: UnsafeMutablePointer<Int32>?,
    _ damAgentTime: UnsafeMutablePointer<Int32>?,
    _ missionState: UnsafeMutablePointer<Int32>?,
    _ scriptedSuccessApplied: UnsafeMutablePointer<Int32>?
)

@_silgen_name("goldenpad_mgb64_dam_route_state")
private func goldenPadMGB64DamRouteState(
    _ cameraMode: UnsafeMutablePointer<Int32>?,
    _ objectiveCount: UnsafeMutablePointer<Int32>?,
    _ objective0: UnsafeMutablePointer<Int32>?,
    _ objective1: UnsafeMutablePointer<Int32>?,
    _ objective2: UnsafeMutablePointer<Int32>?,
    _ objective3: UnsafeMutablePointer<Int32>?
)

@_silgen_name("goldenpad_mgb64_dam_nav_state")
private func goldenPadMGB64DamNavState(
    _ valid: UnsafeMutablePointer<Int32>?,
    _ sourceNode: UnsafeMutablePointer<Int32>?,
    _ targetNode: UnsafeMutablePointer<Int32>?,
    _ destinationNode: UnsafeMutablePointer<Int32>?,
    _ sourceX: UnsafeMutablePointer<Int32>?,
    _ sourceZ: UnsafeMutablePointer<Int32>?,
    _ targetX: UnsafeMutablePointer<Int32>?,
    _ targetZ: UnsafeMutablePointer<Int32>?,
    _ destinationX: UnsafeMutablePointer<Int32>?,
    _ destinationZ: UnsafeMutablePointer<Int32>?,
    _ targetRoom: UnsafeMutablePointer<Int32>?,
    _ switchValid: UnsafeMutablePointer<Int32>?,
    _ switchX: UnsafeMutablePointer<Int32>?,
    _ switchZ: UnsafeMutablePointer<Int32>?,
    _ switchDoorX: UnsafeMutablePointer<Int32>?,
    _ switchDoorZ: UnsafeMutablePointer<Int32>?,
    _ switchDoorState: UnsafeMutablePointer<Int32>?,
    _ switchDoorOpenPosition: UnsafeMutablePointer<Int32>?,
    _ switchDoorPerimPosition: UnsafeMutablePointer<Int32>?,
    _ switchEligibility: UnsafeMutablePointer<Int32>?
)

@_silgen_name("goldenpad_mgb64_facility_door_state")
private func goldenPadMGB64FacilityDoorState(
    _ ready: UnsafeMutablePointer<Int32>?,
    _ count: UnsafeMutablePointer<Int32>?,
    _ state: UnsafeMutablePointer<Int32>?,
    _ openPosition: UnsafeMutablePointer<Int32>?,
    _ maxOpenPosition: UnsafeMutablePointer<Int32>?,
    _ sawOpening: UnsafeMutablePointer<Int32>?,
    _ finishedOpen: UnsafeMutablePointer<Int32>?,
    _ cameraMode: UnsafeMutablePointer<Int32>?
)

@_silgen_name("goldenpad_mgb64_facility_door155_state")
private func goldenPadMGB64FacilityDoor155State(
    _ count: UnsafeMutablePointer<Int32>?,
    _ state: UnsafeMutablePointer<Int32>?,
    _ openPosition: UnsafeMutablePointer<Int32>?,
    _ maxOpenPosition: UnsafeMutablePointer<Int32>?,
    _ sawOpening: UnsafeMutablePointer<Int32>?,
    _ finishedOpen: UnsafeMutablePointer<Int32>?
)

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
    static let n64A = InputButtons(rawValue: 1 << 13)
    static let n64B = InputButtons(rawValue: 1 << 14)
    static let n64Z = InputButtons(rawValue: 1 << 15)
    static let n64L = InputButtons(rawValue: 1 << 16)
    static let n64R = InputButtons(rawValue: 1 << 17)
    static let n64Start = InputButtons(rawValue: 1 << 18)
    static let n64CUp = InputButtons(rawValue: 1 << 19)
    static let n64CDown = InputButtons(rawValue: 1 << 20)
    static let n64CLeft = InputButtons(rawValue: 1 << 21)
    static let n64CRight = InputButtons(rawValue: 1 << 22)
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

struct N64Buttons: OptionSet, Equatable, Sendable {
    let rawValue: UInt16

    static let a = N64Buttons(rawValue: 0x8000)
    static let b = N64Buttons(rawValue: 0x4000)
    static let z = N64Buttons(rawValue: 0x2000)
    static let start = N64Buttons(rawValue: 0x1000)
    static let dpadUp = N64Buttons(rawValue: 0x0800)
    static let dpadDown = N64Buttons(rawValue: 0x0400)
    static let dpadLeft = N64Buttons(rawValue: 0x0200)
    static let dpadRight = N64Buttons(rawValue: 0x0100)
    static let l = N64Buttons(rawValue: 0x0020)
    static let r = N64Buttons(rawValue: 0x0010)
    static let cUp = N64Buttons(rawValue: 0x0008)
    static let cDown = N64Buttons(rawValue: 0x0004)
    static let cLeft = N64Buttons(rawValue: 0x0002)
    static let cRight = N64Buttons(rawValue: 0x0001)
}

struct N64ControllerState: Equatable, Sendable {
    var stick = SIMD2<Float>.zero
    var buttons: N64Buttons = []
}

struct GoldenEyeInputFrame: Equatable, Sendable {
    var primary = N64ControllerState()
    var secondary = N64ControllerState()
}

enum GoldenEyeInputMapper {
    static func map(_ input: InputSnapshot, preset: ControlPreset) -> GoldenEyeInputFrame {
        var buttons = mappedButtons(input)

        if preset == .classic {
            let threshold: Float = 0.42
            if input.look.y > threshold { buttons.insert(.cUp) }
            if input.look.y < -threshold { buttons.insert(.cDown) }
            if input.look.x < -threshold { buttons.insert(.cLeft) }
            if input.look.x > threshold { buttons.insert(.cRight) }
        }

        switch preset {
        case .classic:
            return GoldenEyeInputFrame(
                primary: N64ControllerState(stick: input.movement, buttons: buttons)
            )
        case .modern:
            return GoldenEyeInputFrame(
                primary: N64ControllerState(stick: input.movement, buttons: buttons),
                secondary: N64ControllerState(stick: input.look)
            )
        case .southpaw:
            return GoldenEyeInputFrame(
                primary: N64ControllerState(stick: input.look, buttons: buttons),
                secondary: N64ControllerState(stick: input.movement)
            )
        }
    }

    private static func mappedButtons(_ input: InputSnapshot) -> N64Buttons {
        var result: N64Buttons = []
        let buttons = input.buttons

        if buttons.contains(.fire) || buttons.contains(.n64Z) || input.rightTrigger > 0.25 {
            result.insert(.z)
        }
        if buttons.contains(.aim) || buttons.contains(.n64R) || input.leftTrigger > 0.25 {
            result.insert(.r)
        }
        if buttons.contains(.interact) || buttons.contains(.reload) || buttons.contains(.cancel) || buttons.contains(.n64B) {
            result.insert(.b)
        }
        if buttons.contains(.nextWeapon) || buttons.contains(.confirm) || buttons.contains(.n64A) {
            result.insert(.a)
        }
        if buttons.contains(.crouch) || buttons.contains(.n64CDown) { result.insert(.cDown) }
        if buttons.contains(.pause) || buttons.contains(.n64Start) { result.insert(.start) }
        if buttons.contains(.n64L) { result.insert(.l) }
        if buttons.contains(.n64CUp) { result.insert(.cUp) }
        if buttons.contains(.n64CLeft) { result.insert(.cLeft) }
        if buttons.contains(.n64CRight) { result.insert(.cRight) }
        if buttons.contains(.dpadUp) { result.insert(.dpadUp) }
        if buttons.contains(.dpadDown) { result.insert(.dpadDown) }
        if buttons.contains(.dpadLeft) { result.insert(.dpadLeft) }
        if buttons.contains(.dpadRight) { result.insert(.dpadRight) }
        return result
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

private enum GameplayProbePhase {
    case waiting, settle, movement, aim, fire
    case reloadPulse, reloadWait, weaponPulse, weaponWait
    case pausePulse, pauseWait, complete
}

private enum MissionFlowProbePhase {
    case waitingForDam, settle, waitingForStatus
    case statusSettle, advanceStatus, waitingForReport
    case reportSettle, dismissReport, waitingForMissionSelect, complete
}

private enum FacilityDoorProbePhase {
    case waitingForDam, damSettle, waitingForStatus
    case statusSettle, advanceStatus, waitingForReport
    case reportSettle, advanceReport, waitingForBriefing
    case briefingSettle, startFacility, waitingForFacility
    case route, complete
}

private enum DamRouteProbePhase {
    case waitingForDam, route, complete
}

@MainActor
final class InputCoordinator: ObservableObject {
    @Published private(set) var diagnosticSummary = "input: neutral • controllers: 0"
    @Published private(set) var connectedControllerCount = 0
    @Published private(set) var externalControllerCount = 0
    @Published private(set) var currentPreset = ControlPreset.modern

    private var touch = InputSnapshot.neutral
    private var controllerSlots: [GCController?] = Array(repeating: nil, count: 4)
    private var lastActivity: String?
    private var observers: [NSObjectProtocol] = []
    private var settings = HostSettings()
    private let motionManager = CMMotionManager()
    private var motionLook = SIMD2<Float>.zero
    private var didReportCoreInputProbe = false
    private var menuProbeLastMenu: Int32 = .min
    private var menuProbeLastStage: Int32 = .min
    private var menuProbeLastPendingStage: Int32 = .min
    private var menuProbeFramesInMenu = 0
    private var didReportMenuProbeMissionLoad = false
    private var gameplayProbePhase = GameplayProbePhase.waiting
    private var gameplayProbeFrames = 0
    private var gameplayProbeStartX: Int32 = 0
    private var gameplayProbeStartZ: Int32 = 0
    private var gameplayProbeStartYaw: Int32 = 0
    private var gameplayProbeStartPitch: Int32 = 0
    private var gameplayProbeInitialWeapon: Int32 = -1
    private var gameplayProbeFireAmmo: Int32 = -1
    private var gameplayProbePostFireAmmo: Int32 = -1
    private var gameplayProbeSawAim = false
    private var gameplayProbeSawPause = false
    private var missionFlowProbePhase = MissionFlowProbePhase.waitingForDam
    private var missionFlowProbeFrames = 0
    private var facilityDoorProbePhase = FacilityDoorProbePhase.waitingForDam
    private var facilityDoorProbeFrames = 0
    private var facilityDoorRouteFrame = 0
    private var facilityDoorRouteStartX: Int32 = 0
    private var facilityDoorRouteStartZ: Int32 = 0
    private var facilityDoorRouteStartYaw: Int32 = 0
    private var facilityDoorRouteInput: GoldenEyeInputFrame?
    private var damRouteProbePhase = DamRouteProbePhase.waitingForDam
    private var damRouteFrame = 0
    private var damRouteStartX: Int32 = 0
    private var damRouteStartZ: Int32 = 0
    private var damRouteStartObjectives: [Int32] = []
    private var damRouteInput: GoldenEyeInputFrame?
    private var damNavFrame = 0
    private var damNavLastTargetNode: Int32 = -1
    private var damNavBestTargetDistance = Int.max
    private var damNavFramesWithoutTargetProgress = 0
    private var damNavRecoveryReported = false
    private var damNavSwitchPulseSent = false
    private var damNavSwitchHoldFrames = 0
    private var damNavSwitchSettleFrames = 0
    private var damNavSwitchRetryFrames = 0
    private var damNavSwitchAttempts = 0
    private var damNavSwitchAligningWall = false
    private var damNavSwitchWallAlignFrames = 0
    private var damNavSwitchWallAligned = false
    private var damNavSwitchCrossingFrames = 0
    private var damNavSwitchCrossingStarted = false
    private var damNavCrossingSourceX: Int32 = 0
    private var damNavCrossingSourceZ: Int32 = 0
    private var damNavCrossingTargetX: Int32 = 0
    private var damNavCrossingTargetZ: Int32 = 0
    private var damNavCrossingDoorX: Int32 = 0
    private var damNavCrossingDoorZ: Int32 = 0
    private var didReportProgressionProbe = false

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
        motionManager.stopDeviceMotionUpdates()
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    var shouldShowTouchControls: Bool {
        !settings.touchControlsAutoHide || externalControllerCount == 0
    }

    func configure(settings: HostSettings) {
        let sanitized = settings.sanitized()
        let gyroChanged = self.settings.gyroEnabled != sanitized.gyroEnabled
        let presetChanged = self.settings.controlPreset != sanitized.controlPreset
        self.settings = sanitized
        currentPreset = sanitized.controlPreset
        if presetChanged {
            lastActivity = nil
        }
        if gyroChanged {
            configureMotionUpdates()
        }
        refreshSummary()
    }

    func releaseTouchInput() {
        touch = .neutral
        motionLook = .zero
        refreshSummary()
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
        guard player == 0 else { return controller }

        var combined = controller.merging(touch)
        combined.movement = combined.movement.applyingRadialDeadZone(
            Float(settings.stickDeadZone)
        )
        let touchAndStickLook = combined.look.applyingRadialDeadZone(
            Float(settings.stickDeadZone)
        )
        combined.look = ((touchAndStickLook + motionLook) * Float(settings.lookSensitivity))
            .clampedUnitSquare()
        return combined
    }

    func mappedFrame(player: Int) -> GoldenEyeInputFrame {
        GoldenEyeInputMapper.map(snapshot(player: player), preset: currentPreset)
    }

    func publishToCore() {
        runMenuProbeIfRequested()
        runGameplayProbeIfRequested()
        runMissionFlowProbeIfRequested()
        runDamRouteProbeIfRequested()
        runFacilityDoorProbeIfRequested()
        runProgressionProbeIfRequested()
        if !didReportCoreInputProbe,
           ProcessInfo.processInfo.arguments.contains("--input-probe") {
            touch = InputSnapshot(
                movement: SIMD2(0.5, -0.75),
                look: SIMD2(-0.25, 1.0),
                rightTrigger: 1,
                buttons: [.fire, .interact]
            )
        }
        for player in 0..<controllerSlots.count {
            let frame = player == 0
                ? damRouteInput ?? facilityDoorRouteInput ?? mappedFrame(player: player)
                : mappedFrame(player: player)
            let primary = frame.primary
            let secondary = frame.secondary
            let connected = player == 0 || controllerSlots[player] != nil
            goldenPadMGB64SetControllerState(
                Int32(player),
                Int32((primary.stick.x * 80).rounded()),
                Int32((primary.stick.y * 80).rounded()),
                UInt32(primary.buttons.rawValue),
                Int32((secondary.stick.x * 32_767).rounded()),
                Int32((-secondary.stick.y * 32_767).rounded()),
                connected ? 1 : 0
            )
        }
        if !didReportCoreInputProbe,
           ProcessInfo.processInfo.arguments.contains("--input-probe") {
            didReportCoreInputProbe = true
            let result = goldenPadMGB64ControllerInputProbe()
            print("[GoldenPad] Mobile core input probe: \(result == 1 ? "PASS" : "FAIL")")
        }
    }

    private func runMenuProbeIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--menu-probe") ||
                arguments.contains("--gameplay-probe") ||
                arguments.contains("--mission-flow-probe") ||
                arguments.contains("--dam-route-probe") ||
                arguments.contains("--dam-nav-probe") ||
                arguments.contains("--facility-door-probe") ||
                arguments.contains("--facility-door-chain-probe") else { return }
        if arguments.contains("--mission-flow-probe") {
            if case .complete = missionFlowProbePhase {
                touch = .neutral
                return
            }
        }
        var menu: Int32 = -1
        var stage: Int32 = -1
        var pendingStage: Int32 = -1
        var selectedStage: Int32 = -1
        var hoverFolder: Int32 = -1
        var cursorX: Int32 = 0
        var cursorY: Int32 = 0
        goldenPadMGB64RuntimeState(
            &menu, &stage, &pendingStage, &selectedStage,
            &hoverFolder, &cursorX, &cursorY
        )

        if menu != menuProbeLastMenu {
            menuProbeLastMenu = menu
            menuProbeFramesInMenu = 0
            print(
                "[GoldenPad] Menu probe state: menu=\(menu) stage=\(stage) " +
                "pending=\(pendingStage) selected=\(selectedStage) " +
                "hover=\(hoverFolder) cursor=\(cursorX),\(cursorY)"
            )
        } else {
            menuProbeFramesInMenu += 1
        }

        if stage != menuProbeLastStage || pendingStage != menuProbeLastPendingStage {
            menuProbeLastStage = stage
            menuProbeLastPendingStage = pendingStage
            print(
                "[GoldenPad] Menu probe stage: active=\(stage) pending=\(pendingStage) " +
                "selected=\(selectedStage)"
            )
        }
        if !didReportMenuProbeMissionLoad, stage == 33 {
            didReportMenuProbeMissionLoad = true
            print("[GoldenPad] Menu probe controlled Dam load: PASS")
        }

        touch = .neutral
        let isActionableMenu = (0...10).contains(menu) && menu != 5 ||
            (menu == 5 && hoverFolder >= 0)
        if isActionableMenu,
           menuProbeFramesInMenu >= 30,
           (menuProbeFramesInMenu - 30).isMultiple(of: 120) {
            touch.buttons = [.pause]
            print("[GoldenPad] Menu probe Start pulse: menu=\(menu)")
        } else if menu == 5,
                  menuProbeFramesInMenu > 0,
                  menuProbeFramesInMenu.isMultiple(of: 120) {
            print(
                "[GoldenPad] Menu probe waiting for folder: hover=\(hoverFolder) " +
                "cursor=\(cursorX),\(cursorY)"
            )
        }
    }

    private func runDamRouteProbeIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments
        let isNavProbe = arguments.contains("--dam-nav-probe")
        guard arguments.contains("--dam-route-probe") || isNavProbe else {
            return
        }

        var stage: Int32 = -1
        var ready: Int32 = 0
        var viewMode: Int32 = -1
        var playerX: Int32 = 0
        var playerZ: Int32 = 0
        var yaw: Int32 = 0
        var cameraMode: Int32 = -1
        var objectiveCount: Int32 = 0
        var objective0: Int32 = -1
        var objective1: Int32 = -1
        var objective2: Int32 = -1
        var objective3: Int32 = -1
        var navValid: Int32 = 0
        var navSourceNode: Int32 = -1
        var navTargetNode: Int32 = -1
        var navDestinationNode: Int32 = -1
        var navSourceX: Int32 = 0
        var navSourceZ: Int32 = 0
        var navTargetX: Int32 = 0
        var navTargetZ: Int32 = 0
        var navDestinationX: Int32 = 0
        var navDestinationZ: Int32 = 0
        var navTargetRoom: Int32 = -1
        var navSwitchValid: Int32 = 0
        var navSwitchX: Int32 = 0
        var navSwitchZ: Int32 = 0
        var navSwitchDoorX: Int32 = 0
        var navSwitchDoorZ: Int32 = 0
        var navSwitchDoorState: Int32 = -1
        var navSwitchDoorOpenPosition: Int32 = 0
        var navSwitchDoorPerimPosition: Int32 = 0
        var navSwitchEligibility: Int32 = 0
        goldenPadMGB64RuntimeState(nil, &stage, nil, nil, nil, nil, nil)
        goldenPadMGB64GameplayState(
            &ready, &viewMode, &playerX, &playerZ, &yaw, nil,
            nil, nil, nil, nil, nil, nil, nil
        )
        goldenPadMGB64DamRouteState(
            &cameraMode, &objectiveCount, &objective0, &objective1,
            &objective2, &objective3
        )
        goldenPadMGB64DamNavState(
            &navValid, &navSourceNode, &navTargetNode,
            &navDestinationNode, &navSourceX, &navSourceZ,
            &navTargetX, &navTargetZ,
            &navDestinationX, &navDestinationZ, &navTargetRoom,
            &navSwitchValid, &navSwitchX, &navSwitchZ,
            &navSwitchDoorX, &navSwitchDoorZ, &navSwitchDoorState,
            &navSwitchDoorOpenPosition, &navSwitchDoorPerimPosition,
            &navSwitchEligibility
        )

        damRouteInput = nil
        switch damRouteProbePhase {
        case .waitingForDam:
            guard stage == 33, ready == 1, viewMode == 0, cameraMode == 4 else {
                return
            }
            damRouteStartX = playerX
            damRouteStartZ = playerZ
            damRouteStartObjectives = [
                objective0, objective1, objective2, objective3
            ]
            damRouteFrame = 0
            damNavFrame = 0
            damNavLastTargetNode = -1
            damNavBestTargetDistance = .max
            damNavFramesWithoutTargetProgress = 0
            damNavRecoveryReported = false
            damNavSwitchPulseSent = false
            damNavSwitchHoldFrames = 0
            damNavSwitchSettleFrames = 0
            damNavSwitchRetryFrames = 0
            damNavSwitchAttempts = 0
            damNavSwitchAligningWall = false
            damNavSwitchWallAlignFrames = 0
            damNavSwitchWallAligned = false
            damNavSwitchCrossingFrames = 0
            damNavSwitchCrossingStarted = false
            damRouteProbePhase = .route
            print(
                "[GoldenPad] Dam native route stock spawn: PASS " +
                "pos=\(playerX),\(playerZ) yaw=\(yaw) camera=\(cameraMode) " +
                "objectives=\(objectiveCount):" +
                "[\(objective0),\(objective1),\(objective2),\(objective3)]"
            )

        case .route:
            var routeFrame = GoldenEyeInputFrame()
            if (80..<125).contains(damRouteFrame) {
                routeFrame.primary.stick.y = 1
            }
            if (140..<185).contains(damRouteFrame) {
                routeFrame.primary.buttons.insert(.cRight)
            }
            if (200..<245).contains(damRouteFrame) {
                routeFrame.primary.stick.y = 1
                routeFrame.primary.buttons.insert(.cRight)
            }
            // MGB64's desktop contract releases at frame 620. Mobile display
            // cadence can publish fewer of those samples on the higher-cost
            // iPad surface, so retain the same input for a bounded 20-frame
            // tail while keeping the upstream 4,700-unit acceptance line.
            if (260..<640).contains(damRouteFrame) {
                routeFrame.primary.stick = SIMD2(-1, 1)
            }

            if isNavProbe, damRouteFrame >= 640, navValid == 1 {
                let deltaX = Double(navTargetX - playerX)
                let deltaZ = Double(navTargetZ - playerZ)
                let targetDistance = Int(sqrt(
                    deltaX * deltaX + deltaZ * deltaZ
                ).rounded())
                var desiredYaw = atan2(-deltaX, deltaZ) * 180.0 / .pi
                if desiredYaw < 0 { desiredYaw += 360.0 }
                var yawError = desiredYaw - Double(yaw) / 100.0
                while yawError > 180.0 { yawError -= 360.0 }
                while yawError < -180.0 { yawError += 360.0 }

                routeFrame.secondary.stick.x = Float(
                    max(-1.0, min(1.0, yawError / 45.0))
                )
                let absoluteYawError = abs(yawError)
                if absoluteYawError < 70.0 {
                    routeFrame.primary.stick.y = absoluteYawError < 25.0 ? 1.0 : 0.6
                }

                damNavFrame += 1

                if navTargetNode != damNavLastTargetNode {
                    damNavLastTargetNode = navTargetNode
                    damNavBestTargetDistance = targetDistance
                    damNavFramesWithoutTargetProgress = 0
                    damNavRecoveryReported = false
                    if damNavSwitchCrossingFrames > 0 {
                        damNavCrossingSourceX = navSourceX
                        damNavCrossingSourceZ = navSourceZ
                        damNavCrossingTargetX = navTargetX
                        damNavCrossingTargetZ = navTargetZ
                        damNavCrossingDoorX = navSwitchDoorX
                        damNavCrossingDoorZ = navSwitchDoorZ
                    } else {
                        damNavSwitchPulseSent = false
                        damNavSwitchHoldFrames = 0
                        damNavSwitchSettleFrames = 0
                        damNavSwitchRetryFrames = 0
                        damNavSwitchAttempts = 0
                        damNavSwitchAligningWall = false
                        damNavSwitchWallAlignFrames = 0
                        damNavSwitchWallAligned = false
                        damNavSwitchCrossingStarted = false
                    }
                    print(
                        "[GoldenPad] Dam nav target: source=\(navSourceNode) " +
                        "target=\(navTargetNode) destination=\(navDestinationNode) " +
                        "room=\(navTargetRoom) pos=\(navTargetX),\(navTargetZ)"
                    )
                } else if targetDistance <= damNavBestTargetDistance - 5_000 {
                    damNavBestTargetDistance = targetDistance
                    damNavFramesWithoutTargetProgress = 0
                    damNavRecoveryReported = false
                } else {
                    damNavFramesWithoutTargetProgress += 1
                }

                if navSwitchValid == 1,
                   !damNavSwitchCrossingStarted,
                   damNavSwitchCrossingFrames == 0,
                   navSwitchDoorPerimPosition > 0,
                   (navSwitchDoorState == 1 ||
                    navSwitchDoorOpenPosition + 60 >= navSwitchDoorPerimPosition) {
                    damNavCrossingSourceX = navSourceX
                    damNavCrossingSourceZ = navSourceZ
                    damNavCrossingTargetX = navTargetX
                    damNavCrossingTargetZ = navTargetZ
                    damNavCrossingDoorX = navSwitchDoorX
                    damNavCrossingDoorZ = navSwitchDoorZ
                    damNavSwitchCrossingFrames = 600
                    damNavSwitchCrossingStarted = true
                    print(
                        "[GoldenPad] Dam nav linked door crossing: " +
                        "pos=\(navSwitchDoorX),\(navSwitchDoorZ) " +
                        "state=\(navSwitchDoorState) " +
                        "open=\(navSwitchDoorOpenPosition) " +
                        "perim=\(navSwitchDoorPerimPosition)"
                    )
                }

                if damNavSwitchCrossingFrames > 0 {
                    let doorVectorX = Double(
                        damNavCrossingTargetX - damNavCrossingSourceX
                    )
                    let doorVectorZ = Double(
                        damNavCrossingTargetZ - damNavCrossingSourceZ
                    )
                    let doorVectorLength = max(
                        1.0, sqrt(doorVectorX * doorVectorX + doorVectorZ * doorVectorZ)
                    )
                    let crossingTargetX = Double(damNavCrossingDoorX) +
                        doorVectorX / doorVectorLength * 140_000.0
                    let crossingTargetZ = Double(damNavCrossingDoorZ) +
                        doorVectorZ / doorVectorLength * 140_000.0
                    let crossingDeltaX = crossingTargetX - Double(playerX)
                    let crossingDeltaZ = crossingTargetZ - Double(playerZ)
                    var crossingYaw = atan2(
                        -crossingDeltaX, crossingDeltaZ
                    ) * 180.0 / .pi
                    if crossingYaw < 0 { crossingYaw += 360.0 }
                    var crossingYawError = crossingYaw - Double(yaw) / 100.0
                    while crossingYawError > 180.0 { crossingYawError -= 360.0 }
                    while crossingYawError < -180.0 { crossingYawError += 360.0 }
                    routeFrame.secondary.stick.x = Float(
                        max(-1.0, min(1.0, crossingYawError / 45.0))
                    )
                    routeFrame.primary.stick = .zero
                    if abs(crossingYawError) < 70.0 {
                        routeFrame.primary.stick.y = abs(crossingYawError) < 25.0
                            ? 1.0 : 0.6
                    }
                    damNavSwitchCrossingFrames -= 1
                    if damNavSwitchCrossingFrames == 0 {
                        damNavSwitchCrossingStarted = false
                        damNavSwitchPulseSent = false
                        damNavSwitchHoldFrames = 0
                        damNavSwitchSettleFrames = 0
                        damNavSwitchRetryFrames = 0
                        damNavSwitchAttempts = 0
                        damNavSwitchAligningWall = false
                        damNavSwitchWallAlignFrames = 0
                        damNavSwitchWallAligned = false
                    }
                }

                if damNavFramesWithoutTargetProgress >= 180,
                   damNavSwitchCrossingFrames == 0,
                   !damNavSwitchCrossingStarted {
                    let recoveryFrame =
                        (damNavFramesWithoutTargetProgress - 180) % 360
                    if navSwitchValid == 1, !damNavSwitchPulseSent {
                        let switchDeltaX = Double(navSwitchX - playerX)
                        let switchDeltaZ = Double(navSwitchZ - playerZ)
                        let switchDistance = Int(sqrt(
                            switchDeltaX * switchDeltaX +
                            switchDeltaZ * switchDeltaZ
                        ).rounded())
                        var switchYaw = atan2(
                            -switchDeltaX, switchDeltaZ
                        ) * 180.0 / .pi
                        if switchYaw < 0 { switchYaw += 360.0 }
                        var switchYawError = switchYaw - Double(yaw) / 100.0
                        while switchYawError > 180.0 { switchYawError -= 360.0 }
                        while switchYawError < -180.0 { switchYawError += 360.0 }
                        routeFrame.secondary.stick.x = Float(
                            max(-1.0, min(1.0, switchYawError / 45.0))
                        )
                        routeFrame.primary.stick = .zero
                        if abs(switchYawError) < 65.0, switchDistance > 10_000 {
                            routeFrame.primary.stick.y = switchDistance > 40_000
                                ? 1.0 : 0.35
                        }
                        if (!damNavSwitchWallAligned || abs(switchDeltaZ) > 3_000),
                           switchDistance < 60_000,
                           abs(switchDeltaZ) > 1_000 {
                            if !damNavSwitchAligningWall {
                                damNavSwitchWallAlignFrames = 0
                            }
                            damNavSwitchAligningWall = true
                            damNavSwitchWallAligned = false
                        } else if damNavSwitchAligningWall,
                                  abs(switchDeltaZ) <= 1_000 {
                            damNavSwitchAligningWall = false
                            damNavSwitchWallAligned = true
                        }
                        if damNavSwitchAligningWall {
                            damNavSwitchWallAlignFrames += 1
                            if damNavSwitchWallAlignFrames >= 600 {
                                damNavSwitchAligningWall = false
                                damNavSwitchWallAligned = true
                            }
                        }
                        if damNavSwitchAligningWall {
                            // Walk parallel to the blocking wall until the
                            // live player/switch Z positions align, then face
                            // the button again. This stays entirely inside the
                            // retail controller path.
                            let wallYaw = switchDeltaZ > 0 ? 0.0 : 180.0
                            var wallYawError = wallYaw - Double(yaw) / 100.0
                            while wallYawError > 180.0 { wallYawError -= 360.0 }
                            while wallYawError < -180.0 { wallYawError += 360.0 }
                            routeFrame.primary.stick = .zero
                            routeFrame.secondary.stick.x = Float(
                                max(-1.0, min(1.0, wallYawError / 45.0))
                            )
                            if abs(wallYawError) < 25.0 {
                                routeFrame.primary.stick.y = 0.15
                            }
                        }
                        if navSwitchDoorState == 1 {
                            damNavSwitchPulseSent = true
                            damNavCrossingSourceX = navSourceX
                            damNavCrossingSourceZ = navSourceZ
                            damNavCrossingTargetX = navTargetX
                            damNavCrossingTargetZ = navTargetZ
                            damNavCrossingDoorX = navSwitchDoorX
                            damNavCrossingDoorZ = navSwitchDoorZ
                            print(
                                "[GoldenPad] Dam nav linked door already opening: " +
                                "open=\(navSwitchDoorOpenPosition) " +
                                "perim=\(navSwitchDoorPerimPosition)"
                            )
                        } else if navSwitchEligibility == 0x1ff,
                                  abs(switchYawError) < 8.0,
                                  !damNavSwitchAligningWall {
                            // The eligibility snapshot and controller sample
                            // cross threads. Stop turning long enough for the
                            // game thread to observe a stationary candidate
                            // before sending the single Use edge.
                            routeFrame.primary.stick = .zero
                            routeFrame.secondary.stick = .zero
                            if damNavSwitchSettleFrames < 12 {
                                damNavSwitchSettleFrames += 1
                            } else {
                                routeFrame.primary.buttons.insert(.b)
                                damNavSwitchPulseSent = true
                                damNavSwitchAttempts += 1
                                damNavSwitchRetryFrames = 0
                                // Keep one press visible across the independent
                                // display/game cadences. The N64 still observes a
                                // single edge followed by a held button.
                                damNavSwitchHoldFrames = 8
                                damNavCrossingSourceX = navSourceX
                                damNavCrossingSourceZ = navSourceZ
                                damNavCrossingTargetX = navTargetX
                                damNavCrossingTargetZ = navTargetZ
                                damNavCrossingDoorX = navSwitchDoorX
                                damNavCrossingDoorZ = navSwitchDoorZ
                                print(
                                    "[GoldenPad] Dam nav linked-switch B edge: " +
                                    "pos=\(navSwitchX),\(navSwitchZ) " +
                                    "doorState=\(navSwitchDoorState) " +
                                    "open=\(navSwitchDoorOpenPosition) " +
                                    "perim=\(navSwitchDoorPerimPosition) eligibility=0x1ff"
                                )
                            }
                        } else {
                            damNavSwitchSettleFrames = 0
                        }
                    } else if navSwitchValid == 1, damNavSwitchPulseSent {
                        // Hold position while the stock linked door opens.
                        // Crossing begins only after its own collision-clear
                        // threshold is observed above.
                        routeFrame.primary.stick = .zero
                        routeFrame.secondary.stick = .zero
                        if navSwitchDoorState == 3 {
                            // Dam's paired gate waits for the first slab to
                            // close. Keep walking toward the second slab so
                            // Bond vacates the first slab's collision zone.
                            routeFrame.secondary.stick.x = Float(
                                max(-1.0, min(1.0, yawError / 45.0))
                            )
                            if abs(yawError) < 70.0 {
                                routeFrame.primary.stick.y = 1.0
                            }
                            damNavSwitchHoldFrames = 0
                        } else if damNavSwitchHoldFrames > 0 {
                            routeFrame.primary.buttons.insert(.b)
                            damNavSwitchHoldFrames -= 1
                        } else if navSwitchDoorState == 0,
                                  navSwitchDoorOpenPosition == 0,
                                  damNavSwitchAttempts < 4 {
                            damNavSwitchRetryFrames += 1
                            if damNavSwitchRetryFrames >= 90 {
                                damNavSwitchPulseSent = false
                                damNavSwitchSettleFrames = 0
                                damNavSwitchRetryFrames = 0
                                print(
                                    "[GoldenPad] Dam nav linked-switch retry: " +
                                    "attempt=\(damNavSwitchAttempts + 1) " +
                                    "doorState=0 open=0"
                                )
                            }
                        }
                    } else if navSwitchValid == 0 {
                        // Fall back to following a blocking surface in both
                        // directions when the live setup has no nearby switch.
                        routeFrame.primary.stick.x = recoveryFrame < 180 ? 1 : -1
                        routeFrame.primary.stick.y = 0.35
                        if recoveryFrame.isMultiple(of: 15) ||
                            recoveryFrame % 15 == 1 {
                            routeFrame.primary.buttons.insert(.b)
                        }
                    }
                    if !damNavRecoveryReported {
                        damNavRecoveryReported = true
                        print(
                            "[GoldenPad] Dam nav controller recovery: " +
                            "target=\(navTargetNode) distance=\(targetDistance / 100) " +
                            "switch=\(navSwitchValid):\(navSwitchX),\(navSwitchZ)"
                        )
                    }
                }
            }
            damRouteInput = routeFrame
            damRouteFrame += 1

            if [80, 125, 140, 185, 200, 245, 260, 440, 620, 640, 900].contains(
                damRouteFrame
            ) {
                let deltaX = playerX - damRouteStartX
                let deltaZ = playerZ - damRouteStartZ
                print(
                    "[GoldenPad] Dam native route frame \(damRouteFrame): " +
                    "pos=\(playerX),\(playerZ) delta=\(deltaX),\(deltaZ) yaw=\(yaw)"
                )
            }

            if isNavProbe, damRouteFrame >= 640 {
                let destinationDeltaX = Double(navDestinationX - playerX)
                let destinationDeltaZ = Double(navDestinationZ - playerZ)
                let destinationDistance = Int(sqrt(
                    destinationDeltaX * destinationDeltaX +
                    destinationDeltaZ * destinationDeltaZ
                ).rounded())
                if damNavFrame > 0, damNavFrame.isMultiple(of: 300) {
                    print(
                        "[GoldenPad] Dam nav frame \(damNavFrame): " +
                        "pos=\(playerX),\(playerZ) yaw=\(yaw) " +
                        "source=\(navSourceNode) target=\(navTargetNode) " +
                        "destinationDistance=\(destinationDistance / 100) " +
                        "door=\(navSwitchDoorState):" +
                        "\(navSwitchDoorOpenPosition)/\(navSwitchDoorPerimPosition) " +
                        "doorPos=\(navSwitchDoorX),\(navSwitchDoorZ) " +
                        "switchEligibility=0x\(String(navSwitchEligibility, radix: 16))"
                    )
                }

                let reachedDestination = navValid == 1 &&
                    destinationDistance <= 50_000
                let timedOut = damRouteFrame >= 12_500
                guard reachedDestination || timedOut else { return }

                let deltaX = Double(playerX - damRouteStartX)
                let deltaZ = Double(playerZ - damRouteStartZ)
                let distance = Int(sqrt(deltaX * deltaX + deltaZ * deltaZ).rounded())
                let finalObjectives = [objective0, objective1, objective2, objective3]
                let objectivesUnchanged = finalObjectives == damRouteStartObjectives
                let passed = reachedDestination && distance >= 1_500_000 &&
                    objectiveCount == 4 && objectivesUnchanged
                damRouteProbePhase = .complete
                damRouteInput = nil
                touch = .neutral
                print(
                    "[GoldenPad] Dam read-only nav controller route: " +
                    "\(passed ? "PASS" : "FAIL") distance=\(distance / 100) " +
                    "destinationDistance=\(destinationDistance / 100) " +
                    "source=\(navSourceNode) destination=\(navDestinationNode) " +
                    "final=\(playerX),\(playerZ) " +
                    "objectives=\(objectiveCount):" +
                    "[\(objective0),\(objective1),\(objective2),\(objective3)] " +
                    "stateMutation=\(objectivesUnchanged ? 0 : 1)"
                )
                return
            }

            guard damRouteFrame >= 900 else { return }
            let deltaX = Double(playerX - damRouteStartX)
            let deltaZ = Double(playerZ - damRouteStartZ)
            let distance = Int(sqrt(deltaX * deltaX + deltaZ * deltaZ).rounded())
            let finalObjectives = [objective0, objective1, objective2, objective3]
            let objectivesUnchanged = finalObjectives == damRouteStartObjectives
            let passed = distance >= 470_000 && objectiveCount == 4 &&
                objectivesUnchanged
            damRouteProbePhase = .complete
            damRouteInput = nil
            touch = .neutral
            print(
                "[GoldenPad] Dam native multiwaypoint controller route: " +
                "\(passed ? "PASS" : "FAIL") distance=\(distance / 100) " +
                "final=\(playerX),\(playerZ) camera=\(cameraMode) " +
                "objectives=\(objectiveCount):" +
                "[\(objective0),\(objective1),\(objective2),\(objective3)] " +
                "stateMutation=\(objectivesUnchanged ? 0 : 1)"
            )

        case .complete:
            touch = .neutral
        }
    }

    private func runGameplayProbeIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("--gameplay-probe") else { return }
        var ready: Int32 = 0
        var viewMode: Int32 = -1
        var playerX: Int32 = 0
        var playerZ: Int32 = 0
        var yaw: Int32 = 0
        var pitch: Int32 = 0
        var aimMode: Int32 = 0
        var weapon: Int32 = -1
        var ammo: Int32 = -1
        var triggerTimer: Int32 = 0
        var watchState: Int32 = 0
        var outsideWatch: Int32 = 1
        var pausing: Int32 = 0
        goldenPadMGB64GameplayState(
            &ready, &viewMode, &playerX, &playerZ, &yaw, &pitch,
            &aimMode, &weapon, &ammo, &triggerTimer, &watchState,
            &outsideWatch, &pausing
        )

        guard ready == 1, viewMode == 0 else { return }
        if gameplayProbePhase == .waiting, ammo <= 0 { return }
        touch = .neutral
        gameplayProbeFrames += 1
        gameplayProbeSawAim = gameplayProbeSawAim || aimMode != 0
        gameplayProbeSawPause = gameplayProbeSawPause ||
            watchState != 0 || outsideWatch == 0 || pausing != 0

        switch gameplayProbePhase {
        case .waiting:
            gameplayProbeStartX = playerX
            gameplayProbeStartZ = playerZ
            gameplayProbeInitialWeapon = weapon
            gameplayProbePhase = .settle
            gameplayProbeFrames = 0
            print(
                "[GoldenPad] Gameplay probe ready: pos=\(playerX),\(playerZ) " +
                "weapon=\(weapon) ammo=\(ammo)"
            )

        case .settle:
            if gameplayProbeFrames >= 90 {
                gameplayProbeStartX = playerX
                gameplayProbeStartZ = playerZ
                gameplayProbePhase = .movement
                gameplayProbeFrames = 0
                print("[GoldenPad] Gameplay probe movement: begin")
            }

        case .movement:
            touch.movement = SIMD2(0, 0.8)
            if gameplayProbeFrames >= 120 {
                let deltaX = Double(playerX - gameplayProbeStartX)
                let deltaZ = Double(playerZ - gameplayProbeStartZ)
                let distance = Int(sqrt(deltaX * deltaX + deltaZ * deltaZ).rounded())
                print(
                    "[GoldenPad] Gameplay probe movement: " +
                    "\(distance >= 500 ? "PASS" : "FAIL") delta=\(distance)"
                )
                gameplayProbeStartYaw = yaw
                gameplayProbeStartPitch = pitch
                gameplayProbePhase = .aim
                gameplayProbeFrames = 0
            }

        case .aim:
            touch.look = SIMD2(0.7, -0.35)
            touch.leftTrigger = 1
            touch.buttons = [.aim]
            if gameplayProbeFrames >= 90 {
                let angleDelta = max(
                    abs(yaw - gameplayProbeStartYaw),
                    abs(pitch - gameplayProbeStartPitch)
                )
                let passed = gameplayProbeSawAim && angleDelta >= 50
                print(
                    "[GoldenPad] Gameplay probe aim/look: " +
                    "\(passed ? "PASS" : "FAIL") mode=\(aimMode) delta=\(angleDelta)"
                )
                gameplayProbeFireAmmo = ammo
                gameplayProbePhase = .fire
                gameplayProbeFrames = 0
            }

        case .fire:
            touch.rightTrigger = 1
            touch.buttons = [.fire]
            if gameplayProbeFrames >= 30 {
                gameplayProbePostFireAmmo = ammo
                print(
                    "[GoldenPad] Gameplay probe fire: " +
                    "\(ammo < gameplayProbeFireAmmo ? "PASS" : "FAIL") " +
                    "ammo=\(gameplayProbeFireAmmo)->\(ammo) trigger=\(triggerTimer)"
                )
                gameplayProbePhase = .reloadPulse
                gameplayProbeFrames = 0
            }

        case .reloadPulse:
            touch.buttons = [.reload]
            if gameplayProbeFrames >= 6 {
                gameplayProbePhase = .reloadWait
                gameplayProbeFrames = 0
            }

        case .reloadWait:
            if gameplayProbeFrames >= 180 {
                print(
                    "[GoldenPad] Gameplay probe reload/interact: " +
                    "\(ammo > gameplayProbePostFireAmmo ? "PASS" : "FAIL") " +
                    "ammo=\(gameplayProbePostFireAmmo)->\(ammo)"
                )
                gameplayProbePhase = .weaponPulse
                gameplayProbeFrames = 0
            }

        case .weaponPulse:
            touch.buttons = [.nextWeapon]
            if gameplayProbeFrames >= 6 {
                gameplayProbePhase = .weaponWait
                gameplayProbeFrames = 0
            }

        case .weaponWait:
            if gameplayProbeFrames >= 180 {
                print(
                    "[GoldenPad] Gameplay probe weapon: " +
                    "\(weapon != gameplayProbeInitialWeapon ? "PASS" : "FAIL") " +
                    "weapon=\(gameplayProbeInitialWeapon)->\(weapon)"
                )
                gameplayProbePhase = .pausePulse
                gameplayProbeFrames = 0
            }

        case .pausePulse:
            touch.buttons = [.pause]
            if gameplayProbeFrames >= 6 {
                gameplayProbePhase = .pauseWait
                gameplayProbeFrames = 0
            }

        case .pauseWait:
            if gameplayProbeFrames >= 180 || gameplayProbeSawPause {
                print(
                    "[GoldenPad] Gameplay probe pause: " +
                    "\(gameplayProbeSawPause ? "PASS" : "FAIL") " +
                    "watch=\(watchState) outside=\(outsideWatch) pausing=\(pausing)"
                )
                gameplayProbePhase = .complete
                gameplayProbeFrames = 0
            }

        case .complete:
            break
        }
    }

    private func runMissionFlowProbeIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("--mission-flow-probe") else {
            return
        }

        var menu: Int32 = -1
        var stage: Int32 = -1
        var pendingStage: Int32 = -1
        var ready: Int32 = 0
        var viewMode: Int32 = -1
        var progressionReady: Int32 = 0
        var completed: Int32 = 0
        var bestTime: Int32 = 0
        var missionState: Int32 = -1
        var scriptedSuccessApplied: Int32 = 0
        goldenPadMGB64RuntimeState(
            &menu, &stage, &pendingStage, nil, nil, nil, nil
        )
        goldenPadMGB64GameplayState(
            &ready, &viewMode, nil, nil, nil, nil, nil, nil, nil,
            nil, nil, nil, nil
        )
        goldenPadMGB64ProgressionState(
            &progressionReady, &completed, &bestTime, &missionState,
            &scriptedSuccessApplied
        )

        missionFlowProbeFrames += 1

        switch missionFlowProbePhase {
        case .waitingForDam:
            guard stage == 33, ready == 1, viewMode == 0 else { return }
            missionFlowProbePhase = .settle
            missionFlowProbeFrames = 0
            print("[GoldenPad] Mission flow probe live Dam: PASS")

        case .settle:
            guard missionFlowProbeFrames >= 90 else { return }
            goldenPadMGB64RequestScriptedMissionSuccess()
            missionFlowProbePhase = .waitingForStatus
            missionFlowProbeFrames = 0
            print("[GoldenPad] Mission flow probe scripted success requested")

        case .waitingForStatus:
            guard menu == 12, stage == 90, progressionReady == 1,
                  completed == 1, bestTime > 0,
                  scriptedSuccessApplied == 1 else { return }
            missionFlowProbePhase = .statusSettle
            missionFlowProbeFrames = 0
            print(
                "[GoldenPad] Mission flow probe real status/save: PASS " +
                "menu=\(menu) stage=\(stage) completed=\(completed) " +
                "time=\(bestTime) scripted=\(scriptedSuccessApplied)"
            )

        case .statusSettle:
            guard missionFlowProbeFrames >= 60 else { return }
            missionFlowProbePhase = .advanceStatus
            missionFlowProbeFrames = 0

        case .advanceStatus:
            touch.buttons = [.confirm]
            if missionFlowProbeFrames >= 6 {
                missionFlowProbePhase = .waitingForReport
                missionFlowProbeFrames = 0
            }

        case .waitingForReport:
            guard menu == 13, completed == 1, bestTime > 0 else { return }
            missionFlowProbePhase = .reportSettle
            missionFlowProbeFrames = 0
            print(
                "[GoldenPad] Mission flow probe real statistics report: PASS " +
                "menu=\(menu) stage=\(stage) completed=\(completed) " +
                "time=\(bestTime) scripted=\(scriptedSuccessApplied)"
            )

        case .reportSettle:
            guard missionFlowProbeFrames >= 60 else { return }
            missionFlowProbePhase = .dismissReport
            missionFlowProbeFrames = 0

        case .dismissReport:
            touch.buttons = [.cancel]
            if missionFlowProbeFrames >= 6 {
                missionFlowProbePhase = .waitingForMissionSelect
                missionFlowProbeFrames = 0
            }

        case .waitingForMissionSelect:
            guard menu == 7, completed == 1, bestTime > 0 else { return }
            missionFlowProbePhase = .complete
            missionFlowProbeFrames = 0
            print(
                "[GoldenPad] Mission flow probe report navigation: PASS " +
                "menu=\(menu) completed=\(completed) time=\(bestTime) " +
                "mission=\(missionState)"
            )

        case .complete:
            break
        }
    }

    private func runFacilityDoorProbeIfRequested() {
        let isDoorChainProbe = ProcessInfo.processInfo.arguments.contains(
            "--facility-door-chain-probe"
        )
        let resultLabel = isDoorChainProbe
            ? "Facility door chain probe"
            : "Facility door probe"
        guard isDoorChainProbe ||
                ProcessInfo.processInfo.arguments.contains("--facility-door-probe") else {
            return
        }

        var menu: Int32 = -1
        var stage: Int32 = -1
        var selectedStage: Int32 = -1
        var ready: Int32 = 0
        var viewMode: Int32 = -1
        var playerX: Int32 = 0
        var playerZ: Int32 = 0
        var playerYaw: Int32 = 0
        var playerPitch: Int32 = 0
        var doorReady: Int32 = 0
        var doorCount: Int32 = 0
        var doorState: Int32 = -1
        var doorOpenPosition: Int32 = 0
        var doorMaxOpenPosition: Int32 = 0
        var doorSawOpening: Int32 = 0
        var doorFinishedOpen: Int32 = 0
        var door155Count: Int32 = 0
        var door155State: Int32 = -1
        var door155OpenPosition: Int32 = 0
        var door155MaxOpenPosition: Int32 = 0
        var door155SawOpening: Int32 = 0
        var door155FinishedOpen: Int32 = 0
        var cameraMode: Int32 = -1
        goldenPadMGB64RuntimeState(
            &menu, &stage, nil, &selectedStage, nil, nil, nil
        )
        goldenPadMGB64GameplayState(
            &ready, &viewMode, &playerX, &playerZ, &playerYaw, &playerPitch,
            nil, nil, nil,
            nil, nil, nil, nil
        )
        goldenPadMGB64FacilityDoorState(
            &doorReady, &doorCount, &doorState, &doorOpenPosition,
            &doorMaxOpenPosition, &doorSawOpening, &doorFinishedOpen,
            &cameraMode
        )
        goldenPadMGB64FacilityDoor155State(
            &door155Count, &door155State, &door155OpenPosition,
            &door155MaxOpenPosition, &door155SawOpening,
            &door155FinishedOpen
        )

        facilityDoorRouteInput = nil
        facilityDoorProbeFrames += 1

        switch facilityDoorProbePhase {
        case .waitingForDam:
            guard stage == 33, ready == 1, viewMode == 0 else { return }
            touch = .neutral
            facilityDoorProbePhase = .damSettle
            facilityDoorProbeFrames = 0
            print("[GoldenPad] Facility door probe live Dam setup: PASS")

        case .damSettle:
            touch = .neutral
            guard facilityDoorProbeFrames >= 90 else { return }
            goldenPadMGB64RequestScriptedMissionSuccess()
            facilityDoorProbePhase = .waitingForStatus
            facilityDoorProbeFrames = 0
            print("[GoldenPad] Facility door probe scripted Dam prerequisite requested")

        case .waitingForStatus:
            touch = .neutral
            guard menu == 12, stage == 90 else { return }
            facilityDoorProbePhase = .statusSettle
            facilityDoorProbeFrames = 0

        case .statusSettle:
            touch = .neutral
            guard facilityDoorProbeFrames >= 60 else { return }
            facilityDoorProbePhase = .advanceStatus
            facilityDoorProbeFrames = 0

        case .advanceStatus:
            touch = .neutral
            touch.buttons = [.confirm]
            if facilityDoorProbeFrames >= 6 {
                facilityDoorProbePhase = .waitingForReport
                facilityDoorProbeFrames = 0
            }

        case .waitingForReport:
            touch = .neutral
            guard menu == 13 else { return }
            facilityDoorProbePhase = .reportSettle
            facilityDoorProbeFrames = 0

        case .reportSettle:
            touch = .neutral
            guard facilityDoorProbeFrames >= 60 else { return }
            facilityDoorProbePhase = .advanceReport
            facilityDoorProbeFrames = 0

        case .advanceReport:
            touch = .neutral
            touch.buttons = [.confirm]
            if facilityDoorProbeFrames >= 6 {
                facilityDoorProbePhase = .waitingForBriefing
                facilityDoorProbeFrames = 0
            }

        case .waitingForBriefing:
            touch = .neutral
            guard menu == 10, stage == 90, selectedStage == 34 else { return }
            facilityDoorProbePhase = .briefingSettle
            facilityDoorProbeFrames = 0
            print("[GoldenPad] Facility door probe authentic next briefing: PASS")

        case .briefingSettle:
            touch = .neutral
            guard facilityDoorProbeFrames >= 60 else { return }
            facilityDoorProbePhase = .startFacility
            facilityDoorProbeFrames = 0

        case .startFacility:
            touch = .neutral
            touch.buttons = [.pause]
            if facilityDoorProbeFrames >= 6 {
                facilityDoorProbePhase = .waitingForFacility
                facilityDoorProbeFrames = 0
            }

        case .waitingForFacility:
            touch = .neutral
            guard stage == 34, ready == 1, viewMode == 0, doorReady == 1,
                  cameraMode == 4 else {
                return
            }
            facilityDoorRouteStartX = playerX
            facilityDoorRouteStartZ = playerZ
            facilityDoorRouteStartYaw = playerYaw
            facilityDoorRouteFrame = 0
            facilityDoorProbePhase = .route
            facilityDoorProbeFrames = 0
            print(
                "[GoldenPad] Facility door probe stock spawn: PASS " +
                "doors=\(doorCount) pos=\(playerX),\(playerZ) " +
                "yaw=\(playerYaw) pitch=\(playerPitch) camera=\(cameraMode)"
            )

        case .route:
            touch = .neutral
            var routeFrame = GoldenEyeInputFrame()
            if (80..<700).contains(facilityDoorRouteFrame) {
                routeFrame.primary.stick = SIMD2(-1, 1)
            }
            if (350..<610).contains(facilityDoorRouteFrame) {
                routeFrame.secondary.stick = SIMD2(-1, 0)
            }
            if isDoorChainProbe && (700..<740).contains(facilityDoorRouteFrame) {
                routeFrame.primary.stick = SIMD2(0, -1)
            }
            if isDoorChainProbe && (740..<960).contains(facilityDoorRouteFrame) {
                routeFrame.secondary.stick = SIMD2(-1, 0)
            }
            if [400, 440, 480, 520, 560, 600].contains(where: {
                ($0..<($0 + 4)).contains(facilityDoorRouteFrame)
            }) {
                routeFrame.primary.buttons.insert(.b)
            }
            if isDoorChainProbe && stride(from: 740, through: 956, by: 8).contains(where: {
                ($0..<($0 + 4)).contains(facilityDoorRouteFrame)
            }) {
                routeFrame.primary.buttons.insert(.b)
            }
            facilityDoorRouteInput = routeFrame
            facilityDoorRouteFrame += 1

            if [100, 180, 360, 440, 600, 740, 760, 800, 920, 1060, 1240, 1380].contains(
                facilityDoorRouteFrame
            ) {
                let deltaX = playerX - facilityDoorRouteStartX
                let deltaZ = playerZ - facilityDoorRouteStartZ
                print(
                    "[GoldenPad] Facility door probe route frame " +
                    "\(facilityDoorRouteFrame): pos=\(playerX),\(playerZ) " +
                    "delta=\(deltaX),\(deltaZ) yaw=\(playerYaw) " +
                    "yawDelta=\(playerYaw - facilityDoorRouteStartYaw)"
                )
            }

            let finalRouteFrame = isDoorChainProbe ? 1400 : 760
            guard facilityDoorRouteFrame >= finalRouteFrame else { return }
            let deltaX = Double(playerX - facilityDoorRouteStartX)
            let deltaZ = Double(playerZ - facilityDoorRouteStartZ)
            let distance = Int(sqrt(deltaX * deltaX + deltaZ * deltaZ).rounded())
            let firstDoorPassed = doorReady == 1 && doorSawOpening == 1 &&
                doorFinishedOpen == 1 && doorMaxOpenPosition > 0 &&
                distance >= 68_000
            let secondDoorPassed = !isDoorChainProbe ||
                (door155Count > 0 && door155SawOpening == 1 &&
                 door155FinishedOpen == 1 && door155MaxOpenPosition > 0)
            let passed = firstDoorPassed && secondDoorPassed
            facilityDoorProbePhase = .complete
            facilityDoorRouteInput = nil
            touch = .neutral
            print(
                "[GoldenPad] \(resultLabel) controller interaction: " +
                "\(passed ? "PASS" : "FAIL") doors=\(doorCount) " +
                "state=\(doorState) open=\(doorOpenPosition) " +
                "max=\(doorMaxOpenPosition) sawOpening=\(doorSawOpening) " +
                "finishedOpen=\(doorFinishedOpen) distance=\(distance / 100) " +
                "door155Count=\(door155Count) door155State=\(door155State) " +
                "door155Open=\(door155OpenPosition) " +
                "door155Max=\(door155MaxOpenPosition) " +
                "door155SawOpening=\(door155SawOpening) " +
                "door155FinishedOpen=\(door155FinishedOpen) " +
                "final=\(playerX),\(playerZ) yaw=\(playerYaw)"
            )

        case .complete:
            touch = .neutral
        }
    }

    private func runProgressionProbeIfRequested() {
        guard !didReportProgressionProbe,
              ProcessInfo.processInfo.arguments.contains("--progression-probe") else {
            return
        }
        var ready: Int32 = 0
        var completed: Int32 = 0
        var bestTime: Int32 = 0
        var missionState: Int32 = -1
        var menu: Int32 = -1
        goldenPadMGB64RuntimeState(
            &menu, nil, nil, nil, nil, nil, nil
        )
        goldenPadMGB64ProgressionState(
            &ready, &completed, &bestTime, &missionState, nil
        )
        // GoldenEye loads and validates EEPROM in the legal-screen initializer.
        // An earlier game-thread sample sees the static blank save array, so do
        // not declare a relaunch result until that authentic initializer ran.
        guard menu == 0, ready == 1 else { return }
        didReportProgressionProbe = true
        print(
            "[GoldenPad] Progression relaunch probe: " +
            "\(completed == 1 && bestTime > 0 ? "PASS" : "FAIL") " +
            "Dam/Agent completed=\(completed) time=\(bestTime) " +
            "mission=\(missionState)"
        )
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
        print(
            "[GoldenPad] Controller slot \(slot + 1): " +
            "\(controller.vendorName ?? "unknown") | \(controller.productCategory) | " +
            "attached=\(controller.isAttachedToDevice)"
        )
        updateControllerCounts()
        refreshSummary()
    }

    private func remove(_ controller: GCController) {
        guard let slot = controllerSlots.firstIndex(where: { $0 === controller }) else { return }
        controller.playerIndex = .indexUnset
        controllerSlots[slot] = nil
        updateControllerCounts()
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

    private func updateControllerCounts() {
        let controllers = controllerSlots.compactMap { $0 }
        connectedControllerCount = controllers.count
        externalControllerCount = controllers.filter(isExternalController).count
    }

    private func isExternalController(_ controller: GCController) -> Bool {
#if targetEnvironment(simulator)
        if controller.vendorName == "Gamepad", controller.productCategory == "MFi" {
            return false
        }
#endif
        return true
    }

    private func configureMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        motionLook = .zero
        guard settings.gyroEnabled, motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            Task { @MainActor in
                self?.motionLook = SIMD2(
                    Float(motion.rotationRate.y) * 0.12,
                    Float(-motion.rotationRate.x) * 0.12
                ).clampedUnitSquare()
                self?.refreshSummary()
            }
        }
    }

    private func refreshSummary() {
        let current = snapshot(player: 0)
        let mapped = GoldenEyeInputMapper.map(current, preset: currentPreset)
        let actions = current.buttons.isEmpty ? "none" : "0x\(String(current.buttons.rawValue, radix: 16))"
        let activity = String(
            format: "input: move %.2f %.2f • look %.2f %.2f • actions %@ • N64 0x%04x • %@ • controllers: %d",
            current.movement.x,
            current.movement.y,
            current.look.x,
            current.look.y,
            actions,
            mapped.primary.buttons.rawValue,
            currentPreset.rawValue,
            connectedControllerCount
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

    func applyingRadialDeadZone(_ deadZone: Float) -> SIMD2<Float> {
        let magnitude = sqrt(x * x + y * y)
        guard magnitude > deadZone, magnitude > 0 else { return .zero }
        let scaled = Swift.min((magnitude - deadZone) / Swift.max(1 - deadZone, 0.001), 1)
        return self / magnitude * scaled
    }
}
