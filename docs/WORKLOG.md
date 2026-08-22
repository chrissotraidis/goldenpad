# Worklog

## 2026-08-22 — TD-08 Mac mouse-clamp ownership isolated

- Traced relative mouse input from `NSEvent.deltaX/Y` through the 60 Hz Swift
  publisher, `goldenpad_recomp_queue_touch_look`, the atomic queue, and
  `recomp_get_camera_inputs`. At the default 2.5 sensitivity, Swift reaches its
  `±32767` publication clamp at only about 7.8 host-delta units per publish interval; the
  queue applies the same limit again before the game consumes `[-1, 1]` look.
- Added opt-in `--mouse-clamp-probe`. It observes raw versus published Swift
  deltas, counts saturated axes/lost units, and changes no look value. Its C++
  implementation is a separate Mac-only source file. Normal launches perform a
  one-time disabled reset and no per-sample probe work.
- Rejected an initial shared-runtime instrumentation layout because the rebuilt
  mobile executable changed even though its branches were compiled out. After
  moving the detector out of the shared runtime, the full RT64 Simulator build
  returned exactly to accepted SHA-256
  `5022ffc11d4d127b1714bd9aa728ea2eb5b2ff4736c656ab7cbd0fb5747fface`
  and contains neither Mac probe symbol.
- The native Mac target builds successfully and exports both opt-in hooks; its
  diagnostic executable SHA-256 is
  `1d49e815c42bef08e8df72f5ee980e6acd4da3d00ba52c54e4ab371f1c7d7b18`.
  The detector self-check reports `PASS` with behavior unchanged.
- Live delta sampling is not claimed. The current Mac Alpha reproduced its
  pre-existing runtime/UI stall before mouse input could be exercised: the
  process remained active while RT64 stayed at `dl=0 vi=0 presented=0` and the
  UI became inaccessible. The exact diagnostic process was stopped; the stale
  `active-session.marker` is retained as evidence. ROMs, save, and backup
  remained byte-identical.
- TD-08 is therefore narrowed, not fixed. Do not widen either clamp until a
  healthy unchanged Mac baseline can produce matched raw/published/consumed
  samples and pass the full native input/render/performance gate.

## 2026-08-22 — TD-06 render-order hypothesis rejected and reverted

- Confirmed from the matched GoldenEye source that `shuffle_player_ids()`
  randomizes all four player IDs every simulation tick before `lvlRender`, while
  the game submits each viewport sequentially. The game-side `GlobalLight` is a
  fixed constant installed again for every player pass; no mutation was found.
- Added an isolated launch-only discriminator in commit `cc1cea0`. Observe mode
  sampled the original permutation. Fixed mode temporarily substituted
  `0,1,2,3` only around `lvlRender`, then restored the original order before the
  next simulation tick. No saved setting selected either mode.
- Natural order covered all 24 permutations with zero invalid samples and
  changed on 11,000 of the first 11,490 transitions. The fixed-render run still
  sampled all 24 original permutations and reached 11,628 samples/11,148
  changes while presenting four coherent Temple views.
- Two matched 30-frame Simulator series did not show a systematic luminance
  improvement. Mean absolute per-pixel changes across the four cropped views
  were `0.166553/0.158212/0.141538/0.146119` on a 0–255 scale with fixed
  rendering and `0.193602/0.143154/0.150690/0.133555` with natural rendering.
  The aggregate means were effectively equal, and the per-view directions were
  mixed. Different random spawn views make this a rejection of a broad effect,
  not a pixel-identical physical flicker closure test.
- The user judged the diagnostic presentation worse. The experiment was
  rejected and reverted in `74646c3`; it is not a candidate repair. Rebuilding
  the reverted matched patch set returned exactly to executable SHA-256
  `5022ffc11d4d127b1714bd9aa728ea2eb5b2ff4736c656ab7cbd0fb5747fface`,
  ruling out regeneration/toolchain drift.
