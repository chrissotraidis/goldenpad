#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
companion_dir=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-lan-companion.XXXXXX")
trap 'rm -rf "$companion_dir"' EXIT
export CLANG_MODULE_CACHE_PATH="$companion_dir/clang-module-cache"
export SWIFT_MODULECACHE_PATH="$companion_dir/swift-module-cache"

xcrun swiftc \
  "$repo_root/Sources/LANNetplayProtocol.swift" \
  "$repo_root/Tests/LANNetplayCompanion.swift" \
  -framework MultipeerConnectivity \
  -o "$companion_dir/lan-netplay-companion"

"$companion_dir/lan-netplay-companion"
