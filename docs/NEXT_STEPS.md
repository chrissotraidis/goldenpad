# Next steps

Updated: 2026-08-23

This is the short operational queue for GoldenPad after Preview 4. It does not
replace the authoritative documents:

- [`TECH_DEBT.md`](TECH_DEBT.md) owns priority, evidence, and closure state;
- [`PLAN.md`](PLAN.md#current-execution-plan-2026-08-23) owns detailed waves,
  sizing, dependencies, and stop rules; and
- [`TESTING.md`](TESTING.md#technical-debt-discrimination-gates) owns proof.

If this queue conflicts with those documents, update all affected documents in
the same change rather than choosing whichever wording is more convenient.

## Do now

| Order | Work | Output required before moving on |
| ---: | --- | --- |
| 1 | **TD-01 repair design review** | Preserve the completed baseline: three identical Phantom windows at 20 events/58 ticks (34.4828 per 100) plus guard windows 13/17/18. Specify the smallest source-derived player-and-guard repair and deterministic before/after gate before changing timing. |
| Parallel user-facing lane | **Preview 4 reporter confirmation** | Ask issue #8's reporter to verify touch/controller sidestepping and issue #17's reporter to verify Mac Runway tank controls against Preview 4. Require diagnostics and exact settings for any remaining failure. |
| Parallel evidence lane | **TD-03 A12X crash investigation** | Full redacted `.ips`, A12-family reproduction, and diagnostic-only non-direct/Tier-1 Plume binding builds on accepted hardware. No speculative shipping patch. |

Preview 4 is the accepted release baseline. Its source, package, behavior, and
rollback identities are frozen in
[`PREVIEW_4_BASELINE.md`](PREVIEW_4_BASELINE.md). The player measurement is
complete and its observation branch remains separate from gameplay repair.
Follow [`TD01_FIRE_RATE_LOOP.md`](TD01_FIRE_RATE_LOOP.md) and stop before
implementing timing until the exact repair is reviewed. Reporter confirmation
and A12 evidence collection can proceed without changing released controls.

## Do immediately after

1. **TD-01 fire-rate authenticity repair**
   - Use the confirmed 34.4828 player and 13/17/18 guard baselines.
   - Patch player and guard cadence together as one timing decision.
   - Recheck semi-automatic behavior and obtain hands-on combat acceptance.
2. **TD-14 modal/run-loop neutralization**
   - Fail first on held touch/controller input across Settings, Share, watch,
     pause, and scroll tracking.
   - Publish neutral before presentation and forbid replay on dismissal.
3. **TD-07 disconnect neutralization and lifecycle probe**
   - Publish neutral when the active controller disappears.
   - Never move touch ownership implicitly.
   - Preserve normal touch/controller Player 1 behavior.
4. **TD-04, TD-05, and TD-06 discriminators**
   - Lifecycle: run the physical matrix first, then instrument the observed wait
     class; do not assume a drawable-only stall.
   - Audio: correlate an audible physical event with counters; 22,050 Hz rate
     mismatch is ruled out.
   - Flicker: fixed player order is rejected; the uncalibrated zero
     `formatChanged` signal is narrowing, not closure. Capture the first affected
     physical frame before another RT64 experiment.
5. **TD-12/TD-13 hygiene**
   - Give the runtime-managed ROM copy the same backup/protection policy as the
     Documents copy, with hash-preserving migration/readback.
   - Script the private-input game-bearing build so two clean build directories
     can reproduce the same shipped-source digest.

Evidence for these items may be gathered concurrently. Behavioral fixes land
one at a time against a freshly accepted baseline.

## Do later

- Resolve or deliberately document the A12-family support floor from affected
  hardware evidence.
- Keep Preview 4's shared mapping and the accepted Preview 3 Mac relative-input
  baseline; take only the edge-mask repair independently if fixed-scene captures
  justify it.
- Reduce stage/effect reports to deterministic reproductions.
- Implement stable real two- to four-controller ownership.
- Add deterministic frame numbers and state hashes.
- Run the bounded two-iPad LAN input/hash experiment only if the
  [`network go/no-go gate`](MULTIPLAYER_ROADMAP.md#network-gono-go-gate) passes.

Public matchmaking, relays, authoritative servers, and rollback are not current
implementation tasks.

## Stop conditions

Stop the affected work package when:

- the unchanged baseline fails its new gate;
- the discriminator contradicts the proposed root cause;
- a candidate changes an unrelated accepted surface;
- matched generated patch inputs are unavailable or stale;
- physical hardware or the required crash artifact is unavailable; or
- completion would require weakening an acceptance criterion.

Record the blocker and advance an independent item. Do not convert uncertainty
into a speculative fix.

## Required handoff for every completed item

- debt ID and exact ownership seam;
- before/after automated or synthetic evidence;
- relevant physical, temporal, audio, or affected-hardware acceptance;
- preservation/package/private-data results;
- updated `STATUS.md`, `TECH_DEBT.md`, `TESTING.md`, and public issue state; and
- an independent rollback description.
