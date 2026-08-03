#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir="${GOLDENPAD_MGB64_SOURCE_DIR:-$repo_root/ref/mgb64}"
sim_build="$repo_root/build-mgb64-core-simulator"
device_build="$repo_root/build-mgb64-core-device"

"$repo_root/scripts/fetch-mgb64.sh"
python3 "$source_dir/tools/check_native_sdk_surface.py" --repo-root "$source_dir"

cmake -S "$repo_root" -B "$sim_build" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=iphonesimulator \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DGOLDENPAD_MGB64_SOURCE_DIR="$source_dir"
xcodebuild -project "$sim_build/GoldenPad.xcodeproj" \
    -target GoldenPad -configuration Release \
    -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build

cmake -S "$repo_root" -B "$device_build" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=iphoneos \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DGOLDENPAD_MGB64_SOURCE_DIR="$source_dir"
xcodebuild -project "$device_build/GoldenPad.xcodeproj" \
    -target GoldenPad -configuration Release \
    -sdk iphoneos CODE_SIGNING_ALLOWED=NO build

for archive in \
    "$sim_build/Release-iphonesimulator/libgoldenpad_mgb64_core.a" \
    "$device_build/Release-iphoneos/libgoldenpad_mgb64_core.a"
do
    test -f "$archive"
    xcrun lipo -info "$archive"
    objects=$(xcrun ar -t "$archive" | grep -c '\.o$')
    if [ "$objects" -ne 210 ]; then
        echo "Unexpected MGB64 core archive: $objects objects" >&2
        exit 1
    fi
    if xcrun ar -t "$archive" | grep -E '(^|/)(libultra|libultrare)(/|$)' >/dev/null; then
        echo "SDK-lineage implementation object entered $archive" >&2
        exit 1
    fi
    nm -gU "$archive" | grep -q '_sins'
    nm -gU "$archive" | grep -q '_ge007_sprintf'
    nm -gU "$archive" | grep -q '_watchInvPerspAspect'
    nm -gU "$archive" | grep -q '__rarewarelogoSegmentRomStart'
    nm -gU "$archive" | grep -q '_modelConvertN64Binary'
    nm -gU "$archive" | grep -q '_setupPnamesResolve'
    echo "Verified $archive ($objects objects)"
done

for binary in \
    "$sim_build/Release-iphonesimulator/GoldenPad.app/GoldenPad" \
    "$device_build/Release-iphoneos/GoldenPad.app/GoldenPad"
do
    test -f "$binary"
    file "$binary" | grep -q 'Mach-O 64-bit executable arm64'
    nm -gU "$binary" | grep -q '_goldenpad_mgb64_core_identity'
    nm -gU "$binary" | grep -q '_goldenpad_mgb64_core_probe'
    nm -gU "$binary" | grep -q '_goldenpad_mgb64_install_validated_rom'
    nm -gU "$binary" | grep -q '_goldenpad_mgb64_clear_rom'
    nm -gU "$binary" | grep -q '_goldenpad_mgb64_file_table_ready'
    nm -gU "$binary" | grep -q '_goldenpad_mgb64_prepare_scheduler'
    nm -gU "$binary" | grep -q '_goldenpad_mgb64_scheduler_initialize'
    nm -gU "$binary" | grep -q '_osCreateScheduler'
    nm -gU "$binary" | grep -q '_osScGetCmdQ'
    nm -gU "$binary" | grep -q '_platformPatchFileTable'
    nm -gU "$binary" | grep -q '_randomGetNext'
    nm -gU "$binary" | grep -q '_randomSetSeed'
    nm -gU "$binary" | grep -q '_guNormalize'
    nm -gU "$binary" | grep -q '_sins'
    nm -gU "$binary" | grep -q '_coss'
    nm -gU "$binary" | grep -q '_aimBoneArg0Proceeds'
    nm -gU "$binary" | grep -q '_watchInvPerspAspect'
    nm -gU "$binary" | grep -q '__rarewarelogoSegmentRomStart'
    nm -gU "$binary" | grep -q '_goldenpad_mgb64_mobile_config_probe'
    nm -gU "$binary" | grep -q '_g_pcFovY'
    nm -gU "$binary" | grep -q '_goldenpad_mgb64_mobile_legacy_data_probe'
    nm -gU "$binary" | grep -q '_goldenpad_mgb64_mobile_host_probe'
    nm -gU "$binary" | grep -q '_goldenpad_mgb64_mobile_os_probe'
    nm -gU "$binary" | grep -q '_osSetTimer'
    nm -gU "$binary" | grep -q '_osEepromLongWrite'
    nm -gU "$binary" | grep -q '_platformOverlayWantsInput'
    nm -gU "$binary" | grep -q '_modelConvertFreeAll'
    nm -gU "$binary" | grep -q '_platformApplyRadialDeadzone'
    nm -gU "$binary" | grep -q '_setupPnamesTableOffset'
    nm -gU "$binary" | grep -q '_portWeaponEquipCue'
    nm -gU "$binary" | grep -q '_pcStageSlugForLevelId'
    strings "$binary" | grep -q \
        'MGB64 game core cd9b58f5f91291579b8e551aa925aab000d311cf'
    if otool -L "$binary" | grep -Ei 'SDL|AppKit|OpenGL' >/dev/null; then
        echo "Desktop dependency entered $binary" >&2
        exit 1
    fi
    echo "Verified linked MGB64 probe in $binary"
done
