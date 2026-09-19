# Diagnostics qualification — 2026-09-19

This is a development candidate, not a published release or a fix claim for #25.
Preview 9 remains public. Source maintenance was already merged in PR #27;
this pass adds app/renderer diagnostics without upgrading upstream or changing
private generated game code. `sources.lock.json` records the five new immutable
pins. The existing source/licensing review remains open.

## Verified scope

* Release builds: Apple Silicon macOS and ARM64 iOS/iPadOS AOT target. Both
  renderer static closures also pass the device/Simulator verification script.
* `scripts/test-diagnostics.sh`: native histogram/stall/concurrent-hook/rotation
  checks; Swift export allowlist, path/credential redaction, symlink exclusion,
  URL encoding/size checks; shared SwiftUI typecheck.
* Existing input matrix passes against the preserved private generated inputs;
  no generated game output was regenerated or changed. Source-pin and ROM-safety
  checks pass.
* Real Mac title-sequence launch emitted CPU/GPU/wait/texture/pipeline timings.
  Settings → Report a Problem → native file export produced a 34,338-byte
  report; checked for expected timing data and excluded raw inputs/private paths.
  No GitHub issue was posted or draft opened during validation.
* A disposable iPad Simulator installed and launched the no-game target. Its
  importer displays Report a Problem. The installed Xcode lacks Simulator.app,
  so the complete iPad form was not interactively exercised. This does not
  establish physical-device or AOT Simulator gameplay acceptance.

An all-target iOS build encounters an existing Swift type-check timeout in the
separate Legacy/Foundation target's InputSystem.swift. The shipping AOT target
builds successfully; no unrelated Legacy fix is included.

## Reproducing the build

Use the existing source bootstrap/build instructions and exact source lock.
The validation host uses Xcode 27 and Apple Metal compiler 32023.883. The installed
Metal toolchain was present but not resolved by xcrun; a private task-local xcrun
shim dispatched only metal/metallib to that installed toolchain. No global
Xcode configuration was changed. Private AOT/RSP/patch inputs and the unchanged
iOS runtime archive came from the preserved Preview 9 working sources.

Target `GoldenPadMac` for Mac and `GoldenPadRecompPrototype` for iOS, Release.
Candidate bundle versions are Mac 3 and iOS 10, both product version 0.1.0.
Keep source identity configure-time accurate by re-running CMake after changing
commits. `BuildIdentity.txt` records the app revision and all five dependency
pins. Public source exports use their manifest revision without searching an
enclosing checkout.

## Recovery and remaining acceptance

The complete dirty primary checkout and prior Preview 9 checkout were copied
outside the repository to the private task backup directory on the same physical
disk. Independent restored copies matched 194,962 and 82,296 file/mode/link
entries respectively, and restored primary Git history passed fsck. Worktree
administrative pointer files retain their original locations; these file copies
are not advertised as independently rebound Git worktrees.

For source rollback in a new disposable checkout, select pre-change main
`20e352efccf60fccf390165e6c7382e9df33ecd3` and run
`scripts/bootstrap-sources.sh`. Do not reset the dirty primary checkout. Preserve
Preview 9 packages and existing signing identity for any later in-place device
rollback; no device install, uninstall, save reset or hardware rollback was done.

Before release, compare a quiet and busy GoldenEye scene on physical iPad/iPhone
and the affected Mac, with matching camera, graphics settings and warm-up. Export
both windows. Validate report/export/open-draft behavior on-device and measure
collection overhead. CPU/GPU command timings are investigative evidence, not
unique game FPS. Full GPU sampling is for focused local profiling; normal
collection samples one in sixteen commands. See [measurement definitions and
Apple references](PERFORMANCE_DIAGNOSTICS.md).

## Local overhead screen

Four fresh-process runs used the same private ROM/settings and title sequence,
20 seconds warm-up followed by a 20-second process-CPU window, in off/on/on/off
order. Off measured 82.913% and 80.807%; on measured 84.380% and 82.876%.
Mean enabled CPU was 83.628% versus 81.860% disabled (2.16% relative increase).
This short screen does **not** meet the proposed <2% acceptance threshold;
run-to-run variation and uncontrolled host activity prevent a precise overhead
claim. Keep the PR a draft pending longer matched gameplay measurements on
the target devices. No build or package work ran during the four windows.
An earlier all-command GPU experiment prompted the bounded one-in-sixteen
sampling design; its preliminary control differed and is not a valid final
comparison. The final control disables periodic system sampling correctly.
