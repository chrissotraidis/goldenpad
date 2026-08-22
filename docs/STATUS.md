# Status

Updated: 2026-08-22

## Current at a glance

| Surface | Current truth |
| --- | --- |
| Public release | Preview 2 is published with separately audited unsigned iPhone/iPad and arm64 Mac Alpha artifacts. |
| Primary runtime | Static GoldenEye ARM64 output + N64ModernRuntime + RT64/Plume/Metal. MGB64 is Legacy only. |
| Accepted baseline | Physical iPhone/iPad single-player, touch, Xbox/MFi P1, saves/preferences preservation, and the bounded four-view experimental render repair. |
| Major gameplay debt | Fire-rate authenticity remains blocked; the isolated modern-sidestep candidate passes code/Simulator gates but not physical acceptance. |
| Compatibility debt | A12X issue #9 is an unresolved first-frame RT64/Metal crash report, not an architecture/signing failure. |
| Local multiplayer | Experimental rendering works. An isolated disconnect-containment candidate passes code/Simulator gates; physical reconnect, real P2-P4 slots, and residual flicker remain open. |
| Network multiplayer | Not implemented. It is no-go until local ownership and deterministic state-hash gates pass. |
| Immediate engineering gate | Physically accept TD-02/TD-07 and classify TD-04 with the new bounded lifecycle probe; independently collect TD-05/06 discriminators. |
| Immediate user-facing repair | TD-02 code/Simulator work is complete; physical touch/controller feel remains before promotion. |

Documentation ownership:

- [`STATUS.md`](STATUS.md) states what is true now.
- [`TECH_DEBT.md`](TECH_DEBT.md) owns defect priority, evidence, and closure.
- [`PLAN.md`](PLAN.md) owns implementation order and stop rules.
- [`NEXT_STEPS.md`](NEXT_STEPS.md) is the short operational queue.
- [`TESTING.md`](TESTING.md) owns proof and acceptance procedures.
- [`ARCHITECTURE.md`](ARCHITECTURE.md) owns runtime and subsystem boundaries.
- [`MULTIPLAYER_ROADMAP.md`](MULTIPLAYER_ROADMAP.md) owns local/network scope and
  the network go/no-go decision.

## Summary

The statically recompiled GoldenEye + N64ModernRuntime + RT64/Metal app is now
GoldenPad's primary development runtime. The earlier MGB64/Fast3D app remains
buildable as `GoldenPad Legacy` for regression comparison and fallback. The
detailed current evidence and unresolved physical gates are recorded in
[`RT64_N64RECOMP_MORNING_HANDOFF_2026-08-21.md`](RT64_N64RECOMP_MORNING_HANDOFF_2026-08-21.md)
and [`RT64_N64RECOMP_PROTOTYPE.md`](RT64_N64RECOMP_PROTOTYPE.md).

The 2026-08-22 source review has been reconciled into
[`TECH_DEBT.md`](TECH_DEBT.md). It independently confirmed a global native-60-Hz
automatic-fire timing defect, the absence of a primary-runtime multi-controller
ownership layer, the modern sidestep mapping omission reported in issue #8, the
source mechanisms that can stall presentation/audio during drawable
backpressure, and two counter-invisible audio-risk classes. The exact priority,
certainty, smallest next test, and acceptance gate for each item now live in the
technical-debt ledger; the 1,668-line external review itself is supporting
analysis, not a runtime acceptance artifact. Subsequent isolated branches add a
Simulator-validated modern sidestep candidate and a controller-disconnect
containment candidate; neither has been merged into the Preview 2 baseline.

The Preview 2 signed iPhone/iPad release build launches real GoldenEye gameplay,
preserves its private ROM, save and preference payloads across in-place
installation, and has bounded single-player presentation/audio evidence. Touch
and Xbox/MFi Player 1 control paths, separate phone/tablet touch layouts with a
move/resize/opacity/reset editor, settings, diagnostics, return-to-menu plumbing,
lifecycle handling, and the targeted multiplayer address-mask crash repair are
integrated. The accepted iPhone touch editor, opacity control, phone
defaults, menu alignment, single-player gameplay and controller path received
hands-on acceptance in the preceding baseline. Multiplayer remains explicitly experimental: the latest
physical build removes the former large split-screen corruption, but slight
lighting flicker and real three/four-controller routing remain open.

