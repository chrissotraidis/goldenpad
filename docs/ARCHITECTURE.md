# Architecture

Updated: 2026-08-22

This document describes the architecture that ships in the current Preview 3
line. Historical MGB64 bring-up details remain useful, but they do not describe
the primary product anymore.

## Product topology

```text
                         user-supplied NTSC-U retail dump
                                      |
                         validate + private TLB-free conversion
                                      |
              +-----------------------+-----------------------+
              |                                               |
      iPhone / iPad host                              Apple-Silicon Mac host
      SwiftUI + UIKit                                 SwiftUI + AppKit
      touch + GCController                            keyboard/mouse + controller
      AVAudioSession + AVAudioEngine                  AVAudioEngine
              |                                               |
              +---------------- project-owned bridges --------+
                                      |
                    statically generated GoldenEye ARM64 code
                              + N64ModernRuntime
                                      |
                            N64 display-list tasks
                                      |
                              RT64 -> Plume -> Metal
                                      |
                              CAMetalLayer presentation
```

The primary runtime is the statically recompiled GoldenEye64Recomp path. The
older MGB64/Fast3D application is a separately buildable `GoldenPad Legacy`
comparison and fallback target. It is not the release runtime and its controller,
audio, scheduler, or save architecture must not be attributed to Preview 2.

## Ownership boundaries

| Owner | Responsibilities | Must not own |
| --- | --- | --- |
| SwiftUI/UIKit/AppKit host | Windows and views, ROM selection, settings UI, touch and hardware events, lifecycle notifications, audio-device setup, user-facing diagnostics | GoldenEye simulation state, N64 render commands, network simulation policy |
| `Support/RecompPrototype` | Host callbacks, controller-port publication, relative-look queue, PCM ring, save bridge, lifecycle flags, bounded health counters | App UI, retail-data distribution, RT64 internals |
| Generated AOT game code + N64ModernRuntime | GoldenEye simulation, original menus and multiplayer rules, N64 task scheduling, patched game-side input consumers | Apple UI, device enumeration, transport/matchmaking |
| RT64 + Plume | N64 display-list interpretation, framebuffer tracking, GPU work, Metal swap chain and presentation | GoldenEye gameplay rules, controller assignment, app lifecycle policy |
| User data stores | Converted runtime data, saves and preferences inside the app container | Repository, app bundle, release archive |

These seams are intentional. A host-side convenience must not write
undocumented player/camera structures or fabricate mission state. Renderer fixes
must not silently change game simulation, input ownership, or save data.

## Static recompilation and generated inputs

The primary app executes ahead-of-time generated Apple ARM64 code. It is not a
general Nintendo 64 emulator, interpreter, or JIT. N64ModernRuntime provides the
portable runtime services used by that generated code, and RT64 consumes the
game's N64 display-list tasks.

The generated AOT source and converted retail-derived inputs are intentionally
private and untracked. CMake requires the generated `patches.c` and
`patches_bin.c` pair together and checks for project patch markers before a
complete primary build. Regenerating one half without the other can produce a
valid-looking build whose game-side input or multiplayer repair is absent, so
that state fails configuration by design.

The exact public dependency pins and patch application order are recorded in
[`RT64_N64RECOMP_PROTOTYPE.md`](RT64_N64RECOMP_PROTOTYPE.md). A public clean
checkout can audit the host, patches, pins, and packaging rules, but it cannot
recreate private generated game inputs by itself.

## ROM and save flow

```text
Files picker / Open In
    -> security-scoped private source
    -> normalize Z64, V64, N64, or ROM byte order
    -> validate the supported NTSC-U retail revision
    -> create and validate the required TLB-free runtime image in app storage
    -> start the AOT runtime
```

Preview 2 performs the conversion on device and reuses a valid existing Preview
1 runtime image during an in-place update. No ROM or extracted asset is copied
to the repository or app bundle. The active and backup GoldenEye EEP4K saves
remain separate from the runtime image and from user preferences. Installation
evidence must verify all of those payloads independently.

## Rendering and presentation

RT64 interprets GoldenEye's display lists and emits Metal work through Plume.
UIKit or AppKit owns the view and `CAMetalLayer`; RT64 owns the swap-chain and
renderer contract. The host passes non-owning Apple object handles and does not
encode a second scene renderer.

On mobile, a one-point black trailing-edge overlay masks a measured two-physical-
pixel host sampling seam without changing RT64's drawable or viewport. The Mac
host does not yet apply the equivalent mask. Replacing RT64's window-size
contract with raw `CAMetalLayer.drawableSize` is prohibited: the experiment
expanded the small edge seam into missing, duplicated, and blue world geometry.

GoldenEye renders split-screen players sequentially into a shared framebuffer.
The accepted Preview 2 repair scopes full-frame operations to the active player
viewport and preserves GoldenEye's lower-player shifted depth-image address.
That repair removed the former large black/checkerboard corruption on physical
iPad. Residual lighting flicker remains a separate investigation and does not
currently justify reopening the accepted depth-clear repair.

## Timing

The pinned primary game loop runs one game iteration per VI at native 60 Hz.
The apparent `desiredFPS = 30` frame-skip variables in the upstream patch are
dead state: they are assigned but not consumed. Presentation refresh settings
do not change that simulation cadence.

This distinction matters:

