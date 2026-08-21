#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_dir=${GOLDENPAD_RECOMP_BUILD_DIR:-"$repo_root/build-recomp-prototype-simulator"}
bundle_identifier=${GOLDENPAD_RECOMP_BUNDLE_IDENTIFIER:-com.chrissotraidis.goldenpad.recomp-prototype}
rt64_archive_dir=${GOLDENPAD_RECOMP_RT64_ARCHIVE_DIR:-}
rt64_source_dir=${GOLDENPAD_RECOMP_RT64_SOURCE_DIR:-}

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
    goldenpad_recomp_queue_touch_look \
    goldenpad_recomp_request_crouch_toggle \
    goldenpad_recomp_request_return_to_title \
    goldenpad_recomp_note_transient_inactive \
    goldenpad_recomp_previous_session_ended_unexpectedly
do
    nm -gU "$binary" | grep -q "_$required_symbol"
done
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
