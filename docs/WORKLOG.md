# Worklog

## 2026-08-03 — link and run the MGB64 Fast3D/Metal lifecycle

- Added a narrow mobile selector patch that chooses MGB64's Metal backend
  directly instead of retaining its desktop OpenGL fallback. Both MGB64 patches
  remain exact-pin, temporary, and are reversed after every verifier run.
- Linked the audited 161-object core, two-object Fast3D frontend and four-object
  Metal backend into opt-in Release apps for ARM64 Simulator and `iphoneos`.
  Final binaries retain the backend/layer/lifecycle symbols and no SDL,
  OpenGL or AppKit dependency.
- Added neutral mobile renderer defaults and a UIKit-timed lifecycle bridge.
  ROM globals are explicitly null/zero; the temporary minimap closure is a
  no-op, so this gate presents only ROM-free empty frames.
- Launched strictly sequentially. iPhone 16 Pro initialized the real Metal
  backend and encoded its first 1206x2622 frame; after removal and shutdown,
  iPad Pro 11-inch (M4) did the same at 1668x2420. Neither observation window
  logged GPU errors.
- Added `verify-mgb64-ios-renderer.sh` and strengthened the standalone Fast3D
  verifier. Both SDKs passed and the ignored MGB64 checkout returned clean.
  The next production gate is validated private resource loading plus the
  smallest title/menu main loop—not further legal review.
- Rebuilt the ordinary core-free Simulator/device apps and packaged the
  foundation twice. Both eight-member audits passed with identical IPA SHA-256
  `2d28ed0e6944e60974d166450536ae0adb01b8a60fe5316198881a5710d39b03`;
  sorted app content matched
  `f67321b0f9c234e3b84895f373293c3782bcfa563f438c8608f996d366c8d2d1`.

## 2026-08-03 — compile Fast3D and hand off the UIKit Metal layer

- Isolated MGB64's Fast3D display-list interpreter and room-normal helper into
  an opt-in mobile static target. Target-local fail-closed shims cover the three
  desktop-only SDL/OpenGL calls without adding either framework to iOS.
- Built two-object, non-fat ARM64 archives for `iphonesimulator` and `iphoneos`.
  Both export `gfx_init`, `gfx_run_dl`, and `gfx_end_frame`; neither retains an
  unresolved SDL, desktop OpenGL readback, or OpenGL swap symbol.
- Added a reusable verifier that enforces the exact clean MGB64 pin, both SDKs,
  architecture/object/symbol expectations, and the desktop-dependency audit.
- Added an ARC Objective-C++ bridge implementing MGB64's existing
  `platformGetMetalLayer` entry point as a weak observation of GoldenPad's
  UIKit-owned `CAMetalLayer`.
- Rebuilt the default no-ROM app and ran iPhone 16 Pro first. The attached
  console logged the MGB64 handoff at 1206x2622; the app was removed and the
  phone shut down. Then iPad Pro 11-inch (M4) logged 1668x2420 and was likewise
  removed and shut down. The next gate is resolving and linking the combined
  Fast3D/Metal closure, not title/menu completion yet.
- Rebuilt the generic unsigned device app and retained `platformGetMetalLayer`
  in its final ARM64 executable. Packaged the current foundation twice; both
  eight-member ROM-free audits passed and both IPAs matched SHA-256
  `bf101037f91d723b6819e2fedefaa100de4582d9f685190cd4d0ed7e9b343e75`,
  with sorted app-content digest
  `8945edcf01b1cb760c2651e17eeb8017334c4b09318174459e4193b214a42f87`.

## 2026-08-03 — compile the MGB64 native Metal backend for iOS

- Isolated MGB64's complete native Metal renderer backend from its larger SDL
  platform target, along with only the color-combiner, backend-selector and MSAA
  support units it needs to compile.
- The first mobile build reached exactly two errors: macOS-only
  `CAMetalLayer.displaySyncEnabled` assignments. Added one exact-source patch
  that gates those writes to macOS; iOS presentation cadence remains with
  GoldenPad's existing `MTKView` lifecycle.
