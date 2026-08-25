# Release checklist

GoldenPad 0.1.0 Preview 6 is the current coordinated release. It is a
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
- [ ] Give the runtime-managed Application Support ROM copy the same explicit
  backup-exclusion and file-protection policy as the Documents copy, then prove
  both copies, saves, and preferences byte-identical across an in-place update.
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
- [x] Publish `v0.1.0-preview.2` as a GitHub prerelease, download all four
  hosted assets, verify both checksum manifests, and rerun both package audits
  against the hosted archives.

Do not reopen Mac renderer/input surgery for this update. The current Mac alpha
is intentionally frozen with its disclosed limitations because the rejected
drawable-size and direct-camera experiments caused much larger regressions.

## Coordinated Preview 3 controls update

- [x] Start from the published Preview 2 source baseline and keep renderer,
  ROM conversion, save, audio, and experimental split-screen repairs unchanged.
- [x] Add opt-in Honey sidestep semantics without changing the default Preview 2
  movement mode, menus, Original N64 C-button mode, or multiplayer fallback.
- [x] Obtain hands-on acceptance of the exact Mac C/R/Escape/Delete/mouse/
  wheel/number-key control build while retaining the known thin blue edge.
- [x] Rebuild signed mobile build `3` with the revised first-run/invalid-ROM
  copy, install it in place on iPad, launch the GoldenEye loop, and prove both
  ROMs, both saves, and the latest preferences byte-identical.
- [x] Package the 18-member unsigned IPA twice with identical SHA-256
  `ef2ab9575d5a9df5d7d8d4138caa789625be3407ebc796a4d9339ea1fe6ba777`.
- [x] Package the accepted 20-member Mac Alpha twice with identical SHA-256
  `819bc8eabc1fc84d2a37c1847f68c8832c023f0b0643851ca3f6251244fc32ba`.
- [x] Keep issue #8 open for reporter verification, multiplayer experimental,
  online multiplayer unimplemented, and the remaining technical debt explicit.
- [ ] Close TD-14/TD-07 modal, disconnect, and held-input neutralization before
  claiming lifecycle-safe controller ownership; Preview 3 ordinary-control
  acceptance does not close those transitions.
- [x] Obtain user approval to merge and publish Preview 3.

## Coordinated Preview 4 shared-controls and tank update

- [x] Freeze the exact physically accepted iPad test executable at SHA-256
  `2b31f8868885712fbad34cef1aea20b1dee48f59fc9d930cbd3fa8b8e82b6b12`.
- [x] Preserve raw non-gameplay controller passthrough so the tank repair cannot
  disable title or mission-menu navigation.
- [x] Use one shared 1.1 through 1.4 mapping on mobile and Mac, with native
  left-stick manual Aim and no platform-specific control interpretation.
- [x] Gate tank behavior on GoldenEye's live player/tank/entry state and retain
  the native hatch transition, drive/hull path, turret state, selected-weapon
  cycling, firing, and exit/re-entry behavior.
- [x] Obtain physical iPad acceptance for menu, on-foot controls, Aim, Runway
  tank drive/turn/turret/weapons, return to title, and a Facility regression
  pass.
- [x] Apply the user's final requested 20 percent absolute controller-look
  increase from 1.56 to 1.872 degrees per frame without changing touch, mouse,
  manual Aim, left movement, or menus.
- [x] Rebuild both generated GoldenEye patch halves together and prove tracked
  patch parity plus tank-state markers.
- [x] Pass the shared 1.1 through 1.4 matrix, complete unsigned device build,
  complete native arm64 Mac build, and both package audits.
- [x] Package the 18-member unsigned IPA at SHA-256
  `ff163b0af6b54596590da8e39cbaff0b388b69f1607ca34f62ce61e7fe144130`.
- [x] Package the 20-member Mac Alpha at SHA-256
  `63bec02ad6e323a213f9cb9d15f763a58d6eb7bd4a1a40af6341a4fb8fb333ba`.
- [ ] Keep issue #17 open until the reporter verifies Preview 4 on Mac. Do not
  treat iPad acceptance or Mac package proof as reporter acceptance.
- [ ] The final 1.872-degree unsigned release executable has build and static
  verification, not a second physical-device pass. Keep that distinction in
  release notes and status.

## Coordinated Preview 5 automatic-fire update

- [x] Freeze Preview 4 at merge
  `54474a40e93b77259d10c7594919e6a05f5e276d` and retain its controls/tank
  rollback record.
- [x] Measure three Preview 4 Phantom magazines at 20 events/58 ticks each,
  normalized to 34.4828 events/100 ticks with zero range.
- [x] Patch the one shared player/guard automatic-rate getter: multiply positive
  values by three and preserve zero/negative classifications unchanged.
- [x] Regenerate both embedded patch halves and add CMake stale-pair ratchets.
- [x] Pass the source-derived deterministic rate test and complete Preview 4
  input/Aim/tank matrix.
- [x] Install only the side-by-side test app in place and prove both ROM copies,
  active save, backup save, and preferences byte-identical.
- [x] Obtain physical iPad acceptance. Candidate telemetry recorded the exact
  expected 12 Phantom events/100 ticks, with accepted navigation, movement,
  controls, gameplay, and runtime quality.
