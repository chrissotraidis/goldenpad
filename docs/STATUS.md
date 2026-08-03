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
- The 2.3 MiB device `.app` contains six enumerated files: plist/package metadata,
  the 514 KiB ARM64 executable, project-owned icon renditions and `Assets.car`.
  It contains no bundled retail data or generated game assets.
- Current N64Recomp and its pinned dependencies compile as native ARM64 tools;
  its GoldenRecomp run still fails before generation because the required ELF
  is not public. Public forks and current alternative repositories were audited.
- The host now creates sandbox-safe Application Support, save and derived-cache
  directories; derived cache is excluded from backup.
- Real `AVAudioSession` activation/deactivation plus interruption and route-change
  observers are connected to SwiftUI scene lifecycle. Direct Simulator Home and
  launcher interaction produced an attached-console deactivate/reactivate cycle
  at 48 kHz on iPhone, followed by the same successful cycle on iPad.
- The real system Files picker opened and cancelled cleanly on iPhone, followed
  by iPad, through direct UI interaction rather than the automation seam.
- Missing-path input visibly produced the unreadable-file state on both device
  classes. A synthetic zero-filled 12 MiB Z64-header fixture reached the hash
  gate and visibly produced the SHA-1 mismatch state on both. The fixture was
  deleted after the sequential pass and contained no retail data.
- Versioned settings use clamped values and atomic data-protected writes. Four
  bounded player save slots use atomic opaque bytes. Settings and a 32-byte
  non-game save probe survived terminate/relaunch on both simulator classes;
  both save probes matched SHA-256
  `1423d5f6e56161b09d54695772daf079b2e027f18d6b20f6927c7a86f99a85f5`.
- A common normalized input snapshot now merges touch with assigned
  `GCExtendedGamepad` state. The real iPhone lab produced movement `0.61,0.63`
  and FIRE bit `0x1`; the iPad produced `0.64,0.62` and the same action bit.
  The touch lab was corrected to equal responsive columns after tablet review.
- Original project-owned app art is compiled into phone/tablet icon renditions
  and was visually accepted on both simulator launchers. Provenance is recorded
  in `ART.md`.
- The current unsigned foundation IPA was created twice with identical SHA-256
  `82c4ca4939fe1b590892ed4706965ca3339926fb7ae9c88a9cd3b550010e12f9`.
  Its eight-member payload passed extension, ROM-header, known-hash, signing,
  private-path and ARM64 checks. Its sorted app-content SHA-256 is
  `0783c88170cade31ac901e0fbbc274bacb5edae961f3cc96e42283d608eb4a2f`.

## Failed or blocked

- MGB64 GL/Metal-only fallback fails to link: unresolved `gfx_webgpu_api`.
- MGB64 CTest is not clean: 8/106 failed and 10 skipped on this host.
- GoldenRecomp's `lib/ge` submodule URL is unavailable.
- GoldenRecomp generated function directories are absent from clean checkout.
- Selected production core has not yet built or run on macOS/iOS.
- Full valid-ROM picker selection still needs a safe private Files fixture;
  current valid-ROM evidence invokes the same validator through an explicit
  automation launch argument after the picker UI itself was proven.
- No shared game core, game audio/save integration, full touch mapping/editor,
  physical-controller validation, mission completion, multiplayer, final
  game-bearing unsigned IPA, or final archive audit yet.

## Next gate

Obtain or upstream a licensed complete GoldenRecomp ELF/metadata input, then
connect the generated core to the existing host. In parallel, finish game-facing
input presets without importing unlicensed game, SDK-lineage, or Xbox/XBLA
material.