- Added an apply/build/reverse verifier that refuses dirty/mismatched upstream,
  builds both mobile SDKs, requires four-object non-fat ARM64 archives and the
  exported `gfx_metal_api`, then restores the upstream checkout.
- Both `iphoneos` and `iphonesimulator` passed. The 161-object core and linked
  app verifiers also passed again after the CMake build settings were shared
  between the core and Metal targets. The next gate is the SDL-free Fast3D
  frontend plus GoldenPad layer/drawable-size adapter.

## 2026-08-03 — select and compile the MGB64 production core

- Reframed the community decomp/recomp issue as a disclosed source and release
  risk rather than a GoldenEye-specific development stop. Kept paid access,
  official-store distribution and guaranteed-rights claims behind a separate
  qualified legal review, while preserving the hard ROM/XBLA/SDK exclusions.
- Selected MGB64 `cd9b58f5f91291579b8e551aa925aab000d311cf` as the
  reproducible production candidate. GoldenRecomp remains a useful static-recomp
  reference, but its public checkout still lacks the required TLB-free input and
  generated function tree.
- Added a guarded, opt-in CMake static core containing all 135 MGB64 game C files
  and 26 explicit native system/asset glue files. The exact pin and clean tree
  are enforced; no libultra/libultrare implementation source is compiled.
- Replaced the one desktop-only SDL keyboard include encountered in core-only
  compilation with a target-local inert scancode shim. The eventual platform
  target will use a real mobile input adapter rather than this compile seam.
- Built 161-object non-fat ARM64 archives for both Simulator and device SDKs at
  iOS 17 deployment target, then linked Release GoldenPad executables for both.
  The final binaries retain the exact core identity plus real upstream
  `randomSetSeed` and `randomGetNext` symbols.
- Launched iPhone 16 Pro first and visibly observed probe `0x80c24316`, removed
  and shut it down, then repeated on iPad Pro 11-inch (M4) with the same result.
  No ROM was selected or copied. This completes G1/A1b; the next gate is the
  MGB64 platform/renderer loop, not legal review or GoldenRecomp generation.
- Rebuilt the ordinary core-free foundation and packaged it twice. Both
  eight-member audits passed and both ZIPs matched SHA-256
  `93b089ca95ad6372ac49d4f69e3bd6645755431deea3a0bd0187d08f3246c4f1`;
  sorted app content matched
  `74cc07b77e58b72a168eab2d2404b035508cbaf0578aa96c8d5d315eaa3729a8`.

## 2026-08-03 — complete RT64 mobile static renderer gate

- Mapped RT64's remaining desktop seams to SDL window/events, NFD, inspector UI
  and host shader tools. Added three small embedded-host shims instead of
  carrying those desktop dependencies into the Apple target.
- Added a pinned incremental RT64 patch that consumes host-generated shader
  sources, compiles SDK-specific Metal libraries, excludes desktop tools and
  builds the full renderer for iOS. The verifier applies/reverses all patches
  around an exact clean reference checkout.
- Generated 113 shader blob sources, including all 56 Metal and 56 SPIR-V blobs,
  and built 210-object RT64 archives for `iphoneos` and `iphonesimulator`.
  Force-loaded all 246 RT64/Plume/re-spirv/zstd members into ARM64 link probes;
  neither probe retained SDL, NFD, AppKit, IOKit, X11 or macOS Vulkan symbols.
- Added an opt-in GoldenPad C++ bridge plus a default null stub. The ordinary
  ROM-free app still builds without `ref/`; explicit verified archives create a
  real Plume Metal device, direct command queue and swapchain on the existing
  UIKit-owned layer.
- The first Simulator launch exposed Plume calling the macOS-only Metal
  `location` selector on `MTLSimDevice`. Added a Simulator-only virtual-device
  fallback, reran the complete clean-source build, and kept the native hardware
  query unchanged.
