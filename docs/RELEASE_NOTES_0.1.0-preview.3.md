# GoldenPad 0.1.0 Preview 3

Preview 3 is the accepted controls update for iPhone, iPad, and Apple Silicon
Mac. It stays on Preview 2's accepted game, save, audio, and RT64/Metal
rendering foundation while improving how players configure and use controls.

## Highlights

- Adds an opt-in **Sidestep with left/right** movement adapter for touch and
  connected controllers during live single-player gameplay with GoldenEye's
  1.1 Honey control style. Preview 2 movement remains the default, Original N64
  C-button mode remains available, and menus plus experimental multiplayer keep
  their established mappings.
- Rewrites first-run and invalid-ROM setup copy in plain language. GoldenPad no
  longer exposes the internal `GoldenEye_TLBFREE.z64` filename or implies that
  the user's original file will be replaced.
- Promotes the hands-on-accepted Mac control pass: WASD movement, relative mouse
  look, left mouse Fire, right mouse Action, middle click or wheel weapon
  cycling, Shift Aim, E Action, Q next weapon, R reload, C crouch, 1–9/0 owned
  inventory selection, Escape pause, and Delete pointer release. Space is
  unassigned.
- Retains the accepted Preview 2 single-player, save/preferences, touch-layout,
  Player 1 controller, in-app retail-ROM conversion, and experimental
  split-screen rendering baselines.

## Downloads

### iPhone and iPad

`GoldenPad-0.1.0-preview.3-unsigned.ipa`

SHA-256:

```text
ef2ab9575d5a9df5d7d8d4138caa789625be3407ebc796a4d9339ea1fe6ba777
```

The 18-member IPA is unsigned and must be re-signed for your own device. Its
sorted unsigned app-content SHA-256 is
`956e805d2575167b1045c7c5769f22f55d933e5a60c4a6283bfe30fedc1e5ab0`.
It contains no ROM, save, provisioning profile, or signing identity.

### Apple Silicon Mac Alpha

`GoldenPad-0.1.0-preview.3-macos-arm64-alpha.zip`

SHA-256:

```text
819bc8eabc1fc84d2a37c1847f68c8832c023f0b0643851ca3f6251244fc32ba
```

The 20-member Mac archive contains a native arm64, ad-hoc-signed, non-notarized
app. Its sorted app-content SHA-256 is
`e15c17528a72881e3062504c2abc82a0a57bf0d039feb8240cbaf03b5db4f941`.
The thin far-right blue render edge remains known technical debt.

## Acceptance record

- The user declared the final Preview 3 iPhone/iPad and Mac behavior stable for
  publication, with no newly observed major regression.
- The final signed mobile executable SHA-256 is
  `6ad969b56b6358e8c2731f97063b3d0dccf28674fdb4939216a289a330d8a72e`.
  Build `3` was installed in place on the attached iPad; both ROM copies, the
  active save, backup save, and the latest preferences remained byte-identical.
  The resulting session passed ROM validation and entered the GoldenEye loop.
- The accepted Mac executable SHA-256 is
  `a6352c5179ff5822f4af3d1b20e1b02bf0d5d1af46b453c9bceca435b7e59808`.
- Two independent packaging runs produced byte-identical mobile and Mac release
  archives, and both repository package verifiers passed.

## Known limitations

- Local multiplayer remains experimental. Slight lighting flicker and real
  Player 3/4 controller ownership remain open.
- Online and peer-to-peer multiplayer are not implemented.
- Native-60-Hz automatic-fire authenticity, intermittent audio static,
  screenshot/background lifecycle behavior, A12X compatibility issue #9, and
  stage-specific rendering faults remain documented technical debt.
- The Mac Alpha retains the thin far-right blue edge and still needs broader
  long-session performance coverage.
- The new sidestep adapter is opt-in. Public issue #8 should remain open until
  the reporter confirms touch and controller behavior on their setup.

## Data and rights boundary

GoldenPad does not include, download, or redistribute GoldenEye 007, a ROM,
extracted retail assets, or saves. Users must supply their own supported
original retail dump. This is a source-available developer preview and is not
official, commercially licensed, App Store-cleared, or affiliated with
Nintendo, Rare, or MGM.

GoldenPad builds on GoldenEye64Recomp, N64Recomp, N64ModernRuntime, RT64, and
their contributors. See the repository's source-license manifest, third-party
notices, and legal policy for exact provenance and redistribution boundaries.
