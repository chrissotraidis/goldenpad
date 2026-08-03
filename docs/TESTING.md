# Testing

## Evidence levels

1. **Static:** provenance, contamination and archive inspection.
2. **Build:** exact architecture/SDK and clean-checkout compile.
3. **Runtime:** logs plus framebuffer/UI evidence.
4. **Interaction:** real menu/gameplay input and state transition.
5. **Acceptance:** mission/match completion, persistence and relaunch.

A lower level never substitutes for a higher one.

## Desktop baseline

```sh
ctest --test-dir ref/mgb64/build-goldenpad-webgpu --output-on-failure
```

Current upstream result is recorded in `STATUS.md`; it is not clean.

For a private deterministic framebuffer proof, run from an ignored directory
with a private ROM path and do not publish the output:

```sh
GE007_RENDERER=webgpu GE007_WINDOW_WIDTH=640 GE007_WINDOW_HEIGHT=480 \
  ../build-goldenpad-webgpu/ge007 --rom /private/path/to/retail-game.v64 \
  --level dam --difficulty agent --deterministic \
  --screenshot-frame 600 --screenshot-exit --screenshot-label local-proof \
  --savedir ../local-saves
```

## Mobile matrix

Run sequentially:

1. iPhone simulator: install, invalid ROM, valid ROM, title/menu, mission, audio,
   touch, save, relaunch, background/foreground, rotation/safe area.
2. Stop iPhone simulator and app process.
3. iPad simulator: repeat the same cases.
4. Stop iPad simulator and compare logs, screenshots, memory and layout.
5. Repeat on physical iPhone/iPad for controller, real audio, thermals and any
   simulator-limited Metal/audio behavior.

Do not publish screenshots containing copyrighted game imagery.

### Current foundation evidence

The 2026-08-03 pass used iOS 18.5 simulators, in this strict order:

1. iPhone 16 Pro: build, launch, render, validate supported V64, terminate and
   shut down.
2. iPad Pro 11-inch (M4): build, launch, render, validate supported V64, reject
   a one-byte file, terminate, uninstall and shut down.
3. Remove the iPhone installation as well, so neither app container retains the
   temporary retail-data copy.

The private test seam accepts `--validate-rom /absolute/path` or
`GOLDENPAD_VALIDATE_ROM_PATH`. It invokes the same `ROMValidator` used by the
Files picker and exists to make simulator validation reproducible. It does not
copy or persist the file.

The picker UI interaction pass is now complete on both simulators: open native
Files, inspect the visible picker, cancel, and confirm GoldenPad returns. A real
selection still uses the private validator seam to avoid placing a retail dump
in Files recents or published captures.

Missing-file and wrong-hash acceptance also passes on both. Use a nonexistent
path for the first case. For the second, create a temporary zero-filled 12 MiB
file with only the four-byte Z64 header `80 37 12 40`; require the SHA-1 mismatch
state, then delete the fixture. Never derive this fixture from a retail dump.

Storage relaunch probes use no game data:

```sh
xcrun simctl launch DEVICE_ID com.chrissotraidis.goldenpad \
  --storage-probe-write
xcrun simctl terminate DEVICE_ID com.chrissotraidis.goldenpad
xcrun simctl launch DEVICE_ID com.chrissotraidis.goldenpad \
  --storage-probe-verify
```

The expected visible state is `storage: relaunch verified`. Inspect
`settings.json` and `Saves/player-1.sav` inside the private app container, then
uninstall the app so the probe is removed.

Lifecycle acceptance must use the real Simulator UI with an attached console:

1. Launch GoldenPad with `xcrun simctl launch --console-pty DEVICE_ID ...`.
2. Press Simulator's Home control and require `Audio session inactive`.
3. Open GoldenPad from the launcher and require `Audio session active at 48000.0 Hz`.
4. Terminate, uninstall and shut down that simulator before testing the other.

This gate passed sequentially on iPhone 16 Pro and iPad Pro 11-inch (M4).
Real-core interruption and route-change acceptance remains a game-audio gate.

