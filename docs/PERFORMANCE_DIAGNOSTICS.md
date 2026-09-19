# Performance diagnostics and issue reporting

This describes the diagnostics development branch, not published Preview 9.
macOS and the shared iPhone/iPad AOT host use the same bounded collector.
No game timing, resolution default, shader behavior, save format or upstream
version is changed. MGB64 Legacy is a separate runtime and is outside this pass.

## Report a problem

On Mac, open Settings → Diagnostics → Report a Problem. On iPhone/iPad, use
Report a Problem in the game menu, or below the import screen before loading a
ROM. Describe the problem, mission/area and frequency. Use the primary Report on GitHub action to open the prefilled draft.
Review technical details in the expandable section. Share Diagnostic Report
opens the native share sheet on iPhone/iPad (or file export on Mac); save the
report to Files and attach the reviewed file manually on GitHub. A screenshot or short video can help with visual problems.
Opening a draft never submits the issue or uploads a file. GitHub issues are
public. If opening GitHub fails, the app shows the project issue address.

The three-dot menu has one Report a Problem entry, with report sharing inside
it, following SunPad’s GitHub-first flow. Mac also retains its existing export. Exports include build/source
identity, dependency pins, device model/GPU, OS, requested graphics settings,
thermal/power state, recent performance context and selected log events. They
exclude ROMs, saves, raw controller values, player-memory/position dumps and
private LAN traces. Logs are filtered and common paths/credentials are redacted;
review your own answers before submitting. No telemetry service or automatic
upload is added. Session IDs are random per process, not device identifiers.

Reports label a renderer-only/no-game session and distinguish previous logs.
An unexpected-session marker is evidence of an unclean end, not a crash verdict.
Export before restarting again if the preceding session is the important one.

## What the measurements mean

Each approximately two-second monotonic window records deltas, rather than
lifetime counters. Inactive periods are marked explicitly. The window includes
process CPU time, sampled CPU usage grouped into game/Gfx/RSP/VI/other threads,
physical memory footprint, thermal state, audio rendered/dropped/underrun frames,
queued audio, display-list count, VI calls and screen submissions. Thread CPU
is a kernel sample; process CPU is a window average, and can exceed 100% across
cores. Thread names and IDs are not exported.

| Timing | Measures | Does not establish |
| --- | --- | --- |
| `display_list` | RT64 interpretation/processing wall time | Whole-game CPU cost |
| `screen_submit` | Wall time in RT64 updateScreen | A displayed frame |
| `gpu_command` | Metal GPU end minus start, read after completion | Whole-frame GPU time; command buffers can overlap |
| `gpu_completion_latency` | Submission through completion callback; errors in value_sum | GPU execution alone; includes waits and callback scheduling |
| `drawable_wait` | Time acquiring a CAMetalLayer drawable | GPU saturation by itself |
| `fence_wait`, `present_wait` | CPU waits in the Metal backend | Productive CPU work |
| `pipeline_create` | Synchronous raster/compute pipeline creation | A cold-shader cause without correlation to the hitch |
| `texture_create` | Allocation call count and wall time | GPU memory residency or total upload cost |
| `texture_upload` | Texture-copy encoding call count and wall time | GPU transfer completion |
| `present_complete_interval` | Interval between presentation command-buffer completions | On-screen scanout/unique game-frame cadence |
| `input_poll_interval` | GoldenEye input callback cadence on each calling thread | Simulation FPS; GoldenEye can poll repeatedly in a frame |

GPU command execution/latency samples one in sixteen submissions by default;
`GOLDENPAD_PERF_FULL_GPU=1` enables every command for focused local profiling.
The log records the stride. Rare GPU outliers and errors can be missed by sampling;
zero sampled errors does not prove an error-free session. CPU and presentation
cadence hooks remain unsampled.

Durations report count, mean, maximum and `p95_upper_us`: a fixed histogram
bucket upper bound, not an exact percentile. `drawable` is the output texture
size. `render_scale` is RT64's effective scale relative to its 240-line reference;
active resolution/MSAA/filter values are captured separately from requested UI
settings that apply after restarting. A ten-second no-progress event uses
elapsed time and resets on suspension/progress. It is distinct from slow but
continuing rendering. `dropped_events` includes contended timing samples and
queue overflow; treat high losses as incomplete evidence.

## GoldenEye-specific investigation

Issue #25's Mac mini M4 reporter confirmed that Preview 9 imports and plays,
but reports drops in open/busy scenes. Compare the same mission, position,
camera direction, graphics settings and warm-up time. Capture a quiet scene and
the problematic scene in one session; keep menu/loading periods separate.

