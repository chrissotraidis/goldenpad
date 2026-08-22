# External technical review — 2026-08-22

Read-only, evidence-first assessment of the seven unresolved GoldenPad issue
areas, performed against the repository state below. No files outside this
report were modified; no build, deployment, profiler, or game run was
performed. All claims are traced to tracked source, tracked patches, project
documentation, or the exact pinned public upstream revisions.

This is the second-pass revision: after the first pass, the pinned upstream
sources (GoldenEye64Recomp, RT64, Plume) were read in depth and several
findings were upgraded, corrected, or replaced. The **Revision log** at the
end records exactly what changed and why.

---

## 1. Repository baseline

| Item | Value |
| --- | --- |
| Branch inspected | `claude/goldenpad-technical-review-1ffog7` |
| Commit | `13c07bacf5645ac8fe2addd6613f264d874498c1` ("docs: record Preview 2 publication", 2026-08-22) |
| Worktree | Clean (0 modified/untracked entries) |
| Release tag | `v0.1.0-preview.2` = `bf3abb89d8e4074637c1a619b7d8e27217fe8b8a`, an ancestor of HEAD |
| Delta HEAD vs tag | 1 commit, documentation only (`docs/RELEASE_CHECKLIST.md`, `docs/STATUS.md`, `docs/WORKLOG.md`; +10/−3 lines) |

Because the delta is docs-only, every source/patch claim below holds equally
for the public `v0.1.0-preview.2` release and for HEAD.

**Repository files reviewed** (complete reads unless noted):
`README.md`, `docs/STATUS.md`, `docs/TESTING.md`, `docs/TECH_DEBT.md`,
`docs/MULTIPLAYER_ROADMAP.md`, `docs/PREVIEW_2_ROM_IMPORT.md`,
`docs/RT64_N64RECOMP_PROTOTYPE.md`, `docs/RELEASE_NOTES_0.1.0-preview.2.md`,
`Sources/InputSystem.swift`, `Sources/RecompPrototypeInput.swift`,
`Sources/TouchControlsView.swift` (structure/ownership), `Sources/RecompPrototypeApp.swift`
(lifecycle and canvas regions), `Sources/RecompPrototypeMetalCanvas.swift`,
`Sources/RecompPrototypeAudio.swift`, `Sources/Mac/RecompMacInput.swift`,
`Sources/Mac/RecompMacMetalCanvas.swift`, `Sources/Mac/GoldenPadMacApp.swift`,
`Sources/Mac/RecompMacAudio.swift`,
`Support/RecompPrototype/recomp_game_start.cpp`,
`Support/RecompPrototype/recomp_rt64_surface_bridge.cpp`, `CMakeLists.txt`
(patch-marker guards), and the tracked patches
`goldeneye64recomp-ios-prototype-render-trace.patch`,
`goldeneye64recomp-ios-modern-controls.patch`, `plume-ios-metal.patch`,
`plume-macos-main-queue-coalescing.patch`, `rt64-ios-embedded.patch`.

**Upstream sources reviewed at the exact GoldenPad pins** (primary
repositories, raw file fetches):

- RT64 `rt64/rt64` @ `5473732a822a4423b5696e7cb18fecc425a59875`:
  `src/hle/rt64_present_queue.cpp` (present loop, cursor barrier,
  acquire-failure and resize recovery), `src/hle/rt64_state.cpp`
  (`updateScreen`, `submitFramebufferPair`, the `clearDepthOnly` fast path,
  depth `formatChanged` handling and RAM write-back),
  `src/hle/rt64_rdp.cpp` (image tracking, scissor/rect extended alignment,
  overlap detection), `src/hle/rt64_framebuffer.cpp`,
  `src/hle/rt64_framebuffer_manager.cpp` (`changeRAM` mutual invalidation),
  `src/hle/rt64_workload_queue.cpp`, `src/hle/rt64_application.cpp`,
  `.gitmodules`.
- Plume `renderbag/plume` @ `d890ac899e505fb30040e037a4037cdeca68f033`:
  `plume_metal.cpp` (`MetalSwapChain::acquireTexture`, `present`, `resize`,
  `wait`, `MetalCommandSemaphore` value accounting, command-fence waits).
- GoldenEye64Recomp `cblock85/GoldenEye64Recomp` @
  `a787fe0d95e8278fcba5ba2d768fa6a606e75f55`: `patches/widescreen.c` and
  `patches/skybox.c` (full pre-GoldenPad-patch bodies), `patches/externs.h`
  (`z_buffer` typing), `patches/workbench_theboy.c` (`bossMainloop`, frame
  rate control, `shuffle_player_ids` seam), `src/main/main.cpp` (reference
  host audio: `queue_samples`, `set_frequency`, `get_frames_remaining`).

**Important evidence that was unavailable:**

- The ignored `ref/` upstream checkouts are absent from this clone (only
  `ref/README.md` is tracked), so upstream code was verified via the public
  pinned revisions above rather than local checkouts.
- The private generated AOT sources (`RecompiledPatches/patches.c`,
  `patches_bin.c`) are intentionally untracked; only the CMake content-marker
  guards (`CMakeLists.txt:279-330`) and the tracked patch inputs are
  inspectable. The pre-patch bodies of `widescreen.c`, `skybox.c` and
  `workbench_theboy.c` were recovered from the pinned public
  GoldenEye64Recomp revision instead.
- No device session logs, crash reports, videos, or frame captures exist in
  the repository (correctly, per the data boundary). Every temporal claim
  (flicker, freeze, static) therefore rests on the documented evidence ledger,
  not on artifacts I could re-examine.
- The exact frequency GoldenEye requests from the audio host is not
  recorded in the repository (see Issue 4).

---

## 2. Executive assessment

Findings (source-verified unless marked otherwise):

1. **The Mac "slow mouse" has a structural, source-confirmed ceiling — worse
   than a gain problem, it discards fast motion.** The relative mouse path is
   clamped twice — the accumulated queue itself saturates at ±32,767 = one
   frame of full deflection (`recomp_game_start.cpp:167-173,742-749`), and the
   consumed value is clamped to `[-1, 1]`
   (`recomp_get_camera_inputs`, `recomp_game_start.cpp:831-832`) — before the
   game-side patch multiplies by a fixed 3°/frame (1°/frame while aiming)
   (`patches/goldeneye64recomp-ios-modern-controls.patch:86-89`). The recomp
   game loop targets **30 FPS** (`desiredFPS = 30`, upstream
   `workbench_theboy.c:455-469` at the pin), so the hard ceiling is
   **~90°/s hip-fire and ~30°/s aiming**. Because the *queue* saturates (it is
   clamped, not drained proportionally), any mouse travel beyond ~1 frame of
   deflection per game frame is **discarded**, and raising the sensitivity
   slider *lowers* the physical speed at which discarding begins — which is
   precisely why the slider "doesn't help". This is arithmetic entailed by
   the inspected code, not a latency defect.
2. **The primary runtime has no multi-controller model at all.** It binds
   exactly one controller (`GCController.controllers().first`,
   `Sources/RecompPrototypeInput.swift:305-317`); ports 2–4 exist only as
   test-mode flags in the core (`recomp_game_start.cpp:434-478`). Real
   Player 3/4 routing is not partially built — the ownership layer is absent
   at this seam. The four-slot model that does exist
   (`Sources/InputSystem.swift:466,2208-2242`) belongs to the legacy MGB64
   target and is not wired to the recomp core.
3. **Controller disconnect during the two-player test re-routes touch to
   Player 1 mid-match.** Disconnect clears the test-mode flags core-side
   (`recomp_game_start.cpp:653-665`) and flips the Swift publish branch so
   touch input, previously Player 2, is published to port 0
   (`Sources/RecompPrototypeInput.swift:403-416`). This is a concrete,
   source-confirmed touch-ownership leak.
4. **The screenshot-freeze exposure is now precisely characterized: bounded
   multi-second stalls are an expected mechanism; a hard freeze requires one
   specific unbounded wait.** RT64's present loop recovers from a failed
   drawable acquisition (`swapChainValid = false` → resize/retry,
   `rt64_present_queue.cpp:300-306,466-487` at the pin) and **always advances
   the queue barrier** for a non-paused present even when acquisition fails
   (`:514-529`). But the game/VI thread pushes presents through
   `PresentQueue::advanceToNextPresent`, an **unbounded busy-wait spin**
   (`rt64_present_queue.cpp:38-55`): while iOS throttles drawables (screenshot
   or overlay), each acquire costs up to ~1 s (`nextDrawable` timeout), the
   small present ring fills, and the game thread spins hot — freezing
   simulation *and* audio production together for seconds, then recovering.
   That matches the reported symptom without any bug in tracked code. The only
   truly unbounded wait found on the present path is the command-fence
   `dispatch_semaphore_wait(..., DISPATCH_TIME_FOREVER)`
   (`plume_metal.cpp:3733`) — a hard freeze requires a Metal completed-handler
   that never fires. Plume's signal-before-acquire semaphore ordering is
   value-idempotent on failure (`plume_metal.cpp:2046-2085,3694-3695`), and
   `MetalSwapChain::wait` is 1-second-bounded (`:1982-1992`), so neither can
   deadlock. Remaining work is the physical lifecycle matrix plus two bounded
   breadcrumbs (nil-drawable counter, fence-wait duration).
5. **Audio has one identified cross-thread mutation window and one confirmed
   divergence from the reference host.** `goldenpad_recomp_set_app_active`
   mutates consumer-thread-only fields and the read cursor from the lifecycle
   thread (`recomp_game_start.cpp:696-723`); it is safe in the normal
   background→foreground order (engine paused) but races if an
   interruption/route-change `activate()` restarts the engine while the app is
   backgrounded. Separately, the game's requested output rate is logged and
   ignored (`setFrequency`, `recomp_game_start.cpp:426-428`) while the host
   hard-codes 22,050 Hz (`Sources/RecompPrototypeAudio.swift:82-89`). The
   pinned reference host **honors** that callback — it stores the requested
   rate and rebuilds its resampler from it (upstream `src/main/main.cpp:289-293`)
   — so ignoring it is a real divergence, not a shared convention. (In
   GoldenPad's favor: its continuous-ring design avoids the per-chunk
   resampling seams the reference host must patch over with duplicated
   boundary frames, `main.cpp:182-227`.)