- several original per-rendered-frame counters run too quickly at a fixed 60 Hz;
- the confirmed player/guard automatic-fire defect is tracked in
  [`TECH_DEBT.md`](TECH_DEBT.md);
- modern-look input currently applies a fixed angular step per game frame; and
- unlocking or uncapping the simulation would compound both defects.

High-refresh work therefore belongs behind a fixed-simulation/render-
interpolation design and determinism gates, not a faster game loop.

## Input

### Current primary-runtime model

The iPhone/iPad host currently selects the first connected extended
`GCController`. In normal play it publishes that controller to N64 port 1 and
hides touch. Without a controller, touch publishes to port 1. The opt-in
two-player diagnostic publishes the controller to port 1 and touch to port 2;
the four-player diagnostic only advertises neutral ports 3 and 4 so rendering
can be tested.

This is not a complete multi-controller ownership model. Real controllers 2–4,
stable slot assignment, sleep/disconnect/reconnect, foreground recovery, and
Mac-specific multi-controller policy remain unimplemented. The four-slot
`InputCoordinator` in the legacy MGB64 path is a useful design reference but is
not wired to the primary runtime.

Disconnecting the only controller while the two-player diagnostic is active
currently collapses the test mode and can route touch back to port 1 mid-match.
That is a confirmed ownership leak, not accepted reconnect behavior.

### Control semantics

Touch look accumulates relative deltas and the game-side modern-controls patch
consumes them once per publication. Physical right-stick look can instead use
the original N64 C-button mode. The current modern touch MOVE stick still
inherits GoldenEye's original horizontal analog behavior, so it turns rather
than sidesteps. GitHub issue #8 tracks the missing modern-FPS mapping: MOVE
horizontal should strafe while LOOK horizontal turns, with the original
C-button mode preserved separately and menu navigation unchanged.

Both mobile and Mac publish input from main-run-loop timers. Main-thread drift
can therefore surface as delayed buttons, movement, and look together, even
though rendering and audio consumption live on other threads.

## Audio

GoldenEye produces stereo PCM through the project-owned bounded ring.
`AVAudioSourceNode` consumes it and `AVAudioEngine` handles device-rate output.
Mobile adds `AVAudioSession` activation, interruption, and route-change policy;
Mac uses the same basic ring without the mobile session owner.

Two debts are architecturally important:

1. the game calls a `set_frequency` host callback, but the current project host
   logs and ignores it while Swift creates a 22,050 Hz source format; and
2. foreground reset currently mutates consumer-owned ring fields from the
   lifecycle thread, which can race an audio restart in an unusual
   interruption/background ordering.

Zero drop/underrun counters prove the ring did not starve in that observed run;
they do not rule out rate mismatch, discontinuity, route transition, or audible
static.

## Lifecycle and threading

Mobile distinguishes transient `.inactive` state from `.background`.
Screenshots and system overlays can make the app inactive briefly, so GoldenPad
releases touch but deliberately keeps RT64 presentation active. Backgrounding
deactivates audio and then marks the surface inactive. Foregrounding reverses
that sequence.

At the pinned RT64 revision, the game/VI thread busy-spins when the bounded
present ring is full. A throttled or unavailable drawable can therefore produce
a recoverable multi-second simulation-and-audio stall. Plume also contains one
unbounded Metal command-fence wait; whether current reports include a permanent
fence stall is unknown until a physical lifecycle matrix reproduces it. The
first change must be bounded counters and reproduction, not a lifecycle rewrite.

The Mac Plume patch coalesces per-present AppKit window and refresh queries to at
most one pending update of each kind. Removing that bound would again let the
render thread starve the main queue that owns input and host timers.

## Local and network multiplayer

Current multiplayer is GoldenEye split-screen inside one runtime. It is not
peer-to-peer or online play. Transport, discovery, or GameKit alone cannot turn
it into network play because all peers need a defined simulation-ownership and
synchronization model.

The primary runtime currently exposes controller polling but no validated
savestate/serialization or rollback seam. Network work therefore begins only
after deterministic local controller ownership and state-hash experiments. The
staged feasibility and compatibility gates are documented in
[`MULTIPLAYER_ROADMAP.md`](MULTIPLAYER_ROADMAP.md).

## Build targets

| Target | Role | Current product status |
| --- | --- | --- |
| `GoldenPadRecompPrototype` | Primary iPhone/iPad AOT + RT64 application, packaged to users as GoldenPad | Preview 3 |
| `GoldenPadMac` | Native arm64 AppKit/SwiftUI host for the same AOT + RT64 path | Alpha |
| `GoldenPad` | MGB64/Fast3D mobile application | `GoldenPad Legacy`, comparison/fallback only |

The product names overlap historically, so runtime claims should name the
architecture, not infer it from a target's executable name.

## Legacy MGB64 boundary

MGB64 remains valuable as a source-level behavior oracle, portable-decomp
reference, and regression fallback. Its cooperative scheduler, four-slot input
coordinator, Fast3D renderer, 2 KiB host save experiments, and extensive
diagnostic mission probes belong to the legacy target. They must not be used as
evidence that the primary RT64 runtime already has four-controller ownership,
network determinism, or the same save/audio implementation.

Targeted MGB64 fixes may inform a primary-runtime patch only after the equivalent
GoldenEye function and behavior are traced at the exact primary pin. Bulk
merging MGB64, the completed decompilation, or a different renderer is outside
the current repair strategy.
