# GoldenPad 0.1.0 Preview 1

GoldenPad's first public developer preview promotes the statically recompiled
GoldenEye + N64ModernRuntime + RT64/Metal runtime to the primary iPhone/iPad
build. The earlier MGB64/Fast3D app remains `GoldenPad Legacy` for comparison.

## Included

- Native Apple ARM64 game runtime with RT64's Metal renderer.
- Automatic high resolution, Native N64 and 2x modes, optional 2x MSAA, and
  N64 three-point filtering.
- Physically accepted Xbox/MFi Player 1 controls and editable touch controls.
- Separate iPhone/iPad layouts with drag, size, opacity and reset controls.
- The accepted iPhone 14 layout is the clean-install phone default.
- Native audio, persistent EEP4K saves, diagnostics, and return to main menu.
- Clean installs default **Unlock all missions** to **Off**.

## Installation

The release asset is an unsigned IPA for iOS/iPadOS 17 or later. Re-sign it
with your own Apple development identity or trusted sideloading workflow.

No ROM, save, extracted retail asset, provisioning profile, or signing identity
is included. Preview 1 expects a compatible, user-derived
`GoldenEye_TLBFREE.z64` in the app's Documents folder; copy it with Finder file
sharing after installation. There is no in-app retail-ROM conversion flow yet.

## Known limitations

- Multiplayer is experimental and unstable. Split-screen flashing and match
  instability remain open; single-player is the supported Preview 1 path.
- Occasional audio static and stage-specific geometry issues remain under
  investigation.
- Graphics setting changes apply after fully quitting and reopening GoldenPad.
- This is an unofficial source-available developer preview. No official,
  commercial, App Store, or rights-holder affiliation/clearance is claimed.

## Verification

- Signed device executable SHA-256:
  `c0aee770a84482ee73e26042774ffd4119a09c73df20ff985327fc8ca08bea6f`
- Unsigned IPA SHA-256:
  `a3aa37003a56a498820d07e84de89660d309c2cde40d0911fb3826086caca3e9`
- Unsigned app-content SHA-256:
  `33c590f8d3f849614dacb267972b2a7e65b69a544b3744a7b7624825a80b5cb8`

The package verifier extracted 17 members and confirmed ARM64 primary-runtime
symbols, file sharing, dependency licenses, and the absence of ROM/save/signing
members, known N64 ROM headers, private user paths, and legacy MGB64 symbols.