6. **A complete, source-verified mechanism now exists for the residual
   multiplayer flicker — and it does not implicate the depth-alias repair.**
   GoldenEye aliases every player's depth writes onto the same physical rows
   by shifting the lower players' depth-image base 120 rows (76,800 bytes)
   upward — `z_buffer` is an address in an `s32`
   (upstream `patches/externs.h:415`), and the patch's
   `SCREEN_WIDTH * SCREEN_HEIGHT` shift equals exactly 120 rows of 16-bit
   depth at 640 bytes/row. RT64's framebuffer manager therefore tracks **two
   overlapping depth framebuffers** (base, and base − 76,800), and
   `FramebufferManager::changeRAM` marks *every* overlapping framebuffer
   `rdramChanged` on each write (`rt64_framebuffer_manager.cpp:905-916`).
   Each player pass thus invalidates the sibling row-group's depth framebuffer
   **every multiplayer frame**; `rdramChanged` feeds
   `depthImg.formatChanged` (`rt64_state.cpp:564`), which **discards the
   GPU-side depth, clears the depth target, and re-reads it from quantized
   16-bit RAM** (`rt64_state.cpp:1405-1435`), RAM that is itself a per-pass
   write-back (`:1458-1479`). Single player has one depth framebuffer and
   never takes this path — matching the symptom's confinement to multiplayer,
   its slightness (precision-level, fog/depth-derived), and its migration
   with the shuffled pass order. The final perceptual link (that this
   round-trip is what the eye sees as lighting flicker) is the one unverified
   step; a one-line counter at the `formatChanged` consumer discriminates it.
   The `clearDepthOnly` fast path (`rt64_state.cpp:571-576`) also exactly
   confirms why the depth-alias repair was necessary and correct — the
   fill-only pair's color address must equal the next pair's depth address.
7. **The Mac thin blue edge already has an accepted iOS-precedented fix
   shape.** iOS measured its own far-edge artifact as an exactly
   two-physical-pixel sampling seam and masks it with a one-point opaque host
   overlay without touching RT64 (`Sources/RecompPrototypeApp.swift:78-85`;
   `docs/RT64_N64RECOMP_PROTOTYPE.md:290-295`). The Mac host has no such mask
   (`Sources/Mac/GoldenPadMacApp.swift:65-88`), and its window-size rounding
   (`patches/plume-ios-metal.patch:47-73`) plus `autoResizeDrawable`
   (`Sources/Mac/RecompMacMetalCanvas.swift:181`) make a ~1-px coverage
   mismatch plausible.
8. **The Plume main-queue coalescing patch bounds exactly the two per-frame
   request kinds that caused the Mac starvation cluster** (window attributes
   and refresh rate, one pending each;
   `patches/plume-macos-main-queue-coalescing.patch`), leaving only rare
   user-initiated dispatches (fullscreen toggle) unbounded.
9. **Both platforms publish input from a main-run-loop timer**
   (`Sources/RecompPrototypeInput.swift:182-185`,
   `Sources/Mac/RecompMacInput.swift:217-221`), so any main-thread stall
   simultaneously degrades buttons, movement, and queued look. This is why the
   Mac main-queue fault presented as an "everything" failure and is worth one
   cheap drift instrument on both platforms.
10. **The Simulator keyboard shim leaks D-pad presses into the left stick**
    (`Sources/RecompPrototypeInput.swift:369-376` overwrites `externalStick`
    from arrow keys) — Simulator-only by construction, no release impact, but
    worth knowing when interpreting Simulator input evidence.

**Three highest-value next actions:**

1. Add a one-line bounded counter where `depthImg.formatChanged` forces the
   depth re-read (`rt64_state.cpp:1405-1435` region of the embedded RT64
   build) and read it during a multiplayer session — it directly tests the
   new leading flicker mechanism (fires every multiplayer frame if true, zero
   in single player) without touching the frozen repair (Issue 1).
2. Read the *existing* bounded session logs on the paired devices for the
   `audio: game requested %u Hz output` line and the underrun/drop counters
   coincident with reported static — zero new code, directly discriminates
   the audio hypotheses (Issue 4).
3. Add the iOS-precedented one-point right-edge mask to the Mac host and run
   the existing Dam/Surface scene comparison — XS change, precedented, and it
   retires the most visible Mac defect without touching RT64 (Issue 5).

(The fixed-render-order probe remains valuable as the *second* Issue 1 step:
the exact seam is `shuffle_player_ids()` /
`get_nth_player_from_shuffled(i)` inside the already-patched `bossMainloop`,
upstream `workbench_theboy.c:692-696` — a one-line diagnostic change. Under
the new leading mechanism it predicts the flicker becomes *position-stable*
rather than disappearing; disappearance would instead implicate
order-dependent state leakage.)

**Issues that should remain frozen rather than changed:**

- The depth-address alias repair (`zbufClearCurrentPlayer` hunk of
  `patches/goldeneye64recomp-ios-prototype-render-trace.patch:172-220`) and
  its CMake markers. Physically accepted; no evidence implicates it in the
  residual flicker (see Issue 1).
- RT64's window-size contract on both platforms; the drawable-size
  substitution is a recorded rejected approach (`docs/TECH_DEBT.md:80-110`).
- The KSEG1 `ExtendedRegionMask` repair
  (`patches/rt64-ios-embedded.patch`, `rt64_rsp.cpp`/`rt64_rdp.cpp` hunks).
- The Plume main-queue coalescing bound.

---

## 3. Issue matrix

| Issue | Evidence status | Leading diagnosis | Diagnosis confidence | Safest repair seam | Fix confidence | Best next test | Regression risk |
|---|---|---|---:|---|---:|---|---|
| 1. Multiplayer lighting flicker | Physical video evidence exists but is not in repo; patches and pinned RT64 framebuffer code fully readable | Aliased overlapping depth framebuffers mutually invalidating each other every multiplayer frame → forced quantized depth re-read from RAM → fog/depth precision jitter; order-dependent state leak is the fallback | 50% (Moderate; complete source-verified chain except the final perceptual link; state-leak fallback at 25%) | One-line diagnostic counter at the depth `formatChanged` consumer first; any repair is RT64-side aliased-depth recognition and is **not** small | 35% (repair is nontrivial; instrument confidence is high) | Depth-resync counter in one multiplayer session (predicts: fires every MP frame, zero in SP), then fixed-render-order build | Medium — instrument is safe; a repair touches RT64 framebuffer tracking and must pass the frozen video protocol |
| 2. Real 3/4-controller routing | Confirmed by source; no physical multi-controller evidence exists | Ownership layer absent in primary runtime; single-controller `first()` binding plus flag-gated ports; disconnect leaks touch to P1 | 95% (Confirmed — this is a design gap, not a hidden bug) | New slot model at the `RecompPrototypeInput` → `goldenpad_recomp_set_controller_state` seam, modeled on `InputCoordinator` | 70% | Synthetic `GCVirtualController` connect/disconnect probe asserting port ownership invariants | Medium — touches accepted P1 controller path; guard with existing `--input-probe` plus the new probe |
| 3. Screenshot/resume freeze | Historical symptom; mitigations in tree; upstream present path read in full at pin | Bounded stall by design: game thread busy-spins in `advanceToNextPresent` while drawable acquires time out (~1 s each) during system overlays; audio stalls with it; hard freeze requires a never-firing Metal completion handler (the one unbounded fence wait) | 65% (Moderate–High) for the stall mechanism; hard-freeze cause remains unknown | Bounded counters (nil-drawable count, fence-wait duration) + physical lifecycle matrix; optionally convert the spin to a condvar wait upstream | n/a (verification first) | Scripted physical matrix: screenshot ×10, Control Center, app switcher, camera overlay, with post-run log readback | Low — instrumentation-only first step |
| 4. Audible audio static | Counters healthy in accepted runs; static reports anecdotal; ring and reference host fully readable | Intermittent real jitter/underrun events outside logged runs, plus two counter-invisible candidates (lifecycle-thread mutation race; ignored `setFrequency`, which the reference host honors) | 45% (Moderate–Low; genuinely multi-candidate) | (a) Move foreground ring reset onto the render thread via a flag; (b) honor/verify `setFrequency` | 55% | Read existing logs for requested Hz; then synthetic-sine + output-tap discontinuity detector | Low for (a)/(b); both are small and platform-shared |
| 5. Geometry faults & blue edge | iOS seam measured (2 px) and masked; Mac unmasked; rejected experiment documented | Mac edge: host presentation-boundary coverage/rounding seam, same family as the masked iOS seam; stage geometry: separate lanes (original culling vs unvalidated RT64 effects) | 70% (High–Moderate) for the edge; geometry faults individually unknown | One-point opaque trailing-edge overlay in `GoldenPadMacApp` ZStack (iOS precedent) | 75% | Screenshot Dam/Surface at fixed camera before/after mask; settings matrix for geometry reports | Very low — additive host overlay, no RT64 change |
| 6. Mac mouse feel & performance | Full input path and upstream game loop readable; ceiling and truncation arithmetically confirmed | Double-clamped relative-delta seam at 30 FPS game frames: ~90°/s hip / ~30°/s aim ceiling, with fast motion discarded at queue saturation; not event delivery | 92% (High — entailed by inspected code) | Widen/re-scale the queued-delta term in `recomp_get_camera_inputs` (Mac-gated), leaving player structs and view callbacks untouched | 70% | Log consumed look per frame vs pending host delta; verify flick truncation at max sensitivity | Low if Mac-gated; must not alter the iOS touch tuning path |
| 7. Secondary gaps | Documented in STATUS/TECH_DEBT/PREVIEW_2_ROM_IMPORT | Classification below | — | — | — | — | — |

---

## 4. Detailed issue analyses

### Issue 1 — Residual multiplayer lighting flicker

**Observed facts**

- The former large black/checkerboard corruption is repaired and physically
  accepted: 3,336 consecutive coherent frame comparisons, 54,652 presented VI
  updates, zero audio drops/underruns (`docs/STATUS.md:30-42`,
  `docs/MULTIPLAYER_ROADMAP.md:79-88`).
- The repair mechanism is fully readable: `zbufClearCurrentPlayer` now issues
  each lower player's depth clear through the game's own shifted depth-image
  address (`clear_buffer -= SCREEN_WIDTH * SCREEN_HEIGHT` for player ≥ 3, or
  player 2 of 2) with the viewport's original Y range
  (`patches/goldeneye64recomp-ios-prototype-render-trace.patch:174-220`),
  matching RT64's exact-address depth-clear tracking
  (`docs/TECH_DEBT.md:153-171`).
