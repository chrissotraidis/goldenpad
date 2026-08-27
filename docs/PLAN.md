# Plan

This plan is evidence-gated. A milestone is complete only when its acceptance
gate passes and evidence is recorded in `STATUS.md` and `WORKLOG.md`.

## Selected codebase

Primary runtime: GoldenEye64Recomp's statically recompiled game code,
N64ModernRuntime and RT64/Metal, with exact revisions and private generated-input
boundaries recorded in `RT64_N64RECOMP_PROTOTYPE.md`. MGB64 remains the
deprecated `GoldenPad Legacy` fallback. Matching-target Nintendo/SGI/Rare SDK
implementation sources remain excluded.

The native Apple-Silicon macOS extension is a separate gated product track. Its
research decision, architecture and implementation gates are recorded in
[`MACOS_NATIVE_FEASIBILITY_2026-08-21.md`](MACOS_NATIVE_FEASIBILITY_2026-08-21.md).

## Current execution plan (2026-08-27)

Preview 8 is the accepted mobile baseline. It adds one optional duplicate Fire
control, disabled by default, with independent persisted layout values and
multi-touch aggregation. Build `8` passed physical iPadOS acceptance,
preservation checks, input tests, and deterministic packaging while retaining
Preview 7's iOS 17 Metal target. The Mac Alpha remains Preview 7 and is
byte-identical to Preview 6.

Relative sizes are scope indicators, not calendar promises: **S** is one bounded
seam/probe, **M** crosses a game/host or generated-patch boundary, **L** adds a
subsystem plus physical matrix, and **XL** adds a supported network product or
service.

| Work | Size | Primary risk |
| --- | ---: | --- |
| Preview 7 compatibility promotion | Complete | Production identity, Metal-target provenance, and preservation regression |
| Optional second touch Fire button | Released in Preview 8 | Layout persistence, overlapping touch targets, or duplicated/latched Fire input |
| TD-01 sustained-player measurement | Complete | Three physical-iPad Phantom magazines were identical at 20 events over 58 ticks |
| TD-02/issue #8 controller verification | S | Touch is reporter-confirmed; physical controller result remains pending |
| TD-01 authenticity patch | Released in Preview 5 | Retain its isolated rollback and evidence boundary |
| TD-07 disconnect neutralization/probe | S | Regresses normal touch/controller P1 publication |
| TD-14 modal/run-loop neutralization | S | Replayed input or menu/watch regression across presentation boundaries |
| TD-03 A12 evidence | S | Hardware/artifact availability; repair size remains unknown |
| TD-04/TD-05/TD-06 physical classification | S each | Instrumentation changes timing or logs the wrong boundary |
| TD-09 Mac-only edge repair | S | Renderer coverage regression; keep it independent from Preview 4 input |
| TD-12 storage/package hygiene | S | User-data migration or backup attributes damage a valid runtime copy |
| TD-13 game-bearing build proof | S-M | Private inputs make provenance checks environment-dependent |
| Production 2–4 controller ownership | L | Device identity/lifecycle and touch ownership interactions |
| Two-device deterministic LAN experiment | L | Simulation divergence despite working transport |
| Public internet multiplayer product | XL | Synchronization, service, security, reconnect, operations, and support |

### Wave 0 — freeze evidence and scope

Status: **complete for Preview 4 identity and Preview 6 release; terminal-only
revalidation required before each repair phase**.

- The exact source, package, release executable, physically accepted control,
  and rollback hashes are frozen in
  [`PREVIEW_4_BASELINE.md`](PREVIEW_4_BASELINE.md).
- `TECH_DEBT.md` owns priority and evidence state; `TESTING.md` owns closure
  gates; `STATUS.md` owns current results.
- Every implementation change receives one debt ID and an independent rollback.
- No ROM, save, preference, signing, generated AOT, or unrelated Android work is
  changed by these repairs.

### Wave 1 — measurement plus the smallest user-facing repairs

Execute and land these as separate review units:

