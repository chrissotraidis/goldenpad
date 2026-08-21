# GoldenPad

<p align="center">
  <img src="Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" width="144" alt="GoldenPad app icon">
</p>

<p align="center">
  <strong>GoldenEye 007, rebuilt as a native app for iPhone and iPad.</strong><br>
  Apple ARM64 game code, Metal rendering, user-supplied retail data, touch
  controls, game controllers, saves, audio, and local multiplayer foundations.
</p>

<p align="center">
  <img alt="iOS and iPadOS 17 or later" src="https://img.shields.io/badge/iOS%20%2F%20iPadOS-17%2B-0A84FF?logo=apple">
  <img alt="Metal renderer" src="https://img.shields.io/badge/renderer-Metal-5E5CE6">
  <img alt="Native ARM64" src="https://img.shields.io/badge/runtime-native%20ARM64-30D158">
  <img alt="Developer preview" src="https://img.shields.io/badge/status-developer%20preview-FF9F0A">
  <img alt="ROM not included" src="https://img.shields.io/badge/game%20data-not%20included-FF453A">
</p>

<p align="center">
  <img src="docs/images/goldenpad-rt64-jungle-ipad.jpg" width="960" alt="GoldenPad RT64 gameplay on a physical iPad in the Jungle mission">
</p>
<p align="center"><em>Native RT64/Metal gameplay on a physical iPad Pro.</em></p>

GoldenPad's primary iPhone/iPad runtime uses statically recompiled GoldenEye 007
code, N64ModernRuntime and RT64's Metal renderer. It is not a general Nintendo
64 emulator and it does not contain the game, a ROM, or extracted game assets.
The supported retail data remains user-supplied and private.

The primary RT64 build reaches the original title sequence, menus and multiple
missions on a physical iPad with native audio, the tuned GoldenPad touch layout
and Xbox/MFi controller support. The earlier MGB64/Fast3D app is retained as
`GoldenPad Legacy` for regression comparison and fallback only; it is no longer
the primary development version.

> **Development boundary:** the public repository records the integration and
> reproducible patch chain, but generated AOT game code and retail-derived data
> remain private and are never committed or distributed.

## Current screenshots

<table>
  <tr>
    <td width="50%"><img src="docs/images/goldenpad-rt64-bunker-ipad.jpg" alt="GoldenPad RT64 gameplay in Bunker on a physical iPad"></td>
    <td width="50%"><img src="docs/images/goldenpad-rt64-bunker-action-ipad.jpg" alt="GoldenPad RT64 combat in Bunker on a physical iPad"></td>
  </tr>
  <tr>
    <td align="center"><strong>Bunker</strong><br>Automatic high resolution with RT64 Metal.</td>
    <td align="center"><strong>Live gameplay</strong><br>Native ARM64 game code and controller input.</td>
  </tr>
  <tr>
    <td colspan="2"><img src="docs/images/goldenpad-rt64-file-select-ipad.jpg" alt="GoldenEye file-select menu rendered by GoldenPad on a physical iPad"></td>
  </tr>
  <tr>
    <td colspan="2" align="center"><strong>Original front end</strong><br>GoldenEye menus, saves, missions, and gameplay run in the primary RT64 build.</td>
  </tr>
</table>

These user-approved captures were taken from the signed GoldenPad build on a
physical iPad. No ROM, save, extracted asset file, or game data is included in
the repository or application package.

## Install status

