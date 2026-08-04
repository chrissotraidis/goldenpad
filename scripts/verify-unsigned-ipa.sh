#!/usr/bin/env bash
set -euo pipefail

require_game_core=0
if [ "${1:-}" = "--game-core" ]; then
  require_game_core=1
  shift
fi

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 [--game-core] /absolute/path/to/GoldenPad.ipa" >&2
  exit 2
fi

ipa_path=$1
if [ ! -f "$ipa_path" ] || [[ "$ipa_path" != *.ipa ]]; then
  echo "Expected an existing .ipa file: $ipa_path" >&2
  exit 1
fi

goldenpad_audit=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-ipa-audit.XXXXXX")
trap 'rm -rf "$goldenpad_audit"' EXIT
unzip -q "$ipa_path" -d "$goldenpad_audit"

app_path="$goldenpad_audit/Payload/GoldenPad.app"
executable="$app_path/GoldenPad"
if [ ! -d "$app_path" ] || [ ! -f "$executable" ]; then
  echo "IPA does not contain Payload/GoldenPad.app/GoldenPad." >&2
  exit 1
fi

bad_names=$(unzip -Z1 "$ipa_path" | grep -Ei '\.(z64|n64|v64|rom|wad|eep|sra|fla|mobileprovision|p12|pem|key)$|(^|/)(roms?|generated-assets|runtime-assets)(/|$)' || true)
if [ -n "$bad_names" ]; then
  echo "Refusing contaminated archive paths:" >&2
  echo "$bad_names" >&2
  exit 1
fi

known_hash='abe01e4aeb033b6c0836819f549c791b26cfde83'
while IFS= read -r -d '' file_path; do
  size=$(stat -f '%z' "$file_path")
  magic=$(od -An -tx1 -N4 "$file_path" | tr -d ' \n')
  case "$magic" in
    80371240|37804012|40123780)
      echo "Refusing N64 ROM header in ${file_path#"$goldenpad_audit/"}." >&2
      exit 1
      ;;
  esac

  if [ "$size" -eq 12582912 ]; then
    digest=$(shasum "$file_path" | awk '{print $1}')
    if [ "$digest" = "$known_hash" ]; then
      echo "Refusing known retail ROM bytes in archive." >&2
      exit 1
    fi
  fi
done < <(find "$goldenpad_audit" -type f -print0)

if ! file "$executable" | grep -q 'Mach-O 64-bit executable arm64'; then
  echo "IPA executable is not ARM64." >&2
  exit 1
fi

if codesign -dv "$app_path" >/dev/null 2>&1; then
  echo "IPA is signed; expected an unsigned artifact." >&2
  exit 1
fi

if [ "$require_game_core" -eq 1 ]; then
  notices="$app_path/ThirdPartyNotices.txt"
  if [ ! -f "$notices" ]; then
    echo "IPA is missing ThirdPartyNotices.txt." >&2
    exit 1
  fi
  for notice_name in MGB64 n64-fast3d-engine cgltf jsmn stb_image; do
    if ! grep -Fq "$notice_name" "$notices"; then
      echo "IPA third-party notices are missing: $notice_name" >&2
      exit 1
    fi
  done
  for symbol in _bossEntry _gfx_init _gfx_run_dl; do
    if ! nm -gU "$executable" |
      awk -v required="$symbol" '$3 == required { found = 1 } END { exit !found }'; then
      echo "IPA is missing required game symbol: $symbol" >&2
      exit 1
    fi
  done
fi

if strings "$executable" |
  awk '/\/Users\/|\/tmp\/goldenpad-clean\.|GoldenEye 007 \(U\)|ref\/(mgb64|goldenrecomp|goldeneye_decomp)/ { found = 1 } END { exit !found }'; then
  echo "Executable contains a private build/reference path." >&2
  exit 1
fi

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

echo "IPA audit passed: $(unzip -Z1 "$ipa_path" | wc -l | tr -d ' ') members"
if [ "$require_game_core" -eq 1 ]; then
  echo "Game-core/notices audit passed: bossEntry + Metal Fast3D entry points"
fi
echo "Unsigned ARM64 app content SHA-256: $content_digest"
