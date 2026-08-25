# GoldenPad 0.1.0 Preview 7

Preview 7 is a deliberately narrow iPhone/iPad compatibility release. It
retains Preview 6's accepted gameplay, controls, renderer settings, ROM
conversion, saves, audio, touch layouts, and native Mac behavior.

## What changed

- All 56 embedded device Metal libraries are compiled with an explicit iOS 17
  AIR target instead of inheriting the build machine's iOS 26.5 SDK target.
- All 56 Simulator Metal libraries use the matching explicit iOS 17 Simulator
  AIR target.
- The package verifier rejects missing, mixed, or unexpected Metal deployment
  targets in the shipped executable.
- Preview 6's already-shipped depth-format diagnostic counter is restored to
  the tracked RT64 patch so the tagged source and production link inputs agree.
- The iPhone/iPad production bundle advances to version `0.1.0` build `7`.

No A12-specific renderer workaround, input mapping change, optional Fire
button, lifecycle repair, audio change, multiplayer change, or Mac runtime
change is included.

## Compatibility evidence

Preview 1 through Preview 6 aborted during RT64 common-compute-pipeline setup on
an iPhone 13 mini running iOS 18.7.8. The side-by-side diagnostic build with the
iOS 17 Metal target passed ROM selection and validation, title/menu, Dam
gameplay, audio, and controls on that same device.

That result confirms the issue #19 cause and correction on the affected device.
It does not close the separate A12X first-draw crash in issue #9. The production
Preview 7 artifact has passed GoldenPad's package and production-identity gates.
Physical iPadOS and macOS acceptance remain before publication.

## Candidate acceptance

- [x] Production-identity iPhone/iPad ARM64 build and complete package audit.
- [x] Two byte-identical unsigned IPA packaging passes.
- [x] Physical iPadOS in-place update with both ROM copies, active save, backup
  save, and preferences preserved byte for byte. iPadOS migrated the app-data
  container path during installation without changing those contents.
- [ ] Physical iPadOS launch, menus, touch/controller gameplay, audio, utility
  menu, and background/foreground check.
- [x] Native Apple-Silicon Mac build and two byte-identical package-audit passes.
- [ ] Native Apple-Silicon Mac menu navigation, mouse and keyboard gameplay,
  render-edge, and bounded sustained-play acceptance.
- [ ] Hosted artifacts downloaded and re-audited after publication.

## Downloads

- `GoldenPad-0.1.0-preview.7-unsigned.ipa`
  - SHA-256: `4f6d26616fbc1d098ba1dce598ea8e958162c82efc975aa483db7e19bd9c58c4`
  - unsigned ARM64 app-content SHA-256: `ffd52cbf9df870989dfce183fb88d61c034bb33f28fedc26b6c63a1ef26e7e39`
  - executable SHA-256: `69aef6c5bb436a97893ea1a9abca773f5bea419c29872374ce30a4751f096359`
- `GoldenPad-0.1.0-preview.7-macos-arm64-alpha.zip`
  - SHA-256: `5189dcb5c7089f5ba45e7dbe17d67be9186148da20bce0c2c60e7156f78d71b8`
  - ad-hoc-signed ARM64 app-content SHA-256: `ab27557b23f95e5019b98dad7df82e6e9b808f40563643533a234cf53b874c53`
  - packaged executable SHA-256: `68cb1f0785a0dbde6adc2953dd7c16be5c725d7c863e1c5ec0bf027e8b7c96ca`

Both archives were packaged twice with byte-identical results. The unsigned
Mac source executable is byte-identical to Preview 6 at SHA-256
`05e8ec3da7ca277c22064c62b351ea53ff40eee7d3cbaa8ae967af62e7cf2c6a`.

The IPA is intentionally unsigned. The Mac Alpha is ad-hoc signed, ARM64-only,
and not notarized. Neither archive may contain a ROM, save, provisioning
profile, Apple signing identity, private build path, or generated source.

## Known limitations

- A12/A12X issue #9 remains open pending affected-hardware testing of the
  corrected target and, if necessary, a separate Tier-1/resource-limit build.
- The thin far-right Mac edge, stage/effect rendering defects, occasional audio
  static, lifecycle stalls, and residual split-screen flicker remain separate
  work.
- Real Player 2 through Player 4 controller ownership and network multiplayer
  remain incomplete.
