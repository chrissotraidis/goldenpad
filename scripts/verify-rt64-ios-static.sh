#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
rt64_path=${1:-"$repo_root/ref/rt64"}
plume_path="$rt64_path/src/contrib/plume"
rt64_sdk_patch="$repo_root/patches/rt64-ios-sdk.patch"
rt64_embedded_patch="$repo_root/patches/rt64-ios-embedded.patch"
plume_patch="$repo_root/patches/plume-ios-metal.patch"
plume_query_patch="$repo_root/patches/plume-ios-simulator-query.patch"
simulator_resource_patch="$repo_root/patches/rt64-ios-simulator-resource-limits.patch"
shim_path="$repo_root/Support/RT64"
link_probe="$shim_path/rt64_link_probe.cpp"
expected_rt64=5473732a822a4423b5696e7cb18fecc425a59875
expected_plume=d890ac899e505fb30040e037a4037cdeca68f033
expected_shader_targets=113
expected_metal_shaders=56
expected_rt64_members=210
expected_closure_members=246
expected_metal_target=apple-ios17.0.0
artifact_root=${GOLDENPAD_RT64_ARTIFACT_DIR:-}
simulator_resource_limits=${GOLDENPAD_RT64_SIMULATOR_RESOURCE_LIMITS:-OFF}
metal_toolchain=${GOLDENPAD_METAL_TOOLCHAIN:-}
metal_toolchain_args=()
if [ -n "$metal_toolchain" ]; then
    metal_toolchain_args=(--toolchain "$metal_toolchain")
fi

if [ ! -d "$rt64_path/.git" ] || [ ! -f "$plume_path/plume_metal.cpp" ]; then
    echo "Expected the pinned RT64 checkout at: $rt64_path" >&2
    exit 1
fi

if [ "$(git -C "$rt64_path" rev-parse HEAD)" != "$expected_rt64" ]; then
    echo "RT64 checkout is not at the documented commit: $expected_rt64" >&2
    exit 1
fi

if [ "$(git -C "$plume_path" rev-parse HEAD)" != "$expected_plume" ]; then
    echo "Plume checkout is not at the documented commit: $expected_plume" >&2
    exit 1
fi

rt64_patch_targets=(
    CMakeLists.txt
    src/apple/rt64_apple.mm
    src/hle/rt64_application.cpp
    src/hle/rt64_application_window.h
    src/hle/rt64_state.cpp
)

if ! git -C "$rt64_path" diff --quiet -- "${rt64_patch_targets[@]}"; then
    echo "RT64 embedded-build sources have local changes; refusing to patch them." >&2
    exit 1
fi

if ! git -C "$plume_path" diff --quiet -- plume_apple.mm plume_metal.cpp; then
    echo "Plume Apple/Metal sources have local changes; refusing to patch them." >&2
    exit 1
fi

if [ "$simulator_resource_limits" = "ON" ] && ! git -C "$rt64_path" diff --quiet -- src/render/rt64_descriptor_sets.h src/render/rt64_shader_library.cpp src/shaders/FbRendererCommon.hlsli src/shaders/TextureSampler.hlsli; then
    echo "RT64 Simulator resource-limit sources have local changes; refusing to patch them." >&2
    exit 1
fi

probe_root=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-rt64-static.XXXXXX")
rt64_sdk_patch_applied=0
rt64_embedded_patch_applied=0
plume_patch_applied=0
plume_query_patch_applied=0
simulator_resource_patch_applied=0

cleanup() {
    if [ "$simulator_resource_patch_applied" -eq 1 ]; then
        git -C "$rt64_path" apply --reverse "$simulator_resource_patch" >/dev/null
    fi
    if [ "$plume_query_patch_applied" -eq 1 ]; then
        patch -R -p1 -l --batch -d "$plume_path" < "$plume_query_patch" >/dev/null
    fi
    if [ "$plume_patch_applied" -eq 1 ]; then
        patch -R -p1 -l --batch -d "$plume_path" < "$plume_patch" >/dev/null
    fi
    if [ "$rt64_embedded_patch_applied" -eq 1 ]; then
        patch -R -p1 -l --batch -d "$rt64_path" < "$rt64_embedded_patch" >/dev/null
    fi
    if [ "$rt64_sdk_patch_applied" -eq 1 ]; then
        patch -R -p1 -l --batch -d "$rt64_path" < "$rt64_sdk_patch" >/dev/null
    fi
    rm -f \
        "$rt64_path/src/apple/rt64_apple.mm.orig" \
        "$plume_path/plume_metal.cpp.orig"
    rm -rf "$probe_root"
}
trap cleanup EXIT

