# Testing

## Evidence levels

1. **Static:** provenance, contamination and archive inspection.
2. **Build:** exact architecture/SDK and clean-checkout compile.
3. **Runtime:** logs plus framebuffer/UI evidence.
4. **Interaction:** real menu/gameplay input and state transition.
5. **Acceptance:** mission/match completion, persistence and relaunch.

A lower level never substitutes for a higher one.

## Primary RT64/AOT runtime — 2026-08-22

The primary runtime is the internal `GoldenPadRecompPrototype` target installed
as `GoldenPad`. Its current evidence ledger is
[`RT64_N64RECOMP_MORNING_HANDOFF_2026-08-21.md`](RT64_N64RECOMP_MORNING_HANDOFF_2026-08-21.md).
The MGB64 procedures later in this file now validate `GoldenPad Legacy`; they do
not establish acceptance for the primary app.

Current automated gates:

```sh
./scripts/check-no-rom-data.sh
./scripts/verify-recomp-prototype-host.sh
./scripts/verify-rt64-ios-metal.sh
GOLDENPAD_RT64_ARTIFACT_DIR="$PWD/build-rt64-static" \
  ./scripts/verify-rt64-ios-static.sh
git diff --check -- ':!patches/*.patch'
```

The complete private AOT build additionally requires ignored generated game
objects, N64ModernRuntime archives, RT64 archives and the user's own validated
TLBFREE ROM. Apply and reverse the tracked RT64 SDK, embedded-host, Plume and
GoldenEye trace patches around the Xcode build as documented in
[`RT64_N64RECOMP_PROTOTYPE.md`](RT64_N64RECOMP_PROTOTYPE.md). Both ignored
upstream checkouts must be clean afterward.

For a physical update, build/sign the ARM64 `iphoneos` target and install it in
place with `devicectl device install app`. Never uninstall the existing app.
Before and after installation, independently read back and hash the Documents
ROM, runtime ROM copy, active save and backup save. Confirm the installation
database UUID is unchanged, then launch without a live console, QuickTime,
Simulator control or profiler. Use one bounded application-log readback for PID,
ROM validation, display-list/VI/presentation progress, and audio drop/underrun
counters.

Hands-on acceptance for the newest signed build must cover:

1. Touch movement/look/buttons and Xbox/MFi movement/right-stick/buttons.
2. Normal-speed single-player gameplay through at least one mission segment.
3. Physical-speaker audio without persistent static.
4. Screenshot/system-overlay return without freeze or presentation stall.
5. Three-dot menu placement, Settings, Return to Main Menu, centered reticle,
   and no visible far-right seam.
6. Graphics changes only after fully quitting and reopening GoldenPad.
7. On both iPhone and iPad, choose **⋯ → Edit Touch Controls**. Verify the game
   remains full size and the real three-dot menu stays visible. Drag, resize and
   change the opacity of each of the eight controls, press Done, and verify
   persistence after relaunch. Verify Cancel discards unsaved edits and Reset
   restores only the current device-class draft.
8. Confirm the default iPhone layout keeps MOVE, LOOK, START and the complete
   action cluster visible and non-overlapping in landscape. Confirm the existing
   accepted iPad layout is unchanged. At minimum size, every button label must
   remain on one line inside its control.
9. Confirm a clean install starts with **Unlock all missions** off. An in-place
   update must preserve an existing user choice rather than resetting it.

Multiplayer is not an initial single-player preview gate. The former RT64
`0x0000000320000000` crash has a targeted KSEG1 address-mask repair and the
Preview 2 repair scopes full-frame clears/fades to the active player
viewport. A real two-player Temple match remained visually stable on ARM64 iPad
Simulator for more than 11,000 presented VI updates, with controller Player 1
movement and touch Player 2 FIRE registered independently. This is Simulator
evidence only. The first physical iPad follow-up failed: Player 2 still flashed
in horizontal split, and four-player mode corrupted lower views plus the
upper-right view. A subsequent 81.69-second physical capture showed corruption
recovering and migrating between lower quadrants despite healthy presentation
logs. The accepted repair makes each lower-player depth clear use the exact
shifted image address and viewport Y range used for rendering; a 43.87-second
four-player Simulator recording stayed clean. Physical four-player testing of
the exact render-control executable then kept all views coherent and did not
reproduce the old
black/checkerboard corruption. A 59.33-second device recording stayed coherent
across 3,336 consecutive frame comparisons, and its paired log reached 54,652
presented VI updates with zero audio drops or underruns. This is sufficient to
retain the exact executable as the stable experimental Preview 2 baseline, with
slight residual lighting flicker recorded as known debt; it is not a claim of
bug-free or complete multiplayer acceptance.

For the focused physical multiplayer retest:

1. Run horizontal two-player Temple for at least 30 seconds. Move and fire with
   Player 1 and touch Player 2; reject any black/checkerboard flash in either
   half.
2. Run the neutral four-player Temple diagnostic for at least 30 seconds. Watch
   all four quadrants continuously; reject corruption even if it recovers or
   moves to another player view.
3. If any flash occurs, leave the match running and capture video plus one
   bounded post-run application-log readback. A clean still screenshot is not
   sufficient evidence for this temporal fault.

### Technical-debt discrimination gates

These gates must exist before their corresponding repair is promoted. A test
that merely repeats the proposed implementation is insufficient.

#### Native-60-Hz fire-rate gate

The exact control is [`PREVIEW_4_BASELINE.md`](PREVIEW_4_BASELINE.md), and the
bounded procedure is [`TD01_FIRE_RATE_LOOP.md`](TD01_FIRE_RATE_LOOP.md).
Preview 4 contains the default-off read-only probe. Three guard windows recorded
13, 17, and 18 committed automatic-fire events per 100 ticks. The physical iPad
player baseline is now complete: three clean Phantom magazines each recorded 20
events over 58 ticks, normalized to 34.4828 events per 100 ticks with zero
observed range.

Before launching any app for the repair candidate, run:

```sh
scripts/verify-preview4-baseline.sh --allow-td01-repair
scripts/verify-fire-rate-probe-contract.sh
scripts/verify-fire-rate-authenticity-repair.sh
scripts/verify-recomp-input-matrix.sh
git diff --check
```

These terminal checks prove source identity, default-off wiring, observation
containment, and the accepted input mapping. They do not prove cadence or
gameplay. For the recorded measurement branch, use
`scripts/verify-preview4-baseline.sh --allow-td01-probe`; it permits only the
documented observation-body delta and still rejects input or timing changes.

When real-gameplay use is separately authorized, enable only the fire-rate
probe. Use one repeatable ordinary-input setup with one automatic weapon.
Obtain three complete player windows through the ordinary game input boundary.
A valid window is either 100 sampled ticks or a continuous magazine-to-empty
window containing at least 15 shot events. Record:

- source commit and executable identity;
- platform, stage, difficulty, control style, weapon, and input device;
- simulation ticks;
- weapon and starting/ending ammo;
- player automatic-shot events; and
- starting/ending player fire counter.

Then record three fixed-line-of-sight guard windows separately. Do not inject
inventory, mutate a save, force a transform, move the player, alter mission or
enemy state, or publish input below the ordinary host boundary. Reject a run if
the weapon changes, a reload occurs inside the window, neither valid completion
reason is present, a magazine window has fewer than 15 events, or another
behavior probe is enabled. Normalize magazine results to events per 100 ticks.

The pinned MGB64 reference measured AK-47 at 33.3 shots per 100 locked-60-Hz
ticks without authenticity scaling and 11.3 at the N64-equivalent cadence.
GoldenPad's measured 34.4828 result is close to the unscaled reference and about
3.05 times the authentic target. Record every complete run, mean, range, and
any explained setup variance. Event count and ammo delta must agree or the
observation is invalid.

The selected repair scales the one shared positive automatic-rate getter by
three, so the player and guard paths cannot drift. Zero and negative values,
including the semi-automatic classification, are unchanged. It passes only if
its before/after ratio matches the source-derived expectation, player and guard
timing are changed as one coherent decision, semi-automatic and menu behavior
remain unchanged, the complete Preview 4 input/tank matrix passes, and hands-on
combat feel is explicitly re-accepted.

For the physical candidate stop gate, normally launch `GoldenPad P4 Test`; do
not use remote `devicectl` activation. On Frigate/Agent, continuously empty the
first 20-round Phantom magazine once. The fixed 100-tick observation window
should report approximately 11-12 shots instead of the Preview 4 magazine
emptying at 20 shots/58 ticks. Then confirm: one PP7 shot per trigger press; one
ordinary enemy automatic encounter is slower but functional; menu navigation,
normal movement/look, and held-Aim left-stick sight control remain unchanged.
One clean magazine is sufficient for this acceptance pass; do not repeat three
baseline runs unless the result is inconsistent.

#### Modern sidestep gate

Test GoldenPad's modern and original modes separately in live gameplay:

1. In modern mode, MOVE horizontal strafes and does not turn; LOOK horizontal
   turns and does not emit C-left/right.
2. The same semantics hold for touch and a physical controller.
3. Original N64 C-button mode still emits C-left/right sidestep input.
4. File select, mission menus, watch/pause, and settings navigation keep their
   existing directions and button behavior.
5. Changing modes or opening settings neutralizes held movement/action state.

A code-level mapping test is required before device work; one successful
controller preset does not establish touch behavior.

#### Host input suspension gate

Start with MOVE and FIRE held separately through touch and controller paths.
For each, present Settings, Share Diagnostics, touch-layout editing, the watch,
pause, and a scroll-tracking gesture. Assert that:

