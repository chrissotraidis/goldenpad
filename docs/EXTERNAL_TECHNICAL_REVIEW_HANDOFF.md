# External technical review handoff

Status: the independent revision-2 response is preserved with its maintained
disposition in [`EXTERNAL_REVIEW_2026-08-22.md`](EXTERNAL_REVIEW_2026-08-22.md)
and reconciled into [`TECH_DEBT.md`](TECH_DEBT.md), [`ARCHITECTURE.md`](ARCHITECTURE.md),
[`MULTIPLAYER_ROADMAP.md`](MULTIPLAYER_ROADMAP.md), and
[`TESTING.md`](TESTING.md). [`STATUS.md`](STATUS.md) and [`PLAN.md`](PLAN.md) own
the current truth and execution order. This file remains a reproducible review
prompt, not the authoritative current defect ledger.

Copy this document into the reviewing model's prompt. Give the model read-only
access to the GoldenPad repository if possible.

---

## Prompt for the reviewing model

You are an external senior graphics/runtime engineer performing a read-only,
evidence-first technical review of GoldenPad. Your job is to investigate the
hardest remaining defects, rank plausible causes, and recommend the smallest
useful next experiments. You are not being asked to implement fixes.

Repository:

```text
/Users/chrissotraidis/GitHub/goldenpad
```

Public release baseline:

```text
v0.1.0-preview.3
```

Begin by recording the branch, exact commit, worktree status, and release tag
you inspected. Read the repository's current documentation and source before
drawing conclusions. If local state differs from the release tag, identify that
difference and say which state supports each claim.

### Objective

Produce a technical assessment of the unresolved issues below. For each issue:

1. distinguish confirmed facts, reasonable inferences, and unknowns;
2. identify the exact source/patch/runtime ownership boundary involved;
3. rank competing root-cause hypotheses with calibrated confidence;
4. name evidence supporting and contradicting each hypothesis;
5. propose the cheapest discriminating test or instrumentation change;
6. identify the smallest likely repair seam, without writing the repair;
7. estimate the likelihood that the proposed repair would solve the symptom;
8. describe regression risks and the baseline that must be preserved; and
9. explicitly say **unknown** when the repository does not contain enough
   evidence.

Do not treat build success, a live process, Simulator behavior, log counters, or
a clean screenshot as physical interaction acceptance. Temporal rendering faults
require video or continuous frame evidence. Audio counters do not by themselves
prove the absence of audible static.

### Product and data boundary

GoldenPad is an unofficial, source-available developer preview. The primary
iPhone/iPad runtime uses statically recompiled GoldenEye code,
N64ModernRuntime, RT64 and Metal. Apple-Silicon macOS support is Alpha. The
legacy MGB64/Fast3D target is a comparison/fallback path, not the primary
release runtime.

Never request, copy, expose, summarize, or commit a retail ROM, extracted game
assets, saves, signing material, private generated AOT sources, private paths,
or user identifiers. Do not infer missing proprietary source. Public
documentation, tracked patches, project-owned host code, public upstream source,
and sanitized runtime evidence are in scope.

### Stable baseline that must not be destabilized

Preview 3 was accepted for iPhone/iPad and Apple-Silicon Mac use. It retains
Preview 2's accepted single-player foundation while adding the documented
control changes. The following behavior is a regression boundary:

- normal-speed single-player gameplay;
- high-resolution RT64/Metal rendering;
- accepted touch movement/look/buttons and editable phone/tablet layouts;
- Xbox/MFi Player 1 controls and automatic touch-overlay hiding;
- existing saves, settings, clean-install defaults and user-supplied-ROM flow;
- the current multiplayer depth-alias repair, which removed the former large
  black/checkerboard split-screen corruption on physical iPad; and
- the retained Mac Alpha renderer/input contract, even though it still has
  disclosed shortcomings.

Do not recommend a broad renderer rewrite, direct writes to undocumented player
or camera structures, replacing RT64's window-size contract with raw Metal
drawable size, unbounded per-frame dispatch to AppKit's main queue, or
regenerating only one half of the embedded recompiler patch. Those approaches
already produced worse regressions.

## Problems to investigate

### 1. Residual multiplayer lighting flicker

Current status:

- The former large black/checkerboard corruption is repaired in the frozen
  Preview 2 baseline.
- Four physical views remained coherent across 3,336 consecutive frame
  comparisons and 54,652 presented VI updates, with zero reported audio drops
  or underruns in that run.
