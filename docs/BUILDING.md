# Building

GoldenPad has a native ROM-free iPhone/iPad foundation target. It validates a
user-selected retail dump but intentionally cannot start the game until the
production static-recomp gate passes.

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

Production-core and final unsigned-IPA instructions remain gated on clean core
integration.
