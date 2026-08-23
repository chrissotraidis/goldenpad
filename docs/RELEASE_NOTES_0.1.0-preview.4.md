# GoldenPad 0.1.0 Preview 4

Preview 4 repairs the shared GoldenEye controller path and the mission tank
controls reported in issue #17. It keeps Preview 3's ROM import, saves, audio,
renderer, touch layouts, Mac keyboard and mouse commands, and experimental
multiplayer rendering boundaries.

## Highlights

- Uses one shared controller mapping on iPhone, iPad, and Apple Silicon Mac.
  GoldenPad reads GoldenEye's active 1.1 Honey, 1.2 Solitaire, 1.3 Kissy, or
  1.4 Goodnight style instead of applying a separate platform interpretation.
- Preserves raw controller input outside live gameplay so the title screen,
  mission menus, watch, and controller connection path do not inherit tank or
  modern-look translation.
- Restores GoldenEye's native manual-sight behavior while Aim is held: Bond is
  stationary, the left stick moves the weapon and reticle, and the right stick
  is neutral until Aim is released.
- Repairs the player-enterable tank used by Runway and Streets. The left stick
  owns drive and hull turning, the right stick owns turret aim after the native
  hatch/start transition, and Fire operates only the currently selected weapon.
  GoldenEye's authentic mounted weapon cycling remains available, including
  ordinary weapons and Tank Shells.
- Raises absolute external-controller right-stick response by the requested
  final 20 percent, from 1.56 to 1.872 degrees per frame at full deflection.
  Touch, mouse, native manual Aim, left-stick movement, and menus are unchanged.
- Removes the obsolete separate movement-adapter setting. The active GoldenEye
  control style is now reported automatically in Settings and diagnostics.

## Downloads

### iPhone and iPad

`GoldenPad-0.1.0-preview.4-unsigned.ipa`

SHA-256:

```text
ff163b0af6b54596590da8e39cbaff0b388b69f1607ca34f62ce61e7fe144130
```

The 18-member IPA is unsigned and must be re-signed for the user's own device.
Its sorted unsigned app-content SHA-256 is
`1ec161604af996f30bb3ac1e9c347f7c905623675ca32adf8d2c35a069c6a13c`.
It contains no ROM, save, provisioning profile, signing identity, or private
user path.

### Apple Silicon Mac Alpha

`GoldenPad-0.1.0-preview.4-macos-arm64-alpha.zip`

SHA-256:

```text
63bec02ad6e323a213f9cb9d15f763a58d6eb7bd4a1a40af6341a4fb8fb333ba
```

The 20-member Mac archive contains a native arm64, ad-hoc-signed,
non-notarized app. Its sorted app-content SHA-256 is
`d2d0824047061b81ad3ef1b2fd2fd61fde09fc759176b782209c41279217a341`.

## Acceptance record

- On physical iPad, the user accepted menu navigation, ordinary movement and
  right-stick look, left-trigger manual Aim, Runway tank entry, drive, hull
  turn, turret control, weapon cycling, KF7 and Tank Shell firing, exit and
  re-entry, return to title, and a later Facility regression pass.
- That accepted signed test executable has SHA-256
  `2b31f8868885712fbad34cef1aea20b1dee48f59fc9d930cbd3fa8b8e82b6b12`
  and used the 1.56-degree controller-look baseline.
- The final 1.872-degree public executable is version `0.1.0` build `4` and has SHA-256
  `d83361f4daa70014b378aed20b9e26dc7c787d77b0fcd000816d536aecc8e66b`.
  It incorporates the user's requested 20 percent response increase and passed
  the shared input matrix, complete device build, symbol audit, and package
  audit. This exact unsigned release executable was not installed for a second
  physical pass before publication.
- The native Mac target compiled and its archive passed architecture, signing,
  dependency, symbol, license, private-path, and game-data audits. Issue #17
  remains open because build/package proof does not replace reporter gameplay
  verification on Mac.
- The tracked modern-controls source patch matches the ignored build input.
  Both generated patch halves were rebuilt together. Their SHA-256 values are
  `4a829165889a4e736199841c4c4237ee6a03ed97fa1ce6d891dfc864634862ff`
  for `patches.c` and
  `cb3e439a8eb1587ac11b7fa29551b3f204860f993b9114ebd5331c179bc92bc6`
  for `patches_bin.c`.

## Known limitations

- Issue #17 remains open until the reporter confirms Runway tank controls on
  the Preview 4 Mac Alpha and provides diagnostics if a problem remains.
- Local multiplayer remains experimental. Slight lighting flicker and real
  Player 3 and Player 4 controller ownership remain open.
- Online and peer-to-peer multiplayer are not implemented.
- Native-60-Hz automatic-fire authenticity, intermittent audio static,
  screenshot/background lifecycle behavior, A12X compatibility issue #9,
  stage-specific rendering faults, and long-session performance remain tracked
  technical debt.
- The Mac Alpha retains the thin far-right blue edge and is not notarized.

## Data and rights boundary

GoldenPad does not include, download, or redistribute GoldenEye 007, a ROM,
extracted retail assets, or saves. Users must supply their own supported
original retail dump. This is a source-available developer preview and is not
official, commercially licensed, App Store-cleared, or affiliated with
Nintendo, Rare, or MGM.

GoldenPad builds on GoldenEye64Recomp, N64Recomp, N64ModernRuntime, RT64, and
their contributors. See the source-license manifest, third-party notices, and
legal policy for exact provenance and redistribution boundaries.
