# Next steps

Updated: 2026-08-22

This is the short operational queue for GoldenPad after Preview 2. It does not
replace the authoritative documents:

- [`TECH_DEBT.md`](TECH_DEBT.md) owns priority, evidence, and closure state;
- [`PLAN.md`](PLAN.md#current-execution-plan-2026-08-22) owns detailed waves,
  sizing, dependencies, and stop rules; and
- [`TESTING.md`](TESTING.md#technical-debt-discrimination-gates) owns proof.

If this queue conflicts with those documents, update all affected documents in
the same change rather than choosing whichever wording is more convenient.

For a long-running unattended implementation session, follow
[`GOAL_LOOP.md`](GOAL_LOOP.md) and resume from
[`GOAL_STATE.md`](GOAL_STATE.md).

## Do now

| Order | Work | Output required before moving on |
| ---: | --- | --- |
| 1 | **TD-02 modern sidestep repair** | Modern MOVE horizontal strafes and LOOK horizontal turns on touch and controller; menus and Original N64 C-button mode remain unchanged. Land on a separate branch/review unit. |
| Blocked timing lane | **Finish TD-01 sustained fire-rate baseline** | The probe and three guard windows pass (13/17/18 events per 100 ticks). Three player tap-response windows also pass ammo/event agreement but are not sustained. Resume only with a repeatable ordinary setup providing at least 34 KF7 rounds; do not inject inventory. |
| Parallel evidence lane | **TD-03 A12X crash investigation** | Full redacted `.ips`, Preview 2 reproduction on A12-family hardware, and comparison with a newer accepted device. No speculative renderer patch. |

Land TD-01 and TD-02 as separate review units. TD-01's probe is implemented and
read-only, but its sustained player baseline is formally blocked and its timing
repair remains prohibited. TD-02 now proceeds on a new branch. A12 evidence
collection can proceed independently.

## Do immediately after

1. **TD-01 fire-rate authenticity repair**
   - Use the probe's before/after numbers.
   - Patch player and guard cadence together as one timing decision.
   - Recheck semi-automatic behavior and obtain hands-on combat acceptance.
2. **TD-07 disconnect neutralization and lifecycle probe**
   - Publish neutral when the active controller disappears.
   - Never move touch ownership implicitly.
   - Preserve normal touch/controller Player 1 behavior.
3. **TD-04, TD-05, and TD-06 discriminators**
   - Lifecycle: bounded drawable/present/fence/timer/audio breadcrumbs.
   - Audio: requested-rate readback plus a ROM-free discontinuity signal.
   - Flicker: matched single-/multiplayer depth-rebuild counters before any
     RT64 repair.

Evidence for these items may be gathered concurrently. Behavioral fixes land
one at a time against a freshly accepted baseline.

## Do later

- Resolve or deliberately document the A12-family support floor from affected
  hardware evidence.
- Take Mac mouse and edge-mask repairs independently.
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
