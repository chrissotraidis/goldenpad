# RT64 + N64Recomp prototype

The accepted physical-iPad baseline and its bounded next-day worklist are
recorded in
[`RT64_N64RECOMP_MORNING_HANDOFF_2026-08-21.md`](RT64_N64RECOMP_MORNING_HANDOFF_2026-08-21.md).

## Primary GoldenPad runtime and isolation

The accepted recomp/RT64 app is now GoldenPad's **primary development runtime**
for the original Nintendo 64 release of GoldenEye 007. The internal CMake target
name remains `GoldenPadRecompPrototype` to avoid a risky build-system rename,
while its user-facing app name is `GoldenPad`. The earlier MGB64 app is displayed
as `GoldenPad Legacy` and remains available as a deprecated fallback. The primary
runtime identifier is
`com.chrissotraidis.goldenpad.recomp-prototype`, so it can coexist with
the legacy app in Simulator or on hardware without changing either container.

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

A user-supplied ROM was later imported into private local build and app-container
storage for validation. The repository still contains no retail ROM, generated
game functions, extracted assets, saves or captures.

## AOT iOS finding

N64ModernRuntime upstream unconditionally builds N64Recomp's `LiveRecomp`
target. It failed for ARM64 iOS Simulator in SLJIT's Apple executable allocator,
which is expected for an iOS AOT path and is not a source failure. The narrow
patch [`patches/n64modernruntime-ios-aot.patch`](../patches/n64modernruntime-ios-aot.patch)
skips that live-recompiler dependency when the runtime is only used with static
generated C/C++. It applies and reverses cleanly against the exact ignored
checkout, and produced ARM64 Simulator and iPhoneOS `libultramodern.a` and
`liblibrecomp.a`. The private AOT build now uses those archives in the
isolated prototype target.

## RT64/UIKit host

`GoldenPadRecompPrototype` is an independent CMake/Xcode target. Its SwiftUI
host owns an `MTKView`/`CAMetalLayer` and uses its own C++ bridge to create
RT64's Plume Metal interface and swapchain. The ARM64 Simulator and iPhoneOS
builds use the unique bundle identifier and contain neither production MGB64
runtime nor production app state. The target now submits the recompiled game's
real display lists to RT64; synthetic render tests are not used as gameplay
evidence.

## Required game path and carried fixes

The prototype registers a UIKit-native N64ModernRuntime renderer context and
calls RT64's `loadUCodeGBI` plus `processDisplayLists` with actual `OSTask`
RSP/DP data and RDRAM from the recompiled game. It also has prototype-local
AVAudioEngine, GameController/touch snapshots, private config/log storage and
scene lifecycle rather than transplanting the macOS AppKit/SDL host.

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

## Rendering validation

The rendering order is intro logos/gunbarrel, main menu/briefings, then Dam.
For every checkpoint, capture a private deterministic frame and record display
list submissions, texture-cache hits/misses, TMEM upload bytes, pipeline
creation, frame time and FPS. Compare equal internal/output resolution against
production MGB64; Simulator results are not iPhone/iPad performance claims.

The current hardware build renders the intro, menus and playable stages through
RT64 at automatic high resolution, expanded aspect and optional 2x MSAA. It uses
the original presentation rate because display-rate interpolation exposed
intermittent geometry shimmer. Sky, water, framebuffer-dependent glass,
monitors, blending, camera near-plane behavior and later-stage effects remain
separate validation gates; a correct Dam frame is not proof that every effect
or mission is correct.

## Build and Simulator instructions

Build the ROM-free host checks:

```sh
./scripts/verify-recomp-prototype-host.sh
```

To link the already verified RT64 static archives, first produce them with
`GOLDENPAD_RT64_ARTIFACT_DIR` using `verify-rt64-ios-static.sh`, then configure
with `GOLDENPAD_RECOMP_RT64_ARCHIVE_DIR` and
`GOLDENPAD_RECOMP_RT64_SOURCE_DIR`. The subsequent AOT integration will add the
ignored N64ModernRuntime checkout and private generated output explicitly.

The static-archive verifier uses the installed Metal toolchain via
`TOOLCHAINS=metal-2600.50.6.1` and
`GOLDENPAD_METAL_TOOLCHAIN=metal-2600.50.6.1`. Private generated game output
and runtime build directories remain explicit local inputs and are not
committed.

After a supported private ROM is supplied, build/install/launch evidence must
be separate from game-frame evidence. It must install via `simctl` without
removing `com.chrissotraidis.goldenpad`; capture intro, menu and Dam privately;
and retain console/PID/liveness logs independently.

