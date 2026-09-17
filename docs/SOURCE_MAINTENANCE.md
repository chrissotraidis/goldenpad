# Maintained Apple sources

GoldenPad's primary Apple dependencies now use immutable source commits. Normal
builds do not apply or reverse patches in dependency working trees. This work
preserves the previous upstream versions and keeps the iOS and Mac renderer
variants separate. Legacy MGB64 and LAN experiments retain their separate paths.

## Runtime provenance recovered

The old `e75e0de77e8377d4954fe7b511c0d1cf608e7ded` identifier was a temporary
**local baseline commit**, not an upstream revision. Original build records show
that the runtime was copied from GoldenEye64Recomp `a787fe0`, initialized as a
new Git repository and committed before applying the AOT patch.

Recovery reproduced that exact Git commit from the public vendored tree
`fb2bb121643d3e0e84f7f430a34f59f0955bc5de`. Its commit metadata was `baseline`,
author/committer `private <private@example.invalid>`, Unix time `1787228808`,
timezone `+0200`. The recovered object and tree are preserved in the private
backup bundle. The runtime's source was never missing from the public upstream;
the earlier audit mistakenly treated a disposable local commit as a necessary
upstream fetch target. That blocker is resolved.

## Exact sources and patch mapping

[`sources.lock.json`](../sources.lock.json) and the app's gitlinks are the
machine-readable authority. GitHub fork/parent metadata was verified for all
three forks; each preserves upstream ancestry.

| Maintained source | Selected commit | Previous preparation |
| --- | --- | --- |
| [GoldenEye64Recomp](https://github.com/chrissotraidis/GoldenEye64Recomp/tree/goldenpad/apple-maintained), parent cblock85/GoldenEye64Recomp `a787fe0d95e8278fcba5ba2d768fa6a606e75f55` | `0fb5d192071920304aeb92f30478d3e321a976b4` | render-trace and modern-controls patches; vendored runtime AOT patch |
| [RT64 iOS](https://github.com/chrissotraidis/rt64/tree/goldenpad/ios), parent rt64/rt64 `5473732a822a4423b5696e7cb18fecc425a59875` | `b3a1ceef3fbae10a4a5e5e1f0c240fb60b6d2a0a` | SDK and embedded-Apple patches; pinned iOS Plume |
| [RT64 Mac](https://github.com/chrissotraidis/rt64/tree/goldenpad/macos), same parent/base | `24995c8e4f98c46cb361327562f436289031e305` | Same renderer changes; pinned Mac Plume |
| [Plume iOS](https://github.com/chrissotraidis/plume/tree/goldenpad/ios), parent renderbag/plume `d890ac899e505fb30040e037a4037cdeca68f033` | `2477e5ae6d9972aa37c1e9c077a27e58051d3bae` | Apple Metal and Simulator-query patches |
| [Plume Mac](https://github.com/chrissotraidis/plume/tree/goldenpad/macos), same parent/base | `aa0064be917115d09ae9b8a1323f80041325f195` | Apple Metal and Mac main-queue coalescing patches |

GoldenEye64Recomp/N64ModernRuntime retain GPL-3.0; N64Recomp, RT64 and Plume
retain their existing licenses. No blanket license or new grant is applied to
original GoldenPad code or game-derived material.

The old patch files remain as migration evidence, not the primary source of
Apple behavior. Generated-game weakening is still a required, pinned generator
step: generated files remain private. The Simulator resource-limit option stages a disposable source copy before
applying its diagnostic-only patch; maintained production trees stay unchanged.
LAN clock experiments retain their separately recorded baseline checkout.

## Build and update

```sh
scripts/bootstrap-sources.sh
python3 scripts/check-sources.py
scripts/generate-recomp-inputs.sh /private/path/GoldenEye_TLBFREE.z64 "$PWD/build-private-inputs"
scripts/build-recomp-runtime.sh iphoneos
GOLDENPAD_RT64_ARTIFACT_DIR="$PWD/build-rt64-ios" scripts/verify-rt64-ios-static.sh
scripts/build-recomp-macos-dependencies.sh
```

The generator accepts the exact supported prepared image and refuses an existing
output directory. It builds both recompilers and `file_to_c` from pinned public
source, copies only reference headers from `n64decomp/007` at
`c4356466796c697dfd298010b9bed261f9ed8c6a`, and keeps generated code/data outside
maintained source. No matching SDK implementation is compiled into the host.

Configure the existing CMake app target using `build-private-inputs` for
`GOLDENPAD_RECOMP_AOT_DIR` and `GOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR`,
`vendor/goldeneye/lib/N64ModernRuntime` for the runtime source, and the matching
runtime/archive and `vendor/rt64-ios` or `vendor/rt64-macos` paths. The existing
mobile and Mac package scripts retain package/data/signature checks.

New dependency fixes belong in the appropriate fork branch. Compare against the
recorded upstream base, commit reviewed changes there, update the app gitlink
and lock together, then run source/generation parity and both platform checks.
Do not advance a shared upstream default or silently update another app.
Bootstrap refuses modified source; verification checks exact commits and nested
renderer dependencies. Source archives can be checked without Git metadata.

## Validation and rollback

The maintained files matched the old effective source and executable modes:
10,903 GoldenEye/runtime files; 302 RT64 files per platform; 131 Plume files per
platform. Only RT64's fork URL and selected Plume gitlinks intentionally differ.
All 63 generated AOT files, five generated patch files and two RSP files matched
the preceding candidate after regenerating with pinned public tools.

Complete original/candidate checkout backups and an all-ref Git bundle were
independently restored (227,692 manifest entries), along with all 12 copied iPad
files. Backups are outside the checkout on the same physical disk; sensitive
paths/data and manifests remain private. Accepted iOS Preview 8 and Mac Preview 7
packages were downloaded anonymously and hash-verified. No device uninstall or
save reset was performed. Disposable rollback uses the preserved bundle and
snapshot; an in-place device rollback still requires matching bundle/signing
identity and has not been exercised.

## Source delivery boundary

`scripts/package-public-sources.py` exports app source, exact public dependency
sources, nested renderer sources, needed reference headers and a hash manifest.
It never copies ignored working-directory files. The archive is a public-software
source export, not a legal certification of complete GPL corresponding source.

The remaining issue is specific: the binary statically links the GPL runtime
with generated game logic, while this project's distribution rules exclude that
generated game source and the ROM needed to regenerate it. Original app code
also has no declared outbound license. Source recovery and reproducible build
scripts do not themselves resolve that source/licensing conflict. Preserve the
existing [legal boundary](LEGAL.md); no new rights-holder permission is claimed.

Preview 9 was published with explicit owner approval on 2026-09-17 under the
existing developer-preview policy. Publication does not resolve the review above.
See the [release handoff](MODERNIZATION_HANDOFF.md) for artifacts and validation.
