# TD-01 fire-rate measurement loop

Status: **Preview 4 player baseline confirmed; stopped before timing repair**

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
The physical-iPad measurement recorded below was separately authorized.

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

### T3 - real-gameplay measurement

Do not continue autonomously when the next evidence requires GoldenEye input.
When physical use is authorized:

1. launch the Preview 4 mobile runtime with only the observation probe enabled;
2. use one repeatable ordinary-input setup with one automatic weapon;
3. hold ordinary Fire through either a complete 100-tick window or a continuous
   magazine-to-empty window containing at least 15 shot events;
4. obtain three complete player windows without inventory, save, transform,
   mission, or enemy-state injection;
5. record three separate fixed-line-of-sight guard windows; and
6. preserve the bounded diagnostics log for comparison.

A run is invalid if the weapon changes, neither valid completion reason is
present, a reload occurs inside the window, fewer than 15 shots are observed in
a magazine window, input is synthesized below the ordinary host boundary, or
another behavior change is enabled. Normalize magazine results to events per
100 ticks before comparing them with the fixed-window reference.

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

Preview 4's player result is **CONFIRMED**: all three clean Phantom windows were
20 events over 58 ticks, or 34.4828 events per 100 ticks. Mean and range are
34.4828 and 0.0000. Event count matched the 20-to-0 ammo delta in every run.
This is close to the pinned unscaled MGB64 observation of approximately 33.3
and about 3.05 times its N64-equivalent reference of approximately 11.3. The
measurement supports repair design but does not close TD-01 by itself.

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
| Branch | `codex/td01-magazine-measurement` |
| Starting source | `54474a40e93b77259d10c7594919e6a05f5e276d` |
| Active debt | TD-01 |
| Current phase | T4 CONFIRMED; stopped before T5 repair |
| Runtime behavior change | Observation-only magazine completion and reload rejection; no game-state writes |
| Simulator/device/GUI use | No Simulator or desktop GUI; separately authorized physical iPad only |
| Next mandatory stop | Align the smallest source-derived player-and-guard repair before implementation |
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

## Physical-iPad player evidence

The user launched Frigate on Agent and held ordinary controller Fire through
the Phantom's full 20-round starting magazine. No inventory, save, transform,
mission, enemy-state, or below-host input injection was used.

| Run | Completion | Ticks | Events | Ammo | Normalized events/100 ticks | Private log SHA-256 |
| ---: | --- | ---: | ---: | --- | ---: | --- |
| 1 | magazine empty | 58 | 20 | 20 to 0 | 34.4828 | `6c4478104ee899cf23a142142caa8f1b82a14cc1658498478571356fdf2d8fee` |
| 2 | magazine empty | 58 | 20 | 20 to 0 | 34.4828 | `4691fcaa65d07d4118a39dd78f067225a4099c79999bbb6f8ea9c7e23ee7b9f5` |
| 3 | magazine empty | 58 | 20 | 20 to 0 | 34.4828 | `42c0fc59cce414d99e5249ef65160ec3fde581b2e0321bc6cbe7a7cad2e35517` |

The first attempted session was rejected because intermittent firing and a
reload crossed the old fixed-window assumption. The corrected probe accepts a
continuous magazine of at least 15 shots, labels fixed versus magazine
completion, and rejects reload-contaminated windows. A temporary signed test
artifact defaulted this same read-only probe on so the user could launch the app
normally; the temporary source line was reverted immediately after building.
The temporary default-on executable was
`be4f889fef891c38f72e81404796025ca705afc98ee9009e2284d361dc2b6c59`.
After measurement, the test app was restored to a normally named, signed,
probe-off-by-default executable at
`36e0b46e416f944bc466cde86cbb4fb4b5fa351c63715c5c4ee7fae22a9f3c0a`.
Both ROM copies, active and backup saves, and preferences remained byte-for-byte
unchanged across every in-place test-app installation. Raw logs and game data
remain private local evidence and are not committed.

Remote `devicectl` activation caused severe controller/menu latency on this
iPad. That path is rejected for future hands-on controller measurements; use a
normally launched diagnostic artifact instead.
