# Architecture

## Shape

```text
GoldenPadApp (SwiftUI lifecycle, UIKit document picker/Metal view, status)
    |
ApplePlatform (paths, audio session, controllers, touch, lifecycle, Metal view)
    |
NormalizedInput + PortableHost APIs
    |
MGB64 decompiled game core + native compatibility layer
    |
MGB64 Fast3D/Metal first; RT64 remains a verified renderer option
    |
Metal / CAMetalLayer
```

The simulation, recomp runtime and renderer are portable static libraries. The
iPhone/iPad target is a thin SwiftUI/UIKit host. An Objective-C++ bridge will be
added only where the C++ runtime requires it. Platform callbacks do not leak
into game simulation code.

## Core and undecompiled code

MGB64 is the production-core candidate. Its decompiled retail-N64 game logic is
built ahead of time as Apple ARM64 C code; it is not an interpreter, JIT, or
general N64 emulator. The app accepts only the supported GoldenEye revision and
loads bulk media from the user's ROM at runtime.

MGB64's matching-N64 tree contains historical SDK-lineage compatibility files,
but its native build uses platform replacements and an explicit empty libultra/
libultrare implementation source set. GoldenPad reproduces that narrow boundary
and runs the upstream guard before compiling the core. GoldenRecomp remains a
future static-recomp alternative if its missing public ELF/metadata pipeline is
restored.

## Graphics

RT64 consumes N64 display lists and emits Metal work. Its macOS Metal path is
the starting point. Tracked patches make shader generation SDK-aware, keep the
Plume backend portable across AppKit and UIKit, and replace desktop
window/dialog/inspector ownership with three small embedded-host shims. They are
applied only to exact pinned references by the RT64 verification scripts and
reversed on exit. Generated shaders and archives are never committed.

`AppleRenderSurface` owns the live `MTKView` command queue and lifecycle. While
the view is attached, it exposes non-retaining opaque pointers to that `UIView`
and its `CAMetalLayer`, matching RT64's Apple `RenderWindow { window, view }`
boundary. UIKit retains both objects. The surface pauses rendering outside the
active scene and refreshes the drawable dimensions/refresh rate on layout. The
default ROM-free build clears the foundation frame. When verified RT64 archives
are supplied explicitly, `rt64_metal_bridge.cpp` force-links the full renderer
closure and retains a Plume Metal interface, device, direct command queue and
swapchain for that surface. The default build uses a null bridge stub, so a
clean checkout does not depend on an ignored reference tree.

MGB64's Fast3D Metal path is the shortest initial game renderer because it is
already coupled to the selected core and proven on Apple Silicon. The completed
RT64 mobile closure remains available for a later renderer migration or a
restored GoldenRecomp path; integrating one renderer first avoids carrying two
game-rendering stacks through initial gameplay bring-up.

The complete MGB64 Metal backend now compiles for both Apple mobile SDKs as a
separate static target. Its two macOS-only display-sync assignments are removed
for mobile because `MTKView`/UIKit owns cadence. The Fast3D interpreter,
room-normal helper, screenshot and texture units compile as a separate
five-object mobile archive. Target-local
trap shims make accidental SDL/OpenGL ownership fail closed and leave no desktop
window or GL readback/swap symbols in that archive. A small ARC Objective-C++
bridge implements MGB64's existing `platformGetMetalLayer` contract using the
weakly observed UIKit-owned layer. The opt-in renderer target now links both
archives, selects Metal directly, supplies neutral mobile renderer settings and
lets the game thread's real `gfx_run_dl` own backend `start_frame`/`end_frame`
calls after startup; before startup, `MTKView` presents an empty frame and offers
the scheduler a retrace. Host-owned ROM
globals remain null/zero until a validated private import succeeds. The minimap
queue is an explicit lifecycle-only no-op until the real game overlay is wired.
The native title animation, authentic front end and Dam stage now render through
this path on both simulator classes. A diagnostics-only Start script reaches
the mission through the normal controller boundary; gameplay acceptance remains
separate.

