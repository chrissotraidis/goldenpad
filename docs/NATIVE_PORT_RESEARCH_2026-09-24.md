# Native GoldenEye port research — 2026-09-24

This is a source review and decision record, not a GoldenPad build or device
acceptance result. The comparison baseline is GoldenPad `main` at
`2aa1f61f1b96af717a8fd5ce490b02d92a64c1cf` (Preview 10 on iOS). Keep
the accepted game-bearing source identities in [`sources.lock.json`](../sources.lock.json)
and the current defects in [`TECH_DEBT.md`](TECH_DEBT.md). No third-party game
code or assets were imported in this pass.

## Conclusion

No newly released project supplies a proven drop-in iOS runtime, renderer, or
online server for GoldenPad. The most useful new work is the [September 20
v0.3.0 release of the N64-source GoldenEye PC port](https://github.com/jkdansereau/goldeneye-pc-port/releases/tag/v0.3.0):
it has completed a reported Agent-difficulty campaign playthrough and documents
specific native-port failure mechanisms. Its engine is a decompiled C source
port with a software RSP and desktop graphics/audio/input adapters. GoldenPad
instead executes statically recompiled N64 code through N64ModernRuntime and
RT64/Metal. Treat its findings as test ideas and game-behavior references, not
patches to copy.

## Upstream identity and immediate adoption decision

| Source checked | Finding on 2026-09-24 | GoldenPad decision |
| --- | --- | --- |
| [GoldenEye64Recomp](https://github.com/cblock85/GoldenEye64Recomp) | Public `main` is still `a787fe0d95e8278fcba5ba2d768fa6a606e75f55`, the upstream reference already recorded in `RESEARCH.md`. Its [v1.0.0 release](https://github.com/cblock85/GoldenEye64Recomp/releases/tag/v1.0.0) still lists sky/water, multiplayer UI, and some weapon cadence as known issues. | No newer upstream game patch to pull. GoldenPad's maintained fork and accepted cadence repair remain the relevant build. |
| [RT64](https://github.com/rt64/rt64/compare/5473732a822a4423b5696e7cb18fecc425a59875...main) | Two commits after the historical base: an RDNA4 Vulkan workaround and [rejection of inverted or zero-size VI regions](https://github.com/rt64/rt64/commit/43373749dac9bbc1b653e6a02aed40a9e1783bed). | Adopted the VI validity guard in both maintained Apple RT64 forks; see follow-up below. The Vulkan change does not address Metal. The guard is not evidence of an A12X fix. |
| [N64ModernRuntime](https://github.com/N64Recomp/N64ModernRuntime/commits/main/) | GoldenPad uses a recovered, patched runtime snapshot recorded in `sources.lock.json`. A deeper source audit found older upstream controller and message-queue repairs absent from that snapshot. | See the read-only follow-up below. Never swap this runtime independently of generated game code and the maintained forks. |
| [MGB64](https://github.com/akratch/mgb64) and [GoldenRecomp](https://github.com/kholdfuzion/GoldenRecomp) | MGB64 is archived as discontinued; GoldenRecomp's public branch has not gained a reproducible GoldenPad replacement pipeline. | Keep MGB64 as the existing Legacy comparison. Neither is a safer primary iOS replacement today. |
| [GoldenEye 007 PC Port](https://github.com/jkdansereau/goldeneye-pc-port) | v0.3.0 is a new Windows/Linux N64-source release with reported 20-mission Agent completion. Its [known issues](https://github.com/jkdansereau/goldeneye-pc-port/releases/tag/v0.3.0) still include audio, culling, particles, and other rendering defects; it has no iOS or ARM release. | Use its reproducible findings for focused comparisons. Do not infer iOS performance or campaign completion for GoldenPad from its desktop result. |

## Specific findings worth testing

1. **Mac mouse input — reference for TD-08, no current transplant.** The PC
   port's [direct-look change](https://github.com/jkdansereau/goldeneye-pc-port/commit/fec396f53b)
   reports that slow mouse movement was lost and fast movement saturated; its
   v0.3.0 release says a new mouse path improved both. GoldenPad already has an
   accepted Mac control repair, which the technical-debt ledger says to freeze.
   If TD-08 is reopened, first record raw delta, queued units, normalized
   output, and final yaw on one fixed Mac scene. Do not write camera/player
   fields directly or change iOS touch semantics.

2. **Long-session and mission-transition stability — medium priority as an
   acceptance matrix.** The PC port reports a [Caverns-to-intro permanent
   freeze](https://github.com/jkdansereau/goldeneye-pc-port/releases/tag/v0.3.0),
   a Control Center mission-completion crash, a save-slot/Skip Intro crash, and
   a Facility scripted-execution softlock. Its [AI command investigation](https://github.com/jkdansereau/goldeneye-pc-port/commit/ede16415f2)
   and [broader source audit](https://github.com/jkdansereau/goldeneye-pc-port/commit/448444ed38)
   are useful for naming exact transitions and state to capture. Some failures
   arise from the PC port's own teardown timing; one Facility AI softlock is
   described as possible on original N64 hardware too. GoldenPad should first
   play or script the corresponding transitions on its unchanged build and
   compare original behavior before any game-side fix. Do not add a broad
   watchdog based solely on another port's result.

3. **Audio under load — conditional, relevant to TD-05.** The PC release
   describes a sound-preemption pointer crash on Steam Deck and still lists
   gunshot cadence and intermittent silence as open. Its [D285 repair](https://github.com/jkdansereau/goldeneye-pc-port/commit/1970ab3732f4)
   protects a sound-list reader from a concurrent writer with `osSetIntMask`.
   GoldenPad's game source has the same reader/writer pattern, but its
   N64ModernRuntime `osSetIntMask_recomp` is a no-op. Copying that one call
   would provide no synchronization here. First establish whether those paths
   run concurrently in GoldenPad; if so, design a focused synchronization
   repair and stress it under sound bursts. Also use sustained PP7/AK47 fire
   near a looping alarm as a *listening* scene for the existing static/silence
   report, with ring/underrun/route counters. The PC port's native pointer
   representation differs from GoldenPad's emulated N64 memory.

4. **Visual parity — narrow, lower priority than observed GoldenPad defects.**
   The PC release reports fixes to IA4 texture decoding, near-plane portal
   culling, overscan artifacts, and widescreen FOV scaling. GoldenPad uses RT64
   and has different stage/sky/water gaps. A matched original-versus-GoldenPad
   screenshot at one named stage/camera is required before testing any of those
   algorithms. The PC port still lacks true native widescreen and reports its
   own culling, particle, and water defects. Its 60 fps claim is a desktop
   campaign result, not a GoldenPad iOS optimization.

5. **RNG and 64-bit layout — reference only.** The PC port fixed a PRNG shift
   mismatch and several native pointer-width/layout faults in cutscenes,
   particles, and saves. GoldenPad's static recompilation retains N64 memory
   layout; these mechanisms are not evidence of the same bug here. If a
   GoldenPad replay diverges, compare the exact N64 RNG sequence and state
   first. A source-port pointer-size patch should not enter the recomp runtime.

## New ports to watch, without an adoption case yet

- [GoldenEye Omniport's author announcement](https://www.reddit.com/r/GoldenEye/comments/1w12l2b/goldeneye_omniport_initial_release_android_macos/)
  describes Android, macOS, and Linux source ports at 30 fps, with Android
  controller and touch input. The linked `Gilleece/goldeneye-omniport` GitHub
  release/repository was unavailable during this review, so its code and
  release could not be inspected. It supplies no verified iOS or RT64 fix.
- [ARM-GE's author announcement](https://www.reddit.com/r/R36S/comments/1wn05lv/goldeneye_007_n64_arm64_port/)
  describes an AArch64 Linux/GLES build for R36S and a static audit tool for
  N64-to-64-bit pointer/layout failures. No public source URL was linked in
  that announcement or found in the repository search, so its audit rules
  remain a lead rather than reusable evidence. Its source-port layout risks
  also differ from GoldenPad's static recompilation model.
- Project Midas has public previews but no inspected release or source tree
  for this review. Do not use its frame-rate videos as evidence of a GoldenPad
  iOS fix. Recheck when an inspectable source revision or release appears.

## Online status and restart point

GoldenPad's research-only LAN v3 reached encrypted discovery, stable slots,
ready/start, and ordered input on a physical iPad/iPhone pair. It failed closed
at canonical frame 30: player and prop hashes matched; the aggregate hash of
19 game globals differed. The apps paused as designed. This is recorded in the
[physical checkpoint](NETPLAY_PHYSICAL_CHECKPOINT_2026-08-28.md). The
`codex/netplay-determinism-experiment` branch retains the diagnostic code but
is not part of the supported product. The smallest next experiment is v4
word-by-word logging at frames 1 and 30, then a source-proven correction and
repeat physical LAN gate. No public matchmaking or relay is justified before
a sustained two-device match and latency/disconnect acceptance.

The [GoldenEye Recomp server](https://github.com/SunJaycy/GoldenEye-Recomp-Server)
is a self-hosted matchmaker/UDP relay for the *unreleased Xbox 360 remaster*
port. It relays that game's existing System Link packets and cannot host
GoldenPad's N64 simulation. [GoldenEye: Source](https://docs.geshl2.com/server/)
and Nintendo's [Switch online release](https://www.007.com/goldeneye-007-launches-on-nintendo-switch-online-and-xbox-game-pass/)
also run different games/platform services. The new N64 PC port lists LAN as
future work and does not plan internet multiplayer today.

## Practical order

1. Finish current GoldenPad reproducibility, A12X, audio, lifecycle, and
   observed renderer evidence gates from `TECH_DEBT.md`. No upstream release
   closes them on its own.
2. Keep the accepted Mac controls frozen. Reopen the PC port mouse comparison
   only if a GoldenPad reproduction justifies it.
3. Add the PC port's named mission and audio scenes to a bounded manual
   regression list. Promote a fix only for a GoldenPad reproduction.
4. Resume LAN v4 diagnostics separately from product builds. After physical
   agreement and a playable LAN match, assess latency and only then choose an
   internet room/relay design.

Research method: official repository READMEs, tagged release notes, commit
diffs, GitHub issue state, and GoldenPad's maintained-source lock and technical
debt. No external executable was installed or run; no native-port performance,
campaign, online-server availability, or hardware compatibility claim was
independently reproduced in this pass.

## Follow-up: RT64 VI present guard adopted on 2026-09-24

The maintained iOS and Mac RT64 forks had no equivalent to upstream's
[VI validity guard](https://github.com/rt64/rt64/commit/43373749dac9bbc1b653e6a02aed40a9e1783bed).
The patch now requires a visible VI to have positive framebuffer width and
height before it enters the present path. Valid frames retain the same path.
The fork commits are
[`241fb1905f121e2af94a2b74baf2e9e46b1aee0f`](https://github.com/chrissotraidis/rt64/commit/241fb1905f121e2af94a2b74baf2e9e46b1aee0f)
for iOS and
[`3baebf2a2843bd6c4b5ae84fc13e904894398370`](https://github.com/chrissotraidis/rt64/commit/3baebf2a2843bd6c4b5ae84fc13e904894398370)
for Mac; `sources.lock.json` pins both exact commits.

`scripts/check-sources.py` passed. The maintained iOS static RT64 library
built and linked for arm64 iPhoneOS and arm64 iPhone Simulator, and
`scripts/build-recomp-macos-dependencies.sh` built the arm64 Mac runtime and
RT64 dependencies. No game-bearing app or physical-device gameplay was run for
this change. Issue #9 crashes at the first Metal raster submission, a different
path from this guard; it remains open until its own reproduction and trace.

## Follow-up: deeper donor audit before another implementation

This follow-up is research only. It compares source at GoldenPad `main`
`5205187c4a0f997eb949b866c44f5bad230da06c` with public upstream commits;
it adds no runtime or renderer change. The strongest findings relate to
GoldenPad's existing controller, lifecycle, and audio debt.

| Candidate | Source comparison | Decision and proof needed |
| --- | --- | --- |
| **Controller bitmask** | [N64ModernRuntime #134](https://github.com/N64Recomp/N64ModernRuntime/commit/4cf46bf7f49e9a05a97cbbb87b6f1fb8b536c8ad) changes `*pattern = 1 << controller` to `*pattern |= 1 << controller`. GoldenPad's `vendor/goldeneye/lib/N64ModernRuntime/ultramodern/src/input.cpp` still assigns, while its host can advertise P1-P4 in test or network modes. GoldenEye's `joy.c` consumes the initialization mask and later refreshes status. | A directly applicable boot-time correctness fix, but it does **not** implement stable controller ownership or cure the reported disconnect leak. First capture the mask and P1-P4 status at initialization and after a status refresh; test one, two, and four ports and disconnect/reconnect. Integrate only with TD-07's neutral-frame and physical ownership gate. |
| **Absent-controller pad writes** | [N64ModernRuntime #117](https://github.com/N64Recomp/N64ModernRuntime/commit/ba2acaeb5c2a01db64abd9ec60f947381f5f452a) avoids copying button/stick data from a no-response pad. GoldenPad's `librecomp/src/cont.cpp` still copies every field even though `ultramodern/src/input.cpp` sets only `err_no` for a no-response pad. | Possible indeterminate button/stick bytes at disconnect. Trace the game's `errno` handling and previous sample before adopting upstream's exact write policy; this is not proof of a user-visible input leak by itself. Test no-response, reconnect, and held-input transitions with TD-07. |
| **External message delivery** | [N64ModernRuntime #125](https://github.com/N64Recomp/N64ModernRuntime/commit/a849ecf511c43949597c379a2508f7e64f9cdf44) requeues completion, SI, timer, and PI messages on a full queue while allowing VI/AI retraces to be skipped. GoldenPad has its own `ultramodern/src/mesgqueue.cpp` pending FIFO: it retains **all** external messages and stops flushing at the first full target queue. `events.cpp` calls `osSendMesg` from non-game threads for VI/AI and SP/DP; that path enqueues and reports success before actual delivery. | A plausible head-of-line stall mechanism for TD-04, not a diagnosed cause. Build a bounded queue-full reproducer: fill the VI target, queue a retrace then an SP/DP completion, and observe whether the completion can advance. Compare GoldenPad's FIFO with upstream's selective policy and retain the game-specific no-lost-completion requirement. Then correlate a physical screenshot/resume stall with queue depth and wait-point evidence before changing the runtime. Do not cherry-pick the full upstream runtime. |
| **Long-session audio state** | The N64 source PC port's [D322 investigation](https://github.com/jkdansereau/goldeneye-pc-port/commit/2d9e673129b153ec817637b75a63777470e7f01a) follows a full-campaign report of fading music and intermittent SFX. It distinguishes SFX soft-cap, event-queue, physical-voice, and output-queue health. GoldenPad currently exposes host ring, drop, and underrun counters, but not the game-side voice-pool counters. The PC port's issue remains open. | First capture GoldenPad's own audible failure with a timestamp and existing counters. If those remain healthy during the failure, a low-rate game-side voice/event-queue probe could distinguish pool drift from host output trouble. Do not import its mutex or source-port mixer assumptions: GoldenPad's `osSetIntMask_recomp` is a no-op and its audio backend differs. |

The older [Plume argument-buffer fix](https://github.com/renderbag/plume/commit/561428b7d0499eaf96b17d04bd6aa594d3b1260f)
is already present in GoldenPad's pinned iOS Metal source. Its newer
[device-query change](https://github.com/renderbag/plume/commit/53605876aec40498e50944f9a6f96380928bcb37)
addresses non-macOS and OS 27 selectors; it does not match issue #9's first
`drawIndexedPrimitives` stack. No inspected upstream change proves an A12X
repair. The full redacted crash trace and an A12-family reproduction remain the
necessary gate.

[goldeneye-native](https://github.com/seb-patron/goldeneye-native) is another
active N64 *source port*, with an iOS Metal bring-up and a separate split-screen
implementation. Its [netplay investigation](https://github.com/seb-patron/goldeneye-native/blob/main/docs/NETPLAY.md)
reports identical input traces yet early lockstep divergence, including 0/5
agreed two-process trials after seed and simulation-step fixes. It also found
render-visibility state read by AI on a different cadence; moving that work to
the tick did not eliminate desync. These are useful comparison tests for
GoldenPad's frame-30 globals mismatch, not evidence that its patch applies to
GoldenPad's static recompilation. GoldenPad's v4 word-by-word global capture
remains the next online experiment. The project's README calls iOS a bring-up,
not a proven alternative iOS release.

[GoldenEye Metal](https://github.com/ysrdevs/goldeneye-metal) reaches first-
mission gameplay with a native Mac Metal backend, but it recompiles the
unreleased Xbox 360 game. Its renderer and runtime do not run GoldenPad's N64
simulation. The announced GoldenEye Omniport repository still returned 404
during this check, so there is no inspected source to evaluate.

**Next implementation decision:** reproduce or falsify the queue ordering
problem before adopting message-policy changes; pair the two controller fixes
with TD-07's ownership work; and instrument game-side audio only after a
physical symptom with host counters. None of these findings is physical-device
acceptance, an A12X repair, or a working Internet multiplayer service.

## Validation and build integration — 2026-09-24

The controller and queue findings were reproduced against the actual pinned
runtime C++ sources, compiled with AddressSanitizer, UndefinedBehaviorSanitizer,
and patterned automatic-variable initialization. The old source failed three
behavior checks: multiple-controller masks, preserving pad values on disconnect,
and delivering to an available queue behind a full queue. Reconnect and retained
completion checks already passed.

Two maintained-source commits now address those failures:

- [`995a0f2`](https://github.com/chrissotraidis/GoldenEye64Recomp/commit/995a0f2):
  accumulate every connected port in the initialization mask. On a failed read,
  preserve the previous buttons/sticks but always update the error status;
  leave channels outside `osContSetCh` untouched. This deliberately follows
  GoldenEye's `lib/ge/src/libultrare/io/contreaddata.c`, rather than copying
  upstream #117's omission of the error-status write.
- [`7c56979d357097d32900ef4a3ec3aa6f84689ea9`](https://github.com/chrissotraidis/GoldenEye64Recomp/commit/7c56979d357097d32900ef4a3ec3aa6f84689ea9):
  try each pending external message once per pass so a full destination does
  not block another queue. Retain required completions and existing external
  callers' delivery guarantee, but allow VI/AI notifications to expire when
  their target is full. Replace the ineffective SP/DP retry loop with explicit
  reliable enqueueing. Sanitizers also caught a legacy null-pointer expression
  used for structure-member offsets; standard `offsetof` preserves the offsets
  without that undefined behavior.

[`scripts/test-runtime-reliability.sh`](../scripts/test-runtime-reliability.sh)
now passes 11 checks against the real queue, input, and guest-memory bridge
sources. Coverage includes all 16 connection masks, disconnect/reconnect,
disabled channels, retained completion order, cross-queue progress, external
waits, and 1,000 queued retraces followed by required completions. Scheduler
operations are stubbed to fail on unexpected blocking; this is a focused host
test, not a full scheduler or physical-gameplay test. Both sanitizers pass with
recovery disabled.

Full arm64 iPhoneOS and macOS apps were rebuilt from regenerated private AOT
inputs and the pinned maintained runtime. Candidate bundle builds are iOS
**12** and Mac **5**, named `0.1.0-runtime-reliability.1`. Both package audits
pass, including generated control/tank/fire-rate patch checks, ROM exclusion,
platform/dependency checks, and Mac ad-hoc signature verification. These are
local candidate packages; this work does not replace the public Preview 10
release or accept physical gameplay.

TD-04 still needs a physical resume trace to connect its reported symptom to
the queue defect. TD-07's host-side controller ownership and neutral-frame
work remains separate. Audio pool telemetry, A12X repairs, and netplay changes
were not adopted because this validation established no corresponding fix.
