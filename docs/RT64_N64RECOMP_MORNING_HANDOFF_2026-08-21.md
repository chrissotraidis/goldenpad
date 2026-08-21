# GoldenPad recomp morning handoff — 2026-08-21

## Accepted baseline

The installed `GoldenPadRecompPrototype` build is the accepted mainline
baseline. The 2026-08-21 physical-iPad test successfully selected and launched
multiple missions, including Bunker, and sustained normal gameplay. The Xbox/
MFi controller mapping felt responsive for movement, looking, aiming and
firing. The severe Bunker blue-void rendering failure was not visible in the
final run; the two-pixel right-edge seam was later reproduced and is addressed
below. High-resolution RT64 output
looked substantially better than the earlier MGB64 baseline.

The accepted installed/local app executable SHA-256 is
`addd13724a405237585aa3835000a220283996bc83c980b6263ea5c3735a4826`.

This acceptance is intentionally scoped. A few intermittent map glitches were
still observed, multiplayer was not exercised, and the lifecycle failure below
ended the run. Keep the former MGB64 app as a deprecated fallback while this
recomp build becomes GoldenPad's main development baseline.

## Morning worklist

1. **Screenshot/background return can freeze gameplay.** During a mission, the
   tester took an iPad screenshot, returned to GoldenPad, and found gameplay
   completely frozen. The app process remained alive. Persistent diagnostics
   recorded `host became inactive`, `host became active`, a stale-audio discard,
   and then a watchdog with RT64 counters fixed at `dl=11144`, `vi=11143`, and
   `presented=11051`. There was no new GoldenPad `.ips` crash report at 1:00 AM.
   Treat this as a lifecycle hang, not a confirmed process crash. Reproduce and
   diagnose it tomorrow; do not fold a speculative fix into tonight's baseline.
2. **The optional center reticle is misplaced.** Enabling it placed the reticle
   at the extreme top-right beside the three-dot button rather than at the
   center of the rendered game viewport. The 1:00 AM screenshot records the
   bad placement.
3. **Add `Return to Main Menu` to the three-dot menu.** Start opens GoldenEye's
   watch, but the tester could not find a reliable route from an active mission
   back to mission select/title. This should be an explicit host-menu action,
   with a confirmation if it discards mission progress.
4. **Make graphics-setting application clear.** Toggling N64 three-point
   filtering, 2x MSAA, and Native N64 versus Automatic high resolution produced
   no obvious immediate visual change. Establish whether each setting is live
   or restart-only, then communicate that in the UI. If a restart is required,
   provide an explicit restart/apply flow instead of leaving the result
   ambiguous.
5. **Exercise multiplayer with multiple physical controllers.** Do not assume
   multiplayer becomes available merely because another controller connects.
   Verify controller enumeration, player-port assignment, touch-overlay
   behavior and an actual multiplayer match with at least two controllers.
6. **Record intermittent map glitches by stage and location.** The final missions
   were overwhelmingly stable, but the tester still saw occasional geometry or
   map glitches. Capture stage, room, camera angle and diagnostics when one is
   reproduced. Do not reopen the rejected camera-basis experiment, which made
   gameplay unplayably slow.
7. **Retest physical-speaker audio.** Runtime counters showed no drops or
   underruns in the accepted run, but occasional static was reported in earlier
   physical listening. Keep this as a listening gate rather than treating queue
   health alone as final audio acceptance.

## Morning implementation status

- GoldenPad now keeps RT64 active during transient `.inactive` states caused by
  screenshots and system overlays; only a real `.background` phase suspends the
  renderer and audio. Persistent diagnostics identify ignored transient
  inactive transitions separately from actual background suspension.
- The optional reticle is explicitly centered in the full game surface instead
  of inheriting the utility menu's top-right alignment.
- The three-dot menu includes a confirmed `Return to Main Menu` action. The host
  queues the request atomically and GoldenEye consumes it on its game thread via
  the native title-stage transition.
- Resolution, 2× MSAA and three-point filtering are saved immediately but apply
  on the next GoldenPad launch. Rebuilding the active RT64 session was removed
  after it correlated with the 9:25 slowdown.
