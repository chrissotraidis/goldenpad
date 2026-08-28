#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
  echo "usage: $0 GOLDENEYE_REFERENCE_DIR OUTPUT_DIR" >&2
  exit 64
fi

reference_dir=$1
output_dir=$2
source_dir="$reference_dir/RecompiledPatches"
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

for required in patches.c patches_bin.c funcs.h patches_bin.h recomp_overlays.inl; do
  if [ ! -f "$source_dir/$required" ]; then
    echo "missing generated GoldenEye patch file: $source_dir/$required" >&2
    exit 66
  fi
done

mkdir -p "$output_dir"
for required in patches.c patches_bin.c funcs.h patches_bin.h recomp_overlays.inl; do
  cp "$source_dir/$required" "$output_dir/$required"
done

patch -d "$output_dir" -p2 \
  < "$repo_dir/patches/goldeneye64recomp-deterministic-frame-step.patch"

echo "Prepared deterministic GoldenEye patch output: $output_dir"
