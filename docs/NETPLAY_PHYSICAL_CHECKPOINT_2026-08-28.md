# GoldenPad physical LAN netplay checkpoint

Date: 2026-08-28
Status: **physical v3 synchronization failed at frame 30; experiment preserved**
Branch at test: `codex/netplay-determinism-experiment`
Source commit at test: `7afaaa86c84280bed46de67b56da29fb738c9d69`

This is the authoritative restart point for GoldenPad network multiplayer.
Earlier determinism, overnight-Simulator, and LAN documents retain the path to
this result, but this checkpoint controls the current go/no-go decision.

## Straight answer

GoldenPad's peer-hosted delayed-input lockstep architecture is still plausible,
but it is **not physically deterministic yet** and is not ready for Internet
multiplayer work.

The real iPad and iPhone successfully discovered one another, joined an
encrypted nearby room, received stable Player 1/Player 2 assignments, became
ready, released the same ordered frame stream, and reached checksum frame 30.
At that boundary their player and prop projections were identical, but their
19-word global projection differed. The host reported `DESYNC frame 30` and
both runtimes deliberately paused.

The apps did not crash. No new iOS crash report was generated, both LAN Lab
processes remained alive after the stop, and their private diagnostics
continued writing frozen health samples. The simultaneous stop was the
experiment's fail-closed behavior working as designed.

## Tested hardware

- Host: iPad Pro 12.9-inch (6th generation), model `iPad14,5`.
- Guest: iPhone 14, model `iPhone14,7`.
- Transport: local peer session on the same LAN.
- Simulator state: no Simulator booted during installation or physical replay.
- Diagnostic bundle: `com.chrissotraidis.goldenpad.lan-lab`.
- Protocol/compatibility: v3 / `goldenpad-ge-us-netplay-lab-v3`.

Device-specific CoreDevice identifiers, private container paths, ROM bytes,
saves, preferences, signing material, and raw logs are intentionally not
committed.

## Exact frame-30 evidence

### iPad host

- GoldenEye game-thread barrier: local VI `1092`.
- VI-scheduler barrier: local VI `1093`.
- Canonical frame-30 hash: `0291c118dedbd187`.
- Globals: `62459b2ae49a1fd8`.
- Players: `b928418e0cc40c30`.
- Props: `f9105157e57528de`.
- Last active counters after the deliberate pause: display lists `1090`, VI
  `1090`, presented `1090`.

### iPhone guest

- GoldenEye game-thread barrier: local VI `1091`.
- VI-scheduler barrier: local VI `1092`.
- Canonical frame-30 hash: `77f63ae1188e29c7`.
- Globals: `6d6d0a40fa8666f6`.
- Players: `b928418e0cc40c30`.
- Props: `f9105157e57528de`.
- Last active counters after the deliberate pause: display lists `1085`, VI
  `1085`, presented `1085`.

The one-VI bootstrap difference correlates exactly with a globals-only
canonical mismatch. This is strong evidence that v3's frame-1 bootstrap
normalization is incomplete. It does not yet identify the exact global word or
prove that the extra VI is the only causal path.

## Crash determination

The user's visible experience was reasonably described as both devices
"crashing" because both stopped together. The retained evidence distinguishes
that appearance from process termination:

- no new `GoldenPadRecompPrototype` `.ips` report appeared for this run;
- the newest iPad report predated the replay, and the newest iPhone report was
  from 2026-08-21;
- the installed LAN Lab executables remained in each device's live process
  list after the stop;
- health logs continued at fixed display-list/VI/presentation counters; and
- the coordinator's desync path invalidates timers and calls the native pause
  function, which intentionally freezes deterministic execution.

The diagnostic line saying a previous foreground session ended unexpectedly
appears before the current runtime starts. It is consistent with the earlier
in-place app replacement leaving the prior session marker and is not evidence
that the frame-30 run generated a new process crash.

## What v3 proved

- No ROM patch or replacement GoldenEye multiplayer menu is required.
- Native pre-game room UI can live outside the ROM.
- Nearby advertisement, discovery, encrypted connection, roster, readiness,
  stable slot assignment, start, runtime-ready, and go barriers work on real
  iOS/iPadOS hardware.
- The host can order four-port, exact-frame input bundles.
- A peer responds to ordered frame N with its local sample for frame N+4.
- The host is capped at four produced frames beyond the native consumer.
- Missing exact input is not replaced with stale input.
- The native VI callback, rather than arbitrary controller polls, is the
  correct consumption seam.
- Player and prop canonical projections were identical at the first physical
  comparison.
- The fail-closed checksum path stopped both peers at the same boundary.
- Installing the diagnostic app in place preserved all allowlisted private
  data byte-for-byte.

