# Research

Last reconciled: 2026-08-22. Upstream source checkouts live under ignored
reference or temporary directories and are never copied wholesale into the
tracked repository.

## Decision

GoldenPad's primary Preview 3 runtime uses **GoldenEye64Recomp at
`a787fe0d95e8278fcba5ba2d768fa6a606e75f55`**, statically generated ARM64 game
code, N64ModernRuntime/N64Recomp components, and **RT64 at
`5473732a822a4423b5696e7cb18fecc425a59875`** with Plume at
`d890ac899e505fb30040e037a4037cdeca68f033`. This is the physically approved
iPhone/iPad release architecture and the basis of the Apple-Silicon Mac Alpha.

**MGB64 at `cd9b58f5f91291579b8e551aa925aab000d311cf`** remains buildable as
`GoldenPad Legacy`. It is a regression fallback and a source-level gameplay/
fidelity oracle, not the primary runtime. Its native SDK-surface guard and
machine-classified source manifest remain required for Legacy builds.

This adopts the same disclosed community decomp/recomp boundary used by the
other native N64 ports evaluated for GoldenPad: the ROM supplies bulk media,
while reconstructed or translated game logic is native code. Lack of an
original-rightsholder license is a commercial/official-distribution concern,
not a GoldenEye-specific development blocker. See `LEGAL.md`.

The primary runtime's generated AOT inputs are intentionally private and cannot
be recreated from the public GoldenEye64Recomp checkout alone. That public-
reproducibility boundary remains disclosed; it is not evidence that the shipped
binary uses MGB64. GoldenRecomp is a separate static-recomp lineage whose own
clean public TLB-free ELF/metadata pipeline remains unavailable.

The matching GoldenEye decompilation reached 100% on 2026-08-16. It is a
behavior/game-side oracle, not a drop-in runtime or renderer replacement. The
source/engine watch, timing-fidelity evidence, and gated MGB64 update procedure
are maintained in [Technical debt and upstream watch](TECH_DEBT.md).

## Verified inventory

| Project | URL | Branch and commit | License/provenance | Purpose and disposition |
| --- | --- | --- | --- | --- |
| GoldenEye64Recomp | https://github.com/cblock85/GoldenEye64Recomp | `main` at `a787fe0d95e8278fcba5ba2d768fa6a606e75f55` | GPL-3.0 wrapper/patch lineage; generated game inputs remain private | Primary game/runtime integration reference and generated-patch source. Active. |
| GoldenRecomp | https://github.com/kholdfuzion/GoldenRecomp | `main` at `f31b5d1e214f57c9ddb3dc598daa688bccffdd4f` | GPL-3.0 wrapper; generated game functions are local build output | Separate static-recomp reference; not GoldenPad's active game lineage. |
| N64Recomp | https://github.com/N64Recomp/N64Recomp | generator reference `ffb39cdad1da5de07eaaa48bd1db4a89a7986771`; runtime-linked revision follows the accepted N64ModernRuntime tree | MIT | Recompiler/runtime component in the primary AOT path; update only with the matched generated/runtime set. |
| N64ModernRuntime | https://github.com/N64Recomp/N64ModernRuntime | accepted private AOT build reference `e75e0de77e8377d4954fe7b511c0d1cf608e7ded` plus the tracked AOT patch | GPL-3.0 (`COPYING`) | Active primary runtime dependency. Threads, controllers, audio, timing, PI/ROM, and saves. |
| RT64 | https://github.com/rt64/rt64 | `main` at `5473732a822a4423b5696e7cb18fecc425a59875` | MIT; vendored dependencies carry their own licenses | Primary renderer. GoldenPad's tracked patches build the complete static library for Apple device/Simulator and the Mac Alpha. |
| Plume | RT64 submodule `src/contrib/plume` | `d890ac899e505fb30040e037a4037cdeca68f033` | MIT | RT64 rendering backend. GoldenPad's UIKit/Metal patch compiles and runs its Apple backend on ARM64 device and Simulator targets without copying the dependency into the repository. |
| MGB64 | https://github.com/akratch/mgb64 | `main` at `cd9b58f5f91291579b8e551aa925aab000d311cf` | MIT for first-party work; decompiled game rights and matching-target SDK lineage documented in `THIRD_PARTY.md` | `GoldenPad Legacy` comparison/fallback and fidelity oracle. Compile only the guarded native source surface. |
| n64decomp/007 | https://github.com/n64decomp/007 | `master` at `754a0a977efcbc99a46d079a73292e40780e3aab` | **No LICENSE file found**; includes decompiled game and libultra/Rare lineage | Symbol/decomp research only. Not incorporated. |
| HarkinianPad | https://github.com/chrissotraidis/harkinianpad | `main` at `4db21e4be0f0be52948438de5d8c755d191897ae` | All rights reserved for its integration code, docs and art; upstream licenses separate | UX/architecture reference only. Clean-room reimplement touch ideas; do not copy code or art without permission. |

