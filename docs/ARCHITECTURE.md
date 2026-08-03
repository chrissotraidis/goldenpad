# Architecture

## Shape

```text
GoldenPadApp (SwiftUI lifecycle, UIKit document picker/Metal view, status)
    |
ApplePlatform (paths, audio session, controllers, touch, lifecycle, Metal view)
    |
NormalizedInput + PortableHost APIs
    |
GoldenRecomp-generated game code + N64ModernRuntime
    |
RT64 display-list renderer
    |
Metal / CAMetalLayer
```

The simulation, recomp runtime and renderer are portable static libraries. The
iPhone/iPad target is a thin SwiftUI/UIKit host. An Objective-C++ bridge will be
added only where the C++ runtime requires it. Platform callbacks do not leak
into game simulation code.

## Core and undecompiled code

GoldenRecomp is the preferred core. Decompiled functions needed as deliberate
patches remain small GPL sources with explicit provenance; all remaining MIPS
functions are statically recompiled by N64Recomp. No interpreter, JIT, or general
N64 emulator is embedded. The app only accepts one supported game/revision.

The generated native functions are built ahead of time for Apple ARM64. They do
not contain bulk media. Their public-distribution status is a legal gate in
`docs/LEGAL.md`.

## Graphics

RT64 consumes N64 display lists and emits Metal work. Its macOS Metal path is
the starting point. Shader generation will be made SDK-aware so Metal libraries
are produced for `macosx`, `iphoneos`, and `iphonesimulator` as appropriate.
The UIKit host owns the `CAMetalLayer`; RT64 receives a narrow surface handle.

MGB64's Metal/WebGPU renderer remains an oracle/fallback reference only.

## ROM and resources

```text
UIDocumentPicker -> security-scoped URL -> private temporary copy
    -> normalize Z64/V64/N64 byte order -> SHA-1 validation
    -> derive/cache only required resources in Application Support
    -> remove temporary source copy -> start core
```

Early milestones may read the validated ROM directly from the selected URL.
The final flow never bundles it. Generated caches are versioned by ROM hash,
core version, schema, and locale, and can be regenerated. Caches must stay in
`Application Support`, never `Documents` or the app bundle.

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

The current host implements the common snapshot, exact N64 masks, classic,
modern and southpaw presets, four deterministic controller slots,
extended-gamepad mapping, Core Motion input, and a live touch-layout editor.
Simulator-only synthetic MFi controllers are excluded from auto-hide without
changing physical-device behavior. Real-controller auto-hide, physical gyro and
gameplay semantics remain acceptance gates once the production core is present.

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
