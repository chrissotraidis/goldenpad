# TD-01 fire-rate measurement loop

Status: **Released in Preview 5**

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

The selected repair replaces the shared
`bondwalkItemGetAutomaticFiringRate` getter. Positive automatic rates are
multiplied by the N64 frame cost of three; zero and negative classifications
are returned unchanged. The same getter feeds player and guard automatic-fire
modulo tests, so this changes both together without duplicating policy. It does
not change the first-shot path, semi-automatic classification, weapon damage,
ammo, input, Aim, tank, menu, renderer, or host timing.

## Current checkpoint

| Field | Value |
| --- | --- |
| Branch | `codex/td01-fire-rate-repair` |
| Starting source | `54474a40e93b77259d10c7594919e6a05f5e276d` |
| Active debt | TD-01 |
| Current phase | T5 accepted and released in Preview 5 |
| Runtime behavior change | Positive automatic-fire interval only: shared player/guard value multiplied by 3 |
| Simulator/device/GUI use | No Simulator or desktop GUI; separately authorized physical iPad only |
| Next mandatory stop | Retain as frozen rollback control; any new timing report starts a separate evidence unit |
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

## T5 candidate evidence

- The complete decompiled-call-site audit found the shared getter used as the
  positive modulo divisor by both player and guard automatic firing. Other
  callers only classify nonpositive values.
- `scripts/verify-fire-rate-authenticity-repair.sh` proves the measurement
  control lacks the repair, verifies the tracked source and generated MIPS
  instructions, checks representative positive rates `2/3/4/5/11` become
  `6/9/12/15/33`, and proves `0` and `-1` remain unchanged.
- `scripts/verify-preview4-baseline.sh --allow-td01-repair`, the probe contract,
  and the complete shared input/tank matrix pass.
- Regenerated private patch hashes are `11696e2a55d16ddb334cdcaf7b760b27c8b99e82afc577be85419ce14c69bde5`
  for `patches.bin`, `5e559e3a218c06cc54ead26f73a05f19f6095a542adbaeff664c19187f025217`
  for `patches.c`, and `86113c9d63c92c5a1a7d394de32dd478042e50a9dece10085e93aba3f57ad52d`
  for `patches_bin.c`.
- Signed device candidate executable SHA-256 is
  `146f3f37d568620ce55910ec2a09bc912336ba56b8afc9183862636e5d81015d`.
  Its observation probe is temporarily default-on in that artifact only; the
  tracked source remains default-off.
- That candidate was installed in place only over side-by-side bundle
  `com.chrissotraidis.goldenpad.preview4test`, displayed as `GoldenPad P4 Test`.
  Fresh pre/post readbacks proved both ROM copies, active save, backup save, and
  preferences byte-identical. The ordinary GoldenPad app was not targeted, and
  the candidate was not remotely launched.
- The native arm64 Mac Release build passed with executable SHA-256
  `0c883f0dfff5f11254f81297f050084b9b6ba1641a9c13f594eacf1a90aca38b`.

The candidate is not accepted, merged, released, or grounds to close TD-01
until the physical stop gate passes. Revert the single repair commit to recover
the frozen Preview 4 behavior.

## T5 physical result

The user normally launched the installed P4 Test candidate, navigated to
Frigate/Agent, and accepted menu navigation, movement, general gameplay, and
overall runtime quality with no observed regression. The retrieved bounded log
then supplied the primary cadence discriminator:

| Build | Weapon | Window | Events | Ammo | Result |
| --- | ---: | ---: | ---: | --- | --- |
| Preview 4 control | 11 | 58 ticks | 20 | 20 to 0 | Unscaled fast baseline |
| TD-01 candidate | 11 | 100 ticks | 12 | 20 to 8 | Exact expected scaled interval including the immediate first shot |

The candidate log SHA-256 is
`9cce343d3be6ef7fa187cde59657365a990e4df28dfa91bbeedd1c221a58bfd6`;
the preserved prior-session comparator is
`65fda523ac0773e333eccd05222bbba325b3c6e5f55f0e0a3455db8743fe85f0`.
The runtime advanced to 13,723 display lists, VI updates, and presentations,
with zero audio drops and zero underrun frames/callbacks. No fatal, assertion,
exception, or current-session crash marker appeared. The log did not contain a
complete guard fixed window or an explicit PP7 sequence; guard behavior remains
covered by the same getter, and nonpositive semi-automatic values remain
byte-for-byte unchanged plus deterministically verified. This limitation is
recorded rather than represented as physical evidence.

The physical stop gate passed and the isolated repair ships in Preview 5. Its
release artifacts, package hashes, and public limitations are recorded in
[`RELEASE_NOTES_0.1.0-preview.5.md`](RELEASE_NOTES_0.1.0-preview.5.md).
