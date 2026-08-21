# Technical debt and upstream watch

Updated: 2026-08-22

This document records upstream changes that can materially improve GoldenPad,
the evidence required before adopting them, and the known debt that should be
retested when those changes land. It is an upgrade ledger, not a mandate to
replace working foundations whenever an upstream percentage changes.

## Current decision

Keep the statically recompiled GoldenEye + N64ModernRuntime + RT64/Metal target
as GoldenPad's primary iPhone/iPad runtime. Keep exact MGB64 pin
`cd9b58f5f91291579b8e551aa925aab000d311cf` buildable as `GoldenPad Legacy` for
regression comparison and fallback, not as the release product.

The current preview line deliberately leaves the following primary-runtime
debt visible:

- local multiplayer has a physically coherent experimental baseline, but slight
  lighting flicker and real three/four-controller routing remain open;
- Preview 2 has the bounded in-app retail conversion flow, but its exact final
  first-run path still needs hands-on acceptance on both iPhone and iPad;
- occasional audio static and stage-specific geometry faults need precise
  reproduction and bounded fixes;
- six anonymous `/private/tmp/goldenpad-recomp.*` compiler source literals
  remain in the executable; the package verifier rejects private `/Users/`
  paths and any unexpected temporary path;
- longer thermal, audio-route, screenshot/resume and multi-controller sweeps
  remain post-preview quality work.

Do not regress the accepted single-player speed, high-resolution renderer,
touch tuning, controller mapping, save compatibility, or clean-install defaults
while addressing that debt.

## macOS alpha disposition — 2026-08-21

The native Apple-Silicon Mac product is retained as an **alpha**, one quality
tier below the accepted iPhone/iPad single-player experience. The current
packaged-source artifact is an arm64 `GoldenPad.app` whose product, bundle display
name and executable are all `GoldenPad`; its executable SHA-256 is
`7c78b72f4d6fd1697a5fb0572dfe22de6a8680d7df784ceb0752ef7b9527c35d`.
Hands-on review reached real gameplay and found the current build stable enough
to preserve as the Mac alpha baseline, after which the user intentionally quit
the app. That is alpha acceptance, not sustained-performance or release-parity
evidence.

The remaining Mac alpha debt is explicit:

- mouse look works but remains too slow and the keyboard/mouse experience is
  less natural than touch or controller input; the persisted sensitivity range
  needs a later hands-on tuning pass;
- a thin blue strip remains at the far-right render edge;
- the Mac build performs below the iPhone/iPad versions, and prior iterations
  have staggered or frozen under load, so sustained gameplay still needs a
  bounded acceptance pass without screen recording or continuous diagnostics;
- direct numeric weapon selection and accepted Mac multiplayer assignment are
  not implemented; and
- the separate arm64 Alpha archive is package-audited, while
  oldest-supported-OS testing and notarization remain future gates.

Freeze the accepted renderer/input boundary for the coordinated release. Do not
try to remove the thin blue edge by changing RT64's window-size contract, and do
not rewrite camera/player fields to make mouse input feel more desktop-like.
Those experiments caused much worse world-geometry and control regressions. A
later Mac-only repair must reproduce the thin edge, preserve Dam/Surface scene
geometry, and pass the full input/render gate before replacing this baseline.

Preview 2 is one coordinated source baseline, not one cross-platform binary.
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
`RecompiledPatches/patches.c` calls both `recomp_get_camera_inputs` and
`goldenpad_recomp_consume_crouch_toggle`. Treat either missing call as a failed
build. Do not replace the accepted view callbacks with an app-local event
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
interaction and rendering gates. Direct numeric weapon selection remains open;
GoldenEye's current bridge exposes weapon cycling, not stable inventory-slot
selection, so number-key behavior must not be fabricated without a game-side
contract.

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

The immediate Preview 2 blocker is stable two-player local multiplayer on iOS
and iPadOS. Source tracing found full-frame render-target, sky, scissor, fade and
depth-clear assumptions in the current GoldenEye64Recomp patches even though
GoldenEye renders each player sequentially into a shared framebuffer. Repair and
physically accept that path before expanding multiplayer scope.

The first physical viewport-scoping candidate did not remove the temporal
corruption. A bounded iPad recording showed the black/checkerboard region
recovering and migrating between lower player views while presentation and all
four player passes continued. The current follow-up candidate targets a deeper
N64-to-RT64 ownership mismatch: GoldenEye shifts the lower players' depth-image
base by one logical screen and relies on address/Y aliasing, whereas RT64's
fill-only depth-clear fast path requires the clear address to exactly equal the
following depth-image address. The candidate now clears lower players through
that same shifted address and their original viewport Y range. Do not mark this
debt resolved until physical two-player and four-player video remains clean;
Simulator-only stability is not acceptance.

The physical four-player retest of executable SHA-256
`0976dcdfd17de60beda8e8e60ccff3fc81da7da0b2ef43f159cdea061149677d`
removed the former large black/checkerboard corruption and establishes the
stable experimental Preview 2 baseline. Slight lighting flicker remains as a
separate, lower-severity debt item. Preserve this exact build and do not reopen
the successful depth-alias repair speculatively unless the large corruption
returns or a bounded lighting-state defect is identified.

The four-port neutral render diagnostic now exists on iOS/iPadOS, but physical
iPad testing with real three/four-controller routing and a macOS assignment
remain open. Multiplayer LOD/effects restoration and network research are
specified in
[`MULTIPLAYER_ROADMAP.md`](MULTIPLAYER_ROADMAP.md). They must not be bundled into
the first two-player rendering repair. In particular, do not assume RT64's higher
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
| [akratch/mgb64](https://github.com/akratch/mgb64) | Active game core, Fast3D/Metal renderer, native port services | New commits/releases; decomp imports; renderer, texture-cache, audio, timing, or portability changes | Evaluate first. Update the pin only after all gates pass. |
| [goldeneye_src](https://gitlab.com/kholdfuzion/goldeneye_src) and [status tracker](https://kholdfuzion.github.io/goldeneyestatus/) | Exact game-code/parity reference feeding MGB64 | Post-completion corrections and changes touching known fidelity items | Use as a targeted oracle; preserve provenance and never bulk-import it. |
| [n64decomp/007](https://github.com/n64decomp/007) | Public decomp reference | Mirror synchronization and relevant source history | Reference only; preserve provenance and license review. |
| [GoldenRecomp](https://github.com/kholdfuzion/GoldenRecomp) | Static-recomp architecture reference | Public TLB-free ELF/ROM recipe, generated functions, or complete metadata | Reconsider only when a clean public pipeline is reproducible. |
| [N64Recomp](https://github.com/N64Recomp/N64Recomp) and [N64ModernRuntime](https://github.com/N64Recomp/N64ModernRuntime) | Translator/runtime reference | Metadata compatibility and portable runtime improvements | Pin and test only as part of a reproducible GoldenRecomp path. |
| [RT64](https://github.com/rt64/rt64) and its Plume backend | Verified alternative renderer reference | iOS/Metal improvements, texture-pack behavior, shader or backend changes | Do not carry two production renderers; reconsider only for a demonstrated MGB64 blocker. |

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

## Open debt after this review

- Wait for a public MGB64 engine update; there is no new production pin to adopt
  today.
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
