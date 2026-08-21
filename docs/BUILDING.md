# Building

GoldenPad's primary iPhone/iPad runtime is the recomp/RT64 target documented in
[`RT64_N64RECOMP_PROTOTYPE.md`](RT64_N64RECOMP_PROTOTYPE.md). Its internal target
name remains `GoldenPadRecompPrototype`, but the installed product is
user-facing `GoldenPad`.

The instructions below describe the older MGB64/Fast3D target. It remains
buildable as the deprecated `GoldenPad Legacy` fallback for regression
comparison; it is not the primary release path.

The legacy target is ROM-free. It validates a user-selected retail dump,
derives runtime assets inside the app container, and links the audited MGB64
game core and native Metal renderer.

Requirements currently verified: Xcode 26.5, Swift 6.3.3, AppleClang 21, CMake
4.4, Ninja 1.13, SDL2 2.32.70, and Apple Silicon macOS 26.5.2.

## Primary mobile preview package

The complete primary target requires the ignored/generated AOT inputs and exact
dependency archives described in
[`RT64_N64RECOMP_PROTOTYPE.md`](RT64_N64RECOMP_PROTOTYPE.md). After the signed
device app has been built and physically accepted, create the public unsigned
package with:

```sh
./scripts/package-recomp-prototype-ipa.sh
./scripts/verify-recomp-prototype-ipa.sh \
  dist/GoldenPad-0.1.0-preview.2-unsigned.ipa
```

The packager copies the signed app into a temporary staging directory, removes
its signature, provisioning profile and signing resources, enables Finder file
sharing, stages the applicable upstream licenses, normalizes timestamps, and
invokes the primary package verifier. It never edits the signed source app.

Preview 2 replaces Preview 1's manual Finder file-sharing step with the bounded
first-launch flow in [`PREVIEW_2_ROM_IMPORT.md`](PREVIEW_2_ROM_IMPORT.md). A new
user chooses their supported original retail dump from Files; conversion and
validation stay inside the app container. An in-place update reuses an existing
valid `GoldenEye_TLBFREE.z64`. No retail input, save, generated source, signing
identity, or provisioning profile is placed in the IPA.

The audited Preview 2 IPA SHA-256 is
`704bdf68f67d1f0925fd1844ab865c263a79e105a6349ef410f365602e6c77e3`.
It must not be published until the exact final signed rebuild receives the
remaining hands-on gameplay approval.

## Native Apple-Silicon Mac alpha

The Mac app is a separate native arm64 artifact, not a Catalyst build and not
part of the mobile `.ipa`. It is an Alpha below the accepted iPhone/iPad
single-player quality bar. Mouse tuning, the thin far-right blue edge and
sustained performance remain open; do not change the frozen renderer/input
boundary while preparing the coordinated release.

Build the exact pinned native dependencies first, then configure the app with
the private generated AOT directory and the isolated matched Mac patch source:

```sh
GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR=/path/to/N64ModernRuntime \
  ./scripts/build-recomp-macos-dependencies.sh

cmake -S . -B build-recomp-macos -G Xcode \
  -DGOLDENPAD_RECOMP_MAC=ON \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DGOLDENPAD_RECOMP_AOT_DIR=/path/to/generated-aot \
  -DGOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR=/path/to/N64ModernRuntime \
  -DGOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR="$PWD/build-recomp-macos-deps/runtime" \
  -DGOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR=/path/to/matched-mac-reference \
  -DGOLDENPAD_RECOMP_RT64_SOURCE_DIR="$PWD/ref/rt64" \
  -DGOLDENPAD_RECOMP_RT64_ARCHIVE_DIR="$PWD/build-recomp-macos-deps/rt64"

cmake --build build-recomp-macos --config Release --target GoldenPadMac
./scripts/package-recomp-macos-alpha.sh
```

The installed and packaged product is named `GoldenPad.app`; `GoldenPadMac` is
only the internal CMake target. The packager adds notices, applies an ad-hoc
signature, and runs the Mac artifact audit. No ROM, save, generated source or
Apple signing identity is included.

The audited Alpha archive is
`dist/GoldenPad-0.1.0-preview.2-macos-arm64-alpha.zip` at SHA-256
`7a9e7342b0ae39518f73807f854b479d9691fd612ae6861ea527f2a19e4450a4`.
It is native arm64, ad-hoc signed and not notarized.

