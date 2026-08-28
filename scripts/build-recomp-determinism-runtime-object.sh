#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
runtime_source=${GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR:-}
runtime_archives=${GOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR:-}
output_root=${GOLDENPAD_DETERMINISM_RUNTIME_OUTPUT_DIR:-}

if [ -z "$runtime_source" ] || [ -z "$runtime_archives" ] || [ -z "$output_root" ]; then
    echo "Set GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR, GOLDENPAD_RECOMP_RUNTIME_ARCHIVE_DIR, and GOLDENPAD_DETERMINISM_RUNTIME_OUTPUT_DIR." >&2
    exit 2
fi
if [ -e "$output_root" ]; then
    echo "Refusing to overwrite existing output: $output_root" >&2
    exit 2
fi

for tool in ar cmake cp ninja patch; do
    command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 2; }
done
test -f "$runtime_source/librecomp/src/ultra_translation.cpp"
test -f "$runtime_archives/librecomp/liblibrecomp.a"

mkdir -p "$output_root"
cp -R "$runtime_source" "$output_root/source"
cp -R "$runtime_archives" "$output_root/archives"
patch -p1 --batch --no-backup-if-mismatch \
    -d "$output_root/source" \
    < "$repo_root/patches/n64modernruntime-deterministic-clock-probe.patch"

cmake -S "$output_root/source" -B "$output_root/build" -G Ninja \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=iphonesimulator \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS_RELEASE=-DNDEBUG \
    -DCMAKE_CXX_FLAGS_RELEASE=-DNDEBUG

ninja -C "$output_root/build" \
    librecomp/CMakeFiles/librecomp.dir/src/ultra_translation.cpp.o \
    ultramodern/CMakeFiles/ultramodern.dir/src/events.cpp.o
ar -r "$output_root/archives/librecomp/liblibrecomp.a" \
    "$output_root/build/librecomp/CMakeFiles/librecomp.dir/src/ultra_translation.cpp.o"
ar -r "$output_root/archives/ultramodern/libultramodern.a" \
    "$output_root/build/ultramodern/CMakeFiles/ultramodern.dir/src/events.cpp.o"

if ! nm -u "$output_root/archives/librecomp/liblibrecomp.a" |
    rg -q 'goldenpad_recomp_deterministic_clock_ticks'; then
    echo "Patched runtime object was not installed into liblibrecomp.a" >&2
    exit 1
fi

echo "Determinism-probe runtime source:   $output_root/source"
echo "Determinism-probe runtime archives: $output_root/archives"
