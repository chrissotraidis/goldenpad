# Release checklist

GoldenPad 0.1.0 Preview 1 is the first public primary-runtime unsigned IPA.
It is a developer preview, not an App Store/TestFlight release. `GoldenPad
Legacy` remains a fallback artifact and must not be presented as primary.

## Primary RT64 preview gate

Preview 1 release record:

- [x] Physical iPhone/iPad single-player and controller baseline accepted.
- [x] iPhone/iPad touch editor supports move, resize, per-control opacity and
  reset; the accepted iPhone 14 layout is the clean-install phone default.
- [x] Clean installs default **Unlock all missions** to off.
- [x] `scripts/package-recomp-prototype-ipa.sh` strips signing/provisioning and
  stages the exact dependency licenses.
- [x] `scripts/verify-recomp-prototype-ipa.sh` extracts the IPA and rejects ROM,
  save, signing, private-user-path and legacy-core contamination.
- [x] Preview 1 IPA SHA-256:
  `a3aa37003a56a498820d07e84de89660d309c2cde40d0911fb3826086caca3e9`.
- [ ] Replace Finder-staged TLBFREE setup with an in-app retail conversion flow.
- [ ] Remove the six disclosed anonymous `/private/tmp/goldenpad-recomp.*`
  compiler source literals from a future build. Preview 1 rejects `/Users/` and
  any unexpected temporary path; the six literals contain no ROM or user name.
- [ ] Accept stable multiplayer before advertising it as a feature.

Keep source publication, binary publication, signing and rights clearance as
separate decisions. Preview publication does not imply App Store or commercial
clearance.

The remaining sections are the `GoldenPad Legacy` clean-checkout and packaging
procedure.

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

## Legacy repository and package

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

- Build and audit the primary preview with:

  ```sh
  ./scripts/package-recomp-prototype-ipa.sh
  ./scripts/verify-recomp-prototype-ipa.sh \
    dist/GoldenPad-0.1.0-preview.1-unsigned.ipa
  ```

- Keep the README's install table and limitations accurate.
- Keep repository visibility, source publication, and binary distribution as
  separate decisions.
- Do not publish an IPA until its exact file has passed the package audit.
- Do not describe the project as official, commercially licensed, App Store
  ready, or affiliated with any rights holder.
- Verify the merged PR state, clean worktree, and equality of local `main`,
  `origin/main`, and GitHub's default branch before handoff.
