# Worklog

## 2026-08-04 — prepare the public release surface and reaccept settings

- Reworked the README from an engineering chronology into a HarkinianPad-style
  public guide with an install-status table, feature matrix, first-launch flow,
  touch/controller/scaling reference, ROM-free diagram, limitations, FAQ,
  project map and direct legal boundary. It advertises no public IPA or physical
  hardware acceptance that has not occurred.
- Refined the existing project-owned app icon with OpenAI's built-in image tool,
  using only the earlier GoldenPad icon as input. The opaque 1024×1024 source is
  SHA-256 `90978310...fc15d`; Xcode compiled readable 120px iPhone and 152px iPad
  launcher renditions at `a3a49b31...37038` and `f72163f4...157745`.
  The compiled icon was then inspected by name on the clean iPhone Home Screen,
  removed with that app container, and repeated unchanged on the iPad Home Screen.
- Rebuilt the complete linked game/Metal/audio closure. With no ROM installed,
  the final settings hierarchy visibly exposed Modern/N64/Southpaw setup,
  Touch Controls, Physical Controllers, 1×–4× rendering and the opt-in
  Performance HUD on phone first and then iPad.
- On iPhone, selected FIRE, changed it from 116% to 126%, nudged it right,
  hid/showed it, saved, terminated/relaunched, confirmed 126% persisted, and
  Reset restored 116%. Selecting 4× produced the expected 3496×1608 drawable.
  The separate iPad profile repeated 116% -> 126%, a left nudge, hide/show,
  relaunch persistence and Reset to 116% without inheriting the phone edit.
- Both app containers were removed and both simulators shut down. Exact
  Simulator executable is `818f1733...291a0`; the working package passes all
  nine-member game-core/notices/ROM audits with device executable
  `43bfe1b5...1f389`, IPA `6eed064c...c738d` and sorted app content
  `aed6b272...08a6c`. Physical-finger and device-performance acceptance remain
  open and are stated that way publicly.
- P2 was re-run from the exact public-release source commit `94242be`. Two clean
  checkout paths independently reproduced device executable `43bfe1b5...1f389`,
  byte-identical IPA `6eed064c...c738d` and sorted content `aed6b272...08a6c`,
  with every linked build, source-license, notices and ROM audit passing.

## 2026-08-04 — remove touch swipe loss and phone edge conflicts

- Inspected the live current game overlay rather than extending gameplay
  automation. On landscape iPhone, Weapon/Duck overlapped the home-indicator
  strip and the outer action rail sat against the rounded edge; the iPad layout
  did not share those conflicts.
- Inset the phone Action/Fire/Aim rail and raised its Weapon/Duck utility row
  while leaving the separate tablet defaults unchanged. Existing per-control
  layout overrides remain authoritative.
- Changed relative LOOK input to accumulate every gesture delta received before
  the renderer samples it. The old setter silently kept only the latest event,
  making fast swipes vulnerable to lost motion at variable frame cadence.
- The linked Simulator/device build passed. Exact Simulator binary
  `818f1733fac43edec9a759c81874faf3b6b5bd0d1558c1fdecfb3f76520291a0`
  reported `Touch look accumulation probe: PASS` on iPhone and showed the clear
  revised layout, then ran unchanged with the unaffected iPad layout. Both apps
  were removed and both simulators shut down.
- The ROM scan, source-license manifest and nine-member unsigned IPA audit pass.
  Working-tree hashes are device executable `43bfe1b5...1f389`, IPA
  `e27f9ef6...1335c5` and sorted app content `61cf3850...6acdc8`. Human physical
  touch feel and touch-only mission completion remain open.

## 2026-08-04 — make touch + gamepad multiplayer discoverable

- Drove the current iPad app through private ROM validation, the authentic file
  menu and mode-select screen using the visible mobile controls. With touch and
  the synthetic gamepad both assigned to Player 1, GoldenEye correctly rendered
  Multiplayer disabled because the core exposed only one connected player.
- Used the native Controllers page to move the gamepad to Player 2. The original
  Multiplayer row immediately became available, proving the assignment UI is
  connected to the real controller-count gate rather than being display-only.
- Added one concise stateful instruction to the existing page. Before assignment
  it says how to enable touch + one-gamepad multiplayer; afterward it shows a
  green `Two-player touch + gamepad is ready` confirmation. Exact Simulator
  binary `ad158472f316e184ec155de42985f8847d0e77c8fa33be83d4b43fe3c2728071`
  was inspected phone-first and then unchanged on iPad.
- The full linked Simulator/device build, source-license manifest, ROM scan and
  game-bearing IPA audit passed. This improves the human menu schema and proves
  authentic multiplayer availability; it does not claim match setup or play.
- P2 was re-run after the source change, not inherited from the prior commit.
  Two clean checkouts of `705b58a` produced identical device executables at
  SHA-256 `8fa09749...43eb9`, byte-identical IPAs at `ca39138d...79312`, and
  matching sorted app-content SHA-256 `9ddac5ff...9502e`.

## 2026-08-04 — close current unsigned-IPA reproducibility

- Re-tested P2 from current commit `651e4fe` instead of relying on the older
  notice-bearing mismatch. Two independent local clean clones fetched the exact
  MGB64 pin and built the complete Simulator and device game/Metal/audio closure
  under different absolute paths.
- Both device executables matched SHA-256
  `48e97f9bd63b5c1d9da5428c4472fb280d055fead337addfe7a4165d94a260f6`.
  Both nine-member IPAs were byte-identical at SHA-256
  `4e05ad08dfef3a0c7beeff6bdea116ec304d06641c0a44b31c31792cee1ac94f`
  and reported sorted app-content SHA-256
  `00c7579a1c913f2452b2237e44fb4f511a06c7e609dab56dea0d5dc86460d41e`.
- Each clone independently passed the source-license manifest, unsigned ARM64,
  game-core symbol, third-party notice, private-path and ROM-contamination
  audits. The working-tree package reports the same content digest.
