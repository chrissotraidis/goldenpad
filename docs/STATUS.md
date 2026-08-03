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
- The device `.app` contains only `Info.plist`, `PkgInfo`, and the 256 KiB-class
  executable; it contains no bundled retail data or generated game assets.

## Failed or blocked

- MGB64 GL/Metal-only fallback fails to link: unresolved `gfx_webgpu_api`.
- MGB64 CTest is not clean: 8/106 failed and 10 skipped on this host.
- GoldenRecomp's `lib/ge` submodule URL is unavailable.
- GoldenRecomp generated function directories are absent from clean checkout.
- Selected production core has not yet built or run on macOS/iOS.
- Files-picker interaction itself has not yet been driven; current runtime
  validation evidence uses the same validator through an explicit automation
  launch argument.
- No shared game core, audio/lifecycle/save integration, touch controls,
  controller validation, mission completion, multiplayer, original app icon,
  final unsigned IPA, or final archive audit yet.

## Next gate

Reconstruct GoldenRecomp generation from public inputs and connect only a
provenance-clean generated core to the existing host. Do not import unlicensed
game or SDK-lineage source to make progress appear faster.