- Slight lighting flicker still occurs. It has not yet been isolated to a
  particular player, room, transition, display-list state, or render pass.
- GoldenEye renders players sequentially into a shared framebuffer and shuffles
  player render order. Full-frame or leaked render state can therefore produce
  temporal faults that move between views.

Inspect first:

- `docs/MULTIPLAYER_ROADMAP.md`
- `docs/TECH_DEBT.md`, especially **Local multiplayer debt and sequencing**
- `docs/TESTING.md`, especially the focused physical multiplayer gate
- `patches/goldeneye64recomp-ios-prototype-render-trace.patch`
- `CMakeLists.txt` checks for the generated Preview 2 patch markers
- tracked RT64/Plume integration patches and the RT64 surface bridge

Questions to answer:

- Is the remaining flicker more consistent with viewport/scissor leakage,
  color/depth-image ownership, fog/environment state, lighting state, a
  framebuffer dependency, stale per-player GPU state, or original GoldenEye
  multiplayer behavior?
- Which state transitions can cross player boundaries even after sky, fade,
  background and depth clears are viewport-scoped?
- Can randomized player render order be used as a causal probe rather than
  merely an observation?
- What minimal per-player trace would distinguish a game-side display-list
  state leak from an RT64 render-target/framebuffer interpretation problem?
- What evidence would justify touching the successful depth-address alias
  repair? The default answer should be **do not touch it**.

### 2. Real three/four-controller routing and lifecycle

Current status:

- The four-port neutral render diagnostic works and keeps Players 3/4 neutral.
- Controller Player 1 and touch Player 2 have demonstrated independent input.
- Real Player 3/4 controller assignment, disconnect/reconnect, foreground
  recovery and sustained physical play remain unaccepted.
- macOS has no touch path and therefore needs a different assignment policy.

Inspect first:

- `Sources/InputSystem.swift`, especially `ControllerAssignment`,
  `MultiplayerInputOwnership`, controller slots, `snapshot(player:)`,
  `moveController`, and `publishToCore`
- `Sources/RecompPrototypeInput.swift`
- `Sources/TouchControlsView.swift`
- `Sources/Mac/RecompMacInput.swift`
- `Support/RecompPrototype/recomp_game_start.cpp`
- `docs/MULTIPLAYER_ROADMAP.md`

Questions to answer:

- Does the slot model preserve stable player ownership when controllers connect,
  disconnect, sleep, reconnect, or the app returns to the foreground?
- Are `GCController.playerIndex`, array position, connected-port publication and
  the game's expected N64 port numbering always consistent?
- Can touch/controller merging leak touch buttons or look into a non-touch
  player under any reassignment?
- Is the experimental two-player mode masking a production ownership problem?
- What is the smallest deterministic, synthetic controller-lifecycle test that
  would expose stale handles, slot collapse, duplicate ownership or held input?
- What separate policy should macOS use when two to four physical controllers
  are present?

### 3. Screenshot, system-overlay and foreground resume freezes

Current status:

- Gameplay has previously frozen after taking a screenshot or leaving and
  returning to the app.
- iOS can become `.inactive` briefly for a screenshot/system overlay without
  entering `.background`.
- Suspending RT64 during that transient state can strand an in-flight drawable
  acquisition. The current app intentionally treats inactive and background
  states differently.
- The issue has not received a complete, repeatable physical lifecycle matrix.

Inspect first:

- `Sources/RecompPrototypeApp.swift`, especially scene-phase handling
- `Sources/RecompPrototypeMetalCanvas.swift`
- `Sources/RecompPrototypeAudio.swift`
- `Support/RecompPrototype/recomp_game_start.cpp`, especially app-active,
  foreground audio discard/fade and diagnostic-session handling
- lifecycle changes in
  `patches/goldeneye64recomp-ios-prototype-render-trace.patch`
- `docs/TESTING.md` lifecycle acceptance steps

Questions to answer:

- Which thread or wait can remain blocked if a drawable disappears during
  `.inactive`, `.background`, or foreground recovery?
- Are renderer pause, game simulation pause, audio ring reset and UI scene state
  ordered consistently?
- Could the apparent freeze instead be an input publication stall, audio/main
  queue starvation, or a presentation-only stall while simulation continues?
- What bounded counters/breadcrumbs would distinguish those cases without
  continuous logging that changes performance?
