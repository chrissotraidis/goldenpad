# Next steps

Updated: 2026-08-25

This is the short operational queue for GoldenPad's Preview 7 compatibility
promotion. It does not
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
| 1 | **Build and accept Preview 7** | Production mobile build `7`, iOS 17-only embedded Metal targets, twice-identical packaging, preserved-data readback, and hands-on iPadOS/Mac acceptance. |
| 2 | **Publish and verify Preview 7** | Merge the exact accepted source, publish both artifacts, download them again, and repeat the package/hash audits before closing the release. |
| Parallel user-facing lane | **Affected-device confirmation** | Ask issue #19's reporter to verify production Preview 7 and issue #9's reporter to test the corrected target. Issue #17 is closed; issue #8 controller verification remains open. |

Preview 6 is the accepted release baseline. Preview 7 changes only embedded
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
iPhone passed the side-by-side diagnostic build; final production Preview 7
confirmation remains. A12 evidence can proceed without changing released
behavior.

## Do immediately after

1. **Optional second touch Fire button**
   - Add one optional, independently movable/resizable Fire control.
   - Preserve current defaults and reject overlapping or latched touch input.
   - Accept phone and tablet layouts before including it in a later preview.
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
- Keep Preview 6's shared mapping and accepted Mac relative-input
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
