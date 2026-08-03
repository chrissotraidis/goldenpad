# Plan

This plan is evidence-gated. A milestone is complete only when its acceptance
gate passes and evidence is recorded in `STATUS.md` and `WORKLOG.md`.

## Selected codebase

Preferred core: GoldenRecomp's original-retail-N64 static-recompilation design,
updated to current N64Recomp/N64ModernRuntime and RT64 at the commits in
`RESEARCH.md`. MGB64 is a local Apple behavior oracle, not an incorporated core.

This selection remains behind gate R2 because the public GoldenRecomp checkout
cannot currently reproduce its generated code. If R2 cannot be solved without
private/leaked/unclear material, the only acceptable fallback is a clean,
documented MGB64 first-party extraction after upstream licensing and SDK-lineage
clearance. The project will not route around the provenance gate.

## Milestones

### R — Research and provenance

- [x] R1: protect ROM/reference/build/signing paths with `.gitignore`.
- [x] R2a: inventory decomp, static-recomp, runtime, renderer, macOS and touch
  candidates with exact commits/licenses.
- [ ] R2b: reproduce GoldenRecomp's game-code generation from public sources and
  the user's retail ROM, or record the irreducible upstream blocker.
- [ ] R3: produce a source-level license manifest for every incorporated file.

Gate: no private/leaked/unlicensed source; clean input-to-native-code recipe.

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
- [ ] A1b: add the shared host/core libraries after the production-core gate.
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

- [ ] G1: compile generated GoldenEye code for Apple ARM64 simulator/device.
- [ ] G2: parameterize RT64 Metal shaders/surfaces for iOS.
- [ ] G3: title, menus and mission load render correctly.
- [ ] G4: complete one mission with correct audio and persisted save.
- [ ] G5: background/foreground and audio route/interruption recovery.

Gate: full mission completion after clean install and ROM import.

### I — Input and touch

- [x] I1: common normalized input snapshots for touch and controllers.
- [x] I2: N64-equivalent controls plus modern dual-stick FPS mapping.
- [x] I3: movable/resizable/opacity-adjustable phone and tablet layouts.
- [ ] I4: touch editor, persistence, safe areas, sensitivity/dead zones and gyro.
- [ ] I5: validate menu, aim, fire, reload, interact, crouch, weapon, pause and
  objectives flows.

Gate: a mission is completable with touch alone and with a physical controller.

I1-I3 are host-complete: exact libultra masks, modern/southpaw dual-stick input,
four deterministic controller slots, touch/controller merge and independent
phone/tablet layouts were exercised on both simulators. I4 has a compiled and
persisted editor, safe-area clamping, sensitivity/dead-zone controls and a Core
Motion hook, but direct touch-drag, physical gyro and real-controller auto-hide
still need device acceptance. Gameplay mapping against the core remains I5.

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
