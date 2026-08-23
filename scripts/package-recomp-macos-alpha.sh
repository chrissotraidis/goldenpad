#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
"$repo_root/scripts/verify-recomp-input-matrix.sh"

app_path=${GOLDENPAD_RECOMP_MAC_APP:-"$repo_root/build-recomp-macos-stable/Release/GoldenPad.app"}
release_name=${GOLDENPAD_RELEASE_NAME:-0.1.0-preview.4}
output_name="GoldenPad-${release_name}-macos-arm64-alpha.zip"
output_path="$repo_root/dist/$output_name"

if [ ! -d "$app_path" ] || [ ! -f "$app_path/Contents/Info.plist" ]; then
  echo "Missing native Mac app: $app_path" >&2
  exit 1
fi

executable_name=$(plutil -extract CFBundleExecutable raw "$app_path/Contents/Info.plist")
executable="$app_path/Contents/MacOS/$executable_name"
if [ ! -f "$executable" ] || ! file "$executable" | grep -q 'Mach-O 64-bit executable arm64'; then
  echo "Mac app does not contain an ARM64 executable." >&2
  exit 1
fi

"$repo_root/scripts/check-no-rom-data.sh"

goldenpad_staging=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-macos-alpha.XXXXXX")
trap 'rm -rf "$goldenpad_staging"' EXIT
staged_app="$goldenpad_staging/GoldenPad.app"
resources="$staged_app/Contents/Resources"
mkdir -p "$repo_root/dist"
ditto --noqtn "$app_path" "$staged_app"

codesign --remove-signature "$staged_app" >/dev/null 2>&1 || true
rm -rf "$staged_app/Contents/_CodeSignature"
mkdir -p "$resources"
cp "$repo_root/Config/ThirdPartyNotices.txt" "$resources/ThirdPartyNotices.txt"
cp "$repo_root/ref/goldeneye64recomp/COPYING" "$resources/COPYING-GPL-3.0.txt"
cp "$repo_root/ref/rt64/LICENSE" "$resources/LICENSE-RT64.txt"
cp "$repo_root/ref/rt64/src/contrib/plume/LICENSE" "$resources/LICENSE-Plume.txt"
cp "$repo_root/ref/rt64/src/contrib/re-spirv/LICENSE" "$resources/LICENSE-re-spirv.txt"
cp "$repo_root/ref/rt64/src/contrib/zstd/LICENSE" "$resources/LICENSE-Zstandard.txt"
cp "$repo_root/ref/goldeneye64recomp/lib/N64ModernRuntime/N64Recomp/LICENSE" "$resources/LICENSE-N64Recomp.txt"
cp "$repo_root/ref/goldeneye64recomp/lib/N64ModernRuntime/N64Recomp/lib/fmt/LICENSE" "$resources/LICENSE-fmt.txt"
cp "$repo_root/ref/goldeneye64recomp/lib/N64ModernRuntime/N64Recomp/lib/rabbitizer/LICENSE" "$resources/LICENSE-Rabbitizer.txt"

find "$staged_app" -exec touch -h -t 198001010000 {} +
codesign --force --deep --sign - --timestamp=none "$staged_app"
codesign --verify --deep --strict "$staged_app"
find "$staged_app" -exec touch -h -t 198001010000 {} +

archive_path="$goldenpad_staging/$output_name"
(
  cd "$goldenpad_staging"
  find GoldenPad.app -print | LC_ALL=C sort | zip -X -y -q "$archive_path" -@
)

"$repo_root/scripts/verify-recomp-macos-alpha.sh" "$archive_path"
mv -f "$archive_path" "$output_path"
(
  cd "$repo_root/dist"
  shasum -a 256 "$output_name" > "$output_name.sha256"
)
echo "Created: $output_path"
echo "Checksum: $output_path.sha256"
