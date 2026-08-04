# Status

Updated: 2026-08-04

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
- The startup PCM diagnostic now polls the existing rendered-frame/nonzero-sample
  atomics for up to 30 seconds instead of declaring failure at one fixed
  eight-second instant. Cold Metal startup had produced repeatable early false
  negatives. Exact Simulator binary
  `2b83740c5fb394dd3ced14a25fd75bc76ba42a7c47468a6f1a2e8c22c15c102e`
  reported `Native PCM output probe: PASS after 10s` on iPhone, then unchanged
  on iPad; both were removed and shut down sequentially.
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
- The explicitly scripted `--mission-flow-probe` now proves the game-owned
  mission-report and save seam without claiming organic completion. After normal
  menu traversal and live Dam start, a game-thread request mirrors MGB64's
  existing diagnostic success contract and enters `bossReturnTitleStage()`.
  GoldenEye then writes folder-one Dam/Agent time `1023`, shows mission status
  menu 12, accepts normal A input to statistics menu 13, and accepts normal B
  input back to mission select. After lifecycle background flush, the same
  install restored `completed=1 time=1023` on relaunch. This passed strictly on
  iPhone then iPad with full uninstall/shutdown cleanup.
- The input-only MGB64 desktop route
  `dam_native_multiwaypoint_input_traversal` independently passed at the pin
  with 902 records, 4794.07 world units and no setup automation. GoldenPad's
  `--dam-route-probe` reaches the same stock spawn through authentic menus,
  waits for `CAMERAMODE_FP`, and uses only normal controller frames. A bounded
  20-frame final-input tail covers iPad render cadence while preserving the
  4700-unit gate. iPhone passed at 5038 and iPad at 4784; their read-only
  objective vectors stayed `[0,0,0,0]` with `stateMutation=0`. This proves
  deeper Dam traversal, not objective progress.
- `--dam-nav-probe` now reads the loaded Dam waypoint graph, chooses the
  reachable minimum-Z node with a private breadth-first search, and publishes
  only its next target. Its linked-switch oracle reads the live setup and
  selects the nearest linked door ahead on the active graph edge. Swift reaches
  those targets with ordinary movement, look and B frames; it never writes a
  transform, door, objective or mission state. The final strict same-binary run
  passed first on iPhone (`distance=15917`, `destinationDistance=493`) and then
  iPad (`distance=15879`, `destinationDistance=499`). Both ended at source 182
  toward destination 179 with objectives `4:[0,0,0,0]` and `stateMutation=0`.
  This proves the upper Dam graph and real two-door interlock, not the
  disconnected lower bungee graph or organic objective completion.
- `--dam-bungee-probe` structurally finds the retail AI sequence that tests
  Bond's room, locks control and applies forced velocity, then derives its lower
  exit pad without embedding retail coordinates. An exploratory phone run
  crossed the live interlock and padlocked gate with normal controller frames
  and reported `room=64/64`, `force=0,400`, objectives `4:[0,0,0,1]`,
  `controllerOnly=1` and `hostMutation=0`. Repeated clean-phone promotion runs
  instead reproduced an actor/linked-door collision stop with the slab at
  `open=750/1000`; the phone-first gate therefore failed and iPad was not run.
- The input-only MGB64 desktop route
  `facility_spawn_obj159_door_traversal_contract` independently passed at the
  pinned commit with a 1291.83-unit displacement, real door-allow/transition/
  displacement/finish-open events, and no direct state automation. GoldenPad's
  `--facility-door-probe` uses the same input windows after authentic front-end
  traversal and a scripted Dam-success prerequisite, but waits for Facility's
  real `CAMERAMODE_FP` transition before starting. The stock door model object
  159 reached `open=90000`, `max=90000`, with opening and finished-open states
  observed; normal controller input moved Bond 702 world units. The exact same
  app passed first on iPhone and then iPad, with uninstall and simulator shutdown
  after each. The mobile gate deliberately requires the 680-unit post-door
  milestone plus full door opening; it does not claim the desktop route's later
  1200-unit reach, Facility objectives, or organic mission completion.
- MGB64's promoted
  `facility_spawn_obj159_obj155_door_chain_contract` independently passed with
  1402 records, 1291.82 units of movement, both door models fully opened and no
  setup automation. The upstream left-movement continuation opens a different
  same-model door under mobile timing, so GoldenPad's
  `--facility-door-chain-probe` instead uses a fixed backward continuation and
  right-stick/B sweep after the exact first-door input stream. Its snapshots are
  pad-specific: two model-159 records at pads 67/68 and one model-155 record at
  pad 75. iPhone opened all targets fully and reached 817 world units; iPad
  repeated the result at 827. Both reported `open=90000`, `max=90000`, opening
  and finished-open states, then received full uninstall and simulator-shutdown
  cleanup. This is deeper normal-input Facility progression, not objective or
  mission completion.
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
- GoldenPad now declares and filters one N64 ROM document type covering Z64,
  V64, N64 and ROM extensions. Files **Open in GoldenPad** feeds the same
  security-scoped validator as the picker. Exact binary
  `91f1a1a87ab02eb7fc983e510f388e49bb8003bc31de88211a4d09a87f1faee5`
  received a real Files-origin open event, validated V64 and reached game Metal
  rendering plus PCM on iPhone, then unchanged on iPad. Both private Files
  copies and app containers were removed before sequential shutdown.
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
- Touch axes are now kept separate from physical-controller noise filtering, so
  drift-free touch input no longer receives the Swift dead zone plus MGB64's
  second dead zone. Mobile right-stick shaping is linear; the existing
  sensitivity setting remains available. This is a focused response fix, not
  hands-on acceptance.
