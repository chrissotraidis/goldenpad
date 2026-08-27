# Technical debt and upstream watch

Updated: 2026-08-27

This is GoldenPad's authoritative engineering-debt ledger. It records current
defects, evidence strength, repair order, acceptance gates, rejected approaches,
and upstream changes that may materially improve the product. It is not a
mandate to replace working foundations whenever an upstream percentage changes.

Evidence labels used below:

- **Confirmed:** entailed by the current source, an exact pinned upstream, or a
  reproducible public report with a deterministic signature.
- **Observed:** seen during a bounded physical or hands-on run; the artifact may
  live outside the repository under the project's private-data boundary.
- **Leading hypothesis:** a source-supported causal explanation that still
  needs one discriminating test.
- **Unknown:** insufficient reproduction or evidence; do not patch by analogy.

## Current decision

Keep the statically recompiled GoldenEye + N64ModernRuntime + RT64/Metal target
as GoldenPad's primary iPhone/iPad runtime. Keep exact MGB64 pin
`cd9b58f5f91291579b8e551aa925aab000d311cf` buildable as `GoldenPad Legacy` for
regression comparison and fallback, not as the release product.

The current preview line deliberately leaves the following primary-runtime
debt visible:

- native-60-Hz player/guard automatic-fire cadence is not timing-authentic;
- Preview 4 supersedes Preview 3's opt-in Honey sidestep adapter with one shared
  1.1 through 1.4 mapping; issue #8 reporter confirmation remains open, but no
  additional input rewrite is selected;
- A12-family RT64/Metal compatibility is unresolved after the deterministic
  issue #9 first-frame crash report;
- issue #19's iPhone 13 mini initialization crash is confirmed as a Metal
  deployment-target defect and selected for the compatibility-only Preview 7;
  production-identity confirmation remains a release gate;
- local multiplayer has a physically coherent experimental baseline, but slight
  lighting flicker and real three/four-controller routing remain open;
- settings/share presentation can leave latched touch publishing, controller
  loss can collapse touch onto Player 1 without a neutral frame, and the mobile
  input timer still uses the default run-loop mode;
- Preview 2 has the bounded in-app retail conversion flow, but its exact final
  first-run path still needs hands-on acceptance on both iPhone and iPad;
- occasional audio static and stage-specific geometry faults need precise
  reproduction and bounded fixes;
- the runtime writes a second converted-ROM copy under Application Support;
  unlike the protected Documents copy, that path is not yet backup-excluded or
  assigned an explicit file-protection class;
- six anonymous `/private/tmp/goldenpad-recomp.*` compiler source literals
  remain in the executable; the package verifier rejects private `/Users/`
  paths and any unexpected temporary path;
- longer thermal, audio-route, screenshot/resume and multi-controller sweeps
  remain post-preview quality work.

Do not regress the accepted single-player speed, high-resolution renderer,
touch tuning, controller mapping, save compatibility, or clean-install defaults
while addressing that debt.

## Touch sidestep decision — 2026-08-22