- Both ROMs, active/backup saves, and preferences remained byte-identical.
  Simulator Home cleared the active-session marker. TD-06 remains open only for
  a continuous physical recording of the accepted Preview 2 baseline; do not
  add another renderer patch until that recording identifies a repeatable
  frame-local symptom.

## 2026-08-22 — TD-06 matched depth-rebuild discrimination

- Located the exact RT64 seam: `State::submitFramebufferPair` derives depth
  `formatChanged` from width, size, or overlapping-RDRAM metadata. A changed
  format later discards the previous write, clears the depth target, and resets
  its RAM-read height.
- Added an opt-in, cause-specific counter without changing framebuffer
  allocation, clear behavior, render order, or the frozen Preview 2
  depth-address repair. Normal launches do not poll or log the counter.
- Hardened the pinned two-SDK archive verifier with full shader-build failure
  output, clean no-backup patch application, and an exported-symbol gate. The
  final device and Simulator closures each retained 210 RT64 members and 246
  total force-loaded members.
- A single-player/menu control advanced to 1,437 display lists/presentations
  with zero depth-format rebuilds. A launch-only four-player route then entered
  a real four-player Temple match without changing AppStorage; the match
  advanced from 6,035 to 7,348 display lists with four visible quadrants and
  zero rebuilds from every cause. The exact final executable repeated the live
  match from 2,696 through 4,297 display lists with every cause still zero.
- The matched zero/zero result rejects per-frame aliased-depth rebuild churn as
  the residual lighting-flicker mechanism for this build. It does not close the
  visual defect. At this checkpoint it selected shared lighting state versus
  player render order as the next discriminator; the later experiment recorded
  above rejected a broad fixed-order effect and restored the baseline.
- Both ROM copies, active save, backup save, and preferences remained
  byte-identical; Simulator Home removed the active-session marker.
- The existing Mac Alpha build directory failed its pre-existing generated-input
  gate before compilation because its private `patches.c` predates the TD-01
  probe. No generated output was replaced. TD-06's archive query is compiled
  out for `GOLDENPAD_RECOMP_MAC`; a fresh matched-generation Mac campaign
  remains required before claiming a cross-platform build pass.
- Added inert no-AOT stubs for the accumulated probe/control symbols. The
  ROM-free ARM64 Simulator verifier passed in a fresh temporary build directory;
  the final AOT executable independently exports both the TD-06 host setter and
  RT64 archive getter required by the package audit.

## 2026-08-22 — TD-05 synthetic audio discrimination

- Verified that the game requests 48 kHz during startup and then settles at
  22.05 kHz. GoldenPad's source is 22.05 kHz and AVAudioEngine's Simulator
  session/mixer are 48 kHz, so output-rate conversion is expected rather than
  evidence that the final requested rate is ignored.
- Added opt-in `--audio-probe`: project-generated continuous stereo replaces
  game sample values before the actual ring, while the real consumer checks
  absolute sequence and output steps. The prior no-classifier baseline failed;
  the unchanged detector test passes at a 0.05 threshold.
- Rejected a sine-wave candidate because per-frame trigonometry perturbed the
  cadence under test. The final continuous triangle uses integer arithmetic and
  adds no per-sample probe work to normal launches.
- The final Simulator run observed 1,110,144 output frames with zero ring errors,
  zero >0.05 jumps, and zero producer drops. It recorded 4,480 underrun frames
  across 37 callbacks. This rejects steady-state rate mismatch/ring corruption
  for the run and selects cadence/reserve for physical discrimination; it does
  not prove the reported static or authorize a buffer change.
- A matched normal-mode control reached 3,335 underrun frames/26 callbacks at
  608,931 rendered frames, compared with synthetic 3,195/27 at 604,702. This
  confirms the Simulator cadence issue is not caused by probe overhead.

## 2026-08-22 — TD-04 bounded lifecycle discrimination

- Audited the existing lifecycle path and found that the ten-second watchdog
  could not separate stopped game/runtime progress from a presentation-only
  stall, even though display-list, VI, and presented counters already existed.