- The old mobile FPS source was wrong: it counted every 60 Hz `MTKView` callback
  and therefore described presentation refresh as game FPS. The corrected
  maintained patch ticks only when MGB64 submits a game display list through
  `rspGfxTaskStart`, retaining the monotonic 250 ms window and two-second 1% low.
  Exact binary `057a5883725ee3bf972bd4fb9c4acfa766e5ec7a57eb2ce79ffbde62f347b43e`
  reported 51.8 FPS/19.31 ms/29.2 low on iPhone and, unchanged, 21.8 FPS/45.93
  ms/15.6 low on iPad at 2420x1668. Both displays remained 60 Hz, proving the
  meter no longer parrots refresh rate.
- A live editor provides per-control move, 70–150% size and hide/show controls,
  with the movement stick protected from hiding. Phone and tablet defaults are
  separate; schema-2 settings persist only changed placements. On iPhone, one
  MOVE nudge saved exactly one placement delta and Reset returned overrides to
  `{}`. The equivalent tablet profile and reset were exercised independently.
- The current UI was rebuilt and inspected sequentially on iPhone 16 Pro and
  iPad Pro 11-inch (M4) in portrait and landscape. The full editor remained
  inside safe areas, settings relaunch persisted, and the Simulator's synthetic
  MFi controller no longer falsely hides touch controls.
- Human-play v2 defaults now use a large relative-drag look surface instead of
  the cramped fixed right stick, a larger movement stick and one contextual
  Action control in place of duplicate Use/Reload buttons. Old experimental
  placement overrides do not mask the v2 defaults. The exact Simulator binary
  (`b795af2cb266ffc6103c941937397b8cd855b823b8529db960b9c5c16b361ac8`)
  was visually inspected first on iPhone 16 Pro and then unchanged on iPad Pro
  11-inch (M4); the look drag and editor were exercised during the same v2
  iteration.
- Human-play v3 defaults enlarge the MOVE/LOOK capture regions and action
  targets. Southpaw now mirrors the action cluster to the left instead of
  overlapping it with the right-side movement stick. New v3 layout keys keep
  older experimental overrides from masking these defaults.
- Human-play v4 changes LOOK from a sustained virtual stick into direct swipe
  deltas consumed once per input publish. A stopped thumb now returns to neutral
  instead of continuing to rotate. Action/Fire/Aim form one outside rail and
  Weapon/Duck sit on a lower utility row; Southpaw mirrors it. The accessible
  live surface accepted bidirectional swipes and AIM Off -> On on iPhone first,
  then the unchanged app on iPad. Physical-finger feel remains open.
- The in-game gear now opens a native Game Settings hub instead of jumping
  directly into layout editing. It groups only implemented settings into
  Controls, Touch Overlay and Physical Controllers, then presents the correct
  iPhone or iPad layout editor one level deeper. The exact Simulator binary
  (`e1f2c1a2e17658fe8b44fad84221cf712a9c9b065d856739ca924492843038f9`)
  was exercised phone-first and then unchanged on iPad; the phone form scrolls
  in landscape and the iPad form sheet exposes all three sections.
- Game Settings now uses a native hub-and-detail hierarchy: Touch Controls owns
  aim/overlay/layout, Controllers owns dead zone/status, and Display owns the
  1×–4× scene-resolution selector and opt-in Performance HUD. Schema 5 persists
  both display preferences; resolution defaults to 1× and the HUD defaults off.
  The game drawable changes while native SwiftUI controls remain sharp.
- Exact Simulator binary
  `c71c1630c4930bf60eb2827373025a1fe0431b6b364c53ca0155fa46b45d6681`
  live-switched all four levels in the visible native menu on iPhone first and
  then unchanged on iPad. Logged targets were 874×402, 1748×804, 2622×1206 and
  3496×1608 on iPhone; iPad produced 1210×834, 2420×1668, 3630×2502 and
  4840×3336. Both private app containers were removed and both simulators shut
  down after the sequential pass.