- [x] Build and audit the version `0.1.0` build `5` unsigned IPA and native
  arm64 Mac Alpha from production probe-off source.
- [x] Record package, content, and executable digests in release
  notes, status, testing, building, and worklog documents.
- [x] Merge the isolated PR, verify remote `main`, tag
  `v0.1.0-preview.5`, publish a GitHub prerelease, and download/re-hash every
  hosted asset.
- [x] Keep issue #17 open for reporter Mac verification; Preview 5 retains the
  accepted tank mapping but does not substitute internal iPad evidence for the
  reporter's setup.

## Coordinated Preview 6 Mac and utility-menu update

- [x] Restore analog WASD/trackpad navigation in the Mac GoldenEye front end
  without weakening Preview 5's gameplay, tank, or automatic-fire paths.
- [x] Retain Preview 3 relative mouse behavior, hold Shift Aim until release,
  set default sensitivity to `3.00`, and apply the accepted `1.30x` ordinary
  on-foot turning factor without changing Shift Aim or tank rates.
- [x] Replace the unreliable iPad native utility menu with four independent
  48-point action rows.
- [x] Obtain user acceptance of Mac menu/gameplay controls and iPad utility-menu
  behavior without and with a controller, plus Dam and Bunker controller
  gameplay.
- [x] Advance only the primary iPhone/iPad bundle to build `6`; preserve the
  separate Mac Alpha identity and build number.
- [x] Pass the Preview 6 baseline allowance, fire-rate gate, full input matrix,
  ROM-data audit, ARM64 builds, package audits, and source hygiene checks.
- [x] Package the 18-member unsigned IPA twice at SHA-256
  `ced4d58bd8b54fd0dac4c7e9d892e22ea80f28d4bfa219fd586818dd62ba7266`.
- [x] Package the 20-member Mac Alpha twice at SHA-256
  `5189dcb5c7089f5ba45e7dbe17d67be9186148da20bce0c2c60e7156f78d71b8`.
- [x] Squash-merge the isolated PR, verify remote `main`, publish
  `v0.1.0-preview.6`, download and re-audit all hosted assets, then reply to
  issues #8, #9, #17, and #19 without overstating the renderer fixes.

## Preview 7 compatibility promotion

Preview 7 is limited to the issue #19 Metal deployment-target correction and
production identity. Do not add the optional second Fire button, TD-14, TD-07,
A12-specific work, renderer experiments, audio changes, or storage changes.

- [x] Confirm the same iPhone 13 mini that failed Preview 1 through Preview 6
  passes the exact iOS 17-target diagnostic IPA through ROM validation,
  title/menu, Dam gameplay, audio, and controls.
- [x] Compile all 56 device and all 56 Simulator Metal libraries with explicit
  iOS 17 AIR targets and reject mixed or unexpected targets.
- [x] Restore Preview 6's already-shipped depth diagnostic symbol to the tracked
  RT64 patch without changing its rendering decision.
- [x] Build production `GoldenPad` version `0.1.0` build `7` from the accepted
  generated AOT/runtime inputs and corrected RT64 archives.
- [x] Pass `verify-preview4-baseline.sh --allow-preview7`, the fire-rate gate,
  full input matrix, ARM64 build, ROM-data audit, package audit, source hygiene,
  and exact Metal-target audit.
- [x] Package the unsigned Preview 7 IPA twice with identical SHA-256.
- [x] Build and package the native Apple-Silicon Mac Alpha twice with identical
  SHA-256; require its executable and complete package to remain byte-identical
  to Preview 6.
- [x] Install the production candidate in place on the physical iPad and prove
  both ROM copies, active save, backup save, and preferences unchanged by
  readback.
- [x] Obtain hands-on iPadOS menu, touch/controller, audio, utility-menu,
  lifecycle, and gameplay acceptance.
- [x] Reconfirm the Mac payload has no Preview 7 regression. Retain horizontal
  mouse sluggishness as known Preview 6 debt rather than blocking the unchanged
  coordinated artifact.
- [x] Reconcile README, Status, Testing, Technical Debt, Plan, Next Steps,
  Building, Worklog, and these release notes against exact artifact hashes.
- [x] Merge the isolated PR, verify local/remote/default `main`, publish
  `v0.1.0-preview.7`, download every hosted asset, and rerun both package audits.
- [x] Ask issue #19's reporter to verify the production Preview 7 IPA. Keep
  issue #9 separate unless affected A12 hardware passes this exact artifact.

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
    dist/GoldenPad-0.1.0-preview.4-unsigned.ipa

  ./scripts/package-recomp-macos-alpha.sh
  ./scripts/verify-recomp-macos-alpha.sh \
    dist/GoldenPad-0.1.0-preview.4-macos-arm64-alpha.zip
  ```

- Keep the README's install table and limitations accurate.
- Keep repository visibility, source publication, and binary distribution as
  separate decisions.
- Do not publish an IPA until its exact file has passed the package audit.
- Do not describe the project as official, commercially licensed, App Store
  ready, or affiliated with any rights holder.
- Verify the merged PR state, clean worktree, and equality of local `main`,
  `origin/main`, and GitHub's default branch before handoff.