For repeatable Simulator-only menu testing, enable Simulator's **Capture
Keyboard** control. Arrow keys map to the left stick and N64 D-pad, A/B map to the N64 face
buttons, S maps to Start, Z maps to fire, and R maps to aim. This shim is
compiled only for Simulator and does not alter physical-device controller or
touch behavior.

## Current AOT result — 2026-08-20

The isolated target now links private generated AOT sources, the AOT-only
N64ModernRuntime archives and RT64. With the user-supplied ROM staged only in
the prototype container, the process reaches real GoldenEye PI DMA, scheduler,
RSP and DP completion work. This is execution evidence, not a rendered-frame
claim. ROM derivatives, generated sources, saves and captures remain ignored
private state and are never committed.

The original Simulator failure was RT64's flat common-set ABI: it requested 52
buffers and 18 samplers where the Simulator permits 31 and 16. The private,
Simulator-only static archive now removes unused extended/ray-tracing bindings,
aliases the remaining samplers, and bypasses unavailable counter sampling. It
renders real GoldenEye frames from the user-supplied input. Hardware validation
has since advanced through intro, menus and playable stages. This remains a
private prototype result, not a claim that every stage or effect is complete.

The prototype has independent input plumbing using the production GoldenPad
touch placement and tuning: move, relative look, fire, aim, action, duck,
weapon and Start. AIM supports toggle or hold and has a distinct yellow active
state; DUCK is a yellow C-button-style action. Look uses the production 1.5x
swipe accumulation, 4x default sensitivity and one-third-speed precision while
aiming. Settings include aim behavior, optional aim-only vertical inversion,
an optional centered reticle, resolution, 2x MSAA, and three-point filtering.
Renderer-quality changes are persisted for the next app launch instead of
rebuilding the active RT64 session. A prototype-only
`Unlock all missions` setting uses GoldenEye's existing mission-availability
predicate without marking missions complete or writing EEPROM. It is intended
for later-stage rendering tests and leaves the user's real save progression
unchanged. Its
N64ModernRuntime bridge explicitly advertises a normal controller in port 1,
matching the reference implementation; it previously reported `Device::None`,
which caused GoldenEye's controller-socket error. A Simulator UI gesture on A
was verified in the native log as button bit `0x8000` followed by release. The
bridge is prototype-local and does not use or change the production MGB64 input
system.

The native GameController map supports Xbox/MFi-style hardware. Its default is:
left stick moves, right stick supplies modern analog look, LT aims, RT fires,
A/Y changes weapon, B/X acts, LB toggles duck, RB changes weapon, Menu is Start
and the d-pad maps directly. A dedicated Button Mapping screen can reassign the
face buttons, bumpers, and triggers without rewiring the fixed sticks, d-pad or
Menu/Start path. An opt-in test mode keeps the connected controller on port 1
and advertises touch as port 2, with independent look and crouch state; turning
it off hides touch and keeps the physical controller on port 1. The full ARM64
Simulator build has entered and sustained an authentic two-player split-screen
match with both ports active. Physical controller-plus-touch multiplayer is
still an acceptance gate.

The 2026-08-21 10:04 multiplayer start failure produced an iPadOS crash report,
incident `E40A1ADE-AD85-45A8-ACE3-814507E93D03`: `EXC_BAD_ACCESS`/`SIGBUS` at
`0x0000000320000000` on RT64's display-list thread. The stack ended in
`RT64::Interpreter::processDisplayLists` through `RT64Context::send_dl`.
GoldenEye supplied a KSEG1 `0xA...` address while the newer standalone RT64
revision interpreted any address with bit 31 set as extended RDRAM, subtracting
`0x80000000` and producing the invalid `0x20000000` offset. The embedded RT64
patch now matches GoldenEye64Recomp's pinned behavior: only the `0x8...`
extended region bypasses normal 29-bit physical-address masking. This is a
targeted compatibility repair; the stable single-player presentation path is
otherwise unchanged.

The repaired build was then exercised in a dedicated iPad Simulator through
GoldenEye's main menu, multiplayer options and a live horizontal split-screen
Temple match. Bounded diagnostics recorded independent Player 1 and Player 2
button transitions and advanced past 31,000 display-list, VI and presentation
updates without the former fault. The user nevertheless observed the two
Simulator viewports flashing back and forth, so multiplayer remains work in
progress and is not part of the initial single-player release-acceptance claim.
This closes the deterministic crash reproduction but does not replace
hands-on physical-iPad multiplayer, presentation or performance acceptance.