- Sky fills, background scissors, and fades are viewport-scoped:
  `skyRenderTri`/`skyRenderFull` fill only
  `viGetViewLeft/Top/Width/Height` with the fog color from
  `fogGetCurrentEnvironmentp()` (patch:108-171); `currentPlayerDrawFade`
  scissors and fills only the player view (patch:237-258);
  `bgScissorCurrentPlayerView` selects `gEXSetScissor` vs `gDPSetScissor` by
  whether the view is full-width (patch:221-236).
- GoldenEye renders players sequentially into a shared framebuffer and
  shuffles player order each frame (`docs/MULTIPLAYER_ROADMAP.md:14-19`), so
  order-dependent state is a standing suspect class.
- CMake refuses builds whose generated patches lack the repair markers
  (`viGetViewTop`, `0XFFFE << 16`, `0XD400`; `CMakeLists.txt:302-312`), so
  the shipped binary provably contains the repair.
- Slight lighting flicker remains, not yet isolated to player, room,
  transition, display-list state, or pass (`docs/STATUS.md:37-42`).

**Additional facts established from the pinned upstreams (second pass)**

- The alias arithmetic is coherent: `z_buffer` is a runtime address held in
  an `s32` (upstream `patches/externs.h:413-415`), so the patch's
  `SCREEN_WIDTH * SCREEN_HEIGHT` (76,800-byte) shift equals exactly **120
  rows** of 16-bit depth at 640 bytes/row — one split-screen viewport height.
  All players' depth writes therefore land in the *same physical rows*
  (`[z_buffer, z_buffer + 76,800)`), which is legal because players render
  sequentially and depth is only needed within one pass.
- RT64's `clearDepthOnly` fast path requires the fill-only pair's color-image
  address to **exactly equal** the next pair's depth-image address
  (`rt64_state.cpp:571-576` at the pin) — confirming both why the upstream
  full-frame clear failed for shifted lower players and why the GoldenPad
  repair (clear through the shifted address) is correct. Because each
  player's clear immediately precedes that player's own draw pair, the
  pairing works in any shuffled order.
- **RT64 tracks two overlapping depth framebuffers in multiplayer** — one at
  `z_buffer` (top row-group, range `[base, base+76,800)` for a 120-row pass)
  and one at `z_buffer − 76,800` (bottom row-group, range
  `[base−76,800, base+76,800)` for a 240-row image). Every depth write calls
  `FramebufferManager::changeRAM`, which sets `rdramChanged = true` on
  **every other framebuffer overlapping the written range**
  (`rt64_framebuffer_manager.cpp:905-916`). Since both depth framebuffers'
  ranges cover the same physical rows, **each player pass invalidates the
  sibling row-group's depth framebuffer, every frame**.
- `rdramChanged` flows into `depthImg.formatChanged`
  (`rt64_state.cpp:564`), which (a) discards the GPU-side last write,
  (b) clears the depth render target and resets `readHeight`, and (c)
  re-reads the entire depth target from RDRAM
  (`rt64_state.cpp:1405-1435`) — RDRAM whose contents are themselves a
  quantized 16-bit per-pass write-back (`rt64_state.cpp:1458-1479`).
  Single player has one depth framebuffer, no overlap, and never takes this
  path.
- The player-order shuffle seam is exact and already inside a patched
  function: `shuffle_player_ids()` and
  `set_cur_player(get_nth_player_from_shuffled(i))` in `bossMainloop`
  (upstream `workbench_theboy.c:692-696`) — a fixed-order diagnostic is a
  one-line change in the existing patch-regeneration workflow.
- No `gEXSetRectAlign`/`gEXSetScissorAlign` exists anywhere in the patch
  sources, so RT64's *global* rect/scissor alignment state stays at defaults
  — the "global alignment leaked across passes" sub-hypothesis is ruled out.
  The per-draw scissor origin stack still persists across pass boundaries.

**Unknowns**

- Whether the depth RAM round-trip is what the eye perceives as lighting
  flicker (fog and depth-derived blending are the plausible visible carriers)
  — the one unverified link in the otherwise source-verified chain.
- Whether the flicker exists on original hardware in the same scenes
  (GoldenEye multiplayer genuinely reduces fog/effects;
  `docs/MULTIPLAYER_ROADMAP.md:92-96`). No reference-capture comparison
  exists.
- Whether the flicker's *location* correlates with player render order.

**Ranked hypotheses (revised)**

1. *Aliased-depth framebuffer churn* — the mutual `rdramChanged`
   invalidation forces each row-group's depth through a
   GPU → 16-bit RAM → GPU round-trip every multiplayer frame; frames where
   the round-trip is not value-identical (precision loss, write-back
   ordering across the shuffled passes) show as slight fog/lighting
   differences in the affected views. **Moderate, 50%.** Every link is
   verified in the pinned code except the final perceptual attribution;
   the mechanism is multiplayer-only, slight, and order-migrating —
   matching all three observed properties.
2. *Order-dependent per-player RDP state visibility* (fog/fade/prim-color/
   scissor-origin-stack staleness across shuffled pass boundaries).
   **Low–Moderate, 25%.** Still plausible; the patched family sets state
   that persists into the next pass, and the scissor origin stack survives
   pass boundaries. Weakened relative to the first pass because the
   global-alignment variant is ruled out and because H1 now explains the
   symptom profile more specifically.
3. *Original GoldenEye multiplayer behavior*. **Low, 15%.**
4. *Host presentation artifact*. **Speculative, 5%.**

**Evidence for and against**

- For 1: complete code chain at the pin (citations above); explains
  multiplayer-only, slightness, and migration; also predicts a measurable
  multiplayer performance tax (a full depth re-read per pass per frame).
  Against 1: if RT64's depth write-back and re-read are exactly
  value-preserving in practice, the churn would be invisible and only the
  performance cost would remain.
- For 2: the corruption family history lived in this patch family. Against
  2: the family was just carefully viewport-scoped, the accepted run shows
  no structural leak, and the specific global-alignment variant is now
  excluded by source.
- For 3: GoldenEye's own multiplayer reductions change lighting/fog per
  view. Against 3: testers familiar with the game called it out as a defect.

**Discriminating test (revised, two stages)**

*Stage 1 — depth-resync counter (cheapest, highest information).* One atomic
counter incremented where `depthImg.formatChanged` forces the depth
clear-and-re-read (`rt64_state.cpp:1405-1435` region), surfaced through the
existing `goldenpad_recomp_note_*` pattern and the 10 s health line.
Predictions: H1 → fires on essentially every multiplayer frame and never in
single player; if it does *not* fire per frame, H1 is dead and H2 is
promoted. If it fires, correlate a bounded per-fire timestamp with flicker
timestamps in the standard 30 s video (`docs/TESTING.md:90-101`).

*Stage 2 — fixed player render order.* One-line diagnostic at
`workbench_theboy.c:692-696` (never shipped). Predictions now differ by
hypothesis: H1 → churn continues (order-independent) but the flicker's
*location* becomes stable; H2 → flicker disappears or becomes strictly
reproducible at specific pass transitions; H3 → unchanged.

A third zero-code probe: two-player vs four-player on the same map — H1
predicts flicker wherever aliasing exists (any split mode, any view);
resolution/MSAA changes should modulate H1 (precision-dependent) but not H3.

**Smallest repair seam (revised)**

