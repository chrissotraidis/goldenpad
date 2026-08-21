# GoldenPad 0.1.0 Preview 2

Preview 2 is the first coordinated GoldenPad update for iPhone, iPad and Apple
Silicon Mac. The iOS/iPadOS build remains the primary experience. The Mac build
is a separate Alpha artifact with explicitly lower acceptance.

## Highlights

- Import your own original NTSC-U GoldenEye 007 retail dump from Files on first
  launch. GoldenPad accepts `.z64`, `.v64`, `.n64` and `.rom` byte orders,
  validates the exact revision, converts it privately on device and never adds
  game data to the app or repository.
- Tuned, editable iPhone and iPad touch layouts with drag, resize, per-control
  opacity, reset, separate persisted profiles and accepted iPhone defaults.
- Xbox/MFi Player 1 controls, remappable action buttons and automatic touch
  overlay hiding when a controller is active.
- Native N64, 2x and automatic high-resolution rendering, 2x MSAA and N64
  three-point filtering through RT64 Metal.
- A frozen experimental local-multiplayer render repair that removes the former
  large black/checkerboard split-screen corruption on physical iPad.
- Official GoldenPad project support for Apple Silicon macOS in Alpha status,
  distributed as a separate native arm64 `GoldenPad.app` with the same app icon
  and native Mac menus for settings and diagnostics.

## Downloads

### iPhone and iPad

`GoldenPad-0.1.0-preview.2-unsigned.ipa`

SHA-256:

```text
704bdf68f67d1f0925fd1844ab865c263a79e105a6349ef410f365602e6c77e3
```

The IPA is unsigned and must be re-signed for your own device. It contains no
ROM, save, provisioning profile or signing identity.

### Apple Silicon Mac Alpha

`GoldenPad-0.1.0-preview.2-macos-arm64-alpha.zip`

SHA-256:

```text
7a9e7342b0ae39518f73807f854b479d9691fd612ae6861ea527f2a19e4450a4
```

The Mac app is arm64, ad-hoc signed and not notarized. It is a separate Alpha,
not a Catalyst build and not mobile-quality parity.

## Known limitations

- Local multiplayer remains experimental. Slight lighting flicker and real
  Player 3/4 controller routing remain open even though the former large
  split-screen corruption is repaired in the frozen baseline.
- The Mac Alpha has slow mouse tuning, a thin blue strip at the far-right render
  edge and lower sustained-performance confidence than the mobile builds.
- Screenshot/background resume has previously frozen gameplay and still needs
  a dedicated physical lifecycle pass.
- Occasional audio static and stage-specific geometry faults remain open.
- The generated AOT input pipeline is private and intentionally untracked, so
  the complete primary runtime cannot be reproduced from the public checkout
  alone.

## Data and rights boundary

GoldenPad does not include, download or redistribute GoldenEye 007, a ROM,
extracted retail assets or saves. Users must supply their own supported original
retail dump. This is a source-available developer preview and is not official,
commercially licensed, App Store-cleared or affiliated with Nintendo, Rare or
MGM.

GoldenPad builds on the work of the GoldenEye decompilation community,
GoldenEye64Recomp, N64Recomp, N64ModernRuntime, RT64 and their contributors.
See the repository's source-license manifest, third-party notices and legal
policy for exact provenance and redistribution boundaries.
