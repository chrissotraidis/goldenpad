#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
probe_dir=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-lan-protocol.XXXXXX")
trap 'rm -rf "$probe_dir"' EXIT
export CLANG_MODULE_CACHE_PATH="$probe_dir/clang-module-cache"
export SWIFT_MODULECACHE_PATH="$probe_dir/swift-module-cache"

xcrun swiftc \
  "$repo_root/Sources/LANNetplayProtocol.swift" \
  "$repo_root/Tests/LANNetplayProtocolProbe.swift" \
  -o "$probe_dir/lan-netplay-probe"

"$probe_dir/lan-netplay-probe"
