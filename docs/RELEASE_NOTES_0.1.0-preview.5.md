# GoldenPad 0.1.0 Preview 5

Preview 5 fixes automatic player and guard weapons firing too quickly at
GoldenPad's native 60 Hz simulation rate. It retains Preview 4's accepted shared
controls, native Aim, Runway/Streets tank behavior, controller sensitivity, ROM
import, saves, renderer, audio, touch layouts, and Mac controls.

## What changed

- Converts GoldenEye's positive automatic-fire intervals from original N64
  frame cost to GoldenPad's native simulation cadence by multiplying the one
  shared player/guard rate by three.
- Leaves zero and negative firing classifications unchanged, preserving
  semi-automatic weapons, first-shot behavior, bursts, damage, ammunition, and
  weapon selection.
- Keeps the repair inside GoldenEye's shared weapon-stat getter. There is no
  separate iPhone, iPad, or Mac interpretation and no duplicated player/guard
  policy.
- Adds generated-patch stale-pair checks and a deterministic regression gate
  covering positive automatic rates and unchanged nonpositive values.
- Retains the default-off bounded diagnostic used to compare Preview 4 and the
  candidate without writing game state.

## Physical acceptance

Preview 4's physical iPad baseline fired a 20-round Phantom magazine in 58
simulation ticks, normalized to 34.4828 shots per 100 ticks. Preview 5 recorded
12 shots in a 100-tick window, ammo 20 to 8. That is the exact expected result
for the converted interval including the immediate first shot.

The user normally launched the side-by-side test app and accepted navigation,
movement, controls, general gameplay, and runtime quality with no observed
regression. The session advanced through 13,723 display lists, VI updates, and
presentations with zero audio drops and zero underrun frames or callbacks.

No complete candidate guard window or explicit PP7 sequence was captured in
that physical session. Guards use the same patched getter as the player, while
the unchanged nonpositive semi-automatic path is verified at source and in the
deterministic gate; this is not represented as separate physical evidence.

## Downloads

### iPhone and iPad

`GoldenPad-0.1.0-preview.5-unsigned.ipa`

SHA-256:

```text
d4d6c6d7a00e79d1dd4759a97f3ae544c6112dff7c00ea9e57e21199a25c0db7
```

The IPA is unsigned and must be re-signed for the user's own device. Its sorted
unsigned app-content SHA-256 is
`4753f0814823aeecc545b5f33eea9d1bf2da0e7b93874e34ad5f6a0e8358981b`.
It contains no
ROM, save, provisioning profile, signing identity, generated source, or private
user path.

### Apple Silicon Mac Alpha

`GoldenPad-0.1.0-preview.5-macos-arm64-alpha.zip`

SHA-256:

```text
3dec5864aa637a7115f46a41fd81b8b2077ac44904bf48d7396c54c03a6faee2
```

The Mac archive contains a native arm64, ad-hoc-signed, non-notarized app. Its
sorted app-content SHA-256 is
`0221a39c5137dec3a923b1e5c80b30886f4604486a9c3f23eeb1bcedfeb0ed8a`.
Two independent packaging passes produced byte-identical mobile and Mac
artifacts, and both package verifiers passed.

## Build and rollback identity

- iPhone/iPad version `0.1.0`, build `5`; unsigned executable SHA-256
  `dff62592f42eede6d6865c12bb35ff97c6f548975d7c3903289f6d09fc462491`.
- Native Mac version `0.1.0`, build `1`; executable SHA-256
  `5960150d9eb668b814973045fdfe054240f7c9ef11ff2be9025957884c758bca`.
- Generated `patches.c` SHA-256
  `5e559e3a218c06cc54ead26f73a05f19f6095a542adbaeff664c19187f025217`.
- Generated `patches_bin.c` SHA-256
  `86113c9d63c92c5a1a7d394de32dd478042e50a9dece10085e93aba3f57ad52d`.

The automatic-fire repair is one independently revertible TD-01 commit on top
of the frozen Preview 4 baseline. Reverting it restores Preview 4 firing cadence
without removing Preview 4's accepted controls or tank repair.

## Known limitations

- Issue #17 remains open until its reporter verifies the retained Runway tank
  controls on Mac; Preview 5 does not reinterpret those accepted controls.
- Local multiplayer remains experimental. Slight lighting flicker and real
  Player 3 and Player 4 controller ownership remain open.
- Online and peer-to-peer multiplayer are not implemented.
- Intermittent audio static, screenshot/background lifecycle behavior, A12X
  compatibility issue #9, stage-specific rendering faults, and long-session
  performance remain tracked technical debt.
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
