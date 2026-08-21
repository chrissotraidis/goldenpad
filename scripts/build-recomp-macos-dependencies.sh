#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
rt64_path=${GOLDENPAD_RECOMP_RT64_SOURCE_DIR:-"$repo_root/ref/rt64"}
runtime_source=${GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR:-}
output_root=${GOLDENPAD_RECOMP_MAC_DEPENDENCY_DIR:-"$repo_root/build-recomp-macos-deps"}
metal_toolchain=${GOLDENPAD_METAL_TOOLCHAIN:-}

rt64_sdk_patch="$repo_root/patches/rt64-ios-sdk.patch"
rt64_embedded_patch="$repo_root/patches/rt64-ios-embedded.patch"
plume_patch="$repo_root/patches/plume-ios-metal.patch"
plume_macos_pacing_patch="$repo_root/patches/plume-macos-main-queue-coalescing.patch"
plume_path="$rt64_path/src/contrib/plume"
shim_path="$repo_root/Support/RT64"

expected_rt64=5473732a822a4423b5696e7cb18fecc425a59875
expected_plume=d890ac899e505fb30040e037a4037cdeca68f033
expected_runtime=e75e0de77e8377d4954fe7b511c0d1cf608e7ded

for tool in cmake ninja patch git xcrun rg rsync; do
    command -v "$tool" >/dev/null || { echo "Missing build tool: $tool" >&2; exit 1; }
done
test -d "$rt64_path/.git" || { echo "Missing pinned RT64 checkout: $rt64_path" >&2; exit 1; }
test -n "$runtime_source" || {
    echo "Set GOLDENPAD_RECOMP_RUNTIME_SOURCE_DIR to the private N64ModernRuntime checkout." >&2
    exit 1
}
test -d "$runtime_source/.git" || { echo "Missing private runtime source: $runtime_source" >&2; exit 1; }
test "$(git -C "$rt64_path" rev-parse HEAD)" = "$expected_rt64"
test "$(git -C "$plume_path" rev-parse HEAD)" = "$expected_plume"
test "$(git -C "$runtime_source" rev-parse HEAD)" = "$expected_runtime"

if [ -n "$metal_toolchain" ]; then
    # RT64's generated Ninja rules invoke plain `xcrun`. Propagate the
    # selected standalone Metal toolchain to those nested commands too.
    export TOOLCHAINS="$metal_toolchain"
fi
run_xcrun() {
    if [ -n "$metal_toolchain" ]; then
        xcrun --toolchain "$metal_toolchain" "$@"
    else
        xcrun "$@"
    fi
}
run_xcrun -sdk macosx --find metal >/dev/null

mkdir -p "$output_root"
build_cache="$output_root/build-cache"
export CLANG_MODULE_CACHE_PATH="$build_cache/clang/ModuleCache"
mkdir -p "$CLANG_MODULE_CACHE_PATH"

runtime_build="$output_root/runtime"
runtime_prefix_flags="-ffile-prefix-map=$runtime_source=N64ModernRuntime"
cmake --fresh -S "$runtime_source" -B "$runtime_build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS_RELEASE="$runtime_prefix_flags" \
    -DCMAKE_CXX_FLAGS_RELEASE="$runtime_prefix_flags" \
    -DCMAKE_OSX_SYSROOT=macosx \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
    -DN64MODERNRUNTIME_ENABLE_LIVE_RECOMP=OFF
cmake --build "$runtime_build" --parallel 8

rt64_patch_targets=(
    CMakeLists.txt
    src/apple/rt64_apple.mm
    src/hle/rt64_application.cpp
    src/hle/rt64_application_window.h
    src/hle/rt64_rsp.cpp
    src/hle/rt64_rdp.cpp
)
if ! git -C "$rt64_path" diff --quiet -- "${rt64_patch_targets[@]}"; then
    echo "RT64 sources have local changes; refusing to patch them." >&2
    exit 1
fi
if ! git -C "$plume_path" diff --quiet -- plume_apple.h plume_apple.mm plume_metal.cpp; then
    echo "Plume sources have local changes; refusing to patch them." >&2
    exit 1
fi

sdk_applied=0
embedded_applied=0
plume_applied=0
plume_macos_pacing_applied=0
cleanup() {
    if [ "$plume_macos_pacing_applied" -eq 1 ]; then
        patch -R -p1 -l --batch --no-backup-if-mismatch -d "$plume_path" < "$plume_macos_pacing_patch" >/dev/null
    fi
    if [ "$plume_applied" -eq 1 ]; then
        patch -R -p1 -l --batch --no-backup-if-mismatch -d "$plume_path" < "$plume_patch" >/dev/null
    fi
    if [ "$embedded_applied" -eq 1 ]; then
        patch -R -p1 -l --batch --no-backup-if-mismatch -d "$rt64_path" < "$rt64_embedded_patch" >/dev/null
    fi
    if [ "$sdk_applied" -eq 1 ]; then
        patch -R -p1 -l --batch --no-backup-if-mismatch -d "$rt64_path" < "$rt64_sdk_patch" >/dev/null
    fi
}
trap cleanup EXIT