- What exact physical event sequence is the minimum reliable reproducer?

### 4. Audible audio static

Current status:

- Users have intermittently heard static even when audio is mostly correct.
- The host uses a bounded stereo ring feeding `AVAudioEngine`.
- Some accepted runs reported zero dropped/underrun frames; that does not rule
  out format, discontinuity, route-change, fade, conversion or thread-timing
  defects.
- Heavy Mac regressions have produced large underrun counts, but mobile static
  has not been proven to share that cause.

Inspect first:

- `Sources/RecompPrototypeAudio.swift`
- `Sources/Mac/RecompMacAudio.swift`
- audio producer/ring/statistics code in
  `Support/RecompPrototype/recomp_game_start.cpp`
- lifecycle/audio evidence in `docs/TESTING.md` and `docs/TECH_DEBT.md`

Questions to answer:

- Are producer and consumer sample rates, channel layout, frame counts and
  buffer lifetimes identical across every route?
- Can ring wrap, stale frames after foregrounding, priming/fade transitions,
  integer-to-float conversion, or partial buffer delivery create a click/static
  without incrementing underrun counters?
- Could logging, recording or main-thread load explain only some reports?
- What low-overhead capture or synthetic signal test would identify the first
  discontinuity without recording copyrighted game audio?
- Which fix would be safe for both mobile and Mac, and which should remain
  platform-specific?

### 5. Stage-specific geometry faults and the thin blue render edge

Current status:

- Intermittent stage-specific clipping, missing geometry or blue regions have
  been observed, but many reports are not yet reduced to deterministic camera
  positions and settings.
- A thin blue strip remains at the far-right edge of the Mac Alpha.
- Replacing RT64's window-size contract with `CAMetalLayer.drawableSize`
  expanded that thin strip into severe missing, duplicated and blue world
  geometry. That experiment was rejected.
- Input-only changes must not alter Dam/Surface scene geometry.

Inspect first:

- `docs/TECH_DEBT.md`, especially **macOS alpha disposition** and rejected Mac
  regressions
- `Sources/Mac/RecompMacMetalCanvas.swift`
- `Sources/RecompPrototypeMetalCanvas.swift`
- RT64/Plume window and surface bridges under `Support/RecompPrototype/`
- tracked RT64 and Plume patches
- resolution, MSAA and three-point-filtering settings paths

Questions to answer:

- Is the one-pixel edge more likely a host-view coverage issue, rounding/scaling
  mismatch, viewport/scissor convention, presentation crop, or game clear color?
- Can the edge be masked or corrected at the final presentation boundary
  without changing RT64's internal window-size contract?
- Which geometry symptoms are likely the same defect and which are probably
  original culling/portal or incomplete-renderer behavior?
- What deterministic screenshot/video checkpoints and settings matrix would
  make this issue diagnosable?

### 6. Mac Alpha input feel and sustained performance

Current status:

- Preview 3 keyboard/mouse controls received hands-on acceptance with WASD,
  relative mouse look, mouse buttons, C/R/Escape/Delete, wheel cycling and
  numeric inventory selection working as documented.
- Earlier direct camera writes, mismatched generated patches and app-local event
  monitoring were rejected.
- Unbounded render-thread requests enqueued onto AppKit's main queue caused
  growing input latency, audio underruns and effective freezes. The retained
  Plume patch coalesces those requests.
- The thin far-right blue edge and broader sustained-gameplay coverage remain
  open; Mac multiplayer assignment is not implemented.

Inspect first:

- `Sources/Mac/RecompMacInput.swift`
- `Sources/Mac/RecompMacMetalCanvas.swift`
- `Sources/Mac/GoldenPadMacApp.swift`
- `patches/goldeneye64recomp-ios-modern-controls.patch`
- `patches/plume-macos-main-queue-coalescing.patch`
- Mac sections of `docs/TECH_DEBT.md` and `docs/TESTING.md`

Questions to answer:

- Do the retained queue/consumer clamps create measurable loss or frame-rate
  coupling outside the accepted hands-on scenarios?
- What measurement separates event delivery latency from camera response gain?
- Can any future tuning remain solely at the accepted relative-delta seam?
- Does the coalescing patch bound every relevant main-queue request, and how can
  queue growth be verified with low observer effect?
- What is the minimum sustained acceptance run for promoting this Alpha without
  claiming mobile parity?

### 7. Secondary completeness gaps

