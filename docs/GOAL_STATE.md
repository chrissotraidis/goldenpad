# Autonomous goal state

Updated: 2026-08-22 16:31 CEST

## Session identity

| Field | Value |
| --- | --- |
| Goal | Evidence-gated GoldenPad improvement loop |
| Goal thread | `01a028b2-77e4-7441-b0cd-d02a1a9950a5` |
| Branch | `codex/td02-modern-sidestep` |
| Starting main | `788667eb6b34ad0ca6154c96b2503db5ede73c1f` |
| Release control | `v0.1.0-preview.2` |
| Active debt | TD-02 implementation candidate passes code and Simulator gates; physical touch/controller acceptance remains |
| Phase | L9 checkpoint: document, commit, and push TD-02 as an isolated review unit |
| Merge policy | Push topic branch; no merge to `main` without user review |

## Current determination

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

This is not release acceptance. The code-level and Simulator gates pass, but a
human must still judge touch feel on iPhone and iPad and modern/original mode
behavior with a physical controller. Preview 2 remains the release control.

## Gate ledger

| Gate | Status | Evidence |
| --- | --- | --- |
| Main/release control recorded | PASS | `main` and `origin/main` began at `788667e`; Preview 2 was not modified |
| Dedicated review unit | PASS | TD-01 is preserved on `origin/codex/autonomous-repair-loop`; TD-02 is isolated on `codex/td02-modern-sidestep` |
| Red discriminator | PASS | The first `--sidestep-probe` build reported `Modern sidestep mapping probe: FAIL` with the pre-repair identity mapping |
| Green code-level mapping probe | PASS | The same table-driven probe reports `PASS` for left, right, center/dead-zone, menu, and Original-mode cases |
| Focused ARM64 Simulator build | PASS | `GoldenPadRecompPrototype` Release target rebuilt successfully; executable SHA-256 `4a5f6353fa7a21c822baa03670315ecb5973b98d1431328ee7914acbb5fb3e06` |
| Required bridge symbols | PASS | `_goldenpad_recomp_gameplay_input_active` and `_goldenpad_recomp_set_sidestep_probe_enabled` are exported and required by both primary-runtime verifiers |
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
| Commit/push | PENDING | Run static checks, commit this isolated review unit, and push only its topic branch |

## Blocker ledger

| Item | Status | Evidence | Next discriminating action |
| --- | --- | --- | --- |
| TD-01 sustained player KF7 baseline | FORMALLY BLOCKED | Ordinary input reached a dropped KF7, but the pickup held 20 rounds; repeated attempts did not provide the 34-round discrimination ceiling and survive 100 ticks | Resume only with a repeatable ordinary setup holding at least 34 rounds; do not inject inventory or apply the timing repair |
| TD-02 physical acceptance | WAITING FOR HUMAN/DEVICE INPUT | Code and Simulator gates pass; no physical touch or controller feel can be inferred | Test modern MOVE/LOOK on iPhone and iPad, then test Modern, Original C-buttons, and Off with a physical controller |
| TD-03 A12-family compatibility | EVIDENCE BLOCKED | No full redacted `.ips` or local A12 reproduction | Obtain the complete crash artifact and reproduce Preview 2 before selecting a renderer change or support floor |

TD-02's physical gate does not block independent TD-07 synthetic ownership
work on a new branch. It does block release promotion or closing issue #8.

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

- `Sources/RecompPrototypeInput.swift`: pure modern MOVE mapper, red/green
  probe, game-state classification, mode-change neutral frame, settings-sheet
  suspension, and unchanged modern LOOK publication.
- `Sources/RecompPrototypeApp.swift`: settings/share presentation suspends the
  host input bridge and reliably resumes it on dismissal.
- `Support/RecompPrototype/recomp_game_start.cpp`: read-only gameplay/watch
  classifier and opt-in sidestep publication evidence.
- `scripts/verify-recomp-prototype-host.sh` and
  `scripts/verify-recomp-prototype-ipa.sh`: require the new runtime symbols.
- `docs/GOAL_STATE.md`, `docs/NEXT_STEPS.md`, `docs/TECH_DEBT.md`, and
  `docs/TESTING.md`: current implementation status, evidence, remaining human
  gate, and next safe work.

Normal launches do not enable the sidestep publication probe. The game-state
classification log is bounded to semantic transitions.

## Exact next action

Run the repository/static checks, commit and push TD-02 on
`codex/td02-modern-sidestep`, and do not merge it. Then create a separate TD-07
topic branch for the synthetic controller ownership lifecycle probe and
neutral-on-disconnect repair. Keep TD-01 blocked and keep networking work gated
behind stable local ownership.
