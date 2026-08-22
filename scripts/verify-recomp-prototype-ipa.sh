#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /absolute/path/to/GoldenPad-preview-unsigned.ipa" >&2
  exit 2
fi

ipa_path=$1
if [ ! -f "$ipa_path" ] || [[ "$ipa_path" != *.ipa ]]; then
  echo "Expected an existing .ipa file: $ipa_path" >&2
  exit 1
fi

goldenpad_audit=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-recomp-ipa-audit.XXXXXX")
trap 'rm -rf "$goldenpad_audit"' EXIT
unzip -q "$ipa_path" -d "$goldenpad_audit"

app_path="$goldenpad_audit/Payload/GoldenPad.app"
if [ ! -d "$app_path" ] || [ ! -f "$app_path/Info.plist" ]; then
  echo "IPA does not contain Payload/GoldenPad.app." >&2
  exit 1
fi

executable_name=$(plutil -extract CFBundleExecutable raw "$app_path/Info.plist")
executable="$app_path/$executable_name"
if [ ! -f "$executable" ] || ! file "$executable" | grep -q 'Mach-O 64-bit executable arm64'; then
  echo "IPA executable is not ARM64." >&2
  exit 1
fi

test "$(plutil -extract CFBundleDisplayName raw "$app_path/Info.plist")" = "GoldenPad"
test "$(plutil -extract CFBundleIdentifier raw "$app_path/Info.plist")" = "com.chrissotraidis.goldenpad.recomp-prototype"
test "$(plutil -extract CFBundleShortVersionString raw "$app_path/Info.plist")" = "0.1.0"
test "$(plutil -extract CFBundleVersion raw "$app_path/Info.plist")" = "2"
test "$(plutil -extract UIFileSharingEnabled raw "$app_path/Info.plist")" = "true"
test "$(plutil -extract LSSupportsOpeningDocumentsInPlace raw "$app_path/Info.plist")" = "true"

if codesign -dv "$app_path" >/dev/null 2>&1; then
  echo "IPA is signed; expected an unsigned public artifact." >&2
  exit 1
fi

bad_names=$(unzip -Z1 "$ipa_path" | grep -Ei '\.(z64|n64|v64|rom|wad|eep|sra|fla|sav|mobileprovision|p12|pem|key)$|(^|/)(_CodeSignature|SC_Info|roms?|generated-assets|runtime-assets)(/|$)' || true)
if [ -n "$bad_names" ]; then
  echo "Refusing contaminated archive paths:" >&2
  echo "$bad_names" >&2
  exit 1
fi

known_hash='abe01e4aeb033b6c0836819f549c791b26cfde83'
known_tlbfree_sha256='7ec491ee3164851d0995e3e8ad19999df5e3028be6ba3729c4ac16c31a9c0959'
while IFS= read -r -d '' file_path; do
  size=$(stat -f '%z' "$file_path")
  magic=$(od -An -tx1 -N4 "$file_path" | tr -d ' \n')
  case "$magic" in
    80371240|37804012|40123780)
      echo "Refusing N64 ROM header in ${file_path#"$goldenpad_audit/"}." >&2
      exit 1
      ;;
  esac
  if [ "$size" -eq 12582912 ] && [ "$(shasum "$file_path" | awk '{print $1}')" = "$known_hash" ]; then
    echo "Refusing known retail ROM bytes in archive." >&2
    exit 1
  fi
  if [ "$size" -eq 12653664 ] && [ "$(shasum -a 256 "$file_path" | awk '{print $1}')" = "$known_tlbfree_sha256" ]; then
    echo "Refusing known TLB-free ROM bytes in archive." >&2
    exit 1
  fi
done < <(find "$goldenpad_audit" -type f -print0)

rom_patch="$app_path/vanilla_to_tlbfree.gep1"
if [ ! -f "$rom_patch" ] || [ "$(shasum -a 256 "$rom_patch" | awk '{print $1}')" != "5a079d5b3750afcb027e46367e318b884eadabbd238a450a70f95e3976ded263" ]; then
  echo "IPA is missing the exact pinned Preview 2 GEP1 conversion patch." >&2
  exit 1
fi

for required_symbol in \
  _goldenpad_recomp_start_game \
  _goldenpad_recomp_rt64_initialize \
  _goldenpad_recomp_set_controller_state \
  _goldenpad_recomp_set_touch_input_port \
  _goldenpad_recomp_set_four_player_test_mode \
  _goldenpad_recomp_set_fire_rate_probe_enabled \
  _goldenpad_recomp_set_sidestep_probe_enabled \
  _goldenpad_recomp_set_lifecycle_probe_enabled \
  _goldenpad_recomp_set_audio_probe_enabled \
  _goldenpad_recomp_set_depth_rebuild_probe_enabled \
  _goldenpad_recomp_set_render_order_probe_mode \
  _goldenpad_recomp_render_order_probe \
  _goldenpad_rt64_depth_format_rebuild_stats \
  _goldenpad_recomp_note_audio_host_rates \
  _goldenpad_recomp_audio_probe_stats \
  _goldenpad_recomp_gameplay_input_active \
  _goldenpad_recomp_audio_render \
  _goldenpad_recomp_import_rom \
  _goldenpad_recomp_validate_tlbfree_rom \
  _goldenpad_recomp_request_return_to_title
do
  if ! nm -gU "$executable" | awk -v required="$required_symbol" '$3 == required { found = 1 } END { exit !found }'; then
    echo "IPA is missing required primary-runtime symbol: $required_symbol" >&2
    exit 1
  fi
done
if nm -gU "$executable" | grep -q '_goldenpad_mgb64_'; then
  echo "Legacy MGB64 symbols entered the primary package." >&2
  exit 1
fi

if strings "$executable" | grep -Eq '/Users/'; then
  echo "Executable contains a private user path." >&2
  exit 1
fi
unexpected_tmp=$(strings "$executable" | grep '/private/tmp' | grep -Ev '^/private/tmp/goldenpad-recomp\.[^/]+/(rsp/aspMain\.cpp|runtime-source/(librecomp/src/(eep|mod_events|pi)\.cpp|ultramodern/src/(events|renderer_context)\.cpp))$' || true)
if [ -n "$unexpected_tmp" ]; then
  echo "Executable contains an unexpected temporary build path:" >&2
  echo "$unexpected_tmp" >&2
  exit 1
fi

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
  test -s "$app_path/$required_file"
done
for required_name in GoldenEye64Recomp N64ModernRuntime N64Recomp RT64 Plume re-spirv Zstandard; do
  grep -Fq "$required_name" "$app_path/ThirdPartyNotices.txt"
done

content_digest=$(
  find "$app_path" -type f -print0 |
    LC_ALL=C sort -z |
    while IFS= read -r -d '' file_path; do
      relative=${file_path#"$app_path/"}
      printf '%s  %s\n' "$(shasum -a 256 "$file_path" | awk '{print $1}')" "$relative"
    done |
    shasum -a 256 |
    awk '{print $1}'
)

echo "Primary IPA audit passed: $(unzip -Z1 "$ipa_path" | wc -l | tr -d ' ') members"
echo "Unsigned ARM64 app content SHA-256: $content_digest"