Patch regeneration produces a matched `RecompiledPatches/patches.c` and
embedded `patches_bin.c`; rebuilding or installing with only one half updated
is an invalid black-screen artifact and must fail the display-list liveness
gate. A later experiment that rebuilt `field_488.applied_view` after modern
look was also rejected: it reduced physical-iPad gameplay presentation to about
17-18 frames per second and made controller input feel sluggish.

The bridge writes bounded `[GoldenPadRecomp]` unified-log events for ROM
validation, runtime/overlay setup, the active game loop, controller presence,
first polling/input state, button transitions, audio submission, rumble
requests, stop, and errors. High-frequency button, right-stick, and rumble
transitions are sampled so diagnostics cannot become a gameplay workload. It intentionally
emits no per-frame port warnings.
Audio is consumed by a 22,050 Hz stereo `AVAudioSourceNode` and converted by
AVAudioEngine to the current device route. Diagnostics separately report the
real queued, rendered, non-zero, producer-dropped and consumer-underrun frame
counts. Physical logging identified the reported static as consumer cadence
jitter rather than a sample-rate mismatch: the game and engine averaged the
same rate, but larger AVAudioEngine pulls occasionally arrived just before the
next per-VI game chunk. The host now keeps a 1,024-frame scheduling reserve,
prebuffers about 46 ms and uses 32-frame fades only when rebuffering. The final
hardware soak rendered more than 2.3 million frames with zero underrun frames,
zero underrun callbacks and zero producer drops. Physical-speaker listening
remains the final audio acceptance gate. The iOS ring now also matches the
reference GoldenEye64Recomp host's stereo-pair swap required by
N64ModernRuntime's RDRAM address ordering; queue health alone could not detect
that channel-order defect.

For runtime diagnosis, the prototype also applies a temporary,
reversible trace at the reference RT64 render-context seam. It reports the
first display list and every 300 thereafter, alongside the equivalent VI
presentation count. Physical soaks have reached tens of thousands of processed
display lists and VI updates. A pre-fix hardware run rendered more than 15.5
million audio frames without reproducing the former
`alAuxBusPull`/`alEnvmixerPull` crash. Those faults were traced to 32-bit N64
KSEG addresses losing sign extension across nested recompiled audio calls; the
AOT runtime patch now canonicalizes all RDRAM accesses to the 29-bit physical
address range.

The host explicitly fills and clips the Metal surface over an edge-to-edge
black background. Pixel inspection of the 10:07 hardware screenshot confirmed
that the reported far-right blue strip is exactly two physical pixels wide on
the 2× iPad display. A one-point opaque host overlay now masks only that sampling
seam without changing RT64's drawable or viewport. Physical visual acceptance
of the new mask remains open across device sizes and orientations.

Shared diagnostics retain bounded current and previous session logs. A tiny
foreground-session marker is removed on a real background transition and left
behind by a process crash; the next launch reports that the previous foreground
session ended unexpectedly and directs the tester to the previous log and the
iPadOS crash report. This adds crash visibility without streaming a console or
recording gameplay.

An in-place hardware update on 2026-08-20 preserved prototype database UUID
`D2F4E1F3-F310-4A01-8ED7-65B907FAA17B`. A subsequent 34.7-second QuickTime
capture showed playable full-frame RT64 output with no visible right-edge blue
strip. During the same title/demo progression, native counters exceeded four
thousand display-list/VI updates and two million rendered audio frames with no
consumer underruns or producer drops. The capture contained a 48 kHz mono
audio track but at an extremely low recorded level, so it is not used as a
physical-speaker static acceptance result.

When rebuilding the AOT target, temporarily apply and reverse the existing
RT64 iOS SDK, embedded-host and Plume patches around the Xcode build: the
external RT64 render-context source otherwise includes the desktop SDL path.
The RT64 static-archive verifier works with the downloaded Metal component via
`TOOLCHAINS=metal-2600.50.6.1` and
`GOLDENPAD_METAL_TOOLCHAIN=metal-2600.50.6.1`.

## Primary-runtime decision and remaining gates

The 2026-08-21 physical-iPad acceptance run established the recomp/RT64 app as
GoldenPad's primary development runtime. MGB64 remains buildable only as the
deprecated `GoldenPad Legacy` fallback. This product decision does not erase
the remaining release gates: screenshot/background lifecycle recovery,
physical-speaker audio, longer mission soaks, stage/effect comparison,
multi-controller multiplayer, save compatibility and a clean
ROM/generated-code audit still require explicit evidence.
