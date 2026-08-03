#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir="${GOLDENPAD_MGB64_SOURCE_DIR:-$repo_root/ref/mgb64}"
patch_file="$repo_root/patches/mgb64-ios-metal.patch"
sim_build="$repo_root/build-mgb64-core-simulator"
device_build="$repo_root/build-mgb64-core-device"
metal_source=src/platform/fast3d/gfx_metal.mm
patch_applied=0

cleanup() {
    if [ "$patch_applied" -eq 1 ]; then
        git -C "$source_dir" apply -R "$patch_file"
    fi
}
trap cleanup EXIT

"$repo_root/scripts/fetch-mgb64.sh"
if ! git -C "$source_dir" diff --quiet -- "$metal_source"; then
    echo "MGB64 Metal source is dirty; refusing to patch it." >&2
    exit 1
fi

git -C "$source_dir" apply --check "$patch_file"
git -C "$source_dir" apply "$patch_file"
patch_applied=1

cmake -S "$repo_root" -B "$sim_build" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=iphonesimulator \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DGOLDENPAD_MGB64_SOURCE_DIR="$source_dir"
xcodebuild -project "$sim_build/GoldenPad.xcodeproj" \
    -target goldenpad_mgb64_metal -configuration Release \
    -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build

cmake -S "$repo_root" -B "$device_build" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=iphoneos \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DGOLDENPAD_MGB64_SOURCE_DIR="$source_dir"
xcodebuild -project "$device_build/GoldenPad.xcodeproj" \
    -target goldenpad_mgb64_metal -configuration Release \
    -sdk iphoneos CODE_SIGNING_ALLOWED=NO build

for archive in \
    "$sim_build/Release-iphonesimulator/libgoldenpad_mgb64_metal.a" \
    "$device_build/Release-iphoneos/libgoldenpad_mgb64_metal.a"
do
    test -f "$archive"
    xcrun lipo -info "$archive" | grep -q 'architecture: arm64'
    objects=$(xcrun ar -t "$archive" | grep -c '\.o$')
    if [ "$objects" -ne 4 ]; then
        echo "Unexpected MGB64 Metal archive: $objects objects" >&2
        exit 1
    fi
    nm -gU "$archive" | grep -q '_gfx_metal_api'
    echo "Verified $archive ($objects objects, ARM64, gfx_metal_api)"
done

echo "MGB64 iOS Metal backend compilation passed."
