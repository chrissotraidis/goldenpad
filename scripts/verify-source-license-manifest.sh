#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
project_file=${1:-$repo_root/build-mgb64-renderer-device/GoldenPad.xcodeproj/project.pbxproj}
manifest="$repo_root/docs/source-license-manifest.tsv"
candidate=$(mktemp "${TMPDIR:-/tmp}/goldenpad-license-manifest.XXXXXX")
trap 'rm -f "$candidate"' EXIT

"$repo_root/scripts/generate-source-license-manifest.sh" "$project_file" "$candidate" >/dev/null
if ! cmp -s "$candidate" "$manifest"; then
  echo "Source license manifest is stale. Regenerate it after configuring the production target." >&2
  diff -u "$manifest" "$candidate" || true
  exit 1
fi

echo "Source license manifest matches the configured production target."
