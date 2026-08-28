# Multiplayer roadmap

Updated: 2026-08-28

GoldenPad currently has **experimental local split-screen in one runtime** and
a separate research-only LAN v3 diagnostic. It does not have supported LAN,
internet, relay, dedicated-server, or rollback multiplayer. The physical v3
iPad/iPhone replay failed closed at frame 30 on a globals-only canonical
mismatch. This document separates accepted render work from controller
ownership and diagnostic network research.

## Current product boundary

| Capability | Current status | Evidence boundary |
| --- | --- | --- |
| Original GoldenEye multiplayer menus and match rules | Present | Owned by the game runtime |
| Two-player controller P1 + touch P2 diagnostic | Implemented, experimental | Simulator interaction and bounded physical use; not reconnect acceptance |
| Four-player render diagnostic | Stable experimental baseline | Physical iPad kept four neutral/test views coherent; slight lighting flicker remains |
| Real controller ports 2–4 | Not implemented in the primary host | Core ports exist, but Swift binds only the first extended controller |
| Controller disconnect/reconnect ownership | Not accepted | Disconnect can collapse test mode and route touch back to P1 |
| Apple-Silicon Mac multiplayer assignment | Not implemented | Mac has no touch-P2 policy and also binds one controller |
| LAN or peer-to-peer play | Diagnostic v3 only; physical synchronization failed | Discovery, slots, exact N+4 input, pacing, and desync stop exist; iPad/iPhone globals diverged at frame 30 |
| Internet matchmaking/relay | Not implemented | No transport service or session identity handshake |
| Savestate/rollback | No validated seam | Do not describe rollback as available or near-complete |

## Frozen Preview 2 rendering baseline

The former RT64 KSEG1 address-mask crash and the large black/checkerboard
split-screen corruption have targeted repairs. GoldenEye renders players
sequentially into a shared framebuffer; the accepted patch scopes sky,
background, fade, and depth-clear work to the active viewport and makes each
lower-player clear use the same shifted depth-image address used for rendering.

Physical four-player testing of executable SHA-256
`0976dcdfd17de60beda8e8e60ccff3fc81da7da0b2ef43f159cdea061149677d`
kept all four quadrants coherent across 3,336 consecutive frame comparisons and
54,652 presented VI updates, with zero reported audio drops or underruns in that
run. Slight lighting flicker remained. This establishes a stable experimental
render baseline, not complete multiplayer acceptance.

Do not reopen the depth-address repair unless the former large corruption
returns or a bounded trace directly implicates it. Matched isolated runs found
zero depth-`formatChanged` rebuilds, but that counter lacked a known-active
calibration and non-format upload coverage. A fixed-player-order diagnostic
showed no systematic improvement and was reverted. The residual flicker remains
unclassified; the next evidence is fixed-scene physical capture.

## Local multiplayer blockers

### 1. Stable controller ownership

The primary iPhone/iPad input host selects
`GCController.controllers().first(where: { $0.extendedGamepad != nil })`. The
two-player mode is a flag-controlled diagnostic: controller P1 plus touch P2.
The four-player mode advertises neutral P3/P4 ports for render testing. The
four-slot model in the legacy MGB64 `InputCoordinator` is not wired to this
runtime.

The production ownership model needs:

- deterministic first-free assignment for up to four extended controllers;
- stable identity when devices sleep, disconnect, reconnect, or reorder;
- no duplicate port ownership and no array-index-as-player assumption;
- a neutral frame on loss before any reassignment;
- explicit touch ownership that never moves mid-match implicitly;
- foreground reconciliation without replaying held buttons; and
- a separate Mac policy, because Mac has no touch player.

The first gate is a synthetic lifecycle probe, followed by physical two-, three-,
and four-controller acceptance. Build success or the neutral four-port render
test does not establish this.

### 2. Residual lighting flicker

The old large corruption is closed for the frozen baseline. The remaining
flicker must be treated as a temporal defect:

1. keep the accepted depth-address repair frozen;
2. capture continuous physical video at a fixed, preferably stationary scene;
   a clean still is insufficient;
3. identify the first affected frame and viewport before adding telemetry;
4. if later telemetry is justified, count non-`formatChanged` uploads as well
   as rebuilds and calibrate the counters on a known-active path; and
5. re-run the exact two-/four-player and single-player regression gates after
   any candidate.

### 3. Gameplay input semantics

