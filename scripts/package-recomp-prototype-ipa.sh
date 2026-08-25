#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
"$repo_root/scripts/verify-recomp-input-matrix.sh"

app_path=${GOLDENPAD_RECOMP_APP:-"$repo_root/build-recomp-prototype-device/Release-iphoneos/GoldenPadRecompPrototype.app"}
release_name=${GOLDENPAD_RELEASE_NAME:-0.1.0-preview.7}
reference_source=${GOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR:-"$repo_root/ref/goldeneye64recomp"}
rt64_source=${GOLDENPAD_RECOMP_RT64_SOURCE_DIR:-"$repo_root/ref/rt64"}
output_name="GoldenPad-${release_name}-unsigned.ipa"
output_path="$repo_root/dist/$output_name"

if [ ! -d "$app_path" ]; then
  echo "Missing primary device app: $app_path" >&2
  exit 1
fi

executable_name=$(plutil -extract CFBundleExecutable raw "$app_path/Info.plist")
executable="$app_path/$executable_name"
if [ ! -f "$executable" ] || ! file "$executable" | grep -q 'Mach-O 64-bit executable arm64'; then
  echo "Primary app does not contain an ARM64 device executable." >&2
  exit 1
fi

"$repo_root/scripts/check-no-rom-data.sh"

goldenpad_staging=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-recomp-ipa.XXXXXX")
trap 'rm -rf "$goldenpad_staging"' EXIT
staged_app="$goldenpad_staging/Payload/GoldenPad.app"
mkdir -p "$goldenpad_staging/Payload" "$repo_root/dist"
ditto --noqtn "$app_path" "$staged_app"

# Public preview packages contain neither developer signing material nor the
# developer's provisioning profile. People must re-sign for their own device.
codesign --remove-signature "$staged_app" >/dev/null 2>&1 || true
rm -rf "$staged_app/_CodeSignature" "$staged_app/SC_Info"
rm -f "$staged_app/embedded.mobileprovision"
if ! plutil -extract UIFileSharingEnabled raw "$staged_app/Info.plist" >/dev/null 2>&1; then
  plutil -insert UIFileSharingEnabled -bool true "$staged_app/Info.plist"
fi

# Stage the current notice and exact upstream license texts into the IPA.
cp "$repo_root/Config/ThirdPartyNotices.txt" "$staged_app/ThirdPartyNotices.txt"
cp "$reference_source/COPYING" "$staged_app/COPYING-GPL-3.0.txt"
cp "$rt64_source/LICENSE" "$staged_app/LICENSE-RT64.txt"
cp "$rt64_source/src/contrib/plume/LICENSE" "$staged_app/LICENSE-Plume.txt"
cp "$rt64_source/src/contrib/re-spirv/LICENSE" "$staged_app/LICENSE-re-spirv.txt"
cp "$rt64_source/src/contrib/zstd/LICENSE" "$staged_app/LICENSE-Zstandard.txt"
cp "$reference_source/lib/N64ModernRuntime/N64Recomp/LICENSE" "$staged_app/LICENSE-N64Recomp.txt"
cp "$reference_source/lib/N64ModernRuntime/N64Recomp/lib/fmt/LICENSE" "$staged_app/LICENSE-fmt.txt"
cp "$reference_source/lib/N64ModernRuntime/N64Recomp/lib/rabbitizer/LICENSE" "$staged_app/LICENSE-Rabbitizer.txt"

find "$goldenpad_staging/Payload" -exec touch -h -t 198001010000 {} +
archive_path="$goldenpad_staging/$output_name"
(
  cd "$goldenpad_staging"
  find Payload -print | LC_ALL=C sort | zip -X -q "$archive_path" -@
)

"$repo_root/scripts/verify-recomp-prototype-ipa.sh" "$archive_path"
mv -f "$archive_path" "$output_path"
(
  cd "$repo_root/dist"
  shasum -a 256 "$output_name" > "$output_name.sha256"
)
echo "Created: $output_path"
echo "Checksum: $output_path.sha256"