## What v3 did not prove

- Cross-device canonical global-state agreement.
- A playable stock multiplayer match on two devices.
- Correct physical quadrant framing during an active match.
- Acceptable end-to-end control latency or jitter.
- Resilience to Wi-Fi loss, peer disconnect, backgrounding, or thermal load.
- Internet discovery, NAT traversal, relay behavior, passwords, chat,
  moderation, reconnect, host migration, spectators, or rollback.
- Any shippable online-multiplayer claim.

## Why the final Simulator pass was insufficient

The v3 Simulator runs used one iPad Simulator plus a macOS companion. Immediate
and 2,000 ms delayed peers matched at every common sample through frame 240,
and an extended peer reached frame 1,020. The active path reported `sim 60.0`,
`net 60.0`, three buffered frames, and zero misses.

Those final runs entered the stock-menu barrier at the same local VI. Earlier
Simulator iterations had demonstrated a one-VI variation, but the final
normalized v3 pair did not reproduce that variation. The physical iPad/iPhone
pair did. Therefore the prior wording that normalization made the canonical
state independent of bootstrap VI count was too strong and is superseded.

The simulator still provided useful proof of protocol ordering, pacing,
missing-input behavior, and the correct VI consumption seam. It did not prove
cross-device startup-state identity.

## Current canonical global projection

Frame-30 logging currently reports only one aggregate hash across these 19
game words:

1. `0x8002A6C0` - current menu
2. `0x80023FA8` - current stage
3. `0x80048164` - pending stage
4. `0x80024260` - synchronized RNG state word
5. `0x80024264` - synchronized RNG state word
6. `0x8002B340` - multiplayer scenario/global state
7. `0x80048174` - clock timer
8. `0x80048178` - global timer delta
9. `0x8004817C` - global timer
10. `0x80048198` - multiplayer time
11. `0x8004819C` - multiplayer point/time state
12. `0x80048194` - timing state
13. `0x80048180` - timing state
14. `0x800481B0` - timing state
15. `0x80079EB8` - player number/global selection
16. `0x8008C500` - stop/game state
17. `0x8008C504` - game-over state
18. `0x8002CA64` - character/slot state
19. `0x8002CA68` - character/slot state

v3 normalizes selected volatile clock/counter words at authoritative frame 1,
sets the shared room seed, and later synchronizes the stock multiplayer match
clock. Because the runtime log does not emit the 19 individual values, the
retained v3 evidence cannot distinguish:

- one missed volatile counter;
- RNG advancement derived from a pre-frame-1 difference;
- scenario/menu-transition state derived from the extra bootstrap VI;
- a device-specific runtime behavior outside the canonical projection that
  later feeds one canonical word; or
- more than one differing word.

Removing the global projection or ignoring the mismatch is not an acceptable
repair. Any exclusion needs source-level proof that the field cannot influence
gameplay.

## Smallest next experiment: protocol v4 diagnostic

Do not begin with matchmaking, Internet relay work, rollback, savestates, ROM
modification, or presentation changes.

1. Bump the diagnostic compatibility identifier to v4 so v3 cannot join.
2. At frame 1 and frame 30, log each canonical global as
   `address=value`, followed by the component hashes.
3. On mismatch, send or retain the same 19-word snapshot on host and guest.
4. Also log the shared room seed, assigned slot, game-thread barrier VI,
   scheduler barrier VI, menu/stage/pending state, and consumed/received frame.
5. Build and run the existing immediate/delayed one-Simulator controls.
6. Package a new ROM-free development-signed diagnostic IPA.
7. Back up and hash the same allowlisted private data before installation.
8. Install v4 in place on the same iPad/iPhone, verify private-data hashes, and
   perform one room start. Stop at the first comparison.
9. Diff the 19 words directly.
10. Normalize only the exact source-proven volatile field or repair the state
    transition that produced it, then repeat the same gate.

Pass requires different local bootstrap VI counts to produce identical
individual global words and identical component hashes through at least frame
1,020 before entering a real multiplayer match.

## Source map

- `Sources/LANNetplayProtocol.swift` - protocol v3 identity, message schema,
  four-port input wire encoding, exact future-frame mapping, and producer cap.
- `Sources/LANNetplayCoordinator.swift` - nearby room lifecycle, host roster,
  ready/start barriers, exact-frame input collection, ordered publication,
  checksum comparison, performance overlay state, and fail-closed pause.
- `Sources/RecompPrototypeApp.swift` - LAN Lab launch surface, offline escape,
  overlay, and match-only quadrant selection.
