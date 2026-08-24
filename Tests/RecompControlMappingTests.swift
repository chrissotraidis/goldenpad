import simd

private struct MappingTestFailure: Error, CustomStringConvertible {
    let description: String
}

private func expect<T: Equatable>(_ actual: T, _ expected: T, _ description: String) throws {
    guard actual == expected else {
        throw MappingTestFailure(
            description: "\(description): expected \(expected), got \(actual)"
        )
    }
}

private func context(
    gameplay: Bool = true,
    style: Int32,
    aiming: Bool = false,
    tankState: Int32 = -1,
    nativeLookUpright: Bool = false
) -> RecompRuntimeInputContext {
    RecompRuntimeInputContext(
        gameplayActive: gameplay,
        runtimeStyle: style,
        aiming: aiming,
        tankState: tankState,
        nativeLookUpright: nativeLookUpright
    )
}

private func verifyStyle(
    _ style: Int32,
    fire: UInt16,
    aim: UInt16,
    weapon: UInt16,
    digitalMovement: Bool
) throws {
    let mapping = RecompControlMapping(runtimeStyle: style)
    try expect(mapping.fireButton, fire, "style \(style) fire")
    try expect(mapping.aimButton, aim, "style \(style) aim")
    try expect(mapping.weaponButton, weapon, "style \(style) weapon")
    try expect(mapping.usesDigitalMovement, digitalMovement, "style \(style) movement family")
    try expect(
        mapping.gameplayButtons(
            fire: true, aim: true, action: true, weapon: true, start: true),
        fire | aim | weapon | RecompN64Button.b | RecompN64Button.start,
        "style \(style) semantic chord"
    )
}

