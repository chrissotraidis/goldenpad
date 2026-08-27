# GoldenPad 0.1.0 Preview 8

Preview 8 is a deliberately narrow iPhone/iPad feature release. It adds the
requested optional second touch Fire button and retains Preview 7's accepted
gameplay, controls, renderer settings, iOS 17 Metal target, ROM conversion,
saves, and audio. The unchanged Apple-Silicon Mac Alpha remains Preview 7.

## What changed

- **Touch Controls → Add left-side Fire button** enables a duplicate N64 Z
  control. It is disabled by default.
- The additional Fire button has its own saved position, scale, and opacity for
  iPhone and iPad layouts.
- Both Fire surfaces aggregate into one action: releasing either while the
  other remains held keeps Fire active, and reset clears both safely.
- The iPhone/iPad production bundle advances to version `0.1.0` build `8`.

No renderer, audio, controller-routing, lifecycle, multiplayer, ROM, save, or
Mac runtime change is included.

## Acceptance

- [x] Focused primary/secondary/simultaneous Fire-state tests and complete input
  matrix.
- [x] Signed production ARM64 build and complete ROM-free package audit.
- [x] Two byte-identical unsigned IPA packaging passes.
- [x] Explicit iOS 17 Metal deployment target retained throughout the payload.
- [x] In-place physical iPad update with protected game data and preferences
  preserved.
- [x] Hands-on physical iPad gameplay acceptance of the exact candidate.

## Download

- `GoldenPad-0.1.0-preview.8-unsigned.ipa`
  - SHA-256: `773223b7ed7787c18526fb63281a6a3e4960b87adb0a912b0c2b77d0f1312a1b`
  - unsigned ARM64 app-content SHA-256: `be03451c0b0450c43096d49d944642a82bfb0f3c310f70289831e51fcd28dc6d`
  - accepted signed-candidate executable SHA-256: `6d90224ad63fb50c0eaae9d76e42d105e152e105b3dc9a4e12dcb80db5984dff3`

The IPA is intentionally unsigned and contains no ROM, save, provisioning
profile, Apple signing identity, private build path, or generated source.

## Known limitations

- Residual split-screen flicker and other graphical artifacting remain open.
- A12/A12X issue #9 remains unresolved.
- Issue #19's affected-device diagnostic succeeded; production-release reporter
  confirmation remains pending.
- Stable real Player 2 through Player 4 controller ownership and network
  multiplayer remain incomplete.
- Lifecycle, storage-hygiene, and reproducible private-input build proof remain
  separate technical debt.
