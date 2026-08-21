# Release checklist

GoldenPad's current public deliverable is the source repository. No primary
runtime IPA, App Store build, or TestFlight is advertised.

The reproducible ROM-free unsigned IPA recipe below builds `GoldenPad Legacy`;
it is retained as a fallback artifact and must not be presented as the primary
RT64 release. The playable primary app currently depends on private generated
AOT inputs and a developer-staged retail-derived TLBFREE ROM. A public primary
binary requires both an end-user retail-ROM import/conversion flow and a
data-free package audit that proves no ROM, generated retail-derived code,
saves, signing material or private paths are shipped.

## Primary RT64 preview gate

Before publishing any primary-runtime preview:

- Complete the current signed-iPad hands-on matrix in `docs/TESTING.md` and
  record the exact accepted executable hash.
- Accept the separate touch-layout defaults and move/resize/opacity/reset editor
  on one physical iPhone and one physical iPad, including persistence after
  relaunch.
- Keep multiplayer explicitly work in progress until split-screen flashing and
  a complete physical match are accepted.
- Choose non-prototype public version metadata while preserving the existing
  internal target and bundle identifier only if migration has been audited.
- Define and verify the end-user game-data import/conversion path; developer
  staging is not a public installation workflow.
- Build the public artifact from a clean checkout, enumerate every packaged
  member, and run `scripts/check-no-rom-data.sh` plus a package-specific binary
  contamination audit.
- Keep source publication, binary publication, signing and rights clearance as
  separate decisions.

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