- Modern touch AIM now defaults to Toggle, allowing the same right thumb to tap
  AIM and return to the direct-swipe LOOK surface. Hold remains selectable in
  Game Settings. Switching modes clears a latched aim state, schema 4 persists
  the preference, and older settings decode to Toggle. The layout editor now
  owns only placement/size/visibility; the setup lab and in-game gear share the
  native settings hub.
- The linked Simulator/device verifier passed. Exact Simulator binary
  `9cf79b52bd44b13208271ba9b1fc9ff049b564e10787d1f27cbe4eb08a2a5266`
  reached live rendering with the phone controls, then unchanged with the iPad
  controls. Phone terminate/relaunch retained an explicit Hold value, while a
  clean iPad container encoded schema 3 with the Toggle default. This proves
  build, runtime layout and persistence, not real-finger aim feel.
- The native settings modal now owns a real game boundary: presenting it
  neutralizes touch input, pauses MTKView presentation, external retrace and FPS
  sampling, while scene activity remains independently tracked. Dismissal
  resumes only when the scene is active. Control-preset changes also clear all
  latched touch state.
- Exact Simulator binary
  `3a787f8a1d612b701b54862bc8a2dcd782c9a2e1e0bb2d3eff24ed4403646d28`
  was driven phone-first and then unchanged on iPad. On both, AIM reported
  Off -> On, Game Settings exposed the visible `Aim button` label and accessible
  `Aim button behavior` group, presentation logged
  `paused scene=1 overlay=1`, Done logged `resumed scene=1 overlay=0`, and AIM
  returned Off. This is Simulator interaction proof, not physical-touch feel.
- Original project-owned app art is compiled into phone/tablet icon renditions
  and was visually accepted on both simulator launchers. Provenance is recorded
  in `ART.md`.
- The current unsigned foundation IPA was created twice with identical SHA-256
  `fb866882eca3ae019b145eed9dd0ab8efd3b0ddb20594433eb45fa40ad608dae`.
  Its eight-member payload passed extension, ROM-header, known-hash, signing,
  private-path and ARM64 checks. Its sorted app-content SHA-256 is
  `102337b9cb2a07b4471f7e015c7c06459643de98f6d68c62bdae630308e827cd`.
- The current game-bearing device app now packages through a distinct production
  gate that also requires MGB64's `bossEntry` plus the Fast3D/Metal entry points.
  Two consecutive local packages were byte-identical at SHA-256
  `6fe7bbc17e4271e03bfc1be202e3debe0dc5fb5e5864da2c9d788fe615c062c7`.
  The eight-member unsigned ARM64 payload passed the ROM, signing, private-path
  and game-core symbol audits; its sorted app-content SHA-256 is
  `1708463a1665974cded140570edf70db07cfd1f6695c9ca8455156107c323769`.
  Clean-checkout reproduction remains open.

## Failed or blocked

- MGB64 GL/Metal-only fallback fails to link: unresolved `gfx_webgpu_api`.
- MGB64 CTest is not clean: 8/106 failed and 10 skipped on this host.
- GoldenRecomp's `lib/ge` submodule URL is unavailable.
- GoldenRecomp generated function directories are absent from clean checkout.
- Hands-on control feel is not yet accepted: v4 fixes the continuous-turn look
  defect and separates the action rail from most of the swipe region, but
  sensitivity and button placement still need real finger playtesting and tuning.
  `xcrun devicectl list devices`
  currently reports `No devices found` on this Mac, so this pass could not run
  signed physical-touch acceptance.
- Performance is not accepted. Resolution scaling proves that pixel workload is
  controllable, but produced-game cadence remains scene- and host-load-sensitive;
  the final 1× binary's early sample was only 4.9 FPS on iPhone and 7.8 FPS on
  iPad during this Simulator pass. Do not infer physical-device performance or
  sustained mission cadence from a single startup window.
- Organic mission completion, traversal from upper Dam node 179 into the lower
  bungee graph and a real objective, deeper Facility progression, crouch/objectives
  flow, physical-controller/gyro acceptance, touch-only
  mission completion, multiplayer, clean-checkout game-bearing
  unsigned IPA reproduction, or final archive gate yet. Simulator UI automation proved the
  editor's accessible nudge path; direct finger drag remains a physical-device
  interaction gate.

## Next gate

The Apple shell, native game boot, renderer, audio, save path and menu schema are
substantially integrated, but the complete port is not at definition of done.
The remaining product gates are human touch/controller mission completion,
scene-specific performance profiling, organic save progression, local
multiplayer, physical lifecycle/audio/controller acceptance, the source-level
license manifest and a clean-checkout game-bearing unsigned IPA audit.

With no physical device attached, the next unblocked production slice is the
source-license/package gate. When hardware is available, hands-on playtest v4 on
iPhone, tune swipe sensitivity/action placement, then repeat the accepted layout
unchanged on iPad. Keep diagnostics as bounded smoke coverage only; do not
extend bot navigation as a product gate.
Do not import matching-target SDK implementation sources or Xbox/XBLA material.