- Added an opt-in, transition-relative two-second classifier that stops on
  presentation recovery or at ten seconds. Its unchanged synthetic table first
  reported `FAIL` against the generic baseline and then `PASS` for no-progress,
  presentation-stalled, and recovered cases.
- Reproduced both outcomes on retained Simulator processes. One Home/resume
  recovered at 2.281 seconds with `dl=2 vi=2 presented=2`; another held
  `dl=918 vi=917 presented=870` beyond ten seconds. The frozen run kept
  diagnostics and input alive while the game timer and audio production stayed
  fixed, so it is not evidence of a drawable-only failure.
- Did not select a lifecycle repair. The physical transition matrix must decide
  whether the next bounded work belongs to runtime/game-thread resume or to
  matched RT64/Plume drawable, present-queue, and command-fence timing.

## 2026-08-22 — autonomous TD-01, TD-02, and TD-07 evidence loop

- Added the read-only native-60-Hz fire-rate probe. Ordinary Dam guard windows
  recorded 13/17/18 committed events per 100 ticks; three player tap windows
  matched ammo and events, but sustained player discrimination is formally
  blocked until ordinary play provides at least 34 KF7 rounds. No timing repair
  was applied.
- Implemented the isolated TD-02 modern sidestep candidate. Its unchanged
  red/green mapper probe, live C-left/C-right publication, menu/watch/settings
  isolation, focused build, layout, and preservation gates pass. Physical touch
  and controller feel remains before promotion or issue closure.
- Implemented the isolated TD-07 disconnect-containment candidate. The initial
  ownership probe failed on implicit touch-to-Player-1 fallback; explicit routes,
  neutral-before-reassignment, held-input release-before-activation, stable
  controller retention, and independent overlay/scene suspension now pass the
  same synthetic gate.
- The opt-in Simulator integration reached controller Player 1 plus touch
  Player 2; a clean ordinary relaunch returned to controller Player 1 only.
  ROM, active save, backup save, and preferences remained byte-identical. Real
  disconnect/reconnect timing and explicit physical P2-P4 slots remain open.

## 2026-08-22 — harden the documentation into an execution control plane

- Added exact project/upstream evidence seams and closure tests for every TD-01
  through TD-11 item, plus one universal definition of closed and rules against
  bundling unrelated timing, input, controller, renderer, audio, or networking
  changes.
- Reworked the top of `PLAN.md` into the current post-Preview-2 execution plan:
  fire-rate measurement, modern sidestep, timing repair, controller lifecycle,
  bounded reliability discriminators, platform hardening, and finally local/
  network multiplayer readiness. Preserved the older R–P milestones as
  explicitly historical evidence.
- Added a hard network go/no-go gate requiring accepted local ownership,
  deterministic state hashes, lifecycle policy, performance headroom, protocol
  identity, and private-data safety before even the disposable two-iPad LAN
  experiment begins.
- Added a current-at-a-glance status and documentation ownership map so current
  truth, debt, plan, testing, architecture, and multiplayer scope cannot silently
  diverge again.
- Added `NEXT_STEPS.md` as the concise implementation-session queue while
  retaining `PLAN.md`, `TECH_DEBT.md`, and `TESTING.md` as the detailed
  authorities.

## 2026-08-22 — reconcile the external technical review into the engineering ledger

- Treated the supplied 1,668-line third-pass review as evidence to verify, not
  as repository instructions. Rechecked its principal claims against the
  current checkout, live issues #8/#9, and temporary read-only copies of the
  exact pinned GoldenEye64Recomp, RT64, Plume, and MGB64 revisions.
- Confirmed the native-60-Hz fire-rate defect, single-controller primary-host
  model, modern sidestep omission, present-queue backpressure mechanism,
  unbounded Metal fence wait, ignored requested audio rate, and the source chain
  supporting the aliased-depth flicker hypothesis. Preserved the distinction
  between those source findings and unproven runtime/perceptual conclusions.
