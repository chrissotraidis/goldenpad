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
done < <(git ls-files)

echo "No tracked ROM/package/signing paths or known retail ROM bytes found."