- every published port becomes neutral before the modal/paused boundary;
- no held button, stick, look delta, or queued crouch edge replays on dismissal;
- the 60 Hz mobile publisher remains scheduled through common-mode UI tracking,
  or the UI explicitly suspends and resumes it with a neutral boundary;
- native menu/watch navigation remains unchanged; and
- ordinary Preview 4 touch/controller gameplay resumes only after fresh input.

Run the gate in normal single-player and the controller-P1/touch-P2 diagnostic.
Scene-inactive release alone does not pass sheet presentation, because a SwiftUI
sheet need not background or inactivate the scene.

#### Controller ownership lifecycle gate

The synthetic probe must cover, in order: connect controller A; connect B;
disconnect A while input is held; reconnect A with device ordering changed;
background/foreground; disconnect all. At every step assert:

- each device owns at most one port and each port at most one device;
- a lost device publishes neutral before any reassignment;
- touch stays on its explicit owner and never falls through to Player 1
  mid-match;
- held buttons are not replayed after reconnect/foreground; and
- advertised connected-port count matches actual published states.

Then repeat on physical hardware with two, three, and four controllers. The
neutral four-port render diagnostic is not this gate.

#### Lifecycle stall/freeze gate

On the current physical build, run at least ten repetitions each of screenshot,
Control Center open/close, app switcher round-trip, lock/unlock, and
background/foreground during live gameplay. Record one bounded post-run log,
not a continuous console. Correlate:

- VI and presented-frame progress;
- nil-drawable/acquire failures;
- present-queue wait duration;
- Metal fence-wait duration;
- input-publication timer drift; and
- audio produced/drop/underrun counters.

Classify a recoverable multi-second stall separately from a permanent freeze.
Do not patch the app lifecycle merely because both look similar to a user.

#### Audio discontinuity gate

GoldenEye requests exactly 22,050 Hz and the runtime passes that request through
unquantized, matching the host source node. The requested-Hz line is therefore a
deployed-binary consistency check, not an open rate-mismatch hypothesis.

Capture the drop/underrun trajectories from the same physical session in which
static is heard and correlate them with an external audio timestamp. If the
counters stay flat, feed a project-generated continuous sine or ramp through
the ring and use an output tap to locate sample discontinuities. This test must
contain no game audio. Cover cold start, route change, interruption,
background/foreground, and ring wrap. Zero underrun counters alone do not pass
audible quality.

#### Residual flicker gate

Isolated matched single-player and four-player runs recorded zero depth
`formatChanged` rebuilds. A later fixed-player-render-order diagnostic sampled
all shuffled permutations, showed no systematic luminance improvement, looked
worse to the user, and was reverted. The order hypothesis is rejected. The zero
rebuild signal is only narrowing evidence because it lacked known-active
calibration and did not count non-`formatChanged` uploads.

The next gate is continuous physical capture of the unchanged accepted render
baseline at a fixed, preferably stationary scene. Identify the first affected
frame and viewport before adding more telemetry. If a later RT64 diagnostic is
justified, count both `formatChanged` rebuilds and non-`formatChanged` depth
uploads, calibrate counter placement against a throwaway pre-repair build, and
preserve all three `randomGetNext()` calls in any order experiment. Never alter
the frozen depth-address repair merely to instrument it.

#### A12-family compatibility gate

For issue #9, retain a complete redacted `.ips`, verify the tested IPA checksum,
and record device model, OS build, GPU driver family, first failing project/
RT64 frame, and binary-image UUIDs. Reproduce on Preview 2 and, if possible, on
a second A12-family device. Compare one newer accepted device with the same
scene/configuration. Only a successful candidate run on affected hardware can
close the defect; otherwise document a deliberately chosen minimum GPU
generation rather than calling A12X non-ARM64.

In parallel, two diagnostic-only builds may force Plume's
`useDirectBufferAddresses=false` path and the Tier-1 encoder path on accepted
newer hardware. A reproduction there would localize the non-Metal3 binding seam;
a pass would not clear A12X. Neither variant may ship or replace the affected-
hardware gate.

### Native macOS regression gate

Before promoting a native `GoldenPad.app`, test without a recorder, live log
stream, profiler, or background Simulator control:

1. In file/mission menus, W/S and A/D navigate all four directions. Deliberate
   mouse movement follows the same directions; moving the pointer up must never
   move the selection down.
2. Start Dam and verify the pointer is captured automatically when live play
   begins. Horizontal and vertical look must remain responsive while moving
   with WASD. Escape must open the pause menu without releasing the pointer;
   Delete must release the pointer without pausing. C must toggle between
   GoldenEye's live stand/squat state without pulling the camera downward.
   Shift+W/S must not pitch the camera or move the player while manual aim is
   held. If live play receives no mouse motion or command request, first verify
   generated `RecompiledPatches/patches.c` calls all four bridges:
   `recomp_get_camera_inputs`, `goldenpad_recomp_consume_crouch_toggle`,
   `goldenpad_recomp_consume_reload`, and
   `goldenpad_recomp_consume_inventory_slot`.
   Active stage 33 with repeated `p1look=(0,0)` can mean the generated game-side
   consumer is missing; it does not by itself prove an AppKit delivery defect.
   The accepted baseline uses the Metal view's mouse callbacks and must not be
   replaced with an app-local event monitor without a separate failing test.
3. Compare Dam and Surface against an accepted high-resolution capture. The
   known thin far-right blue line remains open as TD-09; confirm it does not
   widen. Reject any new blue/black region, missing cliff/road/room geometry,
   or culling change after an input-only patch.
4. Enable **Unlock all missions**, return to mission select, and confirm later
   missions are available immediately. Disable it and confirm the current save
   remains unchanged; the setting must not write completion times to EEPROM.
5. Confirm mouse sensitivity and every keyboard binding persist after relaunch.
   Left mouse must fire, right mouse must perform Action, Space must not fire,
   and R must reload both hands through GoldenEye's native reload function.
   Middle click and wheel up/down must produce distinct weapon changes. Number
   keys 1–9/0 must select existing inventory slots and ignore unavailable slots.
6. Keep one mission active long enough to reject a delayed freeze. Read the
   bounded session log only after the run: any rising audio-underrun count or
   uneven VI/present progress is a failure even if launch and input initially
   work. Do not record, stream logs, or profile during this acceptance run.
7. While the mission remains active, confirm mouse and keyboard events stay
   responsive for the entire interval. The embedded Plume bridge must coalesce
   render-thread window/refresh queries so no more than one of each update is
   pending on AppKit's main queue. A build that renders or plays audio but lets
   event latency grow is a failure.

The 2026-08-21 builds that directly wrote player camera fields, used a generated
patch pair without the modern camera/crouch consumer, or used the Metal drawable
as the Plume swap-chain window size failed items 1–4. The retained 21:16:44 app
is the accepted input/render control; it disproved the later app-local event
monitor diagnosis. These are recorded rejected baselines, not release
candidates.

The first 349-function compact candidate also failed item 6 during hands-on
testing. The replacement Release candidate must be tested with QuickTime and
other capture tools closed; build/signature success alone is not acceptance.

The focused Preview 2 multiplayer gate is documented in
[`MULTIPLAYER_ROADMAP.md`](MULTIPLAYER_ROADMAP.md). It requires a sustained real
match with both horizontal viewports continuously visible, controller Player 1
and touch Player 2 operating independently, and no single-player regression.
Three/four-player, enhanced-visual and network tests are later gates.

For the four-player render-only probe, enable **Experimental two-player input
test**, then **Experimental four-player render test**, and fully quit/relaunch
GoldenPad before entering Multiplayer. Require the Multiplayer Options page to
show four players and a live match to show four stable quadrants. Controller
Player 1 and touch Player 2 must remain independent; Players 3/4 must stay
neutral. Pause Player 1 and require its watch UI to remain confined to the
upper-left quadrant without erasing the other three views. This probe does not
establish real four-controller support.

Preview 1 release evidence:

- the final signed executable is
  `c0aee770a84482ee73e26042774ffd4119a09c73df20ff985327fc8ca08bea6f`;
- it was installed in place on iPhone 14 without changing app-data UUID
  `3ACA6644-5550-4EEA-BDCA-D6F9D3827161`;
- the accepted preference/layout file remained byte-identical at
  `12e163bce76605fb852efc0d38a31d38aecbdbd7d6ef5da7d6fffa55d9d73ffd`;
- an unrecorded corrected launch remained alive as PID `4987`;
- `scripts/verify-recomp-prototype-ipa.sh` passed the 17-member unsigned IPA;
- IPA SHA-256 is
  `a3aa37003a56a498820d07e84de89660d309c2cde40d0911fb3826086caca3e9`;
- unsigned app-content SHA-256 is
  `33c590f8d3f849614dacb267972b2a7e65b69a544b3744a7b7624825a80b5cb8`.

The package audit is static/build evidence. The user's physical iPhone/iPad
play provides the single-player interaction/acceptance evidence; neither is
evidence of stable multiplayer.

Preview 2 release evidence:

- the exact signed mobile executable SHA-256 is
  `100ee12be02e2077e7559f6cd4ead210bb933abffb87874cf76a16afa06e67a9`;
- it was installed in place on the connected iPhone and iPad as version `0.1.0`
  build `2` without changing app-data UUIDs
  `3ACA6644-5550-4EEA-BDCA-D6F9D3827161` and
  `D2F4E1F3-F310-4A01-8ED7-65B907FAA17B`;
- independent pre/post readbacks on both devices matched the Documents ROM,
  runtime ROM, active save, backup save and preferences byte for byte;
- the exact build launched successfully on both devices, and the user approved
  this freshly rebuilt executable for publication after hands-on review;