Assess these after the six issues above, without allowing them to distract from
the primary defects:

- first-install ROM importer coverage on both phone and tablet, including wrong
  revision, cancellation, interruption and low storage;
- clean shutdown and session-marker semantics;
- six disclosed anonymous compiler `/private/tmp/goldenpad-recomp.*` literals;
- direct numeric weapon selection on Mac;
- oldest-supported macOS testing and notarization; and
- the private generated-AOT pipeline's effect on public reproducibility.

For each, say whether it is a product defect, release-hardening item,
reproducibility limitation, or policy/distribution task.

## Required research method

1. Read, at minimum:
   - `README.md`
   - `docs/STATUS.md`
   - `docs/TESTING.md`
   - `docs/TECH_DEBT.md`
   - `docs/MULTIPLAYER_ROADMAP.md`
   - `docs/PREVIEW_2_ROM_IMPORT.md`
   - `docs/RT64_N64RECOMP_PROTOTYPE.md`
   - `docs/RELEASE_NOTES_0.1.0-preview.2.md`
2. Trace every important claim into tracked source or patches. Cite
   `path:line` ranges.
3. If you browse upstream, use primary repositories, source, issues or official
   documentation. Record exact URLs and commits. Do not rely on generic search
   summaries or assume current upstream behavior matches GoldenPad's pins.
4. Prefer a test that makes two hypotheses predict different results. Avoid
   “add more logging” unless you specify the exact counter/event, sampling
   cadence, ownership and expected outcomes.
5. Preserve the distinction between iPhone/iPad device evidence, Simulator
   evidence and Mac evidence.
6. Do not modify files, build, deploy, attach a profiler, start continuous log
   streaming, or run the game unless separately authorized. This task ends with
   a report.

## Confidence scale

Use both a label and percentage:

- **Confirmed (95–100%)**: directly demonstrated by source plus reproduced
  evidence, or logically entailed by the inspected code.
- **High confidence (75–94%)**: strong source/evidence fit with limited competing
  explanations.
- **Moderate confidence (50–74%)**: plausible and supported, but a meaningful
  alternative remains.
- **Low confidence (20–49%)**: weak or incomplete evidence; useful mainly as a
  probe target.
- **Speculative (0–19%)**: mention only when the test would be exceptionally
  cheap or informative.

Give separate percentages for:

- confidence that the diagnosis is correct; and
- confidence that the proposed repair seam would resolve the symptom without
  regressing the accepted baseline.

Do not use precise percentages as decoration. Explain what evidence would move
each estimate materially up or down. For mutually exclusive hypotheses within
one issue, make the percentages roughly coherent rather than assigning every
hypothesis high confidence.

## Required report format

Return one Markdown report with these sections:

### 1. Repository baseline

- branch, commit, tag and worktree status inspected;
- files and upstream sources reviewed;
- important evidence that was unavailable.

### 2. Executive assessment

- five to ten concise findings;
- the three highest-value next actions;
- any issue that should remain frozen rather than changed.

### 3. Issue matrix

Use one row per issue:

| Issue | Evidence status | Leading diagnosis | Diagnosis confidence | Safest repair seam | Fix confidence | Best next test | Regression risk |
|---|---|---|---:|---|---:|---|---|

### 4. Detailed issue analyses

For every issue, include:

- **Observed facts**
- **Unknowns**
- **Ranked hypotheses**
- **Evidence for and against**
- **Discriminating test** with expected outcomes for each leading hypothesis
- **Smallest repair seam**
- **Regression gates**
- **Files and lines inspected**

### 5. Cross-issue causal map

Identify shared causes only where evidence supports them. In particular, assess
whether renderer timing, AppKit/UIKit lifecycle, input publication and audio
starvation are independent faults or different consequences of one queue/
thread-ownership problem.

### 6. Recommended sequence

Give an ordered sequence of no more than eight experiments or changes. Each
entry must include expected information gain, implementation size
(`XS`/`S`/`M`/`L`), risk, rollback point and acceptance evidence.

### 7. Do-not-do list

Restate rejected or dangerous approaches and explain why they should not be
retried without new evidence.

### 8. Final certainty statement

State:

- what you believe is fixable with high confidence;
- what is likely fixable but needs one discriminating test;
- what remains genuinely unknown; and
- what additional artifact or observation would be most valuable next.

Do not end with generic advice. If the evidence cannot support a diagnosis,
say so plainly.

---

## End of prompt
