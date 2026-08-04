# Release checklist

GoldenPad's current public deliverable is the source repository and its
reproducible ROM-free unsigned IPA recipe. No downloadable IPA, App Store build,
or TestFlight is advertised.

## Clean checkout

From a new directory on an Apple Silicon Mac with Xcode and CMake installed:

```sh
git clone https://github.com/chrissotraidis/goldenpad.git
cd goldenpad
git status --short
./scripts/verify-mgb64-ios-renderer.sh
```

The clone must fetch MGB64 at the documented commit, build the complete ARM64
Simulator and device apps, pass the linked game/Metal/audio checks, restore the
ignored upstream checkout to clean state, and leave tracked source unchanged.

## Repository and package

```sh
./scripts/check-no-rom-data.sh
./scripts/verify-source-license-manifest.sh
./scripts/package-unsigned-ipa.sh
./scripts/verify-unsigned-ipa.sh --game-core \
  dist/GoldenPad-0.1.0-unsigned.ipa
git diff --check
git status --short
```

Confirm that only ignored build products exist, every README/docs link resolves,
the app and IPA contain no ROM or extracted assets, and the package includes the
required third-party notices. Audit the exact staged paths before pushing.

## Physical iPad

Follow the signed-device command in `docs/BUILDING.md` with the developer's own
team and bundle identifier. Install through `devicectl`, import the supported
retail dump through Files, and complete the human acceptance matrix in
`docs/TESTING.md`.

Do not claim physical acceptance until a person has completed touch gameplay,
mission/save progression, controller assignment, a local multiplayer match,
speaker and route changes, background/foreground recovery, and first-install
plus warm performance checks on the target hardware.

## Publication

- Keep the README's install table and limitations accurate.
- Keep repository visibility, source publication, and binary distribution as
  separate decisions.
- Do not publish an IPA until its exact file has passed the package audit.
- Do not describe the project as official, commercially licensed, App Store
  ready, or affiliated with any rights holder.
- Verify the merged PR state, clean worktree, and equality of local `main`,
  `origin/main`, and GitHub's default branch before handoff.
