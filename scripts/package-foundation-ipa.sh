#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
app_path="$repo_root/build-ios-device/Release-iphoneos/GoldenPad.app"
output_path="$repo_root/dist/GoldenPad-0.1.0-foundation-unsigned.ipa"

if [ ! -d "$app_path" ] || [ ! -f "$app_path/GoldenPad" ]; then
  echo "Missing unsigned device app. Build it with docs/BUILDING.md first." >&2
  exit 1
fi

if ! file "$app_path/GoldenPad" | grep -q 'Mach-O 64-bit executable arm64'; then
  echo "Refusing to package a non-ARM64 device executable." >&2
  exit 1
fi

if codesign -dv "$app_path" >/dev/null 2>&1; then
  echo "Refusing to label a signed app as unsigned." >&2
  exit 1
fi

"$repo_root/scripts/check-no-rom-data.sh"

goldenpad_staging=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-ipa.XXXXXX")
trap 'rm -rf "$goldenpad_staging"' EXIT

mkdir -p "$goldenpad_staging/Payload" "$repo_root/dist"
ditto --noqtn "$app_path" "$goldenpad_staging/Payload/GoldenPad.app"
find "$goldenpad_staging/Payload" -exec touch -h -t 198001010000 {} +

if [ -e "$output_path" ]; then
  rm -f "$output_path"
fi

(
  cd "$goldenpad_staging"
  find Payload -print | LC_ALL=C sort | zip -X -q "$output_path" -@
)

"$repo_root/scripts/verify-unsigned-ipa.sh" "$output_path"
echo "Created: $output_path"
