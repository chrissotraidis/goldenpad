# Modernization handoff — 2026-09-17

The runtime source blocker is resolved. The old commit was a disposable local
snapshot of public source; the exact original hash and tree were recovered.
[Source maintenance](SOURCE_MAINTENANCE.md) records the proof, fork parents,
immutable pins and old-patch mapping. No upstream version was upgraded.

Implementation commit: `56851bf84614` in
[PR #27](https://github.com/chrissotraidis/goldenpad/pull/27).
GoldenEye/runtime, RT64 and separate iOS/Mac Plume source files match their old
prepared trees. Normal dependency builds consume maintained source without patch
replay. ROM and generated game code remain private.

## Published Preview 9 artifacts

| Artifact | SHA-256 |
| --- | --- |
| iOS build 9 `GoldenPad-0.1.0-preview.9-unsigned.ipa` | `d5590251259f503093560ce2dbc7c1dd14d9e487eb52cd36c3aae39dda234a41` |
| Mac build 2 `GoldenPad-0.1.0-preview.9-macos-arm64-alpha.zip` | `345c59477fb22a1eb8fce5f9dd4545351af6fb6c44c8edf45daab3775bea5b84` |
| `GoldenPad-0.1.0-preview.9-public-software-sources.tar.gz` | `6fa53fdfbafe4d99d01d85299eac09e13338c661095359f1d9ff42c7a0f4a1ed` |

Both Apple Release builds and package audits passed using newly built maintained
runtime/renderer archives. Device and Simulator renderer checks passed with
explicit iOS 17 Metal targets. Real retail/prepared import tests and preservation
checks passed. The Mac build was observed advancing into title-sequence cast
credits in isolated storage and then closed normally. No new physical iPad
installation or broad gameplay acceptance is claimed.

The public source archive restored independently, verified all 31,648 files and
symlinks, and regenerated identical private outputs without the original
checkout or Git metadata: 63 AOT, five game-patch and two RSP files. A modified
source file was rejected by its manifest check, then restored. Original checkout,
device data, accepted packages and recovery bundles remain preserved outside the
checkout on the same physical disk; see the private recovery ledger for paths.

## Publication and remaining review

[Preview 9](https://github.com/chrissotraidis/goldenpad/releases/tag/v0.1.0-preview.9)
was published on 2026-09-17 with explicit owner approval under the existing
developer-preview policy. The release contains the artifacts above and a SHA-256
manifest. All four assets were downloaded anonymously after publication; the
three payload hashes match the published manifest and the audited local files.
Earlier releases remain available unchanged.

The source/licensing review remains open. The binary combines GPL runtime code
with generated game logic that project rules prohibit publishing, and original
app code has no outbound license grant. The public-software source archive does
not by itself settle that separate issue. No third-party or original-host license
has been invented or changed. No new physical iPad acceptance is claimed.

GoldenPad's [canonical checklist](https://app.notion.com/p/3dcceacc88a5810395c2e00ab6173d08)
remains in Follow-up for these outstanding gates. Runtime recovery and source
maintenance are complete; the earlier missing-runtime blocker is resolved.
