# Next steps

Updated: 2026-08-28

This is the short operational queue after GoldenPad Preview 8. It does not
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
| Complete | **Preview 7 compatibility promotion** | Merged, published, downloaded, and re-audited with byte-identical hosted assets. |
| Complete | **Preview 8 optional second Fire button** | Default-off duplicate Fire input, independent layout persistence, multi-touch aggregation, deterministic IPA, and physical iPad acceptance passed. |
| 1 | **Affected-device confirmation** | Await the posted issue #19 production Preview 7 result and issue #9 corrected-target result. Issue #17 is closed; issue #8 modern controls are maintainer-accepted and its reporter should test Preview 8's added Fire button. |
| 2 | **Input lifecycle containment** | Take TD-14 modal neutralization and TD-07 controller disconnect behavior as separate repairs. |

Preview 8 is the accepted mobile baseline. It adds only a default-off duplicate
Fire control with independent position, size, and opacity; simultaneous touches
aggregate without cancelling Fire early. Preview 7 changed only embedded
Metal deployment targeting and production identity. Its Mac payload is
byte-identical to Preview 6; horizontal mouse sluggishness remains known Mac
debt, not a Preview 7 regression. Preview 7 retains Preview 5's frozen
mobile controls/tank and TD-01 automatic-rate repairs, restores the Mac menu
and relative mouse path, and replaces the iPad utility menu with independent
rows. The underlying automatic-rate repair remains
documented in [`TD01_FIRE_RATE_LOOP.md`](TD01_FIRE_RATE_LOOP.md). Positive
player/guard intervals scale by three; nonpositive semi-auto classifications
remain unchanged. Source, generated-patch, input/tank, build, package,
preservation, and physical player-cadence gates pass. The affected issue #19
iPhone passed the side-by-side diagnostic build; reporter confirmation of the
production Preview 7 artifact remains. A12 evidence can proceed without
changing released behavior.

## Do immediately after

1. **TD-14 modal/run-loop neutralization**
   - Fail first on held touch/controller input across Settings, Share, watch,
     pause, and scroll tracking.
   - Publish neutral before presentation and forbid replay on dismissal.
2. **TD-07 disconnect neutralization and lifecycle probe**
   - Publish neutral when the active controller disappears.
   - Never move touch ownership implicitly.
   - Preserve normal touch/controller Player 1 behavior.
3. **TD-04, TD-05, and TD-06 discriminators**
   - Lifecycle: run the physical matrix first, then instrument the observed wait
     class; do not assume a drawable-only stall.
   - Audio: correlate an audible physical event with counters; 22,050 Hz rate
     mismatch is ruled out.
   - Flicker: fixed player order is rejected; the uncalibrated zero
     `formatChanged` signal is narrowing, not closure. Capture the first affected
     physical frame before another RT64 experiment.
4. **TD-12/TD-13 hygiene**
   - Give the runtime-managed ROM copy the same backup/protection policy as the
     Documents copy, with hash-preserving migration/readback.
   - Script the private-input game-bearing build so two clean build directories
     can reproduce the same shipped-source digest.

Evidence for these items may be gathered concurrently. Behavioral fixes land
one at a time against a freshly accepted baseline.

## Do later

- Resolve or deliberately document the A12-family support floor from affected
  hardware evidence.
- Keep Preview 6's shared mapping and accepted Mac relative-input
  baseline; take only the edge-mask repair independently if fixed-scene captures
  justify it.
- Reduce stage/effect reports to deterministic reproductions.
- Implement stable real two- to four-controller ownership.
- Resume network research only from the v3 physical checkpoint. Frame numbers,
  hashes, LAN discovery, exact N+4 input exchange, and fail-closed desync
  detection exist in the diagnostic path, but the iPad/iPhone replay produced
  a globals-only mismatch at frame 30.
- Build the protocol v4 word-level diagnostic before another physical replay:
  log all 19 canonical globals at frame 1/frame 30, preserve the one-VI barrier
  difference, and repair only the source-proven divergent field. See
  [`NETPLAY_PHYSICAL_CHECKPOINT_2026-08-28.md`](NETPLAY_PHYSICAL_CHECKPOINT_2026-08-28.md).

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