| Option | Status | What to do |
|---|---|---|
| Local Simulator build | **Verified** | Build with the complete verifier below, then run from Xcode or `simctl`. |
| Local iPhone/iPad build | **Builds for ARM64** | Follow the opt-in signed-device workflow in [Building](docs/BUILDING.md#signed-physical-device-build). |
| Unsigned `.ipa` | **Buildable locally** | Run `scripts/package-unsigned-ipa.sh`, then re-sign the result for your own device. |
| GitHub release | **Not published** | No downloadable GoldenPad IPA is currently advertised. |
| App Store / TestFlight | **Not announced** | Store distribution requires separate rights, signing, review, and device acceptance. |

Simulator gameplay and UI are extensively exercised. A final signed physical
iPhone/iPad pass is still required for touch feel, sustained performance,
speaker and route behavior, controller hardware, thermals, and lifecycle
acceptance. The developer preview should not be described as an App Store-ready
release.

## What works

| Area | Current result |
|---|---|
| Native runtime | Statically recompiled game code runs as Apple ARM64; no JIT or emulator wrapper |
| Rendering | RT64 presents high-resolution Metal output on physical iPad hardware |
| Setup | The private developer build validates a user-derived NTSC-U TLBFREE input staged only in its app container; a public in-app retail-ROM import/conversion flow remains a release gate |
| Gameplay | Original front end and live Dam/Facility gameplay render and accept normal input |
| Touch | Tuned GoldenPad move and relative-look zones plus aim, fire, action, weapon, duck, and Start controls |
| Customization | Touch look sensitivity, hold/toggle aim, shared vertical inversion and optional centered reticle |
| Controllers | `GCController` with accepted Player 1 movement, right-stick look, buttons, and automatic touch-overlay hiding |
| Multiplayer | Opt-in physical-controller Player 1 + touch Player 2 test path; the crash repair is under test and flashing split-screen presentation remains work in progress |
| Audio | Native game PCM feeds `AVAudioEngine` through a bounded stereo ring |
| Saves | GoldenEye's 512-byte EEP4K active and backup files persist in Application Support |
| Display | Native N64, 2× and automatic high-resolution modes, 2× MSAA and N64 three-point filtering |
| Legacy fallback | MGB64/Fast3D remains buildable as `GoldenPad Legacy` |

See [Status](docs/STATUS.md) and [Testing](docs/TESTING.md) for the evidence
ledger and remaining physical-device gates. [Technical debt and upstream
watch](docs/TECH_DEBT.md) records when decompilation, MGB64, and renderer changes
are safe to evaluate or adopt.

## Supported game

| Game | Retail revision | Status |
|---|---|---|
| **GoldenEye 007** | Original US Nintendo 64 release | Supported after exact validation |
| Other regions or revisions | Any other dump | Rejected; not interchangeable with the supported build |
| GoldenEye XBLA | Leaked/unreleased Xbox 360 build | Prohibited and never used |

GoldenPad is a native integration of reconstructed N64 game code, not a general
emulator. Another N64 game or GoldenEye revision cannot be substituted.

## Get started

You need:

- an Apple Silicon Mac with Xcode and its command-line tools;
- [Homebrew](https://brew.sh), CMake 3.28 or newer, and Git;
- an Apple development team for a signed physical-device build; and
- your own legally acquired supported US retail GoldenEye 007 N64 dump.

Install CMake, then clone the repository:

```sh
brew install cmake
git clone https://github.com/chrissotraidis/goldenpad.git
cd goldenpad
```

For Simulator development and the reproducible unsigned device app, build the
complete native game/Metal closure:

```sh
./scripts/verify-mgb64-ios-renderer.sh
```

The verifier fetches the exact pinned MGB64 source, applies GoldenPad's narrow
mobile patches temporarily, builds Release apps for Simulator and device, checks
the linked game/Metal/audio symbols, rejects desktop renderer dependencies, and
leaves the upstream checkout clean.

The resulting apps are written to:

```text
build-mgb64-renderer-simulator/Release-iphonesimulator/GoldenPad.app
build-mgb64-renderer-device/Release-iphoneos/GoldenPad.app
```

For a physical iPad, add your Apple ID under **Xcode → Settings → Accounts**,
connect and trust the iPad, then use your 10-character team ID and a bundle
identifier owned by that team:

```sh
GOLDENPAD_DEVELOPMENT_TEAM=ABCDE12345 \
GOLDENPAD_BUNDLE_IDENTIFIER=com.yourname.goldenpad \
  ./scripts/verify-mgb64-ios-renderer.sh

xcrun devicectl list devices
xcrun devicectl device install app \
  --device YOUR_DEVICE_ID \
  build-mgb64-renderer-device-signed/Release-iphoneos/GoldenPad.app
```

The signed build stays separate from the reproducible unsigned app. If Xcode
has not yet created an Apple Development certificate, use **Manage
Certificates** in the Accounts panel first. See [Building](docs/BUILDING.md)
for signing diagnostics, Simulator destinations, and the maintained RT64
reference path.

## First launch

GoldenPad never downloads or bundles game data.

1. Launch GoldenPad.
2. Select **Select retail ROM**.
3. Choose your supported `.z64`, `.v64`, `.n64`, or `.rom` file in Files.
4. Wait for exact size, header, title, byte-order, and SHA-1 validation.
5. The setup shell yields to the original game once the private runtime handoff
   and native scheduler are ready.

The source file is not copied into the app bundle, IPA, repository, or a
publishable cache. GoldenPad closes the Files security scope after validation
and keeps normalized retail bytes in core-owned volatile memory.

## Touch controls

GoldenPad defaults to a modern dual-stick FPS layout:

| Control | Behavior |
|---|---|
| **MOVE** | Large left virtual stick |
| **LOOK** | Relative right-thumb swipe region; movement stops when the swipe stops |
| **FIRE** | N64 Z / primary fire |
| **AIM** | N64 R; Toggle by default, with Hold available |
| **ACTION** | Contextual N64 B for doors, use, and reload |
| **WEAPON** | N64 A weapon cycle / confirm |
| **DUCK** | C-down crouch |
| **PAUSE** | Start / watch and menus |

Open the persistent gear button and choose **Touch Controls** to adjust:

- look sensitivity;
- Toggle or Hold aim behavior;
- gyroscope aiming;
- overlay opacity and global control size;
- controller auto-hide; and
- the separate iPhone or iPad touch layout.

Choose **Edit touch layout**, tap a control, and drag it to a comfortable
position. The selected control can be resized from 70–150% and hidden or shown;
MOVE cannot be hidden. **Reset** restores the selected device class and preset
to its defaults. Only changed placements are stored, so phone, tablet, Modern,
Southpaw, and N64 layouts remain independent.

The revised phone defaults keep WEAPON/DUCK above the home-indicator strip and
the action rail clear of rounded edges. LOOK accumulates every swipe delta until
the renderer samples it, preventing fast movement from being silently dropped.
These fixes are Simulator-verified; final sensitivity and placement still need
real-finger acceptance on physical hardware.

## Controllers and multiplayer

The primary build automatically uses the first Xbox/MFi extended gamepad for
Player 1 and hides the touch overlay while it is connected. Movement, modern
right-stick look, aim, fire, action, weapon, crouch and Start are physically
accepted. **Settings → Controller → Button mapping** can reassign the face
buttons, bumpers, and triggers; sticks, D-pad, and Menu/Start retain their
standard roles. For hardware-limited testing, **Cheats & Testing → Two-player input
test** keeps the attached controller as Player 1 and exposes touch controls as
Player 2. Turning it off hides touch and keeps the controller as Player 1. The
former multiplayer process crash has a targeted repair, but the Simulator
viewports have shown visible flashing. A complete, visually stable,
human-played mobile match remains an acceptance gate.

## Resolution and performance

Open the three-dot menu and choose **Settings** to select Native N64, 2× or
Automatic high resolution, plus 2× MSAA and N64 three-point filtering. These
settings are saved immediately and apply after quitting and reopening GoldenPad;
the active RT64 session is not rebuilt in place. They alter how the original
ROM assets are rendered; no HD texture pack is bundled. To restore the original
N64 look, select Native N64, disable both 2× anti-aliasing and three-point
filtering, then fully quit and reopen the app.

## Reproducible and ROM-free

The primary integration, dependency pins and reversible patches are public.
Retail data, converted ROM derivatives and generated AOT game sources remain
private and ignored. The ARM64 host and RT64 archive closure have ROM-free
verification scripts, while the complete playable app requires the developer's
private generated inputs. The older MGB64 unsigned-IPA workflow is retained for
legacy fallback builds and must not be presented as the primary release path.

## Current limitations

- Screenshot/system-overlay resume is under renewed physical-iPad validation.
- Human touch-only mission completion and human-completed local multiplayer
  remain open.
- The primary AOT build does not yet provide an end-user retail-ROM
  import/conversion flow; current playable builds use private developer-staged
  inputs and must not distribute ROM or generated retail-derived data.
- Some stage-specific geometry glitches remain to be captured precisely.
- Physical-speaker static and multi-controller play remain acceptance gates.
- The generated-input pipeline is not independently reproducible from the
  public repository; private retail-derived inputs are never distributed.
- This source-available developer preview is not an official or commercially
  licensed GoldenEye distribution.

## Frequently asked questions

<details>
<summary><strong>Does this repository contain GoldenEye 007?</strong></summary>

No. It contains mobile integration code, maintained patches, build scripts, and
documentation. You must supply your own legally acquired supported retail dump.
Do not open issues requesting game data or download links.
</details>

<details>
<summary><strong>Is GoldenPad an N64 emulator?</strong></summary>

No. Statically recompiled GoldenEye code runs as a native Apple ARM64
application, and RT64 renders through Metal. The separate MGB64/Fast3D app is
retained only as the deprecated legacy fallback.
</details>

<details>
<summary><strong>Where is the IPA?</strong></summary>

There is no advertised public primary-runtime release asset yet. The repository
can reproduce a ROM-free unsigned `GoldenPad Legacy` IPA, but the current RT64
primary app still depends on private generated AOT inputs and a developer-staged
retail-derived ROM. A distributable, data-free primary package and end-user
import flow remain release gates.
</details>

<details>
<summary><strong>Do the high-resolution settings make the game run faster?</strong></summary>

No. Native N64, 2× and Automatic high resolution change render quality, not game
speed. Higher internal resolution and 2× anti-aliasing can cost performance;
changes apply after fully quitting and reopening GoldenPad.
</details>

<details>
<summary><strong>Is this legally cleared for the App Store?</strong></summary>

No claim of official, commercial, or App Store clearance is made. User-supplied
retail data keeps ROM media out of the repository and IPA, but it does not erase
the separate rights questions around reconstructed game code. Read the
[Legal and provenance policy](docs/LEGAL.md).
</details>

<details>
<summary><strong>What is the licensing status?</strong></summary>

GoldenPad is source-available, but this repository currently has no top-level
outbound license grant. MGB64-authored port code and third-party libraries keep
their respective licenses; reconstructed original-game code remains subject to
the rights boundary described in [Source licenses](docs/SOURCE_LICENSES.md) and
[Legal](docs/LEGAL.md). Do not infer commercial or redistribution rights from
the repository being publicly readable.
</details>

## Project map

| Path | Purpose |
|---|---|
| [`Sources/`](Sources/) | Native SwiftUI, Metal host, input, audio/save services, and ROM validation |
| [`Support/RecompPrototype/`](Support/RecompPrototype/) | Primary AOT runtime, RT64, diagnostics and Apple bridges |
| [`Support/MGB64/`](Support/MGB64/) | Deprecated legacy fallback adapters |
| [`patches/`](patches/) | Maintained, reversible recomp, RT64 and legacy changes |
| [`scripts/`](scripts/) | Fetch, build, test, audit, and unsigned-IPA packaging gates |
| [`docs/PLAN.md`](docs/PLAN.md) | Milestones and definition-of-done gates |
| [`docs/STATUS.md`](docs/STATUS.md) | Current evidence and remaining work |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Portable core and thin Apple platform design |
| [`docs/RESEARCH.md`](docs/RESEARCH.md) | Pinned upstreams and production-core decision |
| [`docs/BUILDING.md`](docs/BUILDING.md) | Full local build and signing workflow |
| [`docs/TESTING.md`](docs/TESTING.md) | Reproducible verification procedures and hashes |
| [`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md) | Clean-checkout, package, signing, and publication gates |
| [`docs/LEGAL.md`](docs/LEGAL.md) | ROM, source, licensing, and distribution boundary |
| [`docs/ART.md`](docs/ART.md) | Original app-icon provenance |
| [`docs/WORKLOG.md`](docs/WORKLOG.md) | Chronological production log |

Generated source trees, build directories, ROMs, saves, signing material, and
release artifacts are ignored and must never be committed.

## Contributing and support

Read [Contributing](CONTRIBUTING.md) before proposing a change and
[Security](SECURITY.md) before reporting a vulnerability. Reproducible platform
or gameplay defects can be filed through
[GitHub Issues](https://github.com/chrissotraidis/goldenpad/issues). Never attach,
request, or link to ROMs, extracted assets, leaked builds, saves containing
private data, signing identities, or provisioning profiles.

## Legal and acknowledgements

GoldenPad is an unofficial preservation and research project. It is not
affiliated with or endorsed by Nintendo, Rare, Microsoft, MGM, Danjaq, EON
Productions, or any other rights holder. GoldenEye 007 and all related names,
characters, imagery, and game content belong to their respective owners.

GoldenPad builds on GoldenEye64Recomp, N64Recomp, N64ModernRuntime, RT64, MGB64,
the GoldenEye decompilation community, Metal support work, and their
contributors. Each upstream component retains its own copyright and license.
No ROM, extracted game media, leaked XBLA material, or proprietary
matching-target SDK implementation source is included here.
