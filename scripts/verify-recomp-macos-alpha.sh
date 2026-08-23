#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /absolute/path/to/GoldenPad-macos-arm64-alpha.zip" >&2
  exit 2
fi

archive_path=$1
if [ ! -f "$archive_path" ] || [[ "$archive_path" != *.zip ]]; then
  echo "Expected an existing .zip file: $archive_path" >&2
  exit 1
fi

goldenpad_audit=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-macos-alpha-audit.XXXXXX")
trap 'rm -rf "$goldenpad_audit"' EXIT
unzip -q "$archive_path" -d "$goldenpad_audit"

app_path="$goldenpad_audit/GoldenPad.app"
plist="$app_path/Contents/Info.plist"
resources="$app_path/Contents/Resources"
if [ ! -d "$app_path" ] || [ ! -f "$plist" ]; then
  echo "Archive does not contain GoldenPad.app." >&2
  exit 1
fi

executable_name=$(plutil -extract CFBundleExecutable raw "$plist")
executable="$app_path/Contents/MacOS/$executable_name"
if [ ! -f "$executable" ] || ! file "$executable" | grep -q 'Mach-O 64-bit executable arm64'; then
  echo "Mac executable is not ARM64." >&2
  exit 1
fi

test "$(plutil -extract CFBundleDisplayName raw "$plist")" = "GoldenPad"
test "$(plutil -extract CFBundleName raw "$plist")" = "GoldenPad"
test "$executable_name" = "GoldenPad"
test "$(plutil -extract CFBundleIdentifier raw "$plist")" = "com.chrissotraidis.goldenpad.macos"
test "$(plutil -extract CFBundleShortVersionString raw "$plist")" = "0.1.0"
test "$(plutil -extract CFBundleVersion raw "$plist")" = "1"
test "$(plutil -extract LSMinimumSystemVersion raw "$plist")" = "13.0"

if ! xcrun vtool -show-build "$executable" | grep -q 'platform MACOS'; then
  echo "Executable is not a native macOS build." >&2
  exit 1
fi
if xcrun vtool -show-build "$executable" | grep -Eq 'platform (IOS|IOSSIMULATOR|MACCATALYST)'; then
  echo "Executable unexpectedly contains a mobile or Catalyst platform." >&2
  exit 1
fi

codesign --verify --deep --strict "$app_path"
signature_details=$(codesign -dv --verbose=4 "$app_path" 2>&1)
if ! grep -q 'Signature=adhoc' <<<"$signature_details" ||
   ! grep -q 'TeamIdentifier=not set' <<<"$signature_details"; then
  echo "Mac Alpha must carry only an ad-hoc signature." >&2
  exit 1
fi

bad_names=$(unzip -Z1 "$archive_path" | grep -Ei '\.(z64|n64|v64|rom|wad|eep|sra|fla|sav|mobileprovision|p12|pem|key)$|(^|/)(roms?|generated-assets|runtime-assets)(/|$)' || true)
if [ -n "$bad_names" ]; then
  echo "Refusing contaminated archive paths:" >&2
  echo "$bad_names" >&2
  exit 1
fi

while IFS= read -r -d '' artifact_file; do
  magic=$(od -An -tx1 -N4 "$artifact_file" | tr -d ' \n')
  case "$magic" in
    80371240|37804012|40123780)
      echo "Refusing N64 ROM header in ${artifact_file#"$goldenpad_audit/"}." >&2
      exit 1
      ;;
  esac
done < <(find "$goldenpad_audit" -type f -print0)

if strings "$executable" | grep -Eq '/Users/|/private/tmp'; then
  echo "Executable contains a private build path." >&2
  exit 1
fi
if otool -L "$executable" | grep -Eqi '/opt/homebrew|/usr/local|SDL|Vulkan|X11'; then
  echo "Executable contains an unsupported non-system desktop dependency." >&2
  exit 1
fi

for required_symbol in \
  _goldenpad_recomp_start_game \
  _goldenpad_recomp_rt64_initialize \
  _goldenpad_recomp_set_controller_state \
  _goldenpad_recomp_set_right_analog \
  _goldenpad_recomp_request_crouch_toggle \
  _goldenpad_recomp_request_inventory_slot \
  _goldenpad_recomp_request_reload \
  _goldenpad_recomp_consume_crouch_toggle \
  _goldenpad_recomp_consume_inventory_slot \
  _goldenpad_recomp_consume_reload \
  _goldenpad_recomp_queue_mouse_look \
  _goldenpad_recomp_get_input_context
do
  if ! nm -gU "$executable" | awk -v required="$required_symbol" '$3 == required { found = 1 } END { exit !found }'; then
    echo "Mac Alpha is missing required runtime symbol: $required_symbol" >&2
    exit 1
  fi
done

test -s "$resources/AppIcon.icns"
for required_file in \
  ThirdPartyNotices.txt \
  COPYING-GPL-3.0.txt \
  LICENSE-RT64.txt \
  LICENSE-Plume.txt \
  LICENSE-re-spirv.txt \
  LICENSE-Zstandard.txt \
  LICENSE-N64Recomp.txt \
  LICENSE-fmt.txt \
  LICENSE-Rabbitizer.txt
do
  test -s "$resources/$required_file"
done

content_digest=$(
  find "$app_path" -type f -print0 |
    LC_ALL=C sort -z |
    while IFS= read -r -d '' artifact_file; do
      relative=${artifact_file#"$app_path/"}
      printf '%s  %s\n' "$(shasum -a 256 "$artifact_file" | awk '{print $1}')" "$relative"
    done |
    shasum -a 256 |
    awk '{print $1}'
)

echo "Mac Alpha audit passed: $(unzip -Z1 "$archive_path" | wc -l | tr -d ' ') members"
echo "Ad-hoc-signed ARM64 app content SHA-256: $content_digest"