- The historical 20-byte optimized Swift layout difference remains documented.
  Current evidence supersedes it for P2 without deleting the contrary record or
  changing gameplay code.

## 2026-08-04 — expose multiplayer ownership and prove split-screen startup

- Replaced the Controllers page's total-count status with visible Player 1–4
  assignments. Player 1 states its touch ownership, each connected controller
  has a Move menu, and moving into an occupied slot swaps the two controllers.
- Isolated touch composition behind one pure ownership function and added it to
  the linked input probe. `Multiplayer touch ownership probe: PASS` requires
  touch/gyro/sensitivity to affect Player 1 only while Players 2–4 remain exact
  controller snapshots.
- Exact Simulator binary
  `369dcbdf0cfbc0b3d6439305f7b5bc524bab5004077e6da60ad6dfc7776abd13`
  showed Player 1 `Touch + Gamepad` on iPhone, moved the synthetic controller to
  Player 2 while Player 1 remained `Touch`, and repeated unchanged on iPad. The
  full linked Simulator/device build passed, and both installs were removed and
  simulators shut down sequentially.
- Added a maintained macOS compatibility patch and verifier for upstream's
  two-player smoke. The final private run booted a Temple deathmatch, produced
  two distinct healthy viewports with 94.548% changed pixels, and reached the
  two-second 120/120-tick limit. All ROM-derived output was removed and the
  exact upstream checkout restored clean.
- This closes neither M1 hardware acceptance nor D5/M2 human match completion.
  It establishes a usable assignment UI and proves the native split-screen core
  beneath the remaining hands-on product gate.

## 2026-08-04 — close the public MGB64 ROM-free test gate

- Reproduced the stale internal result and classified all eight failures. They
  split between public-harness Bash 3 compatibility defects and tests or
  dependencies belonging to upstream's export-ignored private fidelity/evidence
  surface rather than GoldenPad's public production input.
- Added one exact-pin maintained patch: release guards retain their existing
  patterns with Bash-3-compatible conditionals, the bad-ROM test uses upstream's
  portable timeout helper, and two tests that directly import private fidelity
  tools follow the existing export-ignore boundary.
- Added a clean public-export verifier that applies the patch only in a
  disposable Git checkout, builds the desktop core and runs CTest without ROM
  data. The final run reported 100% passed across 103 entries with 10 explicit
  ROM/browser/optional-binary skips, then restored `ref/mgb64` clean.
- This closes D6 test infrastructure. It does not replace hands-on touch and
  controller play, organic mission/save completion, multiplayer or physical
  device acceptance.

## 2026-08-04 — isolate physical controller face buttons

- Fixed a real controller translation defect: physical A previously inserted
  both Confirm and Interact, which the common mapper emitted as N64 A+B in the
  same sample. A now emits only N64 A; B and X emit N64 B; Y and the right
  bumper emit N64 A/next weapon.
- Added a pure face-button isolation probe to the existing input diagnostic. It
  requires A/Y to equal only `0x8000` and B/X to equal only `0x4000`; the linked
  app reported `Physical face-button isolation probe: PASS` through the real
  mobile launch path.
- Replaced the controller page's ambiguous connected-count-only presentation
  with a compact mapping reference. Exact Simulator binary
  `d6249e072a279a07a31835147a30006510a512fcddf09955c55c47a5c95f10cb`
  showed every mapping row without horizontal clipping on iPhone, then showed
  the same mapping plus status in the iPad form sheet. Both installs were
  removed and both simulators shut down; the full linked Simulator/device
  verifier passed.

## 2026-08-04 — recycle completed Metal upload textures

- Profiled cold and warm Simulator gameplay before changing the renderer. The
  cold eight-second sample spent all 3,320 sampled game-thread frames below
  runtime Metal shader-library creation, explaining why the first FPS window
  was not representative. After warm-up, 2,427 of 3,217 samples were active in
  the game loop and 811 reached `newTextureWithDescriptor` through repeated
  indexed-texture uploads.
- Added one bounded recycler to the maintained MGB64 Metal patch. Evicted RGBA
  upload textures are held in their existing three-frame ring slot and become
  reusable only after that slot's semaphore wait proves its prior GPU work has
  completed. The pool is keyed by dimensions and capped at 1,024 resources.
- In the equivalent post-change sample, 3,141 of 3,662 game-thread samples were
  normal retrace sleep, only 484 were active in `bossMainloop`, and just 76
  reached `newTextureWithDescriptor`; reused textures instead reached
  `replaceRegion`. A visible title-scene inspection showed intact rendering.
- The complete maintained Simulator/device renderer verifier passed, upstream
  applied and reversed cleanly, and the game-bearing unsigned IPA again passed
  source-license, notice, ROM, signing, private-path, ARM64 and game-core audits.
  This is a Simulator profile and removal of the first measured warm bottleneck,
  not physical-device FPS acceptance. Cold runtime shader compilation remains.
- A terminate/relaunch profile then separated first-run shader cost from normal
  startup. Metal's automatic per-app cache reduced synchronous shader creation
  to 2 of 3,702 game-thread samples on the second launch. The remaining title
  workload was mainly Simulator-driver XPC in `replaceRegion`; that transport is
  not a physical-device result. A custom shader cache or font-atlas rewrite is
  therefore deferred until hardware profiling demonstrates a product bottleneck.

## 2026-08-04 — inventory production licenses and bundle notices

- Generated a 236-entry source manifest directly from the configured
  game-bearing target. It classifies 161 original-game/decompilation sources,
  52 MGB64 MIT sources, 19 GoldenPad-original sources, two Fast3D/Perfect Dark
  cases and the two single-header implementations that enter compiled code.
- Added a verifier that regenerates the list and fails on any source-set drift
  or unclassified path. This closes R3 without pretending MGB64's MIT license
  applies to decompiled GoldenEye code or inventing an outbound GoldenPad
  license.