- Rebuilt `TECH_DEBT.md` into the authoritative evidence-ranked priority ledger,
  corrected `ARCHITECTURE.md` to describe the shipped AOT/RT64 runtime rather
  than legacy MGB64, and expanded `MULTIPLAYER_ROADMAP.md` through stable local
  ownership, determinism, LAN research, and later internet decisions.
- Added objective fire-rate, sidestep, controller-lifecycle, lifecycle-stall,
  audio-discontinuity, flicker, and A12-family test gates. Updated status, plan,
  research, legal/source-license boundaries, dependency pins, README
  limitations, and the external-review handoff without changing runtime code or
  private data.

## 2026-08-22 — reconcile and audit the Preview 2 coordinated release

- Reconciled the accepted mobile single-player/touch/controller baseline, the
  physical multiplayer depth-alias repair, the in-app retail-ROM importer, and
  the isolated native Mac Alpha without copying retail data or generated AOT
  source into the tracked tree.
- Received user approval to merge and publish the exact audited Preview 2
  mobile build and separate Apple-Silicon Mac Alpha artifact. This promotes
  macOS to official GoldenPad project support in Alpha status while preserving
  the disclosed input, blue-edge and sustained-performance debt.
- Merged PR #10 into `main` as `b3d4cc4`; local `main`, `origin/main` and the
  GitHub default-branch ref matched before release publication.
- Published `v0.1.0-preview.2` with the audited unsigned IPA, Apple-Silicon Mac
  Alpha archive and both checksum manifests. Fresh hosted downloads matched the
  recorded SHA-256 values and passed the 18-member mobile and 20-member Mac
  package verifiers.
- Found that the tracked mobile viewport patch had advanced while the ignored
  generated patch embedding was stale. Regenerated the matched MIPS patch and
  both C embeddings, then added configure-time guards that require the current
  depth-alias markers and reject generated files older than their sources. The
  Mac build intentionally retains its isolated compact patch set.
- Rebuilt the exact signed mobile product. Its executable SHA-256 is
  `100ee12be02e2077e7559f6cd4ead210bb933abffb87874cf76a16afa06e67a9`.
  Installed build 2 in place on the connected iPhone and iPad without changing
  app-data UUIDs `3ACA6644-5550-4EEA-BDCA-D6F9D3827161` and
  `D2F4E1F3-F310-4A01-8ED7-65B907FAA17B`; independent pre/post hashes on both
  devices matched the Documents ROM, runtime ROM, active save, backup save and
  preferences. Launch succeeded on both, and the user approved this exact
  rebuild for publication after hands-on review.
- Packaged and audited the 18-member ROM-free unsigned mobile archive
  `GoldenPad-0.1.0-preview.2-unsigned.ipa` at SHA-256
  `704bdf68f67d1f0925fd1844ab865c263a79e105a6349ef410f365602e6c77e3`.
  Its sorted unsigned app-content SHA-256 is
  `bce1606fb88cf5a2a423875073871a8417d66f7b1462568bbbae390b72d1a5ec`.
- Rebuilt the native arm64 `GoldenPad.app` at executable SHA-256
  `7c78b72f4d6fd1697a5fb0572dfe22de6a8680d7df784ceb0752ef7b9527c35d`
  and added a separate deterministic Alpha packager/verifier. The 20-member
  `GoldenPad-0.1.0-preview.2-macos-arm64-alpha.zip` passed architecture,
  platform, signature, dependency, icon, notices, private-path and game-data
  audits at SHA-256
  `7a9e7342b0ae39518f73807f854b479d9691fd612ae6861ea527f2a19e4450a4`.
  It remains Alpha because mouse tuning, the thin far-right blue edge and
  sustained performance are still open.

## 2026-08-21 — trace physical split-screen corruption to the lower depth alias

- Rejected the first physical-iPad follow-up candidate. Restoring the current
  color framebuffer after both sky fill paths did not improve two-player mode:
  Player 1 remained clean while Player 2 still flashed. Four-player mode still
  corrupted lower views and also showed corruption in the upper-right view.
