# Autonomous goal state

Updated: 2026-08-22 18:05 CEST

## Session identity

| Field | Value |
| --- | --- |
| Goal | Evidence-gated GoldenPad improvement loop |
| Goal thread | `01a028b2-77e4-7441-b0cd-d02a1a9950a5` |
| Branch | `codex/td06-depth-rebuild-discriminator` |
| Starting main | `788667eb6b34ad0ca6154c96b2503db5ede73c1f` |
| Release control | `v0.1.0-preview.2` |
| Active debt | TD-06 matched depth discriminator complete; aliased-depth churn rejected; shared lighting/render order remains |
| Phase | L10 complete: TD-06 evidence review unit committed and pushed |
| Merge policy | Push topic branch; no merge to `main` without user review |

## Current determination

TD-06 now has a bounded counter at the exact pinned RT64 depth
`formatChanged` seam. It counts total rebuilds and width, size, and RDRAM
overlap causes, while leaving framebuffer allocation, clears, render order, and
the frozen Preview 2 depth-address repair unchanged. The pinned device and
Simulator archive closures both passed with 210 RT64 members and 246 total
force-loaded members.

The matched result rejects the leading aliased-depth hypothesis for this build.
A single-player/menu control reached 1,437 display lists/presentations with zero
rebuilds. A launch-only four-player route advertised neutral P3/P4 without
changing AppStorage, entered a real four-player Temple match, showed four live
quadrants, and advanced from 6,035 to 7,348 display lists while every rebuild
counter remained zero. The final `5022ffc...` binary independently repeated the
four-view result from 2,696 through 4,297 display lists with every cause still
zero. The physical lighting flicker is still open; sequential
player-pass ownership of shared lighting state is the next bounded seam.

TD-05 now has an opt-in, non-game-audio discriminator. `--audio-probe` replaces
incoming game samples with a cheap project-generated continuous stereo triangle
before they enter the real PCM ring. The real AVAudioSourceNode consumer then
checks exact ring sequence and output-step continuity. Normal launches never
replace game samples and avoid per-sample probe work.

The prior host had no discontinuity classifier; the unchanged normal-step/jump
table first reported `audio-probe: detector=FAIL`, then `PASS` after the 0.05
step detector was implemented. A sine-wave candidate was rejected because its
per-frame trigonometry perturbed the timing being measured; none of its underrun
counts are acceptance evidence. The final integer triangle probe is continuous
across ring wrap and has a normal step below 0.01.

The final Simulator run observed 1,110,144 output frames with zero ring-sequence
errors, zero output steps above 0.05, and zero producer drops. It did accumulate
4,480 underrun frames across 37 callbacks. The final rate chain was
`requested=22050 source=22050 session=48000 mixer=48000`: GoldenPad matches the
game's final requested source rate and AVAudioEngine performs the output-rate
conversion. This rejects steady-state rate mismatch and ring corruption for
this run. It makes producer/consumer cadence or buffer-reserve policy the next
test seam, but Simulator underruns do not authorize a production buffer change.

A matched normal-mode control produced the same trajectory without any sample
replacement or per-sample continuity work: at 608,931 rendered frames it had
3,335 underrun frames across 26 callbacks, versus 3,195/27 at 604,702 rendered
frames in the synthetic run. The probe is therefore not the source of the
Simulator underruns. Cadence/reserve is a reproducible normal-path Simulator
seam, but its audible consequence and latency tradeoff remain physical gates.

A Home/foreground attempt started a new PID, so it is process-restart evidence,
not lifecycle continuity. TD-05 remains open for physical listening, route
change, interruption, retained-process lifecycle, and a matched failing-session
log. No audio behavior repair is selected.

TD-04 now has a bounded, opt-in lifecycle discriminator. On transient-inactive
or foreground-resume, it snapshots display-list, VI-update, and presented-frame
counters. At the first monitor tick after each transition-relative two-second
boundary it reports one of three states and stops on recovery or on the first
monitor tick at or beyond ten seconds (strictly less than twelve seconds):

- `recovered`: presented frames advanced;
- `presentation-stalled`: display lists or VI advanced but presentation did not;
- `no-runtime-progress`: none of the three counters advanced.

The previous watchdog could only say that RT64 made no progress for ten seconds.
The unchanged classifier expectation first reported `classifier=FAIL`; it
reports `PASS` after the three-state classifier was implemented.

Two retained-process Simulator Home/resume observations produced different
results. One recovered with `dl +2 / vi +2 / presented +2` at 2.281 seconds.
Another held `dl=918 / vi=917 / presented=870` for more than ten seconds. In the
frozen run the diagnostics thread and input publisher remained alive, while the
game timer, renderer counters, and audio production stayed fixed and ordinary
input did not advance the game. That observation is an intermittent
`no-runtime-progress` reproduction, not evidence of a drawable-only stall.
Other Home runs started a new PID and are process-restart controls, not resume
evidence. The Simulator screenshot toolbar did not cause an iOS scene-phase
transition and is not screenshot acceptance.