- `scripts/verify-recomp-prototype-ipa.sh` passed the 18-member unsigned IPA;
- IPA SHA-256 is
  `704bdf68f67d1f0925fd1844ab865c263a79e105a6349ef410f365602e6c77e3`;
- unsigned mobile app-content SHA-256 is
  `bce1606fb88cf5a2a423875073871a8417d66f7b1462568bbbae390b72d1a5ec`;
- the package-audited Preview 2 Mac executable SHA-256 is
  `7c78b72f4d6fd1697a5fb0572dfe22de6a8680d7df784ceb0752ef7b9527c35d`;
- `scripts/verify-recomp-macos-alpha.sh` passed the 20-member arm64 Alpha
  archive at SHA-256
  `7a9e7342b0ae39518f73807f854b479d9691fd612ae6861ea527f2a19e4450a4`,
  with sorted app-content SHA-256
  `d07294bb9f9c1ca903ae7d9f84f5a75b1886796163fc2680b2a3730f38b3a342`.

These package audits establish architecture and contamination boundaries, not
hands-on gameplay quality. The user separately supplied the final mobile
interaction approval. The packaged Preview 2 Mac executable is a source-
equivalent rebuild of hands-on-tested executable
`0e73a74da8866f9f3784afedf78ff87a0ca18916e363e63fb33083747b149d00`;
the packaged `7c78b72f...` binary itself had package-audit evidence only.
Preview 3 later received exact-binary Mac hands-on acceptance.

Preview 3 release evidence:

- the exact signed mobile executable SHA-256 is
  `6ad969b56b6358e8c2731f97063b3d0dccf28674fdb4939216a289a330d8a72e`;
- build `3` was installed in place on the attached iPad without changing its
  app-data container, and pre/post readbacks proved both ROM copies, the active
  save, backup save and current preferences byte-identical;
- the resulting session passed ROM validation and entered the GoldenEye loop;
- the user accepted the final iPhone/iPad and Mac behavior for Preview 3
  publication, with no newly observed major regression;
- `scripts/verify-recomp-prototype-ipa.sh` passed the deterministic 18-member
  unsigned IPA at SHA-256
  `ef2ab9575d5a9df5d7d8d4138caa789625be3407ebc796a4d9339ea1fe6ba777`,
  with sorted unsigned app-content SHA-256
  `956e805d2575167b1045c7c5769f22f55d933e5a60c4a6283bfe30fedc1e5ab0`;
- the accepted Mac executable SHA-256 is
  `a6352c5179ff5822f4af3d1b20e1b02bf0d5d1af46b453c9bceca435b7e59808`;
- `scripts/verify-recomp-macos-alpha.sh` passed the deterministic 20-member
  arm64 Alpha archive at SHA-256
  `819bc8eabc1fc84d2a37c1847f68c8832c023f0b0643851ca3f6251244fc32ba`,
  with sorted app-content SHA-256
  `e15c17528a72881e3062504c2abc82a0a57bf0d039feb8240cbaf03b5db4f941`;
- two independent packaging runs produced byte-identical mobile and Mac
  archives; and
- the setup-copy gate confirmed that the app asks for an original ROM without
  exposing an internal filename or implying that the selected file is
  replaced.

These results prove the final packages, architecture, data-preservation
boundary and user acceptance recorded for Preview 3. They do not close the
known multiplayer, blue-edge, fire-rate, audio, lifecycle, A12X, or broader
long-session performance debt.

Preview 4 release evidence:

- `scripts/verify-recomp-input-matrix.sh` passes all 1.1 through 1.4 shared
  control-style cases, raw mobile menu passthrough, external-controller native
  manual Aim, the exact 1.872-degree controller-look rate, tracked upstream
  patch parity, and generated tank-state markers;
- the physically accepted signed iPad test executable SHA-256 is
  `2b31f8868885712fbad34cef1aea20b1dee48f59fc9d930cbd3fa8b8e82b6b12`;
- that physical pass covered title/mission navigation, ordinary on-foot
  movement/right look, left-trigger stationary left-stick manual Aim, Runway
  tank entry, drive, hull turn, turret aim, ordinary weapon and Tank Shell
  cycling/firing, exit/re-entry, return to title, and a Facility regression;
- the accepted test executable used 1.56 degrees per frame. The final version
  `0.1.0` build `4` public executable applies the user's requested 20 percent
  increase to 1.872 degrees
  per frame and has SHA-256
  `d83361f4daa70014b378aed20b9e26dc7c787d77b0fcd000816d536aecc8e66b`;
- the complete unsigned device app and native arm64 Mac app both compile against
  the same regenerated GoldenEye patch pair;
- `patches.c` and `patches_bin.c` SHA-256 values are
  `4a829165889a4e736199841c4c4237ee6a03ed97fa1ce6d891dfc864634862ff`
  and `cb3e439a8eb1587ac11b7fa29551b3f204860f993b9114ebd5331c179bc92bc6`;
- `scripts/verify-recomp-prototype-ipa.sh` passes the 18-member unsigned IPA at
  SHA-256
  `ff163b0af6b54596590da8e39cbaff0b388b69f1607ca34f62ce61e7fe144130`,
  with sorted unsigned app-content SHA-256
  `1ec161604af996f30bb3ac1e9c347f7c905623675ca32adf8d2c35a069c6a13c`;
- `scripts/verify-recomp-macos-alpha.sh` passes the 20-member arm64 Alpha archive
  at SHA-256
  `63bec02ad6e323a213f9cb9d15f763a58d6eb7bd4a1a40af6341a4fb8fb333ba`,
  with sorted app-content SHA-256
  `d2d0824047061b81ad3ef1b2fd2fd61fde09fc759176b782209c41279217a341`;
- the final unsigned release executable was not installed for a second physical
  pass after the requested 20 percent response increase; and
- Mac build/package proof does not close issue #17. Keep it open until the
  reporter verifies gameplay and supplies diagnostics if a problem remains.

Run the focused input gate before every package that retains the Preview 4
control boundary:

```sh
./scripts/verify-recomp-input-matrix.sh
```

Preview 5 fire-rate release evidence:

- `scripts/verify-fire-rate-authenticity-repair.sh` proves the frozen Preview 4
  measurement control lacks the repair, positive automatic rates scale by
  three in tracked source and generated MIPS, and zero/negative classifications
  remain unchanged;
- physical iPad telemetry recorded 12 Phantom events over 100 ticks, ammo 20 to
  8, versus Preview 4's 20 events over 58 ticks. The user accepted navigation,
  movement, controls, gameplay, and runtime quality;
- the production mobile app is version `0.1.0` build `5`, ARM64, probe-off by
  default, with unsigned executable SHA-256
  `dff62592f42eede6d6865c12bb35ff97c6f548975d7c3903289f6d09fc462491`;
- two independent packaging runs produced byte-identical 18-member unsigned
  IPAs at SHA-256
  `d4d6c6d7a00e79d1dd4759a97f3ae544c6112dff7c00ea9e57e21199a25c0db7`,
  sorted app-content SHA-256
  `4753f0814823aeecc545b5f33eea9d1bf2da0e7b93874e34ad5f6a0e8358981b`;
- two independent packaging runs produced byte-identical 20-member native arm64
  Mac Alpha archives at SHA-256
  `3dec5864aa637a7115f46a41fd81b8b2077ac44904bf48d7396c54c03a6faee2`,
  sorted app-content SHA-256
  `0221a39c5137dec3a923b1e5c80b30886f4604486a9c3f23eeb1bcedfeb0ed8a`;
- both archive verifiers passed their architecture, bundle, symbol, license,
  signing, ROM/save, private-path, and generated-asset boundaries; and
- no complete candidate guard fixed window or explicit PP7 sequence was
  physically captured. The shared getter and unchanged nonpositive path provide
  source/deterministic coverage; do not describe them as separate physical
  evidence.

Preview 6 menu and Mac-input release evidence:

- the user physically accepted Mac GoldenEye menu navigation, keyboard/mouse
  gameplay, ordinary turning, and held Shift Aim after the final tuning pass;
- on a physical iPad Pro, the user accepted the four utility-menu actions
  without a controller, connected a controller and accepted the same menu,
  then accepted Dam and Bunker controller gameplay with no observed control
  regression;
- `scripts/verify-recomp-input-matrix.sh` proves the front end preserves analog
  Mac navigation, default Mac mouse sensitivity is `3.00`, ordinary on-foot
  turning is `1.30x` while Shift Aim and tank rates remain unchanged, and the
  mobile utility overlay owns four independent 48-point action rows;
- `scripts/verify-preview4-baseline.sh --allow-preview6`, the automatic-fire
  gate, ROM-data audit, ARM64 iOS/Mac builds, and both package verifiers pass;
- two packaging runs produced byte-identical 18-member unsigned IPAs at
  SHA-256
  `ced4d58bd8b54fd0dac4c7e9d892e22ea80f28d4bfa219fd586818dd62ba7266`,
  sorted app-content SHA-256
  `0069201d9bcd8080778342342ec5e7da3a2aca6648c7f3ab7bb6eeae5229c941`;
- two packaging runs produced byte-identical 20-member native arm64 Mac Alpha
  archives at SHA-256
  `5189dcb5c7089f5ba45e7dbe17d67be9186148da20bce0c2c60e7156f78d71b8`,
  sorted app-content SHA-256
  `ab27557b23f95e5019b98dad7df82e6e9b808f40563643533a234cf53b874c53`;
  and
- this acceptance did not itself close the A12X or iPhone 13 mini renderer
  reports, known stage rendering defects, or long-session coverage. Issue #17
  later closed after its reporter verified Preview 6; issue #19 later passed the
  isolated iOS 17-target diagnostic.

Preview 7 compatibility-promotion gate:

