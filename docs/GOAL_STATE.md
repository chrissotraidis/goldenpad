# Autonomous goal state

Updated: 2026-08-22 16:52 CEST

## Session identity

| Field | Value |
| --- | --- |
| Goal | Evidence-gated GoldenPad improvement loop |
| Goal thread | `01a028b2-77e4-7441-b0cd-d02a1a9950a5` |
| Branch | `codex/td07-controller-ownership` |
| Starting main | `788667eb6b34ad0ca6154c96b2503db5ede73c1f` |
| Release control | `v0.1.0-preview.2` |
| Active debt | TD-07 disconnect/lifecycle containment passes code and Simulator gates; physical reconnect and real P3/P4 routing remain |
| Phase | L9 checkpoint: document, commit, and push TD-07 as an isolated review unit |
| Merge policy | Push topic branch; no merge to `main` without user review |

## Current determination

TD-07 now has a bounded ownership/lifecycle containment candidate. Ownership is
explicit: normal touch-only mode assigns touch to Player 1; normal controller
mode assigns the retained controller to Player 1; opt-in paired mode assigns the
controller to Player 1 and touch to Player 2. If that controller disappears
while paired mode is requested, every port is neutral and touch remains
unassigned instead of silently taking Player 1. Reassignment always crosses a
four-port neutral boundary. Overlay and scene lifecycle suspension are tracked
independently, so dismissing one cannot resume input while the other remains
suspended.

The candidate also retains the current `GCController` while it remains present,
even if enumeration order changes. This prevents a newly connected controller
from silently replacing Player 1. It does not implement stable real P2-P4
controller slots, an assignment UI, or network multiplayer.

The modern sidestep defect has a bounded implementation candidate. During live
gameplay, horizontal MOVE input now becomes GoldenEye's native C-left/C-right
sidestep while MOVE-Y remains on the analog stick. Horizontal LOOK remains on
GoldenPad's existing modern camera path. The explicit **Original N64
C-buttons** controller mode bypasses the new MOVE mapping.

The mapping is owned by GoldenEye's game state, not a Swift screen guess. Title
and mission menus keep the original analog stick. Beginning a watch transition
immediately selects menu/watch semantics, and live gameplay semantics resume
only after the watch has fully closed. Presenting a GoldenPad settings/share
sheet publishes neutral state on all four ports until dismissal.

Neither candidate is release acceptance. TD-07 still needs physical
disconnect/reconnect/background testing and real multi-controller work; TD-02
still needs touch/controller feel acceptance. Preview 2 remains the release
control.

## Gate ledger

