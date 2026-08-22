# Autonomous goal loop

Updated: 2026-08-22

This is the mandatory operating procedure for a long-running GoldenPad repair
session. It is designed for several hours of unattended Simulator work with
optional, tightly gated physical-iPad validation. It does not authorize merging
implementation changes to `main` without user review.

The current mutable state is recorded in [`GOAL_STATE.md`](GOAL_STATE.md).

## Objective

Improve GoldenPad without destabilizing the published Preview 2 baseline:

1. measure before changing behavior;
2. work on one technical-debt item at a time;
3. use automated and Simulator evidence before physical hardware;
4. compare every candidate against an unchanged control;
5. commit and push only coherent, independently revertible progress; and
6. leave a complete handoff even when the correct result is “hypothesis
   rejected” or “blocked pending hardware.”

The first active item is TD-01, the behavior-neutral fire-rate measurement
probe. TD-02 modern sidestep is the next user-facing repair. TD-03 A12X evidence
is an independent collection lane and receives no speculative code change.

## Governing documents

Read these at the start of every resumed session:

1. [`GOAL_STATE.md`](GOAL_STATE.md): active item, gate, evidence, blocker, and
   exact next command.
2. [`NEXT_STEPS.md`](NEXT_STEPS.md): short work queue.
3. [`TECH_DEBT.md`](TECH_DEBT.md): evidence, priority, ownership, and closure.
4. [`PLAN.md`](PLAN.md#current-execution-plan-2026-08-22): dependency order and
   stop rules.
5. [`TESTING.md`](TESTING.md#technical-debt-discrimination-gates): proof.
6. [`ARCHITECTURE.md`](ARCHITECTURE.md): subsystem ownership boundaries.

Historical worklogs and handoffs are evidence, not authority over the current
documents above.

## Immutable controls

- Public tag: `v0.1.0-preview.2`.
- Main baseline when this loop began:
  `788667eb6b34ad0ca6154c96b2503db5ede73c1f`.
- Physical four-view render-control executable:
  `0976dcdfd17de60beda8e8e60ccff3fc81da7da0b2ef43f159cdea061149677d`.
- Final Preview 2 mobile executable:
  `100ee12be02e2077e7559f6cd4ead210bb933abffb87874cf76a16afa06e67a9`.
- Accepted single-player touch/controller/save/settings behavior recorded in
  `STATUS.md` and `TESTING.md`.

Never rewrite a control artifact, retag a release, uninstall the physical app,
or regenerate only one half of the embedded patch pair.

## Non-negotiable safety rules

1. Work only on a dedicated `codex/` branch. Keep `main` clean and merge-free.
2. One debt ID per implementation commit or review unit wherever practical.
3. No ROM, generated retail data, saves, preferences, signing material, device
   identifiers, or captures enter git, PR text, or public logs.
4. Never use Xbox/XBLA material, leaked source, or matching-target SDK
   implementation sources.
5. Do not update upstream pins while investigating a behavior bug unless the
   dependency revision itself is the isolated variable.
6. Do not combine timing, input semantics, controller ownership, renderer,
   audio, lifecycle, and networking fixes.
7. A successful build, PID, still image, or healthy counter does not establish
   touch, temporal rendering, audio, controller, lifecycle, or gameplay
   acceptance.
8. Simulator evidence never substitutes for physical performance, touch feel,
   real controller lifecycle, speaker audio, thermal, or A12 compatibility.
9. Physical installation is in-place only. Preserve and independently hash the
   runtime input, active save, backup save, and preferences before and after.
10. Stop QuickTime recording immediately after the targeted reproduction. Never
    leave it recording while compiling, researching, or idle.

## Persistent state model

`GOAL_STATE.md` must always contain:

- branch and current commit;
- main and release controls;
- active debt ID and exact phase;
- current hypothesis and falsifier;
- commands already run and their result;
- Simulator/device/capture evidence level;
- active blocker and failure count;
- last known-good candidate;
- changed files and rollback command; and
- one exact next action.

Update the state after every meaningful build/run decision and before any long
command. A future session must be able to continue without reconstructing
intent from terminal scrollback.

## Loop state machine

### L0 — load and reconcile

1. Read the governing documents and `git status`.
2. Fetch remote state without modifying the worktree.
3. Confirm the branch descends from the recorded main baseline.
4. Inventory user-owned changes and preserve them.
5. Confirm the selected debt item is still the earliest unblocked item.

Gate: branch, scope, baseline, and next experiment agree with `GOAL_STATE.md`.

### L1 — state a falsifiable experiment

Record:

- observed problem;
- source-confirmed facts;
- leading hypothesis;
- competing hypothesis;
- smallest discriminating measurement;
- expected positive and negative result; and
- exact surfaces that must remain unchanged.

No behavior-changing patch is allowed without this entry.

### L2 — baseline gate

Run the unchanged relevant verifier/build/probe first. If it fails:

1. retry the identical command once only when restricted macOS services or a
   transient tool failure are plausible;
2. classify environment versus source failure;
3. stop the repair if the baseline remains red; and
4. record a blocker instead of weakening the gate.

For visual work, preserve the fixed Simulator device, OS, resolution, stage,
camera, and settings before producing a candidate.

### L3 — smallest implementation

- Prefer an observation point or counter before a repair.
- Touch the narrowest project-owned or tracked-patch seam.
- Keep diagnostics bounded and disabled outside an explicit probe.
- Add a fail-before/pass-after test when technically possible.
- Do not perform opportunistic refactors.
- Run `git diff --check` and inspect every changed line before building.

### L4 — build and static verification

Use the exact primary-runtime workflow in `BUILDING.md` and `TESTING.md`.
Private paths are provided locally and never recorded in tracked files.

Minimum gate for a runtime candidate:

- no ROM/private-data contamination;
- matched generated `patches.c` and `patches_bin.c` timestamps/content markers;
- host and relevant focused verifier pass;
- ARM64 Simulator build completes;
- candidate identity and changed source hash are recorded; and
- no unrelated dependency or package change appears in the diff.

Long builds run in an interactive command session and are polled at intervals;
do not launch duplicate builds because output is temporarily quiet.

### L5 — Simulator runtime gate

1. Boot one supported Simulator class at a time.
2. Install only the candidate intended for that Simulator.
3. Launch through the real supported runtime-input path.
4. Run the focused probe before free-form gameplay.
5. Read a bounded log after the run, not a continuous console during acceptance.
6. Capture deterministic screenshots with `simctl` at named checkpoints.
7. Inspect screenshots directly and compare stage, menus, geometry, viewport,
   overlay, and control layout against the fixed control.
8. For temporal symptoms, capture bounded video; a still is insufficient.
9. Stop and shut down the Simulator before changing device class.

Simulator acceptance proves only the exercised route. Record what was not
tested.

### L6 — decision

Choose exactly one result:

- `CONFIRMED`: measurement supports the hypothesis; repair may proceed.
- `REJECTED`: evidence falsifies the hypothesis; revert diagnostic-only code if
  it has no lasting test value and select the next discriminator.
- `PARTIAL`: evidence narrows but does not settle the cause; add one smaller
  measurement.
- `BLOCKED`: required input, hardware, artifact, or green baseline is absent.
- `ACCEPTED`: repair passes all applicable automated, Simulator, and physical
  gates.

Never describe `CONFIRMED` or `PARTIAL` as a fixed bug.

### L7 — physical-device escalation

Escalate only when all are true:

- focused automated and Simulator gates are green;
- the change genuinely needs hardware evidence;
- signing/build identity is known;
- the existing app can be updated in place;
- pre-install runtime/save/preference hashes are recorded; and
- the rollback candidate is available.

After installation, read back and compare every protected payload before
launching. A surviving save does not prove the ROM, backup save, and preferences
also survived.

### L8 — QuickTime evidence

Use the `quicktime-ios-device-watch` procedure for every QuickTime action.

1. Confirm the intended device is attached, trusted, unlocked, and visible.
2. Select the device under QuickTime's **Screen** source, not **Speaker**.
3. Verify the mirror visually before recording.
4. Record only the shortest targeted reproduction with useful playback volume.
5. Mark event time and elapsed timer for a transient bug.
6. Preserve a few seconds of post-roll.
7. Stop recording and verify QuickTime shows the resulting movie before
   returning to builds or other work.
8. Keep the autosaved composition local and unshared.

QuickTime can alter audio routing. Retain a separate unrecorded physical-speaker
check for audio acceptance.

### L9 — commit, push, and handoff

Commit only when the unit is coherent:

- one debt item or one reusable measurement gate;
- focused tests and evidence recorded;
- no private files or generated artifacts staged;
- rollback is obvious; and
- docs reflect the actual evidence level.

Push the topic branch after meaningful checkpoints so work is reviewable. Do
not merge to `main`. A handoff must state:

- what changed;
- what was proven, inferred, rejected, or left open;
- commands and evidence;
- Simulator and physical-device coverage;
- known regressions or none observed;
- branch/commit; and
- exact recommended next action.

## Anti-stall rules

- Do not repeat an unchanged failed command more than twice.
- After three failures with the same root symptom across iterations, stop that
  line, create/update a blocker, and pursue an independent unblocked item.
- Every retry must change one variable or collect new evidence.
- If more than one variable changed, the result cannot identify causality;
  split and rerun.
- If a build takes longer than expected but remains active, poll it rather than
  starting another.
- If the machine, Simulator, CoreDevice, signing, or UI automation becomes
  unavailable, preserve state before attempting recovery.
- If a user message arrives, treat it as higher priority and reconcile it with
  the active experiment before continuing.

## TD-01 loop: fire-rate measurement

Goal: measure GoldenPad's current player and guard automatic cadence without
changing combat behavior.

Required facts:

- pinned primary runtime runs one game iteration per VI at native 60 Hz;
- primary patch chain has no fire-rate authenticity repair;
- MGB64 measured an AK-47 reference of approximately 33.3 versus 11.3 shots per
  100 ticks; and
- GoldenPad must record its own number before using that reference as a gate.

Procedure:

1. Trace the actual generated/game-side player and guard fire events.
2. Reuse the existing bounded diagnostic-probe boundary; do not automate player
   transforms, inventory, enemy state, or mission success.
3. Define a fixed stage/setup, weapon, starting ammo, input interval, and tick
   count.
4. Count both ammo delta and the actual fire event; disagreement is a probe
   defect until explained.
5. Run at least three unchanged repetitions.
6. Run the guard measurement separately with fixed line of sight.
7. Record mean, range, exact ticks, and any RNG/setup variance.
8. Stop after baseline measurement. Do not combine the authenticity repair in
   the same commit.

TD-01 measurement gate passes when repeated current-build numbers are stable
enough to distinguish roughly 33 from 11 shots per 100 ticks and the probe is
demonstrably read-only apart from ordinary controller input/ammo consumption.

## TD-02 loop: modern sidestep

Begin only after TD-01 measurement is committed/pushed or formally blocked.

1. Freeze current menu, touch layout, Original N64 C-button, and modern look
   behavior.
2. Add a synthetic gameplay-only mapping test that fails on the current build.
3. Change modern gameplay semantics so MOVE horizontal strafes and LOOK
   horizontal turns.
4. Preserve Original N64 C-button mode as a separate explicit behavior.
5. Prove menus/watch/settings do not inherit gameplay strafing semantics.
6. Pass Simulator interaction and screenshot/layout gates.
7. Escalate to physical touch/controller feel only after all prior gates pass.

## Visual iteration policy

Screenshots are appropriate for:

- menu/layout placement;
- fixed-camera geometry comparisons;
- right-edge seams;
- static viewport/scissor mistakes; and
- settings-state confirmation.

Video is required for:

- flicker, flashing, interpolation, or corruption that recovers;
- screenshot/resume stalls;
- input latency that grows over time;
- controller disconnect/reconnect behavior; and
- audio/video correlation.

Never infer smoothness, absence of flicker, or audio quality from screenshots.

## End-of-session condition

An unattended session ends safely when one of these is true:

- active item is accepted and pushed;
- active item is measured and pushed, with the repair deliberately deferred;
- a blocker prevents safe progress and all independent in-scope work is
  exhausted;
- physical hands-on judgment is required; or
- the user resumes control.

Before ending: stop QuickTime, stop live log streams, shut down temporary
Simulators, preserve device data, update `GOAL_STATE.md`, commit/push coherent
work, and leave `git status` explained.

## Master continuation prompt

Continue the GoldenPad autonomous goal loop in `docs/GOAL_LOOP.md`. Read
`docs/GOAL_STATE.md` first and obey its exact current phase and next action.
Preserve Preview 2 and `main`; work on the dedicated branch; one TD item per
review unit; measurement before repair; Simulator before device; short targeted
QuickTime recording only when physically gated; never expose private data; do
not merge implementation work to `main`. Update state after every meaningful
decision, apply anti-stall rules, push coherent checkpoints, and stop for
hands-on judgment rather than inventing acceptance.