No TD-04 behavior repair is selected. Physical screenshot, Control Center,
lock, and retained-process background/resume runs must classify the failure. If
display lists or VI advance while presentation stays flat, instrument RT64/
Plume drawable, present-queue, and command-fence waits. If all counters stay
flat, inspect the runtime/game-thread resume seam before touching Metal.

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
| TD-04 isolated branch | PASS | TD-04 is stacked on the pushed TD-07 checkpoint and isolated on `codex/td04-lifecycle-discriminator` |
| TD-04 red classifier | PASS | The first opt-in build reported `lifecycle-probe: classifier=FAIL` against the prior generic no-progress model |
| TD-04 green classifier | PASS | The unchanged zero-progress, presentation-stalled, and recovered table reports `lifecycle-probe: classifier=PASS` |
| TD-04 focused ARM64 Simulator build | PASS | Release target rebuilt successfully; executable SHA-256 `6510dc3c0ce07845f2361987a4b5784b68b83fa1eca9dcce2ba7af3b2789ffec` |
| Retained resume recovery | PASS (one run) | Same PID recovered at 2.281 seconds with deltas `dl=2 vi=2 presented=2` |
| Retained resume freeze | REPRODUCED (one run) | Same PID stayed at `dl=918 vi=917 presented=870`; game timer/audio stayed fixed while diagnostics/input threads remained live |
| Simulator screenshot transition | NOT ESTABLISHED | Simulator's screenshot control did not generate the iOS transient-inactive callback |
| Physical lifecycle matrix | NOT RUN | Simulator cannot establish device screenshot, Control Center, lock, or physical Metal behavior |
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
| TD-07 commit/push | PASS | Implementation commit `38f0c6b` is pushed on `origin/codex/td07-controller-ownership`; `main` was not changed |
| TD-04 commit/push | PASS | Evidence commit `a24c226` is pushed on `origin/codex/td04-lifecycle-discriminator`; `main` was not changed |
| TD-05 isolated branch | PASS | TD-05 is stacked on the pushed TD-04 checkpoint and isolated on `codex/td05-audio-discriminator` |
| TD-05 red detector | PASS | The first opt-in build reported `audio-probe: detector=FAIL` against the prior no-classifier baseline |
| TD-05 green detector | PASS | The unchanged small-step/large-jump table reports `audio-probe: detector=PASS` at the final 0.05 threshold |
| TD-05 focused ARM64 Simulator build | PASS | Release target rebuilt successfully; executable SHA-256 `f1de4a316a1da9db2e8b4693523de634c10c3810552e0229af43c06be4c238b3` |
| Final audio-rate relationship | PASS | Persistent log ends at `requested=22050 source=22050 session=48000 mixer=48000` |
| Synthetic ring integrity | PASS (Simulator) | 1,110,144 observed output frames; zero sequence errors, zero >0.05 jumps, zero producer drops |
| Synthetic underrun trajectory | OBSERVED (Simulator) | 4,480 underrun frames across 37 callbacks; the continuity detector remained zero because the fade path smoothed those boundaries |
| Matched normal-mode underruns | REPRODUCED (Simulator) | Normal path reached 3,335/26 at 608,931 rendered frames versus synthetic 3,195/27 at 604,702; the probe did not create the cadence defect |
| TD-05 physical listening/routes | NOT RUN | Simulator cannot establish audible static, speaker/Bluetooth behavior, interruptions, or retained-process lifecycle continuity |
| TD-05 commit/push | PASS | Evidence commit `119d532` is pushed on `origin/codex/td05-audio-discriminator`; `main` was not changed |
| TD-06 isolated branch | PASS | TD-06 is stacked on the pushed TD-05 checkpoint and isolated on `codex/td06-depth-rebuild-discriminator` |
| TD-06 archive closures | PASS | iPhoneOS and Simulator each retained 210 RT64 members and 246 force-loaded members; RT64 hashes `9d522e0...` and `1c49791...` |
| TD-06 single-player control | PASS | 1,437 display lists/presentations; total/width/size/RDRAM rebuilds all zero |
| TD-06 four-player Temple discriminator | HYPOTHESIS REJECTED | Four live quadrants; initial run `dl=6035..7348`, exact-final recheck `dl=2696..4297`; total/width/size/RDRAM rebuilds all zero |
| TD-06 focused ARM64 Simulator build | PASS | Release executable SHA-256 `5022ffc11d4d127b1714bd9aa728ea2eb5b2ff4736c656ab7cbd0fb5747fface` |
| TD-06 preservation and clean end | PASS | Both ROMs, active/backup saves, and preferences remained byte-identical; Home removed `active-session.marker` |
| TD-06 normal-launch isolation | PASS | Exact final binary returned to `input=external-p1` with no depth-probe or neutral-P3/P4 log entries |
| ROM-free host verification | PASS | Fresh temporary ARM64 Simulator build passed with the complete inert-stub symbol surface |
| Mac Alpha rebuild | BLOCKED BEFORE COMPILE | Existing private generated `patches.c` lacks the earlier TD-01 probe symbol; CMake correctly stopped before compiling/linking TD-06. The RT64 query is compiled out under `GOLDENPAD_RECOMP_MAC`; a fresh matched generation campaign is still required |
| TD-06 commit/push | PASS | Evidence commit `db19f54` is pushed on `origin/codex/td06-depth-rebuild-discriminator`; `main` was not changed |