GitHub issue #8 is independent of multi-controller ownership. Modern MOVE
horizontal input should strafe while LOOK horizontal input turns; the original
N64 C-button mode must remain available separately. Fix and accept this before
using movement traces as a multiplayer determinism signal.

## Network feasibility

### The hard problem

Discovery and packet transport are feasible on Apple platforms. The hard problem
is deciding who owns simulation state and keeping two native game runtimes in
agreement. Current local multiplayer has one process, one game clock, one RNG
stream, and one shared memory image. Network play would split those assumptions.

The isolated LAN diagnostic now supplies authoritative frame identity, a
canonical component hash, exact future-frame input, and fail-closed desync
detection. It still has no validated complete state serialization, rewind, or
rollback restore. More importantly, the first physical v3 replay produced a
globals-only mismatch at frame 30. Therefore a matchmaking UI or packet demo
would not demonstrate playable network multiplayer.

### Feasibility matrix

| Model | Technical feasibility | Missing foundation | Recommended disposition |
| --- | --- | --- | --- |
| Same-device 2–4 player split-screen | High | Real controller ownership, lifecycle acceptance, residual flicker decision | Finish first |
| Two Apple devices on one LAN, input-delay lockstep | Transport/protocol proven; physical determinism failed | Identify the differing canonical global, prove cross-device agreement, then latency/jitter | Continue only with v4 diagnostic |
| Direct internet peer-to-peer | Plausible transport, high product complexity | Everything above plus discovery, NAT traversal/relay fallback, authentication, reconnect, latency adaptation | Do not start before LAN proof |
| GameKit real-time match | Plausible Apple-only transport/matchmaking | Same synchronization work; GameKit does not make simulations deterministic | Evaluate only after protocol proof |
| Relay-assisted internet sessions | Plausible | Protocol, relay service, operations, abuse controls, privacy, monitoring | Later product phase |
| Authoritative hosted game server | Theoretically possible, major rearchitecture | Headless authoritative runtime, state replication, reconciliation, server fleet | Not a near-term GoldenPad feature |
| Rollback netcode | Blocked today | Deterministic savestate, restore, rewind, side-effect control, resimulation budget | Do not promise |

### Recommended transport direction

For the first two-device LAN experiment, use Apple's Network framework with
Bonjour discovery, a versioned application protocol, encrypted connections, and
peer-to-peer interface support. It keeps transport separate from simulation and
does not require an internet service. GameKit can be evaluated later for Apple-
ecosystem matchmaking and relay-like connectivity, but it does not replace the
protocol, compatibility, determinism, or state-ownership work.

The disposable v3 lab used Multipeer Connectivity for encrypted nearby
discovery/session transport because it kept the experiment small. That choice
is not a production transport decision. The application protocol remains the
important boundary; Network.framework or GameKit can be reconsidered only
after deterministic agreement passes.

### Required session handshake

Before a peer can join, both sides must agree on:

- protocol and state-schema version;
- GoldenPad build and patch-set identity;
- exact generated-runtime and upstream dependency identities;
- supported retail revision / converted runtime identity;
- gameplay-affecting settings, cheats, region/timing policy, and enabled mods;
- player count, port ownership, match rules, stage, and seed policy; and
- transport capabilities and maximum accepted input delay.

No ROM bytes, extracted assets, saves, or signing data may cross the network.
Do not include persistent device identifiers in the protocol or compatibility
record; use an ephemeral session/player identity instead.
Reject an incompatible peer with a specific reason before starting simulation.

### Synchronization experiments

The v3 protocol is disposable and measurement-focused. It implemented the
following sequence:

1. run the same build and supported data on two local devices;
2. exchange frame-numbered neutral/controller inputs with a fixed input delay;
3. record compact state hashes at stable game-thread boundaries;
4. start in a deterministic menu or controlled match setup;
5. fail closed on a missing frame or hash mismatch and preserve the first
   divergent frame number;
6. test latency, duplication, reordering, packet loss, backgrounding, and peer
   disconnect without attempting silent recovery; and
7. only after repeatable agreement, decide between delayed lockstep, an
   authoritative peer, state replication, or the much larger rollback path.

An input exchange that renders two screens is research evidence. It is not
online-multiplayer acceptance until real matches, reconnect policy, long-session
desync checks, compatibility rejection, and adverse-network tests pass.