The first physical-iPad viewport follow-up was rejected after two-player still
flashed in Player 2 and four-player corruption also reached the upper-right
view. Live video then showed the corruption recover and migrate between lower
views while the game loop remained healthy. The accepted repair matches
GoldenEye's shifted lower-player depth-image address during each clear, which is
required by RT64's exact-address depth-clear tracking. Its physical render-
control executable had SHA-256
`0976dcdfd17de60beda8e8e60ccff3fc81da7da0b2ef43f159cdea061149677d`.
It passed a 43.87-second four-player Simulator regression recording. Physical
four-player testing kept all four views coherent and did not reproduce
the former black/checkerboard corruption. The user rated it the best build so
far, with only slight residual lighting flicker. A 59.33-second device recording
remained coherent across 3,336 consecutive frame comparisons, while the paired
log reached 54,652 presented VI updates with zero audio drops or underruns. This
establishes the Preview 2 stable experimental multiplayer baseline. Multiplayer
is not yet bug-free or fully accepted pending the residual
flicker investigation and real three/four-controller routing.

GoldenPad officially supports Apple Silicon Macs in **Alpha** status. This is
the project's support status, not an official or commercial affiliation. The
current arm64 Release product is `GoldenPad.app`; its product, display name and
executable are all `GoldenPad`, and the final packaged-source executable
SHA-256 is
`7c78b72f4d6fd1697a5fb0572dfe22de6a8680d7df784ceb0752ef7b9527c35d`.
Hands-on review reached authentic gameplay with working keyboard and mouse
input, and the user intentionally quit after evaluating it. The build is stable
enough to retain as the Mac alpha baseline, but it is not at iPhone/iPad quality:
mouse look remains too slow, desktop controls remain less polished, a thin blue
strip persists at the far-right render edge, and longer performance testing is
still open.

Earlier Mac iterations are not fallbacks. Direct camera-field writes broke
input behavior; a mismatched generated patch removed the game-side mouse and
Crouch consumers; substituting Metal drawable size for RT64's window-size
contract expanded the thin blue edge into severe missing, duplicated and blue
world geometry; and unbounded per-frame AppKit dispatch starved input and audio.
The current source restores the matched input patch, retains the accepted
window-size contract, and coalesces pending Plume window/refresh updates. Those
rejected approaches and the remaining alpha debt are recorded in
[`TECH_DEBT.md`](TECH_DEBT.md). No more Mac renderer surgery is planned for the
coordinated update.

The current iPhone/iPad single-player baseline and the Mac alpha both passed
their latest hands-on launch/gameplay checks. This does not promote local
multiplayer or Mac sustained performance to stable-release status. The
coordinated repository update produces separate audited platform artifacts: an
iOS/iPadOS `.ipa` and an arm64 macOS Alpha archive containing `GoldenPad.app`.

The exact final Preview 2 mobile executable SHA-256 is
`100ee12be02e2077e7559f6cd4ead210bb933abffb87874cf76a16afa06e67a9`.
It was installed in place on the connected iPhone and iPad as version `0.1.0`
build `2` without changing app-data UUIDs
`3ACA6644-5550-4EEA-BDCA-D6F9D3827161` and
`D2F4E1F3-F310-4A01-8ED7-65B907FAA17B`. Independent pre/post readbacks on both
devices matched the Documents ROM, runtime ROM, active save, backup save and
preferences; the exact build launched successfully on both devices. The user
approved this exact rebuilt executable for publication after hands-on review.

The audited Preview 2 mobile artifact is
`GoldenPad-0.1.0-preview.2-unsigned.ipa` at SHA-256
`704bdf68f67d1f0925fd1844ab865c263a79e105a6349ef410f365602e6c77e3`.
Its 18-member archive passed the ROM/save/signing/private-path audit and has
sorted unsigned app-content SHA-256
`bce1606fb88cf5a2a423875073871a8417d66f7b1462568bbbae390b72d1a5ec`.
The audited Mac Alpha artifact is
`GoldenPad-0.1.0-preview.2-macos-arm64-alpha.zip` at SHA-256
`7a9e7342b0ae39518f73807f854b479d9691fd612ae6861ea527f2a19e4450a4`;
its 20-member archive has sorted app-content SHA-256
`d07294bb9f9c1ca903ae7d9f84f5a75b1886796163fc2680b2a3730f38b3a342`.
It contains a native arm64 macOS app, an ad-hoc signature, the GoldenPad icon
and required notices, with no ROM, save, private path or non-system dependency.

