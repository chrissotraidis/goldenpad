import Foundation

@main
struct LANNetplayProtocolProbe {
    static func main() throws {
        let playerOne = LANNetplayParticipant(
            id: "host", name: "iPad", slot: 0, ready: true, connected: true)
        let playerTwo = LANNetplayParticipant(
            id: "guest", name: "iPhone", slot: 1, ready: true, connected: true)
        let message = LANNetplayMessage(
            kind: .start,
            senderID: playerOne.id,
            roomID: "room",
            participants: [playerOne, playerTwo],
            assignedSlot: 1,
            roomSeed: 0xD872_B41C,
            frame: 1)
        let encoded = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(LANNetplayMessage.self, from: encoded)
        precondition(decoded == message)
        precondition(decoded.isCompatible)

        var wrongVersion = decoded
        wrongVersion.version += 1
        precondition(!wrongVersion.isCompatible)

        let p1 = LANNetplayInput(buttons: 0x1000, stickY: 64)
        let p2 = LANNetplayInput(buttons: 0x2000, stickX: -32)
        let ordered = [p1, p2, .neutral, .neutral]
        var buffer = LANNetplayOrderedBuffer()
        try buffer.insert(frame: 2, inputs: ordered)
        do {
            _ = try buffer.consumeNext()
            preconditionFailure("A missing authoritative frame must fault")
        } catch LANNetplayOrderedBuffer.BufferError.missingFrame(1) {
            // Expected: never silently advance past a missing source-of-truth frame.
        }
        try buffer.insert(frame: 1, inputs: ordered)
        let first = try buffer.consumeNext()
        let second = try buffer.consumeNext()
        precondition(first.0 == 1 && second.0 == 2)
        precondition(first.1 == ordered && second.1 == ordered)
        precondition(first.1[2] == .neutral && first.1[3] == .neutral)
        let wire = try XCTUnwrap(LANNetplayInputWire.encode(ordered))
        precondition(wire.count == 64)
        precondition(LANNetplayInputWire.decode(wire) == ordered)

        print("LAN netplay protocol probe: PASS")
    }

    private static func XCTUnwrap<T>(_ value: T?) throws -> T {
        guard let value else {
            throw CocoaError(.coderInvalidValue)
        }
        return value
    }
}
