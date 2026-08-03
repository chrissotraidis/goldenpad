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
- GoldenPad's opt-in MGB64 target compiles all 135 game translation units, 70
  explicit upstream native system/portable units and five project-owned mobile
  adapters into 210-object, non-fat ARM64 archives for both
  `iphonesimulator` and `iphoneos` at the iOS 17 deployment target. Release app
  executables link for both SDKs.
- Final-binary inspection confirms the exact MGB64 commit, bridge identity/probe
  symbols and real upstream `randomSetSeed`/`randomGetNext` code. Sequential
  no-ROM launches reported deterministic probe `0x80c24316` on iPhone 16 Pro,
  then iPad Pro 11-inch (M4); both installs were removed and devices shut down.
- MGB64's complete native Metal backend plus its combiner, backend selector and
  MSAA helper compile into four-object non-fat ARM64 archives for both mobile
  SDKs. The only source changes required were guards around two macOS-only
  `CAMetalLayer.displaySyncEnabled` writes. The verifier applies and reverses
  that exact-source patch, confirms `gfx_metal_api`, and leaves upstream clean.
- MGB64's Fast3D display-list interpreter, room-normal helper, screenshot-series
  service and texture-pack services compile into five-object, non-fat ARM64
  archives for both mobile SDKs. The archive exports
  `gfx_init`, `gfx_run_dl`, and `gfx_end_frame` and retains no unresolved SDL,
  desktop OpenGL readback, or OpenGL swap symbols.
- GoldenPad now implements MGB64's exact `platformGetMetalLayer` contract with a
  weak ARC bridge to the UIKit-owned layer. Sequential no-ROM launches logged
  the handoff at 1206x2622 on iPhone 16 Pro, then 1668x2420 on iPad Pro 11-inch
  (M4); each install was removed and each simulator shut down.
- The Fast3D frontend and native Metal backend now link together in the opt-in
  GoldenPad app. A temporary mobile selector patch chooses Metal directly, and
  a small host bridge supplies conservative renderer settings plus explicitly
  null ROM state. Final ARM64 Simulator and `iphoneos` binaries retain
  `gfx_init`, `gfx_metal_api`, both lifecycle bridge calls and
  `platformGetMetalLayer`, with no SDL/OpenGL/AppKit dependency.
- Strict sequential runtime proof initialized MGB64's real Metal backend and
  encoded/presented its first ROM-free empty frame at 1206x2622 on iPhone 16 Pro,
  then 1668x2420 on iPad Pro 11-inch (M4). Both runs reported one-sample MSAA,
  no GPU errors during the observation window, and were removed/shut down.
- The existing exact-SHA-1 validator now installs supported normalized bytes
  into a core-owned volatile buffer only when MGB64 is linked. The C boundary
  rechecks 12 MiB size, N64 header and internal title. Sequential private V64
  runs logged the handoff on iPhone, then iPad; each entire app container and
  its temporary source copy was removed before shutdown.
- The core now includes upstream's generated native ROM offsets and one-byte,
  zero-content asset-symbol placeholders. After validation it patches the
  complete file table and verifies the first background plus Dam entries point
  inside the owned buffer. Both final SDK binaries link the patch function;
  sequential iPhone/iPad runs reported `MGB64 file table ready` before cleanup.
- A narrow mobile OS adapter now closes the real MGB64 scheduler's libultra host
  surface without importing upstream's monolithic SDL input/audio layer. It
  initializes upstream `os_scheduler`, both message queues and the graphics
  client for final Simulator and device binaries. Sequential private-ROM runs
  reported `MGB64 scheduler ready` at 1206x2622 on iPhone, then 1668x2420 on
  iPad; each app/container was removed and each simulator shut down.
- The UIKit-owned draw callback now offers a cooperative retrace only after the
  scheduler is ready and only while its graphics queue is empty. Before a game
  consumer exists this caps the queue at one message. Attached-console runs
  reported `MGB64 cooperative retrace delivered` at 1206x2622 on iPhone, then
  1668x2420 on iPad, with strict uninstall/shutdown cleanup between them.
- Real GU matrix/vector helpers are now isolated from upstream's monolithic
  desktop SDL compatibility unit in a project-owned mobile source file. Both
  final SDK apps retain `guNormalize`; the deterministic core probe now executes
  a 3/4/0 normalization before the upstream random check and still reports
  `0x80c24316` sequentially on iPhone and iPad. A temporary non-executing
  `bossEntry` link probe confirmed all 15 GU blockers are closed and reduced the
  remaining startup gap from 261 to 246 symbols; the probe was then removed.
- The next audited closure slice adds 28 small upstream SDL-free leaf units for
  segment constants, native trig/stdio compatibility and isolated gameplay
  fidelity helpers. Representative paths now execute in the deterministic core
  probe, which remained `0x80c24316` sequentially on iPhone and iPad. A fresh
  temporary `bossEntry` map closed 61 symbols, introduced none and left 185;
  the normal core and combined-renderer gates then passed after probe removal.
- A mobile configuration owner now supplies the 68 game settings/startup globals
  previously trapped inside `platform_sdl.c`, without importing its SDL event or
  window ownership. The deterministic probe executes representative defaults and
  remains `0x80c24316` sequentially on phone/tablet. The startup map closes all
  68 names with no new symbol and now leaves 117.
- Five additional real upstream services now supply model conversion, stage
  lookup, radial input, setup-name resolution and weapon cue tables. A mobile
  data unit supplies ten native game constants and one ROM offset previously in
  the monolithic compatibility file. Representative paths execute in the
  unchanged phone/tablet probe; the startup map closes 20, introduces none and
  leaves 97.
