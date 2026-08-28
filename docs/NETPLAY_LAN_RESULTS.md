# GoldenPad LAN Netplay Lab results

Date: 2026-08-28
Branch: `codex/netplay-determinism-experiment`

## Straight answer

The experiment has moved from an architecture proposal to a real LAN test
build. GoldenPad can now advertise a nearby room, discover and securely join
it, assign stable player slots, exchange ready/start state, send ordered
four-port input frames, consume them in the native GoldenEye runtime behind a
three-frame buffer, and stop simulation on a missing authoritative frame.

This does **not** yet prove a playable two-device match. The remaining decisive
gate is running the installed build on the physical iPad and iPhone, navigating
the stock GoldenEye Multiplayer flow, and observing matching canonical
checksums while both people control their assigned views.

## Implemented

- A native `LAN Netplay Lab` launch screen appears before the game runtime, so
  both devices can establish one shared room before either simulation starts.
- The iPad or iPhone can host. Another device can browse the local network and
  join without an account or external server.
- The host owns room membership, stable Player 1-4 assignment, readiness,
  synchronized seed, start, input order, and checksum comparison.
- The transport rejects a different protocol or compatibility identifier.
- Every ordered frame contains buttons, left stick, right look, and relative
  touch look for all four N64 ports. Crouch toggles use a per-player sequence
  number so retransmission cannot apply a toggle twice. Empty slots are neutral.
- The C++ game thread waits for the authoritative frame plus a three-frame
  buffer. After a two-second missing-frame boundary it pauses instead of
  inventing input.
- The existing deterministic clock/frame-step path is enabled only for an
  active LAN test. It applies the shared room seed and synchronizes the stock
  multiplayer match clock.
- Canonical state hashes are sampled every 30 consumed frames. A mismatch sent
  to the host ends the test as a visible desync.
- The live overlay reports three independent rates: RT64 presentations,
  simulation frames consumed, and authoritative network frames received.
- GoldenEye's menus remain full-frame. Cropping starts only after the runtime
  confirms an active stock multiplayer match.
- The netplay game surface is centered at 4:3 before quadrant scaling. This
  preserves correct framing on iPad and adds symmetric side bars on wide iPhone
  screens instead of stretching or horizontally shifting a quadrant.
- No ROM bytes, multiplayer menu, or GoldenEye settings screen were replaced.
  The host still selects Multiplayer and its match settings in stock GoldenEye.

## Evidence completed

- Pure protocol probe: PASS.
  - JSON message round trip.
  - compatibility rejection.
  - out-of-order arrival buffered into strict order.
  - missing frame faults.
  - four-port 64-byte native wire encoding round trip.
- One-Simulator limit: PASS. Only `GoldenPad Determinism iPad` was booted.
- Real local discovery with a Mac companion: PASS.
  - room advertised and discovered.
  - secure session connected.
  - companion assigned Player 2.
  - Player 2 Ready reached the host.
  - common start message received.
  - ordered frames 1 through 8 arrived monotonically.
- Native runtime bridge on the iPad Simulator: PASS.
  - more than 1,100 authoritative frames consumed.
  - three/four-frame observed buffer.
  - zero missing frames.
- Performance instrumentation and reported-stall diagnosis: PASS.
  - the old run logged no RT64 progress for ten seconds after the temporary
    companion peer disappeared and repeatedly entered its two-second
    missing-frame wait; that was the observed near-2-FPS behavior.
  - the corrected connected run measured `Render 52.0`, `sim 60.0`, and
    `net 60.0 fps`, with zero misses on the iPad Simulator.
  - disconnect now visibly says `Stopped`, pauses the deterministic runtime,
    and returns immediately from later input polls instead of blocking again.
- Framing regression: PASS.
  - the earlier immediate Player 1 crop was reproduced.
  - cropping was gated on actual multiplayer-match state.
  - the Rare/Nintendo intro then rendered as a complete centered frame after
    the LAN ordered stream began.
- Simulator app and ARM64 device app: BUILD SUCCEEDED.
- Signed device app: code-signature verification passed with the local
  development identity.
- ROM scan and IPA archive test: PASS.
- The unique diagnostic bundle `com.chrissotraidis.goldenpad.lan-lab` was
  installed successfully on both paired physical devices. It does not replace
  the accepted GoldenPad Preview or its data.

## Artifact

- App: `build-recomp-lan-lab-device/Release-iphoneos/GoldenPadRecompPrototype.app`
- IPA: `dist/GoldenPad-LAN-Lab-1-signed.ipa`
- Size: 7,200,797 bytes
- SHA-256: `28521cdea379a28bcbfa291744e5e88700a828322f3519c5dc79dc3375412521`
- ROM content: none

The IPA is locally development-signed for the paired devices. It is a private
diagnostic artifact, not a public or generally installable release.

## Physical iPad + iPhone gate

1. Open **GoldenPad LAN Lab** on both devices. This is separate from GoldenPad.
2. On each device, select the same validated personal TLB-free GoldenEye ROM.
3. Allow Local Network access when iOS asks.
4. On the iPad choose **Host Room**.
5. On the iPhone choose **Find Nearby**, then join the iPad's room.
6. Confirm the roster says Player 1 on iPad and Player 2 on iPhone.
7. Tap **Ready** on both. On the iPad tap **Start LAN Test**.
8. Confirm both devices show the same complete GoldenEye intro/menu—not a
   premature quadrant crop.
9. Player 1 navigates stock GoldenEye into **Multiplayer**, selects the desired
   built-in settings, and starts a four-player match. Players 3 and 4 remain
   neutral for this two-device gate.
10. When the match becomes active, confirm iPad switches to the top-left Player
    1 view and iPhone to the top-right Player 2 view. The iPhone view should be
    centered at 4:3, not stretched edge to edge.
11. Move, turn, fire, and interact on both devices for at least three minutes.
12. Record all three FPS values on both devices during menus and during the
    match. Compare them with **Play Offline** on the same device and settings.
    The LAN build fails if it falls into single-digit FPS or is materially worse
    than the offline baseline beyond a transient shader/startup period.
13. Pass only if both overlays continue advancing, `misses` stays zero, neither
    device reports `DESYNC`, and each player's actions are visible in the shared
    match. Capture a screenshot from each device plus both diagnostics logs.

## Interpretation of the physical result

- **Pass:** LAN synchronized simulation is feasible. The next phase is
  resilience testing, latency/jitter measurement, reconnect policy, and only
  then a small public room-directory/relay design.
- **Desync with zero misses:** the canonical projection or a remaining
  nondeterministic game/runtime source needs isolation. Do not build global
  matchmaking yet.
- **Missing frames or disconnect:** tune transport cadence/buffering and test
  Wi-Fi behavior before changing simulation code.
- **Wrong crop with synchronized state:** fix only the host presentation layer;
  the network architecture remains viable.
- **Both devices cannot reach the same stock menu/match state:** move more of
  the pre-match flow under an explicit synchronized room-start script. Do not
  modify the ROM to solve it.

## What remains out

- Public/global room discovery.
- Internet relay and NAT traversal.
- Passworded rooms, chat, accounts, moderation, and abuse controls.
- Join-in-progress, reconnect, host migration, spectators, or rollback.
- Any claim that online GoldenEye multiplayer is shipping or proven playable.

Those are product layers after the physical LAN synchronization gate, not
prerequisites for running this experiment.
