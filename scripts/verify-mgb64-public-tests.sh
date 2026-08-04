#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
source_dir="${GOLDENPAD_MGB64_SOURCE_DIR:-$repo_root/ref/mgb64}"
patch_file="$repo_root/patches/mgb64-public-tests.patch"
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-mgb64-public-tests.XXXXXX")
public_source="$work_dir/source"
build_dir="$work_dir/build"
patch_applied=0

cleanup() {
    if [ "$patch_applied" -eq 1 ]; then
        git -C "$source_dir" apply --reverse "$patch_file"
    fi
    find "$work_dir" -depth -delete
}
trap cleanup EXIT

for command_name in cmake git ninja python3 tar; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Missing required command: $command_name" >&2
        exit 1
    fi
done

"$repo_root/scripts/fetch-mgb64.sh"
if [ -n "$(git -C "$source_dir" status --porcelain)" ]; then
    echo "MGB64 checkout is dirty; refusing to patch it." >&2
    exit 1
fi

git -C "$source_dir" apply --check "$patch_file"
git -C "$source_dir" apply "$patch_file"
patch_applied=1

mkdir -p "$public_source"
git -C "$source_dir" archive --worktree-attributes HEAD | tar -x -C "$public_source"

git -C "$source_dir" apply --reverse "$patch_file"
patch_applied=0
git -C "$public_source" init --quiet
git -C "$public_source" apply "$patch_file"

if [ -e "$public_source/tools/fidelity/ledger.py" ] ||
   [ -e "$public_source/tools/tests/test_rng_callcount_diff.py" ]; then
    echo "Internal fidelity-only files entered the public source export." >&2
    exit 1
fi

git -C "$public_source" -c core.autocrlf=false add -A
git -C "$public_source" \
    -c user.name=GoldenPad \
    -c user.email=goldenpad@localhost \
    commit --quiet -m public-export-test

export PYTHONDONTWRITEBYTECODE=1
cmake -S "$public_source" -B "$build_dir" -G Ninja \
    -DBUILD_TESTING=ON \
    -DCMAKE_BUILD_TYPE=Release
cmake --build "$build_dir" -j "${GOLDENPAD_MGB64_TEST_JOBS:-4}"
ctest --test-dir "$build_dir" \
    --output-on-failure \
    -j "${GOLDENPAD_MGB64_TEST_JOBS:-4}"

if [ -n "$(git -C "$source_dir" status --porcelain)" ]; then
    echo "MGB64 checkout was not restored to a clean state." >&2
    exit 1
fi

echo "MGB64 public ROM-free test surface passed and upstream was restored clean."
