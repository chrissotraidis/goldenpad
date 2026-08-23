# TD-01 fire-rate measurement loop

Status: **terminal-only preflight complete; stopped at the real-gameplay gate**

Updated: 2026-08-23

This is the bounded operating loop for automatic-fire authenticity. It applies
only to TD-01 and inherits the project-wide closure rules in
[`TECH_DEBT.md`](TECH_DEBT.md#closure-and-change-control-rules). The immutable
control is [`PREVIEW_4_BASELINE.md`](PREVIEW_4_BASELINE.md).

## Objective

Measure Preview 4's sustained player and guard automatic-fire cadence before
changing timing, then implement one independently revertible player-and-guard
repair only if the measurement supports it.

This loop does not authorize merging, releasing, launching a Simulator, using a
physical device, or controlling the desktop GUI without a later explicit gate.

## State machine

### T0 - freeze and reconcile

- Verify remote `main`, tag, release target, hosted asset names, and digests.
- Work from an isolated branch at the exact Preview 4 source merge.
- Leave unrelated dirty worktrees untouched.
- Reconcile `STATUS.md`, `TECH_DEBT.md`, `PLAN.md`, `NEXT_STEPS.md`, and
  `TESTING.md` before changing runtime code.

Gate: `scripts/verify-preview4-baseline.sh` passes and the runtime diff from
Preview 4 is empty.

### T1 - prove diagnostic containment

- Confirm the existing probe is default-off and launch-argument-only.
- Confirm both game-side sampling hooks and the ROM-free host stub remain
  linked.
- Confirm the observation bodies do not write RDRAM or return modified game
  state.
- Do not refactor the probe merely to make it easier to test.

Gate: `scripts/verify-fire-rate-probe-contract.sh` passes. This proves wiring
and containment only, not measurement accuracy or gameplay behavior.

### T2 - run terminal-only regression gates

- Run the Preview 4 shared input matrix against the pinned reference checkout.
  A clean worktree may provide that checkout through
  `GOLDENPAD_RECOMP_REFERENCE_ROOT` rather than copying or modifying it.
- Run host and package-symbol checks that do not launch an app.
- Build the native Mac target from the command line if its pinned dependencies
  are available.
- Run whitespace, contamination, and documentation-link checks.

Gate: every available terminal-only check is green, with unavailable private-
input checks recorded rather than weakened.

### T3 - stop for real-gameplay measurement

Do not continue autonomously when the next evidence requires GoldenEye input.
The missing evidence is:

1. launch the exact unchanged Preview 4 mobile runtime with
   `--fire-rate-probe`;
2. use one repeatable ordinary-input setup with one automatic weapon and at
   least 34 starting rounds;
3. hold ordinary Fire long enough to complete exactly 100 sampled ticks;
4. obtain three complete player windows without inventory, save, transform,
   mission, or enemy-state injection;
5. record three separate fixed-line-of-sight guard windows; and
6. preserve the bounded diagnostics log for comparison.

A run is invalid if the weapon changes, the 100-tick completion line is absent,
starting ammunition is below the discrimination requirement, input is
synthesized below the ordinary host boundary, or another probe/behavior change
is enabled.

### T4 - measurement decision

After valid logs exist, record for every run:

- source commit and executable identity;
- platform, stage, difficulty, weapon, control style, and input device;
- ticks, starting/ending ammo, committed events, and counter range;
- mean, range, and any explained setup variance; and
- agreement or disagreement between event count and ammo delta.

Choose one result:

- **CONFIRMED:** stable player magnitude distinguishes the current cadence from
  the N64-equivalent reference and authorizes repair design.
- **PARTIAL:** the probe is reached but setup variance or incomplete windows
  require one narrower measurement.
- **REJECTED:** evidence contradicts the assumed magnitude; revisit the model
  before changing timing.
- **BLOCKED:** ordinary gameplay cannot produce the required window without
  prohibited state injection.

Measurement never closes TD-01 by itself.

### T5 - later repair unit

Only after T4 is CONFIRMED:

- patch the source-derived player and guard timing seams together;
- add deterministic before/after cadence checks that fail on Preview 4 and pass
  on the candidate;
- retain semi-automatic, menu, Aim, tank, and input behavior;
- regenerate both embedded patch halves together when applicable; and
- stop again for hands-on combat acceptance before merge or release.

## Current checkpoint

| Field | Value |
| --- | --- |
| Branch | `codex/preview4-td01-baseline` |
| Starting source | `54474a40e93b77259d10c7594919e6a05f5e276d` |
| Active debt | TD-01 |
| Current phase | T3 real-gameplay measurement stop |
| Runtime behavior change | None |
| Simulator/device/GUI use | Prohibited in this pass |
| First mandatory stop | T3 real-gameplay measurement |
| Later rollback | Revert the single TD-01 repair commit; Preview 4 remains intact |

Update this checkpoint and the authoritative status documents after every phase
transition. Never convert a missing gameplay result into an inferred pass.

## Terminal-only preflight evidence

- Remote `main` and `v0.1.0-preview.4` both resolved to
  `54474a40e93b77259d10c7594919e6a05f5e276d`; the published release targets
  that commit.
- The local published IPA and Mac archive re-hashed to the manifest values and
  passed their 18-member and 20-member package audits.
- `scripts/verify-preview4-baseline.sh` passed with no runtime diff from the
  frozen source.
- `scripts/verify-fire-rate-probe-contract.sh` passed the default-off, bounded-
  window, hook/stub, and no-RDRAM-write checks.
- `scripts/verify-recomp-input-matrix.sh` passed the 1.1 through 1.4, raw-menu,
  native Aim, tank, tracked-patch, and generated-marker matrix using the pinned
  Preview 4 reference checkout.
- A command-line arm64 Mac Release rebuild of `GoldenPadMac` succeeded from the
  frozen Preview 4 source and private generated inputs.
- No Simulator was booted or built for, no app was launched, no iPad was read or
  modified, and no desktop GUI automation was used.

The next honest evidence is a complete sustained-player gameplay window. This
loop stops here until real-gameplay use is authorized and available.