- Added `ThirdPartyNotices.txt` to the app resources with the applicable MGB64,
  n64-fast3d-engine, Perfect Dark, cgltf, jsmn and stb_image notices. The
  production IPA verifier now rejects an archive that omits those notices.
- The complete Simulator/device linked build, 236-entry manifest verification
  and local nine-member IPA audit passed. Two independent fresh clones of exact
  commit `09e02a0` then fetched MGB64 pin `cd9b58f5`, built both SDK apps and
  passed every production archive audit.
- Those two notice-bearing clean IPAs were not byte-identical. Every payload
  member except the executable matched; optimized Swift code generation used
  two equivalent layouts in the ROM byte-order helper, differing by 20 bytes
  of `__text`. The observed IPA/content digest pairs were `6991d719...744f` /
  `c9d10678...22d4` and `7a225bd8...1624` / `83221d7b...671`. P2 is reopened;
  the product package and P3 contamination proof remain valid.

## 2026-08-04 — add explicit 1×–4× native resolution controls

- Added a persisted four-level Display control instead of a vague
  Performance/Native switch. The scene drawable now scales 1×, 2×, 3× or 4×
  relative to UIKit points; the touch overlay remains native SwiftUI. 1× is the
  performance-first default and 4× is optional supersampling at 16 times the
  1× pixel count.
- A first live implementation recursively changed `MTKView.drawableSize` from
  its own resize delegate and stack-overflowed. The crash report identified the
  exact loop; the final implementation mutates size only from configuration or
  the render pass while the resize callback is observation-only.
- The maintained linked verifier passed for ARM64 Simulator and device SDKs.
  Exact Simulator binary
  `c71c1630c4930bf60eb2827373025a1fe0431b6b364c53ca0155fa46b45d6681`
  then live-switched 1×/2×/3×/4× to 874×402/1748×804/2622×1206/3496×1608 on
  iPhone, followed by 1210×834/2420×1668/3630×2502/4840×3336 on iPad. Both
  private ROM app containers were uninstalled before sequential shutdown.
- The final 1× startup windows reported 4.9 FPS on iPhone and 7.8 FPS on iPad,
  materially below an earlier 1× trial and proving that resolution choice alone
  does not close performance. The HUD remains truthful; sustained scene-specific
  profiling and physical-device acceptance remain open.
- Replaced the stale foundation-only production package path with a game-bearing
  unsigned IPA gate. It requires `bossEntry`, `gfx_init` and `gfx_run_dl` in the
  archived ARM64 executable, then applies the existing signing, ROM, private-path
  and member audit.
- The first fresh-clone package correctly exposed two reproducibility defects:
  MGB64's compiled `__FILE__` strings varied by checkout path, and the prior
  `strings | grep -q` private-path scan could be defeated by `pipefail` when
  `grep` exited early. Compiler prefix mapping now emits stable relative source
  identities, and the verifier consumes the complete string stream.
- Commit `2bc7920` then rebuilt both SDK apps in a new untouched clone. Its IPA
  exactly matched the working-tree package at SHA-256
  `73a70d94633c21b318453fea5979a8434b3cf9a09c9e1429c4a46556c43fbe5b`;
  both reported sorted app-content SHA-256
  `2af801fed7b7902e3622862d2232237fc338988d079ed0752e9fc9a5e50fb016`
  and passed all production archive audits. That historical artifact closed
  P2/P3 at the time; the notice-bearing clean-build comparison above later
  reopened byte-level P2 while leaving P3 closed.

## 2026-08-04 — fix the real FPS source and make look input swipe-based

- Corrected the opt-in Performance HUD at its source. Mobile no longer calls
  `platformFrameStatsTick` from every 60 Hz `MTKView` callback; the maintained
  MGB64 patch calls it when `rspGfxTaskStart` submits an actual game display
  list. The screen refresh rate, game-frame rate and simulation cadence are no
  longer mislabeled as the same number.
- Replaced the modern LOOK surface's sustained virtual-stick response with
  incremental swipe deltas. Each delta is published once and then cleared, so
  a stationary or lifted thumb cannot leave the camera turning. The v4 defaults
  also place Action, Fire and Aim on one outside rail and move Weapon/Duck to a
  lower utility row, preserving more uninterrupted swipe area. Southpaw mirrors
  the same geometry.
- The maintained linked verifier passed for ARM64 Simulator and device SDKs.
  Exact Simulator binary
  `057a5883725ee3bf972bd4fb9c4acfa766e5ec7a57eb2ce79ffbde62f347b43e`
  launched with a private ignored ROM on iPhone 16 Pro, where the 60 Hz display
  produced `Game-frame cadence: PASS 51.8 FPS 19.31 ms 1% low 29.2`. Computer
  Use drove the visible LOOK surface in both directions and verified AIM changed
  from Off to On. The app/container was then uninstalled and the phone shut down.
- The unchanged binary then ran on iPad Pro 11-inch (M4) at 2420x1668. Its 60 Hz
  display produced `Game-frame cadence: PASS 21.8 FPS 45.93 ms 1% low 15.6`;
  visible iPad swipes and the Off-to-On AIM transition were exercised too. The
  app/container and private ROM copy were removed before iPad shutdown. These
  are Simulator interaction and truthful telemetry checks, not physical-finger
  comfort or mission-completion acceptance.

## 2026-08-04 — launch from a user-selected ROM in Files

- Declared one imported Nintendo 64 ROM content type for `.z64`, `.v64`, `.n64`
  and `.rom`. The native picker now filters to that type instead of accepting
  arbitrary data, and cancelling leaves the setup screen unchanged rather than
  reporting an invalid file.
- Registered GoldenPad as an alternate viewer for that type and routed Files
  `Open in GoldenPad` events through the same security-scoped validator used by
  the in-app picker. An import is ignored once the native game is already
  running, avoiding destructive mid-session ROM replacement.
