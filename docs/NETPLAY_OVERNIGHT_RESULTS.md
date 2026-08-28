# GoldenPad netplay Simulator result

Date: 2026-08-28

## Decision

**CONDITIONAL GO for an ordered-input online prototype. Not ready to ship as
online multiplayer.**

GoldenPad can reach a stock four-player GoldenEye match without changing ROM
bytes, run four independent controller streams through that match, keep a
source-owned simulation projection deterministic across fresh runtimes, add a
three-logical-frame input buffer, and present any assigned split-screen
quadrant full-screen on iPadOS.

The accepted Preview runtime does not do this by itself. The experiment needs
an app/runtime scheduler repair, synchronized room seed and epoch, exact-frame
input latching, and a compatibility handshake. No real two-device transport,
room service, packet-loss policy, or desync recovery exists yet. Public online
support must not be announced from this result alone.

## Straight answer

- **Does the ROM need to be modified?** No. The experiment leaves the converted
  ROM byte-for-byte unchanged. It modifies the GoldenPad runtime and generated
  recomp patch output, then drives the original multiplayer menus with ordinary
  controller input.
- **Can each device show one player's view?** Yes as a host presentation
  technique. RT64 still renders the authentic four-way framebuffer; SwiftUI
  magnifies and clips the assigned quadrant. All four anchors were exercised on
  the same iPad Simulator.
- **Can clients remain synchronized by exchanging inputs?** Yes in the tested
  deterministic diagnostic. A normal run and a one-core CPU-stressed run
  matched through 10,620 logical multiplayer frames.
- **Can an existing GoldenEye server be reused?** Not directly. A public
  `GoldenEye-Recomp-Server` exists, but it serves a separate native recomp of
  the Xbox 360 GoldenEye build and relays that game's built-in System Link
  protocol. GoldenPad is an N64 NTSC-U static recomp and does not speak that
  protocol.
- **Is this shippable globally today?** No. The next go/no-go gate is a real
  ordered-input relay connected to two independent clients, followed by two
  physical Apple devices on real networks.

## What was built

The work is isolated behind the diagnostic bundle
`com.chrissotraidis.goldenpad.determinism` and command-line probe switches.
The accepted Preview bundle and ROM importer were not replaced.

### Canonical simulation checksum

The trace distinguishes game state from host/runtime scratch:

- source-owned multiplayer globals, RNG, scenario, timers, and stage/menu
  state;
- four `player_data` records plus selected live player fields; and
- the 600-entry prop pool, excluding the source-proven renderer-computed
  `PropRecord::zDepth` field.

Full 8 MiB RDRAM, region, page, and hot-block hashes remain in the trace as
diagnostics, but they are not used as the lockstep source of truth. Audio,
framebuffer, renderer, N64 OS, and asynchronous runtime scratch legitimately
differ between processes.

### Stock four-player route

The probe advertises four standard N64 controller ports and uses only ordinary
inputs to:

1. traverse the original front end;
2. select `MULTIPLAYER`;
3. start the stock default multiplayer options; and
4. reach menu 11, stage 38, with four allocated players.

Distinct overlapping movement and button windows then exercise all four ports.
No internal multiplayer setup function is called and no in-ROM menu item is
added.

### Deterministic scheduler

The accepted wall-clock path failed because GoldenEye's frame delta depended on
when the host thread woke. Two otherwise identical runs produced
`speedgraphframes` values of 5 and 6, then diverged in RNG, players, and props.

The diagnostic repair:

- sets a room seed before the stock multiplayer Start edge;
- establishes a room-relative VI/count epoch;
- resets GoldenEye's frame-timing globals at that boundary;
- advances exactly one GoldenEye logical frame at each accepted game step; and
- latches controller state by GoldenEye logical frame rather than host poll.

The generated direct calls to both frame-wait paths had to be covered. A
partial hook kept idle state aligned but diverged after movement began.

### Fixed-delay input buffer

The final probe applies each gameplay input three logical frames after its
source frame. At 60 logical frames per second this is 50 ms of deliberate input
delay before any real network allowance. A production room must choose a delay
from measured round-trip time and jitter; three frames is a protocol experiment,
not a universal latency setting.

### Assigned-quadrant presentation

`--netplay-quadrant=1` through `=4` map to the four SwiftUI anchors. A 2x
presentation transform enlarges the selected quarter while clipping the other
three. It does not resize the CAMetalLayer, alter RT64's drawable contract, or
change GoldenEye's viewport state.

Player 1, 2, 3, and 4 were each captured full-screen. A Player 4 crop run also
matched an uncropped run for 208 canonical samples through logical frame 2460,
so the presentation transform did not feed back into tested simulation state.

## Test results

| Experiment | Result |
| --- | --- |
| Accepted wall-clock runtime, fresh processes | Canonical divergence almost immediately |
| Synchronized seed and room-relative VI only | Diverged when host-derived frame deltas differed |
| Fixed frame step without exact-frame input latch | Idle match aligned through frame 389; movement exposed input-latch nondeterminism |
| Fixed step plus direct logical-frame latch | 196/196 shared samples matched through frame 2400 |
| Three-frame fixed-delay input path | 215/215 shared samples matched through frame 2670 |
| Player 4 full-screen crop versus uncropped control | 208/208 shared samples matched through frame 2460 |
| 16,000-poll normal versus one-core CPU-stressed run | 480/480 shared samples matched through logical frame 10,620 |

In the long test, full-RDRAM hashes differed at all 480 matching logical-frame
samples. The canonical globals, four-player state, and prop hashes matched at
all 480. This is the intended distinction between deterministic gameplay and
nondeterministic audiovisual/runtime scratch.

