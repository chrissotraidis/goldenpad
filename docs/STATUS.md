# Status

Updated: 2026-08-03

## Summary

Research, Apple Silicon gameplay feasibility, a ROM-free native mobile
foundation, and the complete RT64 mobile Metal linkage/surface gate are
established. MGB64 is now the selected production-core candidate under the
documented community decomp/recomp legal boundary. GoldenRecomp remains a
reference because its public input-generation path is incomplete; that no
longer blocks MGB64 integration.

## Passed

- ROM/reference/build/signing exclusions are active.
- Local retail V64 is ignored, 12 MiB, normalizes to the supported US SHA-1, and
  was never copied into the tracked tree or a package.
- Required initial research/legal/architecture/plan/build/test/worklog docs exist.
- MGB64 `cd9b58f` builds as native ARM64 on Apple Silicon with default WebGPU.
- MGB64's native SDK-surface guard passes at the exact pin. Its native CMake
  target compiles no `src/libultra/**` or `src/libultrare/**` implementation
  sources; matching-target SDK-lineage files remain outside GoldenPad's source
  and binary boundary.
- GoldenPad's opt-in MGB64 target compiles all 135 game translation units plus
  26 explicit native system/asset glue units into 161-object, non-fat ARM64
  archives for both `iphonesimulator` and `iphoneos` at the iOS 17 deployment
  target. Release app executables link for both SDKs.
- Final-binary inspection confirms the exact MGB64 commit, bridge identity/probe
  symbols and real upstream `randomSetSeed`/`randomGetNext` code. Sequential
  no-ROM launches reported deterministic probe `0x80c24316` on iPhone 16 Pro,
  then iPad Pro 11-inch (M4); both installs were removed and devices shut down.
- MGB64's complete native Metal backend plus its combiner, backend selector and
  MSAA helper compile into four-object non-fat ARM64 archives for both mobile
  SDKs. The only source changes required were guards around two macOS-only
  `CAMetalLayer.displaySyncEnabled` writes. The verifier applies and reverses
  that exact-source patch, confirms `gfx_metal_api`, and leaves upstream clean.
- MGB64's Fast3D display-list interpreter and room-normal helper compile into
  two-object, non-fat ARM64 archives for both mobile SDKs. The archive exports
  `gfx_init`, `gfx_run_dl`, and `gfx_end_frame` and retains no unresolved SDL,
  desktop OpenGL readback, or OpenGL swap symbols.
- GoldenPad now implements MGB64's exact `platformGetMetalLayer` contract with a
  weak ARC bridge to the UIKit-owned layer. Sequential no-ROM launches logged
  the handoff at 1206x2622 on iPhone 16 Pro, then 1668x2420 on iPad Pro 11-inch
  (M4); each install was removed and each simulator shut down.
- WebGPU selects Apple M1/Metal, Dam renders visibly, audio banks initialize,
  and config persistence works in an ignored directory.
- Useful upstreams are pinned under ignored `ref/` checkouts.
- One SwiftUI/UIKit target builds for iPhone and iPad, backed by a live
  `MTKView` clear-frame renderer rather than a placeholder image.
- The UIKit render owner exposes RT64's expected non-retaining `UIView` and
  `CAMetalLayer` pointers, reports drawable size/refresh and pauses with the
  scene lifecycle. Sequential UI passes reported 1206×2622 at 60 Hz on iPhone
  16 Pro and 1668×2420 at 60 Hz on iPad Pro 11-inch (M4).
- At exact RT64 `5473732a` and Plume `d890ac89`, all 56 generated Metal shaders
  compile for both `iphoneos` and `iphonesimulator`. Patched Plume Apple/Metal
  objects archive for both ARM64 targets, its macOS target still builds, and two
  runs reproduced per-SDK aggregate digests recorded in `RESEARCH.md`.
- A clean pinned-source build now produces a 210-object RT64 static archive for
  each mobile SDK. Force-loading all 246 RT64/Plume/re-spirv/zstd members links
  as ARM64 with only expected Apple frameworks/runtime libraries and no SDL,
  NFD, AppKit, IOKit, X11 or macOS Vulkan-surface residue.