- Exact Simulator binary
  `91f1a1a87ab02eb7fc983e510f388e49bb8003bc31de88211a4d09a87f1faee5`
  received a real Files-origin `UIOpenURLAction` on iPhone 16 Pro, validated a
  private V64, started MGB64 and reached Metal rendering plus native PCM. The
  app, private Files copy and phone container were then removed and the phone
  shut down.
- The unchanged binary repeated that chain on iPad Pro 11-inch (M4), reporting
  the 2420x1668 surface, `Validated ROM installed; MGB64 scheduler ready`, 60 Hz
  presentation cadence and native PCM readiness. The iPad private Files copy,
  app container and all temporary inspection images were deleted before
  shutdown. The maintained linked verifier passed both Simulator and device SDK
  targets, and the ROM-safety audit remained clean.
- Computer Use could identify Simulator but timed out before returning its
  accessibility tree, so the already-proven picker open/cancel path was not
  re-driven. The complementary Files Open In route supplies actual supported-ROM
  selection evidence without a private launch argument; physical Files-provider
  behavior remains a device gate.

## 2026-08-04 — keep gameplay acceptance human and refine the mobile controls

- Reaffirmed that automated mission routes are diagnostic leftovers, not a
  product requirement. Production acceptance is ordinary launch plus a human
  completing gameplay with touch or a physical controller.
- Added v3 phone/tablet defaults with larger MOVE and LOOK capture regions and
  larger action targets. Fixed a concrete Southpaw defect by mirroring the
  action cluster away from the right-side movement stick instead of allowing
  the two thumb zones to collide. The v3 key deliberately leaves experimental
  v2 placement overrides behind.
- Reorganized Game Settings into a native hierarchy: preset and destinations
  live in the hub, Touch Controls owns aim/overlay/layout, Controllers owns
  stick response/status, and Display owns the Performance HUD. This keeps the
  landscape phone form short and gives the iPad sheet clear subpages.
- The game FPS overlay is now off by default and opt-in through Performance HUD.
  Internal presentation-cadence logging remains active for diagnostics, so the
  debug readout is not confused with the game's simulation rate.
- The maintained linked verifier built and inspected the Simulator and device
  SDK targets. Exact Simulator binary
  `a4dd8336e96320aa1a53c3d81f10663f5e035fac06ec7f35cb2b86cecbc5d7ad`
  launched with private ROM input on iPhone 16 Pro, was removed and shut down,
  then launched unchanged on iPad Pro 11-inch (M4). Direct captures showed the
  v3 Modern overlay and no default FPS box on both. No physical device is
  attached, so real-hand feel remains open and is not claimed by this pass.
- After adding the schema-4 HUD field to the existing persistence probe, the
  final linked Simulator/device rebuild also passed; its Simulator binary is
  `14efc201561e3eb675cd73bfc604b83ea3ac21e5ba427cb0bc583f83f86ce966`.

## 2026-08-04 — pivot acceptance to human controls and ship v2 defaults

- Shelved the unfinished Dam bungee-route experiment instead of extending bot
  navigation. Diagnostic routes remain bounded smoke coverage; human touch and
  controller play now own gameplay acceptance.
- Replaced the small fixed look stick with a broad relative-drag surface,
  enlarged movement and removed the duplicate B-based Reload button in favor
  of one contextual Action control. New v2 phone/tablet layout keys prevent old
  experimental overrides from hiding the defaults.
- The maintained linked Simulator and device build matrix passed. The exact
  Simulator binary, SHA-256
  `b795af2cb266ffc6103c941937397b8cd855b823b8529db960b9c5c16b361ac8`,
  was inspected on iPhone 16 Pro and then unchanged on iPad Pro 11-inch (M4);
  the drag/editor flow was exercised during the same v2 iteration. Real-finger
  feel remains open.
- Added a native Game Settings hub organized around the controls that actually
  exist: preset/look/gyro, touch overlay visibility/size and physical-controller
  dead zone/status. The device-specific layout editor is one level deeper. The
  exact Simulator binary
  `e1f2c1a2e17658fe8b44fad84221cf712a9c9b065d856739ca924492843038f9`
  was exercised first as a scrollable iPhone landscape form and then unchanged
  as an iPad form sheet.
- Made the modern touch AIM control latch by default so the right thumb can
  return immediately to the broad LOOK surface. Game Settings exposes Toggle
  and Hold as implemented choices, and changing modes releases any latched aim
  state. Schema 3 persists this preference while decoding older settings as
  Toggle.
- Removed feel/visibility controls from the layout editor; it now owns placement,
  size and visibility only, while the native Game Settings hub owns behavior.
  The setup lab routes to that same hub instead of presenting a second settings
  surface.
- The maintained linked Simulator/device verifier passed. Simulator binary
  `9cf79b52bd44b13208271ba9b1fc9ff049b564e10787d1f27cbe4eb08a2a5266`
  reached live rendering with the phone overlay, then unchanged with the tablet
  overlay. A phone terminate/relaunch probe retained the explicit Hold value;
  a fresh iPad container encoded schema 3 with the Toggle default. Real-finger
  aim feel remains the acceptance gate.
- Audited the broad LOOK surface against button hit-testing. LOOK is deliberately
  earlier in the Z-stack and the later circular action controls retain their own
  hit regions, so no overlap fix was needed. The review instead found that
  native Game Settings allowed the game clock to run behind its sheet.
- Added independent scene and native-overlay presentation state. Opening Game
  Settings now neutralizes touch, pauses MTKView/external retrace/FPS sampling,
  and Done resumes only in an active scene. Preset changes also neutralize touch.
- The UI pass found and fixed two accessibility/schema defects: the canvas no
  longer overwrites AIM's `On`/`Off` value with `Visible`, and the Toggle/Hold
  selector now has visible `Aim button` text plus an accessible behavior label.
  The Computer Use review directly drove both corrections.