- Captured 81.69 seconds of the live four-player iPad output while collecting a
  bounded application log. A lower quadrant switched between a clean room and
  large black/checkerboard regions, later recovered, and the corruption moved
  from the lower-right to the lower-left view. The game loop continued to
  present and reported four distinct players without dropped-frame or renderer
  errors, making a fixed screen-layout fault or game-loop stall unlikely.
- Compared GoldenEye's original depth-buffer setup with RT64's framebuffer
  tracking. GoldenEye renders lower players through a depth-image address one
  logical screen below the shared allocation, relying on RDP address/Y aliasing.
  RT64 recognizes a fill-only depth clear only when the clear color-image
  address exactly equals the next depth-image address. The prior patch cleared
  lower players through the unshifted address, so RT64 treated the clear and
  render as different resources even though the N64 byte ranges alias.
- Changed the per-player depth clear to use the same shifted image address and
  original viewport Y range as `zbufInit` for Player 2 in horizontal split and
  Players 3/4 in four-player mode. Added a stored-patch regression guard and
  verified the complete patch applies cleanly to a fresh upstream checkout.
- Regenerated the matched MIPS patch payload in an isolated source copy so the
  concurrent native Mac experiment's generated artifacts were not overwritten.
  A 43.87-second ARM64 iPad Simulator recording kept all four Temple quadrants
  intact while Player 1 input registered. This remains a regression check, not
  hardware acceptance.
- Built and signed the exact ARM64 iPad candidate for team `VKDH2T9UTF` at
  executable SHA-256
  `0976dcdfd17de60beda8e8e60ccff3fc81da7da0b2ef43f159cdea061149677d`.
  Installed it in place on the paired iPad Pro after backing up `Documents` and
  `Library`. Both ROM copies, the active save, backup save and preferences were
  byte-identical before/after; launch succeeded as PID `7124`.
- Hands-on four-player testing found this to be the best physical build so far:
  all four views remained coherent and the former black/checkerboard corruption
  did not return. A slight lighting shimmer remains, so this is the stable
  experimental Preview 2 baseline rather than a claim of bug-free multiplayer.
- Preserved a 59.33-second 1600x1200 H.264 device recording with 48 kHz AAC
  audio. Across 3,336 consecutive frame comparisons, the largest whole-quadrant
  average luminance change was 1.02/255. The paired device log progressed through
  54,652 presented VI updates with zero audio drops or underruns. Freeze this
  exact build and track the residual shimmer as a separate lower-severity issue.

## 2026-08-21 — isolate native Mac mouse/Crouch regression

- Compared the broken `GoldenPad.app` with the retained 21:16:44
  `GoldenPadMac.app`. Hands-on testing confirmed the retained executable still
  accepted mouse look and C Crouch and did not exhibit the later large blue or
  duplicated geometry regression; its remaining renderer symptom was the thin
  far-right blue edge.
- Found that `patches.c` and `patches_bin.c` had been regenerated seconds after
  that retained executable without the tracked modern-controls patch. The host
  still produced camera and crouch input, but the embedded game patch no longer
  called `recomp_get_camera_inputs` or
  `goldenpad_recomp_consume_crouch_toggle`.
- Reapplied `goldeneye64recomp-ios-modern-controls.patch`, rebuilt the MIPS
  patch, regenerated both embedded patch halves, restored the retained
  Metal-view event architecture, and rebuilt the product as `GoldenPad.app`.
- Added a regeneration gate to verify both bridge calls before linking. The
  rebuilt app remains pending hands-on mouse, Crouch, WASD and renderer
  acceptance; build success is not gameplay acceptance.
- Rejected that rebuild after visible staggering and 46,323 audio-underrun
  frames across 396 callbacks. The retained comparison initially produced zero
  underruns but later froze, so it remains evidence rather than a fallback.
- Isolated the Mac candidate from the later multiplayer viewport patch without
  changing the iPhone/iPad source. The isolated patch output contains 349
  functions versus 356 in the staggering build and retains both required input
  bridge calls. Built, signed and launched it as `GoldenPad`; sustained
  hands-on acceptance remains open.