patch -p1 -l --batch --no-backup-if-mismatch -d "$rt64_path" < "$rt64_sdk_patch" >/dev/null
sdk_applied=1
patch -p1 -l --batch --no-backup-if-mismatch -d "$rt64_path" < "$rt64_embedded_patch" >/dev/null
embedded_applied=1
patch -p1 -l --batch --no-backup-if-mismatch -d "$plume_path" < "$plume_patch" >/dev/null
plume_applied=1
patch -p1 -l --batch --no-backup-if-mismatch -d "$plume_path" < "$plume_macos_pacing_patch" >/dev/null
plume_macos_pacing_applied=1

host_build="$output_root/rt64-host"
cmake --fresh -S "$rt64_path" -B "$host_build" -G Ninja \
    -DRT64_STATIC=ON -DCMAKE_BUILD_TYPE=Release

shader_targets="$output_root/rt64-shader-targets.txt"
ninja -C "$host_build" -t targets all |
    awk -F: '/^src\/shaders\/.*\.(metal|spirv|rw)\.c: CUSTOM_COMMAND$/ {print $1}' |
    LC_ALL=C sort -u > "$shader_targets"
test "$(wc -l < "$shader_targets" | tr -d ' ')" -eq 113
xargs ninja -C "$host_build" < "$shader_targets"

file_to_c="$host_build/src/tools/file_to_c/file_to_c"
test -x "$file_to_c" || { echo "RT64 file_to_c generator was not built." >&2; exit 1; }

generated="$output_root/rt64-generated-macos"
rm -rf "$generated"
mkdir -p "$generated/src/shaders"
rsync -a \
    --include '*/' \
    --include '*.spirv.c' --include '*.spirv.h' \
    --include '*.rw.c' --include '*.rw.h' \
    --exclude '*' \
    "$host_build/" "$generated/"

while IFS= read -r source; do
    relative=${source#"$host_build/"}
    output_base="$generated/$relative"
    host_blob_c="$source.c"
    array_name=$(awk '/extern const char/ {gsub("\\[.*", "", $4); print $4; exit}' "$host_blob_c")
    test -n "$array_name" || { echo "Missing shader array name: $host_blob_c" >&2; exit 1; }
    run_xcrun -sdk macosx metal -c "$source" -o "$output_base.air"
    run_xcrun -sdk macosx metallib "$output_base.air" -o "$output_base.metallib"
    "$file_to_c" "$output_base.metallib" "$array_name" "$output_base.c" "$output_base.h"
done < <(find "$host_build/src/shaders" -type f -name '*.metal' | LC_ALL=C sort)

test "$(find "$generated" -type f -name '*.metal.c' | wc -l | tr -d ' ')" -eq 56
test "$(find "$generated" -type f -name '*.spirv.c' | wc -l | tr -d ' ')" -eq 56
test "$(find "$generated" -type f -name '*.rw.c' | wc -l | tr -d ' ')" -eq 1

rt64_build="$output_root/rt64-macos"
rt64_prefix_flags="-ffile-prefix-map=$rt64_path=RT64 -ffile-prefix-map=$generated=RT64Generated -ffile-prefix-map=$repo_root=GoldenPad"
cmake --fresh -S "$rt64_path" -B "$rt64_build" -G Ninja \
    -DCMAKE_SYSTEM_NAME=Darwin \
    -DCMAKE_OSX_SYSROOT=macosx \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS_RELEASE="$rt64_prefix_flags" \
    -DCMAKE_CXX_FLAGS_RELEASE="$rt64_prefix_flags" \
    -DRT64_STATIC=ON \
    -DRT64_EMBEDDED_APPLE=ON \
    -DRT64_PREGENERATED_SHADER_DIR="$generated" \
    -DRT64_EMBEDDED_APPLE_SOURCE_DIR="$shim_path"
cmake --build "$rt64_build" --target rt64 --parallel 8

artifact_dir="$output_root/rt64"
mkdir -p "$artifact_dir"
cp "$rt64_build/rt64.a" "$artifact_dir/rt64.a"
cp "$rt64_build/src/contrib/plume/libplume.a" "$artifact_dir/libplume.a"
cp "$rt64_build/src/contrib/re-spirv/libre-spirv.a" "$artifact_dir/libre-spirv.a"
cp "$rt64_build/src/contrib/zstd/build/cmake/lib/libzstd.a" "$artifact_dir/libzstd.a"

for archive in "$artifact_dir"/*.a; do
    test "$(lipo -archs "$archive")" = arm64
done
if nm -gU "$runtime_build/librecomp/liblibrecomp.a" \
    "$runtime_build/ultramodern/libultramodern.a" \
    "$runtime_build/librecomp/N64Recomp/libN64Recomp.a" | rg -qi 'sljit|map_jit'; then
    echo "AOT-only runtime unexpectedly contains JIT machinery." >&2
    exit 1
fi

echo "GoldenPad Mac dependencies ready:"
echo "  runtime: $runtime_build"
echo "  RT64:    $artifact_dir"
