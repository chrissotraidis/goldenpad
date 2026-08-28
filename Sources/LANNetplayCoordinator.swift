import Foundation
import MultipeerConnectivity
import UIKit

@_silgen_name("goldenpad_recomp_netplay_configure")
private func goldenPadRecompNetplayConfigure(
    _ enabled: Int32,
    _ assignedSlot: Int32,
    _ roomSeed: UInt64
)

@_silgen_name("goldenpad_recomp_netplay_submit_frame")
private func goldenPadRecompNetplaySubmitFrame(
    _ frame: UInt64,
    _ bytes: UnsafePointer<UInt8>,
    _ byteCount: Int32
)

@_silgen_name("goldenpad_recomp_netplay_status")
private func goldenPadRecompNetplayStatus(
    _ consumedFrame: UnsafeMutablePointer<UInt64>,
    _ receivedFrame: UnsafeMutablePointer<UInt64>,
    _ missingFrames: UnsafeMutablePointer<UInt64>,
    _ checksumFrame: UnsafeMutablePointer<UInt64>,
    _ checksum: UnsafeMutablePointer<UInt64>
)

@_silgen_name("goldenpad_recomp_netplay_match_active")
private func goldenPadRecompNetplayMatchActive() -> Int32

@_silgen_name("goldenpad_recomp_netplay_pause")
private func goldenPadRecompNetplayPause()

@_silgen_name("goldenpad_recomp_performance_counters")
private func goldenPadRecompPerformanceCounters(
    _ displayLists: UnsafeMutablePointer<UInt64>,
    _ screenUpdates: UnsafeMutablePointer<UInt64>,
    _ presented: UnsafeMutablePointer<UInt64>,
    _ vis: UnsafeMutablePointer<UInt64>
)

struct LANNetplayRoom: Identifiable, Equatable {
    let peer: MCPeerID
    var id: Int { peer.hash }
    var name: String { peer.displayName }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.peer == rhs.peer }
}

@MainActor
final class LANNetplayCoordinator: NSObject, ObservableObject {
    enum Role: Equatable {
        case idle
        case browsing
        case host
        case guest
    }

    @Published private(set) var role: Role = .idle
    @Published private(set) var rooms: [LANNetplayRoom] = []
    @Published private(set) var participants: [LANNetplayParticipant] = []
    @Published private(set) var assignedSlot: Int?
    @Published private(set) var status = "Choose Host Room or Find Nearby Room."
    @Published private(set) var transportHealth = "Not connected"
    @Published private(set) var gameLaunchAuthorized = false
    @Published private(set) var roomSeed: UInt64?
    @Published private(set) var playerViewActive = false
    @Published private(set) var performance = "Render -- · sim -- · net -- fps"

    var localReady: Bool {
        participants.first(where: { $0.id == localID })?.ready ?? false
    }

    var canStart: Bool {
        role == .host && participants.count >= 2 &&
            participants.allSatisfy { $0.connected && $0.ready }
    }

    var isPlaying: Bool { gameLaunchAuthorized && assignedSlot != nil }

    private let localID = UUID().uuidString
    private lazy var localPeer = MCPeerID(displayName: Self.deviceDisplayName())
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var roomID = UUID().uuidString
    private var peerIDs: [MCPeerID: String] = [:]
    private var latestInputs = Array(
        repeating: LANNetplayInput.neutral,
        count: LANNetplayProtocol.maximumPlayers)
    private var nextOrderedFrame: UInt64 = 1
    private var frameTimer: Timer?
    private var checksumTimer: Timer?
    private var localChecksums: [UInt64: UInt64] = [:]
    private var peerChecksums: [String: [UInt64: UInt64]] = [:]
    private var transportStopped = false
    private var performanceSample: (
        time: TimeInterval,
        presented: UInt64,
        consumed: UInt64,
        received: UInt64
    )?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var simulatorAutoHost: Bool {
        ProcessInfo.processInfo.arguments.contains("--lan-netplay-auto-host")
    }