- Rejected the first compact candidate after it became staggered and effectively
  uncontrollable. QuickTime was not running at the subsequent process check.
  The native log showed initial render/audio progress, while the prior session
  later collapsed to only a few VI presentations per interval and accumulated
  underruns.
- Traced a host-side starvation path to Plume scheduling background window-size
  and refresh-rate reads onto AppKit's main queue for every presentation. Added
  a Mac-only coalescing patch that bounds each class to one pending update,
  rebuilt the pinned RT64/Plume archives with the standalone Metal toolchain,
  and produced a newly linked, ad-hoc-signed Release `GoldenPad.app` at
  executable SHA-256
  `0e73a74da8866f9f3784afedf78ff87a0ca18916e363e63fb33083747b149d00`.
  A later clean launch reached authentic gameplay without recording or
  continuous profiling. Hands-on review retained it as the Mac alpha baseline
  and then intentionally quit the app. Mouse look remains too slow, controls
  remain less polished than mobile, and the thin far-right blue strip persists.
  The renderer/input path is frozen for the coordinated update rather than
  risking a return of the much larger rejected geometry regressions.

## 2026-08-21 — repair two-player viewport ownership

- Traced the flashing split-screen failure to recomp patches that selected or
  cleared the full framebuffer during each player render pass. GoldenEye renders
  players sequentially and shuffles their order, so those operations could erase
  the other player's completed view.
- Scoped sky fills, background scissor, depth clears and fades to the current
  player viewport while retaining extended horizontal output for a full-width
  two-player view.
- Recompiled the MIPS patch payload, regenerated its C embedding, built the full
  ARM64 Simulator app and installed it in place. The existing user-supplied ROM,
  save and backup remained byte-identical.
- Entered a real two-player Temple match using controller Player 1 plus touch
  Player 2. Both horizontal views remained stable through more than 11,000
  presented VI updates; Player 1 camera input and Player 2 FIRE registered on
  their separate ports. Physical iPhone/iPad acceptance remains open.
- Moved three/four-player layout, neutral four-port diagnostics, enhanced
  multiplayer visuals and networking into `MULTIPLAYER_ROADMAP.md` so they do
  not expand the Preview 2 repair.
- Added a subordinate iOS/iPadOS four-player render diagnostic that advertises
  neutral Players 3/4 only when explicitly enabled. A real four-player Temple
  match opened on ARM64 iPad Simulator with four correctly placed quadrants;
  controller Player 1 and touch Player 2 registered independently while Players
  3/4 remained neutral.
- Exercised Player 1 movement and its pause/watch screen. The watch remained
  confined to the upper-left quadrant and did not erase the other three views.
  All four views remained intact through 10,773 presented VI updates. Physical
  iPad validation and real four-controller routing are not claimed.
- Fixed the iPhone utility menu crop by anchoring the three-dot button to the
  saved START control's horizontal position in the same full-screen geometry.
  The corrected circle was fully visible and centered above START on the iPhone
  Simulator; the independent iPad touch layout remains unchanged.
- Built the resulting app as signed ARM64 for team `VKDH2T9UTF`, executable
  SHA-256 `b6c5bd38ca911fe437e7378c1e451b193d11a987e08f94540c89250ce649c4d2`,
  and installed it in place on the paired iPad Pro. The user-supplied ROM,
  active save, backup save and preferences were byte-identical before/after.
  Launch succeeded as PID 7013; physical multiplayer gameplay is awaiting the
  user's hands-on acceptance.

## 2026-08-21 — finalize GoldenPad Preview 1

- Promoted the GoldenEye64Recomp/N64Recomp/RT64 build to the primary GoldenPad
  runtime while retaining the older MGB64 app as deprecated Legacy fallback.
- Accepted the final single-player candidate on physical iPhone and iPad with
  touch and Xbox/MFi controller input. The iPhone 14 layout selected during
  hands-on testing is now the clean-install phone default; saved user layouts,
  opacity and other preferences remain preserved across in-place updates.
- Kept unlock-all-missions disabled by default. Existing tester preferences are
  not reset when an updated build is installed.