- The recomp/RT64 app is user-facing `GoldenPad`; the MGB64 fallback is
  user-facing `GoldenPad Legacy`. Internal target and bundle identifiers remain
  unchanged to preserve build stability and both app containers.

## Morning physical pass

- A clean signed device build was installed in place as
  `com.chrissotraidis.goldenpad.recomp-prototype`. The installation database
  UUID remained `D2F4E1F3-F310-4A01-8ED7-65B907FAA17B`, and the app now appears
  on the iPad as `GoldenPad`.
- Before/after readback hashes matched for both private ROM copies and the
  active and backup save files. No ROM or save was embedded in the app bundle.
- The currently installed 10:34 candidate executable SHA-256 is
  `5f022f5c711df08b07a11890a102359e9b06b8c0f27ac7eca428e7c39dc0effe`.
  It was installed in place with database UUID
  `D2F4E1F3-F310-4A01-8ED7-65B907FAA17B` preserved. The earlier
  hands-on-accepted hash above remains the fallback reference until the new
  multiplayer and right-edge fixes receive physical acceptance.
- The preserved save reached GoldenEye's file-select screen. With an external
  controller connected, the touch controls were hidden and only the three-dot
  utility menu remained. The optional reticle was visually centered in the
  full game surface.
- A simultaneous QuickTime device mirror and unbounded `devicectl --console`
  stream made gameplay severely jittery and input feel unresponsive. Closing
  both and launching normally restored the accepted speed immediately. Treat
  that as diagnostic-harness overhead, not a game regression. Future physical
  passes must use bounded persistent-log readbacks while gameplay is active;
  attach QuickTime or a live console only for a short, isolated capture.
- The first normal-launch readback reached `dl=2340`, `vi=2340`, and
  `presented=2340` with zero audio drops or underrun callbacks. It also recorded
  full-range right-stick samples and controller button transitions.
- The 9:25 screenshot did not reproduce the former lifecycle freeze. The log
  recorded `transient inactive state observed`, then presentation advanced from
  `presented=31108` through `32625` with no watchdog or audio underrun.
- Immediately before the reported 9:25 slowdown, Settings requested six live
  MSAA rebuilds and two filtering updates. Live RT64 quality reconfiguration was
  removed: resolution, MSAA, and filtering are now saved for the next app
  launch, and the UI states that explicitly. Controller/rumble event logging is
  sampled so rapid gameplay input cannot become a file/console workload.
- Controls now distinguish touch-only, controller-only, and shared options.
  Controller button assignments have their own submenu with consistent labels,
  eight remappable face/shoulder/trigger inputs, and Restore Default Mapping.
  Sticks, d-pad, and Menu/Start remain fixed.
  An opt-in two-player test keeps the connected controller on port 1 and
  advertises touch as port 2, with independent movement, buttons, modern look,
  and crouch-toggle state. Turning it off keeps the physical controller on port
  1 and hides touch controls.
- The post-fix normal launch reached `dl=2455`, `vi=2454`, and
  `presented=2454` with zero audio drops or underrun callbacks. No continuous
  console or QuickTime mirror was attached.
- At 9:42, QuickTime remained open with an inactive file panel from the prior
  device-watch session. It was fully quit before rebuilding. No live console,
  profiler, or active recording was present. Right-stick samples were reduced
  from twice per second during sustained movement to once every ten seconds.

Hands-on screenshot/resume, return-to-menu, graphics-toggle and multiplayer
acceptance remain open. Physical audio quality remains a listening gate even
when queue-health counters are clean.

## 10:04 multiplayer crash follow-up

- The multiplayer start failure was confirmed as a process crash, not a UI
  freeze. iPadOS incident `E40A1ADE-AD85-45A8-ACE3-814507E93D03` reports
  `EXC_BAD_ACCESS` / `SIGBUS`, `KERN_PROTECTION_FAILURE` at
  `0x0000000320000000`, on faulting thread 14.
- The faulting stack is RT64 display-list processing:
  `RT64::Interpreter::processDisplayLists` →
  `RT64::Application::processDisplayLists` →
  `zelda64::renderer::RT64Context::send_dl`.
- The register/fault relationship identifies an RDRAM base plus invalid
  `0x20000000`. The current standalone RT64 treated GoldenEye KSEG1 `0xA...`
  addresses as extended RDRAM because it tested only bit 31. GoldenEye's pinned
  RT64 accepts only the `0x8...` extended region. The embedded RT64 patch now
  restores that high-nibble test in RSP physical/segmented and RDP address
  normalization.