- preserve Preview 6's complete input, automatic-fire, utility-menu, Mac, ROM,
  save, audio, renderer-setting, and package boundaries;
- require all 56 device Metal libraries to contain only an explicit iOS 17 AIR
  target and all 56 Simulator libraries to contain only the iOS 17 Simulator
  AIR target;
- require the production executable and unsigned IPA audit to reject any mixed,
  missing, iOS 26.5, or other unexpected embedded Metal target;
- build the normal `GoldenPad` mobile identity at version `0.1.0` build `7`;
- package the IPA and Mac Alpha twice and require byte-identical outputs;
- install the production mobile candidate in place and compare the Documents
  ROM, runtime ROM, active save, backup save, and preferences before and after;
- physically accept iPadOS ROM reuse, title/menu, touch and controller gameplay,
  utility menu, audio, and background/foreground behavior;
- physically accept macOS menu navigation, mouse/keyboard gameplay, the unchanged
  thin edge boundary, and bounded sustained play; and
- keep issue #9 open unless the exact production artifact succeeds on affected
  A12/A12X hardware. Issue #19 closes only after its reporter verifies the
  production Preview 7 artifact, not solely the side-by-side diagnostic app.

Preview 7 production-candidate evidence:

- the production iPhone/iPad identity is version `0.1.0` build `7` and its
  unsigned executable SHA-256 is
  `69aef6c5bb436a97893ea1a9abca773f5bea419c29872374ce30a4751f096359`;
- two unsigned IPA packaging passes reproduced SHA-256
  `4f6d26616fbc1d098ba1dce598ea8e958162c82efc975aa483db7e19bd9c58c4`
  and sorted app-content SHA-256
  `ffd52cbf9df870989dfce183fb88d61c034bb33f28fedc26b6c63a1ef26e7e39`;
- build `7` installed in place on the physical iPad and independent pre/post
  readbacks proved the Documents ROM, runtime ROM, active save, backup save,
  and preferences byte-identical;
- the user then explicitly accepted the exact production candidate on the
  physical iPad after controller pairing and gameplay, reporting that it works
  well with only the already-known graphical issues; and
- two Mac packaging passes reproduced SHA-256
  `5189dcb5c7089f5ba45e7dbe17d67be9186148da20bce0c2c60e7156f78d71b8`
  and sorted app-content SHA-256
  `ab27557b23f95e5019b98dad7df82e6e9b808f40563643533a234cf53b874c53`;
- the unsigned Mac source executable is byte-identical to Preview 6 at
  `05e8ec3da7ca277c22064c62b351ea53ff40eee7d3cbaa8ae967af62e7cf2c6a`.

Hands-on review reconfirmed that horizontal mouse yaw feels sluggish relative
to vertical movement. Because the exact Preview 7 Mac executable and package
are byte-identical to Preview 6, this is retained as known Mac debt rather than
classified as a Preview 7 regression. Do not raise global sensitivity again;
measure the horizontal queue, normalized output, and final yaw delta first.

The release tag `v0.1.0-preview.7` points to merge commit
`1f9ca4e7e668708937c88d77adb0ba6f41483256`. All four hosted assets were
downloaded into a fresh directory and matched the accepted local files byte for
byte. The hosted IPA and Mac ZIP then passed their complete package verifiers
with the same app-content hashes recorded above.

Preview 8 optional-Fire acceptance:

- the production iPhone/iPad identity is version `0.1.0` build `8`;
- the additional left-side Fire control is disabled by default and retains its
  own persisted position, scale, opacity, and enabled state on phone and tablet;
- focused tests prove primary-only, secondary-only, simultaneous press,
  release-one, release-both, and reset behavior for the aggregated N64 Z state;
- the signed candidate executable SHA-256 is
  `6d90224ad63fb50c0eaae9d76e42d105e152e105b3dc9a4e12dcb80db5984dff3`;
- two unsigned IPA packaging passes reproduced SHA-256
  `773223b7ed7787c18526fb63281a6a3e4960b87adb0a912b0c2b77d0f1312a1b`
  and sorted app-content SHA-256
  `be03451c0b0450c43096d49d944642a82bfb0f3c310f70289831e51fcd28dc6d`;
- all embedded Metal libraries retain only the iOS 17 AIR target;
- build `8` installed in place on the physical iPad, with the Documents ROM and
  preferences byte-identical before and after; protected Application Support
  inputs were unchanged; and
- the user tested the exact installed candidate and reported that it works and
  is great. Existing graphical artifacting/flicker remains separate work.

The release tag `v0.1.0-preview.8` targets merge commit
`4cc6e6eeed400cdd52d82a9101d27b6fc45768ab`. The hosted IPA and checksum were
downloaded into a fresh directory, matched the accepted local files byte for
byte, and the hosted IPA passed the complete package verifier with the same
app-content hash recorded above.

## Desktop baseline

```sh
./scripts/verify-mgb64-public-tests.sh
```

This exports the exact pinned public source, temporarily applies
`patches/mgb64-public-tests.patch`, builds it in a disposable directory and runs
its complete public CTest surface. The expected result is 100% passed across
103 entries with 10 explicit ROM/browser/optional-binary skips. Tests that
directly import upstream's export-ignored private fidelity tools stay outside
this public production gate. The ignored upstream checkout must be clean before
the run and is restored clean afterward.

For the private two-player startup gate, provide the supported retail ROM and
run:

```sh
GOLDENPAD_ROM_PATH=/private/path/to/retail-game.v64 \
  ./scripts/verify-mgb64-multiplayer-smoke.sh
```

The verifier temporarily applies
`patches/mgb64-multiplayer-smoke.patch`, builds the pinned native core, starts a
two-player Temple deathmatch, and requires clean assertions, healthy rendering,
two measurably distinct split-screen viewports, and the two-second match timer
to elapse. It deletes every ROM-derived screenshot, trace, log and save on exit
and restores the ignored upstream checkout clean. This is startup/render smoke;
it does not satisfy the human-completed D5/M2 match gate. Python Pillow is
required for the local image comparison.

For a private deterministic framebuffer proof, run from an ignored directory
with a private ROM path and do not publish the output:

```sh
GE007_RENDERER=webgpu GE007_WINDOW_WIDTH=640 GE007_WINDOW_HEIGHT=480 \
  ../build-goldenpad-webgpu/ge007 --rom /private/path/to/retail-game.v64 \
  --level dam --difficulty agent --deterministic \
  --screenshot-frame 600 --screenshot-exit --screenshot-label local-proof \
  --savedir ../local-saves
```

## Mobile matrix

Run sequentially:

1. iPhone simulator: install, invalid ROM, valid ROM, title/menu, mission, audio,
   touch, save, relaunch, background/foreground, rotation/safe area.
2. Stop iPhone simulator and app process.
3. iPad simulator: repeat the same cases.
4. Stop iPad simulator and compare logs, screenshots, memory and layout.
5. Repeat on physical iPhone/iPad for controller, real audio, thermals and any
   simulator-limited Metal/audio behavior.

Before the physical pass, build the opt-in signed target exactly as documented
in `BUILDING.md`. The signed renderer verifier must accept its code signature,
find `embedded.mobileprovision`, and confirm the requested bundle identifier.
Installation must use the resulting `build-mgb64-renderer-device-signed` app;
the reproducible `build-mgb64-renderer-device` app remains unsigned by design.

Keep raw diagnostic gameplay captures private. Only user-approved,
downsampled promotional screenshots may be tracked, and they must remain
separate from app/IPA package contents.

### Current foundation evidence

The 2026-08-03 pass used iOS 18.5 simulators, in this strict order:

1. iPhone 16 Pro: build, launch, render, validate supported V64, terminate and
   shut down.
2. iPad Pro 11-inch (M4): build, launch, render, validate supported V64, reject
   a one-byte file, terminate, uninstall and shut down.
3. Remove the iPhone installation as well, so neither app container retains the
   temporary retail-data copy.

The private diagnostic seam accepts `--validate-rom /absolute/path` or
`GOLDENPAD_VALIDATE_ROM_PATH`. It invokes the same `ROMValidator` used by the
Files picker and exists to make simulator validation reproducible. It does not
copy or persist the file and is not the production user flow.

The public README captures use the opposite, ROM-free path. On 2026-08-04 the
maintained app launched first on iPhone 16 Pro and then on iPad Pro 11-inch
(M4), with no validation argument, imported URL or ROM in either container.
`docs/images/goldenpad-setup-iphone.png` and
`docs/images/goldenpad-setup-ipad.png` show only the project-owned setup and
control-lab surfaces. Each app was terminated and uninstalled before its
simulator was shut down; both devices ended in `Shutdown` state.

The picker UI interaction pass opened native Files and cancelled cleanly on both
simulators. GoldenPad now declares one imported N64 ROM type for `.z64`, `.v64`,
`.n64` and `.rom`; cancel must leave the setup state unchanged.

Actual selection uses either that picker or **Open in GoldenPad** from Files.
The 2026-08-04 Files-origin pass used exact Simulator binary
`91f1a1a87ab02eb7fc983e510f388e49bb8003bc31de88211a4d09a87f1faee5`.
iPhone first received `UIOpenURLAction`, then logged `Validated ROM installed;
MGB64 scheduler ready`, Metal rendering and PCM readiness. After complete phone
cleanup, the unchanged iPad build repeated the chain at 2420x1668. Each private
Files copy, app container and temporary inspection artifact was deleted before
shutdown. This proves Simulator Files import, not a physical file provider.

Missing-file and wrong-hash acceptance also passes on both. Use a nonexistent
path for the first case. For the second, create a temporary zero-filled 12 MiB
file with only the four-byte Z64 header `80 37 12 40`; require the SHA-1 mismatch
state, then delete the fixture. Never derive this fixture from a retail dump.