@main
private struct RecompControlMappingTests {
    static func main() throws {
        try verifyStyle(
            0, fire: RecompN64Button.z, aim: RecompN64Button.r,
            weapon: RecompN64Button.a, digitalMovement: false)
        try verifyStyle(
            1, fire: RecompN64Button.z, aim: RecompN64Button.r,
            weapon: RecompN64Button.a, digitalMovement: true)
        try verifyStyle(
            2, fire: RecompN64Button.a, aim: RecompN64Button.z,
            weapon: RecompN64Button.r, digitalMovement: false)
        try verifyStyle(
            3, fire: RecompN64Button.a, aim: RecompN64Button.z,
            weapon: RecompN64Button.r, digitalMovement: true)

        let movement = SIMD2<Float>(0.75, 0.80)
        let honey = RecompControlMapping(runtimeStyle: 0)
        let solitaire = RecompControlMapping(runtimeStyle: 1)

        try expect(
            honey.movement(buttons: 0, stick: movement, modern: true, context: context(style: 0)),
            RecompMovementMapping(
                buttons: RecompN64Button.cRight,
                stick: SIMD2<Float>(0, 0.80)),
            "1.1 on foot uses analog Y and C-left/right sidestep"
        )
        try expect(
            solitaire.movement(buttons: 0, stick: movement, modern: true, context: context(style: 1)),
            RecompMovementMapping(
                buttons: RecompN64Button.cUp | RecompN64Button.cRight,
                stick: .zero),
            "1.2 on foot uses four C-button movement directions"
        )
        try expect(
            honey.movement(
                buttons: 0, stick: movement, modern: true,
                context: context(style: 0, tankState: 2)),
            RecompMovementMapping(buttons: 0, stick: movement),
            "1.1 running tank uses analog Y drive and analog X hull steering"
        )
        try expect(
            solitaire.movement(
                buttons: 0, stick: movement, modern: true,
                context: context(style: 1, tankState: 2)),
            RecompMovementMapping(
                buttons: RecompN64Button.cUp | RecompN64Button.cRight,
                stick: .zero),
            "1.2 running tank uses four C-button drive directions"
        )

        for style: Int32 in 0...3 {
            let mapping = RecompControlMapping(runtimeStyle: style)
            try expect(
                mapping.movement(
                    buttons: RecompN64Button.dpadUp,
                    stick: movement,
                    modern: true,
                    context: context(style: style, aiming: true, tankState: 2)),
                RecompMovementMapping(buttons: RecompN64Button.dpadUp, stick: .zero),
                "style \(style) aim suppresses synthesized movement"
            )
            for transitionState: Int32 in 0...1 {
                try expect(
                    mapping.movement(
                        buttons: 0,
                        stick: movement,
                        modern: true,
                        context: context(style: style, tankState: transitionState)),
                    RecompMovementMapping(buttons: 0, stick: .zero),
                    "style \(style) tank transition \(transitionState) stays neutral"
                )
            }
        }

        let rightUp = SIMD2<Float>(0.75, 0.80)
        try expect(
            honey.manualAimStick(
                stick: rightUp,
                invertVertical: false,
                context: context(style: 0, aiming: true, nativeLookUpright: false)),
            SIMD2<Float>(0.75, -0.80),
            "Reverse native option is compensated for non-inverted manual aim"
        )
        try expect(
            honey.manualAimStick(
                stick: rightUp,
                invertVertical: false,
                context: context(style: 0, aiming: true, nativeLookUpright: true)),
            rightUp,
            "Upright native option preserves non-inverted manual aim"
        )
        try expect(
            honey.manualAimStick(
                stick: rightUp,
                invertVertical: true,
                context: context(style: 0, aiming: true, nativeLookUpright: false)),
            rightUp,
            "GoldenPad inversion reverses the compensated manual-aim axis"
        )
        try expect(
            honey.manualAimStick(
                stick: rightUp,
                invertVertical: false,
                context: context(style: 0, aiming: false)),
            nil,
            "normal gameplay keeps right stick on the camera path"
        )
        try expect(
            honey.manualAimStick(
                stick: rightUp,
                invertVertical: false,
                context: context(style: 0, aiming: true, tankState: 2)),
            nil,
            "mounted Aim keeps right stick on the tank turret path"
        )
        try expect(
            honey.mouseCameraAimHoldActive(
                context: context(style: 0, aiming: true)),
            true,
            "on-foot Shift keeps relative mouse aim from recentering"
        )
        try expect(
            honey.mouseCameraAimHoldActive(
                context: context(style: 0, aiming: false)),
            false,
            "ordinary mouse look does not hold the aim camera"
        )
        try expect(
            honey.mouseCameraAimHoldActive(
                context: context(style: 0, aiming: true, tankState: 2)),
            false,
            "tank Aim remains on the turret path"
        )

        try expect(
            honey.movement(
                buttons: RecompN64Button.a,
                stick: movement,
                modern: false,
                context: context(style: 0, tankState: 2)),
            RecompMovementMapping(buttons: RecompN64Button.a, stick: movement),
            "classic C-button mode bypasses modern translation"
        )
        try expect(
            honey.movement(
                buttons: RecompN64Button.b,
                stick: movement,
                modern: true,
                context: context(gameplay: false, style: 0)),
            RecompMovementMapping(buttons: RecompN64Button.b, stick: movement),
            "menu mode bypasses gameplay movement translation"
        )

        var latch = RecompMenuStickLatch()
        try expect(latch.buttons(for: SIMD2<Float>(0, 1)), RecompN64Button.dpadUp, "menu first edge")
        try expect(latch.buttons(for: SIMD2<Float>(0, 1)), RecompN64Button.dpadUp, "menu edge spans two host publications")
        try expect(latch.buttons(for: SIMD2<Float>(0, 1)), 0, "held menu stick does not create a second edge")
        try expect(latch.buttons(for: SIMD2<Float>(0, 0.3)), 0, "partial release does not rearm")
        try expect(latch.buttons(for: .zero), 0, "neutral rearms without input")
        try expect(latch.buttons(for: SIMD2<Float>(-1, 0)), RecompN64Button.dpadLeft, "menu second edge")

        latch.reset()
        try expect(
            latch.navigation(for: SIMD2<Float>(-1, 0.75), frontEndActive: true),
            RecompMovementMapping(buttons: 0, stick: SIMD2<Float>(-1, 0.75)),
            "front end preserves Preview 3 analog cursor movement"
        )
        try expect(
            latch.navigation(for: SIMD2<Float>(0, 1), frontEndActive: false),
            RecompMovementMapping(buttons: RecompN64Button.dpadUp, stick: .zero),
            "watch converts movement to one digital edge"
        )

        print("PASS: shared GoldenEye 1.1-1.4 input and tank matrix")
    }
}
