#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
if [ "$#" -ne 2 ]; then echo 'Usage: generate-recomp-inputs.sh VERIFIED_TLBFREE_ROM NEW_PRIVATE_OUTPUT_DIRECTORY' >&2; exit 2; fi
rom=$1
output=$2
[ ! -e "$output" ] || { echo 'Output must be new; refusing to overwrite private inputs.' >&2; exit 1; }
[ "$(shasum -a 256 "$rom" | awk '{print $1}')" = 7ec491ee3164851d0995e3e8ad19999df5e3028be6ba3729c4ac16c31a9c0959 ] || { echo 'Unsupported prepared ROM.' >&2; exit 1; }
python3 "$repo_root/scripts/check-sources.py" --component goldeneye --component rt64-ios
source="$repo_root/vendor/goldeneye"
tools="$repo_root/build-recomp-tools"
cmake -S "$source/n64recomp-src" -B "$tools" -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build "$tools" --target N64Recomp RSPRecomp --parallel 8
mkdir -p "$output"
output=$(cd "$output" && pwd)
if [ -e "$source/.git" ]; then
  git -C "$source" archive HEAD | tar -x -C "$output"
  mkdir -p "$output/lib/ge"
  git -C "$source/lib/ge" archive HEAD include | tar -x -C "$output/lib/ge"
else
  # Offline export: copy only entries recorded in the verified source manifest.
  python3 - "$repo_root" "$output" <<'PYCOPY'
import json,pathlib,shutil,sys
root=pathlib.Path(sys.argv[1]);out=pathlib.Path(sys.argv[2]);prefix='vendor/goldeneye/'
for name in json.loads((root/'source-manifest.json').read_text())['files']:
 if name.startswith(prefix):
  dest=out/name[len(prefix):];dest.parent.mkdir(parents=True,exist_ok=True)
  shutil.copy2(root/name,dest,follow_symlinks=False)
PYCOPY
fi
cp "$rom" "$output/ge007.tlbfree.z64"
"$tools/N64Recomp" "$output/us.toml"
python3 "$output/tools_weaken_patched.py"
"$tools/RSPRecomp" "$output/aspMain.us.toml"
make -C "$output/patches" CC="${GOLDENPAD_MIPS_CC:-/opt/homebrew/opt/llvm/bin/clang}" LD="${GOLDENPAD_MIPS_LD:-/opt/homebrew/opt/lld/bin/ld.lld}"
"$tools/N64Recomp" "$output/patches.toml"
xcrun clang++ -std=c++17 -O2 "$repo_root/vendor/rt64-ios/src/tools/file_to_c/file_to_c.cpp" -o "$tools/file_to_c"
"$tools/file_to_c" "$output/patches/patches.bin" mm_patches_bin "$output/RecompiledPatches/patches_bin.c" "$output/RecompiledPatches/patches_bin.h"
printf 'Private generated inputs: %s\n' "$output"
