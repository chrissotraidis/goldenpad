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
| Human acceptance lane | **TD-02 modern sidestep candidate** | Code and Simulator gates pass. Require hands-on iPhone/iPad touch feel plus Modern/Original/Off physical-controller acceptance before merge, issue closure, or release promotion. |
| 1 | **TD-07 physical lifecycle acceptance** | Code and Simulator gates now pass on an isolated candidate. Test held-input disconnect, reconnect/reorder, background/foreground, and confirm touch never leaks to Player 1. Do not confuse this with real P3/P4 routing. |
| 2 | **TD-04 physical lifecycle classification** | The opt-in bounded discriminator and an intermittent Simulator freeze reproduction are complete. Run the physical matrix; route all-flat counters to runtime resume and presentation-only stalls to matched RT64/Plume timing instrumentation. No repair is selected yet. |
| 3 | **TD-05 physical audio classification** | Synthetic rate/ring checks pass; Simulator underruns remain without detected jumps. Listen on speaker/Bluetooth through route/interruption/lifecycle before selecting cadence, reserve, or reset ownership work. |
| 4 | **TD-06 render-order/lighting discriminator** | Matched depth rebuilds are zero in both single-player and real four-player Temple, so aliased-depth churn is rejected. Instrument shared lighting ownership by player pass next, then require continuous physical four-view video before any repair. |
| Blocked timing lane | **Finish TD-01 sustained fire-rate baseline** | The probe and three guard windows pass (13/17/18 events per 100 ticks). Three player tap-response windows also pass ammo/event agreement but are not sustained. Resume only with a repeatable ordinary setup providing at least 34 KF7 rounds; do not inject inventory. |
| Parallel evidence lane | **TD-03 A12X crash investigation** | Full redacted `.ips`, Preview 2 reproduction on A12-family hardware, and comparison with a newer accepted device. No speculative renderer patch. |

TD-01, TD-02, and TD-07 are separate review units. TD-01's probe is implemented and
read-only, but its sustained player baseline is formally blocked and its timing
repair remains prohibited. TD-02's isolated candidate now passes the red/green
mapping probe, live C-left/C-right publication, menu/watch/settings, build,
layout, clean-session, and preservation gates. It remains open only for physical
acceptance. TD-07's synthetic lifecycle and Simulator integration gates pass,
including neutral paired-controller loss, stable controller retention,
controller-P1/touch-P2, and normal-launch isolation. Physical lifecycle timing
and real P2-P4 controller slots remain open. A12 evidence collection can proceed
independently.

## Do immediately after

1. **TD-04, TD-05, and TD-06 discriminators**
   - Lifecycle: the host-level classifier is implemented; run the physical
     matrix before deciding whether archive-level drawable/fence timing is needed.
   - Audio: the synthetic signal rejects rate mismatch/ring corruption in
     Simulator; physical listening and lifecycle/route evidence remain.
   - Flicker: the matched depth counter rejects aliased-depth churn. Take only
     the fixed render-order/shared-lighting discriminator next; keep the
     accepted depth-address repair frozen.
2. **TD-01 authenticity repair only after its blocker clears**
   - Obtain the sustained 34-round baseline without state injection.
   - Use the probe's before/after numbers.
   - Patch player and guard cadence together, recheck semi-automatic behavior,
     and obtain hands-on combat acceptance.

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