If Stage 1 confirms H1, the honest finding is that **no small repair
exists**: the mutual invalidation is inherent to GoldenEye's aliased depth
images plus RT64's overlap semantics at this pin, and any fix (teaching
`changeRAM`/the framebuffer manager to recognize depth siblings aliasing the
same physical rows, or un-shifting the game's depth images) is RT64-side or
game-render-side surgery of exactly the class the do-not-do list guards.
The correct sequencing is: confirm with the counter, measure the performance
tax, then decide whether the slight flicker justifies an upstream
conversation/patch against RT64's framebuffer manager — with the frozen
video protocol as the gate. If Stage 1 refutes H1, the repair returns to the
patched `skybox.c`/`widescreen.c` family via the per-player trace below.
Either way the depth-alias *clear* repair in `zbufClearCurrentPlayer`
remains untouched — under H1 the churn exists independent of it (it is
created by the game's shifted depth-image binding, not by the clear), and
under H2 it is unrelated.

**Minimal per-player trace** (only if H2 is promoted): tag each `send_dl`
with the current player number — the game already exposes the current-player
pointer the monitor thread reads (`recomp_game_start.cpp:276-277`), and the
trace seam already exists in `send_dl`
(`patches/goldeneye64recomp-ios-prototype-render-trace.patch:71-83`). Record
(frame, player, sky-fill color) and log only on change. Bounded,
change-triggered, no per-frame logging cost.

**Regression gates** — the frozen baseline protocol verbatim:
`docs/TESTING.md:90-101` (30 s two-player + 30 s four-player physical video,
rejection on any flash even if it recovers), plus unchanged single-player
acceptance. Diagnosis confidence 50%; confidence that the eventual repair
seam resolves the symptom without regressing the baseline: 35% (the H1
repair is nontrivial; the instrument itself is near-risk-free).

**Files and lines inspected**:
`patches/goldeneye64recomp-ios-prototype-render-trace.patch:108-267`;
`CMakeLists.txt:279-330`; `docs/TECH_DEBT.md:145-181`;
`docs/MULTIPLAYER_ROADMAP.md:1-125`; `docs/TESTING.md:69-101`;
`docs/STATUS.md:26-42,576-590`; upstream at pins: `patches/widescreen.c`
(full), `patches/skybox.c`, `patches/externs.h:395-415`,
`patches/workbench_theboy.c:600-760`, `rt64_state.cpp:535-615,1350-1480`,
`rt64_rdp.cpp:100-280,970-1240`, `rt64_framebuffer_manager.cpp:895-925`,
`rt64_framebuffer.cpp:40-185`.

### Issue 2 — Real three/four-controller routing and lifecycle

**Observed facts**

- The primary runtime binds exactly one controller:
  `controller = GCController.controllers().first(where: { $0.extendedGamepad != nil })`
  on every connect/disconnect notification
  (`Sources/RecompPrototypeInput.swift:305-317`). It never sets
  `GCController.playerIndex`.
- Ports are published by mode, not by ownership: two-player test → controller
  to port 0, touch to port 1, neutral 2/3 in four-player test; otherwise
  controller-or-touch to port 0
  (`Sources/RecompPrototypeInput.swift:396-409`).
- The core gates port availability purely on the test-mode flags
  (`getInput`/`getConnectedDeviceInfo`, `recomp_game_start.cpp:434-478`), and
  disconnect force-clears both flags (`recomp_game_start.cpp:653-665`).
- **Confirmed leak:** if the controller disconnects while the two-player test
  is active, `refreshController()` recomputes `twoPlayerTestModeActive =
  false` and the next `publish()` takes the touch-only branch — touch
  buttons/movement, previously Player 2's, are published to **port 0**
  (`Sources/RecompPrototypeInput.swift:309-317,406-409`), and queued touch
  look follows (`:410-416`). Mid-match, GoldenEye also loses ports 2–4
  (`Device::None`) with undefined in-game consequences.
- The four-slot model exists only in the legacy MGB64 coordinator:
  slots, swap-based `moveController`, per-slot `playerIndex`
  (`Sources/InputSystem.swift:466,655-669,2208-2242`) publishing via
  `goldenPadMGB64SetControllerState` (`:707-715`) — a different core symbol
  than the recomp bridge. `TouchControlsView.swift` binds `InputCoordinator`
  and is likewise legacy-side.
- Even the legacy model does not preserve ownership across reconnect: a
  reconnecting controller goes to the **first free slot**
  (`Sources/InputSystem.swift:2208-2212`), not its previous slot, so a P2
  assignment silently becomes P1 after a sleep/reconnect cycle if slot 0 is
  free. Touch merges only into player 0 by construction
  (`MultiplayerInputOwnership.compose`, `Sources/InputSystem.swift:240-253`).

**Unknowns**

- GoldenEye's exact in-match behavior when an advertised port switches to
  `Device::None` mid-frame (pause? controller-removed message? crash?). No
  repository evidence.
- Physical behavior of `GCController.controllers()` ordering across
  sleep/wake with 2+ real controllers (API order is unspecified; the code
  depends on it).

**Ranked hypotheses** (framed as answers, since this is a design gap, not a
mystery):

- Stable ownership across connect/disconnect/sleep/foreground: **not
  preserved** in the primary runtime — Confirmed (95%+) from source.
- `playerIndex`/array-position/port consistency: **not maintained** — primary
  runtime never writes `playerIndex` and depends on unspecified array order.
- Touch leakage into a non-touch player: **yes**, on disconnect during the
  two-player test (path above) — Confirmed from source; also transiently
  possible on any future reassignment built on the current publish branches.
- Is the experimental mode masking a production ownership problem: **yes** —
  the flags substitute for an ownership model; there is nothing underneath
  them to promote to production.

**Discriminating test (smallest deterministic synthetic lifecycle test)**

Simulator-only probe using `GCVirtualController` (or the existing synthetic
MFi device), extending the existing `--input-probe` reporting style
(`Sources/RecompPrototypeInput.swift` has no probe today; the pattern lives in
`Sources/InputSystem.swift:729-746`). Scripted sequence with assertions after
each step, read back through a new bounded core query:

1. Connect A → assert port 0 = A. Enable two-player test → assert port 1 =
   touch. 2. Press-and-hold a touch button, disconnect A → assert port 0
   publishes **neutral** (currently fails: port 0 receives touch — this is
   the defect the probe pins). 3. Reconnect A → assert prior shape restored,
   no duplicate ownership, no held buttons. 4. Connect B, disconnect A →
   assert B does not silently inherit A's player. 5. Background/foreground →
   assert all held state cleared (`releaseTouchInput` path) and port shape
   unchanged.

This exposes stale handles, slot collapse, duplicate ownership, and held
input with zero hardware.

**Smallest repair seam**

Lift the slot/ownership model (slots, stable reconnect, swap-move) to the
recomp seam: a slot array inside `RecompPrototypeInput` publishing per-slot
to `goldenpad_recomp_set_controller_state`, with reconnect-by-identity
(vendor+category or `GCController` identity while the object lives) and an
explicit rule that touch binds to exactly one designated port. Core-side,
replace the two boolean test-mode flags with a per-port advertised mask set
by the host. The legacy `InputCoordinator` is the in-repo design reference,
with its reconnect-to-first-free-slot behavior corrected rather than copied.

**macOS policy** (no touch path): keyboard/mouse is always a player (default
Player 1); physical controllers fill the remaining ports in connection order
with the same stable-reconnect rule; a Controllers UI equivalent to the
legacy Move/swap flow covers deliberate reassignment. Keyboard/mouse should
be relegated from Player 1 only by explicit user action, never by a
controller connecting.

**Regression gates**: existing `--input-probe` outputs
(`Multiplayer touch ownership probe`, face-button isolation,
`docs/TESTING.md:521-539`), unchanged single-controller P1 physical
acceptance, unchanged auto-hide behavior, and the frozen multiplayer render
gate. Fix confidence 70% — the design is clear, but GoldenEye's mid-match
hot-plug behavior is the untested half of the risk.

**Files and lines inspected**:
`Sources/RecompPrototypeInput.swift:123-493`;
`Sources/InputSystem.swift:205-283,457-762,2199-2358`;
`Sources/TouchControlsView.swift:1-40` (ownership);
`Support/RecompPrototype/recomp_game_start.cpp:42-74,429-478,613-694`;
`Sources/Mac/RecompMacInput.swift:351-356`; `docs/MULTIPLAYER_ROADMAP.md:62-125`.

### Issue 3 — Screenshot, system-overlay, and foreground-resume freezes

**Observed facts**

- The current tree carries three specific mitigations: (a) `.inactive` does
  **not** suspend RT64 — it only releases touch and notes the transient
  (`Sources/RecompPrototypeApp.swift:158-163`); (b) the host layer sets
  `allowsNextDrawableTimeout = true` so `nextDrawable` cannot block
  indefinitely (`Sources/RecompPrototypeMetalCanvas.swift:176-179`); (c)
  while `.background`, `update_screen` returns before entering RT64's
  presentation (`goldenpad_recomp_is_app_active` gate,
  `patches/goldeneye64recomp-ios-prototype-render-trace.patch:98-104`).
- At the pinned upstream revisions, the failure path of drawable acquisition
  is recoverable by design: `MetalSwapChain::acquireTexture` returns false on
  a nil drawable (`plume_metal.cpp:2060-2064` @ `d890ac89`), RT64's present
  loop marks the swap chain invalid and routes through
  `presentGraphicsWorker->wait()` → `resize()` → retry
  (`rt64_present_queue.cpp:300-306,466-487` @ `5473732a`), and — critically —
  the present thread **advances the queue barrier for every non-paused
  present even when acquisition fails or the present is skipped**
  (`threadAdvanceBarrier`, `rt64_present_queue.cpp:514-529`). The Plume
  semaphore accounting survives a failed acquire: the signal side writes the
  *current* value without incrementing (`plume_metal.cpp:2055-2057`), and
  only the wait side increments (`:3694-3695`), so a signal with no matching
  wait is value-idempotent, not a desync.
- **The game/VI thread pushes presents through an unbounded busy-wait spin.**
  `PresentQueue::advanceToNextPresent` loops taking a mutex until the barrier
  cursor moves (`rt64_present_queue.cpp:38-55`; no condition variable, no
  sleep). `State::updateScreen` calls it on the game-side thread
  (`rt64_state.cpp:1954-1956`). While iOS throttles drawables (screenshot,
  system overlay), each present-thread acquire costs up to ~1 s
  (`nextDrawable` timeout), the small present ring fills, and the game thread
  spins hot until the barrier lifts — freezing simulation **and audio
  production** together for seconds, then recovering. This is a complete,
  bounded mechanism for the reported symptom that involves no bug in tracked
  code and burns a core (thermal/scheduling cost) while it lasts.
- The only genuinely unbounded wait found on the present path is the
  command-fence `dispatch_semaphore_wait(..., DISPATCH_TIME_FOREVER)` in
  Plume's `RenderCommandFence` wait (`plume_metal.cpp:3733`), reached via
  `presentGraphicsWorker->wait()`. A *permanent* freeze therefore requires a
  Metal command buffer whose completed handler never fires.
  `MetalSwapChain::wait` is bounded to 1 s (`plume_metal.cpp:1982-1992`).
- Ordering on background is: release touch → `audio.deactivate()`
  (`engine.pause`) → `setAppActive(false)` (`RecompPrototypeApp.swift:164-167`);
  on foreground: `setAppActive(true)` (which discards stale ring audio and
  resets consumer state, `recomp_game_start.cpp:696-723`) → `audio.activate()`.
  With that order the consumer is paused during the reset — consistent.
- Game simulation is never paused; the monitor thread logs a bounded
  watchdog line if RT64 makes no progress for 10 s while active
  (`recomp_game_start.cpp:326-340`) and a 10 s health line with dl/vi/
  presented/audio/input state (`:293-324`).
- The freeze reports predate the current tree's mitigation set, and no
  physical lifecycle matrix has been run against the current build
  (`docs/STATUS.md:591-592`, `docs/PREVIEW_2_ROM_IMPORT.md:62-65`).

**Unknowns**

- Whether the historical freezes are actually fixed — the mitigations are
  plausible but unverified on hardware.
- Whether iOS ever vends nil drawables during a *screenshot* (as opposed to
  backgrounding); if it never does, mitigation (b) is untested in exactly the
  scenario it targets.
- `MetalSwapChain::present` behavior when the retained `drawable.mtl` is
  stale after a failed acquire: upstream guards with an `assert`
  (`plume_metal.cpp:1944-1945`) that compiles out in Release. RT64's loop
  never reaches `present` with `swapChainValid == false`, so this is
  reachable only through a code path I did not find — recorded as a residual
  unknown, not a diagnosis.

**Ranked hypotheses for the freezes (revised)**

1. *Bounded backpressure stall (by design):* drawable throttling during a
   screenshot/overlay slows the present thread to ~1 acquire-timeout per
   second; the full present ring makes the game thread busy-spin in
   `advanceToNextPresent`, stalling simulation and audio together for
   seconds; recovery when drawables return. Perceived as a freeze, sometimes
   ended by the user killing the app before recovery. **Moderate–High, 65%**
   as the mechanism of the historical reports.
2. *Hard freeze via a never-firing Metal completion handler* (the one
   unbounded fence wait, `plume_metal.cpp:3733`) — possible if a command
   buffer submitted around a lifecycle edge is neither executed nor errored.
   **Low, 15%.** Metal normally completes backgrounded buffers with errors,
   which still fires handlers.
3. *Host main-thread stall* (SwiftUI/timer starvation freezing input publish
   and status, game alive) — input publish and touch handling are main-thread
   (`Sources/RecompPrototypeInput.swift:182-185`). **Low, 10%.**
4. *Other untracked wait.* **Speculative, 10%.**

Note the observable difference: under H1 the health log shows `presented`
flat **and** `menu/stage` flat (game thread spinning, not simulating) with
audio queued frames frozen; under H3 the game-side counters keep advancing.
The existing 10 s health line already captures all three signals
(`recomp_game_start.cpp:293-324`).

**Discriminating test**

Physical matrix, no new code required, using existing breadcrumbs
(`lifecycle`, `health`, `watchdog` events; the transient-inactive note at
`recomp_game_start.cpp:725-727`): during a live mission, (1) hardware
screenshot ×10; (2) Control Center pull-down and dismiss ×5; (3) app switcher
round-trip ×5; (4) full Home → relaunch ×3; (5) screenshot immediately
followed by backgrounding (the compound case most likely to catch an
in-flight acquisition). After each block, one bounded log readback. Expected
outcomes: a stall with `presented`, `menu/stage`, **and** audio-queued all
flat that recovers within seconds → H1 confirmed (spin backpressure — decide
whether the transient hitch is acceptable or worth an upstream condvar);
the same signature that never recovers → H2 (capture the fence-wait
breadcrumb below); game counters advancing while UI/input are dead → H3;
no stall in 40+ transitions → the mitigations hold and the matrix is the
acceptance evidence.

**Bounded instrumentation that would sharpen it** (only if the matrix
reproduces): a counter at Plume's nil-drawable branch (that `fprintf` at
`plume_metal.cpp:2062` goes to stderr, not the session log — route it through
the existing `goldenpad_recomp_note_*` pattern), and a
before/after-timestamp breadcrumb around the command-fence wait
(`plume_metal.cpp:3733`) so a permanently stuck fence is distinguishable
from repeated 1 s acquire timeouts. Both are change-triggered, no per-frame
cost.