[Issue #8](https://github.com/chrissotraidis/goldenpad/issues/8) records a real
gap between GoldenPad's current input configurations. The accepted iPhone/iPad
touch template combines GoldenEye's original analog-stick movement with
GoldenPad's relative LOOK surface. Horizontal MOVE input therefore retains the
original turn behavior and does not expose native sidestepping.

Physical controllers have a separate **Original N64 C-buttons** right-stick
configuration. It emits C-left/C-right and restores GoldenEye's native
sidestepping, but it replaces the modern analog right-stick look path. Preview 2
had no corresponding touch template; Preview 3 added a style-gated opt-in Honey
adapter. Preview 4 supersedes both paths with one shared mapping for mobile and
Mac that reads the active 1.1 through 1.4 style, keeps raw menu input, and
preserves native left-stick Aim and tank semantics.

The verified product decision was to correct the existing modern semantics, not
add four visible C buttons or another preset. Preview 4 implements and
physically accepts that decision on iPad, including menus, native Aim, and the
Runway tank path. Issue #8 remains open for its reporter and broader claimed-
platform confirmation against the superseding Preview 4 release. That open
verification is not evidence for another mapping change.

## External review disposition — 2026-08-23

The attached independent revision-2 review is retained in
[`EXTERNAL_REVIEW_2026-08-22.md`](EXTERNAL_REVIEW_2026-08-22.md). It inspected
historical baseline `788667e`; it is supporting evidence, not repository
instructions or a substitute for Preview 4 verification. Its source findings
remain useful, while its baseline statements and line references are frozen to
that older tree.

The review's documentation corrections are incorporated into the current
authority documents. Its code findings were reconciled against Preview 4 and
the isolated debt branches:

- Preview 4 supersedes the opt-in sidestep adapter with one shared 1.1 through
  1.4 input mapping and accepted iPad Aim/tank behavior. It does not close issue
  #8 reporter verification, settings/share touch latch, controller-collapse
  neutral frame, multi-controller ownership, or physical lifecycle acceptance.
- The fire-rate mechanism remains confirmed. Preview 4 retains the default-off
  read-only probe; three player magazines measured 34.4828 events per 100 ticks
  with zero range and guard windows measured 13/17/18. The isolated shared-
  getter candidate then produced the exact expected 12 player events/100 ticks
  and received hands-on core-gameplay acceptance. Preview 5 releases that repair.
- Matched isolated TD-06 runs recorded zero depth-`formatChanged` rebuilds, and
  a fixed-player-order diagnostic showed no systematic improvement and was
  reverted. The zero did not support predicted per-frame churn, but the counter
  was not calibrated on a known-active pre-repair build and omitted non-format
  uploads, so the wider depth-activity family remains unclosed.
- GoldenEye requests exactly 22,050 Hz and the runtime passes that value through
  unquantized, matching the host source format. Producer/consumer rate mismatch
  is ruled out; overflow discontinuity, lifecycle reset races, cadence/underrun,
  and route/post-engine behavior remain live audio hypotheses.
- The review's non-Metal3 Plume descriptor-binding divergence is a strong A12
  diagnostic lead, not a proven crash cause or authority to change the renderer.
- The runtime-managed converted-ROM copy, game-bearing-build reproducibility,
  and modal/run-loop neutralization gaps are explicit TD-12, TD-13, and TD-14
  items.

The review performed no build, game run, device test, audio capture, or
profiling pass. Confidence labels in that snapshot remain advisory.

## Priority ledger

Priority describes user impact and dependency order, not an instruction to
bundle unrelated changes. Every repair must be independently revertible.

| ID | Priority | Problem | Evidence status | Current conclusion | Next gate before promotion |
| --- | --- | --- | --- | --- | --- |
| TD-01 | P0 | Automatic weapons and guard cadence at native 60 Hz | **Repaired in Preview 5**: Preview 4 measured 34.4828 player events/100 ticks; Preview 5 telemetry recorded the exact expected 12/100 and the user accepted navigation, movement, gameplay, and runtime quality | Root cause was the native-60-Hz host consuming N64-frame automatic-rate divisors without the frame-cost conversion; shared player/guard getter, nonpositive pass-through, generated MIPS, deterministic cadence, input/tank, iOS, Mac, package, and physical player gates pass | Retain the independently revertible repair and default-off diagnostic. No complete candidate guard window or explicit PP7 sequence was logged, so do not misstate those as physical evidence |
| TD-02 | P0 | Modern touch/controller sidestep semantics, [issue #8](https://github.com/chrissotraidis/goldenpad/issues/8) | **Repair released in Preview 4; reporter verification open** | Preview 4 replaces the opt-in Honey adapter with one shared 1.1 through 1.4 mapping and preserves raw menus, native left-stick Aim, and tank semantics; the user physically accepted the iPad control matrix | Ask the reporter to verify Preview 4 touch and controller behavior; do not change the accepted mapping without a new reproduction and the full regression gate |
| TD-03 | P0 | A12X first-frame RT64/Metal crash, [issue #9](https://github.com/chrissotraidis/goldenpad/issues/9) | **Confirmed report** on the published Preview 1 IPA; cause unknown; full `.ips` and local A12 reproduction remain absent | A12X is inside the declared ARM64/Metal/iPadOS envelope. Plume's non-Metal3 descriptor-binding path is a strong diagnostic lead, not a proven cause | Obtain the full redacted `.ips` and A12 reproduction; separately force non-direct/Tier-1 binding paths in diagnostic-only builds on accepted hardware before selecting a repair or floor |
| TD-04 | P1 | Screenshot, system-overlay, and foreground-resume stall/freeze | **Isolated discriminator evidence; physical classification open** | One experimental Simulator run recovered and another held all runtime-progress counters flat while diagnostics stayed live. This is not proof of a drawable-only stall; unbounded fence and queue waits remain | Run the opt-in physical transition matrix, then add only the wait-point instrumentation selected by the observed counter class |
| TD-05 | P1 | Intermittent audible static | **Observed report; cause unknown; rate mismatch ruled out** | Game, runtime, and host agree at 22,050 Hz. Isolated synthetic Simulator runs found no ring corruption or large jumps but did observe underruns; overflow discontinuity, reset race, cadence, and route artifacts remain | Capture one audible failing physical session with counter series and external timestamp; use the ROM-free signal only if the counters stay flat |
| TD-06 | P1 | Residual split-screen lighting flicker | **Observed; fixed order rejected; rebuild counter inconclusive** | Matched isolated runs recorded zero depth-`formatChanged` rebuilds, but lacked known-active calibration and non-format upload counts. Fixed player order showed no systematic benefit and was reverted. The physical owner remains unknown | Capture fixed-scene physical video first; if new telemetry is justified, calibrate it on a known-active path and count both rebuild and non-format upload branches |
| TD-07 | P1 | Real three/four-controller ownership and lifecycle | **Confirmed disconnect leak/design gap; isolated containment candidate exists** | On disconnect-to-none, Preview 3 skips `releaseTouchInput()` and can republish P2 touch as P1; it also lacks stable P2-P4 slots and identity policy. A separate branch proves containment in Simulator only | Rebase the smallest containment change, require a neutral frame on every ownership transition, add held-input suspend/resume coverage, then physically accept before designing slots |
| TD-08 | P2 | Mac horizontal mouse yaw remains sluggish | **Known Preview 6 limitation reconfirmed during Preview 7 review; not a regression** | Preview 7's Mac executable and package are byte-identical to Preview 6. Vertical mouse movement feels acceptable, but horizontal yaw remains sluggish. The shared relative queue is wide while combined output is normalized to one per-frame `[-1, 1]` budget before the game camera path, so raising global sensitivity is not a discriminating repair | Retain Preview 6 as the exact control. Before changing input, measure queued horizontal units, normalized output, saturation count, and final yaw delta in one bounded Mac-only comparison |
| TD-09 | P2 | Thin far-right Mac render edge | **Observed**; host coverage seam is the **leading hypothesis** | Mobile already masks the same family of seam at the final presentation boundary; changing RT64 sizing is rejected | Measure the strip and test a Mac-only one-point trailing-edge mask against fixed Dam/Surface captures |
| TD-10 | P2 | Stage-specific geometry, sky, water, and framebuffer-effect gaps | **Mixed** | Live original `skyRender` selects water, but active replacement helpers discard selected texture/geometry into fog-color fills; the full textured replacement is disabled. Other reports remain unreduced | Treat sky/water as bounded upstream feature debt; require one original-versus-current stage/settings/camera case for every other effect or geometry claim |
| TD-11 | P3 | Peer-to-peer and online multiplayer | **Not implemented** | Local split-screen is one runtime; controller polling exists, but stable simulation frame identity, hashes, serialization, rollback, matchmaking, and transport do not | Complete TD-07, add an offline frame/hash determinism probe, then consider the two-device LAN experiment |
| TD-12 | P2 | Converted-ROM storage, backup, and package-path hygiene | **Confirmed write path; backup exposure is a strong inference** | The protected Documents runtime image is excluded from backup, but librecomp writes another full copy under `Application Support/GoldenPadRecomp` without explicit backup exclusion/protection. Package scans also miss `/var/folders` | Exclude/protect the runtime-managed copy without changing conversion or saves; extend path checks and verify attributes plus package contents |
| TD-13 | P2 | Game-bearing build reproducibility | **Structural gap, disclosed** | Public verifiers build the ROM-free host and audit packaged content; private generated AOT inputs and the accepted runtime pin prevent an external clean build of the shipped executable | Add a scripted game-bearing build proof usable with private inputs and reproduce one shipped-source digest from two independent clean build directories |
| TD-14 | P1 | Host input suspension and modal/run-loop neutralization | **Confirmed source gaps** | Settings/share sheets do not explicitly release touch; the 60 Hz mobile publisher uses the default run-loop mode and can pause during tracking; pause/watch guard completeness still needs a transition probe | Add a failing held-touch modal/scroll/watch transition test, then neutralize all ports on presentation and prove menu/watch/gameplay resume without replayed input |

## Source and evidence map

This map is the shortest route from a debt ID to the seam that must be measured
or changed. Pinned-upstream paths refer to the exact revisions in
[`RESEARCH.md`](RESEARCH.md).

| ID | Project-owned seam | Pinned-upstream or observed evidence | Closure test |
| --- | --- | --- | --- |
| TD-01 | `Support/RecompPrototype/recomp_game_start.cpp`; generated patch pair; new game-side timing patch | GoldenEye64Recomp `README.md` and `patches/workbench_theboy.c`; MGB64 `gun.c`, `chrlv.c`, and `fire_rate_authentic.*` | [`TESTING.md` native-60-Hz fire-rate gate](TESTING.md#native-60-hz-fire-rate-gate) plus hands-on combat acceptance |
| TD-02 | `Sources/RecompPrototypeInput.swift`; `patches/goldeneye64recomp-ios-modern-controls.patch` | Public issue #8 and GoldenEye movement/C-button semantics | [`TESTING.md` modern sidestep gate](TESTING.md#modern-sidestep-gate) |
| TD-03 | `CMakeLists.txt`; `Config/RecompPrototypeInfo.plist.in`; RT64/Plume build | Public issue #9 first-frame `AGXMetalA12` / `submitRasterScene` signature | [`TESTING.md` A12-family compatibility gate](TESTING.md#a12-family-compatibility-gate) |
| TD-04 | `Sources/RecompPrototypeApp.swift`; surface/audio lifecycle bridges | RT64 `rt64_present_queue.cpp`; Plume `plume_metal.cpp`; historical physical symptom | [`TESTING.md` lifecycle stall/freeze gate](TESTING.md#lifecycle-stallfreeze-gate) |
| TD-05 | `Sources/RecompPrototypeAudio.swift`; `Support/RecompPrototype/recomp_game_start.cpp` | Exact 22,050 Hz source chain; isolated synthetic ring/discontinuity evidence; physical static report | [`TESTING.md` audio discontinuity gate](TESTING.md#audio-discontinuity-gate) plus time-correlated physical listening |
| TD-06 | Preview 2 viewport/depth patch and isolated RT64 diagnostic branches | Zero uncalibrated depth-format counts, reverted fixed-order experiment, and physical video showing slight flicker | [`TESTING.md` residual flicker gate](TESTING.md#residual-flicker-gate) and continuous physical video |
| TD-07 | `Sources/RecompPrototypeInput.swift`; `Support/RecompPrototype/recomp_game_start.cpp` | Single `GCController.controllers().first` binding; diagnostic port flags; legacy slots are not connected | [`TESTING.md` controller ownership lifecycle gate](TESTING.md#controller-ownership-lifecycle-gate) plus physical 2–4 controller runs |
| TD-08 | `queueClampedAxis`; `recomp_get_camera_inputs`; `Sources/Mac/RecompMacInput.swift` | Fixed 3°/frame game-side look step and two source-confirmed clamps | Mac input/render gate in [`TESTING.md`](TESTING.md#native-macos-regression-gate) |
| TD-09 | `Sources/Mac/GoldenPadMacApp.swift` | Mobile one-point seam mask in `Sources/RecompPrototypeApp.swift`; observed Mac edge | Fixed-camera Dam/Surface before/after captures with no other pixel-region regression |
| TD-10 | Stage-specific game patches and RT64 effect support | Live water selection degrading through fog-fill replacement helpers; disabled full textured replacement; unreduced user reports | One deterministic stage/settings/camera/original-reference reproducer per claimed defect |
| TD-11 | No current implementation seam | Controller polling exists; serialization, rollback, handshake, transport, and state hashes do not | M0–M3 gates in [`MULTIPLAYER_ROADMAP.md`](MULTIPLAYER_ROADMAP.md#milestones-and-gates) |
| TD-12 | `Sources/RecompPrototypeROMStore.swift`; `Sources/RecompPrototypeMetalCanvas.swift`; librecomp `select_rom`; package verifiers | Protected Documents copy versus runtime-managed Application Support copy; current scan coverage | Attribute/readback gate in [`TESTING.md`](TESTING.md#converted-rom-storage-and-backup-gate) plus package audit |
| TD-13 | CMake private-input path; primary host/package verifiers | ROM-free host build proof and package-content audits do not prove provenance of the game-bearing executable | Two clean private-input builds with identical source/package digests |
| TD-14 | `Sources/RecompPrototypeApp.swift`; `Sources/RecompPrototypeInput.swift`; game-side input guard patch | External review R1/R2; default-mode mobile timer; current sheet presentation and guard set | Held-input modal/scroll/watch transition gate with neutral publication and no post-dismiss replay |

## Closure and change-control rules

A debt item is **closed** only when all applicable layers pass:

1. the root cause and ownership seam are recorded, not merely the symptom;
2. a focused automated or synthetic regression gate fails before the repair and
   passes afterward;
3. the relevant physical interaction, temporal video, audio listening, crash-
   hardware, or long-session acceptance gate passes;
4. the accepted single-player renderer, touch/controller P1, saves, settings,
   package, and private-data boundaries remain intact;
5. `STATUS.md`, this ledger, `TESTING.md`, and any public issue state agree; and
6. the repair can be reverted independently without removing an unrelated fix.

A documented support-floor decision may close a hardware-compatibility item
without a code repair only when the minimum is deliberate, tested, and stated in
the README, package metadata, and issue. “Could not reproduce” does not close a
deterministic public report.

Use one debt ID per implementation branch or review unit wherever practical.
Do not combine game-timing changes, input semantics, controller ownership,
renderer state, audio lifecycle, and networking in one candidate. If two items
must touch the same generated patch pair, land and reaccept the first before
regenerating for the second.

## Execution order

Preview 7 shipped as a compatibility-only promotion after production iPadOS and
Mac acceptance. Its hosted artifacts match the accepted local files byte for
byte. The affected issue #19 iPhone 13 mini passed the exact iOS 17-target
diagnostic artifact; production-release reporter confirmation remains open.
Preview 7 retains Preview 6's accepted controls and Preview 5's exact expected
12 Phantom events per 100 ticks. Its byte-identical Mac payload retains known
horizontal mouse sluggishness without introducing a Preview 7 regression.

Preview 8 adds only the default-off duplicate touch Fire control. Focused tests
prove that primary and secondary touches publish one N64 Z state and that
releasing either source does not cancel or latch the other. Its in-place iPad
installation preserved the ROM and preferences, and the user accepted the
feature in gameplay. Renderer flicker, controller ownership, lifecycle, audio,
storage, and compatibility debt remain separate.

The next landing sequence is:

1. obtain issue #19 production-artifact confirmation for the published Preview
   7 release;
2. close TD-14 modal/run-loop neutralization and TD-07 controller collapse as
   separate input-lifecycle units;
3. run the physical audio/lifecycle/flicker evidence gates and add only the
   counters selected by those observations;
4. act on A12X issue #9 with the corrected target, then a bounded Tier-1 repair
   or tested support-floor decision if the first-draw crash remains;
5. keep the accepted TD-08 Mac input repair frozen and take only a justified
   TD-09 edge repair;
6. close TD-12 storage hygiene and TD-13 build-proof gaps independently; and
7. implement stable real multi-controller ownership before any network layer.

Do not begin peer discovery, matchmaking, relay, or rollback work while TD-07
is open. A transport demo would not prove multiplayer feasibility and would
create a second unfinished ownership system.

## Preview 3 Mac input release — 2026-08-22

Preview 3 changes input only; it retains the accepted RT64/Plume sizing and
the known thin far-right blue edge. The matched MIPS patch compiles and
regenerates, the native arm64 app links all request/consumer symbols, and the
ROM-free 20-member release archive passes the Mac package audit. The user has
accepted the preceding mouse/WASD direction as the best Mac pass so far, then
declared the exact C/R/Escape/Delete/mouse-wheel/number-key follow-up stable and
working. This accepts the second Mac control build for Preview 3; it does not
close TD-09.

The exact accepted executable SHA-256 is
`a6352c5179ff5822f4af3d1b20e1b02bf0d5d1af46b453c9bceca435b7e59808`.
The audited Preview 3 archive SHA-256 is
`819bc8eabc1fc84d2a37c1847f68c8832c023f0b0643851ca3f6251244fc32ba`,
with sorted app-content SHA-256
`e15c17528a72881e3062504c2abc82a0a57bf0d039feb8240cbaf03b5db4f941`.

The current desktop contract is left mouse Fire, right mouse Action, middle
click or wheel weapon cycling, Shift Aim, E Action, Q next weapon, R reload, C
crouch, Space unassigned, and 1–9/0 owned inventory slots. Escape sends
Start/Pause without releasing pointer capture; Delete releases capture without
sending a game button. Shift aim is stationary because Honey otherwise
reinterprets W/S as manual-aim pitch. Crouch reads and adjusts GoldenEye's live
stance; direct inventory selection follows the same native functions used by
the watch menu. Unknown or unavailable slots are ignored.

The corresponding iPad release is version `0.1.0` build `3`. It was installed
in place and launched on the attached iPad Pro without changing the bundle
identifier. Pre/post readbacks produced identical hashes for the Documents ROM,
runtime ROM, active save, backup save, and preferences. Current and previous
build-3 logs additionally show successful ROM validation, an active GoldenEye
loop, stage transitions, continued render/present progress, and nonzero audio.
The user accepted Preview 3 as stable for publication with no newly observed
major regression. TD-02 remains open for issue-reporter confirmation and the
full modern-sidestep regression matrix; the adapter therefore remains opt-in.
The final copy-only signed device executable SHA-256 is
`6ad969b56b6358e8c2731f97063b3d0dccf28674fdb4939216a289a330d8a72e`.

## macOS alpha disposition — 2026-08-21

The native Apple-Silicon Mac product remains **Alpha**, one support tier below
the accepted iPhone/iPad single-player experience. Preview 3's current artifact
is an arm64 `GoldenPad.app` whose product, bundle display name and executable are
all `GoldenPad`. Its accepted executable SHA-256 is
`a6352c5179ff5822f4af3d1b20e1b02bf0d5d1af46b453c9bceca435b7e59808`.
Hands-on review found its keyboard/mouse controls stable and working. That is
Preview 3 Alpha acceptance, not notarization, broad hardware coverage, or a
sustained-performance proof.

The remaining Mac alpha debt is explicit:

- a thin blue strip remains at the far-right render edge and was reconfirmed in
  the accepted Preview 3 Mac controls build;
- prior Mac iterations staggered or froze under load, so broader hardware and
  sustained-gameplay coverage is still required even though the accepted build
  was stable during hands-on review;
- direct numeric inventory selection is accepted in Preview 3; Mac multiplayer
  assignment is not implemented; and
- the separate arm64 Alpha archive is package-audited, while
  oldest-supported-OS testing and notarization remain future gates.

Freeze the accepted renderer/input boundary for the coordinated release. Do not
try to remove the thin blue edge by changing RT64's window-size contract, and do
not rewrite camera/player fields to make mouse input feel more desktop-like.
Those experiments caused much worse world-geometry and control regressions. A
later Mac-only repair must reproduce the thin edge, preserve Dam/Surface scene
geometry, and pass the full input/render gate before replacing this baseline.

Preview 3 is one coordinated source baseline, not one cross-platform binary.
iPhone and iPad ship in an `.ipa`; macOS ships as a separate arm64 Alpha archive
containing `GoldenPad.app`. Mobile multiplayer remains experimental despite the
accepted render baseline because residual flicker and real Player 3/4 routing
remain open.

### Rejected macOS camera/input regressions

A failed native Mac iteration attempted to suppress GoldenEye's automatic
look-ahead by writing player camera fields directly while the mouse was
captured. Hands-on testing rejected that build. Subsequent isolation found two
independent regressions: the generated recompiler patch pair no longer
contained the game-side camera and crouch bridge calls, and a Plume experiment
that substituted
`CAMetalLayer.drawableSize` for the swap chain's window size changed RT64's
viewport contract. The latter expanded the former thin blue edge into large
blue, missing, and duplicated room/background regions. Menu mouse Y was also
reversed, and the enabled unlock-all-missions option did not expose later
missions.

That direct player-structure approach is prohibited from returning. Modern Mac
mouse work must remain inside the accepted Metal-view input boundary and the
existing camera-input patch; it must not write undocumented player/camera
fields. The retained 21:16:44 `GoldenPadMac` executable is the hands-on control:
mouse look and Crouch worked there. The generated `patches.c` and
`patches_bin.c` were then replaced at 21:16:53 and 21:17:12 without the modern
controls patch, so every later executable had host producers but no game-side
consumer. Active Dam stage 33 with queued look `(0,0)` was therefore not proof
of an AppKit event-delivery defect.

Future regeneration must apply
`patches/goldeneye64recomp-ios-modern-controls.patch` first and regenerate both
halves of the embedded patch together. Before linking, verify generated
`RecompiledPatches/patches.c` calls `recomp_get_camera_inputs` plus the crouch,
reload, and inventory consumers. Treat any missing call as a failed build. Do
not replace the accepted view callbacks with an app-local event
monitor to compensate for a missing game patch. Plume's swap-chain window-size
query must likewise remain the
accepted baseline until a separate, Mac-only edge fix passes scene comparisons;
using the Metal drawable size there is a recorded rejected approach. The
mission toggle must drive GoldenEye's retail debug-unlock global without
modifying EEPROM or fabricating completion records.

Any Mac input candidate must be rejected if Dam/Surface geometry differs from
the last accepted RT64 rendering, captured mouse movement fails in either axis,
menu pointer directions disagree with WASD, crouching changes camera pitch on
its own, or unlock-all-missions changes the toggle without changing mission
availability. A successful build and live PID are not acceptance for these
interaction and rendering gates. Direct numeric weapon selection remains open
for acceptance, but it now has a game-side contract: the request is consumed
only in active gameplay, bounds-checks the live inventory count, resolves the
owned item through GoldenEye's inventory index, and invokes the same equip
functions used by the watch menu.

The retained 21:16:44 executable later froze during extended hands-on use, so
it is a comparison control, not a release fallback. A rebuilt candidate using
the later multiplayer viewport patch also staggered and accumulated 46,323
audio-underrun frames across 396 callbacks; the same host audio renderer in the
retained control initially reported zero underruns. The Mac single-player
candidate therefore isolates the compact 349-function patch set from the
356-function multiplayer-derived set. That isolation must pass gameplay,
audio, and freeze gates before it becomes the reproducible Mac configuration.

The first compact candidate still became staggered and effectively
uncontrollable. Its bounded log showed that rendering and audio initially
progressed, while an earlier session later collapsed to only a few VI updates
per interval and began accumulating underruns. QuickTime was not running when
the process state was checked, so capture load may worsen the symptom but is
not an adequate root-cause explanation. Source isolation found that Plume's
background render thread requested both window attributes and refresh rate on
every presentation, and each request enqueued a new AppKit main-queue block.
That queue is also responsible for keyboard, mouse, and host timers. The Mac
dependency build now applies
`patches/plume-macos-main-queue-coalescing.patch`, which permits at most one
pending update of each kind. Do not remove that bound or reintroduce an
unbounded per-frame dispatch to the main queue.

## Local multiplayer debt and sequencing

Preview 2 has shipped with a stable experimental split-screen render baseline;
local multiplayer is no longer a Preview 2 publication blocker. It is still not
a fully supported feature. Source tracing found full-frame render-target, sky,
scissor, fade and depth-clear assumptions in the GoldenEye64Recomp patches even
though GoldenEye renders each player sequentially into a shared framebuffer.
The accepted viewport/depth repair must remain frozen while the remaining
flicker and controller-ownership work proceed independently.

The first physical viewport-scoping candidate did not remove the temporal
corruption. A bounded iPad recording showed the black/checkerboard region
recovering and migrating between lower player views while presentation and all
four player passes continued. The accepted follow-up targeted a deeper
N64-to-RT64 ownership mismatch: GoldenEye shifts the lower players' depth-image
base by one logical screen and relies on address/Y aliasing, whereas RT64's
fill-only depth-clear fast path requires the clear address to exactly equal the
following depth-image address. The repair clears lower players through that same
shifted address and their original viewport Y range. Physical four-player video
established the bounded baseline; Simulator-only stability did not.

The physical four-player retest of executable SHA-256
`0976dcdfd17de60beda8e8e60ccff3fc81da7da0b2ef43f159cdea061149677d`
removed the former large black/checkerboard corruption and establishes the
stable experimental Preview 2 baseline. Slight lighting flicker remains as a
separate, lower-severity debt item. Preserve this exact build and do not reopen
the successful depth-alias repair speculatively unless the large corruption
returns or a bounded lighting-state defect is identified.

The four-port neutral render diagnostic now exists on iOS/iPadOS, but the
primary host still binds only one real controller. Physical testing with real
three/four-controller routing and a macOS assignment policy therefore remain
open. Multiplayer LOD/effects restoration and network research are specified in
[`MULTIPLAYER_ROADMAP.md`](MULTIPLAYER_ROADMAP.md). They must not be bundled into
controller ownership or flicker work. In particular, do not assume RT64's higher
output resolution removes GoldenEye's fixed stage, effect, vertex or display-list
budgets, and do not load single-player gameplay objects into multiplayer under a
visual-quality label.

## Historical decomp/MGB64 watch

The matching GoldenEye decompilation reached **100%** at
[`c73a8531e05a7584dc857405d5b91fe9bc95f9e3`](https://gitlab.com/kholdfuzion/goldeneye_src/-/commit/c73a8531e05a7584dc857405d5b91fe9bc95f9e3)
on 2026-08-16. The final source is now public and auditable, which makes it an
authoritative reference for replacing guessed or nonmatching game-code behavior.
It does **not** make the raw decompilation a replacement for MGB64: the decomp
reconstructs the N64 game, while MGB64 supplies the native renderer, ROM loader,
audio, input, save, portability, and platform layers that GoldenPad integrates.

The legacy-watch sequencing remains:

1. preserve the current known `GoldenPad Legacy` baseline;
2. use the final decomp as a targeted oracle for known MGB64 divergences;
3. watch for and evaluate the next public MGB64 engine/source update;
4. rebase GoldenPad only after texture, performance, build, legal, and package
   evidence is better than the current pin.

Do not bulk-import new decomp/MGB64 changes, rewrite Fast3D/TMEM, or modify the
primary RT64 runtime solely because an upstream matching percentage changes.

## 2026-08-17 upstream snapshot

The completed [`goldeneye_src`](https://gitlab.com/kholdfuzion/goldeneye_src)
repository resolves to:

| Surface | Audited result |
| --- | --- |
| Final commit | `c73a8531e05a7584dc857405d5b91fe9bc95f9e3` (`for england james?`) |
| Final commit date | 2026-08-16 |
| Final commit size | 340 files changed; 152 source files; 125 `src/game` files |
| `NONMATCHING` guards in `src/game` | 273 before the final commit; 0 after |
| Remaining `GLOBAL_ASM` references in `src/game` | 62, observed in data/section declarations rather than undecompiled gameplay-function bodies |

The repository still contains MIPS assembly units and an N64-target build. In
this context, 100% means that the matching-decompilation project is complete; it
does not mean portable ISO C, an iOS app, or a ready static-recompilation input.
The repository also has no top-level license file. Public readability and a
matching result do not place Rare/Nintendo code or game assets in the public
domain, so GoldenPad must preserve its existing provenance review and
bring-your-own-ROM boundary.

The public [MGB64 repository](https://github.com/akratch/mgb64) still resolved
to GoldenPad's current `cd9b58f` pin during this review. GoldenPad is not behind
an available public MGB64 commit today. Its only other public branch and open
pull request concern app icon/signing work, not the completed decomp or renderer.
The public [GoldenRecomp repository](https://github.com/kholdfuzion/GoldenRecomp)
also remains at `f31b5d1e214f57c9ddb3dc598daa688bccffdd4f`, with no open pull request
or published TLB-free/input-metadata completion. Its `lib/ge` submodule still
points to an unavailable GitHub source revision, so it is not a faster
reproducible foundation today. GoldenEye Depot's
[site](https://goldeneyedepot.com/) and [X account](https://x.com/goldeneyedepot)
remain announcement sources; the live tracker and exact repository commits are
the technical evidence.

## What the decomp progress can improve

Decompilation progress can improve game logic and code-coupled data that choose
textures, calculate texture coordinates, configure tile/TMEM state, or emit N64
display-list commands. It does not replace the texture pixels and palettes that
GoldenPad loads from the user's ROM.

The current MGB64 pin already records three direct candidates for comparison
against the newer decomp:

| Ledger item | Current divergence | Why GoldenPad should retest it |
| --- | --- | --- |
| `FID-0104` | `texWriteLoadToTmemAddr` is a nonmatching native rewrite with pipe-sync, fast-path, format, and tile-number differences from the now-exact retail function. | It is reached on non-TLUT texture loads and could change emitted texture state. |
| `FID-0119` | `bgTestBulletHitBackground` returns `-1` texture coordinates instead of performing the retail backward display-list scan. | It can affect surface/material identification for bullet impacts. |
| `FID-0071` | The object-hit texture scan treats a display-list boundary differently from retail. | It can select a different impact material, sound, or decal. |

The exact `FID-0104` function was applied to a temporary copy of the current
MGB64 pin. The full native executable compiled and linked, and the targeted
texture/renderer tests passed. Private deterministic native-Metal captures at
frame 70 were then byte-identical to the current implementation on Dam,
Facility, Surface 1, Archives, and Cradle. This proves that it is a clean
ABI-compatible comparison candidate, but supplies no evidence that importing it
fixes GoldenPad's current visible rendering problems. Do not promote it without
a reproducer that makes the two implementations diverge.

`FID-0119` is not a drop-in source replacement: the exact retail function scans
backward from a display-list command pointer that MGB64's native collision path
does not currently preserve. `FID-0071` has a small exact boundary-semantic
difference, but both items primarily affect bullet-impact material, sound, or
decal selection rather than large world-texture rendering. Keep them as scoped
follow-up work instead of release blockers.

These are comparison targets, not proof that they cause every visible texture
problem. Any change must be re-derived from the final source and verified in a
scene where behavior changes.

## Rendering decision from the 100% review

The reported Dam edge/cliff problem remains a filtering issue in the current
MGB64 evidence, not a missing decompiled function. MGB64's anisotropic-filtering
fix is WebGPU-only: the shared renderer deliberately keeps native Metal on the
nearest-sampler plus in-shader N64 three-point path to avoid double filtering.
GoldenPad's `g_pcTextureAnisotropy = 16` therefore does not activate the same
WebGPU fix on iOS.

A private Metal A/B at the documented Dam viewpoint compared the current path
with `GE007_DISABLE_N64_FILTER=1`. Disabling the N64 shader filter changed
137,458 of the 307,200 capture pixels (normalized RMSE 0.0161) and visibly made
the road and cliff softer/smeared. Do not make this diagnostic flag a GoldenPad
default. If the grazing-angle artifact remains release-blocking, the correct
next experiment is a scoped Metal minification/aniso policy with explicit
masked/wrapped-texture seam tests, not a global filter replacement.

The Dam door-indicator corruption remains covered by MGB64's existing native
display-list collision-pointer-table repair. The completed decomp does not
replace that native 64-bit pointer fix.

## What the decomp progress will not fix automatically

MGB64's renderer and GoldenPad's mobile integration remain separate sources of
visual and performance debt. The newer decomp will not by itself resolve:

- texture-cache identity keyed too narrowly for format, size, or palette state;
- backend filtering, coverage-alpha, alpha-dither, decal-bias, or TLUT handling;
- textured prop bullet impacts corrupting world texture state;
- room scissoring, sky fallback, or the remaining menu-material brightness
  difference;
- Metal texture allocation and upload behavior in GoldenPad; or
- iOS-only lifecycle, memory, drawable, and physical-device performance issues.

The measured GoldenPad performance result is especially important here. The
three-frame texture recycler reduced warm Simulator samples reaching
`newTextureWithDescriptor` from 811 of 3,217 to 76 of 3,662. The remaining
Simulator-heavy path was XPC-backed texture upload. A decomp percentage does not
make that Metal transfer cheaper. A new MGB64 engine may reduce texture churn or
invalidations, but that must be measured on a physical device rather than
assumed from Simulator behavior.

## Foundation watch matrix

Update this table only when a concrete trigger occurs. Record an exact commit,
tag, or public artifact rather than a social percentage alone.

| Foundation | GoldenPad use | Watch for | Adoption rule |
| --- | --- | --- | --- |
| [akratch/mgb64](https://github.com/akratch/mgb64) | `GoldenPad Legacy` core/renderer and source-level behavior oracle | New commits/releases; decomp imports; renderer, texture-cache, audio, timing, or portability changes | Evaluate only for Legacy or a traced primary-runtime defect. Update the Legacy pin only after all gates pass. |
| [goldeneye_src](https://gitlab.com/kholdfuzion/goldeneye_src) and [status tracker](https://kholdfuzion.github.io/goldeneyestatus/) | Exact game-code/parity reference feeding MGB64 | Post-completion corrections and changes touching known fidelity items | Use as a targeted oracle; preserve provenance and never bulk-import it. |
| [n64decomp/007](https://github.com/n64decomp/007) | Public decomp reference | Mirror synchronization and relevant source history | Reference only; preserve provenance and license review. |
| [GoldenEye64Recomp](https://github.com/cblock85/GoldenEye64Recomp) | Primary game-patch/configuration lineage | Game fixes, timing fidelity, sky/water, multiplayer, and reproducible generated-input improvements | Rebase only with a matched patch-generation/build/device campaign. |
| [GoldenRecomp](https://github.com/kholdfuzion/GoldenRecomp) | Separate static-recomp architecture reference | Public TLB-free ELF/ROM recipe, generated functions, or complete metadata | Compare only when its clean public pipeline is reproducible. |
| [N64Recomp](https://github.com/N64Recomp/N64Recomp) and [N64ModernRuntime](https://github.com/N64Recomp/N64ModernRuntime) | Active primary translator/runtime dependency set | AOT portability, metadata, controller/audio/timing, lifecycle, and serialization improvements | Update only as one matched runtime/generated-input set with every primary verifier. |
| [RT64](https://github.com/rt64/rt64) and its Plume backend | Active primary renderer | Apple Metal, framebuffer, presentation, texture, shader, and lifecycle fixes | Evaluate against the exact pinned behavior; preserve the accepted viewport/window contracts. |

Concrete review triggers are:

- a new MGB64 commit, tag, release, or published engine branch;
- a post-completion decomp correction touching a known divergence;
- an upstream change touching `FID-0104`, `FID-0119`, `FID-0071`, texture cache,
  Fast3D, Metal, display-list state, or texture uploads;
- a reproducible GoldenRecomp TLB-free input/metadata pipeline; or
- a material RT64/Plume iOS Metal change that addresses a measured blocker.

## Upgrade gate for a new MGB64 revision

When a trigger lands:

1. Record the upstream URL, exact SHA/tag, date, license/provenance changes, and
   release notes. Confirm the source is public and auditable.
2. Check out the candidate under `ref/`. Do not change GoldenPad's production
   pin yet.
3. Apply GoldenPad's MGB64 patches with `git apply --check`, then rebase each
   conflict deliberately. Do not bulk-copy the candidate tree.
4. Compare the same scenes on current desktop MGB64, candidate desktop MGB64,
   GoldenPad, and a stock reference: Dam cliff/shore/intro, Cradle, Surface,
   menu/briefing materials, glass, and bullet decals.
5. Classify the result before fixing anything:
   - fixed in candidate desktop MGB64: adopt or rebase the upstream fix;
   - broken in candidate desktop MGB64 and GoldenPad: upstream renderer/core
     issue;
   - correct on candidate desktop MGB64 but broken only on iOS: GoldenPad
     Metal/mobile integration issue;
   - visually correct but slow only on iOS: physical-device profiling issue.
6. Recheck `FID-0104`, `FID-0119`, and `FID-0071` against the new source and
   capture scene evidence for any behavior change.
7. Run the maintained Simulator and ARM64 device builds, ROM/data contamination
   checks, source-license manifest, package audit, and upstream-cleanliness
   checks. Keep cold/warm and Simulator/physical performance results separate.
8. Promote the new pin only when the candidate produces no new texture
   corruption, preserves saves and private data boundaries, and improves or
   matches the current baseline.

## Legacy upstream-watch actions

- Watch for a public MGB64 engine update; there is no new Legacy pin to adopt
  in the 2026-08-17 snapshot.
- Preserve the repeatable private native-Metal comparison route used for Dam,
  Facility, Surface 1, Archives, and Cradle; add the exact user-reported scene
  before changing renderer policy.
- Keep `FID-0104` unmodified until a visual or command-stream divergence is
  reproduced. Investigate `FID-0119` and `FID-0071` only in bullet-impact tests.
- If the Dam grazing-angle artifact is release-blocking, prototype scoped Metal
  anisotropy/minification and test masked/wrapped textures; do not globally
  disable the N64 shader filter.
- Keep renderer defects and mobile upload performance in their own evidence
  lanes; do not label them "fixed by decomp" without a measured result.
- Refresh this ledger when a concrete trigger lands, not for every percentage
  tick on the live tracker.
