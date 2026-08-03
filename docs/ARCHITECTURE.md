# Architecture

## Shape

```text
GoldenPadApp (UIKit lifecycle, document picker, status and settings)
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
iPhone/iPad target is a thin Objective-C++/UIKit host. Platform callbacks do not
leak into game simulation code.

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
- **Touch:** left movement stick; right drag/look region; fire, aim, interact,
  reload, crouch, weapon, pause/menu and optional C/D-pad surfaces. Layout,
  scale, opacity, sensitivity and dead zones persist separately for phone/tablet.
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