Storage relaunch probes use no game data:

```sh
xcrun simctl launch DEVICE_ID com.chrissotraidis.goldenpad \
  --storage-probe-write
xcrun simctl terminate DEVICE_ID com.chrissotraidis.goldenpad
xcrun simctl launch DEVICE_ID com.chrissotraidis.goldenpad \
  --storage-probe-verify
```

The expected visible state is `storage: relaunch verified`. Inspect
`settings.json` and `Saves/player-1.sav` inside the private app container, then
uninstall the app so the probe is removed.

The game EEPROM has a separate exact 2 KiB relaunch probe:

```sh
xcrun simctl launch DEVICE_ID com.chrissotraidis.goldenpad \
  --eeprom-probe-write
xcrun simctl terminate DEVICE_ID com.chrissotraidis.goldenpad
xcrun simctl launch DEVICE_ID com.chrissotraidis.goldenpad \
  --eeprom-probe-verify
```

Require `storage: EEPROM relaunch verified`, a 2,048-byte
`Library/Application Support/GoldenPad/Saves/goldeneye-us.eep`, and exact probe
SHA-256 `2048cf697fb66b6c25186c3fdb1ad524cbbdc506a4904ac9c95598f2630f4c4c`.
The 2026-08-03 gate passed first on iPhone and then iPad, with uninstall and
shutdown between classes.

Lifecycle acceptance must use the real Simulator UI with an attached console:

1. Launch GoldenPad with `xcrun simctl launch --console-pty DEVICE_ID ...`.
2. Press Simulator's Home control and require `Audio session inactive`.
3. Open GoldenPad from the launcher and require `Audio session active at 48000.0 Hz`.
4. Terminate, uninstall and shut down that simulator before testing the other.

This gate passed sequentially on iPhone 16 Pro and iPad Pro 11-inch (M4).
Real-core interruption and route-change acceptance remains a game-audio gate.

Render-surface acceptance uses the same attached-console lifecycle pass. Before
backgrounding, require a nonzero `renderer: Metal WIDTH×HEIGHT @ HZ` value in
the visible status and matching `RT64 surface ready` console line. After Home
and launcher return, require the original full drawable size again. The current
sequential pass observed 1206×2622 at 60 Hz on iPhone 16 Pro and 1668×2420 at
60 Hz on iPad Pro 11-inch (M4).

The MGB64 layer-adapter pass reused that strict sequence. Require
`MGB64 Metal surface ready` before accepting the existing RT64/drawable-size
line. The 2026-08-03 run observed the MGB64 handoff at 1206×2622 on iPhone,
removed and shut down the phone, then observed 1668×2420 on iPad and removed and
shut down the tablet. This proves host-layer ownership, not a game frame.

Run `./scripts/verify-mgb64-ios-fast3d.sh` for the corresponding static gate. It
requires two ARM64 objects and the three public Fast3D entry points for each SDK,
and fails if SDL or desktop OpenGL symbols remain unresolved.

The touch lab must be driven through the real UI on both form factors. Verify
that movement/look axes clamp to `[-1, 1]`, momentary action bits clear after
release, the last non-neutral event remains visible for evidence, and controller
count/assignment do not destabilize the touch snapshot. Classic A must report
N64 mask `0x8000`; modern FIRE must report Z mask `0x2000`.

For each phone and tablet profile, open **Game Settings**, then **Touch
Controls** > **Edit touch layout**, and verify:

1. N64, Modern and Southpaw switch the visible live layout.
2. Selecting a control, nudging it and pressing Done persists one placement
   delta after terminate/relaunch; Reset removes that delta.
3. Size clamps to 70–150%; hide/show works; MOVE cannot be hidden.
4. The layout editor contains placement, size and visibility only; feel and
   behavior settings remain in Game Settings.
5. Opacity, global size, look sensitivity, Toggle/Hold aim, dead zone, gyro and
   external-control auto-hide settings persist. Switching aim behavior must
   release any latched AIM input.
6. Portrait and both landscape handed orientations stay within the safe guide.
7. Southpaw mirrors the action cluster to the left; FIRE/AIM must not overlap
   its right-side MOVE region.

The 2026-08-03 Simulator pass covered the accessible nudge path, persistence,
reset, hide/show, size/opacity controls and safe-area layout. Simulator presents
a synthetic unattached MFi controller; GoldenPad ignores it for auto-hide only
when compiled for Simulator. Direct finger dragging, physical Core Motion and
real-controller auto-hide remain device gates.

The 2026-08-04 release-menu pass repeated the mutable layout path with exact
Simulator executable
`818f1733fac43edec9a759c81874faf3b6b5bd0d1558c1fdecfb3f76520291a0`.
On a clean phone profile, FIRE changed from 116% to 126%, moved right,
hid/showed, persisted after terminate/relaunch, and returned to 116% after
Reset. The phone Display menu selected 4× and exposed the expected 3496×1608
drawable. The app was removed and the phone shut down before an independent
iPad install repeated FIRE 116% -> 126%, moved left, hid/showed, persisted after
relaunch and Reset to 116%. This proves that the final public menu schema and
separate profile storage remain wired; it does not convert Simulator input into
physical-finger acceptance.

### Native settings modal gate

Run with an attached console and real gameplay visible. On each form factor:

1. Tap AIM and require its accessibility value to change from `Off` to `On`.
2. Open Game Settings and require visible `Aim button` text plus an accessible
   `Aim button behavior` segmented group.
3. Require `[GoldenPad] Game presentation paused scene=1 overlay=1`. No display
   callbacks should advance while the sheet remains open.
4. Tap Done and require
   `[GoldenPad] Game presentation resumed scene=1 overlay=0`.
5. Require AIM to read `Off`; native UI and preset changes must not retain a
   latched touch action.

The 2026-08-04 pass used exact Simulator binary
`3a787f8a1d612b701b54862bc8a2dcd782c9a2e1e0bb2d3eff24ed4403646d28`
on iPhone 16 Pro, removed and shut down that phone, then repeated unchanged on
iPad Pro 11-inch (M4). Both Simulator installs were removed afterward. This
proves modal clock ownership and accessible state, not physical touch comfort.

### Scene-resolution gate

Open **Game Settings** > **Display** during live gameplay. Exercise 1×, 2×, 3×
and 4× in order, dismiss the sheet at 4× so the renderer allocates and presents
that target, then return to 1×. Require the game to resume after each change and
the native controls to remain at UIKit resolution. Expected landscape targets
for the current Simulator profiles are:

| Level | iPhone 16 Pro | iPad Pro 11-inch (M4) |
| --- | --- | --- |
| 1× | 874×402 | 1210×834 |
| 2× | 1748×804 | 2420×1668 |
| 3× | 2622×1206 | 3630×2502 |
| 4× | 3496×1608 | 4840×3336 |

The exact 2026-08-04 Simulator binary was
`c71c1630c4930bf60eb2827373025a1fe0431b6b364c53ca0155fa46b45d6681`.
All eight device/level combinations reached the expected target. This verifies
menu persistence and drawable wiring, not acceptable frame rate; profile real
missions separately and repeat on physical hardware.

### Game-frame cadence and touch-response gate

The Performance HUD defaults off. Enable it under **Game Settings** >
**Display**, and require the visible values to be sourced from MGB64's actual
`rspGfxTaskStart` display-list submissions. Do not report the device's 60 Hz
`MTKView` callback rate as game FPS, and do not describe rendered game frames as
simulation ticks. Wait for at least 16 published 250 ms windows so ROM/audio
startup has aged out, then require a non-zero log in this form:

```text
[GoldenPad] Game-frame cadence: PASS 51.8 FPS 19.31 ms 1% low 29.2 generation=16
```

Background/foreground the app and confirm the sampler resets instead of
counting suspended time as a frame. Run phone first, cleanly
terminate/uninstall/shut it down, then install the exact same app on iPad. The
2026-08-04 corrected-source pass used exact Simulator binary
`057a5883725ee3bf972bd4fb9c4acfa766e5ec7a57eb2ce79ffbde62f347b43e`.
The 60 Hz iPhone display reported `51.8 FPS 19.31 ms 1% low 29.2`; the unchanged
app on the 60 Hz iPad display reported `21.8 FPS 45.93 ms 1% low 15.6` at
2420x1668. Values are workload-dependent; the required invariant is that they
track game submissions rather than blindly matching display refresh.

For a renderer change, separate cold startup from steady state with two samples
of the live Simulator process. Capture once immediately after ROM launch and
again after the title scene has warmed:

```sh
/usr/bin/sample <GoldenPad-pid> 8 -file /tmp/goldenpad-cold.sample.txt
/usr/bin/sample <GoldenPad-pid> 5 -file /tmp/goldenpad-warm.sample.txt
```

The 2026-08-04 cold sample placed all 3,320 game-thread samples below synchronous
Metal shader-library creation. The warm baseline placed 811 of 3,217 samples in
`newTextureWithDescriptor` through `mtl_upload_texture`. After the bounded
three-frame-safe upload-texture recycler, only 76 of 3,662 samples reached new
texture creation and 3,141 were normal retrace sleep. Require the maintained
patch apply/reverse check, both linked SDK builds, a visible no-corruption check
and the production IPA audit after this class of change. These call-stack counts
are bottleneck evidence, not an FPS or physical-device acceptance result.
Terminate and relaunch without uninstalling before proposing a custom cache.
Metal's automatic per-app cache reduced synchronous shader creation to 2 of
3,702 game-thread samples in the follow-up run. Its remaining title-scene cost
was mostly Simulator XPC under texture `replaceRegion`; only physical-device
profiling can establish whether the upload itself needs another product change.