Physical v3 result: the iPad parked at game/scheduler VI 1092/1093 and the
iPhone at 1091/1092. Frame-30 player and prop hashes matched; globals differed.
Both runtimes deliberately paused and no new crash report appeared. The next
protocol must log the 19 individual canonical global words before attempting a
repair. See
[`NETPLAY_PHYSICAL_CHECKPOINT_2026-08-28.md`](NETPLAY_PHYSICAL_CHECKPOINT_2026-08-28.md).

## Network go/no-go gate

Network implementation is a **go for the bounded M3 research experiment only**
when every condition below is true:

- real two- to four-controller local ownership is deterministic and physically
  accepted, including disconnect/reconnect and foreground recovery;
- TD-01 timing authenticity and TD-02 modern movement semantics are either fixed
  and frozen or explicitly encoded in the compatibility handshake;
- a stable frame number and compact state hash remain identical across at least
  three repeated controlled local matches of the target duration;
- the current build has no unresolved permanent lifecycle freeze, and network
  background/disconnect policy is fail-closed;
- the two target devices have measured CPU, memory, thermal, and frame-time
  headroom for hashing and input exchange;
- protocol, build, runtime, ROM-revision, patch, settings, mod, and match identity
  fields are documented before connection; and
- no ROM bytes, extracted data, save payload, device identifier, or signing data
  is required by the protocol.

The current decision is **no-go beyond bounded diagnostic research** because
the physical peers diverged at frame 30 and v3 retained only the aggregate
global hash, not the individual differing word. The general decision is no-go
if identical local runs diverge without a diagnosable
frame, controller ownership can change implicitly, the only proposal is
transport without state ownership, or success depends on unvalidated savestate/
rollback behavior.

Passing this gate authorizes a disposable two-device LAN protocol and evidence
collection. It does not authorize public matchmaking, an internet service, or a
multiplayer support claim.

## Enhanced local visuals

GoldenEye applies multiplayer reductions to view distance, fog, debris, glass,
smoke, scorch marks, casings, and decorative stage props. Higher RT64 output
resolution does not remove the original stage, effect, vertex, display-list, or
memory limits.

Evaluate separately:

1. view distance and model LOD;
2. transient effects and fixed buffers; and
3. decorative props omitted by multiplayer setup data.

Never restore AI, collision, paths, spawns, or gameplay-bearing single-player
objects under a visual-quality label. Visual enhancement comes after local
ownership/flicker acceptance and must not be bundled with network work.

## Milestones and gates

### M0 — Preserve the render baseline

- Old black/checkerboard corruption does not recur in two- or four-player video.
- Single-player rendering, audio, touch, controller P1, saves, and lifecycle stay
  unchanged.
- Residual flicker remains disclosed until its own gate closes.

### M1 — Production local ownership

- Synthetic lifecycle probe passes every connect/disconnect/reconnect order.
- Touch never changes player implicitly and all lost ports publish neutral.
- Two to four physical controllers retain stable ports on supported devices.
- iPhone/iPad and Mac policies are tested separately.

### M2 — Determinism observability

- A stable frame number and compact game-state hash are defined.
- Identical local runs remain hash-identical for the target match interval.
- Timing-authenticity and modern movement fixes are frozen before the baseline.

### M3 — Two-device LAN research

- **Partial/failing v3 checkpoint.** Protocol compatibility rejects old builds;
  discovery, slots, ready/start, frame-numbered input, pacing, and desync stop
  work on an iPad/iPhone pair.
- Physical canonical globals diverged at frame 30 while players/props matched.
- v4 must expose the individual 19-word snapshot and pass different bootstrap
  VI counts before loss/delay/app-switch testing proceeds.
- No claim beyond research is made.

### M4 — Product network decision

Choose internet P2P/GameKit/relay/authoritative direction only from M3 evidence.
Document service cost, privacy, abuse handling, reconnect behavior, latency
budget, compatibility policy, and an explicit rollback decision before building
public matchmaking.

## Current sequence

1. Preserve the accepted Preview 2 viewport/depth repair.
2. Fix modern sidestep semantics and add the controller-lifecycle probe.
3. Implement and physically accept stable real 2–4 controller ownership.
4. Run the depth-rebuild flicker discriminator and decide whether a renderer
   repair is proportionate.
5. Preserve the implemented deterministic frame/state observability.
6. Resume the failed two-device LAN experiment with the v4 word-level
   diagnostic; do not merely repeat v3.
7. Decide whether internet multiplayer is justified only after physical
   canonical agreement.
8. Consider enhanced visuals independently.
