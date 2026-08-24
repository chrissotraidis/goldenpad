struct RecompN64Button {
    static let a: UInt16 = 0x8000
    static let b: UInt16 = 0x4000
    static let z: UInt16 = 0x2000
    static let start: UInt16 = 0x1000
    static let dpadUp: UInt16 = 0x0800
    static let dpadDown: UInt16 = 0x0400
    static let dpadLeft: UInt16 = 0x0200
    static let dpadRight: UInt16 = 0x0100
    static let r: UInt16 = 0x0010
    static let cUp: UInt16 = 0x0008
    static let cDown: UInt16 = 0x0004
    static let cLeft: UInt16 = 0x0002
    static let cRight: UInt16 = 0x0001
}

struct RecompRuntimeInputContext: Equatable {
    /// -1 means Bond is not mounted. GoldenEye's native tank run states are
    /// 0 entering, 1 starting, and 2 running.
    var gameplayActive: Bool
    var runtimeStyle: Int32
    var aiming: Bool
    var tankState: Int32
    var nativeLookUpright: Bool

    var isInTank: Bool { tankState >= 0 }
    var isTankRunning: Bool { tankState == 2 }
}

struct RecompMovementMapping: Equatable {
    var buttons: UInt16
    var stick: SIMD2<Float>
}

/// Translates GoldenPad's semantic actions into GoldenEye's active 1.x layout.
/// The same table is compiled into the Mac, iPhone, and iPad hosts.
struct RecompControlMapping {
    let runtimeStyle: Int32

    private var usesKissyButtons: Bool {
        runtimeStyle == 2 || runtimeStyle == 3
    }

    var usesDigitalMovement: Bool {
        runtimeStyle == 1 || runtimeStyle == 3
    }

    var fireButton: UInt16 {
        usesKissyButtons ? RecompN64Button.a : RecompN64Button.z
    }

    var aimButton: UInt16 {
        usesKissyButtons ? RecompN64Button.z : RecompN64Button.r
    }

    var weaponButton: UInt16 {
        usesKissyButtons ? RecompN64Button.r : RecompN64Button.a
    }

    func gameplayButtons(
        fire: Bool,
        aim: Bool,
        action: Bool,
        weapon: Bool,
        start: Bool
    ) -> UInt16 {
        var buttons: UInt16 = 0
        if fire { buttons |= fireButton }
        if aim { buttons |= aimButton }
        if action { buttons |= RecompN64Button.b }
        if weapon { buttons |= weaponButton }
        if start { buttons |= RecompN64Button.start }
        return buttons
    }

    func movement(
        buttons: UInt16,
        stick: SIMD2<Float>,
        modern: Bool,
        context: RecompRuntimeInputContext,
        threshold: Float = 0.30
    ) -> RecompMovementMapping {
        guard modern, context.gameplayActive else {
            return RecompMovementMapping(buttons: buttons, stick: stick)
        }

        // Modern Aim owns both look axes. Never synthesize GoldenEye's C-button
        // lean/step controls from the movement stick while the real game state is
        // aiming. Likewise, leave the original tank entry animation undisturbed.
        if context.aiming || (context.isInTank && !context.isTankRunning) {
            return RecompMovementMapping(buttons: buttons, stick: .zero)
        }

        if context.isInTank {
            if usesDigitalMovement {
                return RecompMovementMapping(
                    buttons: buttons | directionalCButtons(for: stick, threshold: threshold),
                    stick: .zero
                )
            }
            // Honey/Kissy use native analog Y for drive and analog X for hull
            // steering. Do not synthesize C-left/right here; those turn the turret.
            return RecompMovementMapping(buttons: buttons, stick: stick)
        }

        if usesDigitalMovement {
            // Solitaire/Goodnight define all four C directions as movement.
            return RecompMovementMapping(
                buttons: buttons | directionalCButtons(for: stick, threshold: threshold),
                stick: .zero
            )
        }

        // Honey/Kissy keep analog Y for walking while modern horizontal movement
        // becomes the native C-button sidestep pair.
        var mappedButtons = buttons
        if stick.x < -threshold { mappedButtons |= RecompN64Button.cLeft }
        if stick.x > threshold { mappedButtons |= RecompN64Button.cRight }
        return RecompMovementMapping(buttons: mappedButtons, stick: SIMD2(0, stick.y))
    }

