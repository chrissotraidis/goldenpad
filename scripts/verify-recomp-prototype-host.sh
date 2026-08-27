#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_dir=${GOLDENPAD_RECOMP_BUILD_DIR:-"$repo_root/build-recomp-prototype-simulator"}
bundle_identifier=${GOLDENPAD_RECOMP_BUNDLE_IDENTIFIER:-com.chrissotraidis.goldenpad.recomp-prototype}
rt64_archive_dir=${GOLDENPAD_RECOMP_RT64_ARCHIVE_DIR:-}
rt64_source_dir=${GOLDENPAD_RECOMP_RT64_SOURCE_DIR:-}
render_patch="$repo_root/patches/goldeneye64recomp-ios-prototype-render-trace.patch"

if [ "$(grep -Fc 'gDPSetColorImage(gdl++, G_IM_FMT_RGBA, G_IM_SIZ_16b, viGetX(), osViGetCurrentFramebuffer());' "$render_patch")" -ne 2 ]; then
    echo "The GoldenEye skybox patch must restore the current framebuffer in both fill paths." >&2
    exit 1
fi

if ! grep -Fq 'clear_buffer -= SCREEN_WIDTH * SCREEN_HEIGHT;' "$render_patch"; then
    echo "The GoldenEye multiplayer depth clear must use the lower-view depth-image alias." >&2
    exit 1
fi

if [ -n "$rt64_archive_dir" ] && [ -z "$rt64_source_dir" ]; then
    echo "GOLDENPAD_RECOMP_RT64_SOURCE_DIR is required with prototype RT64 archives." >&2
    exit 1
fi

cmake -S "$repo_root" -B "$build_dir" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=iphonesimulator \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DGOLDENPAD_RECOMP_PROTOTYPE=ON \
    -DGOLDENPAD_RECOMP_BUNDLE_IDENTIFIER="$bundle_identifier" \
    -DGOLDENPAD_RECOMP_RT64_ARCHIVE_DIR="$rt64_archive_dir" \
    -DGOLDENPAD_RECOMP_RT64_SOURCE_DIR="$rt64_source_dir"

xcodebuild -quiet -project "$build_dir/GoldenPad.xcodeproj" \
    -target GoldenPadRecompPrototype -configuration Release -sdk iphonesimulator \
    CODE_SIGNING_ALLOWED=NO build

app="$build_dir/Release-iphonesimulator/GoldenPadRecompPrototype.app"
binary="$app/GoldenPadRecompPrototype"
test -f "$binary"
file "$binary" | grep -q 'Mach-O 64-bit executable arm64'
test "$(plutil -extract CFBundleIdentifier raw -o - "$app/Info.plist")" = "$bundle_identifier"
test "$(plutil -extract CFBundleDisplayName raw -o - "$app/Info.plist")" = "GoldenPad"
test -f "$app/ThirdPartyNotices.txt"
for required_symbol in \
    goldenpad_recomp_rt64_initialize \
    goldenpad_recomp_rt64_shutdown \
    goldenpad_recomp_set_msaa_enabled \
    goldenpad_recomp_set_resolution_mode \
    goldenpad_recomp_set_three_point_filtering \
    goldenpad_recomp_set_controller_state \
    goldenpad_recomp_set_right_analog \
    goldenpad_recomp_set_controller_connected \
    goldenpad_recomp_set_two_player_test_mode \
    goldenpad_recomp_set_four_player_test_mode \
    goldenpad_recomp_set_determinism_probe_enabled \
    goldenpad_recomp_deterministic_clock_enabled \
    goldenpad_recomp_deterministic_clock_ticks \
    goldenpad_recomp_set_fire_rate_probe_enabled \
    goldenpad_recomp_queue_touch_look \
    goldenpad_recomp_gameplay_input_active \
    goldenpad_recomp_current_control_style \
    goldenpad_recomp_request_crouch_toggle \
    goldenpad_recomp_request_return_to_title \
    goldenpad_recomp_note_transient_inactive \
    goldenpad_recomp_previous_session_ended_unexpectedly
do
    nm -gU "$binary" | grep -q "_$required_symbol"
done
for required_text in \
    'Edit touch layout' \
    'Edit Touch Controls' \
    'Drag directly on the game' \
    'opacity sliders at the top' \
    'iPhone Touch Layout' \
    'iPad Touch Layout' \
    'recomp.touchLayout.phone.v1' \
    'recomp.touchLayout.tablet.v1' \
    'Add left-side Fire button' \
    'Additional Fire' \
    'Choose Original ROM' \
    'Your original file will not be changed.' \
    'The file you select stays in its original location.' \
    'Preview 2 movement' \
    'Sidestep with left/right' \
    'Per-player styles; adapter paused' \
    'Experimental four-player render test'
do
    strings "$binary" | grep -Fq "$required_text"
done
grep -Fq '@AppStorage("recomp.unlockAllMissions") private var unlockAllMissions = false' \
    "$repo_root/Sources/RecompPrototypeApp.swift"
grep -Fq '@AppStorage("recomp.movementMode") private var movementMode = RecompPrototypeMovementMode.previewTwo.rawValue' \
    "$repo_root/Sources/RecompPrototypeApp.swift"
if find "$app" -type f \( \
    -iname '*.z64' -o -iname '*.v64' -o -iname '*.n64' -o \
    -iname '*.rom' -o -iname '*.eep' -o -iname '*.sav' \
\) | grep -q .; then
    echo "Retail ROM or save data entered the isolated host app." >&2
    exit 1
fi
if strings "$binary" | grep -Eq '/Users/|/private/tmp'; then
    echo "A private local path entered the isolated host binary." >&2
    exit 1
fi
if nm -gU "$binary" | grep -q '_goldenpad_mgb64_'; then
    echo "Production MGB64 symbols entered the isolated prototype." >&2
    exit 1
fi
if [ -n "$rt64_archive_dir" ] && ! nm -gU "$binary" | grep -q _goldenpad_recomp_rt64_initialize; then
    echo "The configured RT64 bridge did not enter the prototype binary." >&2
    exit 1
fi

echo "GoldenPadRecompPrototype host passed (ARM64 Simulator, $bundle_identifier)."
