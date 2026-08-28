# Netplay determinism experiment goal loop

Updated: 2026-08-27

> Historical first determinism loop. Later Simulator work reached a conditional
> go, but the physical LAN v3 replay failed at frame 30 on a globals-only
> mismatch. Resume from
> [`NETPLAY_PHYSICAL_CHECKPOINT_2026-08-28.md`](NETPLAY_PHYSICAL_CHECKPOINT_2026-08-28.md).

## Goal

Prove or falsify the minimum simulation property required for GoldenPad online
multiplayer: two independent Preview 8 runtimes that begin from the same private
game data and receive the same ordered controller inputs must produce the same
game-memory state at the same controller-poll boundary.

This is a diagnostic experiment. It does not add matchmaking, transport,
peer-to-peer connectivity, a relay, rollback, or a public multiplayer claim.

## Frozen control

- Source control: `origin/main` commit
  `7e0926c9513639e98ad20e45089647c0acbc7625`.
- Product control: accepted Preview 8 mobile behavior.
- Renderer/depth, controls, audio, ROM conversion, saves, lifecycle, and release
  settings remain unchanged unless a measured determinism failure later points
  to one of those seams.
- The user's installed app, ROMs, saves, preferences, and current dirty checkout
  are not modified by this experiment.

## Why this is the first experiment

Input-delay lockstep does not require rollback when every runtime waits for
confirmed inputs before advancing. It does require deterministic simulation and
a shared initial state. GoldenPad already exposes four controller ports, but its
current runtime has no stable frame identity, state checksum, serialization, or
rollback facility.

The current runtime also contains known possible sources of divergence:

- VI delivery is derived from each device's wall clock and can drop a nonblocking
  retrace message.
- `osGetCount`, `osGetTime`, and timer delivery use local wall-clock time.
- the game receives a remaining-audio count derived from each device's local
  audio consumer;
- renderer/RSP work may mutate RDRAM concurrently with an unsafe observation
  boundary; and
- local save/configuration, build, generated patch, ROM, and settings identity
  must match before any trace comparison is meaningful.

The experiment observes these risks before proposing a synchronization fix.

## Diagnostic contract

Launch with `--netplay-determinism-probe`.

The diagnostic mode:

1. disables live controller/touch publication at the native callback boundary;
2. supplies the same built-in, poll-numbered controller script on every run;
3. counts actual VI callbacks separately from controller polls;
4. samples the base 8 MiB of N64 RDRAM at selected poll boundaries;
5. hashes eight 1 MiB regions and 128 64 KiB pages with XXH3, plus 4 KiB
   blocks inside empirically hot pages, and folds the regions into one state
   hash;
6. immediately repeats each sample to report whether the observation boundary
   was stable during both reads;
7. records the exact input, menu, stage, pending stage, VI count, deterministic
   clock-read count, state hash, and regional/page hashes in a separate trace
   file; and
8. stops recording after the bounded script completes.

The fixed script starts neutral, emits bounded Start pulses through the stock
front end, then publishes movement, turn, combined movement/turn, and Fire
windows. It never invokes a game menu, stage, player, or camera function
directly. A trace remains useful even if the stock front-end timing prevents the
script from reaching Dam: the exact ordered inputs and sampled state are still
comparable.

## Trace comparison

Use:

```sh
scripts/compare-recomp-determinism-traces.py TRACE_A TRACE_B
```

The comparator rejects mismatched headers, poll sets, or input streams before
comparing state. It reports the first stable state mismatch and the 1 MiB RDRAM
regions, 64 KiB pages, and selected 4 KiB blocks that differ. Samples marked
unstable are reported separately and are not treated as proof of cross-run
divergence.

## Reproduce the experiment

Keep all output in an ignored build directory and use the dedicated experiment
bundle ID `com.chrissotraidis.goldenpad.determinism`.

First, produce a copied runtime archive containing the diagnostic-only clock
translation object:

```sh
GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR=/path/to/N64ModernRuntime \
GOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR=/path/to/pinned/ios-simulator/archives \
GOLDENPAD_DETERMINISM_RUNTIME_OUTPUT_DIR=/path/to/new/ignored/output \
scripts/build-recomp-determinism-runtime-object.sh
```

Configure the GoldenPad Simulator build with the helper's `source` and
`archives` outputs as `GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR` and
`GOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR`. Use the accepted Preview 8 AOT and RT64
inputs, the dedicated bundle ID above, and `GoldenPad Determinism` as the
display name. Never put a ROM in the app bundle.

Then collect each clean run:

```sh
scripts/run-recomp-determinism-probe.sh \
    SIMULATOR_UDID \
    /path/to/GoldenPadRecompPrototype.app \
    /private/path/to/GoldenEye_TLBFREE.z64 \
    /path/to/new/output-trace.log
```

The runner refuses a non-experiment bundle, an unexpected ROM size, or an
existing output trace. It reinstalls only the dedicated experiment bundle on
the explicit Simulator, copies the private ROM only into that fresh container,
waits for the bounded completion marker, and copies out the hash-only trace.
It does not modify the source ROM or any Preview 8 installation.

## Result on 2026-08-27

**Decision: offline determinism failed. Do not build transport, matchmaking, or
a public lobby on the current runtime.**

Two fresh full runs of the unmodified Preview 8 runtime used the same arm64
Simulator app, converted ROM, empty app state, and 3,600-poll input script. Both
reached live Dam gameplay and every recorded sample was stable inside its own
run. They nevertheless diverged at poll 1:

- VI callback identity was already `20` versus `19`;
- the menu/stage/pending tuple was identical;
- 1 MiB RDRAM regions 0 and 3 differed; and
- the divergence persisted through the gameplay interval.

Source inspection identified a direct gameplay leak: GoldenEye calls
`osGetCount` to seed its RNG, while N64ModernRuntime implements that count from
the host wall clock. The first bounded fix patched only the translated
`osGetCount` and `osGetTime` calls during the diagnostic, replacing host time
with an ordered deterministic clock. Two more fresh, complete runs still
diverged at poll 1 even when the compared VI counts matched.

The final scripted reproducibility pair used the complete checked-in probe and
runner. Both traces completed at poll 3,600, both reported VI count 19 at poll
1, and both had the same deterministic-clock read count. The first stable
mismatch was still poll 1, in 64 KiB pages 5, 6, and 59, narrowed to
`0x8005d000`, `0x80060000`, and `0x803b3000`.

The refined page map localized early differences to these 4 KiB areas:

- `0x80023000`: VI, speed-graph, debug, stage, and allocator globals;
- `0x8005d000`: emulated N64 threads, scheduler queues, and VI modes;
- `0x80060000`: speed-graph and VI state; and
- `0x803b3000`: audio workspace.

By poll 450, both runs still reported the same menu states, but asynchronous
VI/RSP/audio work had spread differences through additional scheduler,
controller, framebuffer/workspace, and task-memory pages. This is not evidence
that the GoldenEye rules themselves are random. It is evidence that the current
runtime exposes host scheduling and device-event order inside the emulated
state, so a full-RDRAM input-lockstep checksum cannot converge today.

The deterministic-clock prototype intentionally used a crude ordered-call
clock. It removed the RNG seed's wall-clock dependency but slowed stock menu
pacing and did not make the native-thread event system deterministic. It is a
diagnostic result, not a candidate release clock.

The second Apple-device-class repetitions were skipped because the stricter
same-device gate had already failed twice. A cross-device pass cannot rescue a
same-device failure.

## Architecture decision

The experiment does not say that GoldenEye online multiplayer is impossible.
It says the proposed low-bandwidth design, where every iPhone or iPad runs its
own copy and peers exchange only ordered inputs, is not ready to implement on
the current runtime.

There are now only two honest branches:

1. Build a deterministic runtime mode that advances VI, timer, RSP completion,
   audio, and controller events from one logical frame scheduler, then rerun
   this exact offline gate. This changes GoldenPad/runtime code, not the user's
   ROM bytes, but it is substantial engine work.
2. Keep one authoritative runtime and transmit rendered output/state to the
   other players. That avoids deterministic replicas but reintroduces the
   latency and streaming compromises already rejected for the product.

Sending periodic authoritative state to native-rendering clients is not a
shortcut yet: GoldenPad still lacks complete state capture, restore,
side-effect suppression, and resimulation. A lobby service, passwords, chat,
STUN/TURN, or a relay can be built independently, but none of those components
solve this failed simulation gate.

The next useful engine experiment, if this branch is funded, is a disposable
single-logical-scheduler mode. It must make emulated device events advance only
when the game consumes the next confirmed input frame. It should not begin with
WebRTC, GameKit, a server room, ROM UI changes, or rollback.

## Goal loop

Repeat this loop until a stop or promotion gate is reached:

1. **Freeze:** record source, generated runtime, ROM identity, settings, save
   state, Simulator/device, and exact launch arguments.
2. **Predict:** name one expected result and the next action for pass, mismatch,
   or unstable sampling.
3. **Build:** make one diagnostic-only change in the isolated experiment branch.
4. **Verify:** run source/contract checks and the complete game-bearing build.
5. **Run:** collect two clean independent traces with identical inputs.
6. **Compare:** preserve only hashes, counters, build identities, and controller
   input metadata. Do not publish or commit ROMs, saves, screenshots, extracted
   assets, or raw memory.
7. **Classify:** record PASS, DIVERGED at poll N, or INCONCLUSIVE because the
   sampling boundary was unstable.
8. **Narrow:** if divergent, change only the highest-confidence owner and repeat
   from the frozen control. If the hypothesis is rejected, revert it.
9. **Promote or stop:** proceed to a two-device LAN lockstep experiment only
   after the acceptance gate below passes.

## Acceptance gate

The offline determinism foundation passes only when:

- three clean runs on one Simulator and two clean runs on a second Apple-device
  class use byte-identical app/runtime and private ROM identities;
- every comparison has the exact same poll-numbered input stream;
- the trace reaches its bounded completion marker;
- stable state hashes agree at every comparable sample;
- the scripted run reaches at least one live gameplay interval;
- no accepted Preview 8 behavior or protected user data is changed; and
- the result is reproducible from documented commands.

Passing this gate authorizes a disposable two-device LAN lockstep experiment.
It does not authorize a lobby, internet service, beta announcement, or support
claim.

## Stop and branch rules

- If repeated reads disagree, stop treating the poll seam as a stable boundary;
  add a measured game-thread/RSP barrier before interpreting cross-run hashes.
- If hashes diverge, preserve the first poll and differing RDRAM regions. Do not
  add transport.
- If wall-clock VI/count/timer behavior is the first owner, create a diagnostic
  deterministic-clock mode separately. Do not alter normal Preview 8 timing.
- If local audio feedback is the first owner, replace only the game-visible
  audio count with a deterministic diagnostic schedule. Do not retune release
  audio from this experiment.
- If clean initial state cannot be reproduced without copying private data over
  the network, stop. Netplay may compare identities but must never transmit ROM
  bytes, extracted assets, saves, signing data, or device identifiers.
- Rollback remains out of scope until complete state capture, restore, side-
  effect suppression, and resimulation are independently proven.

## Later LAN gate

If offline determinism passes, the next experiment uses a fixed-delay lockstep
protocol on two local devices:

- exchange only frame/poll-numbered inputs and periodic checksums;
- wait rather than predict when an input is missing;
- fail closed on mismatch, backgrounding, or disconnect;
- use a strict build/runtime/ROM/settings handshake; and
- measure latency before choosing direct WebRTC/GameKit or relay transport.