**Smallest repair seam**: none proposed until the matrix produces a
reproduction; the tree's current posture (`.inactive` keeps presenting,
timeout-bounded acquisition, recover-by-resize upstream, barrier always
advancing) is the correct default. If H1's multi-second hitch is judged
unacceptable, the seam is upstream: converting `advanceToNextPresent`'s
busy-wait to a condition-variable wait (the barrier side already holds
`cursorMutex`) — a small, contained RT64 patch, but one that touches the
frozen present path and therefore needs the full multiplayer video gate.

**Regression gates**: `docs/TESTING.md:48-56` items 3–4 (screenshot/overlay
return without freeze), audio-session cycle acceptance
(`docs/TESTING.md:349-356`), unchanged save flush on backgrounding.

**Files and lines inspected**:
`Sources/RecompPrototypeApp.swift:117-173`;
`Sources/RecompPrototypeMetalCanvas.swift:41-204`;
`Sources/RecompPrototypeAudio.swift:30-78,142-156`;
`Support/RecompPrototype/recomp_game_start.cpp:246-353,696-731`;
`patches/goldeneye64recomp-ios-prototype-render-trace.patch:84-107`; upstream
at pins: `rt64_present_queue.cpp:25-105,295-410,440-535`,
`rt64_state.cpp:1838-1960` (`State::updateScreen`),
`rt64_application.cpp:512-516`, `plume_metal.cpp:1940-2090,3630-3740`.

### Issue 4 — Audible audio static

**Observed facts**

- Single-producer/single-consumer bounded stereo ring: 65,536 frames,
  1,024-frame scheduling reserve hidden from the game
  (`getFramesRemaining`, `recomp_game_start.cpp:419-425`), 32-frame fades on
  rebuffer, prime-at-1,024 (`goldenpad_recomp_audio_render`,
  `:871-930`). Stereo-pair swap for N64ModernRuntime's RDRAM ordering is in
  the producer (`:405-411`).
- Underrun accounting has one deliberate blind spot: the first shortfall
  after priming (`renderedBefore == 0`) is not counted (`:889-894`), and
  every prebuffer period is silence with no counter (`:879-887`). So a
  priming/starvation *cycle* can insert audible gaps while reporting zero
  underruns — a counter-invisible discontinuity class.
- `goldenpad_recomp_set_app_active(true)` discards stale frames and resets
  `audioPlaybackPrimed`/fade/`audioLastLeft/Right` — fields documented as
  consumer-thread-only (`:96-99`) — from the lifecycle thread (`:696-723`).
  Safe in the normal foreground order (engine paused first,
  `RecompPrototypeApp.swift:164-167` then `:155-157`), **unsafe** if
  `activate()` was re-entered by an interruption-ended or route-change
  notification while backgrounded (`Sources/RecompPrototypeAudio.swift:39-45,142-155`),
  leaving the engine running during the reset. A torn read of the read-cursor
  exchange there produces exactly a one-off click/garbage burst with no
  counter.
- The game's requested output rate is **ignored**: `setFrequency` only logs
  (`recomp_game_start.cpp:426-428`) while both hosts hard-code a 22,050 Hz
  source format (`Sources/RecompPrototypeAudio.swift:82-89`,
  `Sources/Mac/RecompMacAudio.swift:66-73`). The pinned reference host does
  the opposite: `set_frequency` stores the requested rate and rebuilds the
  SDL resampler from it (`sample_rate = freq; update_audio_converter()`,
  upstream `src/main/main.cpp:289-293`), and `get_frames_remaining` scales by
  that dynamic rate (`:255-278`). So ignoring the callback is a genuine
  divergence from the reference implementation, not a shared convention. The
  system self-clocks (the game schedules audio from `getFramesRemaining`), so
  a mismatch cannot drift unboundedly — the exposure is a constant small
  rate/pitch error, not accumulating gaps — but the actual requested value is
  not recorded anywhere in the repo, and prior diagnosis history (the
  stereo-swap defect, `docs/RT64_N64RECOMP_PROTOTYPE.md:272-277`) shows queue
  health cannot detect format-class defects.
- Two reference-host comparisons in GoldenPad's favor, established this pass:
  the reference host resamples **per chunk** and must duplicate four boundary
  frames per chunk to hide interpolation seams (`main.cpp:182-227`), a seam
  class GoldenPad's continuous ring + AVAudioEngine stream conversion avoids
  entirely; and the reference host's latency control decimates audio crudely
  under backlog (`skip_factor`, `main.cpp:236-249`), which GoldenPad replaces
  with counted ring-full drops. The stereo-pair swap is identical in both
  (`main.cpp:208-212` vs `recomp_game_start.cpp:405-411`). GoldenPad's
  1,024-frame reserve also exceeds the reference's ~2-VI (~735-frame)
  offset (`main.cpp:255-270`).
- The documented static diagnosis so far: consumer cadence jitter, mitigated
  by the reserve/prebuffer/fade design; final soak: 2.3 M+ frames, zero
  underruns (`docs/RT64_N64RECOMP_PROTOTYPE.md:264-274`). Mac's historical
  46,323-underrun runs were main-queue starvation, a distinct mechanism
  (`docs/TECH_DEBT.md:122-143`).

**Unknowns**

- The frequency GoldenEye actually requests (present in every session log as
  `audio: game requested %u Hz output` — retrievable without any new build).
- Whether reported mobile static coincides with route changes, thermal
  events, or logging — no session correlation exists in the repo.
- AVAudioEngine's pull-size distribution on device (bursty resampler pulls
  were the documented jitter source).

**Ranked hypotheses**

1. Real jitter/underrun events in sessions whose counters were never read
   (the zero-counter evidence covers *accepted* runs only). **Moderate,
   40%.** Includes the counter-invisible priming-cycle variant.
2. Lifecycle-thread mutation race on interruption/route-change while
   backgrounded (one-off clicks near transitions). **Low, 20%.**
3. Rebuffer fade transitions being audible as brief level dips (by design:
   fade-out + ≥46 ms silence + fade-in) perceived as "static" when frequent.
   **Low, 20%.** Would correlate with `audioUnderrunCallbacks` when counted.
4. Sample-rate/format mismatch against the hard-coded 22,050 Hz. **Low,
   10%** — self-clocking bounds it to a constant pitch error rather than
   static, but the reference host honors the callback and GoldenPad does
   not, so it remains the one unchecked assumption worth one log line to
   retire.
5. Integer-to-float or channel-layout defect. **Speculative, 5%** — the code
   is straightforward (`:919-921`) and channel order was already fixed.

**Discriminating test**

Step 0, zero cost: read existing device logs for the requested-Hz line and
counter trajectories in a session where static was heard. Step 1, no
copyrighted audio: a diagnostic flag that replaces `queueSamples` input with
a host-generated continuous sine; install a render tap on
`engine.mainMixerNode` that computes only a derivative-anomaly count
(discontinuities per minute) — no audio is recorded. Expected outcomes:
anomalies clustered at lifecycle/route events → H2; anomalies correlated
with `audioUnderrunCallbacks` → H1/H3; steady-state anomalies with clean
counters → H4/H5; zero anomalies → the static originates upstream of
`queueSamples` (game/RSP side), which redirects the investigation entirely.

**Smallest repair seam**

(a) Make the foreground reset consumer-owned: `set_app_active` sets one
atomic `audioResetRequested` flag; `goldenpad_recomp_audio_render` performs
the discard/unprime at its next entry. Removes the race on all platforms,
~10 lines, no behavior change in the common path. (b) Record and assert the
requested frequency (fail loudly on mismatch, or configure the source-node
format from it). Both are platform-shared and safe; anything cadence-related
(reserve size, fade length) should remain per-platform and evidence-gated.

**Regression gates**: zero drops/underruns over a repeat of the documented
soak; unchanged prebuffer behavior at cold start
(`docs/TESTING.md:699-711` PCM probe); physical-speaker listening remains the
final acceptance (`docs/RT64_N64RECOMP_PROTOTYPE.md:274-275`).

