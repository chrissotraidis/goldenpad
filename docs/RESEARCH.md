# Research

Last verified: 2026-08-03. All checkouts below live under the ignored `ref/`
directory and are references unless this document explicitly says otherwise.

## Decision

GoldenPad's production-core candidate is **MGB64 at `cd9b58f`**. It is the only
inspected original-retail-N64 project that both builds from its public checkout
and reaches visible Apple Silicon GoldenEye gameplay. Its native target compiles
the reconstructed game logic plus first-party platform replacements, while
leaving the historical libultra/libultrare implementation source sets empty.
The upstream native SDK-surface guard passes at the exact pin.

This adopts the same disclosed community decomp/recomp boundary used by the
other native N64 ports evaluated for GoldenPad: the ROM supplies bulk media,
while reconstructed or translated game logic is native code. Lack of an
original-rightsholder license is a commercial/official-distribution concern,
not a GoldenEye-specific development blocker. See `LEGAL.md`.

GoldenRecomp + N64Recomp + N64ModernRuntime + RT64 remains the preferred static-
recomp reference architecture, but not the active production path: its pinned
game-code submodule is unavailable, generated `RecompiledFuncs` are absent, and
its TLB-free ROM/ELF recipe cannot be reproduced from the public checkout.

## Verified inventory

| Project | URL | Branch and commit | License/provenance | Purpose and disposition |
| --- | --- | --- | --- | --- |
| GoldenRecomp | https://github.com/kholdfuzion/GoldenRecomp | `main` at `f31b5d1e214f57c9ddb3dc598daa688bccffdd4f` | GPL-3.0 wrapper; generated game functions are local build output | Static-recomp/RT64 reference. Not active until its input pipeline is reproducible. |
| N64Recomp | https://github.com/N64Recomp/N64Recomp | `main` at `ffb39cdad1da5de07eaaa48bd1db4a89a7986771` | MIT | Recompiler tooling reference; pin before incorporation. |
| N64ModernRuntime | https://github.com/N64Recomp/N64ModernRuntime | `main` at `589bbf018a3e6d3646ddf7de1e7919f1b7e99bb1` | GPL-3.0 (`COPYING`) | Threads, controllers, audio, timing, PI/ROM and saves. Candidate dependency. |
| RT64 | https://github.com/rt64/rt64 | `main` at `5473732a822a4423b5696e7cb18fecc425a59875` | MIT; vendored dependencies carry their own licenses | Preferred renderer. GoldenPad's tracked patches build the complete static library for iOS device and Simulator and link it through an opt-in host bridge. |
| Plume | RT64 submodule `src/contrib/plume` | `d890ac899e505fb30040e037a4037cdeca68f033` | MIT | RT64 rendering backend. GoldenPad's UIKit/Metal patch compiles and runs its Apple backend on ARM64 device and Simulator targets without copying the dependency into the repository. |
| MGB64 | https://github.com/akratch/mgb64 | `main` at `cd9b58f5f91291579b8e551aa925aab000d311cf` | MIT for first-party work; decompiled game rights and matching-target SDK lineage documented in `THIRD_PARTY.md` | Selected production-core candidate. Compile only the guarded native source surface; never matching-target SDK implementations or ROM media. |
| n64decomp/007 | https://github.com/n64decomp/007 | `master` at `754a0a977efcbc99a46d079a73292e40780e3aab` | **No LICENSE file found**; includes decompiled game and libultra/Rare lineage | Symbol/decomp research only. Not incorporated. |
| HarkinianPad | https://github.com/chrissotraidis/harkinianpad | `main` at `4db21e4be0f0be52948438de5d8c755d191897ae` | All rights reserved for its integration code, docs and art; upstream licenses separate | UX/architecture reference only. Clean-room reimplement touch ideas; do not copy code or art without permission. |

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
GoldenRecomp limitation, not a blocker on the selected MGB64 production path.

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
- compiled all 135 game C files plus 26 explicit native system/asset glue files
  into 161-object ARM64 archives for both Apple mobile SDKs;
- linked the real upstream random-core code into GoldenPad and executed the same
  deterministic probe on iPhone and iPad simulators.

The fallback documented as `-DMGB64_WEBGPU_BACKEND=OFF` failed at link time:
`gfx_pc.c` still references `gfx_webgpu_api`. The default build succeeded.

CTest result: 106 tests discovered; 92% passed, 8 failed, and 10 skipped. Failures
included malformed shell `case` syntax, Bash-3-incompatible associative arrays,
missing Pillow, pre-push assumptions, and stale/missing fidelity evidence paths.
This is a working desktop oracle, not a release-ready upstream.

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
mobile renderer/surface gate, not the game-rendering gate: the selected MGB64
core now compiles, but its platform/render loop is not yet connected.

MGB64's Fast3D/WebGPU path already proves GoldenEye display lists on Metal. The
first mobile integration will preserve that coupled renderer/core path and
compile only the audited native source set. RT64 remains a verified alternative,
not a second simultaneous bring-up dependency.

## Current unknowns

1. Which minimum MGB64 platform/renderer sources must be replaced or patched for
   UIKit-owned lifecycle, input, audio, filesystem and `CAMetalLayer`?
2. Can MGB64's direct Metal backend adopt GoldenPad's existing UIKit layer
   without retaining SDL desktop window ownership?
3. Can GoldenRecomp's exact TLB-free input branch or equivalent complete public
   metadata eventually be restored for a comparative RT64 build?
