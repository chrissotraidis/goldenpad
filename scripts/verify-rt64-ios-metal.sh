#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
rt64_path=${1:-"$repo_root/ref/rt64"}
plume_path="$rt64_path/src/contrib/plume"
rt64_patch="$repo_root/patches/rt64-ios-sdk.patch"
plume_patch="$repo_root/patches/plume-ios-metal.patch"
expected_rt64=5473732a822a4423b5696e7cb18fecc425a59875
expected_plume=d890ac899e505fb30040e037a4037cdeca68f033
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

if ! git -C "$rt64_path" diff --quiet -- CMakeLists.txt; then
    echo "RT64 CMakeLists.txt has local changes; refusing to patch it." >&2
    exit 1
fi

if ! git -C "$plume_path" diff --quiet -- plume_apple.mm plume_metal.cpp; then
    echo "Plume Apple/Metal sources have local changes; refusing to patch them." >&2
    exit 1
fi

probe_root=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-rt64-ios.XXXXXX")
rt64_patch_applied=0
plume_patch_applied=0

cleanup() {
    if [ "$plume_patch_applied" -eq 1 ]; then
        patch -R -p1 -l --batch -d "$plume_path" < "$plume_patch"
    fi
    if [ "$rt64_patch_applied" -eq 1 ]; then
        patch -R -p1 -l --batch -d "$rt64_path" < "$rt64_patch"
    fi
    rm -rf "$probe_root"
}
trap cleanup EXIT

patch -p1 -l --batch -d "$rt64_path" < "$rt64_patch"
rt64_patch_applied=1
patch -p1 -l --batch -d "$plume_path" < "$plume_patch"
plume_patch_applied=1

build_path="$rt64_path/build-goldenpad-ios-metal-probe"
cmake -S "$rt64_path" -B "$build_path" -G Ninja \
    -DRT64_STATIC=ON -DCMAKE_BUILD_TYPE=Release >/dev/null

target_list="$probe_root/metal-targets.txt"
ninja -C "$build_path" -t targets all |
    awk -F: '/^src\/shaders\/.*\.metal: CUSTOM_COMMAND$/ {print $1}' |
    LC_ALL=C sort -u > "$target_list"

expected_shader_count=56
shader_count=$(wc -l < "$target_list" | tr -d ' ')
if [ "$shader_count" -ne "$expected_shader_count" ]; then
    echo "Expected $expected_shader_count RT64 Metal shaders, found $shader_count." >&2
    exit 1
fi

xargs ninja -C "$build_path" < "$target_list" >/dev/null

plume_includes=(
    -I "$plume_path"
    -I "$plume_path/contrib/metal-cpp"
    -I "$plume_path/contrib/volk"
    -I "$plume_path/contrib/Vulkan-Headers/include"
    -I "$plume_path/contrib/VulkanMemoryAllocator/include"
)

for sdk in iphoneos iphonesimulator; do
    sdk_output="$probe_root/$sdk"
    mkdir -p "$sdk_output/shaders"

    while IFS= read -r target; do
        name=${target#src/shaders/}
        source="$build_path/src/shaders/$name"
        xcrun "${metal_toolchain_args[@]}" -sdk "$sdk" metal -c "$source" -o "$sdk_output/shaders/$name.air"
        xcrun "${metal_toolchain_args[@]}" -sdk "$sdk" metallib \
            "$sdk_output/shaders/$name.air" \
            -o "$sdk_output/shaders/$name.metallib"
    done < "$target_list"

    if [ "$sdk" = "iphoneos" ]; then
        target=arm64-apple-ios17.0
    else
        target=arm64-apple-ios17.0-simulator
    fi

    xcrun -sdk "$sdk" clang++ -target "$target" -std=c++17 -fblocks \
        -c "$plume_path/plume_metal.cpp" "${plume_includes[@]}" \
        -o "$sdk_output/plume_metal.o"
    xcrun -sdk "$sdk" clang++ -target "$target" -std=c++17 -fblocks \
        -x objective-c++ -c "$plume_path/plume_apple.mm" "${plume_includes[@]}" \
        -o "$sdk_output/plume_apple.o"
    xcrun -sdk "$sdk" ar rcs "$sdk_output/libplume-metal.a" \
        "$sdk_output/plume_metal.o" "$sdk_output/plume_apple.o"

    metallib_count=$(find "$sdk_output/shaders" -type f -name '*.metallib' | wc -l | tr -d ' ')
    if [ "$metallib_count" -ne "$expected_shader_count" ]; then
        echo "$sdk produced $metallib_count metallibs; expected $expected_shader_count." >&2
        exit 1
    fi

    content_digest=$(
        find "$sdk_output/shaders" -type f -name '*.metallib' -print0 |
            LC_ALL=C sort -z |
            xargs -0 shasum -a 256 |
            awk '{print $1}' |
            shasum -a 256 |
            awk '{print $1}'
    )
    echo "$sdk: $metallib_count shaders; patched Plume ARM64 archive; digest $content_digest"
done

cmake --build "$build_path" --target plume --parallel 8 >/dev/null
echo "RT64 iOS Metal feasibility passed at $expected_rt64."