For touch response, drag across the visible LOOK region and require incremental
motion only: stopping the finger must produce neutral look on the following
publish instead of continuous virtual-stick rotation. AIM must toggle Off to On
without hiding the swipe region. A physical controller still uses the configured
Swift radial dead zone; mobile MGB64 keeps its downstream dead zone at zero and
look curve at one. This proves the response path, not physical comfort or a
hands-on mission playtest.

Multiple LOOK gesture updates may arrive before the next renderer input sample.
Run `--input-probe` and require `Touch look accumulation probe: PASS`; earlier
deltas must add to the pending swipe instead of being replaced by the latest
event. On landscape phone, require Weapon/Duck to sit above the home-indicator
strip and Action/Fire/Aim to clear the rounded edge. Exact Simulator binary
`818f1733fac43edec9a759c81874faf3b6b5bd0d1558c1fdecfb3f76520291a0`
passed the probe and visible phone layout first, then the unchanged iPad layout.
Both apps were removed and both simulators shut down. This remains Simulator
interaction evidence, not signed physical-touch acceptance.

For physical face buttons, run `--input-probe` and require
`Physical face-button isolation probe: PASS`. The pure mapping gate requires A
and Y to produce only N64 A (`0x8000`) and B and X to produce only N64 B
(`0x4000`); no single face button may emit A+B. Open **Game Settings** >
**Physical Controllers** and confirm the compact mapping reference fits the
landscape phone, then repeat unchanged in the iPad sheet. Exact binary
`d6249e072a279a07a31835147a30006510a512fcddf09955c55c47a5c95f10cb`
passed the diagnostic and visible menu check. A connected hardware playtest is
still required for stick, button and multiplayer feel.

The same probe must report `Multiplayer touch ownership probe: PASS`. Open
**Game Settings** > **Controllers** and require visible rows for Players 1–4.
Player 1 must state `Touch` or `Touch + <controller>`; Players 2–4 must never
claim touch. Use the Move menu to place a connected controller in Player 2 and
confirm Player 1 remains `Touch`. Moving to an occupied slot must swap the two
controllers. Exact Simulator binary
`369dcbdf0cfbc0b3d6439305f7b5bc524bab5004077e6da60ad6dfc7776abd13`
passed phone first and then unchanged on iPad with the synthetic MFi controller.
Physical multi-controller assignment and gameplay feel remain hardware gates.

For the authentic touch + gamepad preparation path, start from a clean install
with one controller on Player 1. Enter the original file and mode-select menus;
Multiplayer must be visibly disabled because the core sees only one player.
Open **Game Settings** > **Controllers** and require the instruction to move the
gamepad to Player 2. Perform that move and require `Two-player touch + gamepad is
ready`; after returning to mode select, Multiplayer must be enabled. Exact
Simulator binary
`ad158472f316e184ec155de42985f8847d0e77c8fa33be83d4b43fe3c2728071`
showed both native readiness states phone-first and then unchanged on iPad. The
authentic disabled-to-enabled game-menu transition was visually confirmed on
iPad. This proves preparation/discoverability, not match setup or completion.

For repository contamination checks:

```sh
./scripts/check-no-rom-data.sh
```

## MGB64 Apple ARM64 core gate

```sh
./scripts/verify-mgb64-ios-core.sh
```

At exact MGB64 `cd9b58f5f91291579b8e551aa925aab000d311cf`, the
2026-08-03 gate passed the upstream native SDK guard and produced 210-object
archives for both `iphonesimulator` and `iphoneos`. Both are non-fat ARM64. The
Release app linked for both SDKs, and binary inspection found the exact commit,
`goldenpad_mgb64_core_identity`, `goldenpad_mgb64_core_probe`, the real upstream
`randomSetSeed`/`randomGetNext` implementations, and the project-owned mobile
`guNormalize` implementation.

Runtime validation used no ROM. iPhone 16 Pro launched first and visibly
reported deterministic probe `0x80c24316`; it was terminated, uninstalled and
shut down before iPad Pro 11-inch (M4) launched and reported the same value.
The iPad app was then removed and shut down. This passes compilation/linkage and
a bounded game-code/GU execution seam, not title/menu/gameplay acceptance.

The coupled-renderer gates are:

```sh
./scripts/verify-mgb64-ios-metal.sh
./scripts/verify-mgb64-ios-fast3d.sh
./scripts/verify-mgb64-ios-renderer.sh
```

The unpatched backend failed for exactly two references to macOS-only
`CAMetalLayer.displaySyncEnabled`. The tracked exact-source patch gates those
writes to macOS, after which the complete `gfx_metal.mm` backend and its
combiner/backend/MSAA support compiled into four-object, non-fat ARM64 archives
for both mobile SDKs. Both export `gfx_metal_api`, and the verifier restored the
ignored MGB64 checkout to a clean tree. The Fast3D verifier also builds its
five-object ARM64 frontend for both SDKs while rejecting SDL/OpenGL residue.

The combined verifier links the core, Fast3D and Metal targets into both final
Release apps and requires `gfx_init`, `gfx_metal_api`, the renderer init/draw
bridge and `platformGetMetalLayer`. It rejects SDL/OpenGL/AppKit linkage and
leaves the upstream checkout clean. Runtime then proceeds strictly sequentially:
iPhone 16 Pro first reported backend init, `MSAA=0`, and `first frame: scene
1206x2622, geometry encoder open`; after removal/shutdown, iPad Pro 11-inch (M4)
reported the same at 1668x2420. Five-second observation windows produced no GPU
errors. This proves a real ROM-free MGB64 frame lifecycle, not title/menu output.

The next private-data subgate reused the existing automation path with the
supported V64 copied only into each Simulator app's temporary directory.
Require `Validated ROM installed; MGB64 file table ready` after SHA-1
validation. iPhone passed first while the renderer continued at 1206x2622; its
app was uninstalled and simulator shut down before iPad repeated at 1668x2420.
The iPad app was then uninstalled and shut down. The source copy and core-owned
heap are therefore absent after each pass. This proves volatile ownership and
file-table patching, not title startup.

The file-table gate adds upstream `rom_offsets.c` and its zero-content native
asset-symbol placeholders. Both final SDK binaries must retain
`platformPatchFileTable` and `goldenpad_mgb64_file_table_ready`. After validation,
require `Validated ROM installed; MGB64 file table ready`. The 2026-08-03
sequential run observed that line at 1206x2622 on iPhone, removed the app and
shut down, then observed it at 1668x2420 on iPad before the same cleanup. The
bridge verifies entry 1 and Dam entry 14 against exact owned-buffer offsets.

The scheduler bootstrap gate adds the project-owned `mgb64_mobile_os.c` rather
than upstream's combined SDL input/audio shim. Both final SDK binaries must
retain `goldenpad_mgb64_prepare_scheduler`, `osCreateScheduler` and
`osScGetCmdQ`. After a supported validation, require `Validated ROM installed;
MGB64 scheduler ready`. The sequential run observed that line alongside the
real Metal first frame at 1206x2622 on iPhone, removed its entire app container
and shut down the phone, then repeated at 1668x2420 on iPad before identical
cleanup. This proves scheduler/queue construction, not frame delivery or title
startup.

The next frame-delivery subgate requires `MGB64 cooperative retrace delivered`
after the scheduler-ready line. The producer must enqueue only when the graphics
queue is empty, so a build with no `bossEntry` consumer retains one message
rather than filling all 32 slots. Attached-console runs observed the line at
1206x2622 on iPhone, removed/shut down the phone, then repeated at 1668x2420 on
iPad before identical cleanup. This proves UIKit-to-scheduler cadence ownership,
not simulation or title rendering.

The first portable startup-closure subgate extracts MGB64's real host-side GU
matrix/vector implementations from the desktop SDL compatibility translation
unit. A temporary non-executing `bossEntry` reference must fail only after
linking the core and renderer archives; the 2026-08-03 map fell from 261 to 246
unique unresolved symbols and contained none of the 15 extracted GU names. The
reference was removed, both clean verifiers passed, and the no-ROM core probe
again reported `0x80c24316` sequentially on iPhone and iPad before uninstall and
shutdown.

The second startup-closure subgate adds 28 explicitly enumerated SDL-free leaf
units: native segment constants, trig/stdio compatibility and isolated gameplay
fidelity helpers. The final core probe must retain and execute `sins`, `coss`,
`aimBoneArg0Proceeds`, `watchInvPerspAspect`, and
`_rarewarelogoSegmentRomStart`. It reported the unchanged `0x80c24316` result
sequentially on iPhone then iPad, with uninstall/shutdown cleanup. A temporary
`bossEntry` map closed 61 symbols, introduced zero and left 185; the probe was
removed before the normal combined-renderer pass.

The mobile-configuration subgate must retain
`goldenpad_mgb64_mobile_config_probe` and `g_pcFovY` in both final core apps.
The unit supplies exactly the 68 settings/startup globals present in the prior
map while leaving SDL window/event ownership absent. Its expanded probe remained
`0x80c24316` sequentially on iPhone then iPad with complete cleanup. The
temporary startup map fell from 185 to 117 with zero newly introduced symbols,
then was removed before the clean renderer verifier.

The portable-service subgate requires the core archives to retain the complete
model/setup helpers and final apps to execute model cleanup, radial deadzone,
weapon cue, setup-null and stage-null probes plus native constants. The result
remained `0x80c24316` sequentially on iPhone then iPad with full cleanup. A
temporary `bossEntry` map closed 20 symbols, introduced none and fell from 117
to 97 before removal and the normal renderer pass.

