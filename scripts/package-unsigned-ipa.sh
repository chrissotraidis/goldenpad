#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
app_path="$repo_root/build-mgb64-renderer-device/Release-iphoneos/GoldenPad.app"
output_path="$repo_root/dist/GoldenPad-0.1.0-unsigned.ipa"
executable="$app_path/GoldenPad"

if [ ! -d "$app_path" ] || [ ! -f "$executable" ]; then
  echo "Missing game-bearing device app. Run ./scripts/verify-mgb64-ios-renderer.sh first." >&2
  exit 1
fi

if ! file "$executable" | grep -q 'Mach-O 64-bit executable arm64'; then
  echo "Refusing to package a non-ARM64 device executable." >&2
  exit 1
fi

if codesign -dv "$app_path" >/dev/null 2>&1; then
  echo "Refusing to label a signed app as unsigned." >&2
  exit 1
fi

for symbol in _bossEntry _gfx_init _gfx_run_dl; do
  if ! nm -gU "$executable" |
    awk -v required="$symbol" '$3 == required { found = 1 } END { exit !found }'; then
    echo "Refusing to package an app without required game symbol: $symbol" >&2
    exit 1
  fi
done

"$repo_root/scripts/check-no-rom-data.sh"

goldenpad_staging=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-ipa.XXXXXX")
trap 'rm -rf "$goldenpad_staging"' EXIT

mkdir -p "$goldenpad_staging/Payload" "$repo_root/dist"
ditto --noqtn "$app_path" "$goldenpad_staging/Payload/GoldenPad.app"
find "$goldenpad_staging/Payload" -exec touch -h -t 198001010000 {} +

archive_path="$goldenpad_staging/GoldenPad-0.1.0-unsigned.ipa"
(
  cd "$goldenpad_staging"
  find Payload -print | LC_ALL=C sort | zip -X -q "$archive_path" -@
)

"$repo_root/scripts/verify-unsigned-ipa.sh" --game-core "$archive_path"
mv -f "$archive_path" "$output_path"
echo "Created: $output_path"
