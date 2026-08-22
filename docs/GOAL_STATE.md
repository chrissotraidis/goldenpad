# Autonomous goal state

Updated: 2026-08-22 14:24 CEST

## Session identity

| Field | Value |
| --- | --- |
| Goal | Evidence-gated GoldenPad improvement loop |
| Goal thread | `01a028b2-77e4-7441-b0cd-d02a1a9950a5` |
| Branch | `codex/autonomous-repair-loop` |
| Starting main | `788667eb6b34ad0ca6154c96b2503db5ede73c1f` |
| Release control | `v0.1.0-preview.2` |
| Active debt | TD-01 fire-rate measurement probe |
| Phase | L7: record partial result; fixed player window remains open |
| Merge policy | Push topic branch; no merge to `main` without user review |

## Current determination

The external review's mechanism is confirmed in GoldenPad's primary runtime for
guards: a real Dam KF7 guard advances `firecount` once per firing call and the
unchanged game gate commits on every third count. Three 100-tick observation
windows produced 13, 17, and 18 committed events. The observed spread remains
setup/AI variance to control in a future fixed-line-of-sight rerun; the current
evidence does not assign it to a single cause.

The player seam is also reached: GoldenEye's own attract input began a KF7
window at 30 rounds and counter 8. That recorded segment ended or changed
weapon before 100 ticks, so it is not a completed baseline. TD-01 therefore
remains open. Do not apply the authenticity repair or begin TD-02 on this branch
until three fixed 100-tick player runs exist or the user explicitly changes the
gate.

## Gate ledger

| Gate | Status | Evidence |
| --- | --- | --- |
| Main/release control recorded | PASS | `main` and `origin/main` began at `788667e`; Preview 2 tag was not moved |
| Dedicated branch | PASS | `codex/autonomous-repair-loop` |
| Goal-loop procedure | PASS | `docs/GOAL_LOOP.md` and this mutable ledger are linked from the repository docs |
| Unchanged static/documentation gate | PASS | Whitespace, links/anchors, table shape, and contamination checks passed before implementation |
| Unchanged focused build | PASS | Primary Simulator target rebuilt before the probe; executable SHA-256 `482fbb02712d65b6199e1623ca1f03bf14f0cf2ad7e622727221abba4275a748` |
| Source seam traced | PASS | Direct AOT-to-AOT calls bypass runtime dispatch; the accepted seam samples the patched game caller and the once-per-player-tick main loop |
| Tracked patch reproducibility | PASS | The tracked patch applies to a clean upstream archive and reproduces the four patched source files byte-for-byte |
| MIPS patch compile | PASS | Homebrew LLVM 22 compiled and linked `patches.elf`; N64Recomp regenerated the matched `patches.c` and patch binary pair |
| TD-01 measurement implementation | PASS | Opt-in `--fire-rate-probe`; three-run caps; no timing, inventory, mission, transform, player, or guard writes |
| ARM64 Simulator build | PASS | Debug ARM64 Simulator candidate built successfully; executable SHA-256 `6afa14ef47531acb19b663d0f9a8ff036493726ed8b72241c1540cc9cbb7f1d6` |
| In-place preservation | PASS | Both ROM copies, the active save, and the backup save matched their preinstall SHA-256 values after every candidate install |
| Simulator runtime/log evidence | PARTIAL PASS | Three guard windows complete; player callback reached but its attract segment did not complete 100 ticks |
| Visual comparison | PASS FOR PROBE SCOPE | Nintendo/title, mission UI, Dam intro, live gameplay, KF7 guards, and attract gameplay rendered without a new static-layout regression |
| Normal launch | PASS | Relaunch without `--fire-rate-probe` produced no probe marker or samples; normal runtime, graphics, input, and audio startup remained live |
| Physical iPad escalation | NOT RUN | Simulator proves the measurement seam; no gameplay repair exists to justify touching the attached iPad |
| QuickTime | OFF | It was never started; no recording can remain open |
| Commit/push | PENDING | Commit after final static/build verification and documentation reconciliation |

## Blocker ledger

