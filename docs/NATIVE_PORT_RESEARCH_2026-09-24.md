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
| [RT64](https://github.com/rt64/rt64/compare/5473732a822a4423b5696e7cb18fecc425a59875...main) | Two commits after the historical base: an RDNA4 Vulkan workaround and [rejection of inverted or zero-size VI regions](https://github.com/rt64/rt64/commit/43373749dac9bbc1b653e6a02aed40a9e1783bed). | The Vulkan change does not address Metal. Check whether GoldenPad's maintained RT64 fork already has an equivalent VI guard; consider the other change only if a captured invalid VI reaches the present queue. Neither is evidence of an A12X fix. |
| [N64ModernRuntime](https://github.com/N64Recomp/N64ModernRuntime/commits/main/) | Recent upstream commits concern game modes, octagonal input, and CLI selection. GoldenPad uses a recovered, patched runtime snapshot recorded in `sources.lock.json`. | No direct reliability repair identified. Never swap this runtime independently of generated game code and the maintained forks. |
| [MGB64](https://github.com/akratch/mgb64) and [GoldenRecomp](https://github.com/kholdfuzion/GoldenRecomp) | MGB64 is archived as discontinued; GoldenRecomp's public branch has not gained a reproducible GoldenPad replacement pipeline. | Keep MGB64 as the existing Legacy comparison. Neither is a safer primary iOS replacement today. |
| [GoldenEye 007 PC Port](https://github.com/jkdansereau/goldeneye-pc-port) | v0.3.0 is a new Windows/Linux N64-source release with reported 20-mission Agent completion. Its [known issues](https://github.com/jkdansereau/goldeneye-pc-port/releases/tag/v0.3.0) still include audio, culling, particles, and other rendering defects; it has no iOS or ARM release. | Use its reproducible findings for focused comparisons. Do not infer iOS performance or campaign completion for GoldenPad from its desktop result. |

## Specific findings worth testing

1. **Mac mouse input — medium priority, directly relevant to TD-08.** The PC
   port's [direct-look change](https://github.com/jkdansereau/goldeneye-pc-port/commit/fec396f53b)
   reports that slow mouse movement was lost and fast movement saturated; its
   v0.3.0 release says a new mouse path improved both. GoldenPad already has a
   measured horizontal yaw limit and an accepted control contract. First record
   raw delta, queued units, normalized output, and final yaw on one fixed Mac
   scene. Only if that reproduces the same loss class, evaluate a Mac-only
   adaptation at GoldenPad's existing input seam. Do not write camera/player
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
   gunshot cadence and intermittent silence as open. The source port's native
   pointer representation differs from GoldenPad's emulated N64 memory. Use
   sustained PP7/AK47 fire near a looping alarm as a reproducible *listening*
   scene if GoldenPad's reported static or silence recurs. Correlate its own
   ring/underrun/route counters; do not transplant a pointer guard blindly.

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
2. Run a small Mac mouse-loss comparison against the PC port's diagnosed class;
   change only the measured seam if the mechanism matches.
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