## Historical path-selection evidence

The following blocker and MGB64 evidence records why the project initially
selected MGB64 and how the static-recomp path was evaluated before the current
AOT inputs became available. It is historical evidence, not the current product
decision.

## Blocker follow-up

- Current N64Recomp and all five pinned submodules build successfully as native
  Apple ARM64 command-line tools. This proves host-tool portability, not game
  input availability.
- Running that tool with GoldenRecomp's `us.toml` stops at `Elf file not found`.
  The configuration still names `ge007.tlbfree.elf`; its alternative
  `symbols_file_path = "dump.toml"` is commented and no dump is published.
- Current N64Recomp can consume a ROM plus a complete symbol metadata file, but
  it does not infer the full function/section/relocation map from a retail ROM.
- All public GoldenRecomp forks inspected through 2026-08-03 retain the same
  unavailable `kholdfuzion/goldeneye_src` URL and publish no generated function
  tree or replacement metadata.
- The only public repository found with the `goldeneye_src` name has no license,
  no TLB-free branch, and is not the pinned history. It is unusable here.
- `ysrdevs/goldeneye-metal` is a PowerPC/ReXGlue Xbox 360 recompilation that
  imports `default.xex` or Xbox LIVE/STFS data. It is outside this project's
  original-N64-ROM boundary and is explicitly excluded despite its Apple Metal
  work. Other XBLA/XEX recompilation projects are excluded for the same reason.

The static-recomp path therefore needs one external upstream change: a
licensed public TLB-free input repository/ELF recipe, or a licensed complete
ROM symbol/section/relocation metadata file compatible with current N64Recomp.
Neither exists in the inspected public ecosystem today. This remains a
GoldenRecomp limitation. Historically it did not block the then-selected MGB64
path; the current primary runtime instead uses private generated AOT inputs and
keeps that public-reproducibility limitation disclosed.

## GoldenRecomp inspection

- The public README describes a stable game and good audio but lists incomplete
  multiplayer UI, custom sky/water rendering, weapon timing, and modern
  dual-analog controls.
- It needs a specially modified TLB-free, uncompressed ROM plus ELF from a
  decomp branch and a fork of N64Recomp.
- The pinned `lib/ge` URL returns “Repository not found.”
- The pinned commit is `b72aa387146d09bdd1e66b39edc4fe646e89709f`,
  but the submodule could not be initialized.
- `RecompiledFuncs/` and `RecompiledPatches/` are not present after clone, so a
  clean checkout cannot configure a useful executable without local generation.
- The checked-in prebuilt `N64Recomp.exe`/`RSPRecomp.exe` are Windows binaries;
  GoldenPad will build tools from source and never trust those binaries.

## MGB64 runtime evidence

On this Apple M1 host, commit `cd9b58f`:

- configured and compiled to a Mach-O ARM64 executable with AppleClang 21;
- the default pinned `wgpu-native v29.0.1.1` path initialized backend 5 on the
  `Apple M1` adapter, which is Metal-backed on Apple;