    override init() {
        super.init()
        participants = [localParticipant(slot: 0, ready: simulatorAutoHost)]
    }

    deinit {
        frameTimer?.invalidate()
        checksumTimer?.invalidate()
    }

    func hostRoom() {
        stop(resetMessage: false)
        role = .host
        roomID = UUID().uuidString
        assignedSlot = 0
        participants = [localParticipant(slot: 0, ready: simulatorAutoHost)]
        let session = makeSession()
        self.session = session
        let advertiser = MCNearbyServiceAdvertiser(
            peer: localPeer,
            discoveryInfo: ["room": "GoldenPad LAN Lab", "protocol": "1"],
            serviceType: LANNetplayProtocol.serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser
        status = "Hosting GoldenPad LAN Lab. Waiting for another device…"
        transportHealth = "Room advertised on the local network"
    }

    func browseForRooms() {
        stop(resetMessage: false)
        role = .browsing
        participants = [localParticipant(slot: -1, ready: false)]
        let session = makeSession()
        self.session = session
        let browser = MCNearbyServiceBrowser(
            peer: localPeer,
            serviceType: LANNetplayProtocol.serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser
        status = "Looking for GoldenPad rooms on this Wi-Fi network…"
        transportHealth = "Browsing nearby"
    }

    func join(_ room: LANNetplayRoom) {
        guard role == .browsing, let browser, let session else { return }
        status = "Requesting to join \(room.name)…"
        browser.invitePeer(room.peer, to: session, withContext: nil, timeout: 15)
    }

    func toggleReady() {
        guard let index = participants.firstIndex(where: { $0.id == localID }) else { return }
        participants[index].ready.toggle()
        if role == .host {
            broadcastRoster()
        } else {
            send(LANNetplayMessage(
                kind: .ready,
                senderID: localID,
                ready: participants[index].ready))
        }
    }

    func startGame() {
        guard canStart else { return }
        let seed = UInt64.random(in: 1...UInt64.max)
        beginGame(seed: seed, slot: 0)
        for peer in session?.connectedPeers ?? [] {
            let peerID = peerIDs[peer]
            let slot = participants.first(where: { $0.id == peerID })?.slot
            send(LANNetplayMessage(
                kind: .start,
                senderID: localID,
                roomID: roomID,
                assignedSlot: slot,
                roomSeed: seed,
                frame: 1), to: [peer])
        }
    }

    func stop(resetMessage: Bool = true) {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser = nil
        browser = nil
        session = nil
        frameTimer?.invalidate()
        frameTimer = nil
        checksumTimer?.invalidate()
        checksumTimer = nil
        goldenPadRecompNetplayConfigure(0, -1, 0)
        role = .idle
        rooms = []
        peerIDs = [:]
        participants = [localParticipant(slot: 0, ready: false)]
        assignedSlot = nil
        roomSeed = nil
        playerViewActive = false
        performance = "Render -- · sim -- · net -- fps"
        performanceSample = nil
        transportStopped = false
        gameLaunchAuthorized = false
        nextOrderedFrame = 1
        latestInputs = Array(repeating: .neutral, count: LANNetplayProtocol.maximumPlayers)
        localChecksums = [:]
        peerChecksums = [:]
        if resetMessage {
            status = "Choose Host Room or Find Nearby Room."
            transportHealth = "Not connected"
        }
    }

    func submitLocalInput(_ input: LANNetplayInput) {
        guard isPlaying, let slot = assignedSlot,
              latestInputs.indices.contains(slot) else { return }
        var merged = input
        merged.crouchSequence = latestInputs[slot].crouchSequence
        latestInputs[slot] = merged
    }

    func requestLocalCrouchToggle() {
        guard isPlaying, let slot = assignedSlot,
              latestInputs.indices.contains(slot) else { return }
        latestInputs[slot].crouchSequence &+= 1
        if latestInputs[slot].crouchSequence == 0 {
            latestInputs[slot].crouchSequence = 1
        }
    }

    func addLocalTouchLook(x: Int16, y: Int16) {
        guard isPlaying, let slot = assignedSlot,
              latestInputs.indices.contains(slot) else { return }
        latestInputs[slot].touchLookX = x
        latestInputs[slot].touchLookY = y
    }

    private func makeSession() -> MCSession {
        let result = MCSession(
            peer: localPeer,
            securityIdentity: nil,
            encryptionPreference: .required)
        result.delegate = self
        return result
    }

    private func beginGame(seed: UInt64, slot: Int) {
        assignedSlot = slot
        roomSeed = seed
        gameLaunchAuthorized = true
        transportStopped = false
        nextOrderedFrame = 1
        latestInputs = Array(repeating: .neutral, count: LANNetplayProtocol.maximumPlayers)
        goldenPadRecompNetplayConfigure(1, Int32(slot), seed)
        status = "Connected as Player \(slot + 1). Use GoldenEye's stock Multiplayer menu."
        transportHealth = "Starting ordered input stream"
        startTimers()
    }

    private func startTimers() {
        frameTimer?.invalidate()
        frameTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) {
            [weak self] _ in self?.frameTick()
        }
        checksumTimer?.invalidate()
        checksumTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {
            [weak self] _ in self?.checksumTick()
        }
    }

    private func frameTick() {
        guard isPlaying else { return }
        if role == .guest {
            send(LANNetplayMessage(
                kind: .input,
                senderID: localID,
                input: assignedSlot.flatMap { latestInputs[$0] }))
            return
        }
        guard role == .host else { return }
        let frame = nextOrderedFrame
        nextOrderedFrame += 1
        submitOrderedFrame(frame: frame, inputs: latestInputs)
        send(LANNetplayMessage(
            kind: .orderedFrame,
            senderID: localID,
            frame: frame,
            inputs: latestInputs))
        if let slot = assignedSlot {
            latestInputs[slot].touchLookX = 0
            latestInputs[slot].touchLookY = 0
        }
    }

    private func submitOrderedFrame(frame: UInt64, inputs: [LANNetplayInput]) {
        guard let data = LANNetplayInputWire.encode(inputs) else {
            fault("Host produced an invalid four-port input frame.")
            return
        }
        data.withUnsafeBytes { raw in
            guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return }
            goldenPadRecompNetplaySubmitFrame(frame, base, Int32(data.count))
        }
    }