- `Sources/RecompPrototypeInput.swift` - local controller/touch publication into
  the assigned LAN slot.
- `Support/RecompPrototype/recomp_game_start.cpp` - native frame ring, VI
  consumption seam, stock-menu/game-thread barrier, bootstrap normalization,
  room seed/clock handling, canonical hashes, and native pause/status APIs.
- `patches/goldeneye64recomp-deterministic-frame-step.patch` - patched
  GoldenEye frame-step seam.
- `patches/n64modernruntime-deterministic-clock-probe.patch` - runtime VI/clock
  callback seam used by the experiment.
- `Tests/LANNetplayProtocolProbe.swift` - pure message/wire/order/pacing checks.
- `Tests/LANNetplayCompanion.swift` - real macOS nearby peer with configurable
  runtime-ready delay, target frame, hold time, and exact N+4 responses.
- `scripts/compare-lan-netplay-checksum-logs.py` - first common checksum
  mismatch detector.
- `scripts/verify-lan-netplay-protocol.sh` and
  `scripts/run-lan-netplay-companion.sh` - retained protocol and nearby-peer
  entry points.
- `scripts/package-lan-netplay-lab-ipa.sh` - signed diagnostic packaging and
  ROM/save-like payload rejection.

## Commit path to the physical result

1. `05fd42a` - add the determinism experiment.
2. `771a841` - document the overnight Simulator loop.
3. `5133cf6` - prototype deterministic four-player feasibility.
4. `471b93d` - document the two-device LAN loop.
5. `103bddd` - build the two-device LAN Lab.
6. `606500c` - synchronize LAN runtime start and clock.
7. `082dbac` - gate LAN input at the synchronized VI boundary.
8. `6d6ab01` - harden exact frame-indexed lockstep and pacing.
9. `7afaaa8` - record signed v3 physical installation and preservation.

The documentation commit after this list publishes the failed physical result;
use Git history from this file to identify its final SHA.

## Artifact and reproduction identity

- Device app:
  `build-recomp-lan-lab-device/Release-iphoneos/GoldenPadRecompPrototype.app`
- Private diagnostic IPA:
  `dist/GoldenPad-LAN-Lab-3-frame-indexed-lockstep-signed.ipa`
- IPA size: 7,208,011 bytes.
- IPA SHA-256:
  `ae6a479f82f6055ac77aebcd43efd08e540f729fdc09503be1bd77876d77bf33`.
- IPA contains no ROM or save-like payload.
- The IPA is development-signed for the paired devices and is not a public
  installable release.
- Generated build directories and `dist/` artifacts remain ignored; use the
  committed packaging script to reproduce them locally.

Relevant gates:

```sh
scripts/verify-lan-netplay-protocol.sh
python3 scripts/compare-recomp-determinism-traces.py --self-test
python3 scripts/compare-lan-netplay-checksum-logs.py FIRST.log SECOND.log \
  --minimum-frame 240 --maximum-frame 240
cmake --build build-recomp-lan-lab-simulator --config Release \
  --target GoldenPadRecompPrototype -j 8
cmake --build build-recomp-lan-lab-device --config Release \
  --target GoldenPadRecompPrototype -j 8
scripts/package-lan-netplay-lab-ipa.sh
scripts/check-no-rom-data.sh
```

## Preservation boundary

Before v3 installation, the iPad and iPhone LAN Lab containers were copied to
private temporary storage. Five allowlisted files were hashed on each device:

- preferences plist;
- converted runtime ROM;
- active save;
- backup save; and
- selected TLB-free ROM in Documents.

All five pre/post-install hashes matched on both devices. The public document
records that result without publishing private save or preference hashes. The
validated TLB-free ROM identity remains the already documented SHA-256
`7ec491ee3164851d0995e3e8ad19999df5e3028be6ba3729c4ac16c31a9c0959`.

The temporary backups are not a durable archive and must not be treated as the
only recovery copy in a later session. Repeat the backup/hash gate before any
future installation.

## Resume checklist

- Start from current GitHub `main` after this checkpoint is published.
- Confirm the working tree is clean or use a new isolated worktree.
- Keep the accepted Preview bundle and the LAN Lab diagnostic bundle separate.
- Do not boot more than one Simulator.
- Do not commit ROMs, saves, preferences, signing material, raw device logs,
  raw RDRAM, generated source trees, or local absolute paths.
- Treat v3 physical status as **FAIL at frame 30, globals only**.
- Treat "both devices crashed" as **disproven for this replay**; they paused.
- Implement the v4 word-level diagnostic before attempting a gameplay fix.
- Do not announce or build global online rooms until cross-device canonical
  agreement passes.
