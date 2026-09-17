#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
  echo "Usage: $0 RUNTIME_SOURCE_DIR PATCH_PATH VERIFIED_TLBFREE_PATH [RETAIL_PATH]" >&2
  exit 2
fi
runtime_source=$1
shift
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-rom-import-test.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT
xcrun clang -O2 -c "$runtime_source/thirdparty/xxHash/xxhash.c" -o "$build_dir/xxhash.o"
xcrun clang++ -std=c++20 -O2 -I"$runtime_source/thirdparty" \
  -c "$repo_root/Support/RecompPrototype/recomp_rom_import.cpp" -o "$build_dir/import.o"
xcrun swiftc -O -parse-as-library \
  "$repo_root/Sources/Mac/RecompMacROMStore.swift" \
  "$repo_root/Tests/RecompMacROMImportTests.swift" \
  "$build_dir/import.o" "$build_dir/xxhash.o" -lc++ -o "$build_dir/import-test"
"$build_dir/import-test" "$@"
