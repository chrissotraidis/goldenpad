# GoldenPad LAN Netplay Lab results

Date: 2026-08-28
Branch: `codex/netplay-determinism-experiment`

## Straight answer

The experiment has moved from an architecture proposal to a real LAN test
build. GoldenPad can now advertise a nearby room, discover and securely join
it, assign stable player slots, exchange ready/start state, send ordered
four-port input frames, consume them in the native GoldenEye runtime behind a
three-frame buffer, and stop simulation on a missing authoritative frame.

The first physical iPad/iPhone run proved discovery, secure joining, stable
Player 1/2 assignment, ready/start, and roughly two seconds of 60 Hz ordered
input delivery. It also found a real synchronization defect: the two runtimes
started 178 ms apart, their local VI-derived clocks differed by one tick, and
the first shared checksum comparison stopped both devices.

The latest Simulator candidate now derives netplay time from the authoritative
consumed input frame and synchronizes at the runtime VI boundary. A two-part
barrier waits until both GoldenEye's game thread and the VI scheduler are
parked before the host releases frame 1. With a fixed room seed, immediate
guest readiness and readiness delayed by two seconds produced the same 42
canonical hashes through frame 1,260 while rendering normally. A new device
build and second physical run remain the decisive playable-synchronization
gate; the v2 build currently installed on the devices predates this Simulator
correction.

## First physical run: failure and diagnosis

- Host configured at `08:06:39.779`; guest configured at `08:06:39.850`.
- Host reached its first native input poll at `08:06:40.787`; guest reached it
  at `08:06:40.965`, a 178 ms offset.
- At the first comparable boot-state sample, the host menu timer was 71 and
  the guest timer was 72.
- Reliable ordered-frame packets arrived at roughly 60 Hz until
  `08:06:41.854`, then the host emitted the checksum-fault message and stopped
  the frame timer.
- Neither runtime logged a missing authoritative frame. Discovery and
  transport were not the initial failure.
- The overlay correctly showed `Stopped`, but the old pause seam stopped
  synchronized input rather than the entire presentation loop. Continuing
  animation after the fault was independent divergence, not working netplay.

## Initial protocol v2 correction

- Both native runtimes report runtime-ready to the room host before `go`.
- The host releases one explicit `go` barrier before frame 1. Reliable message
  ordering guarantees the guest sees `go` before any ordered frame.
- While netplay is enabled, the patched GoldenEye clock is based on the shared
  consumed logical frame instead of each device's local RT64 VI count.
- A fault now stops frame, checksum, and ready timers once, preserves the
  original reason, prints it to unified logging, and shows the checksum values
  directly in the overlay.
- The protocol/compatibility identifier is now v2 so an older LAN Lab build
  cannot silently join the corrected room.

## Simulator scheduling correction after v2

- Blocking at the first controller poll was wrong. GoldenEye can read the
  controller many times in one presented frame, especially during startup, so
  consuming one network frame per poll created the observed roughly 2 FPS
  behavior and left RT64 at zero presented frames in the first black-screen
  reproduction.
- Controller reads are now instantaneous and return the most recently latched
  authoritative input.
- N64ModernRuntime's VI callback latches exactly one ordered input bundle
  immediately before releasing one actual VI event to GoldenEye. This is the
  simulation source-of-truth seam.
- A VI-only barrier was still timing-sensitive: delaying the companion by two
  seconds changed whether Player/Prop initialization completed by network
  frame 30.
- The final barrier is game-defined. Bootstrap VIs run normally until
  GoldenEye reaches its patched wait boundary. The next VI parks the scheduler;
  only after both game thread and VI scheduler are parked does the host send
  `go`.
- In both controlled runs the game thread parked at local VI 37 and the VI
  scheduler parked at VI 38. The two-second companion delay did not change
  these values or any canonical hash through frame 1,260.

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
- The runtime VI callback waits for the authoritative frame plus a three-frame
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
- One-Simulator limit: PASS. Exactly one iPad Simulator was booted throughout.
  The dedicated profile twice lost its device service and Simulator
  automatically selected another iPad profile; each transition was checked
  before testing continued, and no two Simulators were booted concurrently.
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
  - the controller-poll-gated reproduction consumed network frames at 60 Hz
    while reporting `dl=0`, `vi=0`, and `presented=0`; controller polling was
    not a valid simulation clock.
  - the VI-gated connected run reached `dl=515`, `vi=514`, and
    `presented=514` in its first health window, then exceeded 1,100 presented
    frames with zero audio drops.
  - the final immediate/delayed barrier runs both maintained one presentation
    per VI. Their first sampled windows were 552 and 477 presented frames;
    the difference is sampling-window length, not simulation-frame identity.
  - disconnect now visibly says `Stopped`, pauses the deterministic runtime,
    and returns immediately from later input polls instead of blocking again.
- Startup-delay determinism: PASS in one Simulator.
  - fixed room seed: `424242`.
  - immediate-ready and 2,000 ms delayed-ready runs both parked the game thread
    at VI 37 and scheduler at VI 38.
  - all 42 common 30-frame checksum samples matched byte-for-byte from frame 30
    through frame 1,260; the delayed log contained one additional frame-1,290
    sample because it was captured slightly later.
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

Corrected v2 artifact:

- IPA: `dist/GoldenPad-LAN-Lab-2-clock-barrier-signed.ipa`
- Size: 7,202,174 bytes
- SHA-256: `4ba647d7f40dc5498d925ab87ff1016a8a3e5c7f2e1fccebb5304fbb11757f38`
- ROM content: none
- Installed in place on the physical iPad and iPhone.
- Pre/post-install ROM, active save, backup save, and preferences: byte-for-byte
  preserved on both devices.
- This artifact is now superseded for testing by the un-packaged Simulator
  scheduling correction above. Do not use its physical replay as the final
  verdict; build and install the new device candidate first.

## Physical iPad + iPhone gate

Before this gate, build/sign/package the new game-thread + VI-barrier candidate
and install it in place on both devices while re-verifying private data hashes.

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
