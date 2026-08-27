# Netplay overnight Simulator goal loop

Started: 2026-08-28

## Objective

Determine whether GoldenPad can credibly support the proposed online model:
every participant runs the same GoldenEye multiplayer simulation locally,
peers exchange only frame-numbered inputs, and each device presents its assigned
split-screen quadrant.

The overnight result must be one of:

- **GO:** canonical multiplayer state converges across repeated independent
  runtimes and remains converged under timing stress;
- **CONDITIONAL GO:** a deterministic diagnostic runtime converges, but the
  accepted asynchronous runtime does not; or
- **NO-GO FOR THIS FOUNDATION:** canonical gameplay state still diverges after
  host time and asynchronous event ordering are removed at the smallest
  defensible seams.

This loop does not modify ROM bytes, build a public lobby, publish an IPA, or
claim online multiplayer support.

## Frozen inputs and safety boundary

- Accepted source baseline: Preview 8, `7e0926c9513639e98ad20e45089647c0acbc7625`.
- Prior experiment checkpoint: `05fd42a` on
  `codex/netplay-determinism-experiment`.
- Work only in the isolated nested checkout and dedicated bundle
  `com.chrissotraidis.goldenpad.determinism`.
- Use fresh disposable Simulator app containers for every run.
- The converted ROM is read-only input copied only into the disposable
  container. Never commit ROMs, saves, extracted assets, raw RDRAM, signing
  material, or local private paths.
- Preserve the user's working Preview checkout and all unrelated dirty files.

## Why the prior result is not yet the final answer

The prior full-RDRAM checksum correctly proved that the accepted runtime does
not reproduce byte-identical emulated memory. It also localized early
differences to VI, scheduler, controller queue, speed-graph, and audio
workspaces. Those areas can diverge without proving that player positions,
props, projectiles, scores, timers, and gameplay RNG have diverged.

The next test must therefore compare a canonical simulation projection while
continuing to report the full-memory mismatch separately. Excluding output or
OS scratch from the canonical projection is allowed only when source ownership
is established; empirical masking alone is not evidence.

## Seven-hour loop

### Loop 0: Freeze and predict

1. Record exact source/runtime/AOT/ROM/Simulator identities.
2. Preserve the prior failing traces outside source control.
3. Write the expected pass, divergence, and inconclusive branches before each
   code change.
4. Make one diagnostic hypothesis per iteration.

### Loop 1: Canonical-state ownership map

1. Map GoldenEye globals and pools for multiplayer mode, stage, scenario,
   match timer, RNG, player state, props, characters, projectiles, pickups, and
   scores.
2. Map noncanonical N64 OS, VI, RSP, audio, framebuffer, debug, and scheduler
   workspaces.
3. Define a versioned canonical checksum from explicit fields or owned ranges.
4. Include validity metadata so a checksum cannot silently pass while the test
   remains in menus or observes invalid pointers.

Promotion gate: the projection must detect a controlled gameplay-state change
and ignore only source-proven presentation/OS scratch changes.

### Loop 2: Stock four-player route

1. Replace the single-player menu script with a state-independent sequence of
   ordinary N64 inputs for four connected controller ports.
2. Traverse the stock multiplayer menus without calling internal setup
   functions or patching ROM data.
3. Reach a live four-player match and exercise movement, turning, firing, and
   at least two player ports.
4. Record a route-state marker proving the match is active.

Promotion gate: both clean runs reach the same live multiplayer setup and
consume byte-identical per-port input streams.

### Loop 3: Independent-process determinism

1. Run at least three fresh processes on one Simulator profile.
2. Compare input identity, canonical state, full state, VI identity, and clock
   identity at every sampled poll.
3. Locate the first canonical mismatch, not merely the first full-memory
   mismatch.
4. Repeat with an iPad Simulator profile only after the same-profile gate
   passes.

Promotion gate: canonical state matches through a live match. Full memory may
still differ only in source-proven noncanonical workspaces.

### Loop 4: Deterministic scheduler controls

If canonical state diverges, inspect the first owner and implement only the
smallest justified diagnostic control, in this order:

1. deterministic game-visible clock and RNG seed;
2. deterministic VI delivery and no dropped retrace message;
3. explicit RSP/RDP completion barrier before the next logical frame;
4. deterministic timer delivery;
5. removal of local audio-queue feedback from simulation decisions; and
6. a single logical event pump if narrower controls are insufficient.

After every change, repeat from a fresh container. Revert controls that do not
move the first canonical divergence.

Stop rule: if a single logical event pump still cannot reproduce canonical
state, classify this runtime as a no-go for input-only lockstep unless a much
larger engine rewrite is explicitly funded.

### Loop 5: Timing stress

Only after canonical convergence:

1. inject deterministic render delay, audio-consumer delay, and host CPU load;
2. vary launch timing while keeping the same logical input epoch;
3. run at least 10,000 logical frames; and
4. require zero canonical mismatches.

### Loop 6: Loopback fixed-delay exchange

Only after timing stress passes:

1. exchange only session identity, frame-numbered four-port inputs, readiness,
   and periodic canonical checksums over localhost;
2. wait for confirmed inputs rather than predicting;
3. inject latency, jitter, reordering, duplication, and loss;
4. fail closed on mismatch or missing inputs; and
5. measure the minimum playable fixed delay.

This loop is transport proof, not a lobby or internet beta.

## Evidence required at handoff

- exact local commit and clean isolated worktree;
- build and privacy audits;
- hash-only traces and comparator summaries;
- first canonical divergence or longest converged interval;
- controls attempted and whether each moved the divergence;
- GO, CONDITIONAL GO, or NO-GO decision with a concrete next action; and
- explicit list of what still requires physical iPhone/iPad testing.

## Expected overnight boundary

Simulator work can decide whether deterministic simulation is credible and can
exercise loopback networking if it is. It cannot validate real Wi-Fi, thermal
behavior, different Apple chips, hardware Metal/audio timing, controller feel,
backgrounding, or worldwide relay quality. Those are later gates, not reasons
to defer the offline decision.
