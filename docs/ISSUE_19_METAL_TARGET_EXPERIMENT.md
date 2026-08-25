# Issue 19 Metal Deployment-Target Experiment

Status: automated verification and physical issue #19 confirmation complete;
the correction is selected for production promotion in Preview 7.

Date: 2026-08-24

## Scope

This experiment changes only the deployment target embedded in RT64's generated
Metal libraries. It does not include the separate A12/A10 Tier 1 renderer work.

The branch begins at exact Preview 6 commit
`32de23d00f533b7803a57b19b77380605147b9af`. The published Preview 6 IPA remains
the untouched control at SHA-256
`ced4d58bd8b54fd0dac4c7e9d892e22ea80f28d4bfa219fd586818dd62ba7266`.

## Diagnosis being tested

Preview 6's embedded Metal libraries identify themselves as targeting iOS
26.5 even though the app declares iOS/iPadOS 17.0. The issue #19 iPhone 13 mini
runs iOS 18.7.8 and aborts while RT64 creates its first common compute pipeline.
The same Preview 6 starts on an older iPhone 12 mini running iOS 27 beta.

The static RT64 builder already computed an iOS 17 target but did not pass a
minimum deployment version to the Metal compiler.

The first clean full-app link also exposed a Preview 6 source-reproducibility
gap. Preview 6's app source calls `goldenpad_rt64_depth_format_rebuild_stats`,
and the published Preview 6 executable exports that symbol, but the RT64 patch
on `origin/main` did not contain its implementation. This experiment restores
the exact already-released counter-only seam and verifies that both new RT64
archives export it. The counter observes depth-format rebuild causes; it does
not change the format-change decision or rendering result.

## Isolation boundary

The test artifact uses:

- display name `GoldenPad I19 Test`;
- bundle identifier `com.chrissotraidis.goldenpad.issue19-test`;
- marketing version `0.1.0`, build `7`; and
- release name `0.1.0-issue19-test.1`.

It therefore installs beside Preview 6 instead of replacing its app or data
container. All dependency, app and package outputs are written beneath this
experiment's isolated worktree or a new temporary dependency copy.

## Required automated evidence

- all 56 device and all 56 Simulator Metal libraries compile with explicit AIR
  triples for iOS 17, retaining the required `-simulator` platform marker in
  the Simulator libraries;
- host shader-generation failures preserve their Ninja diagnostics instead of
  being discarded by the verifier;
- the temporary RT64 and Plume patch cycle restores its isolated dependency
  checkout without leaving patch backup files;
- every generated Metal library contains only `apple-ios17.0.0` target metadata;
- the complete device and Simulator RT64 static closures pass their existing
  architecture, membership and desktop-symbol checks;
- the side-by-side app builds from the exact Preview 6 AOT/runtime inputs;
- existing input, fire-rate and Preview 6 baseline gates pass, while the known
  stub-host gap is recorded separately;
- the unsigned IPA passes the complete ROM/save/signing/path/license audit;
- the packaged executable contains only iOS 17 Metal target metadata; and
- the published Preview 6 artifact and local control build remain byte-identical.

The IPA verifier defaults to the corrected iOS 17 target. Its expected target
can be set explicitly when re-auditing a historical artifact, so the new guard
does not make the unchanged Preview 6 control unverifiable.

The package script also accepts explicit read-only RT64 and GoldenEye reference
source paths. Its defaults are unchanged; the experiment uses the explicit
paths so packaging does not require copying private/ignored dependency trees
into the worktree.

## Physical closure

The issue #19 reporter tested the exact hosted diagnostic IPA on the same
iPhone 13 mini running iOS 18.7.8 that failed Preview 1 through Preview 6. ROM
selection and validation, common-pipeline initialization, title/menu, Dam
gameplay, audio, and controls all passed. This confirms the deployment-target
correction on the affected device. Issue closure still requires confirmation of
the production-identity Preview 7 artifact because the diagnostic app used a
separate bundle and data container.

## Automated results

The final device and Simulator archive build passed the existing RT64
membership, force-load, architecture and dependency gates:

| Artifact | SHA-256 |
| --- | --- |
| Device `rt64.a` | `0ff650a24ca02b87302ce4c25fb506218c237a1cb80f9ee63b48686c4924798c` |
| Simulator `rt64.a` | `7476d0019676172ffdfe540b5a296187f8bfd711dced40a157fe3acf247a52dc` |
| Device executable | `46e836ffebf04fdfc06c524e7e515a0d101ad7f4bbda28b5cf52a6b7eb32d116` |
| Simulator executable | `5a6a026a60d0dc99ac09931026172d83a10a577ba90f5c9c2157c1a193d15745` |
| Unsigned experimental IPA | `a878a9aed0a253ce0012f473d171429edb1c5bb306bbb01184dac6dff1b891bd` |

The IPA was packaged twice with the same checksum. Its complete audit passed
with 18 members and unsigned app-content SHA-256
`ea955c670ea0731608e26a36510135fe803d4f58c9080c2d7855e9d065da9396`.
The device executable contains only `air64_v26-apple-ios17.0.0`; the Simulator
executable contains only `air64_v26-apple-ios17.0.0-simulator`.

The side-by-side Simulator app validated the private ROM, started the GoldenEye
loop and reached `RT64 setup ready`. An initial test caught that the deployment
minimum alone omitted the Simulator platform marker; the final explicit AIR
triples removed every `library was not compiled for the simulator` error. The
standard renderer then reported the Simulator's known Tier 1 31-buffer and
16-sampler limits. That is the separately documented A12/A10 compatibility
work and is not part of this device candidate.

The lightweight stub host gate remains broken on the Preview 6 baseline because
its stubs do not define `goldenpad_recomp_audio_probe_stats` and
`goldenpad_recomp_set_touch_input_port`. This experiment does not change those
symbols; the real AOT device and Simulator apps both link successfully.

The published Preview 6 IPA was re-audited with its historical Metal target and
remains SHA-256
`ced4d58bd8b54fd0dac4c7e9d892e22ea80f28d4bfa219fd586818dd62ba7266`.
The original dirty checkout remains on `ba5236d` with its pre-existing changes;
the experiment did not write to it or its build directories.

## Publication

The source implementation is commit `3bc34e8` on branch
`codex/issue19-metal-target-experiment`. It is intentionally not merged into
`main` pending physical confirmation.

The separately hosted prerelease is:

- release: <https://github.com/chrissotraidis/goldenpad/releases/tag/v0.1.0-issue19-test.1>
- IPA: `GoldenPad-0.1.0-issue19-test.1-unsigned.ipa`
- hosted SHA-256: `a878a9aed0a253ce0012f473d171429edb1c5bb306bbb01184dac6dff1b891bd`
- reporter request: <https://github.com/chrissotraidis/goldenpad/issues/19#issuecomment-5400358661>

The hosted IPA was downloaded again and passed the same 18-member, identity,
Metal-target, symbol, signing, ROM/save/path and license audit as the local
artifact. The reporter then confirmed ROM import, title/menu, Dam gameplay,
audio, and controls on the affected iPhone 13 mini. Preview 7 promotes the same
Metal-target correction under GoldenPad's production identity while keeping the
separate A12X first-draw investigation in issue #9 open.
