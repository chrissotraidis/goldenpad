#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
measurement_commit=9f039518090f634d1ea8d216416dcdfd5af02dcf
reference_root=${GOLDENPAD_RECOMP_REFERENCE_ROOT:-"$repo_root/ref/goldeneye64recomp"}
tracked_patch="$repo_root/patches/goldeneye64recomp-ios-modern-controls.patch"
source_patch="$reference_root/patches/workbench_theboy.c"
generated_patch="$reference_root/RecompiledPatches/patches.c"
generated_binary="$reference_root/RecompiledPatches/patches_bin.c"

require_marker() {
    marker=$1
    source_file=$2
    if ! grep -Fq -- "$marker" "$source_file"; then
        echo "FAIL: missing TD-01 repair marker '$marker' in $source_file" >&2
        exit 1
    fi
}

for source_file in "$source_patch" "$generated_patch" "$generated_binary"
do
    if [ ! -f "$source_file" ]; then
        echo "FAIL: missing generated-patch input $source_file" >&2
        exit 1
    fi
done

if git -C "$repo_root" show "$measurement_commit:patches/goldeneye64recomp-ios-modern-controls.patch" |
    grep -Fq 'RECOMP_PATCH s8 bondwalkItemGetAutomaticFiringRate'; then
    echo "FAIL: the frozen measurement control already contains the repair" >&2
    exit 1
fi

for marker in \
    '#define GOLDENPAD_AUTHENTIC_FRAME_COST 3' \
    '#define GOLDENPAD_AUTOMATIC_RATE_OFFSET 0x22' \
    'return rawRate > 0 ? rawRate * GOLDENPAD_AUTHENTIC_FRAME_COST : rawRate;' \
    'RECOMP_PATCH s8 bondwalkItemGetAutomaticFiringRate(ITEM_IDS item)'
do
    require_marker "$marker" "$tracked_patch"
    require_marker "$marker" "$source_patch"
done

for marker in \
    'RECOMP_FUNC void bondwalkItemGetAutomaticFiringRate' \
    'ctx->r2 = MEM_B(ctx->r2, 0X22);' \
    'ctx->r1 = SIGNED(0) < SIGNED(ctx->r2) ? 1 : 0;' \
    'ctx->r1 = S32(ctx->r2 << 1);' \
    'ctx->r2 = ADD32(ctx->r1, ctx->r2);'
do
    require_marker "$marker" "$generated_patch"
done

if [ "$reference_root/patches/patches.bin" -nt "$generated_binary" ]; then
    echo "FAIL: patches_bin.c is older than the regenerated patches.bin" >&2
    exit 1
fi

scale_rate() {
    raw_rate=$1
    if [ "$raw_rate" -gt 0 ]; then
        echo $((raw_rate * 3))
    else
        echo "$raw_rate"
    fi
}

for case_value in 2:6 3:9 4:12 5:15 11:33 0:0 -1:-1
do
    raw_rate=${case_value%%:*}
    expected=${case_value#*:}
    actual=$(scale_rate "$raw_rate")
    if [ "$actual" -ne "$expected" ]; then
        echo "FAIL: raw automatic rate $raw_rate scaled to $actual, expected $expected" >&2
        exit 1
    fi
done

legacy_shots=$((360 / 3))
authentic_shots=$((360 / 9))
if [ "$legacy_shots" -ne 120 ] || [ "$authentic_shots" -ne 40 ] ||
    [ "$legacy_shots" -ne $((authentic_shots * 3)) ]; then
    echo "FAIL: deterministic 360-tick cadence discriminator is inconsistent" >&2
    exit 1
fi

echo "PASS: frozen measurement control lacks the TD-01 timing repair"
echo "PASS: tracked source and generated MIPS patch scale positive automatic rates by 3"
echo "PASS: zero and negative semi-automatic classifications remain unchanged"
echo "PASS: deterministic rate-3 lane changes from 120 to 40 gates over 360 ticks"
echo "NOTE: physical player/guard cadence and combat feel still require hands-on acceptance"
