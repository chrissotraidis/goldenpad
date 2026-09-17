#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"
# Never reset a user's tracked changes while updating dependency checkouts.
for source in vendor/goldeneye vendor/rt64-ios vendor/rt64-macos; do
  if [ -e "$source/.git" ] && [ -n "$(git -C "$source" status --porcelain --ignore-submodules=all --untracked-files=no)" ]; then
    echo "Refusing to update modified dependency: $source" >&2
    exit 1
  fi
  if [ -e "$source/.git" ]; then
    git -C "$source" submodule foreach --quiet --recursive 'test -z "$(git status --porcelain --ignore-submodules=all --untracked-files=no)" || { echo "Modified nested dependency: $displaypath" >&2; exit 1; }'
  fi
done
git submodule update --init -- vendor/goldeneye vendor/rt64-ios vendor/rt64-macos
git -C vendor/goldeneye submodule update --init -- lib/ge
for source in vendor/rt64-ios vendor/rt64-macos; do
  git -C "$source" submodule update --init --recursive
done
python3 scripts/check-sources.py
