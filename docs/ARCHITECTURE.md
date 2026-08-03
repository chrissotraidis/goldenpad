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
for mobile because `MTKView`/UIKit owns cadence. The Fast3D interpreter and room
normal helper also compile as a separate two-object mobile archive. Target-local
trap shims make accidental SDL/OpenGL ownership fail closed and leave no desktop
window or GL readback/swap symbols in that archive. A small ARC Objective-C++
bridge implements MGB64's existing `platformGetMetalLayer` contract using the
weakly observed UIKit-owned layer. The opt-in renderer target now links both
archives, selects Metal directly, supplies neutral mobile renderer settings and
lets `MTKView` drive real backend `start_frame`/`end_frame` calls. Host-owned ROM
globals remain null/zero until a validated private import succeeds. The minimap
queue is an explicit lifecycle-only no-op until the real game overlay is wired.
The next boundary starts the title/menu display-list loop.

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
consumer. A timed fallback remains inside blocking `osRecvMesg` for bring-up and
will be removed once lifecycle-aware producer/consumer synchronization is live.
Neutral controller, rumble, task and sequence-audio seams are explicitly
provisional; normalized Swift input, Game Controller haptics, Fast3D dispatch
and AVAudio must own them before gameplay acceptance.

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
- **Audio:** an engine PCM callback feeds `AVAudioEngine`; `AVAudioSession`
  handles interruption, route changes and sample-rate changes.
- **Saves:** EEPROM/SRAM/Flash callbacks write atomically under Application
  Support. Settings use a separate versioned file. Flush on backgrounding.
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
changing physical-device behavior. The selected core now compiles and exposes a
bounded live probe; real-controller auto-hide, physical gyro and gameplay
semantics remain acceptance gates once its platform/render loop is running.

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
