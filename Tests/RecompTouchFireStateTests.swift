@main
struct RecompTouchFireStateTests {
    static func main() {
        var state = RecompTouchFireState()
        expect(!state.isPressed, "Fire starts released")

        state.setPressed(true, source: .primary)
        expect(state.isPressed, "Primary Fire presses Z")

        state.setPressed(true, source: .secondary)
        state.setPressed(false, source: .primary)
        expect(state.isPressed, "Releasing primary Fire preserves held secondary Fire")

        state.setPressed(false, source: .secondary)
        expect(!state.isPressed, "Fire releases after both touch sources release")

        state.setPressed(true, source: .secondary)
        state.reset()
        expect(!state.isPressed, "Input reset releases every Fire source")

        print("PASS: primary and optional secondary touch Fire aggregate safely")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            fatalError("FAIL: \(message)")
        }
    }
}
