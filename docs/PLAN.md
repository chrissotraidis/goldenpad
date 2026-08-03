# Plan

This plan is evidence-gated. A milestone is complete only when its acceptance
gate passes and evidence is recorded in `STATUS.md` and `WORKLOG.md`.

## Selected codebase

Production-core candidate: MGB64's original-retail-N64 decompiled game and
native port at the exact commit in `RESEARCH.md`. GoldenPad will consume only
the audited native source surface; matching-target Nintendo/SGI/Rare SDK
implementation sources remain excluded. GoldenRecomp/N64Recomp/N64ModernRuntime
and the completed RT64 mobile renderer remain references and potential future
replacement components, but GoldenRecomp cannot currently reproduce its
generated code from a public checkout.

## Milestones

### R — Research and provenance

- [x] R1: protect ROM/reference/build/signing paths with `.gitignore`.
- [x] R2a: inventory decomp, static-recomp, runtime, renderer, macOS and touch
  candidates with exact commits/licenses.
- [x] R2b: record GoldenRecomp's irreducible public-input blocker and select the
  reproducible MGB64 native source surface.
- [ ] R3: produce a source-level license manifest for every incorporated file.

Gate: no private/leaked/XBLA source, no proprietary SDK implementation in the
native target, and a pinned retail-ROM-to-runtime recipe.

### D — Native desktop baseline

- [x] D1: compile a native ARM64 Apple Silicon candidate.
- [x] D2: validate retail-ROM normalization/loading and visible mission render.
- [x] D3: validate audio initialization and persistent config path.
- [ ] D4: interactively validate menus, input, save/relaunch and mission progress.
- [ ] D5: start and complete a local multiplayer match.
- [ ] D6: make the selected production core's ROM-free tests clean.

Gate: selected core, not just the oracle, completes a mission and multiplayer.

### A — Apple application shell

- [x] A1a: create one native SwiftUI/UIKit iPhone+iPad application target.
- [x] A1b: add the guarded shared MGB64 core library and host probe bridge.
- [x] A2: render an original Metal clear frame on iPhone simulator.
- [x] A3: stop iPhone; render on iPad simulator; compare logs and layout.
- [x] A4: implement Files picker, byte-order normalization and SHA-1 validation.
- [x] A5: persist cache/settings/saves under sandbox-safe paths.
- [x] A6: implement lifecycle and audio-session transitions.

Gate: both simulators handle valid, missing and invalid ROM flows and relaunch.
This gate passes: valid V64, native Files-picker open/cancel, settings/save
relaunch, missing-file rejection and a synthetic 12 MiB wrong-hash rejection
were driven sequentially on both; invalid-size rejection also passed on iPad.

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

### I — Input and touch

- [x] I1: common normalized input snapshots for touch and controllers.
- [x] I2: N64-equivalent controls plus modern dual-stick FPS mapping.
- [x] I3: movable/resizable/opacity-adjustable phone and tablet layouts.
- [ ] I4: touch editor, persistence, safe areas, sensitivity/dead zones and gyro.
- [ ] I5: validate menu, aim, fire, reload, interact, crouch, weapon, pause and
  objectives flows.

Gate: a mission is completable with touch alone and with a physical controller.

I1-I3 are core-connected: exact libultra masks, modern/southpaw dual-stick input,
four deterministic controller slots, touch/controller merge and independent
phone/tablet layouts were exercised through the real mobile `osCont*` boundary
on both simulators, including an exact deterministic probe. I4 has a compiled and
persisted editor, safe-area clamping, sensitivity/dead-zone controls and a Core
Motion hook, but direct touch-drag, physical gyro and real-controller auto-hide
still need device acceptance. I5 now has strict sequential game-state proof for
movement, modern look/aim, fire, B reload/action, A weapon cycle and Start
pause/watch. Crouch, a context-sensitive world interaction, objectives flow and
organic mission completion remain open. The downstream report and persisted-save
path is independently proven through an explicitly scripted diagnostic trigger.

### M — Multiplayer

- [ ] M1: deterministic controller assignment and touch coexistence.
- [ ] M2: complete two-player local split-screen match.
- [ ] M3: validate three/four players and iPad viewport/aspect layouts.

Gate: four-player iPad match where core support allows it.

### P — Package and publish

- [x] P1: original neutral icon at every required size.
- [ ] P2: reproducible unsigned IPA from clean checkout.
- [ ] P3: archive contamination scan proves no ROM/assets/secrets/private paths.
- [ ] P4: sequential iPhone then iPad acceptance matrix; record device-only gaps.
- [x] P5: README/docs match observed behavior.
- [ ] P6: staged-file audit, coherent commits, push, and remote verification.

Gate: all definition-of-done items are passed or a specific external hardware or
upstream gate remains open with reproducible evidence.

The current foundation IPA reproduces byte-for-byte and passes the contamination
auditor, but P2/P3 remain open until the clean production core is present and a
fresh-checkout final package passes the same gates.

## Test rhythm

For every meaningful mobile change: build/run iPhone simulator, stop it, then
build/run iPad simulator, stop it, compare evidence, fix, and repeat. Never run
both simulators concurrently.