- The experimental routing is corrected to physical controller Player 1 and
  touch Player 2, including independent movement, buttons, modern look, and
  crouch toggles. Normal controller-only and touch-only Player 1 paths remain
  unchanged.
- Shared Diagnostics now reports when the prior foreground session ended
  unexpectedly and includes the bounded previous-session log. This uses a tiny
  lifecycle marker rather than an attached console or recording session.
- Pixel inspection of the 10:07 screenshot found the far-right blue seam in
  exactly two physical columns. A one-point opaque black host mask covers that
  seam without resizing or rebuilding the RT64 viewport.
- Graphics copy now says that resolution, 2× anti-aliasing, and three-point
  filtering require fully quitting and reopening GoldenPad. It also documents
  the original-look combination: Native N64 with both enhancements disabled.
- A bounded readback after the final in-place launch found PID `5674` alive.
  Presentation advanced to `dl=6229`, `vi=6228`, and `presented=6228`; audio
  reached 3,077,357 rendered frames with zero dropped frames, underrun frames,
  or underrun callbacks. No live console, QuickTime mirror, or profiler was
  attached. The log SHA-256 is
  `cd418c730d51828f8057e86af0f90bb70777b4ccebb61a0648fd8b8c6abb2e1f`.

The crash report SHA-256 is
`f85b7eeb0f455ca012aeb733152b1c8d91a11c1dee5e2e1d216aefd294f7d9b6`.
The captured current/previous app-log SHA-256 values are
`116aec20404aeaa5b63bdc6c41bb4009ce34d14558252808b4d0126f91b0671e`
and `f41072a93ef4b78c8de7e54aeab26bdf801c2c168cc48e7271456f9e4b550d74`.

## 11:10 Simulator multiplayer validation

- A dedicated iPad Pro Simulator (`55A93862-CC29-48E8-8AA5-043258D6B8BE`)
  ran the full ARM64 AOT + RT64 build with the private ROM staged only in its
  app container. The staged-ROM readback SHA-256 remained
  `7ec491ee3164851d0995e3e8ad19999df5e3028be6ba3729c4ac16c31a9c0959`.
- With the opt-in two-player test enabled, GoldenEye exposed its authentic
  `MULTIPLAYER` entry, accepted the default two-player setup, and entered a
  live horizontal split-screen Temple match. The former
  `0x0000000320000000` display-list crash did not recur.
- The bounded native log advertised normal controllers on ports 1 and 2,
  retained `external-p1+touch-p2`, recorded independent Player 1 and Player 2
  button transitions, and advanced to `dl=31909`, `vi=31909`, and
  `presented=31909`. Launch service still reported PID `36887` alive.
- The final Simulator executable SHA-256 is
  `fcb2f6e822a9d14b141baaa3b70b1dba05ff9c2980f4b098ebc9d2f58eda4d92`.
  The private split-screen evidence image SHA-256 is
  `6790c9122fb40af82b51332e638840d6bc6ff9bfe663c3fa445a0814b9417aff`.
- Simulator UI automation produced 1,497 startup/interaction underrun frames
  before the match and the count then remained fixed. This is not physical
  audio evidence; the clean bounded iPad audio run above remains the relevant
  device result.
- The ROM-free host verifier, all six RT64/Plume/GoldenEye patch dry-runs, and
  an unsigned ARM64 iPhoneOS build passed after this test. The keyboard helper
  used to navigate GoldenEye is compiled only for Simulator. Physical
  controller-plus-touch multiplayer and visual right-edge acceptance remain
  open and require a normal unrecorded iPad run.
- The user observed the two Simulator multiplayer viewports flashing back and
  forth. Multiplayer therefore remains explicitly work in progress for the
  first public candidate even though the former process crash is fixed. Do not
  describe the Simulator split-screen presentation as visually accepted.

## 11:31 physical release-candidate deployment

- A fresh signed ARM64 build was installed in place on Chris' iPad Pro as
  `GoldenPad`; no uninstall or remove-existing-content operation was used. The
  installation database UUID remained
  `D2F4E1F3-F310-4A01-8ED7-65B907FAA17B`.