The complete AOT build must have the maintained GoldenEye iOS context patch
applied while compiling:

```sh
git -C ref/goldeneye64recomp apply \
  ../../patches/goldeneye64recomp-ios-prototype-render-trace.patch
```

CMake deliberately refuses a complete AOT configuration without the patch.
It supplies the writable first-launch RT64 Application Support path as well as
the existing render diagnostics. Reverse it after the build to leave the
ignored upstream checkout clean:

```sh
git -C ref/goldeneye64recomp apply --reverse \
  ../../patches/goldeneye64recomp-ios-prototype-render-trace.patch
```

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

This creates an unsigned, ROM-free IPA for host-shell validation.
Its filename says `foundation` because it does not contain the game core and is
not the final deliverable. Use the game-bearing package gate below for current
production validation.

## MGB64 iOS game core

Fetch the exact ignored upstream checkout, run its native SDK-surface guard, and
build the complete audited C core for both Apple mobile SDKs:

```sh
./scripts/fetch-mgb64.sh
./scripts/verify-mgb64-public-tests.sh
./scripts/verify-mgb64-ios-core.sh
./scripts/verify-mgb64-ios-metal.sh
./scripts/verify-mgb64-ios-fast3d.sh
./scripts/verify-mgb64-ios-renderer.sh
```

The public-test verifier builds a disposable Git export of the exact pin rather
than running upstream's private fidelity checkout in place. Its maintained
compatibility patch keeps the public release guards valid on macOS Bash 3 and
produces a 103-entry CTest surface with no failures; 10 prerequisite-dependent
tests skip explicitly. It never requires or copies a ROM.

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

Package the complete unsigned device app after the combined verifier passes:

```sh
./scripts/verify-mgb64-ios-renderer.sh
./scripts/verify-source-license-manifest.sh
./scripts/package-unsigned-ipa.sh
./scripts/verify-unsigned-ipa.sh --game-core \
  dist/GoldenPad-0.1.0-unsigned.ipa
```

Game-core mode requires MGB64's game entry point and the native Fast3D/Metal
renderer entry points in addition to the normal ARM64, unsigned and ROM-free
archive checks. Native compiler source paths are prefix-mapped to stable relative
identities so private checkout paths cannot enter the Mach-O. The IPA also
carries the required third-party notices. At commit `94242be`, two independent
clean checkouts produced the same device executable and byte-identical IPA, so
the current package is byte reproducible. Exact hashes are recorded in
`TESTING.md`.

## Signed physical-device build

Unsigned reproducibility remains the default. To build the same complete
game-bearing target for a device, first confirm that Xcode has an Apple
Development identity:

```sh
security find-identity -v -p codesigning
```

Then provide your Apple team ID and a bundle identifier owned by that team:

```sh
GOLDENPAD_DEVELOPMENT_TEAM=YOURTEAMID \
GOLDENPAD_BUNDLE_IDENTIFIER=com.yourname.goldenpad \
  ./scripts/verify-mgb64-ios-renderer.sh
```

This keeps the maintained MGB64 patches applied for the entire compile/sign
operation, asks Xcode to manage provisioning, verifies the resulting signature
and embedded provisioning profile, and writes the signed app separately from
the reproducible unsigned build:

```text
build-mgb64-renderer-device-signed/Release-iphoneos/GoldenPad.app
```

With a trusted iPhone or iPad connected, list it and install the app:

```sh
xcrun devicectl list devices
xcrun devicectl device install app \
  --device DEVICE_ID \
  build-mgb64-renderer-device-signed/Release-iphoneos/GoldenPad.app
```

Do not package this signed app with `package-unsigned-ipa.sh`; that script
deliberately accepts only the separate unsigned build. Signing and installation
require the developer's own identity, team provisioning and connected hardware.

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

With that build and a private supported ROM available, the maintained
two-player split-screen startup gate is:

```sh
GOLDENPAD_ROM_PATH=/private/path/to/retail-game.v64 \
  ./scripts/verify-mgb64-multiplayer-smoke.sh
```

Its private ROM-derived artifacts are disposable and removed automatically.
Passing it proves native split-screen startup and rendering, not completion of
a local match.

The upstream `-DMGB64_WEBGPU_BACKEND=OFF` option currently fails to link at the
pinned commit and is intentionally not the documented baseline.

Full gameplay and final unsigned-IPA instructions remain gated on clean mobile
platform/renderer integration.