Diagnosis confidence 45% (multi-candidate by nature); confidence that seam
(a)+(b) plus the tap-driven follow-up resolves audible static without
regressing the baseline: 55%.

**Files and lines inspected**:
`Support/RecompPrototype/recomp_game_start.cpp:83-100,382-428,696-723,871-954`;
`Sources/RecompPrototypeAudio.swift` (complete);
`Sources/Mac/RecompMacAudio.swift` (complete);
`docs/RT64_N64RECOMP_PROTOTYPE.md:262-277`; `docs/TECH_DEBT.md:122-143`;
upstream reference host `src/main/main.cpp:180-320` at the
GoldenEye64Recomp pin.

### Issue 5 — Stage-specific geometry faults and the thin blue render edge

**Observed facts**

- iOS previously had the same class of artifact: pixel inspection measured it
  as **exactly two physical pixels** at the far edge and it is masked by a
  one-point opaque host overlay without changing RT64's drawable or viewport
  (`docs/RT64_N64RECOMP_PROTOTYPE.md:290-295`;
  `Sources/RecompPrototypeApp.swift:78-85`). iOS also switched the MTKView
  clear color from blue to black specifically because the seam exposed the
  host clear (`Sources/RecompPrototypeMetalCanvas.swift:170-174`).
- The Mac host has no equivalent mask (`Sources/Mac/GoldenPadMacApp.swift:65-88`),
  though its clear/background colors are already black
  (`Sources/Mac/RecompMacMetalCanvas.swift:179,192-195`).
- The Mac pixel-size pipeline has a rounding boundary: Plume derives window
  size as `round(contentFrame.size * backingScaleFactor)`
  (`patches/plume-ios-metal.patch:47-73`) and sizes the layer's
  `drawableSize` from it (`plume_metal.cpp:1994-2014` at the pin), while the
  host view also has `autoResizeDrawable = true`
  (`Sources/Mac/RecompMacMetalCanvas.swift:181`) — two writers of
  `drawableSize` whose values can disagree by one pixel for fractional
  layout widths.
- Substituting `CAMetalLayer.drawableSize` for the window-size contract
  expanded the strip into severe missing/duplicated/blue world geometry and
  was rejected (`docs/TECH_DEBT.md:80-110`, `docs/STATUS.md:57-66`) — strong
  evidence that the strip lives at the size-contract boundary, and equally
  strong evidence that the contract must not be touched.
- Stage-specific reports are not reduced to deterministic camera positions
  (`docs/STATUS.md:595-596`), and RT64 validation explicitly leaves sky,
  water, framebuffer-dependent glass, monitors, and later-stage effects as
  open gates (`docs/RT64_N64RECOMP_PROTOTYPE.md:117-121,137`).

**Unknowns**

- The Mac strip's exact pixel width (never measured the way iOS's was).
- Whether any reported stage geometry fault reproduces deterministically;
  none has a recorded camera position/settings tuple.

**Ranked hypotheses (edge)**

1. Presentation-boundary coverage/rounding seam — the final VI blit's edge
   texels sampling clamped framebuffer content (blue = sky/fog), same family
   as the measured iOS seam. **High–Moderate, 70%.**
2. Game clear-color showing through a host coverage gap. **Low, 15%** — both
   host layers are already black, and the strip is blue.
3. Viewport/scissor convention inside RT64. **Low, 10%** — would have shown
   on iOS beyond 2 px and in the drawable-size experiment in a different
   shape.

**Discriminating test**

Screenshot Dam and Surface at a fixed camera on Mac; count the strip's exact
pixel width at 1× and at a fractionally-resized window. Width constant at
1–2 px regardless of content → H1; width scaling with resolution mode →
RT64-internal (H3); strip color tracking the current sky/fog color → confirms
sampled-content origin (H1) over host clear (H2).

**Smallest repair seam**

The iOS-precedented mask: a trailing-edge one-point opaque overlay in the
`GoldenPadMacApp` ZStack (mirror of `Sources/RecompPrototypeApp.swift:81-85`).
Additive, hit-test-disabled, no RT64/Plume change, trivially reversible. Fix
confidence 75% for masking the symptom (it is a mask, not a root-cause
repair — the honest framing the iOS side already uses). If the measured strip
is wider than ~2 px, stop and re-diagnose rather than widening the mask.

**Geometry-fault triage** (which symptoms are the same defect): the
edge strip and the rejected experiment's severe corruption are the same
*boundary* (size contract) at different severities. Stage-specific clipping/
missing geometry is **probably not** — the documented unvalidated-effects
list and GoldenEye's own culling/portal behavior are the likelier lanes. The
diagnosable next step is process, not code: a fixed checkpoint matrix —
per report, record stage, camera (the health log already emits position/yaw/
pitch, `recomp_game_start.cpp:293-324`), resolution mode, MSAA, and
three-point filtering; reproduce at Native N64 with MSAA off to split
"original behavior" from "RT64/scaling behavior". Input-only changes must
leave Dam/Surface captures byte-comparable (`docs/TECH_DEBT.md:111-117`).

**Regression gates**: the native macOS gate items 1–4
(`docs/TESTING.md:102-131`), Dam/Surface comparison against the accepted
capture, unchanged iOS mask behavior.

**Files and lines inspected**:
`Sources/RecompPrototypeApp.swift:62-91`;
`Sources/RecompPrototypeMetalCanvas.swift:164-183`;
`Sources/Mac/RecompMacMetalCanvas.swift:165-220`;
`Sources/Mac/GoldenPadMacApp.swift:63-115`;
`patches/plume-ios-metal.patch:39-111`; upstream `plume_metal.cpp:1994-2050`;
`docs/TECH_DEBT.md:36-143`.

### Issue 6 — Mac Alpha input feel and sustained performance

**Observed facts**

- The complete mouse-look path is: `NSView` delta events → `pendingMouseDelta`
  accumulation (`Sources/Mac/RecompMacInput.swift:246-257`) → per-60 Hz-tick
  scale by `1_680 × sensitivity` (default 2.5, max 6.0), clamp to ±32,767,
  queue (`:496-506`) → core accumulation clamped to ±32,767
  (`recomp_game_start.cpp:167-173,742-749`) → per-game-frame consumption
  normalized by 32,767 and **clamped to [-1, 1]**
  (`recomp_get_camera_inputs`, `:825-832`) → game-side patch applies
  `lookX × 3°` per frame (1° while aiming)
  (`patches/goldeneye64recomp-ios-modern-controls.patch:86-89,109`).
- Therefore the maximum camera rate is ~3°/game-frame hip-fire and
  1°/game-frame aiming, **regardless of physical mouse speed or the
  sensitivity setting**. The recomp game loop targets **30 FPS**
  (`static int desiredFPS = 30`, `frameSkipInterval = 60/30`, upstream
  `workbench_theboy.c:455-469`; `InitFrameRateControl()` called at
  `bossMainloop` start, `:534`), so the ceiling is **~90°/s hip-fire and
  ~30°/s aiming** — an order of magnitude below ordinary desktop FPS turn
  rates, and frame-rate-coupled by construction.
- Worse than a ceiling: because the *queue itself* clamps its accumulated
  value to ±32,767 (`queueClampedAxis`, `recomp_game_start.cpp:167-173`) —
  exactly one game frame of full deflection — mouse travel beyond the
  saturation point between game-frame consumptions is **discarded, not
  deferred**. A fast flick loses most of its rotation. And since the host
  multiplies deltas by `1_680 × sensitivity` *before* queueing
  (`Sources/Mac/RecompMacInput.swift:496-506`), raising the sensitivity
  slider lowers the physical speed at which discarding begins: at the 2.5
  default, saturation is ≈ 7.8 event-pixels per game frame (~235 px/s); at
  the 6.0 maximum, ≈ 3.3 pixels (~98 px/s). This precisely reproduces the
  reported feel — slow, and the slider does not fix it.
- Additional clamps/dead zones on this path: none for the mouse (the 0.15
  radial dead zone and 1.5 response curve apply only to a physical right
  stick, `:406-408`; the controller-vs-touch scale split is core-side,
  `recomp_game_start.cpp:820-830`). So the cause is not stacked dead zones.
- The main-queue starvation cluster was root-caused to Plume's per-present
  window/refresh dispatches, and the retained patch coalesces each kind to
  one pending block via CAS flags
  (`patches/plume-macos-main-queue-coalescing.patch`). The two per-frame
  request kinds are bounded; the remaining unbounded dispatch,
  `toggleFullscreen`, is user-initiated and rare (upstream
  `plume_apple.mm`).
- Mac keeps a 10 s monitor cadence to limit observer effect
  (`recomp_game_start.cpp:345-351`); Mac quit bypasses runtime teardown by
  design (`goldenpad_recomp_stop_game`, `:956-966`).

**Unknowns**

- Whether GoldenEye applies any additional smoothing to `vv_theta` deltas of
  this size (the patch writes angles directly then calls
  `bondviewApplyVertaTheta`; behavior for larger per-frame steps is untested).
- The *achieved* Mac frame rate under load (the 30 FPS target is by
  construction; sustained dips would lower the ceiling further).

**Ranked hypotheses (why mouse feels slow)**

1. Camera-rate saturation plus fast-motion truncation at the double-clamped
   seam, at 30 game-frames/s (arithmetic above). **High, 92% — entailed by
   the inspected code**; the residual covers only perceptual factors beyond
   the rate cap.
2. Event-delivery latency (main-queue congestion). **Low, 5%** — the
   coalescing patch removed the congestion source, and delivery latency
   cannot explain a *rate* ceiling.
3. Game-side consumption smoothing. **Speculative, 3%.**

**Measurement separating delivery latency from gain**: log, per publish tick,
the host's pending-delta magnitude before queueing, and (sampled, e.g. every
60th frame) the consumed post-clamp value inside `recomp_get_camera_inputs`.
Saturation (consumed pinned at ±1.0 while pending grows) → gain ceiling;
pending arriving late/bunched → delivery. The existing health line already
carries the absolute right-stick values (`:307-310`) but **not** the queued
relative look — that one sampled log line is the missing instrument.

**Can sensitivity be improved solely at the accepted relative-delta seam?**
Yes, but the repair must widen **both** clamps, and both live in
project-owned host code (not generated), inside the accepted boundary (no
player-struct writes, no event monitor):

