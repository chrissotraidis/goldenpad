# Worklog

## 2026-08-03 — research and desktop feasibility

- Read the governing goal and repository instructions.
- Found an empty Git repository with only a local HarkinianPad checkout and
  retail V64 under `ref/`.
- Added immediate ROM/reference/build/package/signing exclusions and a tracked
  local-reference notice.
- Verified the private V64 is ignored and normalizes in-memory to supported US
  SHA-1 `abe01e4aeb033b6c0836819f549c791b26cfde83`.
- Inspected and pinned MGB64, n64decomp/007, N64Recomp, N64ModernRuntime,
  GoldenRecomp, RT64 and HarkinianPad.
- Recorded the unlicensed decomp boundary, MGB64 SDK-lineage boundary, and
  HarkinianPad all-rights-reserved boundary.
- Built MGB64 default WebGPU configuration as ARM64. The documented backend-off
  build failed at final link with unresolved `gfx_webgpu_api`.
- Ran the upstream CTest suite: 92% passed, 8 failed, 10 skipped. Kept exact
  failure classes in `RESEARCH.md`/`STATUS.md`.
- Direct-booted Dam with the local ROM. Logs proved V64 conversion, runtime ROM
  load, Metal-backed Apple M1 WebGPU, SDL input surface, 261/261 decoded SFX,
  75 music instruments, synth startup, level setup, and clean shutdown.
- Captured and privately inspected a 640x480 deterministic gameplay framebuffer.
  The capture remains ignored and must not be published.
- GoldenRecomp clone proved its pinned `lib/ge` URL is unavailable and generated
  recompilation sources are absent. Chose it as the preferred architecture only
  behind a reproducibility/provenance gate.

## 2026-08-03 — native Apple mobile foundation

- Added a single CMake-generated SwiftUI/UIKit application target for iPhone and
  iPad, requiring iOS 17 and Apple ARM64/Metal.
- Added a live `MTKView` renderer with its own Metal command queue and a neutral,
  original, asset-free import/status interface.
- Added security-scoped Files import and in-memory Z64/V64/N64 normalization,
  exact 12 MiB enforcement, and supported-US SHA-1 validation. No selected data
  is retained by the foundation.
- Built and visibly inspected the app sequentially on iPhone 16 Pro and iPad Pro
  11-inch (M4), both running iOS 18.5. The phone and tablet layouts rendered
  correctly and the Metal view stayed live.
- Passed the private V64 on both devices and visibly proved invalid-size handling
  on iPad. Screenshots remain ignored; no game imagery was published.
- Uninstalled the app from both simulator devices after testing and confirmed
  both devices were shut down, removing the temporary container ROM copies.
- Added a repo-owned iOS plist with explicit device families, launch screen,
  Metal/ARM64 capabilities, and phone/tablet orientation declarations.
- Built an unsigned Release bundle against the generic iOS device SDK; its
  executable is ARM64 and its complete app payload is roughly 256 KiB with no
  ROM or generated game assets.
