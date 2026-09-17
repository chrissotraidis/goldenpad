## GoldenPad Preview 9 — Apple builds

Mac ROM setup now accepts a supported original GoldenEye NTSC-U ROM and performs the same conversion already used on iPhone/iPad. Imports run away from the UI thread, verify their output, and preserve the existing stored game file on failure. This addresses the Mac import limitation reported in #25.

Both Apple builds now select required game patches reliably, independent of private build-directory names. Dependency changes live in pinned maintained GoldenEye64Recomp, RT64 and Plume forks; normal builds no longer patch source in place. No upstream version was upgraded.

### Downloads
- iOS/iPadOS 17+: unsigned IPA, version 0.1.0 build 9; sign for your own device.
- Apple Silicon Mac: ad-hoc-signed native alpha, version 0.1.0 build 2.
- Public-software source archive and SHA-256 checksums.

Supply your own supported ROM. Downloads exclude ROM images, saves, extracted retail media and signing credentials. Existing device data was preserved during this work; no new physical-device installation or broad gameplay acceptance is claimed. Mac remains an alpha with its existing platform limitations; this release does not claim to fix unrelated device crash or graphics reports.

### Verification and source provenance

Artifacts and source archive were built from clean commit `56851bf84614240f381d4602ba7919dc39e64c82`. PR #27 subsequently merged the fixes, maintained sources and documentation into main. Exact dependency pins are in `sources.lock.json`.

Original/prepared ROM conversion and failure-preservation tests passed. Both Apple Release builds, package audits and device/Simulator renderer checks passed. The maintained Mac app advanced into the title-sequence cast credits in isolated storage. The public-software archive restored independently and regenerated identical private AOT, game-patch and RSP output.

### Distribution boundary — unresolved review

The source archive includes public software sources, required nested dependencies, reference headers and build/generation scripts. It excludes the user ROM and generated game source. It is not a certification of complete GPL corresponding-source delivery. The statically linked GPL runtime/generated-game source boundary and original host's lack of an outbound license grant remain under review. No new license, rights-holder permission, commercial clearance or App Store clearance is claimed. See `docs/SOURCE_MAINTENANCE.md` and `docs/LEGAL.md`.

### Published checksums

```text
d5590251259f503093560ce2dbc7c1dd14d9e487eb52cd36c3aae39dda234a41  GoldenPad-0.1.0-preview.9-unsigned.ipa
345c59477fb22a1eb8fce5f9dd4545351af6fb6c44c8edf45daab3775bea5b84  GoldenPad-0.1.0-preview.9-macos-arm64-alpha.zip
6fa53fdfbafe4d99d01d85299eac09e13338c661095359f1d9ff42c7a0f4a1ed  GoldenPad-0.1.0-preview.9-public-software-sources.tar.gz
```