Exact Preview 1 signed executable
`c0aee770a84482ee73e26042774ffd4119a09c73df20ff985327fc8ca08bea6f`
is installed in place on the physical iPhone 14. Its accepted layout was read
back and promoted to the clean-install phone defaults. The iPhone app-data UUID
remained `3ACA6644-5550-4EEA-BDCA-D6F9D3827161`, its preference file remained
byte-identical at
`12e163bce76605fb852efc0d38a31d38aecbdbd7d6ef5da7d6fffa55d9d73ffd`,
and the unrecorded corrected launch remained alive as PID `4987`. The prior
exact executable was also accepted on both physical devices. Their
app-data UUIDs remained `3ACA6644-5550-4EEA-BDCA-D6F9D3827161` and
`D2F4E1F3-F310-4A01-8ED7-65B907FAA17B`; independent pre/post readbacks matched
for both ROMs, both saves and each device's preferences. Normal unrecorded
launches remained alive as iPhone PID `4732` and iPad PID `6696`.

The audited unsigned Preview 1 package is
`GoldenPad-0.1.0-preview.1-unsigned.ipa` at SHA-256
`a3aa37003a56a498820d07e84de89660d309c2cde40d0911fb3826086caca3e9`.
It contains no ROM/save/signing material and requires re-signing plus a
user-derived TLBFREE file copied through Finder file sharing. The long MGB64
evidence ledger below is preserved as historical validation for
`GoldenPad Legacy`.

## Passed

- ROM/reference/build/signing exclusions are active.
- Local retail V64 is ignored, 12 MiB, normalizes to the supported US SHA-1, and
  was never copied into the tracked tree or a package.
- Required initial research/legal/architecture/plan/build/test/worklog docs exist.
- The configured production target has a machine-checked 236-entry source
  license manifest: 161 original-game/decompilation files, 52 MGB64 MIT files,
  19 GoldenPad-original files, two Fast3D/Perfect Dark cases and two embedded
  header implementations. The IPA now carries the corresponding third-party
  notices, which the production package verifier requires.
- MGB64 `cd9b58f` builds as native ARM64 on Apple Silicon with default WebGPU.
- MGB64's native SDK-surface guard passes at the exact pin. Its native CMake
  target compiles no `src/libultra/**` or `src/libultrare/**` implementation
  sources; matching-target SDK-lineage files remain outside GoldenPad's source
  and binary boundary.
- MGB64's exact public-export source surface now builds and reports 100% passed
  across 103 CTest entries on macOS; 10 ROM/browser/optional-binary cases skip
  explicitly. The maintained patch fixes Bash 3 parsing, uses upstream's
  portable timeout helper, and prevents tests that directly import
  export-ignored fidelity tools from leaking into the public suite. The verifier
  applies the patch to a temporary Git checkout and restores `ref/mgb64` clean.
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
- Physical controller face buttons no longer combine incompatible N64 actions.
  The old A mapping emitted A+B together; exact binary
  `d6249e072a279a07a31835147a30006510a512fcddf09955c55c47a5c95f10cb`
  now maps A/Y to N64 A and B/X to N64 B, and its isolation probe passed. The
  compact Controllers reference was inspected phone-first and then unchanged on
  iPad. This proves mapping and menu presentation, not a real gamepad playtest.
- The Controllers page now exposes Players 1–4 instead of only a total count.
  Touch is visibly owned by Player 1, and each connected controller can move to
  another player slot; an occupied destination swaps the two controllers. Exact
  Simulator binary
  `369dcbdf0cfbc0b3d6439305f7b5bc524bab5004077e6da60ad6dfc7776abd13`
  moved the synthetic MFi controller from Player 1 to Player 2 on iPhone, then
  repeated unchanged on iPad. Its linked input probe proved touch remains absent
  from Players 2–4. Physical multi-controller acceptance remains open.