- Documented multiplayer as experimental: split-screen flashing and physical
  multi-controller completion remain open and do not block Preview 1.
- Added deterministic unsigned-IPA packaging and an archive verifier that
  rejects ROM/save/signing data, known retail headers, MGB64 symbols and private
  paths while requiring primary-runtime symbols and dependency licenses.
- Built and audited `GoldenPad-0.1.0-preview.1-unsigned.ipa` at SHA-256
  `a3aa37003a56a498820d07e84de89660d309c2cde40d0911fb3826086caca3e9`.

## 2026-08-04 — prove the public another-Mac handoff

- Compared GoldenPad directly with HarkinianPad's public README and aligned the
  useful visitor structure: captioned current screenshots, install status,
  supported game, direct signed-iPad commands, licensing FAQ, project map, and
  contribution/security guidance. Claims remain narrower where physical proof
  is absent.
- Added `CONTRIBUTING.md`, `SECURITY.md` and `docs/RELEASE_CHECKLIST.md`. The
  README now gives the exact Apple-team/bundle-ID build and `devicectl` install
  path rather than requiring a reader to reconstruct it from engineering notes.
- Cloned public-surface commit `f6d33ee25d5abc05900c02ab5b483d643b085f31`
  with `--no-local` into a fresh temporary directory. It fetched MGB64 from its
  public GitHub remote at the exact pin, built both ARM64 SDK apps, packaged and
  audited the IPA, resolved all tracked Markdown/image targets, restored the
  ignored upstream checkout and ended clean.
- The clean clone reproduced Simulator executable `818f1733...91a0`, device
  executable `43bfe1b5...f389`, IPA `6eed064c...c738d`, and sorted app content
  `aed6b272...08a6c`. The temporary clone was deleted. Signed installation is
  ready for a receiving Mac's own Apple identity and iPad, not falsely claimed
  as completed here.

## 2026-08-04 — make the physical signing path real

- Found that the public instructions told a developer to configure signing even
  though the generated target hard-disabled it and the maintained MGB64 patches
  were restored immediately after the unsigned verifier. Added opt-in team and
  bundle-identifier inputs to the existing verifier so compile and automatic
  provisioning happen inside the same safe patch window.
- Kept signed Simulator/device trees separate from the reproducible unsigned
  trees. The signed branch verifies the final code signature, embedded mobile
  provision and requested bundle ID; the default branch still explicitly builds
  with signing disabled.
- Generated unsigned and signed probe projects. They respectively contained
  `CODE_SIGNING_ALLOWED/REQUIRED=NO/NO` and `YES/YES`; the signed probe also
  carried `ABCDE12345` and `com.example.goldenpad` exactly. Shell syntax passed.
- Rebuilt the complete unsigned game/Metal/audio closure. Simulator and device
  executables remained byte-identical at `818f1733...91a0` and
  `43bfe1b5...f389`; the device app remained unsigned and `ref/mgb64` remained
  clean. Actual signed installation is not claimed: this Mac reports zero valid
  signing identities and no connected devices.

## 2026-08-04 — close the Simulator publication ledger

- Reconciled the plan with the completed release handoff: PR #1 merged as
  `4ed057ecd926c4b9f66e53544411986b1b4e37e8`, local `main` matched
  `origin/main`, package/provenance audits passed and the worktree was clean.
- Captured a public-safe product view first on iPhone 16 Pro and then on iPad
  Pro 11-inch (M4), with no ROM loaded. The two tracked PNGs show only
  GoldenPad's project-owned setup/control-lab UI and hash to
  `ca6aafbdf1f0661cba3f597de72ed2f0cbcfb3808b7a57767fa9bc2207f2531a`
  and `b119b361884cdc1f9a1ce143b09f00c2e2ab67cdf93730171654118a9c459fab`.
- Terminated, uninstalled and shut down the phone before starting the tablet,
  then repeated cleanup on the tablet. P4 and P6 are now closed for their stated
  Simulator/publication scope; human mission/match and physical-device
  acceptance remain open.

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