| Gate | Status | Evidence |
| --- | --- | --- |
| Main/release control recorded | PASS | `main` and `origin/main` began at `788667e`; Preview 2 was not modified |
| Dedicated review units | PASS | TD-01 is preserved on `origin/codex/autonomous-repair-loop`; TD-02 is pushed on `origin/codex/td02-modern-sidestep`; TD-07 is isolated on `codex/td07-controller-ownership` |
| Red discriminator | PASS | The first `--sidestep-probe` build reported `Modern sidestep mapping probe: FAIL` with the pre-repair identity mapping |
| Green code-level mapping probe | PASS | The same table-driven probe reports `PASS` for left, right, center/dead-zone, menu, and Original-mode cases |
| TD-07 red discriminator | PASS | The unchanged ownership model reported `Controller disconnect ownership probe: FAIL` because paired-controller loss implicitly returned touch to Player 1 |
| TD-07 green lifecycle probe | PASS | The same connect/order/disconnect/reconnect/held-input/overlay/scene table reports `Controller ownership lifecycle probe: PASS` after explicit routing, release-before-activation, and neutral boundaries |
| Focused ARM64 Simulator build | PASS | `GoldenPadRecompPrototype` Release target rebuilt successfully; executable SHA-256 `7c8a8fff5a085d7fe8e925e49a517832f9489e41dc1b55d88e5a478b5d936e59` |
| Required bridge symbols | PASS | Gameplay, sidestep-probe, and touch-port ownership symbols are exported and required by both primary-runtime verifiers |
| Paired integration route | PASS | Opt-in Simulator runtime reached `input=external-p1+touch-p2` and visibly rendered the Player 2 touch overlay |
| Opt-in isolation | PASS | A clean ordinary relaunch returned to `input=external-p1`, hid the touch overlay, and did not persist the paired test mode |
| Independent suspension reasons | PASS (synthetic) | Overlay-only, scene-only, combined, and separately released states remain suspended until both reasons clear |
| Physical disconnect/reconnect | NOT RUN | Simulator and synthetic models cannot establish GameController notification timing or hardware behavior |
| Real P2-P4 controllers | NOT IMPLEMENTED | This candidate contains the existing P1/P2 test route; it does not create stable multi-controller slots |
| Live right sidestep publication | PASS | Opt-in runtime log: `controller=1 buttons=0x0001 stick=(0,0)` |
| Live left sidestep publication | PASS | Opt-in runtime log: `controller=1 buttons=0x0002 stick=(0,0)` |
| File/mission menus | PASS | Title/file/mission navigation remained on ordinary stick semantics and rendered normally |
| Watch transition and navigation | PASS | An initial candidate leaked one C-right sample during watch opening and was rejected; the corrected candidate switches to menu/watch semantics before the first transition sample, navigates the watch horizontally, and records no extra sidestep event |
| GoldenPad settings input isolation | PASS | Settings rendered over live gameplay; repeated horizontal Simulator input produced no additional sidestep sample while all host ports were suspended |
| Layout/screenshot gate | PASS | File select, mission briefing, live Dam, watch inventory, and the settings sheet showed no new static-layout regression |
| In-place preservation | PASS | Both ROM copies, active save, backup save, and preferences remained byte-identical after every Simulator candidate install |
| Clean session end | PASS | Simulator Home removed `active-session.marker`; no app session or recording was left active |
| Physical touch/controller feel | NOT RUN | Simulator and synthetic evidence cannot establish touch ergonomics or physical-controller feel |
| QuickTime | OFF | It was never started |
| Commit/push | PENDING | Run static checks, commit this isolated TD-07 review unit, and push only its topic branch |

## Blocker ledger

| Item | Status | Evidence | Next discriminating action |
| --- | --- | --- | --- |
| TD-01 sustained player KF7 baseline | FORMALLY BLOCKED | Ordinary input reached a dropped KF7, but the pickup held 20 rounds; repeated attempts did not provide the 34-round discrimination ceiling and survive 100 ticks | Resume only with a repeatable ordinary setup holding at least 34 rounds; do not inject inventory or apply the timing repair |
| TD-02 physical acceptance | WAITING FOR HUMAN/DEVICE INPUT | Code and Simulator gates pass; no physical touch or controller feel can be inferred | Test modern MOVE/LOOK on iPhone and iPad, then test Modern, Original C-buttons, and Off with a physical controller |
| TD-07 physical lifecycle | WAITING FOR HUMAN/DEVICE INPUT | Synthetic lifecycle and Simulator integration pass; no real disconnect/reconnect or multi-controller timing was exercised | Test controller loss while held, reconnect, reorder, background/foreground, then design real P2-P4 slots separately |
| TD-03 A12-family compatibility | EVIDENCE BLOCKED | No full redacted `.ips` or local A12 reproduction | Obtain the complete crash artifact and reproduce Preview 2 before selecting a renderer change or support floor |

TD-02's physical gate and TD-07's physical lifecycle gate are independent. Both
block promotion of their respective candidates; neither justifies starting a
network transport.

## Evidence ledger

- The retained Preview 2 release tag and `main` were not changed.
- The desired mapping test was first run against an identity implementation and
  failed, then passed unchanged after the mapping was implemented.
