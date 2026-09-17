#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
if [ "$#" -ne 2 ]; then echo 'Usage: build-recomp-apple.sh ios|macos PRIVATE_GENERATED_DIRECTORY' >&2; exit 2; fi
platform=$1
inputs=$(cd "$2" && pwd)
python3 "$repo_root/scripts/check-sources.py"
args=(-DGOLDENPAD_RECOMP_AOT_DIR="$inputs" -DGOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR="$inputs" -DGOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR="$repo_root/vendor/goldeneye/lib/N64ModernRuntime")
case "$platform" in
 ios)
  target=GoldenPadRecompPrototype; sdk=iphoneos; output="$repo_root/build-maintained-ios"
  args+=(-DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT=iphoneos -DGOLDENPAD_RECOMP_PROTOTYPE=ON -DGOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR="${GOLDENPAD_RUNTIME_BUILD_DIR:-$repo_root/build-runtime-iphoneos}" -DGOLDENPAD_RECOMP_RT64_SOURCE_DIR="$repo_root/vendor/rt64-ios" -DGOLDENPAD_RECOMP_RT64_ARCHIVE_DIR="${GOLDENPAD_RT64_ARTIFACT_DIR:-$repo_root/build-rt64-ios}/iphoneos")
  ;;
 macos)
  target=GoldenPadMac; sdk=macosx; output="$repo_root/build-maintained-macos"
  deps=${GOLDENPAD_RECOMP_MAC_DEPENDENCY_DIR:-"$repo_root/build-recomp-macos-deps"}
  args+=(-DGOLDENPAD_RECOMP_MAC=ON -DGOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR="$deps/runtime" -DGOLDENPAD_RECOMP_RT64_SOURCE_DIR="$repo_root/vendor/rt64-macos" -DGOLDENPAD_RECOMP_RT64_ARCHIVE_DIR="$deps/rt64")
  ;;
 *) echo 'Platform must be ios or macos' >&2; exit 2;;
esac
cmake -S "$repo_root" -B "$output" -G Xcode -DCMAKE_OSX_ARCHITECTURES=arm64 "${args[@]}"
xcodebuild -quiet -project "$output/GoldenPad.xcodeproj" -target "$target" -configuration Release -sdk "$sdk" CODE_SIGNING_ALLOWED=NO build