## Graphics investigation

The same sole iPad Simulator produced an 87.92-second continuous four-player
capture. At one-second inspection intervals:

- the former large black/checkerboard split-screen corruption did not appear;
- corruption did not recover and migrate between quadrants;
- flat brown/grey views followed players turning into nearby walls; and
- all four quadrant crops showed a coherent camera and radar.

This rules out sustained or migrating catastrophic corruption in that
Simulator run. It does not rule out a subsecond lighting flicker or replace the
required frame-by-frame physical-device gate.

The existing RT64 depth `formatChanged` counter stayed at zero throughout a
separate scripted four-player run. This agrees with the current project notes,
but it does **not** close residual flicker: the counter lacks positive
calibration and does not count non-`formatChanged` depth uploads. The frozen
Preview 2 shifted-depth-address repair was not changed. The next graphics gate
remains continuous physical-device capture followed, only if a first affected
frame is found, by calibrated counters for both upload paths.

## External protocol research

The result is consistent with established emulator netplay, but none of these
implementations can be linked into GoldenPad unchanged:

- [Mupen64Plus's documented netplay protocol](https://mupen64plus.org/wiki/index.php/Mupen64Plus_v2.0_Core_Netplay_Protocol)
  uses a client/server model, UDP frame inputs, a server-owned event order, and
  client sync data. Its server is the input source of truth. This is the closest
  architectural analogue to the GoldenPad result.
- [Dolphin's netplay guide](https://blog.dolphin-emu.org/docs/guides/netplay-guide/)
  documents fixed input buffers, strict compatibility settings, controller-slot
  assignment, a traversal service, and a public room browser. Dolphin's code
  and state model are GameCube/Wii-specific; its protocol is not a reusable N64
  transport library.
- [RetroArch's netplay FAQ](https://github.com/libretro/docs/blob/master/docs/guides/netplay-faq.md)
  says its general save-state model is not practically suitable for N64. A
  rollback integration would also require complete fast save/restore support,
  which this GoldenPad experiment did not build.
- [simple64's archived netplay notes](https://github.com/simple64/simple64/wiki/Netplay-Features)
  describe a server-based, low-bandwidth N64 model that verifies ROM/emulator
  versions and exchanges inputs rather than graphics. That is supporting
  precedent, not drop-in code.
- [GoldenEye-Recomp-Server](https://github.com/SunJaycy/GoldenEye-Recomp-Server)
  is an Unlicense matchmaker and opaque UDP relay for a separate
  [Xbox 360 recompilation](https://github.com/SunJaycy/GoldenEye-Recomp).
  Its small directory/heartbeat/relay shape is useful reference, but its `GE02`
  System Link payload has no meaning to GoldenPad's N64 runtime.

## Smallest credible production architecture

The simplest global design is server-relayed lockstep, not pure peer-to-peer
and not a server running GoldenEye:

```text
GoldenPad lobby overlay
    | HTTPS/WSS: rooms, chat, passwords, readiness, compatibility
    v
Room/input relay
    | assigns P1-P4, seed, epoch and delay
    | orders frame-numbered input bundles
    | compares periodic canonical hashes
    v
P1 runtime       P2 runtime       P3 runtime       P4 runtime
full GE sim      full GE sim      full GE sim      full GE sim
crop quadrant 1 crop quadrant 2 crop quadrant 3 crop quadrant 4
```

All clients make outbound connections, which avoids requiring player port
forwarding. The relay is authoritative only for room membership, start
parameters, and ordered inputs. It does not simulate the world, stream video,
or receive ROM data.

The room handshake must include at least:

- protocol and GoldenPad build version;
- generated AOT/runtime compatibility ID;
- supported-ROM identity hash, never ROM bytes;
- deterministic scheduler/checksum version;
- graphics-independent gameplay settings;
- selected stock multiplayer settings;
- player-slot ownership;
- room seed, logical start epoch, and fixed delay; and
- periodic canonical checksum cadence.

The lobby belongs in the native three-dot overlay. `Online Multiplayer` opens a
native room browser before GoldenEye starts. Once everyone is ready, the app
drives the stock multiplayer route and settings; the game ROM never needs a new
folder page or online menu item.

## Remaining go/no-go gates

1. Connect the diagnostic input seam to a real ordered-input relay.
2. Run two independent clients simultaneously; sequential replays are strong
   determinism evidence but not transport evidence.
3. Stall safely when a required input bundle is late. Do not silently predict
   or reuse remote inputs in the first implementation.
4. Inject latency, jitter, reordering, duplication, loss, disconnect, and
   reconnect; determine a playable delay envelope.
5. Send periodic canonical hashes and fail closed on desync. State resync and
   rollback are later work, not assumed capabilities.
6. Validate slot ownership, touch/controller routing, readiness, host migration,
   and leaving a room.
7. Repeat on two physical iPhones/iPads over LAN, Wi-Fi, cellular, and a public
   relay, including mixed Apple chips and long thermal runs.
8. Regression-test the deterministic scheduler across single-player, menus,
   pause/watch transitions, audio, saves, and the existing fire-rate repair
   before considering it for a Preview build.

## Next experiment to implement

The next code slice should be one room with no public browser:

- a tiny ordered-input relay on localhost/LAN;
- two clients with an exact compatibility handshake;
- one fixed room seed and start epoch;
- four frame-numbered controller records per logical frame;
- a three-to-adjustable-frame buffer;
- periodic canonical hashes; and
- deliberate packet impairment with a hard timeout.

Only after that passes should the project add global discovery, passwords,
chat, invitations, moderation, or a public beta.
