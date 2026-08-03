# Building

GoldenPad has a native ROM-free iPhone/iPad foundation target. It validates a
user-selected retail dump and can link the audited MGB64 game core and native
renderer, but it does not start the game until the remaining resource and
platform/main-loop adapters are present.

Requirements currently verified: Xcode 26.5, Swift 6.3.3, AppleClang 21, CMake
4.4, Ninja 1.13, SDL2 2.32.70, and Apple Silicon macOS 26.5.2.

## iPhone/iPad foundation

Configure and build the ARM64 simulator target:

```sh
./scripts/configure-ios-simulator.sh
xcodebuild -project build-ios-simulator/GoldenPad.xcodeproj \
  -scheme GoldenPad -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' \
  CODE_SIGNING_ALLOWED=NO build
```

Build the unsigned ARM64 device bundle:

```sh
cmake -S . -B build-ios-device -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64
xcodebuild -project build-ios-device/GoldenPad.xcodeproj \
  -scheme GoldenPad -configuration Release -sdk iphoneos \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
file build-ios-device/Release-iphoneos/GoldenPad.app/GoldenPad
```

The last command must report a `Mach-O 64-bit executable arm64`. Build trees are
ignored. Never place a ROM in either build tree.

Package and verify the explicitly incomplete foundation artifact:

```sh
./scripts/package-foundation-ipa.sh
./scripts/verify-unsigned-ipa.sh \
  dist/GoldenPad-0.1.0-foundation-unsigned.ipa
```

This creates a reproducible, unsigned, ROM-free IPA for host-shell validation.
Its filename says `foundation` because it does not contain the game core and is
not the final deliverable.

## MGB64 iOS game core

Fetch the exact ignored upstream checkout, run its native SDK-surface guard, and
build the complete audited C core for both Apple mobile SDKs:

```sh
./scripts/fetch-mgb64.sh
./scripts/verify-mgb64-ios-core.sh
./scripts/verify-mgb64-ios-metal.sh
./scripts/verify-mgb64-ios-fast3d.sh
./scripts/verify-mgb64-ios-renderer.sh
```

The verifier compiles all 135 `src/game/*.c` translation units, 70 explicit
upstream native system/portable units and five project-owned SDL-free mobile
adapters into 210-object ARM64 archives. It rejects a
mismatched or dirty upstream checkout, never compiles `src/libultra/**` or
`src/libultrare/**` implementation sources, builds the opt-in GoldenPad app for
Simulator and device, and requires the final executables to retain the exact
MGB64 identity, real upstream random-core symbols and the mobile `guNormalize`
implementation.

The opt-in configuration used by that script is equivalent to:

```sh
cmake -S . -B build-mgb64-core-simulator -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DGOLDENPAD_MGB64_SOURCE_DIR="$PWD/ref/mgb64"
```

The ordinary foundation configuration remains independent of `ref/`. The core
configuration proves compilation and a small deterministic game-code execution
seam. That probe normalizes a real vector, checks representative native trig,
fidelity, watch-aspect and segment-constant paths, then executes the upstream
random check. It also verifies conservative mobile-owned settings/startup
defaults. The current mobile OS adapter initializes MGB64's real cooperative
scheduler and graphics-client queues after a validated ROM/file-table handoff;
the same probe blocks on a delayed mobile timer and round-trips the volatile
16 Kbit EEPROM surface. The complete app link has no unresolved `bossEntry`
boundary, starts the game once after all readiness gates, feeds Swift controller
frames through `osCont*`, and renders MGB64 synth PCM through `AVAudioEngine`.
Persistent game EEPROM now crosses the atomic Application Support bridge;
the diagnostics-only menu probe traverses the real controller path and proves a
controlled Dam load on both simulator classes. A second retained gameplay-state
seam proves movement, aim/look, fire/reload, weapon and pause mappings without
calling gameplay functions. Mission completion remains open.

The core also includes the real upstream model converter, CLI stage table,
radial deadzone, setup-name and weapon-cue services. A small native data unit
owns constants/offsets that otherwise live in the desktop compatibility file.

The Metal verifier applies `patches/mgb64-ios-metal.patch` only inside the exact
ignored checkout, compiles the complete native Metal backend plus its combiner,
backend selector and MSAA helper, verifies four-object ARM64 archives for both
SDKs, and reverses the patch on exit. The patch gates two macOS-only
`CAMetalLayer.displaySyncEnabled` writes; presentation cadence remains owned by
the iOS view/display lifecycle. This is a backend compilation gate, not yet a
linked renderer or displayed game frame.