patch -p1 -l --batch -d "$rt64_path" < "$rt64_sdk_patch" >/dev/null
rt64_sdk_patch_applied=1
patch -p1 -l --batch -d "$rt64_path" < "$rt64_embedded_patch" >/dev/null
rt64_embedded_patch_applied=1
patch -p1 -l --batch -d "$plume_path" < "$plume_patch" >/dev/null
plume_patch_applied=1
patch -p1 -l --batch -d "$plume_path" < "$plume_query_patch" >/dev/null
plume_query_patch_applied=1
if [ "$simulator_resource_limits" = "ON" ]; then
    git -C "$rt64_path" apply "$simulator_resource_patch"
    simulator_resource_patch_applied=1
fi

host_build="$probe_root/host"
cmake -S "$rt64_path" -B "$host_build" -G Ninja \
    -DRT64_STATIC=ON -DCMAKE_BUILD_TYPE=Release >/dev/null

shader_targets="$probe_root/shader-targets.txt"
ninja -C "$host_build" -t targets all |
    awk -F: '/^src\/shaders\/.*\.(metal|spirv|rw)\.c: CUSTOM_COMMAND$/ {print $1}' |
    LC_ALL=C sort -u > "$shader_targets"

shader_target_count=$(wc -l < "$shader_targets" | tr -d ' ')
if [ "$shader_target_count" -ne "$expected_shader_targets" ]; then
    echo "Expected $expected_shader_targets generated shader sources, found $shader_target_count." >&2
    exit 1
fi

shader_build_log="$probe_root/shader-build.log"
if ! xargs ninja -C "$host_build" < "$shader_targets" >"$shader_build_log" 2>&1; then
    rg -n 'FAILED:|error:' "$shader_build_log" | tail -n 40 >&2 || true
    tail -n 120 "$shader_build_log" >&2
    exit 1
fi

metal_sources="$probe_root/metal-sources.txt"
find "$host_build/src/shaders" -type f -name '*.metal' | LC_ALL=C sort > "$metal_sources"
metal_source_count=$(wc -l < "$metal_sources" | tr -d ' ')
if [ "$metal_source_count" -ne "$expected_metal_shaders" ]; then
    echo "Expected $expected_metal_shaders generated MSL sources, found $metal_source_count." >&2
    exit 1
fi

file_to_c="$host_build/src/tools/file_to_c/file_to_c"
if [ ! -x "$file_to_c" ]; then
    echo "Host file_to_c generator was not built." >&2
    exit 1
fi

