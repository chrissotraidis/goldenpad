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
    private var lastOrderedFrame: UInt64 = 0

    func run() {
        session.delegate = self
        browser.delegate = self
        browser.startBrowsingForPeers()
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            fputs("LAN companion: timed out\n", stderr)
            exit(1)
        }
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
        } else if message.kind == .orderedFrame,
                  let frame = message.frame,
                  let inputs = message.inputs,
                  inputs.count == LANNetplayProtocol.maximumPlayers,
                  !passed {
            guard lastOrderedFrame == 0 || frame == lastOrderedFrame + 1 else {
                fputs("LAN companion: non-monotonic ordered frame\n", stderr)
                exit(1)
            }
            lastOrderedFrame = frame
            send(LANNetplayMessage(
                kind: .input,
                senderID: senderID,
                input: .neutral))
            guard frame >= 8 else { return }
            passed = true
            print("LAN companion: PASS discovery, Player 2, ready/start, ordered frames 1...\(frame)")
            fflush(stdout)
            browser.stopBrowsingForPeers()
            // Stay connected briefly so the one-Simulator validation can
            // capture the actual two-peer roster without opening a second UI.
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { exit(0) }
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