* High game-thread CPU with long gaps between display lists suggests a game-side
  lead. Use Instruments Time Profiler on the GE game threads to identify functions;
  do not infer enemy AI, visibility or effects as the cause from the scene alone.
* Growing display-list time and graphics-thread CPU suggest RT64 CPU processing.
* Pipeline creation aligned with hitches is a compilation lead. Compare first
  visit against a warm revisit before changing shader/cache behavior.
* GoldenPad's earlier texture-recycler experiment reduced Simulator allocations,
  but XPC-backed texture upload remained expensive. Allocation/encoding counters
  now make this testable. Simulator results do not establish physical GPU cost.
* Long GPU commands, drawable/fence waits and CPU inactivity need a Metal System
  Trace to distinguish queue starvation, back-pressure and GPU execution.
* Thermal changes, memory growth and audio underruns provide correlated context;
  none individually proves the cause of a frame drop.

Apple recommends correlating CPU/GPU timelines in the Game Performance template.
GoldenPad emits optional Instruments signpost intervals under subsystem
`com.chrissotraidis.goldenpad`, category `performance`, name `GoldenPad work`.
Kinds: 0 display list, 1 screen submit, 2 GPU, 3 GPU completion latency,
4 drawable wait, 5 fence wait, 6 pipeline, 7 present completion interval,
8 texture creation, 9 copy encoding, 10 input poll interval, 11 present wait. Never add
`waitUntilCompleted` just to profile: the completion handlers read GPU timestamps
without changing submission order. MetricKit remains a possible later crash/hang
supplement; it is not a replacement for these scene-level measurements.

References: [Apple Metal performance analysis](https://developer.apple.com/documentation/xcode/analyzing-the-performance-of-your-metal-app/),
[signposts](https://developer.apple.com/documentation/os/ossignposter),
[GPU timestamps](https://developer.apple.com/documentation/metal/mtlcommandbuffer/gpustarttime),
[drawable practices](https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/Drawables.html),
[MetricKit](https://developer.apple.com/documentation/metrickit).
The reporting workflow was informed by KartPad's native Report a Problem flow
and GalaxyPad's bounded draft/export design; implementation here is project-specific.

## Collection and validation

Hot-path hooks only try a short lock and update fixed histograms; contention drops
samples instead of waiting. Events enter a queue capped at 256 lines of at most
896 bytes. A worker writes every 250 ms, emits summaries every two seconds and
retains two 4 MiB segments per session, plus the prior session's two segments.
Export reads at most 256 KiB from each selected segment. Truncated first lines
are omitted. Symlink log files are rejected. A bounded export flush can wait up
to 750 ms for queued events; process termination can still lose the final tail.
File write failures go to unified logging; the app cannot manufacture missing
logs. Unified debug messages are private; performance signposts contain numbers.

Run `scripts/test-diagnostics.sh` for histogram/stall/concurrency, actual rotation,
export-filtering, symlink, redaction and URL-bound checks. Build both shipping
Apple targets, then verify the report flow in the real Mac app and iPad/iPhone UI.
The no-game Simulator probe proves the UI, not AOT gameplay or device performance.

For an otherwise identical local control build, launch with
`GOLDENPAD_PERF_DISABLED=1`. This disables timing/system sampling, not lifecycle
logging. Compare warmed scenes repeatedly with and without collection; use an
initial acceptance budget of <2% median overhead, with no recurring new hitch.
A title-sequence or host microbenchmark cannot certify gameplay overhead on an
M4 Mac mini or a physical iPhone/iPad. Keep those acceptance boundaries explicit.

## Source ownership and rollback

New renderer hooks live in the existing GoldenEye64Recomp and Plume forks, pinned
through RT64 and `sources.lock.json`. Optional weak defaults preserve standalone
renderer linkage. Normal app builds compile `vendor/goldeneye/src/main/rt64_render_context.cpp`
directly; the stale copy in private generated-input folders is no longer used.
The runtime and all private generated game sources remain unchanged.

Use a clean checkout of the pre-change main `20e352efccf60fccf390165e6c7382e9df33ecd3`
and `scripts/bootstrap-sources.sh` to restore the original source graph. Existing
Preview 9 downloads are unchanged. Reinstall only in place with the established
bundle/signing identity; never delete app storage. The task's complete private
checkout/artifact backups and restoration manifests are kept outside the repo
on the same physical disk. No new physical-device rollback is claimed.