| Order | Work package | Why now | Required output | Promotion gate |
| ---: | --- | --- | --- | --- |
| Complete | **Preview 7 production promotion** | Issue #19's affected iPhone passed the bounded iOS 17-target diagnostic | Production bundle build `7`, audited IPA and byte-identical Preview 6 Mac archive, preserved-data readback, and hands-on iPadOS/Mac acceptance | PASS: exact artifacts passed twice, published assets matched locally, and no unrelated behavior changed |
| Complete | **Preview 8 optional second Fire** | User-requested duplicate Fire surface | Default-off control, independent saved layout, aggregated Z state, build `8`, and audited IPA | PASS: focused tests, in-place preserved-data install, and physical iPad acceptance |
| 1 | **TD-01 sustained-player probe completion** | Complete; player magnitude now distinguishes the current cadence from the authentic target | Three ordinary-input Phantom magazines each recorded 20 events in 58 ticks, normalized to 34.4828; retained guard evidence is 13/17/18 per 100 ticks | PASS: three identical player numbers, matching ammo deltas, no gameplay-state writes, and protected data preserved |
| Parallel user-facing lane | **Issue #8 and #19 release verification** | Issue #8 touch is positive and issue #19's diagnostic is positive | Issue #8 controller result and issue #19 production Preview 7 result | Do not close either report beyond the behavior its reporter actually verified |
| Parallel evidence lane | **TD-03 A12X crash artifact/reproduction** | High-severity compatibility report, but no safe patch exists without affected evidence | Full redacted `.ips`, current Preview 4 reproduction, original-signature comparison, and affected/newer device comparison | First failing RT64/Metal boundary isolated or deliberate tested support-floor decision |

Reporter confirmation and A12 evidence work can proceed without changing
accepted Preview 8 controls. Preview 8 is the mobile baseline; keep TD-14/TD-07
behavior changes as separate later candidates. Follow
[`TD01_FIRE_RATE_LOOP.md`](TD01_FIRE_RATE_LOOP.md) for the completed measurement,
repair, acceptance, and rollback record. Any later input change must
be reviewed separately from controller-lifecycle work because both touch input
publication.

### Wave 2 — major behavior and reliability corrections

1. **TD-01 authenticity patch:** released in Preview 5 from the completed baseline.
   The shared positive player/guard automatic-rate getter is scaled by three;
   zero and negative classifications are unchanged. Deterministic, generated-
   patch, input/tank, platform-build, exact Phantom cadence, and hands-on core-
   controls gates pass. No complete candidate guard
   window or explicit PP7 sequence was logged; retain that evidence boundary.
2. **TD-14 modal/run-loop neutralization:** add the failing held-input boundary
   gate, neutralize settings/share presentation, and prove watch/pause plus
   scroll tracking cannot replay latched input.
3. **TD-07 disconnect neutralization and lifecycle probe:** rebase only the
   smallest proven containment seam, add held-input suspend/resume coverage,
   and physically accept it before implementing real controller slots.
4. **TD-04 lifecycle classification:** run the physical transition matrix with
   existing bounded signals, then instrument only the observed wait class.
5. **TD-05 audio evidence:** correlate one audible physical event with the
   counter series. The exact 22,050 Hz chain rules out rate mismatch; use the
   ROM-free signal only for counter-invisible discontinuities.
6. **TD-06 physical flicker capture:** fixed player order is rejected; the zero
   `formatChanged` signal remains inconclusive without known-active calibration
   and non-format upload counts. Identify the first affected physical frame
   before more renderer work.
7. **TD-12/TD-13 hygiene:** repair runtime-copy attributes and add game-bearing
   build provenance as independent non-gameplay work packages.

These packages may gather evidence concurrently, but behavioral repairs land
one at a time against a freshly accepted baseline.

### Wave 3 — platform hardening

- Resolve TD-03 on affected A12 hardware or publish an evidence-backed support
  floor.
- Keep Preview 4's shared input mapping and Preview 3's accepted Mac relative-
  input repair frozen. Take a TD-09
  trailing-edge mask only after fixed-scene captures isolate the strip.