1. the queue accumulation clamp in `queueClampedAxis`
   (`recomp_game_start.cpp:167-173`) — otherwise the queue can never hold
   more than one frame of deflection and fast motion keeps being discarded;
2. the consume-side `[-1, 1]` clamp for the queued-delta term in
   `recomp_get_camera_inputs` (`recomp_game_start.cpp:824-832`) — e.g. allow
   the queued component into ±3 under `GOLDENPAD_RECOMP_MAC`, so the game
   patch's 3°/frame multiplier acts on a >1 magnitude and a fast flick
   yields proportionally more rotation per frame while a physical stick's
   behavior is untouched.

Risk: verify GoldenEye tolerates larger per-frame `vv_theta` steps
(interpolation/aim-assist artifacts); the prototype notes RT64 interpolation
guards for teleport rotations exist
(`docs/RT64_N64RECOMP_PROTOTYPE.md:96-99`). Diagnosis 92%;
fix-resolves-feel-without-regression 70%. iPhone/iPad must be excluded from
the change — the same two functions serve the accepted touch tuning, whose
1.5× swipe gain and 4× sensitivity were tuned against these exact clamps.

**Coalescing verification with low observer effect**: add one atomic counter
incremented when the CAS in each coalesced path finds an update already
pending (i.e., a request was absorbed), sampled by the existing 10 s Mac
monitor line; plus measure the 60 Hz input Timer's actual interval drift
(main-queue health proxy) in the same line. No streaming, no profiler.

**Minimum sustained acceptance run** (Alpha promotion, not mobile parity):
one ≥30-minute continuous mission session, no QuickTime/profiler/streaming,
followed by a single bounded log readback requiring: monotonic even VI/present
progression (no interval below ~50% of the session median), zero rising
audio-underrun counters, absorbed-request counter stable (not growing per
present), and hands-on confirmation that input latency at minute 30 matches
minute 1 — exactly the `docs/TESTING.md:127-136` items 6–7 made quantitative.

**Regression gates**: the macOS gate items 1–5 (`docs/TESTING.md:104-131`) —
menu directions, capture/release, Dam/Surface geometry unchanged, bindings
persistence; the do-not-do list below.

**Files and lines inspected**:
`Sources/Mac/RecompMacInput.swift` (complete);
`Sources/Mac/GoldenPadMacApp.swift` (complete);
`Support/RecompPrototype/recomp_game_start.cpp:167-173,742-749,781-848`;
`patches/goldeneye64recomp-ios-modern-controls.patch` (complete);
`patches/plume-macos-main-queue-coalescing.patch` (complete);
`docs/TECH_DEBT.md:75-143`; `docs/TESTING.md:102-148`; upstream
`patches/workbench_theboy.c:455-540` (frame-rate control) at the
GoldenEye64Recomp pin.

### Issue 7 — Secondary completeness gaps

| Item | Classification | Basis |
| --- | --- | --- |
| First-install ROM importer coverage (wrong revision, cancel, interruption, low storage, both devices) | **Release-hardening item** (with product-defect potential in the untested negative paths) | The importer's state machine is designed to leave the prior destination untouched on any failure (`docs/PREVIEW_2_ROM_IMPORT.md:36-45`), and the happy path plus byte-order fixtures are verified; the unchecked boxes (`:61-65`) are acceptance work, not known defects. |
| Clean shutdown and session-marker semantics | **Release-hardening item; semantics are sound with one documented edge** | Marker created on foreground, removed on real background (`recomp_game_start.cpp:151-165,710-717`), so background jetsam kills correctly read as clean and active-session crashes are flagged. Edge: a crash while `.inactive` (screenshot moment) is flagged (marker present) — correct. Mac's `_Exit` path marks clean first (`:956-966`). No repair owed; document the semantics. |
| Six anonymous `/private/tmp/goldenpad-recomp.*` compiler literals | **Reproducibility/hardening limitation, not a product defect** | Verifier allowlists exactly these patterns and rejects user paths (`docs/STATUS.md:600-603`); removal requires archive rebuilds (`docs/TECH_DEBT.md:26-28`). |
| Direct numeric weapon selection on Mac | **Product feature gap requiring a game-side contract — research item** | The bridge exposes weapon cycling only; number-key behavior must not be fabricated without a stable inventory-slot contract (`docs/TECH_DEBT.md:117-120`). Number keys are already bindable (`Sources/Mac/RecompMacInput.swift:46-47`), so the host side is ready when a contract exists. |
| Oldest-supported macOS testing and notarization | **Policy/distribution task** | Explicit future gates (`docs/TECH_DEBT.md:58-60`); no code evidence of an OS-version hazard was found in the Mac host sources. |
| Private generated-AOT pipeline vs public reproducibility | **Reproducibility limitation by policy, partially mitigated** | Intentional boundary (`README.md:219-245`); the CMake content-marker guards (`CMakeLists.txt:279-330`) are the existing mitigation against the known mismatched-patch failure class. The residual risk is that markers check presence, not pairing — the `IS_NEWER_THAN` timestamp guards (`:313-330`) cover the pairing half. Adequate; no action beyond keeping both guards. |

---

## 5. Cross-issue causal map

**One confirmed shared-cause cluster (Mac, historical):** growing input
latency + audio underruns + effective freeze were one fault — unbounded
per-present dispatch onto AppKit's main queue starving keyboard, mouse, and
host timers (`docs/TECH_DEBT.md:131-143`). The coalescing patch addresses the
mechanism at its source. These were *not* three independent defects.

**Why that cluster generalizes (both platforms):** input publication is a
main-run-loop timer on iOS and Mac
(`Sources/RecompPrototypeInput.swift:182-185`,
`Sources/Mac/RecompMacInput.swift:217-221`), audio *control* (not rendering)
is main-thread, and SwiftUI status flows are main-thread. Any main-thread
stall therefore presents simultaneously as input lag, delayed lifecycle
response, and (on Mac, where timers gate the queue-feeding) audio symptoms.
This is a legitimate single point of coupling to keep instrumented (the
timer-drift measure in Issue 6), but there is **no evidence** it is currently
misbehaving on iOS.

**Independent faults:** the multiplayer flicker (game-patch/RT64 state
domain), the audio ring's counter-blind discontinuity classes (consumer
thread domain), and the blue edge (presentation-boundary geometry) share no
mechanism with each other or with the queue cluster. The screenshot-freeze
history is probably the drawable/lifecycle domain, with the main-thread
coupling as its secondary suspect — the Issue 3 matrix separates them
(presented-counter flat vs input-timer starved leave different log
signatures).

**Renderer timing vs audio (revised):** the audio *consumer* is independent
of presentation (`AVAudioSourceNode` render thread vs the `update_screen`
gate), but the audio *producer* is not — audio chunks are generated on the
game-side thread cadence, and that thread busy-spins in
`PresentQueue::advanceToNextPresent` when the present ring backs up
(`rt64_present_queue.cpp:38-55`). So drawable throttling stalls video and
audio **together through the game thread**, which is a second legitimate
coupling point alongside the host main-thread timers. Zero audio drops during
the 54,652-VI multiplayer soak shows this coupling is quiescent in normal
play; it activates only under presentation backpressure (screenshot/overlay
windows), which is exactly when the freeze symptom was reported.

---

## 6. Recommended sequence

1. **Read existing device session logs** for `game requested %u Hz`,
   underrun/drop trajectories, and lifecycle breadcrumbs from any session
   with reported static or a freeze. Info gain: high (discriminates Issue 4
   H1/H4 and Issue 3 H1 for free). Size **XS** (no code). Risk: none.
   Rollback: n/a. Acceptance evidence: the log lines themselves.
2. **Mac blue-edge mask** — one-point trailing-edge opaque overlay in
   `GoldenPadMacApp`, mirroring `RecompPrototypeApp.swift:81-85`, after
   measuring the strip width per Issue 5's test. Info gain: medium
   (width/color measurement doubles as diagnosis). Size **XS**. Risk: very
   low. Rollback: revert the overlay. Acceptance: Dam/Surface fixed-camera
   captures show no strip and no other change.
3. **Physical lifecycle matrix** (Issue 3) on the current build with existing
   breadcrumbs; 40+ scripted transitions, bounded post-run readback. Info
   gain: high (either closes the freeze or yields the first current-build
   reproduction). Size **XS** (procedure only). Risk: none. Acceptance: the
   matrix log, per `docs/TESTING.md:48-56` item 4.
4. **Depth-resync counter build** (Issue 1, Stage 1): one atomic counter
   where `depthImg.formatChanged` forces the depth clear-and-re-read
   (`rt64_state.cpp:1405-1435` region of the embedded RT64 build), surfaced
   through the existing `goldenpad_recomp_note_*` pattern and the 10 s
   health line; run one multiplayer and one single-player session. Info
   gain: very high (a per-frame nonzero count in multiplayer with zero in
   single player confirms the aliased-depth churn as real; zero kills the
   leading hypothesis outright). Size **S** (RT64-side one-liner in the
   embedded archive rebuild; no game-patch regeneration). Risk: low —
   counting only, frozen repair untouched. Rollback: rebuild without the
   counter. Acceptance: the counter values plus the standard 30 s video for
   timestamp correlation.
5. **Fixed-render-order multiplayer probe build** (Issue 1, Stage 2):
   one-line diagnostic at the `shuffle_player_ids()` /
   `get_nth_player_from_shuffled(i)` seam (upstream
   `workbench_theboy.c:692-696`, already inside the patched `bossMainloop`);
   repeat the 30 s two- and four-player physical video gate. Info gain: high
   (under H1, flicker becomes position-stable; disappearance promotes the
   state-leak hypothesis instead — then follow with the player-tagged
   `send_dl` trace at the existing seam,
   `patches/goldeneye64recomp-ios-prototype-render-trace.patch:71-83`).
   Size **S** (requires the matched patch-pair regeneration; the CMake
   marker/timestamp guards cover the known failure mode). Risk: low
   (diagnostic build, never shipped). Rollback: rebuild from the frozen
   patch pair. Acceptance: video per `docs/TESTING.md:90-101` plus a
   flicker-position verdict.
6. **Audio consumer-owned reset + frequency assert** (Issue 4 seams a+b):
   atomic reset flag consumed in `goldenpad_recomp_audio_render`; record and
   assert the `setFrequency` value (the reference host honors it — parity
   argument, upstream `main.cpp:289-293`). Info gain: medium (removes a race
   class; verifies an assumption). Size **S**. Risk: low; platform-shared.
   Rollback: revert two small hunks. Acceptance: soak with zero counters +
   unchanged cold-start PCM probe (`docs/TESTING.md:699-711`).