    private func checksumTick() {
        guard isPlaying else { return }
        var consumed: UInt64 = 0
        var received: UInt64 = 0
        var missing: UInt64 = 0
        var checksumFrame: UInt64 = 0
        var checksum: UInt64 = 0
        goldenPadRecompNetplayStatus(
            &consumed, &received, &missing, &checksumFrame, &checksum)
        playerViewActive = goldenPadRecompNetplayMatchActive() != 0
        updatePerformance(consumed: consumed, received: received)
        if !transportStopped {
            transportHealth = "Frame \(consumed) · buffered \(received >= consumed ? received - consumed : 0) · misses \(missing)"
        }
        guard checksumFrame != 0, checksum != 0 else { return }
        if role == .host {
            localChecksums[checksumFrame] = checksum
            compareChecksums(frame: checksumFrame)
        } else {
            send(LANNetplayMessage(
                kind: .checksum,
                senderID: localID,
                frame: checksumFrame,
                checksum: checksum))
        }
    }

    private func handle(_ message: LANNetplayMessage, from peer: MCPeerID) {
        guard message.isCompatible else {
            fault("\(peer.displayName) is using an incompatible LAN Lab build.")
            return
        }
        switch message.kind {
        case .hello:
            guard role == .host else { return }
            peerIDs[peer] = message.senderID
            let used = Set(participants.map(\.slot))
            guard let slot = (1..<LANNetplayProtocol.maximumPlayers).first(where: { !used.contains($0) }) else {
                send(LANNetplayMessage(
                    kind: .fault,
                    senderID: localID,
                    detail: "This room is full."), to: [peer])
                return
            }
            participants.removeAll { $0.id == message.senderID }
            participants.append(LANNetplayParticipant(
                id: message.senderID,
                name: message.senderName ?? peer.displayName,
                slot: slot,
                ready: false,
                connected: true))
            participants.sort { $0.slot < $1.slot }
            broadcastRoster()
            status = "\(peer.displayName) joined as Player \(slot + 1)."
        case .roster:
            guard role != .host, let roster = message.participants else { return }
            participants = roster
            assignedSlot = message.assignedSlot ??
                roster.first(where: { $0.id == localID })?.slot
            role = .guest
            status = "Joined \(peer.displayName). Mark Ready when both devices are set."
        case .ready:
            guard role == .host,
                  let index = participants.firstIndex(where: { $0.id == message.senderID }) else { return }
            participants[index].ready = message.ready ?? false
            broadcastRoster()
            if simulatorAutoHost && canStart {
                startGame()
            }
        case .start:
            guard role != .host, let seed = message.roomSeed,
                  let slot = message.assignedSlot else { return }
            beginGame(seed: seed, slot: slot)
        case .input:
            guard role == .host,
                  let slot = participants.first(where: { $0.id == message.senderID })?.slot,
                  let input = message.input,
                  latestInputs.indices.contains(slot) else { return }
            latestInputs[slot] = input
        case .orderedFrame:
            guard role == .guest, let frame = message.frame,
                  let inputs = message.inputs,
                  inputs.count == LANNetplayProtocol.maximumPlayers else { return }
            submitOrderedFrame(frame: frame, inputs: inputs)
            if let slot = assignedSlot {
                latestInputs[slot].touchLookX = 0
                latestInputs[slot].touchLookY = 0
            }
        case .checksum:
            guard role == .host, let frame = message.frame,
                  let checksum = message.checksum else { return }
            peerChecksums[message.senderID, default: [:]][frame] = checksum
            compareChecksums(frame: frame)
        case .fault:
            fault(message.detail ?? "The other device ended the LAN test.")
        }
    }

