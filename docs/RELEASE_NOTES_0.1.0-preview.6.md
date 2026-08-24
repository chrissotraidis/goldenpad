# GoldenPad 0.1.0 Preview 6

Preview 6 repairs the macOS menu-navigation regression reported after Preview
3, preserves Preview 5's accepted mobile controls and automatic-fire cadence,
and replaces the unreliable iPad utility menu with four independent touch
targets.

## What changed

- macOS menu screens again accept fluid WASD and trackpad/mouse navigation.
- macOS gameplay retains the Preview 3 relative mouse path, with a default
  sensitivity of `3.00` and a focused `1.30x` increase for ordinary on-foot
  turning. Shift Aim and tank sensitivity are unchanged.
- Holding Shift keeps the macOS Aim view where the player places it; the view
  recenters only after Shift is released.
- The iPhone/iPad utility overlay now owns four separate 48-point rows for
  Return to Main Menu, Settings, Edit Touch Controls, and Share Diagnostics &
  Logs.
- Preview 5's shared 1.1 through 1.4 mappings, native controller Aim, tank
  controls, controller sensitivity, and authentic automatic-fire repair are
  retained.

## Acceptance and verification

The user physically accepted macOS menu navigation, keyboard/mouse gameplay,
turning, and Shift Aim. On a physical iPad Pro, the user accepted the utility
menu both without and with a connected controller, then accepted controller
gameplay in Dam and Bunker with no observed control regression. These hands-on
checks do not prove every iPhone model, renderer path, long session, or open
crash report.

The complete input matrix, Preview 4 baseline guard, automatic-fire repair
gate, ROM-data audit, ARM64 builds, and both package verifiers pass. Two
independent packaging runs produced byte-identical archives.

## Downloads

- `GoldenPad-0.1.0-preview.6-unsigned.ipa`
  - SHA-256: `ced4d58bd8b54fd0dac4c7e9d892e22ea80f28d4bfa219fd586818dd62ba7266`
  - unsigned ARM64 app-content SHA-256: `0069201d9bcd8080778342342ec5e7da3a2aca6648c7f3ab7bb6eeae5229c941`
  - executable SHA-256: `2c5bb31906203d46a5b163c35b836185e3eacacd1a283faeb807435b104b3bde`
- `GoldenPad-0.1.0-preview.6-macos-arm64-alpha.zip`
  - SHA-256: `5189dcb5c7089f5ba45e7dbe17d67be9186148da20bce0c2c60e7156f78d71b8`
  - ad-hoc-signed ARM64 app-content SHA-256: `ab27557b23f95e5019b98dad7df82e6e9b808f40563643533a234cf53b874c53`
  - packaged executable SHA-256: `68cb1f0785a0dbde6adc2953dd7c16be5c725d7c863e1c5ec0bf027e8b7c96ca`

The IPA is intentionally unsigned. The Mac Alpha is ad-hoc signed, ARM64-only,
and not notarized. Neither archive contains a ROM, save, provisioning profile,
Apple signing identity, or generated source.

## Known limitations

- The A12X first-frame RT64/Metal crash in issue #9 and iPhone 13 mini shader
  initialization crash in issue #19 do not have confirmed Preview 6 repairs.
  Affected users should retry this exact build and attach the requested crash
  and diagnostic evidence if the failure remains.
- Known stage/effect rendering defects, including the Mac far-right edge issue,
  remain separate work.
- Local multiplayer controller ownership, lifecycle coverage, sustained
  performance, and network multiplayer remain incomplete.

Preview 6 advances the iPhone/iPad production bundle to version `0.1.0` build
`6`. The native Mac Alpha remains version `0.1.0` build `1` with its separate
bundle identity.