## Scheduler and mobile OS surface

MGB64's native port uses a cooperative scheduler: the original scheduler data
structures and queues remain intact, while the host frame loop delivers retrace
messages instead of starting an emulated N64 scheduler thread. GoldenPad keeps
that upstream model but does not compile the desktop `platform/stubs.c`, which
also owns SDL keyboard, mouse, controller and audio behavior. The project-owned
`mgb64_mobile_os.c` implements only the required message, timing, VI, task,
neutral-controller and scheduler bootstrap surface.

The UIKit-owned `MTKView` now offers a retrace after each presented empty frame,
but only when the scheduler is initialized and its graphics queue is empty.
This naturally leaves exactly one pending message before `bossEntry` supplies a
consumer. Queue mutation is protected for the future game/UI thread split.
Before UIKit attaches, a timed fallback permits bounded bring-up; after attach,
blocking receives wait for MTKView and inactive/background scenes produce no
synthetic frames. Non-graphics queues also honor real one-shot/repeating timers,
including the 100 ms waits in `bossInitMainthreadData`.

`mgb64_mobile_host.c` owns the four pthread-protected controller states fed by
Swift, deterministic-mode flags, frame stats, renderer recovery state,
lifecycle-watchdog state and the bounded PCM ring without an SDL window. MGB64's
portable `app_overlay_hooks.c` remains the real overlay dispatch owner. Rumble
and Game Controller haptics remain provisional; controller reads, Fast3D
dispatch and native PCM output now cross the real game boundary.

After ROM, file-table, scheduler and renderer readiness, the host calls
`goldenpad_mgb64_start_game` exactly once. A named detached pthread initializes
the portable audio/watchdog services and enters non-returning `bossEntry`.
UIKit continues to provide retrace cadence while display-list submission and
Metal presentation remain on the game thread.

Portable GU matrix/vector math is similarly isolated into
`mgb64_mobile_gu.c`. The functions are MGB64's real native host algorithms, not
matching-target SDK implementation sources, and do not pull the SDL-owned
platform unit into the app. This is the first bounded `bossEntry` closure slice.

The next closure layer directly enumerates small upstream portable leaf units:
segment constants, clean-room trig, bounded stdio, and isolated gameplay
fidelity decisions. Keeping them separate from audio, settings, input and
window ownership lets the linker map prove progress without importing a desktop
subsystem.

Game-side configuration and direct-start globals are owned by
`mgb64_mobile_config.c` on Apple mobile. These are plain typed defaults consumed
by the decompiled game code; UIKit settings can update them through a narrow
bridge later. The SDL platform file remains excluded.

Portable model conversion, level-name lookup, analog radial mapping, setup-name
resolution and weapon-cue tables use MGB64's real separated upstream modules.
Small game constants and the `unknown2` ROM offset live in
`mgb64_mobile_legacy_data.c`, away from the desktop compatibility owner and
without embedding the referenced ROM bytes.

## ROM and resources

```text
UIDocumentPicker -> security-scoped URL -> mapped private source
    -> normalize Z64/V64/N64 byte order -> SHA-1 validation
    -> copy normalized bytes into volatile core-owned memory
    -> patch native file table to owned-buffer offsets
    -> close source access -> start core
```

The handoff rechecks exact size, big-endian header and internal title before
copying. Replacement clears the prior heap buffer before freeing it; process or
app-container removal clears the remainder. The final flow never bundles the
ROM. Generated caches are versioned by ROM hash,
core version, schema, and locale, and can be regenerated. Caches must stay in
`Application Support`, never `Documents` or the app bundle.

MGB64's generated `rom_offsets.c` performs the table patch. Its native
`asset_stubs.c` contributes one-byte link placeholders only; they contain no
game media and every active table pointer is replaced with a validated ROM
offset before resource loading begins. Clearing ROM ownership first nulls all
table pointers, then zeroes and frees the old allocation.

## Platform services