- Modern gameplay maps MOVE-X beyond the existing `0.30` threshold to native
  C-left/C-right and zeros analog stick X. MOVE-Y and all existing action
  buttons are preserved.
- Touch always uses modern MOVE semantics. A physical controller uses them only
  in **Modern analog (experimental)** mode; Original and Off retain their
  previous left-stick behavior.
- Modern LOOK remains separate: controller right analog and accumulated touch
  look continue through the existing camera bridge and never enter the MOVE
  mapper.
- The game-state bridge reads the pinned `BONDdata` watch fields. Live gameplay
  requires `watch_animation_state == 0`, `outside_watch_menu != 0`, and
  `open_close_solo_watch_menu == 0`.
- The first watch candidate waited only for `outside_watch_menu` to clear. The
  runtime probe caught one leaked C-right sample during the opening animation;
  that candidate was rejected and replaced by the three-field boundary.
- The corrected runtime sequence was menu/watch → live gameplay → menu/watch,
  with exactly two sidestep samples between the transitions: C-right and
  C-left, both with analog stick X equal to zero.
- Opening Settings from live gameplay suspends all four host ports and clears
  touch look/action state. Dismissal resumes current input without persisting a
  new setting.
- TD-07 first encoded the pre-repair paired-disconnect behavior and failed
  because touch fell through to Player 1. The unchanged expectations pass after
  explicit ownership routes and neutral-before-reassignment behavior.
- The lifecycle probe also proves stable current-controller retention across
  enumeration reordering, release-before-activation for a held reconnect, and
  independent overlay/scene suspension state.
- The opt-in Simulator launch exercised the live bridge as controller Player 1
  plus touch Player 2. A normal relaunch returned to controller Player 1 only.
- Final Simulator data hashes remained:
  - both ROM copies: `7ec491ee3164851d0995e3e8ad19999df5e3028be6ba3729c4ac16c31a9c0959`;
  - active save: `36d67fe002913ae2b8ba1b1d9fd45c236d6de0b0e4dc11ee90cde23816216fe9`;
  - backup save: `c01d40132c4db90db0c3a7ee48d121705daa7e5f51ba0f0b238b29046dbeb634`;
  - preferences: `4000410d27cb619ab806f6792102ea42b0e38207a50ab4038f49b6dd97e092b8`.
- The first final-build attempt inside the restricted sandbox lost access to
  CoreSimulator. The unchanged focused retry with normal host access passed;
  this is environmental, not a source failure.
- No retail ROM, save, preference, screenshot, generated dependency output, or
  private runtime log is tracked.

## Changed files

- `Sources/RecompPrototypeInput.swift`: explicit ownership route, red/green
  lifecycle probe, stable current-controller retention, neutral transition,
  touch-overlay visibility, and independent overlay/scene suspension.
- `Sources/RecompPrototypeApp.swift`: renders touch controls only when touch has
  an owner and routes scene lifecycle through its independent suspension reason.
- `Support/RecompPrototype/recomp_game_start.cpp`: receives the explicit touch
  port, reports truthful runtime ownership, and keeps unowned ports neutral.
- `scripts/verify-recomp-prototype-host.sh` and
  `scripts/verify-recomp-prototype-ipa.sh`: require the new runtime symbols.
- `docs/GOAL_STATE.md`, `docs/NEXT_STEPS.md`, `docs/STATUS.md`,
  `docs/TECH_DEBT.md`, `docs/TESTING.md`, `docs/PLAN.md`, and
  `docs/WORKLOG.md`: current implementation status, evidence, remaining human
  gate, and next safe work.

Normal launches enable neither the sidestep publication probe nor the TD-07
paired ownership probe. The latter is a launch-only diagnostic and never writes
the saved two-player preference.

## Exact next action

Run the repository/static checks, commit and push TD-07 on
`codex/td07-controller-ownership`, and do not merge it. Keep TD-01 formally
blocked, retain TD-02 for physical acceptance, and keep networking gated behind
physical lifecycle acceptance plus a separate real P2-P4 ownership design.
