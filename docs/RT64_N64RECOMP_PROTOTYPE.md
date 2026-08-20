# RT64 + N64Recomp prototype

## Objective and isolation

This branch evaluates a **separate**, non-production `GoldenPadRecompPrototype`
iOS/iPadOS app for the original Nintendo 64 release of GoldenEye 007. It does
not alter the `GoldenPad` MGB64 target, bundle identifier, container, saves, or
renderer. The prototype identifier is
`com.chrissotraidis.goldenpad.recomp-prototype`, so it can coexist with
production in a Simulator.

The intended execution route is AOT/static N64Recomp output from a user-owned
US retail ROM, N64ModernRuntime's libultra replacement, and RT64's Metal
renderer. No live JIT or executable-memory allocation is permitted in the iOS
route. The current target is a buildable UIKit/CAMetalLayer host only; it never
claims to render a game frame until private AOT output drives real RSP/RDP tasks.

## Dependency record and license boundary

Verified on 2026-08-20 using public primary repositories:

| Dependency | Commit | License/status | Prototype use |
| --- | --- | --- | --- |
| `n64decomp/007` | `c4356466796c697dfd298010b9bed261f9ed8c6a` | No top-level license found; original-game rights remain unresolved | Behavioral/oracle reference only |
| `cblock85/GoldenEye64Recomp` | `a787fe0d95e8278fcba5ba2d768fa6a606e75f55` | GPL-3.0 | Static configuration, conversion and fix reference; isolate any reuse |
| `kholdfuzion/GoldenRecomp` | `f31b5d1e214f57c9ddb3dc598daa688bccffdd4f` | GPL-3.0 | Historical/static-recomp reference only |
| `N64Recomp/N64Recomp` | `ffb39cdad1da5de07eaaa48bd1db4a89a7986771` | MIT | Static generator/tooling |
| `N64Recomp/N64ModernRuntime` | `589bbf018a3e6d3646ddf7de1e7919f1b7e99bb1` | GPL-3.0 | Runtime, input/audio/queues/saves |
| `rt64/rt64` | `5473732a822a4423b5696e7cb18fecc425a59875` | MIT | RDP renderer; Plume submodule `d890ac899e505fb30040e037a4037cdeca68f033` |
| `Kenix3/libultraship` | `7eb555d06656271556efc9cb9b23fc39b31b9aef` | MIT | Fast3D design reference only |
| `perfect-dark-pc-port/perfect_dark` | `32a1cb9f268dd3ac73016801025c6bbbfa20130f` | MIT | Sky conversion reference only |

Linking N64ModernRuntime or GoldenEye64Recomp-derived code creates a GPL-3.0
prototype distribution obligation. Therefore it must remain a separately
documented target and cannot be folded into production MGB64 without a separate
licensing and migration decision. The N64 decomp's public readability does not
place game code or assets in the public domain.

## ROM and generated-code boundary

Only the normalized US retail dump with SHA-1
`abe01e4aeb033b6c0836819f549c791b26cfde83` is in scope. Retail ROM bytes,
TLB-free converted ROM bytes, extracted assets, AOT-generated game functions,
RSP output, saves and captures stay in ignored local storage. They must never
be committed, packaged or cited in public evidence. The planned conversion uses
GoldenEye64Recomp's local, pinned `vanilla_to_tlbfree.xdelta` input and writes
only outside the repository. N64Recomp then consumes the private TLB-free ROM
and `us.toml`; the generated `RecompiledFuncs/` directory remains private.

No retail ROM was located in the project workspace during this audit, so this
branch has not generated or inspected game-derived code.

## AOT iOS finding

N64ModernRuntime currently unconditionally builds N64Recomp's `LiveRecomp`
target. It failed for ARM64 iOS Simulator in SLJIT's Apple executable allocator,
which is expected for an iOS AOT path and is not a source failure. The narrow
patch [`patches/n64modernruntime-ios-aot.patch`](../patches/n64modernruntime-ios-aot.patch)
skips that live-recompiler dependency when the runtime is only used with static
generated C/C++. It applies and reverses cleanly against the exact ignored
checkout, and produced ARM64 Simulator `libultramodern.a` and `liblibrecomp.a`.
It has not yet been integrated into the app target.

## RT64/UIKit host