- recognized the local 12 MiB V64, converted byte order in memory, and matched
  normalized US SHA-1 `abe01e4aeb033b6c0836819f549c791b26cfde83`;
- direct-booted Dam, decoded 261/261 SFX, parsed 75 music instruments, and saved
  a valid 640x480 gameplay framebuffer;
- created and persisted a configuration in a dedicated ignored save directory.
- compiled all 135 game C files, 70 explicit upstream native system/portable
  files and five project-owned mobile adapters into 210-object ARM64 archives
  for both Apple mobile SDKs;
- linked the real upstream random-core code into GoldenPad and executed the same
  deterministic probe on iPhone and iPad simulators.
- compiled the complete native Metal backend and its combiner/backend/MSAA
  support for both Apple mobile SDKs after guarding two macOS-only
  `CAMetalLayer.displaySyncEnabled` writes;
- compiled the Fast3D interpreter, room-normal helper, screenshot and texture
  units into five-object ARM64
  archives for both mobile SDKs without unresolved SDL or desktop OpenGL calls;
- supplied `platformGetMetalLayer` from the UIKit host and observed it live at
  1206x2622 on iPhone followed by 1668x2420 on iPad;
- linked the Fast3D/Metal closure into final ARM64 Simulator and device apps,
  then encoded/presented real ROM-free MGB64 empty frames sequentially at those
  same drawable sizes without SDL/OpenGL/AppKit dependencies or GPU errors;
- normalized the supported private V64 through the existing exact SHA-1 gate,
  installed it into core-owned volatile memory on iPhone and then iPad, and
  removed each entire app container immediately after its sequential pass.
- initialized the real upstream scheduler, message queues and graphics client
  through the SDL-free mobile OS adapter in final Simulator/device binaries;
  sequential phone/tablet runtime reached `MGB64 scheduler ready` before the
  same app-container cleanup.
- linked upstream native ROM-offset and zero-content asset-symbol units, patched
  the complete file table, and verified its first background and Dam entries
  inside the owned buffer on both mobile device classes.
- isolated the real host-side GU matrix/vector helpers from the desktop SDL
  compatibility unit, executed `guNormalize` inside the mobile core probe on
  both device classes, and reduced the measured `bossEntry` link gap from 261
  to 246 unique symbols with no GU blocker remaining.
- added 28 small SDL-free upstream leaf units for segment constants, trig/stdio
  compatibility and isolated fidelity helpers; representative paths executed in
  the unchanged phone/tablet probe, while the startup map closed 61 symbols,
  introduced none and fell from 246 to 185.
- moved the 68 game settings/startup globals needed by the title path into a
  project-owned mobile configuration unit rather than SDL; representative
  defaults executed on both device classes and the startup map fell from 185 to
  117 with no new unresolved name.
- linked real model conversion, stage lookup, radial input, setup-name and
  weapon-cue services plus a mobile legacy-data unit; representative paths ran
  on both device classes and the startup map fell from 117 to 97 with no new
  unresolved symbol.
- linked the real portable overlay dispatcher plus project-owned thread-safe
  queues/timers, volatile EEPROM and neutral UIKit host services. Their delayed
  timer, EEPROM and lifecycle probes ran on both device classes; the startup map
  closed 27, introduced none and fell from 97 to 70.
- closed the remaining portable `bossEntry` boundary with no unresolved symbol,
  without importing SDL or matching-target SDK implementation sources, and
  started it once on a dedicated game thread after all readiness gates.
- rendered the real title animation and demo-stage setup through Fast3D/Metal
  sequentially at 2622x1206 on iPhone and 2420x1668 on iPad.
- connected Swift controller frames to the real mobile `osCont*` reads; the
  deterministic input probe passed on both simulator classes.
- decoded 261/261 SFX and parsed 75 music instruments/138 sounds on each class;
  the 22.05 kHz synth fed a bounded PCM ring and the native output probe passed.