## Blocker ledger

| Item | Status | Evidence | Next discriminating action |
| --- | --- | --- | --- |
| TD-01 sustained player KF7 baseline | FORMALLY BLOCKED | Ordinary input reached a dropped KF7, but the pickup held 20 rounds; repeated attempts did not provide the 34-round discrimination ceiling and survive 100 ticks | Resume only with a repeatable ordinary setup holding at least 34 rounds; do not inject inventory or apply the timing repair |
| TD-02 physical acceptance | WAITING FOR HUMAN/DEVICE INPUT | Code and Simulator gates pass; no physical touch or controller feel can be inferred | Test modern MOVE/LOOK on iPhone and iPad, then test Modern, Original C-buttons, and Off with a physical controller |
| TD-07 physical lifecycle | WAITING FOR HUMAN/DEVICE INPUT | Synthetic lifecycle and Simulator integration pass; no real disconnect/reconnect or multi-controller timing was exercised | Test controller loss while held, reconnect, reorder, background/foreground, then design real P2-P4 slots separately |
| TD-04 physical classification | WAITING FOR HUMAN/DEVICE INPUT | Intermittent same-process Simulator freeze is real, but the physical failure has not been classified | Run the opt-in physical transition matrix and select scheduler/runtime or renderer wait instrumentation from the observed counter pattern |
| TD-05 physical audio | WAITING FOR HUMAN/DEVICE INPUT | Simulator rejects rate mismatch/ring corruption but observes underruns without detected jumps | Listen to the synthetic probe on speaker and Bluetooth across route/interruption/lifecycle; retain the same-session counters when static is heard |
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
- TD-04 diagnostics are opt-in via `--lifecycle-probe`; normal launches retain
  only the pre-existing health/watchdog logging.
- TD-04 writes at most one sample after each transition-relative two-second boundary,
  exits early on recovery, and stops on the first existing monitor tick at or
  beyond ten seconds. It does not add sleeps or locks to the game, render,
  audio, or main threads.
- TD-05 replaces sample values only under `--audio-probe`; it preserves the
  actual producer callback cadence, ring indices, prebuffer, underrun fade,
  AVAudioSourceNode consumer, and AVAudioEngine conversion path.
- The final triangle-wave candidate uses integer arithmetic. The earlier sine
  candidate was rejected after its computational cost confounded underrun
  evidence.
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
  port, reports truthful runtime ownership, keeps unowned ports neutral, and
  owns the opt-in bounded lifecycle classifier.
- `Sources/RecompPrototypeMetalCanvas.swift`: enables the TD-04 diagnostic only
  for the explicit `--lifecycle-probe` launch argument and enables TD-06
  counter logging only for `--depth-rebuild-probe`.
- `Sources/RecompPrototypeAudio.swift`: enables TD-05 only for
  `--audio-probe`, records source/session/mixer rates, and polls bounded probe
  counters off the render thread.
- `Support/RecompPrototype/recomp_rt64_surface_stub.cpp`: keeps every probe and
  input symbol inert but link-complete in the no-AOT verification target.
- `scripts/verify-recomp-prototype-host.sh` and
  `scripts/verify-recomp-prototype-ipa.sh`: require the TD-06 runtime setter;
  the package audit also requires the RT64 archive getter.
- `patches/rt64-ios-embedded.patch`: adds the cause-specific RT64 depth-format
  counter without changing the framebuffer path.
- `scripts/verify-rt64-ios-static.sh`: verifies the exported counter in both
  mobile archives, reports shader-generation failures, and leaves pinned
  sources free of patch backup files.
- `docs/GOAL_STATE.md`, `docs/NEXT_STEPS.md`, `docs/STATUS.md`,
  `docs/TECH_DEBT.md`, `docs/TESTING.md`, `docs/PLAN.md`, and
  `docs/WORKLOG.md`: current implementation status, evidence, remaining human
  gate, and next safe work.

Normal launches enable neither the sidestep publication probe, the TD-07 paired
ownership probe, nor TD-06 counter logging. The launch-only four-player route
never writes the saved two- or four-player preferences.

## Exact next action

Keep TD-06 unmerged. Start the next independent TD-06 unit at the game/renderer
boundary: locate shared lighting state that
persists across sequential player passes and add only a fixed-render-order
discriminator. Do not change the frozen Preview 2 depth-address repair, and do
not promote a lighting repair without continuous physical four-view evidence.
Keep TD-01 formally blocked, retain TD-02/TD-04/TD-05/TD-07 for physical
acceptance, and keep networking gated behind stable local ownership and
deterministic state.