    /// Converts the external left stick into GoldenEye's original manual-sight
    /// stick while aiming on foot. The game applies its Reverse/Upright option
    /// after reading this value, so compensate for that live option first and
    /// let GoldenPad's host setting provide the final user-facing polarity.
    func manualAimStick(
        stick: SIMD2<Float>,
        invertVertical: Bool,
        context: RecompRuntimeInputContext
    ) -> SIMD2<Float>? {
        guard context.gameplayActive, context.aiming, !context.isInTank else {
            return nil
        }

        var rawY = context.nativeLookUpright ? stick.y : -stick.y
        if invertVertical { rawY = -rawY }
        return SIMD2(stick.x, rawY)
    }

    func mouseCameraAimHoldActive(
        context: RecompRuntimeInputContext
    ) -> Bool {
        context.gameplayActive && context.aiming && !context.isInTank
    }

    static func menuNavigationButtons(
        up: Bool,
        down: Bool,
        left: Bool,
        right: Bool
    ) -> UInt16 {
        var buttons: UInt16 = 0
        if up { buttons |= RecompN64Button.dpadUp }
        if down { buttons |= RecompN64Button.dpadDown }
        if left { buttons |= RecompN64Button.dpadLeft }
        if right { buttons |= RecompN64Button.dpadRight }
        return buttons
    }

    private func directionalCButtons(
        for stick: SIMD2<Float>,
        threshold: Float
    ) -> UInt16 {
        var buttons: UInt16 = 0
        if stick.y > threshold { buttons |= RecompN64Button.cUp }
        if stick.y < -threshold { buttons |= RecompN64Button.cDown }
        if stick.x < -threshold { buttons |= RecompN64Button.cLeft }
        if stick.x > threshold { buttons |= RecompN64Button.cRight }
        return buttons
    }
}

/// GoldenEye's watch control-style list advances once per frame at full analog
/// deflection. Publish one digital edge, then require neutral before another step.
struct RecompMenuStickLatch {
    private(set) var armed = true
    private var pulseButton: UInt16 = 0
    private var pulseFramesRemaining = 0

    mutating func buttons(for stick: SIMD2<Float>) -> UInt16 {
        let neutralThreshold: Float = 0.20
        let activationThreshold: Float = 0.50
        let absX = abs(stick.x)
        let absY = abs(stick.y)

        // Keep the edge visible for two host publications so GoldenEye cannot
        // miss it between game polls. Because the button never returns to zero
        // between these frames, native PressedThisFrame still advances once.
        if pulseFramesRemaining > 0 {
            pulseFramesRemaining -= 1
            return pulseButton
        }

        if absX <= neutralThreshold && absY <= neutralThreshold {
            armed = true
            pulseButton = 0
            return 0
        }
        guard armed, max(absX, absY) >= activationThreshold else { return 0 }
        armed = false

        pulseButton = absX > absY
            ? (stick.x < 0 ? RecompN64Button.dpadLeft : RecompN64Button.dpadRight)
            : (stick.y < 0 ? RecompN64Button.dpadDown : RecompN64Button.dpadUp)
        pulseFramesRemaining = 1
        return pulseButton
    }

    mutating func navigation(
        for stick: SIMD2<Float>,
        frontEndActive: Bool
    ) -> RecompMovementMapping {
        if frontEndActive {
            reset()
            return RecompMovementMapping(buttons: 0, stick: stick)
        }
        return RecompMovementMapping(buttons: buttons(for: stick), stick: .zero)
    }

    mutating func reset() {
        armed = true
        pulseButton = 0
        pulseFramesRemaining = 0
    }
}
