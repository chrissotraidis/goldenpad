# Release checklist

GoldenPad 0.1.0 Preview 2 is the current coordinated release. It is a
developer preview, not an App Store/TestFlight release. `GoldenPad Legacy`
remains a fallback artifact and must not be presented as primary.

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
- [x] Preview 2 source has a first-launch in-app retail conversion flow with
  exact retail/output validation, common N64 byte-order normalization, atomic
  replacement, and preservation of a valid Preview 1 Documents ROM.
- [x] Obtain user approval to publish the exact Preview 2 build after in-place
  install, preserved-data readback, launch and hands-on review on iPhone/iPad.
  The full first-install and importer negative-path matrix remains open in
  `PREVIEW_2_ROM_IMPORT.md`.
- [ ] Remove the six disclosed anonymous `/private/tmp/goldenpad-recomp.*`
  compiler source literals from a future build. Preview 1 rejects `/Users/` and
  any unexpected temporary path; the six literals contain no ROM or user name.
- [ ] Accept stable multiplayer before advertising it as a feature.

Keep source publication, binary publication, signing and rights clearance as
separate decisions. Preview publication does not imply App Store or commercial
clearance.

## Coordinated Preview 2 update

This update is one reviewed source baseline with platform-appropriate
artifacts. It is not one universal package: iPhone/iPad use an `.ipa`, while
native Apple-Silicon macOS uses a separate `GoldenPad.app`.

- [x] Retain the hands-on-accepted iPhone/iPad single-player, touch and Player 1
  controller baseline.
- [x] Keep **Unlock all missions** off for every clean-install default.
- [x] Integrate and review the concurrent iPhone/iPad multiplayer compatibility
  work without overwriting its generated patches or physical-test evidence.
- [x] Preserve the exact physical four-player baseline that removed the former
  black/checkerboard corruption and disclosed the remaining slight lighting
  flicker.
- [x] Preserve the physically coherent multiplayer render candidate and keep
  multiplayer labeled experimental because residual flicker and real Player
  3/4 controller routing remain open.
- [x] Retain the current native arm64 Mac app as **GoldenPad Alpha**. Authentic
  gameplay launches, but mouse look remains slow, the far-right blue strip is
  unresolved, and Mac performance remains below the mobile builds.
- [x] Run the final mobile source/build/package verifiers after all concurrent
  changes have landed. Preview 2 IPA SHA-256:
  `704bdf68f67d1f0925fd1844ab865c263a79e105a6349ef410f365602e6c77e3`.
- [x] Audit the final `GoldenPad.app` separately for architecture, signing,
  dependencies, private paths and game data. Mac Alpha archive SHA-256:
  `7a9e7342b0ae39518f73807f854b479d9691fd612ae6861ea527f2a19e4450a4`.
- [x] Reconcile README, Status, Testing, Technical Debt, Worklog and release
  notes against the exact final artifacts before publishing.
- [x] Confirm local `main`, `origin/main` and GitHub's default branch match only
  after the reviewed source and both artifact records are complete.

Do not reopen Mac renderer/input surgery for this update. The current Mac alpha
is intentionally frozen with its disclosed limitations because the rejected
drawable-size and direct-camera experiments caused much larger regressions.

The remaining sections preserve the `GoldenPad Legacy` clean-checkout and
packaging procedure.

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
    dist/GoldenPad-0.1.0-preview.2-unsigned.ipa

  ./scripts/package-recomp-macos-alpha.sh
  ./scripts/verify-recomp-macos-alpha.sh \
    dist/GoldenPad-0.1.0-preview.2-macos-arm64-alpha.zip
  ```

- Keep the README's install table and limitations accurate.
- Keep repository visibility, source publication, and binary distribution as
  separate decisions.
- Do not publish an IPA until its exact file has passed the package audit.
- Do not describe the project as official, commercially licensed, App Store
  ready, or affiliated with any rights holder.
- Verify the merged PR state, clean worktree, and equality of local `main`,
  `origin/main`, and GitHub's default branch before handoff.
