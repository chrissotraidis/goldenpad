# Contributing to GoldenPad

GoldenPad welcomes focused fixes to its Apple platform integration, build
scripts, documentation, and legally clean upstream patches.

## Before opening a change

- Read `docs/LEGAL.md` and `docs/ARCHITECTURE.md`.
- Never commit or attach ROMs, extracted game assets, saves, leaked/XBLA
  material, certificates, provisioning profiles, private paths, or credentials.
- Keep MGB64 pinned. Put upstream checkouts and private inputs only under the
  ignored `ref/` area.
- Prefer the smallest change that preserves the shared portable core and thin
  Apple platform boundary.

## Verify the change

Run the checks relevant to your scope. For the primary AOT/RT64 runtime, the
public ROM-free host and renderer checks are:

```sh
./scripts/verify-recomp-prototype-host.sh
./scripts/verify-rt64-ios-static.sh
./scripts/check-no-rom-data.sh
```

A game-bearing mobile build additionally requires the private generated AOT
inputs documented in `docs/BUILDING.md`. After building it, package and audit
the exact artifact:

```sh
./scripts/package-recomp-prototype-ipa.sh
./scripts/verify-recomp-prototype-ipa.sh \
  dist/GoldenPad-0.1.0-preview.3-unsigned.ipa
```

For the native Mac Alpha, use
`scripts/build-recomp-macos-dependencies.sh`,
`scripts/package-recomp-macos-alpha.sh`, and
`scripts/verify-recomp-macos-alpha.sh`.

The following checks are for `GoldenPad Legacy` only; they do not prove the
primary Preview 3 runtime:

```sh
./scripts/verify-mgb64-ios-renderer.sh
./scripts/verify-source-license-manifest.sh
./scripts/package-unsigned-ipa.sh
./scripts/verify-unsigned-ipa.sh --game-core \
  dist/GoldenPad-0.1.0-unsigned.ipa
./scripts/check-no-rom-data.sh
```

Meaningful mobile changes must be exercised sequentially: iPhone Simulator
first, shut it down, then iPad Simulator. Physical-device claims require a
signed build and direct human testing; automation and Simulator evidence do not
substitute for touch feel, controller feel, audio routes, thermals, or mission
and multiplayer completion.

## Pull requests

Explain the user-visible result, why the change is needed, which exact checks
passed, and which acceptance gates remain open. Do not include copyrighted game
screenshots or private runtime logs.
