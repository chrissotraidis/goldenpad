# GoldenPad LAN Netplay Lab results

Date: 2026-08-28
Branch: `codex/netplay-determinism-experiment`
Current protocol: v3

## Straight answer

This is now a credible two-device LAN experiment, not yet proven playable
multiplayer.

GoldenPad can advertise and discover a nearby room, assign stable player
slots, synchronize ready/start, and run the full GoldenEye simulation on every
device from the same ordered four-controller input stream. The ROM is not
modified. The native GoldenPad layer owns the room UI, networking, input
ordering, synchronization, diagnostics, and per-player presentation crop.

Protocol v3 fixes the failure seen in the first physical run and the later
roughly 2 FPS Simulator reproduction:

- Input is latched once per GoldenEye VI, not once per controller poll.
- Each peer labels its controller sample with the exact future frame it belongs
  to. The host never substitutes the latest or last-known input.
- The host may lead the native consumer by at most four ordered frames. This
  prevents an unconstrained sender from racing ahead and increasing latency.
- A stable stock file-menu boundary parks both GoldenEye's game thread and the
  VI scheduler before authoritative frame 1.
- Only volatile pre-match clock/counter globals are normalized at frame 1.
  Menu, stage, saves, players, props, match settings, and ROM data are not
  rewritten.
- A missing peer input or checksum mismatch visibly stops the test.

Three fresh fixed-seed Simulator runs now agree: an immediate peer, a peer
whose runtime-ready response was delayed 2,000 ms, and an extended peer run
produced identical canonical hashes at every common 30-frame sample. The
extended run remained synchronized through frame 1,020. During the active run,
simulation and network delivery both measured 60.0 FPS with zero missing
frames and three buffered frames.

The v3 candidate is now installed on the paired iPad and iPhone with the ROM,
converted ROM, active save, backup save, and preferences verified byte-for-byte
unchanged. The remaining decisive gate is to play a real stock multiplayer
match on those two devices.

## Architecture now under test

- The host is the source of truth for room membership, Player 1-4 assignment,
  readiness, the room seed, ordered input frames, and checksum comparison.
- The host does not stream video and does not simulate the world for clients.
  Every iPhone/iPad runs the same full local GoldenEye simulation.
- Frames 1-4 use neutral input. On receipt of ordered frame N, every device
  samples its local controls for frame N+4. The host waits for the exact sample
  from every connected player before ordering that frame.
- The native runtime consumes frame N only after the three following frames
  have arrived, maintaining the bounded look-ahead used by the deterministic
  bridge.
- Empty N64 ports remain neutral. Crouch toggles carry per-player sequence
  numbers so retries cannot apply a toggle twice.
- Canonical game-state hashes are sampled every 30 consumed frames. A mismatch
  is reported with frame and hash values and stops all timers.
- The live overlay reports render, simulation, and network rates separately.

This architecture is peer-hosted LAN lockstep. A later Internet version can
reuse the deterministic/input protocol, but global discovery, NAT traversal,
relay service, latency policy, abuse controls, and host-loss behavior are
separate product work.

## What the first physical run proved

The v1/v2-era iPad/iPhone run proved:

- local discovery and encrypted joining;
- stable Player 1 and Player 2 assignment;
- ready/start exchange;
- roughly two seconds of ordered 60 Hz input delivery;
- preservation of the ROM, saves, and preferences across installation.

It also failed correctly enough to expose the original synchronization bug:

- Host configured at `08:06:39.779`; guest at `08:06:39.850`.
- Host reached its first native input poll at `08:06:40.787`; guest at
  `08:06:40.965`, a 178 ms offset.
- The local VI-derived clocks differed by one tick at the first comparable
  sample, producing a checksum fault.
- Neither runtime reported a missing authoritative frame. Transport was not
  the initial cause.

That physical build is superseded. Its result must not be treated as a verdict
on v3.

## Simulator experiments and decisions

### Rejected: controller-poll synchronization

GoldenEye can poll a controller many times within one presented frame,
especially during startup. Advancing one network frame per poll produced the
reported roughly 2 FPS behavior and left RT64 at zero presented frames in the
first reproduction. Controller reads are now instantaneous and return the
most recently VI-latched authoritative sample.

### Rejected: a guessed fixed VI boundary

A fixed VI 60 pre-roll deadlocked: the VI scheduler parked before GoldenEye's
game thread reached the patched wait. A constant VI count is not a valid
cross-device start contract.

### Retained: game-state plus VI barrier

Neutral boot runs until GoldenEye reaches stock file menu 3 with stage and
pending stage 90. The game thread parks there; the following VI parks the
scheduler. Frame 1 is released only after the host receives runtime-ready from
all peers.

Repeated launches showed that the local barrier can still occur one VI apart.
This corrected an earlier, too-strong conclusion that VI 37/38 was invariant.
The remaining difference was confined to volatile pre-match timing globals;
players and props already matched. Normalizing those counters at authoritative
frame 1 made the canonical state independent of the local bootstrap VI count.

### Retained: exact frame-indexed input

The earlier host reused the latest peer input and could continue for hundreds
of frames after the companion exited. Protocol v3 accepts only an input tagged
for the exact future frame. The three current runs stopped at frame 242 or
1,022 immediately after the companion intentionally left instead of silently
replaying stale input.

## Current evidence

- Protocol probe: PASS.
  - JSON round trip and compatibility rejection.
  - strict ordered buffering and missing-frame failure.
  - four-port 64-byte native wire encoding.
  - host lead is allowed through four frames and rejected at five.