- Built the linked Simulator app as ARM64. Ran iPhone 16 Pro first and visibly
  observed `RT64 Metal Apple iOS simulator GPU 1206x2622`, then terminated,
  uninstalled and shut it down. Repeated on iPad Pro 11-inch (M4) at 1668x2420,
  then removed and shut down that simulator. No game data was used.
- Built the linked Release app against `iphoneos`; its executable is ARM64 and
  the desktop-symbol audit remains empty. G2 is complete; G3 remains blocked on
  the production GoldenRecomp input/code-generation gate.
- Rebuilt the default null-bridge foundation and packaged it twice. Both
  eight-member ROM-free audits passed; both IPAs matched SHA-256
  `2fea2b01f1c2af095fbc77eb88f93bcdb62fd07356bab7a14deb3044a3903392`
  with sorted app-content digest
  `48eff2250257d920e472f7ad9763b40bd1b8ab13f5800a1ebf86c40a6f14c770`.

## 2026-08-03 — RT64 iOS Metal feasibility and surface boundary

- Confirmed pinned RT64 `5473732a` still matches current upstream and pinned its
  Plume submodule at `d890ac89` in the license inventory.
- Added narrow, reviewable patches for SDK-aware RT64 Metal generation and an
  iOS-safe Plume Apple backend. The probe applies only to exact clean references
  and reverses both patches on exit.
- Generated 56 RT64 MSL files and compiled all 56 independently for both
  `iphoneos` and `iphonesimulator`. Two runs reproduced the per-SDK aggregate
  digests in `RESEARCH.md`.
- Built patched Plume Apple/Metal ARM64 archives for device and Simulator and
  rebuilt the patched macOS Plume target. Full RT64 iOS configuration remains
  open at the desktop SDL2/NFD/window boundary; no RT64 binary is shipped.
- Added `AppleRenderSurface`, which owns the `MTKView` lifecycle and exposes the
  exact `UIView`/`CAMetalLayer` pair expected by RT64 while retaining the neutral
  foundation clear frame.
- Rebuilt and visibly accepted iPhone first, stopped it, then iPad. The visible
  status reported nonzero Metal drawable sizes on both; Home/reopen paused and
  restored rendering alongside the audio lifecycle.
- Rebuilt the unsigned generic-device ARM64 app. Two packages were byte-identical
  at SHA-256 `35b37ffacc24803a1550030e4c2885e17b2afbddff4458431bbc7caa4a0091bd`;
  the eight-member audit passed with content digest
  `bf1483d8e2a58f94076cfe9bff62608b5d2a3ab08273807b91a4a8c29fd61065`.

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
  executable is ARM64 and its complete app payload is roughly 324 KiB with no
  ROM or generated game assets.

## 2026-08-03 — core-blocker audit and platform services

- Built current N64Recomp and RSPRecomp plus their pinned dependencies as native
  Apple ARM64 tools. GoldenRecomp generation still stops at its missing modified
  ELF; no complete public `dump.toml` alternative is present.
- Searched current public GoldenRecomp forks, similarly named source repositories
  and static-recomp projects. Forks retain the unavailable game-code URL and do
  not publish generated functions or replacement metadata.
- Rejected the newer GoldenEye Metal path because it consumes Xbox 360 XEX/STFS
  data through a PowerPC/ReXGlue runtime, violating the original N64-only goal.
- Added sandbox platform paths for derived cache, saves and settings. Created
  directories were observed inside each simulator app container; the derived
  cache is excluded from backup.
- Added SwiftUI scene-phase handling backed by a real `AVAudioSession`, including
  activation, deactivation, interruption and route-change transitions.
- Rebuilt and visibly reran iPhone first, then iPad. Both reported `storage:
  sandbox ready` and `audio: session ready`; each install was removed and each
  simulator was shut down before moving on or concluding the pass.
- Generated a fully original gold/teal directional `G` icon with OpenAI's
  built-in image tool, resized the opaque RGB source to 1024×1024, recorded its
  provenance, and compiled it through Xcode's asset catalog.
- Visually accepted the real launcher icon on iPhone, removed/stopped that
  simulator, then repeated on iPad and removed/stopped it.
