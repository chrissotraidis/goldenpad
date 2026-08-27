#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 DEVICE_UDID APP_BUNDLE ROM_PATH OUTPUT_TRACE" >&2
    exit 2
fi

device_udid=$1
app_bundle=$2
rom_path=$3
output_trace=$4
bundle_id=com.chrissotraidis.goldenpad.determinism

test -d "$app_bundle" || { echo "Missing app bundle: $app_bundle" >&2; exit 2; }
test -f "$rom_path" || { echo "Missing converted ROM: $rom_path" >&2; exit 2; }
test ! -e "$output_trace" || { echo "Refusing to overwrite: $output_trace" >&2; exit 2; }

actual_bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_bundle/Info.plist")
test "$actual_bundle_id" = "$bundle_id" || {
    echo "Refusing non-experiment bundle ID: $actual_bundle_id" >&2
    exit 2
}
rom_size=$(stat -f '%z' "$rom_path")
test "$rom_size" = 12653664 || {
    echo "Unexpected converted ROM size: $rom_size" >&2
    exit 2
}

xcrun simctl boot "$device_udid" 2>/dev/null || true
xcrun simctl bootstatus "$device_udid" -b
xcrun simctl terminate "$device_udid" "$bundle_id" 2>/dev/null || true
xcrun simctl uninstall "$device_udid" "$bundle_id" 2>/dev/null || true
xcrun simctl install "$device_udid" "$app_bundle"
container=$(xcrun simctl get_app_container "$device_udid" "$bundle_id" data)
cp "$rom_path" "$container/Documents/GoldenEye_TLBFREE.z64"
xcrun simctl launch "$device_udid" "$bundle_id" --netplay-determinism-probe >/dev/null

trace="$container/Library/Application Support/GoldenPadRecomp/Logs/goldenpad-determinism-trace-v1.log"
for _ in $(seq 1 180); do
    if [ -f "$trace" ] && rg -q '^COMPLETE poll=3600$' "$trace"; then
        cp "$trace" "$output_trace"
        xcrun simctl terminate "$device_udid" "$bundle_id" 2>/dev/null || true
        echo "Determinism trace: $output_trace"
        exit 0
    fi
    sleep 1
done

xcrun simctl terminate "$device_udid" "$bundle_id" 2>/dev/null || true
echo "Probe did not complete within 180 seconds: $trace" >&2
exit 1