    private func broadcastRoster() {
        guard role == .host else { return }
        for peer in session?.connectedPeers ?? [] {
            let id = peerIDs[peer]
            let slot = participants.first(where: { $0.id == id })?.slot
            send(LANNetplayMessage(
                kind: .roster,
                senderID: localID,
                roomID: roomID,
                participants: participants,
                assignedSlot: slot), to: [peer])
        }
    }

    private func compareChecksums(frame: UInt64) {
        guard let local = localChecksums[frame] else { return }
        for participant in participants where participant.id != localID {
            if let remote = peerChecksums[participant.id]?[frame], remote != local {
                fault("DESYNC at logical frame \(frame). The test was stopped.")
                send(LANNetplayMessage(
                    kind: .fault,
                    senderID: localID,
                    detail: status))
                return
            }
        }
        localChecksums = localChecksums.filter { $0.key + 600 >= frame }
        for id in peerChecksums.keys {
            peerChecksums[id] = peerChecksums[id]?.filter { $0.key + 600 >= frame }
        }
    }

    private func send(_ message: LANNetplayMessage, to peers: [MCPeerID]? = nil) {
        guard let session else { return }
        let recipients = peers ?? session.connectedPeers
        guard !recipients.isEmpty else { return }
        do {
            try session.send(encoder.encode(message), toPeers: recipients, with: .reliable)
        } catch {
            fault("LAN send failed: \(error.localizedDescription)")
        }
    }

    private func fault(_ detail: String) {
        status = detail
        transportHealth = "Stopped"
        transportStopped = true
        frameTimer?.invalidate()
        frameTimer = nil
        if gameLaunchAuthorized {
            // Keep the deterministic runtime explicitly paused. Disabling
            // netplay here would let the process continue offline and diverge.
            goldenPadRecompNetplayPause()
        } else {
            goldenPadRecompNetplayConfigure(0, -1, 0)
        }
    }

