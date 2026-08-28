import Foundation
import MultipeerConnectivity

final class Companion: NSObject,
    MCNearbyServiceBrowserDelegate,
    MCSessionDelegate
{
    private let peer = MCPeerID(displayName: "GoldenPad Host Companion")
    private let senderID = UUID().uuidString
    private lazy var session = MCSession(
        peer: peer,
        securityIdentity: nil,
        encryptionPreference: .required)
    private lazy var browser = MCNearbyServiceBrowser(
        peer: peer,
        serviceType: LANNetplayProtocol.serviceType)
    private var invited = false
    private var readySent = false
    private var passed = false
    private var goReceived = false
    private var lastOrderedFrame: UInt64 = 0
    private var timeoutWorkItem: DispatchWorkItem?
    private let runtimeReadyDelay: TimeInterval = {
        let environment = ProcessInfo.processInfo.environment
        guard let raw = environment["GOLDENPAD_LAN_COMPANION_READY_DELAY_MS"],
              let milliseconds = Double(raw),
              milliseconds >= 0 else { return 0 }
        return milliseconds / 1_000
    }()
    private let targetFrame: UInt64 = {
        let raw = ProcessInfo.processInfo.environment[
            "GOLDENPAD_LAN_COMPANION_TARGET_FRAME"]
        return raw.flatMap(UInt64.init) ?? 120
    }()
    private let holdSeconds: TimeInterval = {
        let raw = ProcessInfo.processInfo.environment[
            "GOLDENPAD_LAN_COMPANION_HOLD_SECONDS"]
        return raw.flatMap(Double.init) ?? 10
    }()
    private let timeoutSeconds: TimeInterval = {
        let raw = ProcessInfo.processInfo.environment[
            "GOLDENPAD_LAN_COMPANION_TIMEOUT_SECONDS"]
        return raw.flatMap(Double.init) ?? 45
    }()

    func run() {
        session.delegate = self
        browser.delegate = self
        browser.startBrowsingForPeers()
        let timeout = DispatchWorkItem {
            fputs("LAN companion: timed out\n", stderr)
            exit(1)
        }
        timeoutWorkItem = timeout
        DispatchQueue.main.asyncAfter(
            deadline: .now() + timeoutSeconds,
            execute: timeout)
        RunLoop.main.run()
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        guard !invited else { return }
        invited = true
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        fputs("LAN companion browse error: \(error)\n", stderr)
        exit(1)
    }

    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        guard state == .connected else { return }
        send(LANNetplayMessage(
            kind: .hello,
            senderID: senderID,
            senderName: peer.displayName))
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode(LANNetplayMessage.self, from: data),
              message.isCompatible else { return }
        if message.kind == .roster,
           let participants = message.participants,
           participants.count >= 2,
           message.assignedSlot == 1,
           !readySent {
            readySent = true
            send(LANNetplayMessage(
                kind: .ready,
                senderID: senderID,
                ready: true))
        } else if message.kind == .start {
            print("LAN companion: delaying runtime-ready by \(Int(runtimeReadyDelay * 1_000)) ms")
            fflush(stdout)
            DispatchQueue.main.asyncAfter(deadline: .now() + runtimeReadyDelay) { [weak self] in
                guard let self else { return }
                self.send(LANNetplayMessage(
                    kind: .runtimeReady,
                    senderID: self.senderID))
            }
        } else if message.kind == .go {
            goReceived = true
        } else if message.kind == .orderedFrame,
                  let frame = message.frame,
                  let inputs = message.inputs,
                  inputs.count == LANNetplayProtocol.maximumPlayers {
            guard goReceived else {
                fputs("LAN companion: ordered frame arrived before go barrier\n", stderr)
                exit(1)
            }
            guard lastOrderedFrame == 0 || frame == lastOrderedFrame + 1 else {
                fputs("LAN companion: non-monotonic ordered frame\n", stderr)
                exit(1)
            }
            lastOrderedFrame = frame
            send(LANNetplayMessage(
                kind: .input,
                senderID: senderID,
                frame: LANNetplayPacing.inputFrame(afterOrderedFrame: frame),
                input: .neutral))
            guard frame >= targetFrame, !passed else { return }
            passed = true
            timeoutWorkItem?.cancel()
            print("LAN companion: PASS discovery, Player 2, ready/start/runtime-ready/go, ordered frames 1...\(frame)")
            fflush(stdout)
            browser.stopBrowsingForPeers()
            // Stay connected and keep responding to every ordered frame so
            // this remains a real peer during screenshots and log capture.
            DispatchQueue.main.asyncAfter(deadline: .now() + holdSeconds) { [weak self] in
                guard let self else { exit(1) }
                print("LAN companion: completed through ordered frame \(self.lastOrderedFrame)")
                fflush(stdout)
                exit(0)
            }
        }
    }

    private func send(_ message: LANNetplayMessage) {
        guard let data = try? JSONEncoder().encode(message),
              !session.connectedPeers.isEmpty else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }

    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {}

    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {}

    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {}
}

@main
struct LANNetplayCompanion {
    static func main() {
        let companion = Companion()
        companion.run()
        withExtendedLifetime(companion) {}
    }
}