- The selected native desktop core now passes a maintained private two-player
  startup gate. It booted a Temple deathmatch, reported clean assertions and
  render health, produced two distinct viewports with 94.548% changed pixels,
  and reached the configured 120/120-tick timer. The verifier deletes its
  ROM-derived artifacts and restores the exact upstream pin clean. This proves
  M2's core split-screen path, not a person completing a match.
- The authentic mobile mode-select path now exposes a clear touch + gamepad
  preparation flow. With the Simulator gamepad still merged into Player 1, the
  original Multiplayer row was disabled. Moving that gamepad to Player 2 made
  the row available. Exact Simulator binary
  `ad158472f316e184ec155de42985f8847d0e77c8fa33be83d4b43fe3c2728071`
  now explains the required move and changes to a green `Two-player touch +
  gamepad is ready` state. Both native states were inspected on iPhone and then
  unchanged on iPad. This closes discoverability, not match completion.
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
- The next human-control pass fixes two defects found in the live landscape phone
  layout: Weapon/Duck no longer occupy the home-indicator strip, and the
  Action/Fire/Aim rail is inset from the rounded edge. LOOK now accumulates all
  gesture deltas received before the renderer's next input sample rather than
  overwriting earlier movement. Exact Simulator binary
  `818f1733fac43edec9a759c81874faf3b6b5bd0d1558c1fdecfb3f76520291a0`
  passed `Touch look accumulation probe: PASS`, the full linked build, and a
  clean-layout inspection on iPhone first and then unchanged on iPad. This
  removes observable layout/event-loss defects; real-finger comfort remains open.
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
- The final public-menu recheck used exact Simulator executable
  `818f1733fac43edec9a759c81874faf3b6b5bd0d1558c1fdecfb3f76520291a0`.
  Phone FIRE resize/move/hide persisted across relaunch and Reset restored its
  116% default; selecting 4× produced 3496×1608. After phone cleanup, the iPad's
  independent profile repeated resize/move/hide persistence and Reset without
  inheriting phone state. The same app exposed the complete settings hierarchy
  cleanly on both form factors. This closes the final Simulator menu review, not
  signed physical-touch acceptance.
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
- Commit `2bc7920` packages the game-bearing device app through a production
  gate that requires MGB64's `bossEntry` plus the Fast3D/Metal entry points.
  The working tree and a fresh clone produced byte-identical eight-member IPAs
  at SHA-256
  `73a70d94633c21b318453fea5979a8434b3cf9a09c9e1429c4a46556c43fbe5b`.
  Both unsigned ARM64 payloads passed the ROM, signing, private-path and
  game-core symbol audits; sorted app-content SHA-256 is
  `2af801fed7b7902e3622862d2232237fc338988d079ed0752e9fc9a5e50fb016`.
- The current notice-bearing package at `09e02a0` has nine members and passed
  those audits plus the source-manifest/notices gate in two independent fresh
  clones. Their IPA/content pairs were `6991d719...744f` / `c9d10678...22d4`
  and `7a225bd8...1624` / `83221d7b...671`. Every member except the executable
  matched; the optimized Swift ROM byte-order helper differed by one equivalent
  20-byte `__text` layout. That historical result reopened P2; P3 remained closed.
- Current source commit `94242be` keeps P2 closed with fresh evidence. Two independent
  clean checkouts built identical device executables at SHA-256
  `43bfe1b5a0cfe46b16f48eeb33130ab3efd36bb1a1521adeba3db0277c91f389`
  and byte-identical nine-member IPAs at SHA-256
  `6eed064c79ca7a9ebedb6a3cb2f4a5d97a8cd0ab426fa9503e94db535c3c738d`.
  Both reported sorted app-content SHA-256
  `aed6b2725e2deac8cddb7c0901dca2d385f6966474125bdb5d5f1a628e408a6c`
  and independently passed every production package audit.

## Failed or blocked

- The primary runtime runs GoldenEye's simulation at native 60 Hz but does not
  carry MGB64's source-level player/guard automatic-fire authenticity repair.
  The pinned lineages identify this as roughly a three-times-fast automatic
  cadence. GoldenPad's opt-in probe recorded one ordinary Dam guard at 13, 17,
  and 18 committed events per 100 ticks. Three player tap windows matched ammo
  to events, but the sustained player gate is formally blocked until an
  ordinary setup provides at least 34 KF7 rounds without state injection.
