# Testing

## Evidence levels

1. **Static:** provenance, contamination and archive inspection.
2. **Build:** exact architecture/SDK and clean-checkout compile.
3. **Runtime:** logs plus framebuffer/UI evidence.
4. **Interaction:** real menu/gameplay input and state transition.
5. **Acceptance:** mission/match completion, persistence and relaunch.

A lower level never substitutes for a higher one.

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

Do not publish screenshots containing copyrighted game imagery.

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
