#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
sdk=${1:-iphoneos}
case "$sdk" in iphoneos|iphonesimulator) system=iOS; target=17.0;; macosx) system=Darwin; target=13.0;; *) echo 'SDK must be iphoneos, iphonesimulator or macosx' >&2; exit 2;; esac
python3 "$repo_root/scripts/check-sources.py" --component goldeneye
source="$repo_root/vendor/goldeneye/lib/N64ModernRuntime"
output=${GOLDENPAD_RUNTIME_BUILD_DIR:-"$repo_root/build-runtime-$sdk"}
flags="-O3 -DNDEBUG -ffile-prefix-map=$source=N64ModernRuntime"
cmake -S "$source" -B "$output" -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME="$system" -DCMAKE_OSX_SYSROOT="$sdk" -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$target" -DN64MODERNRUNTIME_ENABLE_LIVE_RECOMP=OFF \
  -DCMAKE_C_FLAGS_RELEASE="$flags" -DCMAKE_CXX_FLAGS_RELEASE="$flags"
cmake --build "$output" --parallel 8
