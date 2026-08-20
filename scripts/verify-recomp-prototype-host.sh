#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_dir=${GOLDENPAD_RECOMP_BUILD_DIR:-"$repo_root/build-recomp-prototype-simulator"}
bundle_identifier=${GOLDENPAD_RECOMP_BUNDLE_IDENTIFIER:-com.chrissotraidis.goldenpad.recomp-prototype}

cmake -S "$repo_root" -B "$build_dir" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=iphonesimulator \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DGOLDENPAD_RECOMP_PROTOTYPE=ON \
    -DGOLDENPAD_RECOMP_BUNDLE_IDENTIFIER="$bundle_identifier"

xcodebuild -quiet -project "$build_dir/GoldenPad.xcodeproj" \
    -target GoldenPadRecompPrototype -configuration Release -sdk iphonesimulator \
    CODE_SIGNING_ALLOWED=NO build

app="$build_dir/Release-iphonesimulator/GoldenPadRecompPrototype.app"
binary="$app/GoldenPadRecompPrototype"
test -f "$binary"
file "$binary" | grep -q 'Mach-O 64-bit executable arm64'
test "$(plutil -extract CFBundleIdentifier raw -o - "$app/Info.plist")" = "$bundle_identifier"
nm -gU "$binary" | grep -q _goldenpad_recomp_rt64_initialize
nm -gU "$binary" | grep -q _goldenpad_recomp_rt64_shutdown
if nm -gU "$binary" | grep -Eq '_bossEntry|_goldenpad_mgb64_'; then
    echo "Production MGB64 symbols entered the isolated prototype." >&2
    exit 1
fi

echo "GoldenPadRecompPrototype host passed (ARM64 Simulator, $bundle_identifier)."