- The installed candidate was built from executable SHA-256
  `87a8e193b290f587d33b170241b86146a6da36032e7f1a5e6af47e356a5a7896`,
  bundle ID `com.chrissotraidis.goldenpad.recomp-prototype`, and signing team
  `VKDH2T9UTF`.
- Before and after installation, both private ROM readbacks matched
  `7ec491ee3164851d0995e3e8ad19999df5e3028be6ba3729c4ac16c31a9c0959`.
  The active and backup save readbacks also remained byte-identical at
  `f4ff93fe66c1ca8b36ad2a8f4897e4387c69f1abfc0b58470a415ce3cd961cc6`
  and `e4476b2d18d2a0e9d9c484d8ab9c0cb5fb9bcf8bec6694188acdff900b79b13b`.
- GoldenPad launched without a live console, Simulator control, QuickTime, or
  recorder. PID `6122` remained alive; the bounded app log reached `dl=3494`,
  `vi=3494`, and `presented=3494`, with 1,531,622 audio frames rendered and
  zero dropped or underrun frames/callbacks. The log SHA-256 is
  `605ccc5d56f16d7cf2254467b8fde1b186d2d0101cbe1a18608da0f92c55d6c4`.
- The build is now ready for normal hands-on single-player/controller/audio,
  screenshot-resume, utility-menu and right-edge visual acceptance. Multiplayer
  may be tested, but flashing or other split-screen defects do not block this
  candidate from being evaluated as a single-player-first public preview.

## Release-candidate requirement audit

| Requirement | Current evidence | Status |
|---|---|---|
| Primary static-recomp + RT64/Metal runtime | Full private ARM64 Simulator/device builds, real GoldenEye display-list/VI/presentation progress, user-facing `GoldenPad` metadata | Proven for the current build |
| User-supplied data boundary | Tracked contamination gate passes; no ROM/save/signing files or known retail bytes are tracked; both ROM and save readbacks survived the in-place update byte-for-byte | Proven for repository and installed container |
| Older implementation preserved | `GoldenPad Legacy` remains a separate bundle/target and its complete Simulator/device MGB64 renderer verifier passes | Proven |
| Stable single-player presentation/audio | Current iPad launch reached 3,494 matched display-list/VI/presented updates and 1.53 million rendered audio frames with no drops/underruns | Bounded runtime proven; newest hands-on mission/audio listening pending |
| Touch and controller input | Tuned touch path, remappable Xbox/MFi map, right-stick normalization, automatic overlay hiding and P1/P2 routing are linked; earlier physical controller/touch sessions were accepted | Integrated; newest candidate hands-on pending |
| Clear settings and utility menu | Restart-only graphics copy, touch/controller/shared sections, button mapping, reticle and confirmed Return to Main Menu are present and Simulator-inspected | Integrated; newest physical interaction pending |
| Bounded diagnostics/lifecycle | Current/previous bounded logs, sampled high-frequency input, clean/background marker, transient-inactive handling and share sheet are linked and emitting | Proven at runtime; screenshot/resume hands-on pending |
| Multiplayer crash repair | RT64 KSEG1 mask fix is in the reversible patch; Simulator entered and sustained a two-player match beyond 31,000 presentations without the former fault | Crash reproduction fixed in Simulator; flashing presentation and physical match pending |
| Signed physical deployment | Team-signed ARM64 app installed in place, database UUID preserved, PID alive, private payloads preserved | Proven |
| Evidence-backed documentation | README, status, testing, release checklist, prototype record and this handoff distinguish primary/legacy, automated/physical, and accepted/open gates | Proven |

The strengthened ROM-free host verifier now requires all graphics, input,
two-player, lifecycle, diagnostics and return-to-menu bridge symbols; correct
primary bundle metadata; third-party notices; no MGB64 symbols; no ROM/save
payloads; and no private home or temporary paths in the executable. It passed
after these checks were added. Repository contamination, source-license and
diff-whitespace gates also pass.

## 11:37 hands-on iPad follow-up

