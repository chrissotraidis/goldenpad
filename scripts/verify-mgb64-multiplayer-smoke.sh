#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
source_dir="${GOLDENPAD_MGB64_SOURCE_DIR:-$repo_root/ref/mgb64}"
build_dir="${GOLDENPAD_MGB64_BUILD_DIR:-build-goldenpad-webgpu}"
patch_file="$repo_root/patches/mgb64-multiplayer-smoke.patch"
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-mgb64-multiplayer.XXXXXX")
patch_applied=0

cleanup() {
    if [ "$patch_applied" -eq 1 ]; then
        git -C "$source_dir" apply --reverse "$patch_file"
    fi
    find "$work_dir" -depth -delete
}
trap cleanup EXIT

for command_name in cmake git python3; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Missing required command: $command_name" >&2
        exit 1
    fi
done

if [ -z "${GOLDENPAD_ROM_PATH:-}" ]; then
    echo "Set GOLDENPAD_ROM_PATH to a private supported retail ROM." >&2
    exit 1
fi

case "$GOLDENPAD_ROM_PATH" in
    /*) rom_path="$GOLDENPAD_ROM_PATH" ;;
    *) rom_path="$PWD/$GOLDENPAD_ROM_PATH" ;;
esac

if [ ! -f "$rom_path" ]; then
    echo "Retail ROM not found: $rom_path" >&2
    exit 1
fi

if ! python3 -c 'from PIL import Image' >/dev/null 2>&1; then
    echo "Python Pillow is required for private split-screen image analysis." >&2
    exit 1
fi

"$repo_root/scripts/fetch-mgb64.sh"
if [ -n "$(git -C "$source_dir" status --porcelain)" ]; then
    echo "MGB64 checkout is dirty; refusing to patch it." >&2
    exit 1
fi

git -C "$source_dir" apply --check "$patch_file"
git -C "$source_dir" apply "$patch_file"
patch_applied=1

"$source_dir/tools/mp_smoke.sh" \
    --build-dir "$build_dir" \
    --rom "$rom_path" \
    --players 2 \
    --mp-stage temple \
    --scenario deathmatch \
    --timelimit 2 \
    --out-dir "$work_dir"

git -C "$source_dir" apply --reverse "$patch_file"
patch_applied=0

if [ -n "$(git -C "$source_dir" status --porcelain)" ]; then
    echo "MGB64 checkout was not restored to a clean state." >&2
    exit 1
fi

echo "MGB64 two-player split-screen startup passed and private artifacts were removed."