- One-Simulator limit: PASS. Exactly one iPad Simulator was booted throughout
  this iteration.
- Real local discovery against a macOS companion: PASS.
  - encrypted session, Player 2, ready/start/runtime-ready/go.
  - monotonically ordered frames and exact N+4 input responses.
- Startup-delay determinism: PASS in one Simulator.
  - fixed room seed `424242`;
  - immediate and 2,000 ms delayed peers produced eight identical common
    samples from frame 30 through frame 240;
  - a third extended run matched both shorter runs through frame 240 and then
    continued to frame 1,020 without a missing authoritative frame.
- Active pacing: PASS for the synchronization path.
  - overlay sample at ordered frame 537: `buffered 3`, `misses 0`,
    `sim 60.0`, `net 60.0 fps`;
  - the earlier synchronization-induced roughly 2 FPS stall did not recur.
- Simulator rendering: existing issue, no LAN regression measured.
  - both LAN and offline controls showed the same red/dark RT64 corruption;
  - comparable health windows reported 556/1,149/1,397 presentations on LAN
    and 557/1,153/1,376 offline, so the network path did not reproduce the old
    synchronization-induced slowdown;
  - an active LAN overlay sample showed roughly 14 render FPS while sim/net
    stayed at 60 FPS. GoldenEye can submit display lists below VI rate, so that
    single instantaneous value is not labeled a GPU benchmark;
  - physical-device render rate and image quality must still be recorded
    before any playability claim.
- Framing logic: IMPLEMENTED, physical proof open.
  - menus and intro stay full-frame;
  - cropping begins only after the runtime reports an active stock multiplayer
    match;
  - the full game surface is centered at 4:3 before selecting the assigned
    quadrant, preserving iPad framing and adding symmetric side bars on wider
    iPhones.
- Simulator app and ARM64 device app: BUILD SUCCEEDED.
- Signed device app and extracted IPA signature: PASS.
- ROM/save-like archive scan and ZIP integrity: PASS.

## Current artifact

- App: `build-recomp-lan-lab-device/Release-iphoneos/GoldenPadRecompPrototype.app`
- IPA: `dist/GoldenPad-LAN-Lab-3-frame-indexed-lockstep-signed.ipa`
- Size: 7,208,011 bytes
- SHA-256: `ae6a479f82f6055ac77aebcd43efd08e540f729fdc09503be1bd77876d77bf33`
- Bundle: `com.chrissotraidis.goldenpad.lan-lab`
- Architecture: ARM64
- ROM/save content: none
- Physical installation status: installed in place on the paired iPad and
  iPhone; pre/post private-data manifests match

The IPA is development-signed for the paired devices. It is a private
diagnostic artifact, not a public or generally installable release.

Earlier artifacts remain historical evidence:

- v1 `GoldenPad-LAN-Lab-1-signed.ipa`: discovery/transport prototype.
- v2 `GoldenPad-LAN-Lab-2-clock-barrier-signed.ipa`: installed on the physical
  iPad/iPhone, private data preserved, but superseded by the VI and frame-index
  corrections.

## Next physical iPad + iPhone gate

Installation prerequisites completed on 2026-08-28: both devices were backed
up to private temporary locations, the signed v3 app was installed in place,
and all five allowlisted private-data hashes matched before/after on each
device. No Simulator remained booted.

1. Open **GoldenPad LAN Lab** on both devices and select the existing validated
   personal TLB-free GoldenEye ROM.
2. On the iPad choose **Host Room**. On the iPhone choose **Find Nearby** and
   join the iPad.
3. Confirm Player 1/Player 2 assignment, mark both Ready, and start the test.
4. Confirm both devices show the same complete intro/file menu, not a premature
   quadrant crop.
5. Player 1 enters GoldenEye's stock **Multiplayer** menu, chooses the normal
   built-in settings, and starts a match. Players 3/4 remain neutral.
6. Confirm iPad shows Player 1's top-left view and iPhone shows Player 2's
   top-right view, each centered without stretching or horizontal shift.
7. Move, turn, fire, and interact from both devices for at least three minutes.
8. Record render/sim/net FPS on both devices in menus and in-match. Also run
    **Play Offline** with the same settings as the renderer baseline.
9. Pass only if `misses` stays zero, neither device reports `DESYNC`, controls
    remain responsive, each player sees the same world interactions, and the
    image/crop is usable. Save screenshots and both diagnostic logs.

## Interpretation

- **Pass:** deterministic LAN multiplayer is feasible. Next measure input
  latency and jitter, then design a small Internet directory/relay experiment.
- **Desync with zero misses:** isolate remaining nondeterministic state before
  any Internet work.
- **Missing exact input:** tune the frame window and Wi-Fi behavior; do not
  restore stale-input replay.
- **Correct simulation but bad render/crop:** repair the presentation layer;
  the synchronization architecture remains viable.
- **Unacceptable latency at four frames plus Wi-Fi:** LAN lockstep is
  technically correct but not shippable without prediction/rollback or a
  stricter latency policy.

## Still out of scope

- Public/global room discovery and Internet relay/NAT traversal.
- Passworded rooms, chat, accounts, moderation, and abuse controls.
- Join-in-progress, reconnect, host migration, spectators, or rollback.
- Any claim that online GoldenEye multiplayer is shipping or physically
  proven playable.

Those are product layers after the physical LAN synchronization gate, not
requirements for this experiment.
