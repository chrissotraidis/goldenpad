#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

bad_names=$(git ls-files | grep -Ei '(^|/)(baserom|roms?)(/|[._-])|\.(z64|n64|v64|rom|wad|ipa|mobileprovision|p12)$' || true)
if [ -n "$bad_names" ]; then
  echo "Refusing tracked ROM/package/signing paths:" >&2
  echo "$bad_names" >&2
  exit 1
fi

known_hash='abe01e4aeb033b6c0836819f549c791b26cfde83'
known_tlbfree_sha256='7ec491ee3164851d0995e3e8ad19999df5e3028be6ba3729c4ac16c31a9c0959'
while IFS= read -r path; do
  [ -f "$path" ] || continue
  size=$(stat -f '%z' "$path")
  if [ "$size" -eq 12582912 ]; then
    digest=$(shasum "$path" | awk '{print $1}')
    if [ "$digest" = "$known_hash" ]; then
      echo "Refusing tracked retail ROM bytes: $path" >&2
      exit 1
    fi
  fi
  if [ "$size" -eq 12653664 ]; then
    digest=$(shasum -a 256 "$path" | awk '{print $1}')
    if [ "$digest" = "$known_tlbfree_sha256" ]; then
      echo "Refusing tracked TLB-free ROM bytes: $path" >&2
      exit 1
    fi
  fi
done < <(git ls-files)

echo "No tracked ROM/package/signing paths or known retail ROM bytes found."
