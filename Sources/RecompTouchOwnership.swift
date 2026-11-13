// Which N64 player port each local input owns on iPhone and iPad.
//
// The external controller is always Player 1. Touch is Player 1 when no
// controller is connected. With a controller, touch gives way while auto-hide
// is on; with auto-hide off (Show Touch Controls) it stays on Player 1 beside
// the controller, and only the two-player input test moves it to Player 2.
struct RecompInputOwnershipRoute: Equatable {
    var externalPort: Int32?
    var touchPort: Int32?
    var twoPlayerActive: Bool
}

enum RecompInputOwnership {
    static func route(
        controllerPresent: Bool,
        twoPlayerRequested: Bool,
        autoHideTouch: Bool
    ) -> RecompInputOwnershipRoute {
        if controllerPresent {
            if twoPlayerRequested {
                return RecompInputOwnershipRoute(
                    externalPort: 0, touchPort: 1, twoPlayerActive: true)
            }
            return RecompInputOwnershipRoute(
                externalPort: 0, touchPort: autoHideTouch ? nil : 0, twoPlayerActive: false)
        }
        return RecompInputOwnershipRoute(
            externalPort: nil,
            touchPort: twoPlayerRequested ? nil : 0,
            twoPlayerActive: false
        )
    }

    /// Controller and touch on the same port: buttons combine and the stick
    /// pushed further wins, so neither input cancels the other.
    static func sharedPort(
        external: (buttons: UInt16, stick: SIMD2<Float>),
        touch: (buttons: UInt16, stick: SIMD2<Float>)
    ) -> (buttons: UInt16, stick: SIMD2<Float>) {
        let externalLength = (external.stick * external.stick).sum()
        let touchLength = (touch.stick * touch.stick).sum()
        return (
            external.buttons | touch.buttons,
            touchLength > externalLength ? touch.stick : external.stick
        )
    }
}