- Added deterministic unsigned-foundation-IPA packaging and a contamination
  auditor. Two consecutive packages had identical SHA-256 `d5c94ba3cfc476df417dd608ea5bc340b9d0a79d13e43c3e79f59f547d8071a9`;
  the eight-member payload and sorted-content digest passed all checks.

## 2026-08-03 — picker, persistence and normalized input

- Used the real Simulator UI to open the native Files picker on iPhone, cancel
  back to GoldenPad, remove/stop iPhone, then repeat on iPad. No retail file was
  selected or exposed in tracked evidence.
- Drove nonexistent-path and synthetic correct-size/wrong-hash validation on
  iPhone, removed/stopped it, then repeated on iPad. Both displayed the expected
  unreadable-file and SHA-1 mismatch states. Deleted the header-only fixture.
- Added schema-versioned, range-clamped host settings with sorted JSON and atomic
  data-protected writes. Added four bounded atomic opaque save slots.
- Wrote a non-game settings/save probe, terminated and relaunched the app, and
  visibly confirmed `storage: relaunch verified` on iPhone and then iPad. Both
  32-byte save probes had the same expected SHA-256; both app installs were
  removed after the pass.
- Added a common normalized input snapshot, deterministic player slots,
  `GCExtendedGamepad` mapping and touch/controller merge for player one.
- Added a neutral responsive touch input lab. Direct iPhone interaction produced
  movement `0.61,0.63` and FIRE `0x1`; iPad produced `0.64,0.62` and FIRE `0x1`.
- Tablet review caught left-clustered controls. Changed the lab to three equal
  responsive columns, rebuilt, and visually rechecked before accepting it.
- Attached to the app console, pressed Simulator Home, and reopened GoldenPad
  from the launcher. Audio deactivated in the background and reactivated at
  48 kHz on iPhone, then passed the same sequential gate on iPad.
- Generic device-SDK Release still builds as unsigned ARM64. Two fresh foundation
  IPA runs were byte-identical at SHA-256
  `82c4ca4939fe1b590892ed4706965ca3339926fb7ae9c88a9cd3b550010e12f9`;
  the eight-member audit passed with content digest
  `0783c88170cade31ac901e0fbbc274bacb5edae961f3cc96e42283d608eb4a2f`.

## 2026-08-03 — exact N64 mapping and customizable touch layouts

- Read the clean GoldenEye decomp as a primary behavioral reference and mapped
  the exact libultra A/B/Z/Start, D-pad, L/R and C-button masks without
  incorporating upstream source.
- Added classic N64, modern dual-stick and southpaw presets to one input frame.
  Modern FIRE produced Z `0x2000`; direct classic A produced `0x8000` on both
  tested simulator classes.
- Added separate phone/tablet layout defaults and schema-2 delta persistence.
  Per-control position, 70–150% size and visibility plus global opacity, scale,
  sensitivity, dead zone, gyro and external-controller auto-hide are exposed.
- Built a live editor with safe-area guides, tap selection, drag handling,
  accessible directional nudges and Reset. A single iPhone MOVE nudge persisted
  exactly one override; Reset returned the overrides dictionary to `{}`. The
  tablet profile was modified, relaunched and reset independently.
- Found that Simulator exposes an unattached synthetic MFi controller and
  initially triggered auto-hide. Limited the exclusion to Simulator builds and
  rechecked visible touch controls; physical-controller behavior is unchanged.
- Rebuilt and visually inspected iPhone first, removed/stopped it, then iPad in
  portrait and landscape. Both layouts stayed inside their safe areas. Direct
  finger drag, physical gyro and real-controller auto-hide remain device gates.
- Built the unsigned generic-device Release as ARM64. Two packages were
  byte-identical at SHA-256
  `582b1dbb832accc27bb0ffd3ae6c865b13c4d2fd7bcc72e81cb108bfc263ab9f`;
  the eight-member audit passed with content digest
  `35b91921a5a78500c2cd92d4cf1053233d91bd34a3dbd8d93ffa117f1294be2e`.