for sdk in iphoneos iphonesimulator; do
    if [ "$sdk" = iphoneos ]; then
        target=arm64-apple-ios17.0
        metal_target=air64-apple-ios17.0
        expected_sdk_metal_target="$expected_metal_target"
    else
        target=arm64-apple-ios17.0-simulator
        metal_target=air64-apple-ios17.0-simulator
        expected_sdk_metal_target="$expected_metal_target-simulator"
    fi

    generated="$probe_root/generated-$sdk"
    build="$probe_root/build-$sdk"
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
        if [ -z "$array_name" ]; then
            echo "Could not read the generated array name from: $host_blob_c" >&2
            exit 1
        fi
        xcrun "${metal_toolchain_args[@]}" -sdk "$sdk" metal \
            -target "$metal_target" \
            -c "$source" -o "$output_base.air"
        xcrun "${metal_toolchain_args[@]}" -sdk "$sdk" metallib "$output_base.air" -o "$output_base.metallib"
        metal_targets=$(strings "$output_base.metallib" | sed -E -n 's/.*(air64_v[[:alnum:]_.-]*apple-ios[0-9.]+(-simulator)?).*/\1/p' | LC_ALL=C sort -u)
        if ! printf '%s\n' "$metal_targets" | grep -Eq "^air64_v[[:alnum:]_.-]*${expected_sdk_metal_target}$"; then
            echo "$sdk Metal library has the wrong deployment target: $output_base.metallib" >&2
            printf '%s\n' "$metal_targets" >&2
            exit 1
        fi
        unexpected_metal_targets=$(printf '%s\n' "$metal_targets" | grep -Ev "^air64_v[[:alnum:]_.-]*${expected_sdk_metal_target}$" || true)
        if [ -n "$unexpected_metal_targets" ]; then
            echo "$sdk Metal library contains unexpected deployment targets: $output_base.metallib" >&2
            printf '%s\n' "$unexpected_metal_targets" >&2
            exit 1
        fi
        "$file_to_c" "$output_base.metallib" "$array_name" \
            "$output_base.c" "$output_base.h"
    done < "$metal_sources"

    generated_metal_count=$(find "$generated" -type f -name '*.metal.c' | wc -l | tr -d ' ')
    generated_spirv_count=$(find "$generated" -type f -name '*.spirv.c' | wc -l | tr -d ' ')
    generated_rw_count=$(find "$generated" -type f -name '*.rw.c' | wc -l | tr -d ' ')
    if [ "$generated_metal_count" -ne 56 ] || [ "$generated_spirv_count" -ne 56 ] || [ "$generated_rw_count" -ne 1 ]; then
        echo "$sdk generated an incomplete shader cache: MSL=$generated_metal_count SPIR-V=$generated_spirv_count preprocessed=$generated_rw_count" >&2
        exit 1
    fi

    cmake -S "$rt64_path" -B "$build" -G Ninja \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_SYSROOT="$sdk" \
        -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0 \
        -DCMAKE_BUILD_TYPE=Release \
        -DRT64_STATIC=ON \
        -DRT64_EMBEDDED_APPLE=ON \
        -DRT64_PREGENERATED_SHADER_DIR="$generated" \
        -DRT64_EMBEDDED_APPLE_SOURCE_DIR="$shim_path" >/dev/null

    build_log="$probe_root/$sdk-build.log"
    if ! cmake --build "$build" --target rt64 --parallel 8 >"$build_log" 2>&1; then
        rg -n 'FAILED:|error:' "$build_log" | tail -n 40 >&2 || true
        tail -n 120 "$build_log" >&2
        exit 1
    fi

    archives=(
        "$build/rt64.a"
        "$build/src/contrib/plume/libplume.a"
        "$build/src/contrib/re-spirv/libre-spirv.a"
        "$build/src/contrib/zstd/build/cmake/lib/libzstd.a"
    )
    for archive in "${archives[@]}"; do
        if [ ! -f "$archive" ]; then
            echo "$sdk did not produce expected archive: $archive" >&2
            exit 1
        fi
    done

    if ! xcrun -sdk "$sdk" nm -gU "${archives[0]}" |
        rg '_goldenpad_rt64_depth_format_rebuild_stats$' >/dev/null; then
        echo "$sdk RT64 archive does not export the Preview 6 depth-format rebuild counter." >&2
        exit 1
    fi

    rt64_members=$(xcrun -sdk "$sdk" ar -t "${archives[0]}" | wc -l | tr -d ' ')
    closure_members=0
    for archive in "${archives[@]}"; do
        member_count=$(xcrun -sdk "$sdk" ar -t "$archive" | wc -l | tr -d ' ')
        closure_members=$((closure_members + member_count))
    done
    if [ "$rt64_members" -ne "$expected_rt64_members" ] || [ "$closure_members" -ne "$expected_closure_members" ]; then
        echo "$sdk archive membership changed: RT64=$rt64_members closure=$closure_members" >&2
        exit 1
    fi

    executable="$probe_root/$sdk-link-probe"
    link_args=()
    for archive in "${archives[@]}"; do
        link_args+=( -Wl,-force_load,"$archive" )
    done
    xcrun -sdk "$sdk" clang++ -target "$target" "$link_probe" \
        "${link_args[@]}" \
        -framework Metal -framework QuartzCore -framework CoreGraphics \
        -framework Foundation -framework UIKit \
        -o "$executable"

    if xcrun -sdk "$sdk" nm -u "$executable" | rg -q 'SDL|NFD|AppKit|IOKit|X11|vkCreateMacOSSurface'; then
        echo "$sdk force-loaded closure retains a desktop-only undefined symbol." >&2
        xcrun -sdk "$sdk" nm -u "$executable" | rg 'SDL|NFD|AppKit|IOKit|X11|vkCreateMacOSSurface' >&2
        exit 1
    fi

    architecture=$(lipo -archs "$executable")
    if [ "$architecture" != arm64 ]; then
        echo "$sdk link probe has unexpected architecture: $architecture" >&2
        exit 1
    fi

    archive_digest=$(shasum -a 256 "${archives[0]}" | awk '{print $1}')
    probe_digest=$(shasum -a 256 "$executable" | awk '{print $1}')
    dependencies=$(otool -L "$executable" | tail -n +2 | awk '{print $1}' | paste -sd, -)
    if [ -n "$artifact_root" ]; then
        artifact_sdk="$artifact_root/$sdk"
        mkdir -p "$artifact_sdk"
        cp "${archives[0]}" "$artifact_sdk/rt64.a"
        cp "${archives[1]}" "$artifact_sdk/libplume.a"
        cp "${archives[2]}" "$artifact_sdk/libre-spirv.a"
        cp "${archives[3]}" "$artifact_sdk/libzstd.a"
    fi
    echo "$sdk: $rt64_members RT64 members; $closure_members force-loaded members; arm64"
    echo "$sdk: RT64 $archive_digest; link probe $probe_digest"
    echo "$sdk: dependencies $dependencies"
done

echo "RT64 embedded Apple static-library verification passed at $expected_rt64."
if [ -n "$artifact_root" ]; then
    echo "Verified archives copied to $artifact_root."
fi