- Linked Simulator/device builds passed. Exact Simulator binary
  `3a787f8a1d612b701b54862bc8a2dcd782c9a2e1e0bb2d3eff24ed4403646d28`
  produced the complete Off -> On -> settings/pause -> Done/resume -> Off flow
  on iPhone 16 Pro, then unchanged on iPad Pro 11-inch (M4). Both apps were
  removed and both simulators shut down. `xcrun devicectl list devices` returned
  `No devices found`, so real-finger feel remains open.
- The fast menu passes exposed a false-negative evidence bug: the native PCM
  probe sampled once at eight seconds, before cold Metal startup had produced
  nonzero audio, and printed FAIL even though the path became ready shortly
  afterward. Replaced that instant with one-second polling and a strict
  30-second timeout; the underlying rendered-frame/nonzero-sample contract is
  unchanged.
- Linked Simulator/device builds passed. Exact Simulator binary
  `2b83740c5fb394dd3ced14a25fd75bc76ba42a7c47468a6f1a2e8c22c15c102e`
  reported `Native PCM output probe: PASS after 10s` on iPhone, then unchanged
  on iPad. Both installs were removed and both simulators shut down.

## 2026-08-03 — narrow the Dam promotion blocker to live-guard recovery

- Expanded the read-only linked-door guard search to the full local interlock
  area. A clean phone run then crossed the previously blocked paired slabs,
  destroyed the lower padlock with ordinary fire and reached the final
  room-64 approach before its generic surface recovery oscillated.
- Added bounded controller-only recovery for a guard standing between Bond and
  a switch, resumed chamber movement immediately after the one warning shot,
  and added a two-phase lateral/converging move for the final room boundary.
- Kept automated Use in the live controller state for one display sample while
  retaining the queued fallback. On the next clean phone run the first eligible
  `0x1ff` switch sample opened the slab immediately; the earlier 45 consecutive
  missed pulses did not recur.
- Promotion is still closed. The latest clean phone run was killed by the live
  guard during the second interlock before its obstruction recovery fired, so
  there is no iPad claim. The app/container were removed and the phone
  simulator was shut down. Linked simulator and device builds still pass.

## 2026-08-03 — replace zero FPS telemetry and remove duplicate touch shaping

- Replaced the mobile host's permanently zero `PlatformFrameStats` stub with a
  mutex-protected monotonic sampler driven by real `MTKView` presentation
  callbacks. It publishes FPS/frame time every 250 ms, computes a two-second
  1% low and resets its history across scene inactivity.
- Delayed the one-shot runtime proof until generation 16 so startup ROM/audio
  work has aged out. The exact same app reported `60.0 FPS 16.67 ms 1% low 54.8`
  on iPhone, then `60.0 FPS 16.67 ms 1% low 54.7` on iPad. The phone HUD also
  visibly showed `60 FPS 16.7ms` and `1% low 60` during live Dam gameplay.
- Applied the user-selected radial dead zone only to physical-controller axes,
  leaving drift-free touch input direct. Disabled MGB64's second mobile dead
  zone and changed the mobile look curve from 1.5 to linear 1.0. Diagnostic
  routes are unaffected because they use their explicit controller frames.
- Simulator and device linked renderer builds pass, the new symbols are part of
  both binary audits, and both Simulator installs were removed and shut down in
  strict phone-then-tablet order. Touch feel remains open for real hands-on
  acceptance even though the duplicate shaping defect is fixed.

## 2026-08-03 — derive the retail bungee trigger and expose a strict blocker

- Added a structural scan for the loaded Dam AI sequence that tests Bond's
  room, locks control and applies forced velocity. It derives the lower exit
  pad and publishes read-only navigation, linked-door, guard and padlock state;
  no retail coordinate or state mutation is embedded in the host.
- Added `--dam-bungee-probe`, which continues the live waypoint route, handles
  the padlocked gate with ordinary controller input, and accepts only the real
  room trigger plus forced velocity. A diagnostic-only one-read button queue
  preserves B presses across the `osContGetReadData` boundary; normal held user
  controls are unchanged.
- An exploratory phone run observed the retail trigger at `distance=28461`,
  `pad=330`, `room=64/64`, `force=0,400`, objectives `4:[0,0,0,1]`,
  `controllerOnly=1` and `hostMutation=0`.
- Repeated clean-phone promotion runs instead reproduced a linked-door
  collision stop with the slab at `state=2 open=750/1000`, including through
  frame 14700. The phone app was terminated/uninstalled and its simulator shut
  down; iPad was not run because the phone-first gate failed.
- The linked simulator and device verification matrix still passes. This is an
  exploratory retail-trigger proof plus a reproducible promotion blocker, not
  organic Dam completion. At this checkpoint, hands-on controls were poor and
  the visible FPS value was untrusted; the later entry above addresses the
  concrete duplicate-shaping and zero-counter defects.

## 2026-08-03 — cross Dam's live two-door interlock

- Added a read-only Dam waypoint snapshot and private breadth-first navigator.
  Source, target and destination positions come from the loaded retail setup;
  the host contains no copied ROM coordinates and does not write game state.
- Added a read-only linked-switch oracle that chooses the nearest linked door
  ahead on the active waypoint edge. Controller recovery aligns with the live
  switch, sends normal B input, respects the paired gate's WAITING/OPENING
  states and keeps walking until the first slab clears.
- Strict same-binary acceptance passed first on iPhone at
  `distance=15917 destinationDistance=493` and then on iPad at
  `distance=15879 destinationDistance=499`. Both finished source 182 toward
  destination 179 with objectives `4:[0,0,0,0]` and `stateMutation=0`; each app
  was terminated, uninstalled and its simulator shut down in sequence.
- The endpoint is the reachable upper node 179/pad-140 area. The bungee trigger
  remains on a disconnected lower graph, so organic bungee activation and Dam
  completion remain open. At that checkpoint, hands-on controls were still poor
  and the visible FPS counter was still untrusted; the later entry above records
  the concrete response and telemetry fixes.

## 2026-08-03 — promote MGB64's clean Dam route to mobile

