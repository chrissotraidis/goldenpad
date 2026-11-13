@main
struct RecompTouchOwnershipTests {
    static func main() {
        let touchOnly = RecompInputOwnership.route(
            controllerPresent: false, twoPlayerRequested: false, autoHideTouch: true)
        expect(touchOnly == RecompInputOwnershipRoute(externalPort: nil, touchPort: 0, twoPlayerActive: false),
               "Without a controller touch is Player 1")

        let autoHidden = RecompInputOwnership.route(
            controllerPresent: true, twoPlayerRequested: false, autoHideTouch: true)
        expect(autoHidden == RecompInputOwnershipRoute(externalPort: 0, touchPort: nil, twoPlayerActive: false),
               "A controller hides touch while auto-hide is on")

        let shown = RecompInputOwnership.route(
            controllerPresent: true, twoPlayerRequested: false, autoHideTouch: false)
        expect(shown == RecompInputOwnershipRoute(externalPort: 0, touchPort: 0, twoPlayerActive: false),
               "Show keeps touch on Player 1 beside the controller without the two-player test")

        let twoPlayer = RecompInputOwnership.route(
            controllerPresent: true, twoPlayerRequested: true, autoHideTouch: false)
        expect(twoPlayer == RecompInputOwnershipRoute(externalPort: 0, touchPort: 1, twoPlayerActive: true),
               "Only the two-player test moves touch to Player 2")
        expect(RecompInputOwnership.route(
                   controllerPresent: true, twoPlayerRequested: true, autoHideTouch: true) == twoPlayer,
               "Auto-hide does not change the two-player test")

        expect(RecompInputOwnership.route(
                   controllerPresent: false, twoPlayerRequested: false, autoHideTouch: false) == touchOnly,
               "Disconnecting the controller returns touch to Player 1 either way")

        let merged = RecompInputOwnership.sharedPort(
            external: (0x8000, SIMD2(0.2, 0)), touch: (0x2000, SIMD2(0, -0.9)))
        expect(merged.buttons == 0xA000, "Shared Player 1 combines controller and touch buttons")
        expect(merged.stick == SIMD2(0, -0.9), "The stick pushed further wins")
        let idleTouch = RecompInputOwnership.sharedPort(
            external: (0x0010, SIMD2(0.5, 0.5)), touch: (0, .zero))
        expect(idleTouch.buttons == 0x0010 && idleTouch.stick == SIMD2(0.5, 0.5),
               "Idle touch leaves the controller's input untouched")

        print("PASS: touch ownership follows the controller, auto-hide and the two-player test")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fatalError("FAIL: \(message)") }
    }
}