- Reduce each stage/effect report under TD-10 to one deterministic camera,
  stage, settings, and expected-reference case before changing game or renderer
  code.
- Re-run preservation and package checks after any dependency or generated-patch
  update.

### Wave 4 — multiplayer readiness and network decision

1. Implement stable primary-runtime controller slots only after Wave 1's
   lifecycle invariants exist.
2. Physically accept real two-, three-, and four-controller ownership on mobile;
   accept a separate no-touch Mac policy.
3. Define a stable frame number and compact state hash; prove repeated local
   deterministic matches.
4. Run the bounded two-iPad LAN input/hash experiment.
5. Decide whether GameKit, direct P2P with relay fallback, or no network product
   is justified. Rollback remains blocked until complete state serialization and
   restore are proven.

The network go/no-go gate is in
[`MULTIPLAYER_ROADMAP.md`](MULTIPLAYER_ROADMAP.md#network-gono-go-gate). No
discovery, matchmaking, relay, or public online UI begins before it passes.

### Anti-stall and stop rules

- If the unchanged baseline fails a new gate, stop and classify environment,
  stale generated inputs, or a real regression before implementing the fix.
- If a diagnostic contradicts the leading hypothesis, update `TECH_DEBT.md` and
  choose the next discriminator; do not force the planned patch.
- If a candidate changes an unrelated accepted surface, revert or split it.
- If required physical hardware or a reporter artifact is unavailable, keep the
  item open and advance an independent work package rather than guessing.
- Do not weaken acceptance criteria to make networking, a release, or a support
  claim appear complete.

### Completion criteria for this plan

This plan is complete only when:

- TD-01 and TD-02 are closed with objective and hands-on evidence;
- TD-03 has either a verified repair on affected hardware or a deliberate,
  tested, consistently documented support floor;
- TD-04 through TD-06 have been reproduced/classified with their discriminating
  evidence, and any justified repair has passed its physical gate;
- TD-07 supports stable real local controller ownership and TD-14 closes modal,
  pause, and run-loop neutralization on the claimed platforms;
- TD-12 storage/backup hygiene and TD-13 game-bearing build proof pass without
  weakening private-data or reproducibility boundaries; and
- the network go/no-go decision is recorded from determinism and LAN evidence,
  even if the correct product decision is **no network multiplayer**.

## Historical foundation milestones

The following R–P milestones preserve the project's original bring-up and
release evidence. Completed boxes are historical facts; open boxes do not
override the current execution plan above.

### R — Research and provenance

- [x] R1: protect ROM/reference/build/signing paths with `.gitignore`.
- [x] R2a: inventory decomp, static-recomp, runtime, renderer, macOS and touch
  candidates with exact commits/licenses.
- [x] R2b: record GoldenRecomp's irreducible public-input blocker and select the
  reproducible MGB64 native source surface.
- [x] R3: produce a source-level license manifest for every incorporated file.

Gate: no private/leaked/XBLA source, no proprietary SDK implementation in the
native target, and a pinned retail-ROM-to-runtime recipe.

### D — Native desktop baseline

- [x] D1: compile a native ARM64 Apple Silicon candidate.
- [x] D2: validate retail-ROM normalization/loading and visible mission render.
- [x] D3: validate audio initialization and persistent config path.
- [ ] D4: interactively validate menus, input, save/relaunch and mission progress.
- [ ] D5: start and complete a local multiplayer match.
- [x] D6: make the selected production core's public ROM-free tests clean.

Gate: selected core, not just the oracle, completes a mission and multiplayer.

D6 passes against the exact public-export surface GoldenPad consumes. A narrow
maintained patch makes upstream's release guards compatible with macOS Bash 3,
uses the existing portable timeout helper, and keeps tests that directly import
export-ignored fidelity tooling on that same internal-only side of the boundary.
The clean exported checkout builds and reports 100% passed across 103 CTest
entries; 10 ROM/browser/optional-binary cases skip explicitly. This closes core
test infrastructure, not the D4/D5 mission and multiplayer acceptance gates.

### A — Apple application shell

- [x] A1a: create one native SwiftUI/UIKit iPhone+iPad application target.
- [x] A1b: add the guarded shared MGB64 core library and host probe bridge.
- [x] A2: render an original Metal clear frame on iPhone simulator.
- [x] A3: stop iPhone; render on iPad simulator; compare logs and layout.
- [x] A4: implement typed Files picker/Open In, byte-order normalization and
  SHA-1 validation.
- [x] A5: persist cache/settings/saves under sandbox-safe paths.
- [x] A6: implement lifecycle and audio-session transitions.

Gate: both simulators handle valid, missing and invalid ROM flows and relaunch.
This gate passes: valid V64 from a real Files-origin open event, native
Files-picker open/cancel, settings/save relaunch, missing-file rejection and a
synthetic 12 MiB wrong-hash rejection were driven sequentially on both;
invalid-size rejection also passed on iPad.

A5 now passes with versioned/clamped settings, bounded atomic save slots, data
protection and terminate/relaunch verification. A6 passes its host gate: Home
backgrounding deactivated the audio session and foreground return reactivated it
at 48 kHz on both simulators. Real-core interruption/route acceptance remains G5.

### G — Game integration

- [x] G1: compile MGB64's audited game core for Apple ARM64 simulator/device.
- [x] G2: parameterize RT64 Metal shaders/surfaces for iOS.
- [x] G3: title, menus and mission load render correctly.
- [ ] G4: complete one mission with correct audio and persisted save.
- [ ] G5: background/foreground and audio route/interruption recovery.

Gate: full mission completion after clean install and ROM import.

G1 passes: all 135 MGB64 game translation units, 70 explicit upstream native
system/portable units and five project-owned mobile adapters compile into
210-object ARM64 archives for both mobile SDKs. Release app binaries link real
upstream random-core and GU math code, and the same
deterministic probe ran sequentially on iPhone and iPad without ROM data.

G2 passes: all 56 RT64 Metal shaders compile for ARM64 `iphoneos` and
`iphonesimulator`; the embedded build replaces desktop window, NFD and inspector
ownership with narrow host shims; and the complete 210-object RT64 archive plus
its 246-object closure force-links without desktop symbols. The linked GoldenPad
app created the real Plume Metal device, command queue and swapchain on iPhone
and iPad simulators.

The first G3 renderer subgate also passes: MGB64's full native Metal backend and
three support units compile into four-object ARM64 archives for both mobile SDKs
after two macOS-only display-sync assignments are guarded. The second subgate
passes too: the Fast3D interpreter, room-normal helper, screenshot and texture
units compile into five-object
ARM64 archives for both SDKs without SDL/OpenGL symbols, and sequential iPhone
then iPad launches prove the exact `platformGetMetalLayer` handoff from UIKit.
The third subgate now passes: both closures link in final ARM64 apps and the real
MGB64 backend encodes/presents UIKit-timed ROM-free empty frames on both device
classes. The private
loader subgate now passes too: exact-SHA-1 normalized bytes enter only a
core-owned volatile buffer, with sequential phone/tablet proof and container
removal. File-table patching now passes too: upstream native offset/placeholder
units link for both SDKs, known background and Dam entries are verified inside
the owned buffer, and sequential phone/tablet runtime logs confirm readiness.
The scheduler bootstrap subgate now passes too: the real upstream scheduler,
message queues and graphics client initialize through an SDL-free mobile OS
adapter in both final SDK binaries, with sequential phone/tablet runtime proof.
MTKView-driven cooperative frame delivery now passes as well: it queues one
retrace only when the graphics queue is empty, and sequential phone/tablet logs
prove delivery without queue growth. The portable `bossEntry` boundary now
links with no unresolved symbols and starts once on a detached game thread after
ROM, file-table, scheduler and renderer readiness. Its first closure slice
isolates 15 real GU helpers from
the desktop compatibility unit; the temporary force-link map dropped from 261
to 246 unresolved symbols with no GU blocker remaining. The next 28-unit
SDL-free leaf slice closes another 61 with no new unresolved dependency, leaving
185. Mobile-owned settings/startup defaults then close all 68 `g_pc*` names from
the SDL platform owner without importing it, leaving 117.
Real model/stage/radial/setup/weapon service modules plus native legacy data then
close 20 more without a new dependency, leaving 97.
Thread-safe queue/timer semantics, volatile EEPROM, neutral mobile host services
and real portable overlay hooks close another 27 without introducing a name,
leaving 70. Native settings, trace/decor/texture/audio services then close the
remaining boundary without importing the excluded desktop/SDK owners. The real
title sequence and demo-stage setup now render through Fast3D/Metal sequentially
on iPhone and iPad, the MGB64 synth feeds a bounded native PCM ring, and Swift
input reaches `osContGetReadData`. G3 is complete: a diagnostic script emitted
real one-frame Start input through that same boundary, traversed menus
0/1/2/3/4/5/6/7/8/10, selected Agent/Dam, reached run-stage menu 11 and observed
active stage 33. Live Dam gameplay rendered sequentially on iPhone and iPad
before full cleanup. The game EEPROM also restores from and flushes atomically
to Application Support; exact 2 KiB relaunch probes passed on both classes.
An intermediate diagnostics-only gate now mirrors MGB64's scripted success
contract after live Dam starts, then leaves the authentic game path to write the
save and render mission-status/statistics menus 12/13. Normal A/B input traversed
those reports, and `completed=1 time=1023` survived lifecycle flush plus relaunch
on iPhone and iPad. This isolates the remaining G4 work to organic objectives and
mission completion; the scripted gate does not complete G4.
The next controller-only acceptance slice used that scripted Dam result only to
reach the authentic Facility briefing. After normal Start input and the real
first-person camera transition, the route opened Facility door model object 159
fully and moved 702 world units on iPhone followed by iPad. This proves a real
world interaction, not Facility objectives or organic mission completion.
The promoted two-door extension identified model object 155 at exact setup pad
75. Mobile timing required a fixed backward continuation plus a right-stick/B
view sweep after the first door. iPhone reached 817 world units and iPad 827;
both opened pads 67/68 and pad 75 fully. No transform, door, objective or stage
state was forced.
MGB64's separate clean Dam multiwaypoint route now also runs through the mobile
controller boundary. GoldenPad waits for real first-person control, replays the
promoted input sequence with a bounded iPad-cadence tail, and preserves the
upstream 4700-unit gate. iPhone reached 5038 units and iPad 4784 while the
read-only four-objective vector remained `[0,0,0,0]`. This is a bridge toward
organic objectives, not objective progress itself.
The next read-only navigation slice now derives a breadth-first route and Dam's
two linked gate controls from the live retail setup. Normal controller movement
and B input crossed both interlock doors and reached upper-graph node 179 within
500 world units: iPhone passed at 15917 units and iPad at 15879, with the same
`[0,0,0,0]` objective vector and `stateMutation=0`. The destination is the
upper pad-140 region, not the disconnected lower bungee graph; organic bungee
activation remains the next Dam traversal gate.

An exploratory lower-route run has now reached that retail bungee trigger. The
host structurally derives the target pad from the loaded AI room-test,
control-lock and forced-velocity sequence, reads navigation, guard, padlock and
linked-door state without writing it, and emits ordinary controller frames. It
observed `room=64/64`, `force=0,400`, objective vector `[0,0,0,1]`,
`controllerOnly=1` and `hostMutation=0`. This is not promoted acceptance:
the original linked-slab stop has been crossed in a clean phone run, but the
live guard can still kill Bond during the second interlock before bounded
obstruction recovery starts. Phone cleanup was performed; the exact same app
was not advanced to iPad because the phone-first gate failed.

Diagnostic routes stop here. They remain launch/input smoke coverage, not a
product milestone and not a substitute for a person playing the game. The
production loop now prioritizes human touch feel, the editable phone/tablet
layouts and the native Apple settings/menu surface. Organic mission completion
will be accepted through hands-on touch and controller play.

### I — Input and touch

- [x] I1: common normalized input snapshots for touch and controllers.
- [ ] I2: N64-equivalent controls plus complete modern dual-stick FPS semantics.
- [x] I3: movable/resizable/opacity-adjustable phone and tablet layouts.
- [x] I4: touch editor, persistence, safe areas and sensitivity/dead zones.
- [ ] I5: validate menu, aim, fire, reload, interact, crouch, weapon, pause and
  objectives flows.
- [ ] I6: accept physical gyro behavior on supported devices.

Gate: a mission is completable with touch alone and with a physical controller.

I1, I3, and I4 are core-connected: exact libultra masks, modern/southpaw
touch/look input, controller Player 1, touch/controller diagnostic merge, and
independent phone/tablet layouts were exercised through the real primary-runtime
boundary and accepted on physical iPhone and iPad hardware. I2 remains open
because modern MOVE horizontal still follows the original turn behavior rather
than strafing; original C-button mode and modern menu behavior must remain
separate. The editor persists dragged
positions, per-control scale and global opacity while clamping controls to the
safe area. Physical gyro remains a separate open gate. The v4 modern defaults use a broad direct-swipe
look surface whose deltas accumulate until they are consumed once, larger
movement/action targets and
one contextual Action control instead of duplicate B-based Use/Reload buttons.
Southpaw mirrors the action
rail away from its right-side movement stick. Action/Fire/Aim occupy the outside
rail while Weapon/Duck use a lower utility row. Phone defaults now keep both
groups clear of the rounded edge and home-indicator strip. The maintained binary
was inspected sequentially on phone and tablet simulators. The in-game
gear now opens a native settings hub with Touch Controls, Controllers and Display detail
pages; the device-specific layout editor sits beneath Touch Controls instead of
being the entire settings experience. Display persists explicit 1×, 2×, 3× and
4× game-scene resolution while leaving native SwiftUI controls sharp; 1× is the
performance-first default. The Performance HUD is off by default and opt-in
from Display. Modern touch AIM now
defaults to a persistent toggle so the look thumb does not have to hold one
button while dragging elsewhere; Hold remains available in Game Settings. The
layout editor is placement-only, avoiding a second copy of behavior settings.
Opening the native settings sheet now neutralizes touch input and suspends the
UIKit presentation/retrace clock until dismissal; scene inactivity remains an
independent pause reason. I5 now has strict
sequential game-state proof for
movement, modern look/aim, fire, B reload/action, A weapon cycle and Start
pause/watch. It also has strict sequential proof that normal controller movement,
look and B input opens two chained stock Facility door models. Crouch, objectives
flow and organic mission completion remain open. The downstream report and
persisted-save path is independently proven through an explicitly scripted
diagnostic trigger. A separate clean Dam probe now proves more than 4700 units
of controller-only stock-spawn traversal on both simulator classes without
changing any objective state.
When enabled, the FPS HUD is backed by monotonic timing at MGB64's actual game
display-list submission boundary, not the previous all-zero stub or every
`MTKView` callback. A strict same-binary run distinguished both 60 Hz displays
from 51.8 FPS on iPhone and 21.8 FPS on the higher-resolution iPad workload.
Touch input no longer passes through both Swift and
MGB64 dead zones, and the mobile look curve is linear. Mapping and telemetry
are proven; final sensitivity and action-placement acceptance remains a
hands-on real-play task.
Physical face buttons are now isolated at the N64 boundary: A/Y produce only A
and B/X only B, fixing a prior A+B collision. The linked diagnostic passed and
the compact mapping reference was inspected on phone and iPad. Real-controller
comfort and multiplayer assignment acceptance remain I4/M1 hardware gates.

Exact Simulator binary
`c71c1630c4930bf60eb2827373025a1fe0431b6b364c53ca0155fa46b45d6681`
live-switched all four resolution levels on both device classes. Phone targets
were 874×402, 1748×804, 2622×1206 and 3496×1608; iPad targets were 1210×834,
2420×1668, 3630×2502 and 4840×3336. This closes the settings/wiring slice, not
the performance gate: truthful produced-frame samples vary materially by scene.
An eight-second cold profile showed the whole sampled game thread under runtime
Metal shader compilation, so the early 4.9/7.8 FPS windows are not steady-state
results. A warm profile then identified repeated Metal upload-texture allocation
as the first sustained bottleneck. The maintained patch now recycles textures
only after their three-frame semaphore slot completes: allocation samples fell
from 811/3,217 to 76/3,662 while 3,141 post-change samples were normal retrace
sleep. A terminate/relaunch profile then found only 2 of 3,702 game-thread
samples in synchronous shader creation because Metal's automatic per-app cache
was active. Remaining Simulator time was primarily its XPC texture-upload path;
do not treat that as a device bottleneck. First-install cost, sustained cadence
and physical-device acceptance keep the performance gate open.

### M — Multiplayer

- [ ] M1: deterministic controller assignment and touch coexistence.
- [ ] M2: complete two-player local split-screen match.
- [ ] M3: validate three/four players and iPad viewport/aspect layouts.

Gate: four-player iPad match where core support allows it.

M1 now has a substantial Simulator subgate: the Controllers page shows the
four player slots and deterministic swapping for the **legacy MGB64** target.
That work is a design reference, not evidence that the primary RT64/AOT host has
multi-controller ownership. The primary host binds one real extended controller;
its two-player mode is controller P1 plus touch P2, and its four-player mode
advertises neutral P3/P4 ports only for rendering diagnostics. M1 therefore
remains open pending a primary-runtime lifecycle probe and physical two- to
four-controller acceptance.

Preview 2 completed the bounded M2/M3 rendering repair: physical four-player
video kept all quadrants coherent without the former large black/checkerboard
corruption. Slight lighting flicker and real P2–P4 controller ownership remain
open, so local multiplayer is still experimental. Network play is a later
program with determinism, compatibility-handshake, synchronization, transport,
and adverse-network gates in [`MULTIPLAYER_ROADMAP.md`](MULTIPLAYER_ROADMAP.md);
it must not be bundled into local ownership or renderer work.

### P — Package and publish

- [x] P1: original neutral icon at every required size.
- [x] P2: byte-reproducible unsigned IPA from independent clean checkouts.
- [x] P3: archive contamination scan proves no ROM/assets/secrets/private paths.
- [x] P4: sequential iPhone then iPad acceptance matrix; record device-only gaps.
- [x] P5: README/docs match observed behavior.
- [x] P6: staged-file audit, coherent commits, push, and remote verification.

Gate: all definition-of-done items are passed or a specific external hardware or
upstream gate remains open with reproducible evidence.

Preview 2 packages the primary GoldenEye64Recomp/N64Recomp/RT64 runtime as an
unsigned, user-re-signable ARM64 IPA. The verifier requires primary-runtime and
in-app importer symbols, rejects MGB64 symbols, and scans for ROMs, saves,
signatures, known retail headers and private paths. It also requires the complete
third-party notice and license set. The audited archive is
`GoldenPad-0.1.0-preview.2-unsigned.ipa`, SHA-256
`704bdf68f67d1f0925fd1844ab865c263a79e105a6349ef410f365602e6c77e3`.

The exact signed candidate was installed in place on the connected iPhone and
iPad as build 2 without changing either app container or any ROM, save, or
preference payload. It launched successfully, received hands-on gameplay
approval, and Preview 2 was published. Local multiplayer ships only as an
experimental render baseline with residual flicker and real Player 3/4 routing
disclosed. The native arm64 Mac app is packaged separately as Alpha.

## Test rhythm

For meaningful mobile changes, keep automated diagnostics bounded, validate the
relevant simulator class, then perform hands-on acceptance on the affected
physical device. Build, install, PID and log evidence do not substitute for
touch, controller, audio, lifecycle or gameplay acceptance.
