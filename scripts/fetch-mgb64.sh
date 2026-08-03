#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir="${GOLDENPAD_MGB64_SOURCE_DIR:-$repo_root/ref/mgb64}"
remote_url="https://github.com/akratch/mgb64.git"
commit="cd9b58f5f91291579b8e551aa925aab000d311cf"

if [ ! -d "$source_dir/.git" ]; then
    git clone --filter=blob:none "$remote_url" "$source_dir"
fi

if [ -n "$(git -C "$source_dir" status --porcelain)" ]; then
    echo "MGB64 checkout is dirty; refusing to change it." >&2
    exit 1
fi

git -C "$source_dir" fetch --quiet origin "$commit"
git -C "$source_dir" checkout --quiet --detach "$commit"
git -C "$source_dir" remote set-url --push origin DISABLED

actual=$(git -C "$source_dir" rev-parse HEAD)
if [ "$actual" != "$commit" ]; then
    echo "MGB64 pin mismatch: expected $commit, got $actual" >&2
    exit 1
fi

echo "MGB64 ready at $actual"