- The Xbox controller did not automatically reconnect at first. The tester
  manually connected it through iPadOS Bluetooth, after which GoldenPad detected
  it, hid the normal touch overlay, and controller-driven single-player gameplay
  worked. This is a pairing/reconnection observation, not evidence of a broken
  GoldenPad button map; no speculative controller-lifecycle change is included
  in this release-polish pass.
- Enabling the experimental Player 1 controller + Player 2 touch mode exposed
  GoldenEye's two-player menu and started a Normal match, but the substantial
  presentation defect remained. The 11:37 screenshot shows most of the display
  black with only a partial player viewport/geometry visible. Its SHA-256 is
  `20bfdb7c269e9d3c3aeab8522b7774d9f4b13cccd7070d44ebab41a4a693e32b`.
  Per the tester's release decision, multiplayer is documented but deliberately
  not repaired in this candidate.
- After disabling the experimental mode, normal single-player Surface and
  Bunker sessions rendered and controlled correctly. Four user-approved
  physical-iPad captures were downsampled to 1600 pixels wide and added to the
  README; the raw diagnostic multiplayer/settings screenshots remain outside
  the repository.
- The signed follow-up candidate removes the redundant `Restart required / Quit
  and reopen app` row while retaining the explanatory graphics paragraph, and
  moves the three-dot menu six points left. No other Settings layout or gameplay
  path is changed.
- That candidate's executable SHA-256 is
  `2f34e1ff9ee18ac2837cac09b3f0e5f0e62907c6caab275ffa9a97695ffdcdb1`.
  It was installed in place on the physical iPad; the installation database UUID
  remained `D2F4E1F3-F310-4A01-8ED7-65B907FAA17B`. Both ROM readbacks remained
  `7ec491ee3164851d0995e3e8ad19999df5e3028be6ba3729c4ac16c31a9c0959`,
  and the active and backup save hashes remained
  `f4ff93fe66c1ca8b36ad2a8f4897e4387c69f1abfc0b58470a415ce3cd961cc6`
  and `e4476b2d18d2a0e9d9c484d8ab9c0cb5fb9bcf8bec6694188acdff900b79b13b`.
- GoldenPad launched normally as PID `6356` without a live console or recorder.
  One bounded persistent-log readback reached `dl=1854`, `vi=1854`, and
  `presented=1854`, with 868,829 audio frames rendered and zero dropped or
  underrun frames/callbacks. It also detected the already connected external
  controller and hid the touch overlay. The log SHA-256 is
  `fff407945c40d6ffc678bbc6d135e0b355d63e1b9436c83c1b99f2d0d82c373a`.
- iPhone installation and layout acceptance are intentionally deferred until
  the tester approves this next iPad build.

## 12:13 accepted-build iPhone transfer

- After the iPad candidate received hands-on single-player acceptance, the exact
  same signed ARM64 app (executable SHA-256
  `2f34e1ff9ee18ac2837cac09b3f0e5f0e62907c6caab275ffa9a97695ffdcdb1`)
  was installed on Chris' connected iPhone 14. GoldenPad was not previously
  installed there, so no existing iPhone app container or save was replaced.
  The new installation database UUID is
  `3ACA6644-5550-4EEA-BDCA-D6F9D3827161`.
- The accepted iPad Documents ROM, runtime ROM, active save, backup save and
  preferences were copied into the new iPhone container. Independent iPhone
  readbacks matched the iPad files byte-for-byte: both ROM hashes are
  `7ec491ee3164851d0995e3e8ad19999df5e3028be6ba3729c4ac16c31a9c0959`,
  save hashes are
  `f4ff93fe66c1ca8b36ad2a8f4897e4387c69f1abfc0b58470a415ce3cd961cc6`
  and `e4476b2d18d2a0e9d9c484d8ab9c0cb5fb9bcf8bec6694188acdff900b79b13b`,
  and the preferences hash is
  `c76b41b43b9c4d633486a8f0396d803a94c4c59166d8872acd40ef6a7878e166`.
- The transferred preferences retain automatic high resolution, 2x MSAA,
  three-point filtering, inverted aiming, unlocked missions, centered reticle
  off and experimental two-player mode off.
- GoldenPad launched normally on the iPhone without a live console or recorder
  and remained alive as PID `4433`. One bounded log readback reached `dl=1146`,
  `vi=1146`, and `presented=1146`, with 427,476 audio frames rendered and zero
  dropped or underrun frames/callbacks. The log SHA-256 is
  `135bcb488d447c6e219c43e3b2fdf2076c4d6f6f954a06f4ff1d057496b2fe03`.
