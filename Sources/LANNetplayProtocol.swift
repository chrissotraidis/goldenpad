import Foundation

enum LANNetplayProtocol {
    static let version = 3
    static let compatibility = "goldenpad-ge-us-netplay-lab-v3"
    static let serviceType = "gpad-netplay"
    static let inputDelayFrames: UInt64 = 3
    static let maximumPlayers = 4
}

enum LANNetplayPacing {
    // Frame N can be consumed only after N + inputDelayFrames has arrived.
    // Keep exactly that look-ahead plus the frame being consumed; producing
    // farther ahead only increases latency and can overwrite the native ring.
    static let maximumLeadFrames = LANNetplayProtocol.inputDelayFrames + 1

    static func canProduce(nextFrame: UInt64, consumedFrame: UInt64) -> Bool {
        nextFrame <= consumedFrame + maximumLeadFrames
    }

    static func inputFrame(afterOrderedFrame frame: UInt64) -> UInt64 {
        frame + maximumLeadFrames
    }
}

struct LANNetplayInput: Codable, Equatable, Sendable {
    var buttons: UInt16 = 0
    var stickX: Int16 = 0
    var stickY: Int16 = 0
    var lookX: Int16 = 0
    var lookY: Int16 = 0
    var touchLookX: Int16 = 0
    var touchLookY: Int16 = 0
    var crouchSequence: UInt16 = 0

    static let neutral = LANNetplayInput()
}

struct LANNetplayParticipant: Codable, Equatable, Identifiable, Sendable {
    let id: String
    var name: String
    var slot: Int
    var ready: Bool
    var connected: Bool
}

struct LANNetplayMessage: Codable, Equatable, Sendable {
    enum Kind: String, Codable, Sendable {
        case hello
        case roster
        case ready
        case start
        case runtimeReady
        case go
        case input
        case orderedFrame
        case checksum
        case fault
    }

    var version = LANNetplayProtocol.version
    var compatibility = LANNetplayProtocol.compatibility
    var kind: Kind
    var senderID: String
    var senderName: String? = nil
    var roomID: String? = nil
    var participants: [LANNetplayParticipant]? = nil
    var ready: Bool? = nil
    var assignedSlot: Int? = nil
    var roomSeed: UInt64? = nil
    var frame: UInt64? = nil
    var inputs: [LANNetplayInput]? = nil
    var input: LANNetplayInput? = nil
    var checksum: UInt64? = nil
    var detail: String? = nil

    var isCompatible: Bool {
        version == LANNetplayProtocol.version &&
            compatibility == LANNetplayProtocol.compatibility
    }
}

struct LANNetplayOrderedBuffer {
    enum BufferError: Error, Equatable {
        case invalidPortCount
        case duplicateFrame
        case staleFrame
        case missingFrame(UInt64)
    }

    private(set) var nextFrame: UInt64 = 1
    private var frames: [UInt64: [LANNetplayInput]] = [:]

    mutating func reset(startingAt frame: UInt64 = 1) {
        nextFrame = frame
        frames.removeAll(keepingCapacity: true)
    }

    mutating func insert(frame: UInt64, inputs: [LANNetplayInput]) throws {
        guard inputs.count == LANNetplayProtocol.maximumPlayers else {
            throw BufferError.invalidPortCount
        }
        guard frame >= nextFrame else { throw BufferError.staleFrame }
        guard frames[frame] == nil else { throw BufferError.duplicateFrame }
        frames[frame] = inputs
    }

    mutating func consumeNext() throws -> (UInt64, [LANNetplayInput]) {
        guard let inputs = frames.removeValue(forKey: nextFrame) else {
            throw BufferError.missingFrame(nextFrame)
        }
        let consumed = nextFrame
        nextFrame += 1
        return (consumed, inputs)
    }
}

enum LANNetplayInputWire {
    static let bytesPerPort = 16

    static func encode(_ inputs: [LANNetplayInput]) -> Data? {
        guard inputs.count == LANNetplayProtocol.maximumPlayers else { return nil }
        var data = Data(capacity: bytesPerPort * inputs.count)
        for input in inputs {
            append(input.buttons, to: &data)
            append(UInt16(bitPattern: input.stickX), to: &data)
            append(UInt16(bitPattern: input.stickY), to: &data)
            append(UInt16(bitPattern: input.lookX), to: &data)
            append(UInt16(bitPattern: input.lookY), to: &data)
            append(UInt16(bitPattern: input.touchLookX), to: &data)
            append(UInt16(bitPattern: input.touchLookY), to: &data)
            append(input.crouchSequence, to: &data)
        }
        return data
    }

    static func decode(_ data: Data) -> [LANNetplayInput]? {
        guard data.count == bytesPerPort * LANNetplayProtocol.maximumPlayers else {
            return nil
        }
        return (0..<LANNetplayProtocol.maximumPlayers).map { port in
            let base = port * bytesPerPort
            return LANNetplayInput(
                buttons: read(data, at: base),
                stickX: Int16(bitPattern: read(data, at: base + 2)),
                stickY: Int16(bitPattern: read(data, at: base + 4)),
                lookX: Int16(bitPattern: read(data, at: base + 6)),
                lookY: Int16(bitPattern: read(data, at: base + 8)),
                touchLookX: Int16(bitPattern: read(data, at: base + 10)),
                touchLookY: Int16(bitPattern: read(data, at: base + 12)),
                crouchSequence: read(data, at: base + 14))
        }
    }

    private static func append(_ value: UInt16, to data: inout Data) {
        data.append(UInt8(truncatingIfNeeded: value))
        data.append(UInt8(truncatingIfNeeded: value >> 8))
    }

    private static func read(_ data: Data, at offset: Int) -> UInt16 {
        UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }
}
