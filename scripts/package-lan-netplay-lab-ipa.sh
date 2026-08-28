#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
app_path=${GOLDENPAD_LAN_LAB_APP:-"$repo_root/build-recomp-lan-lab-device/Release-iphoneos/GoldenPadRecompPrototype.app"}
output_path=${GOLDENPAD_LAN_LAB_IPA:-"$repo_root/dist/GoldenPad-LAN-Lab-1-signed.ipa"}

test -d "$app_path" || { echo "Missing LAN Lab app: $app_path" >&2; exit 1; }
bundle_id=$(plutil -extract CFBundleIdentifier raw "$app_path/Info.plist")
test "$bundle_id" = "com.chrissotraidis.goldenpad.lan-lab" || {
    echo "Refusing to package unexpected bundle: $bundle_id" >&2
    exit 1
}
executable_name=$(plutil -extract CFBundleExecutable raw "$app_path/Info.plist")
file "$app_path/$executable_name" | rg -q 'Mach-O 64-bit executable arm64'
codesign --verify --deep --strict "$app_path"
"$repo_root/scripts/check-no-rom-data.sh"

staging=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-lan-lab-ipa.XXXXXX")
trap 'rm -rf "$staging"' EXIT
mkdir -p "$staging/Payload" "$(dirname "$output_path")"
ditto --noqtn "$app_path" "$staging/Payload/GoldenPad LAN Lab.app"
codesign --verify --deep --strict "$staging/Payload/GoldenPad LAN Lab.app"
(
    cd "$staging"
    zip -qry --symlinks "$output_path" Payload
)

unzip -tq "$output_path" >/dev/null
if unzip -Z1 "$output_path" | rg -i '\.(z64|n64|v64|rom|sav|sra|eep|fla)$'; then
    echo "ROM or save-like payload found in LAN Lab IPA." >&2
    exit 1
fi
shasum -a 256 "$output_path" > "$output_path.sha256"
echo "Created: $output_path"
echo "Checksum: $output_path.sha256"