- Physical iPhone touch-layout, controller, audio-listening and mission gameplay
  remain hands-on acceptance items; this transfer proves package, data,
  preference, launch and bounded runtime health only.

## 12:15 iPhone touch-layout follow-up

- Physical iPhone gameplay and performance were accepted, but the fixed iPad
  overlay did not fit the 2532×1170 landscape phone capture. MOVE extended past
  the left/bottom edges, LOOK occupied most of the right half, and the complete
  action cluster overlapped. The private diagnostic screenshot SHA-256 is
  `3c2f08a2b31f179836fa5c58aaccfbb4fa43ac60150d326e1f29af50d3544966`.
- The initial focused follow-up exposed a scaled preview editor. Physical use
  showed that the preview hid the real three-dot placement reference, shrank the
  gameplay canvas, pushed the size slider below the visible phone viewport, and
  allowed `WEAPON` to wrap at small sizes. The 12:45 editor and 12:46 live-layout
  screenshot hashes are
  `f4b1053c6cb21298b91dfa0d8f07aad77a48d342069fbbe4af2451975ea33f99`
  and `67f7061422c9574de3d2efe5aa6faabe75fbc85b2da090ff2bf0ba488a98bd9a`.
- The revised editor operates directly over the full-size running game. The real
  three-dot menu remains visible, all eight controls drag at their actual live
  size and position, the selected control is outlined, and an always-visible
  floating slider resizes it from 55–160%. Cancel discards the draft, Reset
  restores the current device defaults, and Done persists it. Touch button text
  is single-line with automatic downscaling to prevent label overflow.
- iPhone and iPad layouts use separate UserDefaults keys. The new phone defaults
  use an 844×390 reference canvas and height-aware scaling; the tablet defaults
  retain the accepted 1366×1024 positions and scale. No input mapping,
  controller, renderer, audio or multiplayer code changes are part of this pass.
- The initial preview-editor executable SHA-256 was
  `adb91d0e391e0e0b1511c8f0170b27eaf687798ddf619454b7e0b36819aba228`;
  it was immediately superseded after hands-on feedback. The corrected live
  editor executable SHA-256 is
  `025818412e672e73baf28a1ebdf42fc7e4c63631a164b53eac6f343e85e78d59`.
  It was installed in place on both devices: the iPhone database UUID remained
  `3ACA6644-5550-4EEA-BDCA-D6F9D3827161` and the iPad UUID remained
  `D2F4E1F3-F310-4A01-8ED7-65B907FAA17B`. On both devices, independent
  before/after readbacks matched byte-for-byte for both ROMs, both saves and the
  existing preferences file.
- Normal unrecorded launches remained healthy. The iPhone process was PID
  `4637` and reached `dl=1517`, `vi=1517`, `presented=1517`, and 648,211 audio
  frames with zero drops/underruns. The iPad process was PID `6568` and reached
  `dl=1518`, `vi=1518`, `presented=1518`, and 647,741 audio frames with zero
  drops/underruns. Their bounded log hashes are
  `82a460c4dfce515baa0f775e6896fde4c8fc5544f4f1fc4b710ed9b55da40996`
  and `73b9e6837b0cb76e532e6f688e5d1a5e7bcb24b6f5eb4b53c9c3f7bd4ed955fd`.
- Host compilation and the strengthened ROM-free verifier pass. Physical
  drag/resize/persistence and final comfort remain hands-on gates even though
  the new editor, separate persistence keys and responsive defaults are linked
  in both installed apps.
- The custom iPhone draft saved with the preview editor was preserved across the
  corrected in-place update. Its preferences readback remained byte-identical at
  SHA-256 `daec411c0c2da2f3959431bb085a25c729fd29d1b49f8a842b5702b624d7cc08`,
  including `recomp.touchLayout.phone.v1`.