Render-surface acceptance uses the same attached-console lifecycle pass. Before
backgrounding, require a nonzero `renderer: Metal WIDTH×HEIGHT @ HZ` value in
the visible status and matching `RT64 surface ready` console line. After Home
and launcher return, require the original full drawable size again. The current
sequential pass observed 1206×2622 at 60 Hz on iPhone 16 Pro and 1668×2420 at
60 Hz on iPad Pro 11-inch (M4).

The touch lab must be driven through the real UI on both form factors. Verify
that movement/look axes clamp to `[-1, 1]`, momentary action bits clear after
release, the last non-neutral event remains visible for evidence, and controller
count/assignment do not destabilize the touch snapshot. Classic A must report
N64 mask `0x8000`; modern FIRE must report Z mask `0x2000`.

For each phone and tablet profile, open **Customize controls** and verify:

1. N64, Modern and Southpaw switch the visible live layout.
2. Selecting a control, nudging it and pressing Done persists one placement
   delta after terminate/relaunch; Reset removes that delta.
3. Size clamps to 70–150%; hide/show works; MOVE cannot be hidden.
4. Opacity, global size, look sensitivity, dead zone, gyro and external-control
   auto-hide settings persist.
5. Portrait and both landscape handed orientations stay within the safe guide.

The 2026-08-03 Simulator pass covered the accessible nudge path, persistence,
reset, hide/show, size/opacity controls and safe-area layout. Simulator presents
a synthetic unattached MFi controller; GoldenPad ignores it for auto-hide only
when compiled for Simulator. Direct finger dragging, physical Core Motion and
real-controller auto-hide remain device gates.

For repository contamination checks:

```sh
./scripts/check-no-rom-data.sh
```

## RT64 mobile Metal and static-library gate

With the exact RT64 and Plume commits from `RESEARCH.md` initialized under
ignored `ref/rt64`, run:

```sh
./scripts/verify-rt64-ios-metal.sh
GOLDENPAD_RT64_ARTIFACT_DIR="$PWD/build-rt64-static" \
  ./scripts/verify-rt64-ios-static.sh
```

The scripts refuse dirty or mismatched target sources, temporarily apply their
tracked patches, and reverse them on exit. The fast probe must produce 56
metallibs for each mobile SDK, patched ARM64 Plume archives for each, and a
successful macOS Plume regression build. Expected stable aggregate digests are:

- `iphoneos`: `04c7eb0f7719dc27ea3f4ca4b2f95fc7bb5a59837c1c77af68ce421d081cc838`
- `iphonesimulator`: `7b9a5a185799bd8bda7f7e2b25fe4bcb18223200cf14df781c442441f93f2212`

The full verifier must report, for both SDKs, 210 RT64 archive members, 246
force-loaded closure members, ARM64, and dependencies limited to expected Apple
frameworks/runtime libraries. It rejects SDL, NFD, AppKit, IOKit, X11 and macOS
Vulkan-surface symbols.

Configure the opt-in linked app using `BUILDING.md`, then run strictly iPhone
first and iPad second. Require visible `renderer: RT64 Metal DEVICE WIDTHxHEIGHT`
status, terminate/uninstall/shut down the phone, and only then repeat on iPad.
The 2026-08-03 pass reported `Apple iOS simulator GPU` at 1206x2622 and
1668x2420 respectively. A Release `iphoneos` linked app also built as ARM64.
This satisfies G2; GoldenEye frames begin at G3 and remain core-gated.

## Package gate

Every IPA test must unzip into a fresh temporary directory, enumerate members,
run the contamination policy from `LEGAL.md`, and prove the app cannot play
without user-selected retail data. Record hashes of project-owned artifacts only.

The repository scripts implement the current foundation gate:

```sh
./scripts/package-foundation-ipa.sh
./scripts/verify-unsigned-ipa.sh \
  dist/GoldenPad-0.1.0-foundation-unsigned.ipa
```

The verifier rejects ROM/save/signing path names, all three N64 byte-order magic
headers, the supported retail SHA-1, a signed app, non-ARM64 code, and private
developer/reference strings. It also prints a sorted-content digest independent
of ZIP metadata.