`GoldenPadRecompPrototype` is an independent CMake/Xcode target. Its SwiftUI
host owns an `MTKView`/`CAMetalLayer` and uses its own C++ bridge to create
RT64's Plume Metal interface and swapchain. The initial ARM64 Simulator host
build passed with the unique bundle identifier and contains neither `bossEntry`
nor `goldenpad_mgb64_*` symbols. This is host/surface evidence only; it does
not submit a colored triangle or a synthetic display list and does **not** count
as RT64 GoldenEye rendering.

## Required game path and carried fixes

The next integration stage must register a UIKit-native N64ModernRuntime
renderer context and call RT64's `loadUCodeGBI` plus `processDisplayLists` with
the actual `OSTask` RSP/DP data and RDRAM from the recompiled game. It must also
adapt production's AVAudioEngine, GameController/touch snapshots, atomic save
root and scene lifecycle rather than transplanting the macOS AppKit/SDL host.

The following changes are required before considering a frame valid:

1. Preserve SP/DP completion messages with a FIFO pending queue when the game
   scheduler queue is full; upstream current drops them.
2. Force RT64's ubershader route on Metal until the specialized shader issue is
   reproduced as fixed; otherwise character, weapon and logo geometry may be
   absent.
3. Guard interpolation for incompatible/teleport rotations and clamp the
   angular `acos` input.
4. Patch the static `cosf` fallthrough into `sinf` in the private generated
   function output; no live-recompiler-only fix belongs in the AOT target.
5. Verify that live-only odd-FPR, `mtc1` width and cross-section jump-table
   fixes are absent from the static generator route rather than applying them
   blindly.

## Rendering validation and known blocker

The rendering order is intro logos/gunbarrel, main menu/briefings, then Dam.
For every checkpoint, capture a private deterministic frame and record display
list submissions, texture-cache hits/misses, TMEM upload bytes, pipeline
creation, frame time and FPS. Compare equal internal/output resolution against
production MGB64; Simulator results are not iPhone/iPad performance claims.

GoldenEye64Recomp currently reports black skyboxes and flat water because their
custom command path is not represented by RT64. The completed GoldenEye decomp
builds the sky/water from projected vertices (`skyRenderTri`/`skyRenderFull`),
and Perfect Dark's non-N64 port converts the equivalent projected vertices into
ordinary allocated vertices before submitting display-list triangles. The first
candidate fix is therefore a small GoldenEye-specific conversion of those
computed vertices into ordinary RT64-supported triangles (or documented RT64
extended commands), preserving texture coordinates and vertex color. A flat
clear color is unacceptable as a final result. Framebuffer-dependent glass,
monitors and blending remain separate validation gates after base geometry.

## Build and Simulator instructions

Build the current ROM-free host:

```sh
./scripts/verify-recomp-prototype-host.sh
```

To link the already verified RT64 static archives, first produce them with
`GOLDENPAD_RT64_ARTIFACT_DIR` using `verify-rt64-ios-static.sh`, then configure
with `GOLDENPAD_RECOMP_RT64_ARCHIVE_DIR` and
`GOLDENPAD_RECOMP_RT64_SOURCE_DIR`. The subsequent AOT integration will add the
ignored N64ModernRuntime checkout and private generated output explicitly.

On the current host, `verify-rt64-ios-static.sh` reaches RT64's generated MSL
compile and stops because `xcrun -sdk macosx metal` reports a missing Metal
Toolchain. Xcode 26.6's `xcodebuild -downloadComponent MetalToolchain` completed
successfully, but the command still reports the component unavailable. This is
a host-toolchain registration blocker, not an RT64 source or iOS patch failure;
the patches apply/reverse cleanly. Do not treat the surface-only host as a
linked RT64 renderer until this command succeeds and the four verified archives
exist.

After a supported private ROM is supplied, build/install/launch evidence must
be separate from game-frame evidence. It must install via `simctl` without
removing `com.chrissotraidis.goldenpad`; capture intro, menu and Dam privately;
and retain console/PID/liveness logs independently.

## Migration gates and current recommendation

Do not migrate production based on the current host build. Continue MGB64 while
the prototype advances. Migration requires all of the following: AOT game
execution, real intro/menu/Dam RT64 frames, correct textures/core geometry,
audio plus touch or controller, confirmed or specifically reproduced sky/water
state, framebuffer effects, an equivalent-settings comparison, and a clean
ROM/generated-code audit. Until then, the recommendation is **continue both
temporarily**: production MGB64 remains the playable baseline and this isolated
prototype is the RT64 investigation path.
