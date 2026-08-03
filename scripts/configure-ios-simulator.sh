#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
build_dir=${1:-"$repo_root/build-ios-simulator"}

cmake -S "$repo_root" -B "$build_dir" -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES=arm64

echo "Configured: $build_dir/GoldenPad.xcodeproj"