The fallback documented as `-DMGB64_WEBGPU_BACKEND=OFF` failed at link time:
`gfx_pc.c` still references `gfx_webgpu_api`. The default build succeeded.

The original internal checkout run discovered 106 tests, with eight failures
split across macOS Bash 3 incompatibilities, a missing Pillow dependency and
stale private fidelity evidence. That result mixed the public release surface
with upstream's export-ignored fidelity program. GoldenPad now verifies the
actual public export at the exact pin with a maintained compatibility patch:
the exported source builds and reports 100% passed across 103 CTest entries,
with 10 explicit ROM/browser/optional-binary skips. No private fidelity test or
evidence path is reclassified as a production release gate.

## Renderer assessment

RT64 currently advertises and contains D3D12, Vulkan and Metal backends. Its
Apple path creates an SDL Metal view and previously hard-coded `-sdk macosx` for
shader compilation. At the pinned commit, the repo-owned SDK patch generated 56
MSL files and compiled all 56 independently into `.metallib` files for both
`iphoneos` and `iphonesimulator`. Consecutive runs produced stable aggregate
digests `04c7eb0f7719dc27ea3f4ca4b2f95fc7bb5a59837c1c77af68ce421d081cc838`
and `7b9a5a185799bd8bda7f7e2b25fe4bcb18223200cf14df781c442441f93f2212`,
respectively.

The Plume Metal core compiled into ARM64 static archives for both mobile SDKs
after a narrow patch replaced AppKit helpers with UIKit, used the default Metal
device when `MTL::CopyAllDevices()` is unavailable on iOS, and guarded macOS-only
display-sync APIs. A Simulator-only guard avoids the unavailable Metal `location`
selector while retaining the native device query on hardware.

The embedded RT64 patch excludes the desktop SDL window/event adapter, NFD,
inspector UI and cross-compiled host tools. Host-generated SPIR-V/preprocessed
sources are reused while each mobile SDK receives its own 56 compiled Metal
libraries. Exact clean-tree runs produce a 210-object RT64 archive for both SDKs;
RT64, Plume, re-spirv and zstd total 246 archive members. Force-loading all four
archives leaves no SDL, NFD, AppKit, IOKit, X11 or macOS Vulkan-surface symbols.

GoldenPad's opt-in bridge then created the real Plume Metal device, direct
command queue and swapchain against its UIKit-owned `CAMetalLayer`. Sequential
runtime passes visibly reported `Apple iOS simulator GPU` at 1206x2622 on
iPhone 16 Pro and 1668x2420 on iPad Pro 11-inch (M4). This completes the RT64
mobile renderer/surface reference gate. That path was subsequently promoted to
the primary runtime and physically approved on iPhone/iPad; MGB64's coupled
Fast3D/Metal renderer remains independently connected as Legacy.

MGB64's coupled Fast3D/Metal path now runs the title, menus and live missions on
iOS. Only the audited native source set is compiled; UIKit owns the layer and
cadence, while ROM state remains null before validated import. It is retained
for comparisons and source-level behavior evidence, not as a second production
renderer.

## Current unknowns

1. What sustained player fire-rate cadence does GoldenPad measure before/after
   an authenticity repair? Isolated guard windows already record 13/17/18
   events per 100 ticks.
2. What frame-local state causes the residual multiplayer lighting flicker?
   Fixed player order is rejected; the zero depth-`formatChanged` signal still
   needs known-active calibration and non-format upload coverage.
3. Can the primary input host preserve stable ownership across two to four real
   controllers and every disconnect/reconnect/foreground order?
4. Is the reported A12X first-frame crash repairable in RT64/Plume, or does the
   project need a deliberately tested minimum GPU generation?
5. Which audio discontinuity class produces the intermittent static, and does a
   current-build hard lifecycle freeze exist apart from recoverable stalls?
6. Can the game-bearing private-input build become scripted and independently
   reproducible without distributing retail-derived data?
7. Can the runtime-managed Application Support ROM copy receive the Documents
   copy's backup/protection policy without disturbing validation or saves?