7. **Touch-ownership leak fix + synthetic controller lifecycle probe**
   (Issue 2): on test-mode collapse from disconnect, publish neutral to
   port 0 instead of falling through to the touch branch until the user
   re-confirms; land the `GCVirtualController` probe with the five-step
   assertions. Info gain: high (turns Issue 2's invariants into a repeatable
   gate). Size **S**. Risk: medium-low (touches the accepted P1 path; gated
   by existing `--input-probe`). Rollback: revert the publish-branch change.
   Acceptance: probe PASS lines + unchanged single-controller physical feel.
8. **Mac mouse widening at both relative-delta clamps** (Issue 6),
   Mac-gated: widen the queue accumulation clamp
   (`recomp_game_start.cpp:167-173`) and the consume-side queued-delta clamp
   (`:824-832`) together, after the sampled consumed-look instrument
   confirms saturation. Info gain: medium (the instrument is itself the
   confirmation). Size **S**. Risk: medium (per-frame angle steps larger
   than tuned values); gated by the full macOS input/render gate
   (`docs/TESTING.md:104-131`) with Dam/Surface capture comparison.
   Rollback: both changes behind `GOLDENPAD_RECOMP_MAC`. Acceptance:
   hands-on feel pass + unchanged geometry captures + no aim-assist
   artifacts.

Real three/four-controller *implementation* (the slot model) is deliberately
after this list: it is the largest change, it depends on step 7's probe
existing first, and nothing in the frozen baseline degrades while it waits.

---

## 7. Do-not-do list

Restated from the repository's own rejected-approach record, with the
source-level reason each stays rejected:

- **Do not reopen the depth-address alias repair** (`widescreen.c`
  `zbufClearCurrentPlayer` hunk) without the two-condition evidence bar in
  Issue 1. It is the fix that ended the black/checkerboard corruption on
  physical iPad (`docs/TECH_DEBT.md:162-171`); the residual flicker has no
  evidence trail into it.
- **Do not replace RT64's window-size contract with
  `CAMetalLayer.drawableSize`** on any platform. The experiment converted a
  1–2 px seam into severe missing/duplicated/blue geometry
  (`docs/TECH_DEBT.md:80-88`); the pinned swap chain sizes its drawables from
  the window contract (`plume_metal.cpp:1994-2014`), so substituting the
  drawable size creates a feedback loop between two writers of the same
  property.
- **Do not write undocumented player/camera structures from the host.** The
  accepted seam is `recomp_get_camera_inputs` +
  `goldenpad_recomp_consume_crouch_toggle` consumed by the game-side patch
  (`docs/TECH_DEBT.md:89-96`); direct writes broke input and were disproved
  as a diagnosis by the retained 21:16:44 control build.
- **Do not regenerate only one half of the embedded patch pair.** A
  mismatched `patches.c`/`patches_bin.c` produces a black-screen artifact
  with host producers and no game-side consumer
  (`docs/TECH_DEBT.md:92-103`); the CMake presence markers
  (`CMakeLists.txt:293-312`) and timestamp guards (`:313-330`) exist to make
  this fail at configure time — keep both.
- **Do not remove or weaken the Plume main-queue coalescing bound**, and do
  not reintroduce any unbounded per-frame dispatch to AppKit's main queue
  (`docs/TECH_DEBT.md:131-143`) — the starvation cluster it caused presented
  as three separate defects.
- **Do not replace the Metal view's input callbacks with an app-local event
  monitor** to compensate for missing look input; that diagnosis was
  disproved (`docs/TECH_DEBT.md:104-107`, `docs/TESTING.md:113-119`).
- **Do not treat build success, a live PID, Simulator stability, log
  counters, or a still screenshot as acceptance** for temporal faults —
  the repository's own gates require video/continuous evidence
  (`docs/TESTING.md:96-101,117-131`), and this review's audio analysis shows
  two discontinuity classes the counters cannot see.
- **Do not restore multiplayer visual/LOD/effect budgets** as part of any
  flicker or routing fix (`docs/MULTIPLAYER_ROADMAP.md:90-110`), and do not
  bundle networking into anything (`:111-115`).

---

## 8. Final certainty statement

**Fixable with high confidence now:**

- The Mac mouse-look defect — the 30 FPS × 3°/frame ceiling and the
  queue-saturation truncation are entailed by the inspected code (diagnosis
  ~92%), and a Mac-gated widening of the two project-owned clamps is a
  contained change (fix ~70%, the residual being GoldenEye's tolerance of
  larger per-frame angle steps).
- The touch-to-Player-1 leak on controller disconnect during the two-player
  test — confirmed from source; the neutral-fallback fix is small and
  probe-gated.
- The Mac blue edge as a *symptom* — the one-point mask has an accepted iOS
  precedent and adds no renderer risk (~75%), while honestly leaving the
  underlying rounding seam diagnosed-but-unrepaired, exactly as iOS does.

**Likely explainable, needing one discriminating test first:**

- The residual multiplayer flicker — the aliased-depth churn chain is now
  fully source-verified except its final perceptual link, and the one-line
  depth-resync counter settles that link cheaply. Note the asymmetry: this
  is "likely *diagnosable*", not "likely quickly fixable" — if confirmed,
  the repair is RT64-side aliased-depth recognition, which is real surgery
  and should be weighed against the symptom's low severity. The depth-alias
  clear repair stays frozen under every branch.
- The screenshot/resume "freeze" — the busy-spin backpressure mechanism
  explains a recoverable multi-second stall entirely from pinned code; the
  lifecycle matrix plus two breadcrumbs distinguish it from the (much less
  likely) permanent fence-wait freeze.
- Audible static — the requested-Hz log readback plus the synthetic-sine tap
  will either implicate the two identified counter-blind classes (both have
  small, safe seams) or redirect the investigation upstream of the ring.

**Genuinely unknown:**

- Whether the depth RAM round-trip is visually perceptible as the reported
  flicker (versus being only a hidden performance tax with the flicker
  living elsewhere) — the single most leveraged unknown in the review, and
  the cheapest to resolve.
- Whether any reported stage-geometry fault is a GoldenPad defect at all, as
  opposed to original culling/portal behavior or a documented unvalidated
  RT64 effect — no report is currently reproducible.
- GoldenEye's in-match behavior when advertised controller ports vanish —
  the key unknown gating the multi-controller design.
- Whether a hard (non-recovering) freeze exists at all in the current build,
  as opposed to the recoverable stall — only the physical matrix can say.

**Most valuable next artifact:** the bounded application-log readback from a
physical session in which a user actually hears static or hits a freeze —
the counters, requested-Hz line, and lifecycle breadcrumbs needed to close
Issues 3 and 4 already exist in the shipped binary and have simply never been
collected from a failing session. Second: one multiplayer session's
depth-resync counter reading, which either confirms or kills the leading
flicker mechanism. Both cost near-zero engineering and each resolves the
largest open branch of its issue.

---

## 9. Revision log (second pass)

Changes from the first pass of this review, after reading the pinned
GoldenEye64Recomp, RT64 and Plume sources in depth:

1. **Issue 1 — leading diagnosis replaced.** First pass ranked an
   order-dependent render-state leak (40%) above an RT64 framebuffer
   transient (30%) on circumstantial grounds. Second pass established a
   complete code chain for a specific RT64-side mechanism — overlapping
   aliased depth framebuffers, mutual `rdramChanged` invalidation
   (`rt64_framebuffer_manager.cpp:905-916`), and a forced per-frame
   quantized depth re-read (`rt64_state.cpp:1405-1435,1458-1479`) — that
   uniquely matches all three observed properties (multiplayer-only, slight,
   order-migrating). It is now leading at 50%, with the state leak demoted
   to 25% (its global-alignment variant is affirmatively ruled out: no
   `gEXSetRectAlign`/`gEXSetScissorAlign` exists in any patch source). The
   recommended first probe changed from the fixed-order build to a one-line
   depth-resync counter; the fixed-order build became Stage 2 with revised
   predictions. The repair-seam assessment worsened honestly: if confirmed,
   no small fix exists. The `clearDepthOnly` fast-path source
   (`rt64_state.cpp:571-576`) also upgraded the depth-alias repair's
   correctness from documented to source-confirmed, and the alias
   arithmetic (120 rows × 640 bytes) was verified against `externs.h`.
2. **Issue 3 — from "no identified mechanism" to a specific bounded one.**
   First pass said the current tree has no identified stuck wait. Second
   pass found `PresentQueue::advanceToNextPresent` is an unbounded
   busy-spin on the game thread (`rt64_present_queue.cpp:38-55`), which
   under drawable throttling produces a recoverable multi-second
   simulation+audio stall — a mechanism for the reported symptom requiring
   no bug anywhere. The barrier was also verified to advance on failed
   acquires (`:514-529`), and the single truly unbounded wait was isolated
   to the command-fence `dispatch_semaphore_wait(FOREVER)`
   (`plume_metal.cpp:3733`). Hypotheses, expected matrix outcomes, and the
   instrumentation plan were rewritten accordingly; the cross-issue causal
   map's "presentation and audio are independent" claim was corrected (they
   couple through the game thread under backpressure).
3. **Issue 6 — strengthened and corrected.** First pass assumed up to 60
   game fps (ceiling "180°/s"). The pinned `bossMainloop` targets 30 FPS
   (`workbench_theboy.c:455-469`), halving the ceiling to ~90°/s hip /
   ~30°/s aim. Second pass also established that the *queue* clamp discards
   (rather than defers) fast motion and that raising sensitivity lowers the
   discard threshold — explaining why the slider does not help. Diagnosis
   85% → 92%; the repair seam was corrected to require widening **both**
   clamps, not just the consume-side one.
4. **Issue 4 — one assumption hardened into a divergence.** The pinned
   reference host honors `set_frequency` and rebuilds its resampler from it
   (`main.cpp:289-293`); GoldenPad ignores it. Also recorded two points
   where GoldenPad's ring design is stronger than the reference host
   (no per-chunk resampling seams; counted drops instead of crude
   decimation), which narrows the plausible static causes.
5. **Issues 2, 5, 7 — unchanged** by the second pass; no new evidence
   contradicted them.
