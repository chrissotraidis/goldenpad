# Research

Last verified: 2026-08-03. All checkouts below live under the ignored `ref/`
directory and are references unless this document explicitly says otherwise.

## Decision

GoldenPad's preferred production core is the original-retail-N64
**GoldenRecomp + N64Recomp + N64ModernRuntime** path, rendered by **RT64 over
Metal**. This path has a clearly licensed wrapper/runtime/tooling chain and does
not require distributing the unlicensed `n64decomp/007` C tree.

The decision is gated, not final: GoldenRecomp's pinned game-code submodule is
currently unavailable, generated `RecompiledFuncs` are not tracked, and its
documented TLB-free ROM/ELF recipe cannot be reproduced from the public checkout.
No GoldenRecomp code will be incorporated until that gate is resolved and the
resulting source/binary provenance is reviewed.

MGB64 is the strongest current Apple Silicon behavior and platform reference.
It is not the production core because the underlying decompiled game tree has
no license and the checkout inventories SDK-lineage material outside MGB64's
MIT grant.

## Verified inventory

| Project | URL | Branch and commit | License/provenance | Purpose and disposition |
| --- | --- | --- | --- | --- |
| GoldenRecomp | https://github.com/kholdfuzion/GoldenRecomp | `main` at `f31b5d1e214f57c9ddb3dc598daa688bccffdd4f` | GPL-3.0 wrapper; generated game functions are local build output | Preferred static-recomp core reference. Remains ignored reference until its input pipeline is reproducible. |
| N64Recomp | https://github.com/N64Recomp/N64Recomp | `main` at `ffb39cdad1da5de07eaaa48bd1db4a89a7986771` | MIT | Recompiler tooling reference; pin before incorporation. |
| N64ModernRuntime | https://github.com/N64Recomp/N64ModernRuntime | `main` at `589bbf018a3e6d3646ddf7de1e7919f1b7e99bb1` | GPL-3.0 (`COPYING`) | Threads, controllers, audio, timing, PI/ROM and saves. Candidate dependency. |
| RT64 | https://github.com/rt64/rt64 | `main` at `5473732a822a4423b5696e7cb18fecc425a59875` | MIT; vendored dependencies carry their own licenses | Preferred renderer. Code inspection confirms macOS Metal sources/shaders and SDL Metal surfaces. iOS remains unproven. |
| MGB64 | https://github.com/akratch/mgb64 | `main` at `cd9b58f5f91291579b8e551aa925aab000d311cf` | MIT only for first-party work; decompiled game and SDK-lineage exclusions are documented in `THIRD_PARTY.md` | Apple Silicon gameplay oracle and platform reference only. Do not copy game/SDK material. |
| n64decomp/007 | https://github.com/n64decomp/007 | `master` at `754a0a977efcbc99a46d079a73292e40780e3aab` | **No LICENSE file found**; includes decompiled game and libultra/Rare lineage | Symbol/decomp research only. Not incorporated. |
| HarkinianPad | https://github.com/chrissotraidis/harkinianpad | `main` at `4db21e4be0f0be52948438de5d8c755d191897ae` | All rights reserved for its integration code, docs and art; upstream licenses separate | UX/architecture reference only. Clean-room reimplement touch ideas; do not copy code or art without permission. |

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

The fallback documented as `-DMGB64_WEBGPU_BACKEND=OFF` failed at link time:
`gfx_pc.c` still references `gfx_webgpu_api`. The default build succeeded.

CTest result: 106 tests discovered; 92% passed, 8 failed, and 10 skipped. Failures
included malformed shell `case` syntax, Bash-3-incompatible associative arrays,
missing Pillow, pre-push assumptions, and stale/missing fidelity evidence paths.
This is a working desktop oracle, not a release-ready upstream.

## Renderer assessment

RT64 currently advertises and contains D3D12, Vulkan and Metal backends. Its
Apple path creates an SDL Metal view and compiles Metal shader libraries on
macOS. The current CMake shader commands hard-code `-sdk macosx`; moving to iOS
requires parameterizing the SDK (`iphoneos`/`iphonesimulator`), validating
Metal feature use, and replacing desktop window/filesystem assumptions.

MGB64's Fast3D/WebGPU path already proves the same GoldenEye display-list family
on Metal, but its fast3d provenance has redistribution qualifications and its
game integration cannot be cleanly separated without more audit. It remains a
fallback technical reference, not the first choice.

## Current unknowns

1. Can GoldenRecomp's exact TLB-free input branch and pinned `lib/ge` commit be
   obtained from a public, provenance-documented source?
2. Can current N64Recomp generate GoldenEye code directly from ROM plus public
   symbols, eliminating the special decomp-built ELF?
3. Does RT64's Metal backend compile and run on iOS without unsupported desktop
   APIs or runtime shader compilation?
4. Are the generated recompilation outputs suitable for public source/binary
   distribution? This needs explicit legal review; this document is not legal
   advice.