- Physical follow-up accepted the corrected full-screen editor and customized
  iPhone layout. The remaining requested polish is intentionally narrow: move
  only the iPhone three-dot menu closer to START, add a 20–100% opacity slider
  for the selected control, and retain the repository default of **Unlock all
  missions** off while preserving existing device preferences. The accepted
  editor and Facility gameplay screenshot SHA-256 values are
  `b26d88e766316f25fa37e90875bd1f468a9fd600b8e0e21cc9a32915465added`
  and `546c945df9643f355b8eec020be6f143eeaa9f5cb332497306c11a4d503cc577`.
- The final polish keeps the accepted live editor and mappings unchanged. It
  moves only the iPhone utility menu approximately 34 points right, adds a
  per-selected-control 20–100% opacity slider, and decodes the existing saved
  layout schema with the established 72% opacity when that new field is absent.
  Clean installs retain the source default `Unlock all missions = false`; the
  in-place update deliberately preserved the tester's existing `true` choice.
- The signed final-polish executable SHA-256 is
  `f0072a6dddd53ab6cc7fb061877aea2aed7717625340c4fd5f355a24077abc32`.
  It was installed in place on the physical iPhone without a live console,
  recorder or profiler. The installation database UUID remained
  `3ACA6644-5550-4EEA-BDCA-D6F9D3827161`, and the normal launch remained alive
  as PID `4732` in the bounded process snapshot.
- Independent pre/post-install readbacks matched byte-for-byte: both ROMs
  `7ec491ee3164851d0995e3e8ad19999df5e3028be6ba3729c4ac16c31a9c0959`,
  active save
  `f4ff93fe66c1ca8b36ad2a8f4897e4387c69f1abfc0b58470a415ce3cd961cc6`,
  backup save
  `e4476b2d18d2a0e9d9c484d8ab9c0cb5fb9bcf8bec6694188acdff900b79b13b`,
  and preferences/custom phone layout
  `12e163bce76605fb852efc0d38a31d38aecbdbd7d6ef5da7d6fffa55d9d73ffd`.
  The strengthened ARM64 Simulator host verifier, contamination gate, source
  license manifest and diff-whitespace gate all pass. The newly aligned menu
  and opacity control still require the tester's final hands-on acceptance.
- The exact same signed executable was then installed in place on the physical
  iPad. Its database UUID remained
  `D2F4E1F3-F310-4A01-8ED7-65B907FAA17B`; both ROMs, active save, backup save and
  preferences matched byte-for-byte before and after. The iPad preferences hash
  is `c76b41b43b9c4d633486a8f0396d803a94c4c59166d8872acd40ef6a7878e166`.
  GoldenPad launched normally without a recorder, console stream or profiler
  and remained alive as PID `6696` in the bounded process snapshot.
- The ROM/save/package-member and legacy-symbol checks pass for the private
  signed app, but the deliberately strict public-path audit found six embedded
  `/private/tmp` compile source strings: private `aspMain.cpp` plus five
  N64ModernRuntime translation units. Stripping the executable does not remove
  them because they are compiled literals, not debug records. This is not an
  installed-app regression, but it is a concrete public-package blocker: rebuild
  the AOT/runtime inputs with deterministic source-prefix mapping and reject all
  `/Users/` or `/private/tmp` strings before distribution.

## Preserved evidence

- User screenshot: `Screenshot 2026-08-21 at 1.00.22 AM.png` (kept outside the
  repository because it is a private gameplay capture).
- Current and previous bounded application logs were copied from
  `Library/Application Support/GoldenPadRecomp/Logs` before relaunching or
  rebuilding.
- The current log SHA-256 is
  `8996f3cc5936f5d12d424b336365f9cdca490810d6a34c6f878924d2b1aecd7a`.
- The previous log SHA-256 is
  `c1a3e2d7d498515a25e062662cde57854292d4cb98116d3f3487136fa6aa6fbf`.
- The most recent pre-existing CPU-resource report was also copied for later
  comparison; its SHA-256 is
  `b5d17d962435f86dd054b7faeac7976842fc2b905dfb7522d866fe29637f0f73`.
- Raw logs, `.ips` files, ROM data, saves and gameplay captures remain private
  local evidence and are not committed.

## Release boundary

The final run is strong physical evidence for a public tech-demo baseline, not
proof that every mission, multiplayer, screenshot/resume path or audio route is
release-complete. Tomorrow's first gate is the screenshot/background-return
freeze; the other work should remain small and independently verifiable.
