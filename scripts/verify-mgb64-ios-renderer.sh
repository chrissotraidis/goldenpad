#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir="${GOLDENPAD_MGB64_SOURCE_DIR:-$repo_root/ref/mgb64}"
bundle_identifier="${GOLDENPAD_BUNDLE_IDENTIFIER:-com.chrissotraidis.goldenpad}"
development_team="${GOLDENPAD_DEVELOPMENT_TEAM:-}"
metal_patch="$repo_root/patches/mgb64-ios-metal.patch"
fast3d_patch="$repo_root/patches/mgb64-ios-fast3d.patch"
if [ -n "$development_team" ]; then
    sim_build="$repo_root/build-mgb64-renderer-simulator-signed"
    device_build="$repo_root/build-mgb64-renderer-device-signed"
else
    sim_build="$repo_root/build-mgb64-renderer-simulator"
    device_build="$repo_root/build-mgb64-renderer-device"
fi
metal_applied=0
fast3d_applied=0

cleanup() {
    cleanup_status=0
    if [ "$fast3d_applied" -eq 1 ]; then
        git -C "$source_dir" apply -R "$fast3d_patch" || cleanup_status=1
    fi
    if [ "$metal_applied" -eq 1 ]; then
        git -C "$source_dir" apply -R "$metal_patch" || cleanup_status=1
    fi
    return "$cleanup_status"
}
trap cleanup EXIT

"$repo_root/scripts/fetch-mgb64.sh"
if [ -n "$(git -C "$source_dir" status --porcelain)" ]; then
    echo "MGB64 checkout is dirty; refusing to patch it." >&2
    exit 1
fi

git -C "$source_dir" apply --check "$metal_patch"
git -C "$source_dir" apply "$metal_patch"
metal_applied=1
git -C "$source_dir" apply --check "$fast3d_patch"
git -C "$source_dir" apply "$fast3d_patch"
fast3d_applied=1

build_app() {
    build_dir=$1
    sdk=$2

    cmake -S "$repo_root" -B "$build_dir" -G Xcode \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_SYSROOT="$sdk" \
        -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DGOLDENPAD_BUNDLE_IDENTIFIER="$bundle_identifier" \
        -DGOLDENPAD_DEVELOPMENT_TEAM="$development_team" \
        -DGOLDENPAD_MGB64_SOURCE_DIR="$source_dir" \
        -DGOLDENPAD_MGB64_RENDERER=ON
    if [ "$sdk" = "iphoneos" ] && [ -n "$development_team" ]; then
        xcodebuild -quiet -jobs 4 -project "$build_dir/GoldenPad.xcodeproj" \
            -target GoldenPad -configuration Release \
            -sdk "$sdk" -destination 'generic/platform=iOS' \
            -allowProvisioningUpdates build
    else
        xcodebuild -quiet -jobs 4 -project "$build_dir/GoldenPad.xcodeproj" \
            -target GoldenPad -configuration Release \
            -sdk "$sdk" CODE_SIGNING_ALLOWED=NO build
    fi
}

build_app "$sim_build" iphonesimulator
build_app "$device_build" iphoneos

for binary in \
    "$sim_build/Release-iphonesimulator/GoldenPad.app/GoldenPad" \
    "$device_build/Release-iphoneos/GoldenPad.app/GoldenPad"
do
    test -f "$binary"
    info_plist=$(dirname "$binary")/Info.plist
    test "$(plutil -extract CFBundleDisplayName raw -o - "$info_plist")" = "GoldenPad Legacy"
    test "$(plutil -extract LSSupportsOpeningDocumentsInPlace raw -o - "$info_plist")" = "true"
    document_types=$(plutil -extract CFBundleDocumentTypes json -o - "$info_plist")
    imported_types=$(plutil -extract UTImportedTypeDeclarations json -o - "$info_plist")
    printf '%s' "$document_types" | grep -q 'com.chrissotraidis.goldenpad.n64-rom'
    printf '%s' "$imported_types" | grep -q 'com.chrissotraidis.goldenpad.n64-rom'
    for extension in z64 v64 n64 rom
    do
        printf '%s' "$imported_types" | grep -q "\"$extension\""
    done
    file "$binary" | grep -q 'Mach-O 64-bit executable arm64'
    for symbol in \
        _gfx_init \
        _gfx_metal_api \
        _goldenpad_mgb64_renderer_initialize \
        _goldenpad_mgb64_renderer_draw_frame \
        _goldenpad_mgb64_deliver_retrace \
        _platformGetMetalLayer \
        _bossEntry \
        _portAudioInit \
        _portAudioFrame \
        _goldenpad_mgb64_start_game \
        _goldenpad_mgb64_game_state \
        _goldenpad_mgb64_set_controller_state \
        _goldenpad_mgb64_audio_render \
        _goldenpad_mgb64_audio_output_probe \
        _goldenpad_mgb64_eeprom_load \
        _goldenpad_mgb64_eeprom_snapshot \
        _goldenpad_mgb64_runtime_state \
        _goldenpad_mgb64_gameplay_state \
        _goldenpad_mgb64_player_vitals \
        _goldenpad_mgb64_request_scripted_mission_success \
        _goldenpad_mgb64_progression_state \
        _goldenpad_mgb64_dam_route_state \
        _goldenpad_mgb64_dam_nav_state \
        _goldenpad_mgb64_set_dam_nav_bungee_mode \
        _goldenpad_mgb64_dam_nav_linked_door_state \
        _goldenpad_mgb64_dam_nav_guard_state \
        _goldenpad_mgb64_queue_controller_buttons \
        _goldenpad_mgb64_request_crouch_toggle \
        _goldenpad_mgb64_frame_stats_set_active \
        _goldenpad_mgb64_frame_stats_snapshot \
        _goldenpad_mgb64_set_fps_overlay \
        _goldenpad_mgb64_dam_nav_padlock_state \
        _goldenpad_mgb64_dam_bungee_state \
        _goldenpad_mgb64_facility_door_state \
        _goldenpad_mgb64_facility_door155_state \
        _alBnkfNew \
        _portAudioPlaySfxDetailed
    do
        nm -gU "$binary" | grep -q "$symbol"
    done
    if nm -u "$binary" | grep -E -q '_SDL_|_gfx_opengl_api|_glGetTexImage|_glReadPixels'; then
        echo "Desktop renderer symbol entered $binary" >&2
        exit 1
    fi
    if otool -L "$binary" | grep -E -q 'SDL|AppKit|OpenGL'; then
        echo "Desktop renderer framework entered $binary" >&2
        exit 1
    fi
    echo "Verified $binary (ARM64, linked MGB64 game/Metal/audio lifecycle)"
done

if [ -n "$development_team" ]; then
    signed_app="$device_build/Release-iphoneos/GoldenPad.app"
    codesign --verify --deep --strict "$signed_app"
    test -f "$signed_app/embedded.mobileprovision"
    actual_bundle_identifier=$(plutil -extract CFBundleIdentifier raw -o - \
        "$signed_app/Info.plist")
    test "$actual_bundle_identifier" = "$bundle_identifier"
    echo "Verified signed device app ($bundle_identifier, team $development_team)."
fi

echo "MGB64 iOS linked game/renderer/audio lifecycle passed."