The mobile-host subgate requires both archives to retain the OS/host probes,
`osSetTimer`, `osEepromLongWrite` and upstream overlay dispatch. The core probe
must block on a delayed timer, round-trip and restore EEPROM block 255, exercise
neutral host/watchdog state, and remain `0x80c24316`. A temporary `bossEntry`
map must close 27 symbols with none introduced, leaving 70, before removal and
the clean combined-renderer pass. The 2026-08-03 sequential no-ROM run passed at
1206x2622 on iPhone then 1668x2420 on iPad with uninstall/shutdown cleanup.

The permanent game-start gate requires both final apps to retain `bossEntry`,
`portAudioInit`, `portAudioFrame`, `goldenpad_mgb64_start_game`,
`goldenpad_mgb64_game_state`, `goldenpad_mgb64_set_controller_state`,
`goldenpad_mgb64_audio_render`, `alBnkfNew` and
`portAudioPlaySfxDetailed`, with no unresolved symbol or desktop dependency.
After a supported private ROM validates, the app must reach all readiness gates
and enter `bossEntry` exactly once.

The 2026-08-03 private-data proof ran strictly sequentially. iPhone 16 Pro first
rendered the real title/Rare/Bond animation and demo-stage setup through Metal at
2622x1206, decoded 261/261 SFX and 75 music instruments/138 sounds, and reported
`Native PCM output probe: PASS`. It also reported the deterministic mobile core
input probe as PASS. The app was terminated and uninstalled and the simulator
was shut down before iPad Pro 11-inch (M4) repeated the title animation, input
probe and PCM proof at 2420x1668, followed by identical cleanup. Screenshots and
ROM data remained ignored local evidence. Simulator output proves nonzero native
PCM delivery; a real-speaker and route/interruption pass remains a physical-device
gate.

Cold shader compilation can delay the first nonzero PCM beyond a fixed startup
instant. The app therefore polls the rendered-frame/nonzero-sample atomics once
per second for at most 30 seconds and emits exactly one terminal line:

```text
[GoldenPad] Native PCM output probe: PASS after Ns
```

Treat `FAIL timeout=30s` as a real gate failure. The 2026-08-04 strict pass used
exact Simulator binary
`2b83740c5fb394dd3ced14a25fd75bc76ba42a7c47468a6f1a2e8c22c15c102e`;
iPhone 16 Pro passed after 10 seconds, was removed and shut down, then iPad Pro
11-inch (M4) passed unchanged after 10 seconds and received the same cleanup.

### Controlled menu and mission-load gate

Use the combined Simulator build with a private ignored supported V64 and the
diagnostic argument below. The source file must live outside tracked/build
outputs; copying it into the installed app's temporary container is acceptable
only when the app is uninstalled after the run.

```sh
xcrun simctl launch --console-pty DEVICE_ID \
  com.chrissotraidis.goldenpad \
  --validate-rom /private/path/to/retail-game.v64 --menu-probe
```

`--menu-probe` reads an atomic snapshot published by the game thread and emits
one-frame Start presses through the ordinary touch snapshot and N64 controller
mapping. It must never invoke a front-end or stage-selection function directly.
Require authentic transitions through menus 0, 1, 2, 3, 4, 5, 6, 7, 8 and 10,
then menu 11, `active=33`, and `Menu probe controlled Dam load: PASS`.

The 2026-08-03 run passed first at 2622x1206 on iPhone 16 Pro. The app was
terminated and uninstalled and the phone was shut down before the identical app
passed at 2420x1668 on iPad Pro 11-inch (M4). Private `/tmp` screenshots were
inspected to confirm rendered Dam gameplay and the native touch overlay; no ROM
or game-derived image entered the repository. The iPad received the same full
cleanup. This completes G3, not mission-completion or touch-gameplay acceptance.

### Controlled gameplay-input gate

Launch the same private combined build with `--gameplay-probe`. This implies the
menu probe, waits for active Dam stage 33 and gameplay view mode, and then drives
only the normal normalized touch-to-N64 path. Its read-only game-state snapshot
is published from the game thread alongside `osContGetReadData`.

Require all of these lines without a `FAIL`:

- `Gameplay probe movement: PASS` with a nontrivial position delta.
- `Gameplay probe aim/look: PASS` with aim mode and angle delta.
- `Gameplay probe fire: PASS` with magazine `7->6`.
- `Gameplay probe reload/interact: PASS` with magazine `6->7`.
- `Gameplay probe weapon: PASS` with weapon `5->1`.
- `Gameplay probe pause: PASS` with nonzero watch/pause state.

The 2026-08-03 gate passed first on iPhone 16 Pro, then on iPad Pro 11-inch
(M4), using the exact same built app. Private visual inspection confirmed the
moved Dam view and open watch. Each app/container and temporary ROM copy was
removed and each simulator was shut down in strict sequence. This proves mapped
semantics, not physical touch/controller hardware, a context-sensitive door or
terminal interaction, crouch/objectives flow, or mission completion.

### Scripted mission-report and progression gate

Launch a clean install with `--mission-flow-probe`. This implies the menu probe
and waits for live Dam gameplay. It then makes one explicitly diagnostic request
that mirrors MGB64's existing scripted-success contract; it does not place or
complete objectives through play and must never be reported as organic mission
completion.

Require all of these lines without a `FAIL`:

- `Mission flow probe live Dam: PASS`.
- `Mission flow probe real status/save: PASS menu=12` with `completed=1` and a
  nonzero time.
- `Mission flow probe real statistics report: PASS menu=13` after normal A input.
- `Mission flow probe report navigation: PASS menu=7` after normal B input.

Next, background GoldenPad by launching another app and require
`Game EEPROM persisted atomically`. Terminate but do not uninstall. Relaunch the
same app and private temporary ROM with `--progression-probe`; require
`Game EEPROM restored from Application Support` followed by
`Progression relaunch probe: PASS Dam/Agent completed=1` with the same time.

On 2026-08-03 this passed first at 2622x1206 on iPhone 16 Pro, which was then
uninstalled and shut down. iPad Pro 11-inch (M4) repeated it at 2420x1668. Both
reported time `1023`, and the iPad received the same cleanup. This proves the
real report/save/relaunch seam only. Organic objectives and mission completion
remain open.

### Dam native multiwaypoint controller gate

First run MGB64's promoted clean route with a private ignored retail ROM:

```sh
python3 ref/mgb64/tools/campaign_route_smoke.py \
  --binary ref/mgb64/build-goldenpad-webgpu/ge007 \
  --rom /private/path/to/retail-game.v64 \
  --out-dir /tmp/mgb64-dam-native-route \
  --route dam_native_multiwaypoint_input_traversal --timeout 90
```

The pinned desktop run passed with 902 records, 4794.07 world units and no
setup automation. Launch the combined mobile app with `--dam-route-probe`. It
implies the authentic menu flow, waits for active Dam and `CAMERAMODE_FP`, then
publishes MGB64's four normal-controller input windows. Mobile retains the final
forward-left input for 20 additional frames to absorb iPad render-cadence loss;
the acceptance distance remains the upstream 4700 units.

Require `Dam native multiwaypoint controller route: PASS`, `distance>=4700`,
`objectives=4:[0,0,0,0]`, and `stateMutation=0`. The objective/camera snapshot
is read-only and the route must not force a transform, objective, stage, or
mission state.

The final strict run passed first on iPhone at 5038 units and then on iPad at
4784. Both objective vectors remained unchanged. Each installed app, private
ROM and container was removed and each simulator shut down before proceeding.
This is deep traversal evidence, not objective progress or mission completion.

### Dam live-waypoint/interlock controller gate

Launch a clean install with `--dam-nav-probe`. The probe implies the authentic
menu path and stock-spawn route above, then reads the loaded retail setup's
waypoint and switch-to-door graphs. A private breadth-first search publishes
only the next live target; Swift supplies ordinary movement, look and B input.
No transform, door, objective, stage or mission state may be written.

Require `Dam read-only nav controller route: PASS`, `distance>=15000`,
`destinationDistance<=500`, `objectives=4:[0,0,0,0]`, and
`stateMutation=0`. Run phone first, terminate/uninstall/shut it down, then install
the exact same app on iPad. The final strict run passed at
`distance=15917 destinationDistance=493` on iPhone and
`distance=15879 destinationDistance=499` on iPad. Both reported source 182 and
destination 179. This endpoint is the upper pad-140 region; it is not proof of
the disconnected lower bungee path or objective completion.

### Dam retail-bungee controller gate

Launch a clean install with `--dam-bungee-probe`. The host structurally derives
the lower exit pad from the loaded retail AI room-test, control-lock and
forced-velocity sequence. Navigation, linked-door, guard and padlock snapshots
are read-only; Swift emits ordinary controller frames, including one-read B
presses through the same `osContGetReadData` boundary.

Require `Dam retail bungee AI trigger: PASS`, the current room to equal the
derived bungee room, non-zero forced velocity, `controllerOnly=1` and
`hostMutation=0`. An exploratory phone run passed at `distance=28461`,
`pad=330`, `room=64/64`, `force=0,400` and objectives `4:[0,0,0,1]`. Promotion
remains open: repeated clean-phone runs stopped in the linked-door interlock at
`state=2 open=750/1000`, including through frame 14700. The phone was cleaned
up and iPad was not run because the phone-first gate failed.

### Facility controller-interaction gate

First verify the pinned MGB64 desktop contract with a private ignored retail ROM:

```sh
python3 ref/mgb64/tools/campaign_route_smoke.py \
  --binary ref/mgb64/build-goldenpad-webgpu/ge007 \
  --rom /private/path/to/retail-game.v64 \
  --out-dir /tmp/mgb64-facility-route \
  --route facility_spawn_obj159_door_traversal_contract --timeout 90
```