- The opt-in GoldenPad bridge force-links that complete closure and creates the
  real Plume Metal device, direct command queue and swapchain. Sequential live
  status reported `Apple iOS simulator GPU` at 1206×2622 on iPhone 16 Pro and
  1668×2420 on iPad Pro 11-inch (M4). Both installs were removed and both
  simulators shut down. The same linked app builds as Release ARM64 for
  `iphoneos`.
- Debug simulator builds succeeded and rendered responsively on an iPhone 16
  Pro and an iPad Pro 11-inch (M4), sequentially; both simulators were stopped.
- The local V64 passed in-memory size, header, V64-to-Z64 normalization and
  supported-US SHA-1 validation on both simulator classes. A one-byte `.v64`
  was visibly rejected on iPad with an exact size error.
- The app was uninstalled from both simulators after validation, removing the
  temporary container copies. The original ignored reference file remains.
- A generic iOS device-SDK Release build succeeds as an unsigned ARM64 Mach-O.
- The 2.7 MiB device `.app` contains six enumerated files: plist/package metadata,
  the 918 KiB ARM64 executable, project-owned icon renditions and `Assets.car`.
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
- The same input frame now carries exact libultra-compatible N64 masks. Direct
  classic A input reported `0x8000` on iPhone and iPad; modern FIRE reported the
  expected Z mask `0x2000`. Classic, modern and southpaw mappings are available.
- A live editor provides per-control move, 70–150% size and hide/show controls,
  with the movement stick protected from hiding. Phone and tablet defaults are
  separate; schema-2 settings persist only changed placements. On iPhone, one
  MOVE nudge saved exactly one placement delta and Reset returned overrides to
  `{}`. The equivalent tablet profile and reset were exercised independently.
- The current UI was rebuilt and inspected sequentially on iPhone 16 Pro and
  iPad Pro 11-inch (M4) in portrait and landscape. The full editor remained
  inside safe areas, settings relaunch persisted, and the Simulator's synthetic
  MFi controller no longer falsely hides touch controls.
- Original project-owned app art is compiled into phone/tablet icon renditions
  and was visually accepted on both simulator launchers. Provenance is recorded
  in `ART.md`.
- The current unsigned foundation IPA was created twice with identical SHA-256
  `bf101037f91d723b6819e2fedefaa100de4582d9f685190cd4d0ed7e9b343e75`.
  Its eight-member payload passed extension, ROM-header, known-hash, signing,
  private-path and ARM64 checks. Its sorted app-content SHA-256 is
  `8945edcf01b1cb760c2651e17eeb8017334c4b09318174459e4193b214a42f87`.

## Failed or blocked

- MGB64 GL/Metal-only fallback fails to link: unresolved `gfx_webgpu_api`.
- MGB64 CTest is not clean: 8/106 failed and 10 skipped on this host.
- GoldenRecomp's `lib/ge` submodule URL is unavailable.
- GoldenRecomp generated function directories are absent from clean checkout.
- MGB64's Fast3D and Metal archives are not yet linked together in the app;
  renderer-support resolution, audio, input, resource-loading and main-loop
  seams remain. The core probe does not start menus or gameplay.
- Full valid-ROM picker selection still needs a safe private Files fixture;
  current valid-ROM evidence invokes the same validator through an explicit
  automation launch argument after the picker UI itself was proven.
- No shared game core, game audio/save integration, physical-controller/gyro
  acceptance, touch-only mission completion, multiplayer, final game-bearing
  unsigned IPA, or final archive audit yet. Simulator UI automation proved the
  editor's accessible nudge path; direct finger drag remains a physical-device
  interaction gate.

## Next gate

Link the proven MGB64 Fast3D and Metal archives with the minimum remaining
renderer support, then start one UIKit-timed no-ROM-safe renderer lifecycle
before attempting title/menu startup. Do not import matching-target SDK
implementation sources or Xbox/XBLA material.
