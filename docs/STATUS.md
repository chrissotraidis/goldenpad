# Status

Updated: 2026-08-03

## Summary

Research, Apple Silicon feasibility, and a ROM-free native mobile foundation are
established. No production game core has been incorporated yet. Public release
is blocked by the GoldenRecomp input-generation/provenance gate.

## Passed

- ROM/reference/build/signing exclusions are active.
- Local retail V64 is ignored, 12 MiB, normalizes to the supported US SHA-1, and
  was never copied into the tracked tree or a package.
- Required initial research/legal/architecture/plan/build/test/worklog docs exist.
- MGB64 `cd9b58f` builds as native ARM64 on Apple Silicon with default WebGPU.
- WebGPU selects Apple M1/Metal, Dam renders visibly, audio banks initialize,
  and config persistence works in an ignored directory.
- Useful upstreams are pinned under ignored `ref/` checkouts.
- One SwiftUI/UIKit target builds for iPhone and iPad, backed by a live
  `MTKView` clear-frame renderer rather than a placeholder image.
- Debug simulator builds succeeded and rendered responsively on an iPhone 16
  Pro and an iPad Pro 11-inch (M4), sequentially; both simulators were stopped.
- The local V64 passed in-memory size, header, V64-to-Z64 normalization and
  supported-US SHA-1 validation on both simulator classes. A one-byte `.v64`
  was visibly rejected on iPad with an exact size error.
- The app was uninstalled from both simulators after validation, removing the
  temporary container copies. The original ignored reference file remains.
- A generic iOS device-SDK Release build succeeds as an unsigned ARM64 Mach-O.
- The 2.1 MiB device `.app` contains six enumerated files: plist/package metadata,
  the 324 KiB ARM64 executable, project-owned icon renditions and `Assets.car`.
  It contains no bundled retail data or generated game assets.
- Current N64Recomp and its pinned dependencies compile as native ARM64 tools;
  its GoldenRecomp run still fails before generation because the required ELF
  is not public. Public forks and current alternative repositories were audited.
- The host now creates sandbox-safe Application Support, save and derived-cache
  directories; derived cache is excluded from backup.
- Real `AVAudioSession` activation/deactivation plus interruption and route-change
  observers are connected to SwiftUI scene lifecycle. Both simulator classes
  visibly reported sandbox and audio-session readiness in a sequential rerun.
- Original project-owned app art is compiled into phone/tablet icon renditions
  and was visually accepted on both simulator launchers. Provenance is recorded
  in `ART.md`.
- The unsigned foundation IPA was created twice with identical SHA-256
  `d5c94ba3cfc476df417dd608ea5bc340b9d0a79d13e43c3e79f59f547d8071a9`.
  Its eight-member payload passed extension, ROM-header, known-hash, signing,
  private-path and ARM64 checks. Its sorted app-content SHA-256 is
  `888944a784ac89cb9c34979f7bd11ccd69d17b0c7a551f205548ab5f2a644ac1`.

## Failed or blocked

- MGB64 GL/Metal-only fallback fails to link: unresolved `gfx_webgpu_api`.
- MGB64 CTest is not clean: 8/106 failed and 10 skipped on this host.
- GoldenRecomp's `lib/ge` submodule URL is unavailable.
- GoldenRecomp generated function directories are absent from clean checkout.
- Selected production core has not yet built or run on macOS/iOS.
- Files-picker interaction itself has not yet been driven; current runtime
  validation evidence uses the same validator through an explicit automation
  launch argument.
- No shared game core, audio-engine/save persistence, touch controls,
  controller validation, mission completion, multiplayer, final game-bearing
  unsigned IPA, or final archive audit yet.

## Next gate

Obtain or upstream a licensed complete GoldenRecomp ELF/metadata input, then
connect the generated core to the existing host. In parallel, finish picker,
settings/save and lifecycle acceptance without importing unlicensed game,
SDK-lineage, or Xbox/XBLA material.