- Audited MGB64's Dam campaign contracts and separated its controller-only
  `dam_native_multiwaypoint_input_traversal` from the scripted objective and
  mission-result contracts. The pinned desktop route passed independently at
  4794.07 world units with no setup automation.
- Added `--dam-route-probe`, which reaches Agent/Dam through the authentic front
  end, waits for `CAMERAMODE_FP`, and publishes the upstream forward, C-right,
  forward+C-right, and forward-left sequence through the ordinary controller
  bridge. A bounded 20-frame continuation of the last input compensates for the
  higher-cost iPad surface while retaining MGB64's 4700-unit acceptance line.
- Added a read-only game-thread snapshot of Dam's camera mode and four objective
  statuses. The probe does not write player, stage, mission, or objective state.
- The final strict iPhone-then-iPad run reached 5038 and 4784 world units. Both
  began with four incomplete objectives and ended with the same `[0,0,0,0]`
  vector and `stateMutation=0`. Each install/private ROM was removed and each
  simulator shut down before continuing.
- This proves deep stock-spawn Dam traversal under normal controller input. It
  deliberately does not claim objective progress or organic mission completion.

## 2026-08-03 — extend Facility to a two-door input chain

- MGB64's promoted
  `facility_spawn_obj159_obj155_door_chain_contract` passed independently at the
  exact pin with 1402 records, 1291.82 units of movement, both door models fully
  opened and no setup automation.
- Extended the read-only Facility snapshot to door model object 155 and added a
  separate `--facility-door-chain-probe`. A broad model-ID snapshot initially
  produced a false positive by observing the wrong model-155 door. The final
  snapshot is exact: model 159 at pads 67/68 and model 155 at pad 75.
- The upstream left continuation also reached the wrong same-model door under
  mobile timing. The final fixed mobile input uses backward movement after the
  first door, then a right-stick/B sweep while inside pad 75's interaction range.
  No player, door, objective or stage state is forced.
- Strict iPhone-then-iPad runs opened both exact targets fully and reached 817
  and 827 world units respectively. Each installed app, private temporary ROM
  and container was removed before simulator shutdown.
- This proves deeper chained world interaction only. Facility objectives and
  organic mission completion remain open.

## 2026-08-03 — open a stock Facility door through normal input

- Independently reran MGB64's pinned
  `facility_spawn_obj159_door_traversal_contract` on the desktop oracle. It
  passed with 762 records, a 1291.83-unit horizontal delta, real object-159
  allow/open/displace/finish events and no direct state automation.
- Added a read-only game-thread snapshot for Facility camera mode and door model
  object 159. The mobile route waits for the real first-person camera transition
  and sends only normalized movement, look and B frames through the existing
  controller boundary; it never forces player or door state.
- The authentic front end reached Dam. One explicitly labelled scripted success
  supplied only the already-proven prerequisite to advance through real reports
  and the Facility briefing; the debug objective flag was restored before
  Facility began.
- Strict iPhone-then-iPad runs each opened the stock door fully
  (`open=90000`, `max=90000`, opening and finished-open observed) and moved Bond
  702 world units. Each installed app, private temporary ROM and container was
  removed before simulator shutdown.
- This completes the simulator context-sensitive interaction subgate only. The
  mobile proof intentionally accepts MGB64's 680-unit post-door milestone rather
  than claiming its later 1200-unit reach. Facility objectives and organic
  mission completion remain open.

## 2026-08-03 — prove the real mission-report and progression seam

- Added an explicitly diagnostics-only atomic request that mirrors MGB64's
  existing scripted mission-success contract. After live Dam gameplay starts,
  it temporarily marks objectives complete and enters `bossReturnTitleStage()`;
  the engine still owns `end_of_mission_briefing()`, the EEPROM write, stage
  transition and both report screens. This is not organic objective completion.
- Added a read-only game-thread snapshot of folder-one Dam/Agent completion and
  best time. The relaunch probe waits until GoldenEye's legal-screen initializer
  has validated EEPROM before declaring a result.
- Strict iPhone-then-iPad runs traversed the authentic front end to Dam, reached
  menu 12 with a game-written completion time of `1023`, pressed A through the
  normal controller bridge to menu 13, then pressed B back to mission select.
- On each device class, launching Settings backgrounded GoldenPad and triggered
  the existing atomic EEPROM flush. The same installed app then restored the
  image and reported `Dam/Agent completed=1 time=1023` after relaunch. Each app,
  private temporary ROM copy and container was removed before simulator
  shutdown. Organic objectives, world interaction and Dam completion remain
  open and G4 is not complete.

## 2026-08-03 — prove real Dam gameplay input semantics

- Added a diagnostics-only atomic snapshot of game-owned player position, view
  angles, aim mode, equipped weapon, magazine, trigger and watch/pause state.
  It is sampled on the game thread beside the real controller read.
- Added `--gameplay-probe`, which reaches Dam through authentic menus, waits for
  the frozen intro camera to release, and drives normalized touch/N64 input only.
- Strict iPhone-then-iPad runs proved movement, modern aim/look, PP7 fire
  (`7->6`), B reload/action (`6->7`), A weapon cycle (`5->1`) and Start
  pause/watch entry. Private screenshots confirmed the moved Dam view and watch.
- Both installed apps and temporary ROM copies were removed before sequential
  simulator shutdown. Context interaction, crouch/objectives and Dam completion
  remain the next input/gameplay gates.

## 2026-08-03 — traverse the authentic front end and load Dam

- Added a diagnostics-only atomic snapshot of menu, stage, selection, file-slot
  hover and cursor state, published from the game thread's real controller-read
  boundary.
- Added `--menu-probe`, which sends one-frame Start presses through the normal
  Swift snapshot and libultra-compatible N64 mapping. It does not call menu or
  stage functions.
- Strict sequential runs traversed menus 0/1/2/3/4/5/6/7/8/10, selected
  Agent/Dam, reached run-stage menu 11 and reported active Dam stage 33 on
  iPhone 16 Pro, then iPad Pro 11-inch (M4).