The Fast3D verifier temporarily applies `patches/mgb64-ios-fast3d.patch`, which
selects Metal directly for the mobile build and removes the retained desktop GL
selector. It builds the display-list interpreter, room-normal helper, screenshot
and texture units as five-object ARM64 archives for both SDKs. It requires the public `gfx_init`,
`gfx_run_dl`, and `gfx_end_frame` entry points and rejects unresolved SDL window,
desktop OpenGL readback, or OpenGL swap symbols. GoldenPad's default app also
contains the ARC layer bridge consumed by `gfx_metal.mm`.

The combined verifier applies both tracked patches to the exact clean ignored
checkout, links the audited core plus Fast3D/Metal closure into Release apps for
both SDKs, rejects desktop dependencies, and reverses both patches on exit. Its
configuration is equivalent to:

```sh
cmake -S . -B build-mgb64-renderer-simulator -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DGOLDENPAD_MGB64_SOURCE_DIR="$PWD/ref/mgb64" \
  -DGOLDENPAD_MGB64_RENDERER=ON
```

Before validation this starts and presents ROM-free empty frames through
MGB64's real backend. It
also enables the existing validator to install a supported normalized ROM into
volatile MGB64-owned memory after the exact SHA-1 passes. The generated native
offset unit patches the complete file table and verifies known background/Dam
entries. It also initializes the upstream scheduler through the SDL-free mobile
OS adapter, and the UIKit draw callback delivers a bounded cooperative retrace
when the graphics queue is empty. Once UIKit owns retrace, scene suspension
blocks production instead of starting the fallback clock. A valid private ROM
then starts `bossEntry`; the game thread submits the real title/demo display
lists while the native audio and input bridges remain active.

## RT64 iOS static renderer

Initialize the exact RT64 checkout and submodules recorded in `RESEARCH.md`
under ignored `ref/rt64`, then run:

```sh
./scripts/verify-rt64-ios-metal.sh
GOLDENPAD_RT64_ARTIFACT_DIR="$PWD/build-rt64-static" \
  ./scripts/verify-rt64-ios-static.sh
```

The first command is the fast shader/backend feasibility check. The second
generates 113 shader blob sources, compiles all 56 Metal shaders for each SDK,
builds the complete RT64/Plume/re-spirv/zstd static closure, and force-loads all
246 archive members into a link probe. Patches are temporary and automatically
reversed. Supplying `GOLDENPAD_RT64_ARTIFACT_DIR` retains only the four verified
archives for each SDK under the ignored output directory.

Link those archives into GoldenPad's opt-in renderer bridge:

```sh
cmake -S . -B build-ios-simulator-rt64 -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DGOLDENPAD_RT64_ARCHIVE_DIR="$PWD/build-rt64-static/iphonesimulator" \
  -DGOLDENPAD_RT64_SOURCE_DIR="$PWD/ref/rt64"
xcodebuild -project build-ios-simulator-rt64/GoldenPad.xcodeproj \
  -scheme GoldenPad -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' \
  CODE_SIGNING_ALLOWED=NO build
```

The linked host initializes RT64's real Plume Metal device, command queue and
swapchain. It still cannot render game display lists until the selected MGB64
core is connected through its mobile platform/render loop.

## Apple Silicon research oracle

```sh
cmake -S ref/mgb64 -B ref/mgb64/build-goldenpad-webgpu -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DMGB64_APP=OFF
cmake --build ref/mgb64/build-goldenpad-webgpu --parallel 8
file ref/mgb64/build-goldenpad-webgpu/ge007
```

The result must report `Mach-O 64-bit executable arm64`.

Do not copy the ROM into a source/build directory. Pass its private absolute path
at runtime and keep saves under an ignored directory:

```sh
GE007_RENDERER=webgpu ref/mgb64/build-goldenpad-webgpu/ge007 \
  --rom /private/path/to/retail-game.v64 \
  --level dam --difficulty agent --no-input-grab \
  --savedir ref/mgb64/local-saves
```

The upstream `-DMGB64_WEBGPU_BACKEND=OFF` option currently fails to link at the
pinned commit and is intentionally not the documented baseline.

Full gameplay and final unsigned-IPA instructions remain gated on clean mobile
platform/renderer integration.
