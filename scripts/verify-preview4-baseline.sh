#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
baseline_commit=54474a40e93b77259d10c7594919e6a05f5e276d
baseline_tree=4232141f9d14d2f6197e43173694f649828e730f

git -C "$repo_root" cat-file -e "$baseline_commit^{commit}"

actual_tree=$(git -C "$repo_root" rev-parse "$baseline_commit^{tree}")
if [ "$actual_tree" != "$baseline_tree" ]; then
    echo "FAIL: Preview 4 tree is $actual_tree, expected $baseline_tree" >&2
    exit 1
fi

if ! git -C "$repo_root" merge-base --is-ancestor "$baseline_commit" HEAD; then
    echo "FAIL: current branch does not descend from published Preview 4" >&2
    exit 1
fi

runtime_paths='CMakeLists.txt Config Sources Support Tests patches'
if ! git -C "$repo_root" diff --quiet "$baseline_commit" -- $runtime_paths; then
    echo "FAIL: runtime source differs from frozen Preview 4 before measurement" >&2
    git -C "$repo_root" diff --name-only "$baseline_commit" -- $runtime_paths >&2
    exit 1
fi

untracked_runtime=$(git -C "$repo_root" status --porcelain --untracked-files=all -- $runtime_paths)
if [ -n "$untracked_runtime" ]; then
    echo "FAIL: untracked or staged runtime files exist before measurement" >&2
    printf '%s\n' "$untracked_runtime" >&2
    exit 1
fi

baseline_doc="$repo_root/docs/PREVIEW_4_BASELINE.md"
for required_value in \
    "$baseline_commit" \
    "$baseline_tree" \
    ff163b0af6b54596590da8e39cbaff0b388b69f1607ca34f62ce61e7fe144130 \
    63bec02ad6e323a213f9cb9d15f763a58d6eb7bd4a1a40af6341a4fb8fb333ba \
    d83361f4daa70014b378aed20b9e26dc7c787d77b0fcd000816d536aecc8e66b \
    2b31f8868885712fbad34cef1aea20b1dee48f59fc9d930cbd3fa8b8e82b6b12 \
    0d64256620a5dcb43e7ccf86f9fedd7282242f823ea7d9984c0447c85f3a1cea \
    4a829165889a4e736199841c4c4237ee6a03ed97fa1ce6d891dfc864634862ff \
    cb3e439a8eb1587ac11b7fa29551b3f204860f993b9114ebd5331c179bc92bc6
do
    if ! grep -Fq "$required_value" "$baseline_doc"; then
        echo "FAIL: baseline manifest is missing $required_value" >&2
        exit 1
    fi
done

echo "PASS: current branch descends from the exact Preview 4 tree"
echo "PASS: runtime source is unchanged from Preview 4 before TD-01 measurement"
echo "PASS: Preview 4 source, package, release executable, and physical-control identities are recorded"
