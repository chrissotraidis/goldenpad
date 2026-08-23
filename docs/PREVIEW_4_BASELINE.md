# Preview 4 frozen control baseline

Status: **published control; frozen for TD-01 measurement and repair**

Updated: 2026-08-23

This document identifies the exact control that every post-Preview 4 repair
must preserve. It is an identity and rollback record, not a claim that every
open issue is fixed or that build evidence replaces hands-on gameplay.

## Published identity

| Item | Frozen value |
| --- | --- |
| Source merge | `54474a40e93b77259d10c7594919e6a05f5e276d` |
| Source tree | `4232141f9d14d2f6197e43173694f649828e730f` |
| Pull request | [#18](https://github.com/chrissotraidis/goldenpad/pull/18) |
| Tag | `v0.1.0-preview.4` |
| Release | [Preview 4](https://github.com/chrissotraidis/goldenpad/releases/tag/v0.1.0-preview.4) |
| Unsigned IPA | `GoldenPad-0.1.0-preview.4-unsigned.ipa` |
| IPA SHA-256 | `ff163b0af6b54596590da8e39cbaff0b388b69f1607ca34f62ce61e7fe144130` |
| Mac Alpha archive | `GoldenPad-0.1.0-preview.4-macos-arm64-alpha.zip` |
| Mac archive SHA-256 | `63bec02ad6e323a213f9cb9d15f763a58d6eb7bd4a1a40af6341a4fb8fb333ba` |
| Tracked GoldenEye patch SHA-256 | `0d64256620a5dcb43e7ccf86f9fedd7282242f823ea7d9984c0447c85f3a1cea` |
| Generated `patches.c` SHA-256 | `4a829165889a4e736199841c4c4237ee6a03ed97fa1ce6d891dfc864634862ff` |
| Generated `patches_bin.c` SHA-256 | `cb3e439a8eb1587ac11b7fa29551b3f204860f993b9114ebd5331c179bc92bc6` |

The tag and remote `main` both resolved to the source merge above when this
baseline was frozen. GitHub reported the same SHA-256 digests for both hosted
binary assets. The release is a published prerelease, not a draft.

The audited IPA has sorted unsigned app-content SHA-256
`1ec161604af996f30bb3ac1e9c347f7c905623675ca32adf8d2c35a069c6a13c`.
The audited Mac archive has sorted app-content SHA-256
`d2d0824047061b81ad3ef1b2fd2fd61fde09fc759176b782209c41279217a341`.
Neither package contains a ROM, save, provisioning profile, signing identity,
or private build path.

## Accepted behavior boundary

The physically accepted signed iPad test executable is
`2b31f8868885712fbad34cef1aea20b1dee48f59fc9d930cbd3fa8b8e82b6b12`.
It established:

- controller connection, raw menu navigation, and mission startup;
- ordinary on-foot movement and both-axis right-stick look;
- stationary left-trigger Aim using the left stick for GoldenEye's native
  weapon/reticle path and neutral right stick;
- Runway tank entry, drive, hull steering, turret control, weapon cycling,
  ordinary-weapon and Tank Shell firing, exit, and re-entry; and
- return to title plus a later Facility on-foot regression pass.

Preview 4's final unsigned executable is version `0.1.0` build `4` at SHA-256
`d83361f4daa70014b378aed20b9e26dc7c787d77b0fcd000816d536aecc8e66b`.
It changes only the requested external-controller normal-look and mounted-
turret rate from 1.56 to 1.872 degrees per frame on top of the accepted test
binary. The shared input matrix, full device build, symbol audit, and package
audit passed. That exact final unsigned executable did not receive a second
physical-device pass before publication; preserve that distinction.

The detailed mapping and rollback contract remains
[`PREVIEW_4_INPUT_FIX.md`](PREVIEW_4_INPUT_FIX.md). Issue
[#17](https://github.com/chrissotraidis/goldenpad/issues/17) remains open for
reporter Mac verification. Issue
[#8](https://github.com/chrissotraidis/goldenpad/issues/8) also remains open for
reporter confirmation against the superseding Preview 4 mapping. Open reporter
verification does not authorize another input rewrite.

## TD-01 diagnostic boundary

Preview 4 contains the TD-01 read-only observation hooks. The completed
measurement branch changes only the host observation window so a continuous
magazine of at least 15 shots can finish before 100 ticks and a reload rejects
the window; it does not change game timing or input.

- Normal launch initializes `fireRateProbeEnabled` to false.
- Only the explicit `--fire-rate-probe` launch argument in the mobile host
  enables it. Mac contains the runtime symbol but does not provide the current
  gameplay-measurement activation route.
- The probe observes at most three player windows and three 100-tick guard
  windows. A player window completes at 100 ticks or when at least 15 continuous
  shots empty the magazine; magazine results are normalized per 100 ticks.
- It records player weapon, magazine ammo, fire counter, and ordinary ammo
  consumption. The guard wrapper calls GoldenEye's original firing routine and
  then records the resulting counter transition.
- It does not alter timing, inventory, saves, mission state, transforms,
  player state, guard state, input mapping, or renderer state.
- Evidence contains three guard windows at 13, 17, and 18 committed events per
  100 ticks and three identical physical-iPad player windows at 20 events over
  58 ticks, normalized to 34.4828 per 100 ticks.

The probe's presence and default-off wiring can be checked without launching
the game. Its measurements cannot.

## Isolated TD-01 repair delta

Branch `codex/td01-fire-rate-repair` leaves this published baseline immutable.
Its only gameplay change replaces the shared automatic-rate getter: positive
values are multiplied by the N64 frame cost of three, while zero and negative
values are returned unchanged. Player and guard modulo paths therefore change
together. Input mapping, controller sensitivity, native Aim, tank behavior,
menus, damage, ammo, first-shot behavior, renderer, and host timing are outside
the repair.

The candidate is not part of Preview 4 and is not accepted until the physical
stop gate in [`TD01_FIRE_RATE_LOOP.md`](TD01_FIRE_RATE_LOOP.md) passes. Reverting
the single repair commit restores the identities and behavior recorded above.

## Change and rollback rules

1. Start each TD-01 review unit from the frozen source merge above.
2. Before gameplay measurement, runtime source must remain byte-identical to
   Preview 4. Documentation and verification scripts are the only allowed
   changes.
3. Do not combine TD-01 with input sensitivity, Aim, tank behavior, controller
   ownership, lifecycle, audio, renderer, storage, A12X, or networking work.
4. The measurement unit changes no gameplay behavior. The later authenticity
   repair is a separate commit and review unit.
5. If the repair changes the tracked GoldenEye patch, regenerate and validate
   `patches.c` and `patches_bin.c` together.
6. Every candidate must pass the complete Preview 4 input matrix and package
   boundaries before physical escalation.
7. Reverting the single TD-01 repair commit must restore this baseline without
   removing Preview 4 controls.

Run the terminal-only freeze checks from the repository root:

```sh
scripts/verify-preview4-baseline.sh
scripts/verify-fire-rate-probe-contract.sh
scripts/verify-recomp-input-matrix.sh
git diff --check
```

For the isolated candidate, replace the first command with
`scripts/verify-preview4-baseline.sh --allow-td01-repair` and add
`scripts/verify-fire-rate-authenticity-repair.sh`.

The first two checks require no Simulator, device, ROM, app launch, or GUI. The
input matrix is also command-line-only but needs the pinned reference checkout;
an isolated worktree may supply it through
`GOLDENPAD_RECOMP_REFERENCE_ROOT=/path/to/goldeneye64recomp`.