- **Input:** touch and `GCController` devices feed one normalized snapshot per
  simulation tick. Players 1-4 are assigned deterministically. Touch is player 1
  only and auto-hides when an active physical controller is assigned.
- **Input mapping:** one frame carries normalized movement/look/actions plus an
  exact libultra-compatible N64 controller state. Classic exposes A/B/Z/Start,
  D-pad, L/R and all four C buttons; modern and southpaw preserve independent
  move/look axes while still deriving the corresponding N64 mask.
- **Touch:** left movement stick; right look region; fire, aim, interact, reload,
  crouch, weapon and pause/menu surfaces. Classic adds the complete N64 button
  set. Each preset resolves from device-class defaults plus small persisted
  deltas, so phone and tablet changes do not copy or overwrite each other.
  Per-control position, 70–150% size and visibility plus global opacity, scale,
  sensitivity, dead zone, gyro and controller auto-hide settings are supported.
- **Audio:** MGB64's native synth produces 22.05 kHz stereo PCM into a bounded
  lock-protected ring. An `AVAudioSourceNode` pulls it into `AVAudioEngine`,
  which resamples to the current device rate; `AVAudioSession` handles
  interruption, route changes and sample-rate changes.
- **Saves:** the game-facing 16 Kbit EEPROM API and bounds behavior are live.
  Swift restores the exact 2 KiB image from Application Support at bootstrap and
  snapshots it under a C mutex for an atomic, protected write on scene
  deactivation/backgrounding. Settings and generic host save slots persist
  separately.
- **Timing:** `mach_continuous_time`/display callbacks drive a fixed simulation
  cadence. Rendering may interpolate but never advances game state twice.
- **Filesystem:** all paths are injected by the host; core code never assumes
  current-working-directory or desktop locations.
- **Lifecycle:** resign-active pauses input/audio; background flushes saves and
  releases transient GPU work; foreground recreates surfaces if needed.

The current host implements the Apple render-surface boundary, common snapshot,
exact N64 masks, classic,
modern and southpaw presets, four deterministic controller slots,
extended-gamepad mapping, Core Motion input, and a live touch-layout editor.
Simulator-only synthetic MFi controllers are excluded from auto-hide without
changing physical-device behavior. The selected core now consumes these frames
through its real `osCont*` calls, renders its title/front-end/Dam path, and emits
decoded game audio through the native PCM chain. Diagnostics observe menu/stage
state through atomics published alongside the game-thread controller read. Menu
and gameplay-input probes are read-only. One separately named mission-flow probe
may request MGB64's existing scripted-success behavior after live Dam starts;
the game still owns report construction and EEPROM writes, and the result is
never accepted as organic completion. The same diagnostic boundary can publish
player position, view angles, aim, weapon/ammo, watch and progression state for
acceptance. Read-only snapshots sample Facility's real camera mode, model-159
doors at setup pads 67/68, and the model-155 door at pad 75 on the game thread.
The Facility routes wait for
`CAMERAMODE_FP`, then publish only ordinary normalized movement, look and B
frames through the same controller setter used by touch and physical pads. They
never force a player transform or door state. The separate Dam route uses that
same boundary for MGB64's promoted multiwaypoint controller sequence. Its
game-thread diagnostic publishes only camera mode, player position, and the
four objective statuses; acceptance requires that the objective vector remain
unchanged. Real-controller auto-hide,
physical gyro, crouch/objectives flow and organic mission-completion semantics
remain acceptance gates.

## Targets

One Xcode app target supports iPhone and iPad device families with an ARM64
device slice and Apple Silicon simulator slice. Core/runtime/renderer are static
library targets shared with a macOS validation executable. iOS and iPadOS are
one source target with device-class layouts, not forked game code.

## Multiplayer

Single-player is completed first. Then controller assignment and viewport
layout are validated for two players, followed by three/four players. Touch
never generates inputs for unassigned players. Four-player iPad split screen is
a final acceptance gate, not an initial architecture dependency.