| Item | Status | Evidence | Next discriminating action |
| --- | --- | --- | --- |
| Fixed player KF7 100-tick run | OPEN | Two ordinary Dam acquisition attempts killed KF7 guards but did not reliably collect the drops before later combat ended the run; attract input reached weapon 8 but changed state before tick 100 | Use a repeatable ordinary-input loadout route or a longer recorded automatic segment; do not inject inventory or mutate saves |

This is a gate blocker, not a tooling blocker. The probe, build, Simulator, and
guard route work. Anti-stall policy rejects repeating the same unreliable pickup
route or weakening the 100-tick requirement.

## Evidence ledger

- Preview 2 remains the control. No implementation change was made on `main`.
- The first attempted observation seam wrapped runtime loaded-function entries.
  Build and launch passed, but real combat produced no events. Generated AOT
  shows patched functions call one another directly, bypassing that map. The
  dispatch-wrapper design is rejected.
- The accepted player seam runs once after `lvlViewMoveTick`, reports only the
  current weapon, magazine, fire counter, and player number, and opens a window
  only on an observed automatic-weapon ammo decrement.
- The accepted guard seam replaces the 0x74-byte original
  `chrlvTriggerFireWeapon` caller, preserves both hidden-bit branches and the
  original `chrlvFireWeaponRelated` call, then reports before/after counters.
- The guard weapon item must come from `chrGetEquippedWeaponProp`, matching the
  original routine's ownership path. Reading the guard action record returned
  item 0; the corrected path returned item 8 (AK-47/KF7).
- Guard baseline: 13, 17, and 18 committed events per 100 simulation ticks;
  mean 16.0, range 13–18. Counters were 3→39, 42→90, and 93→144.
- Player partial: attract input began `weapon=8`, `ammo=30`, `counter=8`; no
  complete player window was recorded.
- Preserved private evidence outside the repository:
  `/private/tmp/goldenpad-td01-guard-measurement.log` (SHA-256
  `119172ff381e436477a211b9b99a01c3f4c065ee7b07b4b31a1c0e91b3a39d93`),
  `/private/tmp/goldenpad-td01-attract-measurement.log` (SHA-256
  `c4b194bc92396c0a06cc1568e60bb9af3d78cc2a060942bf59556e3044e1c482`),
  and `/private/tmp/goldenpad-td01-kf7-guards.jpeg` (SHA-256
  `e0fd322baebe6136769a328adc2941001781c4066fa93b3713c0f9dd4fda13a7`).
- The first sandboxed Xcode retry failure was environmental: CoreSimulator and
  the module cache were unavailable. The identical permitted host-access retry
  passed, so it is not classified as a source failure.
- The final normal-launch check was backgrounded through Simulator Home; the
  active-session marker was removed, so no recording or forced-active session
  was left behind.

## Changed files

- `docs/GOAL_LOOP.md`, `docs/GOAL_STATE.md`: autonomous procedure and live
  evidence ledger.
- `README.md`, `docs/NEXT_STEPS.md`, `docs/TECH_DEBT.md`, `docs/TESTING.md`:
  navigation, current TD-01 status, and the exact probe recipe.
- `Support/RecompPrototype/recomp_game_start.cpp`: opt-in bounded player/guard
  counters and log output.
- `Sources/RecompPrototypeInput.swift`: launch-argument switch plus
  Simulator-only IJKL analog pulses; existing arrow/menu and A/S/B/Z/R keys stay
  unchanged.
- `patches/goldeneye64recomp-ios-modern-controls.patch`: read-only game-side
  sampling calls and the preserved guard caller.
- `CMakeLists.txt` and verifier scripts: fail stale generated patch pairs and
  require the probe control symbol.

Normal launches do not enable the probe. No retail data, generated dependency
output, screenshots, or private logs are committed.

## Exact next action

Obtain three ordinary-input player KF7 runs of exactly 100 simulation ticks,
record ammo delta plus shot events, and reconcile their mean/range beside the
guard result. If that gate passes, commit/push TD-01 as a measurement-only
review unit. Do not combine the authenticity repair with this baseline.