- Preview 2 modern touch/controller movement does not provide modern-FPS
  sidestep semantics. The isolated TD-02 candidate maps live Modern MOVE-X to
  native C-left/C-right while preserving menus, watch, settings, LOOK, and
  Original mode in code/Simulator gates. Physical iPhone/iPad and controller
  acceptance remains, so [issue #8](https://github.com/chrissotraidis/goldenpad/issues/8)
  stays open and Preview 2 remains the release control.
- The published Preview 1 artifact crashes deterministically at the first RT64
  rendered frame on a reported A12X iPad Pro. A12X meets the declared ARM64,
  Metal, device-family, and OS requirements; treat [issue #9](https://github.com/chrissotraidis/goldenpad/issues/9)
  as an unresolved A12/RT64 compatibility defect or support-floor decision, not
  a signing or CPU-architecture failure. A complete redacted `.ips` and a
  Preview 2 A12-family reproduction remain open.

- Local multiplayer remains experimental. The earlier crash and large physical
  split-screen corruption are repaired in the frozen Preview 2 baseline, but
  slight lighting flicker remains. Enhanced multiplayer visuals and networking
  are deferred in [`MULTIPLAYER_ROADMAP.md`](MULTIPLAYER_ROADMAP.md).
- An opt-in iOS/iPadOS four-player render diagnostic now advertises neutral
  Players 3/4 without changing normal input routing. Its first ARM64 iPad
  Simulator Temple run entered a real four-player match with all quadrants
  correctly placed. Player 1 pause/watch remained isolated to its quadrant and
  Player 1 controller plus Player 2 touch events registered independently.
  All four views remained intact through 10,773 presented VI updates. The later
  physical four-player run kept every quadrant coherent and is accepted as a
  stable experimental render baseline. Real Player 3/4 controller routing is
  not implemented or accepted.
- The isolated TD-07 candidate prevents paired-controller loss from silently
  moving touch to Player 1, publishes a neutral boundary before reassignment,
  retains the active controller across enumeration reorder, and separates
  overlay from scene suspension. Its red/green model and controller-P1/touch-P2
  Simulator integration pass. Physical disconnect/reconnect timing and stable
  real P2-P4 controller slots remain open.
- Screenshot/background resume has previously frozen gameplay and needs a
  dedicated physical lifecycle pass. An isolated opt-in TD-04 discriminator now
  distinguishes no runtime progress from presentation-only stalls. One retained
  Simulator resume recovered and one froze with game/render/audio counters flat
  while diagnostics/input stayed live. No repair is selected from Simulator
  evidence alone.
- A small amount of audible static has been reported during otherwise working
  audio; long-session speaker and route-change acceptance remains open.
- Some maps can still expose original or renderer-specific geometry/clipping
  artifacts. Preview 1 does not claim complete stage/effect parity.
- Preview 2 includes the bounded in-app retail-ROM importer. Exact physical
  first-run and negative-path acceptance on both iPhone and iPad remains open
  quality work; a valid Preview 1 TLB-free input is preserved and reused.
- The packaged executable retains six anonymous `/private/tmp/goldenpad-recomp.*`
  compiler source literals from prebuilt runtime archives. The verifier allows
  only those exact patterns and rejects user-home paths or other temporary paths.
  Removing them requires rebuilding the archives and is tracked as hardening debt.

## Next gate

Preview 2 is published as a prerelease with separately audited mobile and Mac
Alpha artifacts. The hosted downloads matched their published checksums and
passed the same package verifiers as the local artifacts. TD-01's measurement
probe is retained, but its sustained-player baseline is formally blocked until
an ordinary setup provides at least 34 KF7 rounds. The immediate human gates are
TD-02 touch/controller feel and TD-07 held-input disconnect/reconnect/lifecycle.
Independent unattended work should collect bounded TD-04/05/06 discriminators
before selecting renderer or audio fixes, while issue #9 remains evidence-only.
Do not begin network transport before stable local ownership and deterministic
state hashes, and do not import matching-target SDK implementation sources or
Xbox/XBLA material.