The 2026-08-03 desktop run passed with 762 records, a 1291.83-unit horizontal
delta, real object-159 allow/open/displace/finish events and no setup automation.
Keep its logs private because they come from a retail-ROM-backed run.

Launch a clean GoldenPad install with `--facility-door-probe`. This implies the
authentic menu/Dam flow, uses the explicitly scripted Dam result only as a
prerequisite, presses normal A through both report screens, reaches Facility's
real briefing and presses Start. The controller route must not begin until the
game reports `CAMERAMODE_FP`.

Require `Facility door probe stock spawn: PASS` followed by
`Facility door probe controller interaction: PASS`, with `open=90000`,
`max=90000`, `sawOpening=1`, `finishedOpen=1`, and at least 680 world units of
horizontal displacement. The route publishes only normalized movement, look and
B frames; its game snapshot is read-only and it never forces a transform, door,
objective or stage state.

On 2026-08-03 the same built app passed first on iPhone 16 Pro and then on iPad
Pro 11-inch (M4). Each reported a 702-unit displacement and a fully open door;
each app and private temporary ROM was removed and each simulator shut down
before proceeding. This closes the simulator context-interaction subgate. It
does not claim the desktop route's later 1200-unit milestone, Facility objective
completion, touch hardware, or organic mission completion.

For the next chained-interaction gate, first run the upstream route
`facility_spawn_obj159_obj155_door_chain_contract`. The 2026-08-03 desktop run
passed with 1402 records, 1291.82 units of movement, both door models opened and
no setup automation. Then launch GoldenPad with `--facility-door-chain-probe`.
Require `Facility door chain probe controller interaction: PASS` with both the
model-159 fields and `door155Open=90000`, `door155Max=90000`,
`door155SawOpening=1`, and `door155FinishedOpen=1`.

Do not reuse the upstream second-leg left input blindly: under mobile timing it
opens a different model-155 door. The mobile route observes only model 159 at
setup pads 67/68 and model 155 at pad 75. After the first-door stream it uses
fixed backward movement on frames 700–739, then a right-stick sweep on frames
740–959 with four-frame B pulses every eight frames through 956. This is still
normal controller input; the snapshots never steer or mutate game state.

The same built app passed first on iPhone at 817 world units and then iPad at
827, with both exact door targets fully open. Each app/private ROM was removed
and each simulator shut down in strict sequence. This proves a second normal-
input interaction and deeper corridor traversal; it still does not prove
Facility objectives or organic mission completion.

## RT64 mobile Metal and static-library gate

With the exact RT64 and Plume commits from `RESEARCH.md` initialized under
ignored `ref/rt64`, run:

```sh
./scripts/verify-rt64-ios-metal.sh
GOLDENPAD_RT64_ARTIFACT_DIR="$PWD/build-rt64-static" \
  ./scripts/verify-rt64-ios-static.sh
```

The scripts refuse dirty or mismatched target sources, temporarily apply their
tracked patches, and reverse them on exit. The fast probe must produce 56
metallibs for each mobile SDK, patched ARM64 Plume archives for each, and a
successful macOS Plume regression build. Expected stable aggregate digests are:

- `iphoneos`: `04c7eb0f7719dc27ea3f4ca4b2f95fc7bb5a59837c1c77af68ce421d081cc838`
- `iphonesimulator`: `7b9a5a185799bd8bda7f7e2b25fe4bcb18223200cf14df781c442441f93f2212`

The full verifier must report, for both SDKs, 210 RT64 archive members, 246
force-loaded closure members, ARM64, and dependencies limited to expected Apple
frameworks/runtime libraries. It rejects SDL, NFD, AppKit, IOKit, X11 and macOS
Vulkan-surface symbols.

Configure the opt-in linked app using `BUILDING.md`, then run strictly iPhone
first and iPad second. Require visible `renderer: RT64 Metal DEVICE WIDTHxHEIGHT`
status, terminate/uninstall/shut down the phone, and only then repeat on iPad.
The 2026-08-03 pass reported `Apple iOS simulator GPU` at 1206x2622 and
1668x2420 respectively. A Release `iphoneos` linked app also built as ARM64.
This satisfies G2; GoldenEye frames begin at G3 and remain core-gated.

## LAN netplay diagnostic gate

This gate is research-only and never promotes the accepted Preview by itself.
The authoritative current result and restart procedure are in
[`NETPLAY_PHYSICAL_CHECKPOINT_2026-08-28.md`](NETPLAY_PHYSICAL_CHECKPOINT_2026-08-28.md).

Before Simulator or device work:

```sh
scripts/verify-lan-netplay-protocol.sh
python3 scripts/compare-recomp-determinism-traces.py --self-test
git diff --check
scripts/check-no-rom-data.sh
```

Keep at most one Simulator booted. The host companion must prove encrypted
discovery, Player 2 assignment, ready/start/runtime-ready/go, monotonic ordered
frames, exact N+4 input responses, bounded lead, and fail-closed peer loss.
Compare immediate and delayed logs with
`compare-lan-netplay-checksum-logs.py`; a passing Simulator run does not replace
the physical cross-device gate.

Before every physical installation, privately copy and hash the LAN Lab
preferences, converted ROM, active save, backup save, and Documents runtime
ROM. Install in place, copy them back, and require byte-for-byte pre/post
agreement. Never commit those files or their private save/preference hashes.

Physical v3 evidence is a failure at frame 30: Player/Prop hashes matched,
global hashes differed, and the runtimes were one bootstrap VI apart. No new
crash reports appeared and both processes remained live. The next valid run is
protocol v4 with all 19 canonical global values logged at frame 1 and frame 30.
A v4 repair passes only when different local barrier VI counts retain identical
individual global words and component hashes through at least frame 1,020.

## Converted ROM storage and backup gate

GoldenPad currently keeps the protected, backup-excluded Documents runtime
image and a second librecomp-managed copy under
`Application Support/GoldenPadRecomp/<game_id>.z64`. Before TD-12 closes:

1. import through the normal picker and verify both copies by size/hash without
   printing or exporting their bytes;
2. verify both files carry the intended data-protection class and are excluded
   from device/iCloud backup;
3. relaunch and prove the runtime still selects the same validated data;
4. perform an in-place update and prove both files, active save, backup save,
   and preferences remain byte-identical; and
5. rerun the IPA/package audit to prove neither copy entered the artifact.

Do not delete or relocate an existing user copy as part of a documentation or
attribute-only repair. Migration must be atomic and preservation-tested.

## Package gate

Every IPA test must unzip into a fresh temporary directory, enumerate members,
run the contamination policy from `LEGAL.md`, and prove the app cannot play
without user-selected retail data. Record hashes of project-owned artifacts only.

The current game-bearing package gate is:

```sh
./scripts/verify-source-license-manifest.sh
./scripts/package-unsigned-ipa.sh
./scripts/verify-unsigned-ipa.sh --game-core \
  dist/GoldenPad-0.1.0-unsigned.ipa
```

The verifier rejects ROM/save/signing path names, all three N64 byte-order magic
headers, the supported retail SHA-1, a signed app, non-ARM64 code, and private
developer/reference strings. Game-core mode additionally requires MGB64's game
entry point, the native Fast3D/Metal renderer entry points and the bundled
third-party notices. It also prints a sorted-content digest independent of ZIP
metadata.

Commit `2bc7920` historically produced byte-identical working-tree and
fresh-clone IPAs. The current notice-bearing commit `09e02a0` was built in two
independent fresh clones; both passed every audit, but optimized Swift codegen
produced two equivalent executable layouts. Their IPA/content digest pairs were
`6991d7197f8476946de2d7cff0aba2d684ee4880ca68bcbdd0c8f95513ce744f` /
`c9d10678c497d10c6738e88bba423ee81dce423d1d08acb58c893980901422d4`
and
`7a225bd8cca26c50674eefeeb222c46767aaeb452480a9a28ac080c49da1624b` /
`83221d7b66763e9fbddad64e264477d03c91dae54f7ae6f49ee5e93ffd677671`.
That historical mismatch reopened the packaging gate. A new current-state run
at commit `94242be` built the complete Simulator/device closure and packaged the
app independently under two different clean checkout paths. Both device
executables matched SHA-256
`43bfe1b5a0cfe46b16f48eeb33130ab3efd36bb1a1521adeba3db0277c91f389`.
Both nine-member IPAs were byte-identical at SHA-256
`6eed064c79ca7a9ebedb6a3cb2f4a5d97a8cd0ab426fa9503e94db535c3c738d`,
with sorted app-content SHA-256
`aed6b2725e2deac8cddb7c0901dca2d385f6966474125bdb5d5f1a628e408a6c`.
Each checkout independently passed the source-manifest, ARM64, unsigned,
game-core symbol, notices, private-path and ROM-contamination audits. This
closes P2 for the current source state while retaining the older contrary result
as historical evidence.

The public-handoff commit `f6d33ee25d5abc05900c02ab5b483d643b085f31`
was then cloned with `--no-local` into a new temporary path. That clone fetched
MGB64 from GitHub at the exact pin, built both complete SDK closures, restored
the ignored upstream checkout, packaged the nine-member IPA, resolved every
tracked Markdown link and README image, and ended with no tracked changes. It
reproduced the same Simulator executable `818f1733...91a0`, device executable
`43bfe1b5...f389`, IPA `6eed064c...c738d`, and sorted content
`aed6b272...08a6c`. The temporary clone was deleted after the pass. This proves
the source handoff on another clean path; signing still requires the receiving
Mac's own Apple identity, team and connected iPad.