    private func updatePerformance(consumed: UInt64, received: UInt64) {
        var displayLists: UInt64 = 0
        var screenUpdates: UInt64 = 0
        var presented: UInt64 = 0
        var vis: UInt64 = 0
        goldenPadRecompPerformanceCounters(
            &displayLists, &screenUpdates, &presented, &vis)
        let now = ProcessInfo.processInfo.systemUptime
        guard let previous = performanceSample,
              now > previous.time,
              presented >= previous.presented,
              consumed >= previous.consumed,
              received >= previous.received else {
            performanceSample = (now, presented, consumed, received)
            return
        }
        let elapsed = now - previous.time
        let renderFPS = Double(presented - previous.presented) / elapsed
        let simulationFPS = Double(consumed - previous.consumed) / elapsed
        let networkFPS = Double(received - previous.received) / elapsed
        performance = String(
            format: "Render %.1f · sim %.1f · net %.1f fps",
            renderFPS, simulationFPS, networkFPS)
        performanceSample = (now, presented, consumed, received)
    }

    private func localParticipant(slot: Int, ready: Bool) -> LANNetplayParticipant {
        LANNetplayParticipant(
            id: localID,
            name: localPeer.displayName,
            slot: slot,
            ready: ready,
            connected: true)
    }

    private static func deviceDisplayName() -> String {
        let raw = UIDevice.current.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return String((raw.isEmpty ? UIDevice.current.model : raw).prefix(32))
    }
}

extension LANNetplayCoordinator: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Task { @MainActor [weak self] in
            guard let self, self.role == .host,
                  self.participants.count < LANNetplayProtocol.maximumPlayers,
                  let session = self.session else {
                invitationHandler(false, nil)
                return
            }
            invitationHandler(true, session)
        }
    }

    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: Error
    ) {
        Task { @MainActor [weak self] in
            self?.fault("Could not advertise the room: \(error.localizedDescription)")
        }
    }
}

extension LANNetplayCoordinator: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        Task { @MainActor [weak self] in
            guard let self, !self.rooms.contains(where: { $0.peer == peerID }) else { return }
            self.rooms.append(LANNetplayRoom(peer: peerID))
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor [weak self] in self?.rooms.removeAll { $0.peer == peerID } }
    }

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        Task { @MainActor [weak self] in
            self?.fault("Could not browse for rooms: \(error.localizedDescription)")
        }
    }
}

extension LANNetplayCoordinator: MCSessionDelegate {
    nonisolated func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch state {
            case .connected:
                self.browser?.stopBrowsingForPeers()
                self.send(LANNetplayMessage(
                    kind: .hello,
                    senderID: self.localID,
                    senderName: self.localPeer.displayName), to: [peerID])
                self.transportHealth = "Secure local session connected"
            case .connecting:
                self.transportHealth = "Connecting to \(peerID.displayName)…"
            case .notConnected:
                if let id = self.peerIDs[peerID],
                   let index = self.participants.firstIndex(where: { $0.id == id }) {
                    self.participants[index].connected = false
                    self.participants[index].ready = false
                }
                if self.isPlaying {
                    self.fault("\(peerID.displayName) disconnected. The LAN test was stopped.")
                } else if self.role == .host {
                    self.broadcastRoster()
                }
            @unknown default:
                self.fault("Unknown local-session state.")
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let message = try JSONDecoder().decode(LANNetplayMessage.self, from: data)
            Task { @MainActor [weak self] in self?.handle(message, from: peerID) }
        } catch {
            Task { @MainActor [weak self] in
                self?.fault("Rejected a malformed LAN message from \(peerID.displayName).")
            }
        }
    }

    nonisolated func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {}

    nonisolated func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {}

    nonisolated func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {}
}