- The mobile OS host now supplies thread-safe message queues, delayed/repeating
  timers, `osClockRate`, and a 16 Kbit EEPROM-compatible memory surface. A new
  neutral UIKit-owned host supplies input, frame-stat, deterministic-mode,
  renderer-recovery and lifecycle-watchdog seams, while upstream's portable
  overlay-hook unit remains the real owner of overlay dispatch. The live probe
  blocks on a real delayed timer and round-trips the last EEPROM block.
- MTKView retrace ownership is now explicit across attach, active, inactive and
  detach states. Once UIKit is configured, the game thread waits for its real
  producer; it does not synthesize frames while the app is inactive. The queue
  operations are safe across the future background game thread and UI thread.
- A fresh temporary `bossEntry` force-link map closed exactly 27 host symbols,
  introduced none and reduced the remaining boundary from 97 to 70. After probe
  removal, both SDK core/renderer gates passed. Strict no-ROM runtime proof then
  showed probe `0x80c24316` and first Metal frames at 1206x2622 on iPhone,
  followed by 1668x2420 on iPad; each app was uninstalled and each simulator
  shut down before proceeding.
- Real upstream settings, trace, decoration, screenshot, texture-pack and
  clean-room native audio modules close the remaining startup boundary. The
  permanent background-launch bridge now retains `bossEntry`, `portAudioInit`,
  the sequence synthesizer and SFX mixer in both final SDK apps with zero
  unresolved startup symbols and no duplicate definitions.
- The validated-ROM path starts `bossEntry` once on a detached game thread only
  after the UIKit Metal renderer and scheduler are ready. MTKView stops drawing
  empty host frames after launch and supplies retraces while the game thread
  submits real display lists through Fast3D/Metal.
- The setup shell yields to a landscape gameplay surface with independent
  phone/tablet touch profiles. Swift samples touch and assigned Game Controller
  state once per MTKView frame and publishes exact N64 stick/button state plus
  modern right-stick aim to the C host. The deterministic bridge probe observed
  `stick=39,-59`, `right=-7947,-31789`, `buttons=0x6000` and passed.
- The real MGB64 audio decoder/mixer now pumps on consumed retrace messages. Its
  22.05 kHz stereo output enters a bounded project-owned PCM ring and is pulled
  by an `AVAudioSourceNode`; `AVAudioEngine` performs device-rate conversion.
  Runtime proof requires rendered frames and non-zero samples and passed on
  both simulator classes.
- Strict private-ROM runtime proof rendered the GoldenEye title animation and
  loaded multiple demo-stage setup/resource sets at 2622x1206 on iPhone 16 Pro,
  then 2420x1668 on iPad Pro 11-inch (M4). Both runs decoded 261/261 SFX,
  parsed 75 music instruments, initialized the native sequence synthesizer,
  reported non-zero PCM, and were fully removed/shut down in sequence.
- The diagnostic `--menu-probe` path publishes one-frame Start presses through
  the normal Swift-to-N64 controller bridge; it does not call menu or stage
  functions. Strict iPhone-then-iPad runs traversed the authentic front end,
  selected Agent/Dam, reached menu 11 and observed the game thread change from
  title stage 90 to active Dam stage 33. Private visual inspection confirmed
  live Dam gameplay and native touch overlays at 2622x1206 and 2420x1668. Both
  installs and temporary ROM copies were removed before simulator shutdown.
- The diagnostics-only `--gameplay-probe` waits for Dam's frozen intro camera to
  release, then drives the normal normalized touch/N64 path while reading an
  atomic game-thread snapshot. On iPhone and then iPad it proved position change,
  real aim mode plus view-angle change, PP7 fire (magazine 7 to 6), B reload/action
  (6 to 7), A weapon cycling (item 5 to 1), and Start watch/pause entry. Private
  inspection confirmed the moved Dam viewpoint and open watch; both runs received
  full uninstall/shutdown cleanup.
- The 16 Kbit game EEPROM is now mutex-protected across the game/host threads,
  restored from Application Support at bootstrap, and atomically flushed with
  file protection on scene deactivation/backgrounding. Strict sequential
  write/terminate/relaunch probes produced the same exact 2,048-byte SHA-256 on
  iPhone and iPad before uninstall/shutdown cleanup.
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
  the 920 KiB ARM64 executable, project-owned icon renditions and `Assets.car`.
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
  `fb866882eca3ae019b145eed9dd0ab8efd3b0ddb20594433eb45fa40ad608dae`.
  Its eight-member payload passed extension, ROM-header, known-hash, signing,
  private-path and ARM64 checks. Its sorted app-content SHA-256 is
  `102337b9cb2a07b4471f7e015c7c06459643de98f6d68c62bdae630308e827cd`.

## Failed or blocked

- MGB64 GL/Metal-only fallback fails to link: unresolved `gfx_webgpu_api`.
- MGB64 CTest is not clean: 8/106 failed and 10 skipped on this host.
- GoldenRecomp's `lib/ge` submodule URL is unavailable.
- GoldenRecomp generated function directories are absent from clean checkout.
- Full valid-ROM picker selection still needs a safe private Files fixture;
  current valid-ROM evidence invokes the same validator through an explicit
  automation launch argument after the picker UI itself was proven.
- Mission completion and post-mission progression persistence, context-sensitive
  world interaction, crouch/objectives flow, physical-controller/gyro acceptance,
  touch-only mission completion,
  multiplayer, final game-bearing
  unsigned IPA, or final archive audit yet. Simulator UI automation proved the
  editor's accessible nudge path; direct finger drag remains a physical-device
  interaction gate.

## Next gate

Exercise real gameplay actions through the connected touch path, then complete
Dam on Agent and verify the resulting EEPROM progression survives relaunch.
Do not import matching-target SDK implementation sources or Xbox/XBLA material.