- Private visual inspection confirmed live Dam gameplay with the native touch
  overlay at 2622x1206 and 2420x1668. Each installed app and temporary ROM copy
  was removed and each simulator was shut down before proceeding. G3 is now
  complete; mission completion is the next production gate.

## 2026-08-03 — persist the real game EEPROM

- Added a mutex-protected import/snapshot boundary around the exact 2 KiB MGB64
  EEPROM surface while preserving the game-facing `osEeprom*` API.
- Swift restores `goldeneye-us.eep` from Application Support before gameplay and
  atomically flushes changed generations with file protection whenever the scene
  becomes inactive or enters the background.
- Both SDK core gates pass and final binaries retain the persistence boundary.
- A no-ROM deterministic image survived terminate/relaunch on iPhone 16 Pro with
  SHA-256 `2048cf697fb66b6c25186c3fdb1ad524cbbdc506a4904ac9c95598f2630f4c4c`.
  After uninstall/shutdown, iPad Pro 11-inch (M4) reproduced the same exact
  2,048-byte hash and received identical cleanup.

## 2026-08-03 — start the real game with native input, Metal and PCM

- Closed the portable `bossEntry` link boundary from 70 unresolved names to
  zero using explicit native service modules and project-owned mobile adapters;
  SDL and matching-target SDK implementations remain excluded.
- Added a one-shot readiness-gated game thread. After exact ROM validation,
  file-table patching, scheduler setup and renderer attachment, it enters the
  real non-returning game main loop and lets `gfx_run_dl` own Metal frames.
- Connected four Swift-fed controller states to MGB64's real `osCont*` surface.
  The deterministic core input probe passed on iPhone and iPad.
- Connected MGB64's 22.05 kHz stereo synth to a bounded PCM ring and
  `AVAudioSourceNode`; 261/261 SFX and 75 instruments/138 sounds decoded, and the
  native nonzero-output probe passed on both simulator classes.
- Strict sequential private-ROM proof rendered the real title/Bond animation and
  demo-stage setup at 2622x1206 on iPhone 16 Pro, then 2420x1668 on iPad Pro
  11-inch (M4). Each app was uninstalled and each simulator shut down before the
  next run. Screenshots and retail data remained ignored local evidence only.
- Both SDK archives now contain 210 core objects and five Fast3D objects. The
  next production slice is persistent EEPROM, followed by interactive menu and
  controlled mission-load acceptance.

## 2026-08-03 — make the mobile host safe for the game thread

- Replaced the non-graphics immediate-return behavior with thread-safe message
  queues and cooperative blocking receives. Added real one-shot/repeating timer
  delivery and `osClockRate`, including the 100 ms contract used by boss init.
- Added the 16 Kbit EEPROM API with exact 8-byte addressing/bounds behavior. Its
  storage is deliberately volatile until the atomic Application Support bridge
  lands; the probe preserves the block it uses.
- Added neutral SDL-free UIKit host ownership for input, frame stats,
  deterministic flags, renderer recovery and lifecycle watchdog state, plus
  MGB64's real portable overlay hook dispatcher. MTKView retrace now distinguishes
  pre-attach fallback from active/inactive UIKit ownership.
- Both SDK gates pass with 202-object ARM64 core archives. The expanded probe
  blocks on a delayed timer, round-trips EEPROM and remains `0x80c24316` on
  iPhone then iPad while real Metal first frames encode at 1206x2622 and
  1668x2420. Each app was uninstalled and each simulator shut down in sequence.
- A temporary `bossEntry` map fell from 97 to 70: 27 closed, zero introduced.
  The probe was removed before the clean combined-renderer pass.

## 2026-08-03 — link real portable services and legacy data

- Added MGB64's real model conversion, CLI stage lookup, radial deadzone,
  setup-name resolution and weapon-cue modules to the audited mobile core.
- Added one project-owned data unit for ten native gameplay constants and one
  ROM offset otherwise defined only in the monolithic desktop compatibility
  file. It contains no media or matching-target implementation code.
- The audited core is now 200 ARM64 objects. Both SDK core and combined
  Fast3D/Metal gates pass, with complete model/setup symbols retained.
- Representative service/data paths execute inside the deterministic probe,
  which visibly remained `0x80c24316` sequentially on iPhone then iPad with
  complete app removal and shutdown between them.
- A temporary `bossEntry` map fell from 117 to 97: 20 closed, zero introduced.
  The probe was removed before the clean combined-renderer pass.

## 2026-08-03 — move game configuration ownership off SDL

- Added one project-owned mobile configuration unit for the 68 game-side
  settings and startup globals previously defined only inside `platform_sdl.c`.
  It keeps conservative upstream-compatible defaults without importing SDL
  event, controller or window ownership.
- The audited core is now 194 ARM64 objects. Both SDK core and combined
  Fast3D/Metal gates pass, and final apps retain the mobile config probe.
- Representative defaults execute inside the deterministic probe, which visibly
  remained `0x80c24316` on iPhone then iPad. Each app/container was removed and
  each simulator shut down in strict sequence.
- A temporary `bossEntry` map fell from 185 to 117: all 68 `g_pc*` names closed,
  zero new unresolved symbols. The probe was removed before clean verification.

## 2026-08-03 — add the SDL-free portable leaf closure

- Explicitly added 28 small upstream leaf units for native segment constants,
  trig/stdio compatibility and isolated gameplay fidelity helpers. Together
  they are under 1,000 source lines and import no SDL, audio or window owner.
- The audited core is now 193 ARM64 objects. Core and combined Fast3D/Metal
  verifiers pass for Simulator and device SDKs, required representative symbols
  are retained, and the exact ignored MGB64 checkout returns clean.
- Extended the runtime probe through native trig, aim-bone fidelity,
  watch-aspect and Rareware-logo segment constants. It visibly remained
  `0x80c24316` on iPhone and then iPad; both app containers were removed and both
  simulators shut down in strict sequence.
