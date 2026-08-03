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
copy or persist the file. The picker UI itself still needs an interaction pass.

For repository contamination checks:

```sh
./scripts/check-no-rom-data.sh
```

## Package gate

Every IPA test must unzip into a fresh temporary directory, enumerate members,
run the contamination policy from `LEGAL.md`, and prove the app cannot play
without user-selected retail data. Record hashes of project-owned artifacts only.