- A temporary non-executing `bossEntry` map fell from 246 to 185 unique
  unresolved symbols: 61 closed and zero introduced. The probe was removed
  before the clean combined-renderer pass.

## 2026-08-03 — isolate portable GU math from the desktop platform unit

- Added one project-owned mobile GU source containing MGB64's real host-side
  matrix, projection, look-at, rotation, scale, translation and normalization
  implementations without importing its monolithic SDL compatibility unit.
- The audited core is now 165 ARM64 objects. Simulator/device core and combined
  Fast3D/Metal verifiers pass, final binaries retain `guNormalize`, and the
  exact ignored upstream checkout returns clean.
- Extended the deterministic core probe to normalize 3/4/0 before running the
  upstream random check. Sequential no-ROM launches visibly reported the
  unchanged `0x80c24316` result on iPhone and iPad; each app was removed and
  each simulator shut down before the next device or handoff.
- A temporary non-executing `bossEntry` force-link probe reduced the startup
  map from 261 to 246 unique unresolved symbols—exactly the 15 GU helpers—and
  left no GU name unresolved. The probe was removed after recording the map.

## 2026-08-03 — deliver the first UIKit-owned scheduler retrace

- Connected the existing MTKView draw callback to the cooperative scheduler
  after each real MGB64 Metal frame. Delivery is gated on scheduler readiness
  and an empty graphics queue, so no-consumer bring-up holds one pending message
  instead of filling all 32 slots.
- Both final SDK apps retain the retrace bridge and remain free of SDL, AppKit
  and desktop OpenGL dependencies. Core and combined renderer verifiers pass and
  the ignored upstream checkout returns clean.
- iPhone attached-console runtime reported `MGB64 cooperative retrace delivered`
  after scheduler readiness and its 1206x2622 first Metal frame. The entire app
  container was removed and the phone shut down before iPad repeated after its
  1668x2420 frame and received the same cleanup.
- A non-executing `bossEntry` force-link probe then exposed 261 remaining title
  startup symbols. Most map to public portable MGB64 platform modules; the
  desktop SDL/audio/window owners remain intentionally excluded. The probe was
  removed after recording the next closure boundary.

## 2026-08-03 — initialize the native scheduler without SDL

- Rejected upstream `platform/stubs.c` as an iOS build unit because it combines
  required libultra host calls with desktop SDL input and audio. Added one
  project-owned mobile OS adapter around the exact cooperative scheduler seam.
- The adapter initializes upstream `os_scheduler`, interrupt/command queues and
  the graphics client after the validated ROM and file table are ready. It
  exposes a timed retrace fallback; MTKView signaling, Fast3D task dispatch,
  normalized game input, rumble and AVAudio remain explicit next gates.
- The complete audited core was 164 ARM64 objects at this checkpoint. Core and combined
  Fast3D/Metal verifiers passed for both Simulator and device SDKs; the exact
  ignored MGB64 checkout remained clean.
- Attached-console runtime reported `MGB64 scheduler ready` and a real Metal
  first frame at 1206x2622 on iPhone. Its app/container was removed and the
  simulator shut down before iPad repeated at 1668x2420 and received the same
  cleanup. Neither Simulator retains the temporary retail-data copy.

## 2026-08-03 — patch the native file table from validated ROM memory

- Added upstream `rom_offsets.c` and `asset_stubs.c` to the audited native core.
  The latter contains only one-byte zero placeholders for legacy link symbols;
  it carries no ROM-derived media. Activating the table increased the complete
  core archive from 161 to 163 objects for both Apple mobile SDKs.
- After exact validation and volatile ownership, the bridge now patches the
  complete resource table and verifies the first background plus Dam entries
  against their exact offsets inside the owned buffer. Clearing a ROM nulls
  every table address before zeroing/freeing the allocation.
- Core and linked-renderer verifiers passed for both SDKs. Final binaries retain
  `platformPatchFileTable` and the readiness probe; the ignored MGB64 checkout
  remained clean.
- Sequential runtime logged `MGB64 file table ready` on iPhone at 1206x2622.
  Its app/container was removed and simulator shut down before iPad repeated at
  1668x2420 and was likewise removed/shut down.
- The next gate is the smallest scheduler/platform closure around `bossEntry`,
  not more ROM handling.
- Rebuilt ordinary core-free Simulator/device apps. The foundation IPA
  reproduced twice at SHA-256
  `fb866882eca3ae019b145eed9dd0ab8efd3b0ddb20594433eb45fa40ad608dae`;
  its eight-member audit passed and sorted app content matched
  `102337b9cb2a07b4471f7e015c7c06459643de98f6d68c62bdae630308e827cd`.

## 2026-08-03 — hand validated retail bytes to volatile core memory

- Split ROM ownership from the renderer bridge. Core builds now accept bytes
  only after the existing size/header/byte-order/SHA-1 validator succeeds; the
  C boundary independently rechecks 12 MiB size, big-endian header and internal
  `GOLDENEYE` title before making its own heap copy.
- Replacement zeroes the prior allocation before freeing it. Core-free builds
  retain validation-only behavior, and no path writes normalized retail bytes
  into the app bundle, repository or persistent cache.
- Used the ignored supported V64 through a temporary Simulator app-container
  copy. iPhone logged the volatile MGB64 install while its real renderer kept
  presenting at 1206x2622; the app/container was removed and phone shut down
  before iPad repeated at 1668x2420 and was likewise removed/shut down.
- The next gate is MGB64 file-table/resource patching followed by the smallest
  title/menu main-loop adapter.
- Rebuilt both ordinary core-free SDK targets and reran the enhanced 161-object
  core verifier. The foundation IPA reproduced twice at SHA-256
  `7ee9af41309b6b9b52836c4b6974c01087eac9b164984c1f9d949e2aabc49e36`;
  its eight-member audit passed and sorted app content matched
  `23da2017f0fa283924c78cb3bc2e1ded0c3c631fd28c5e0f8758a3a3f5c0baf9`.

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
