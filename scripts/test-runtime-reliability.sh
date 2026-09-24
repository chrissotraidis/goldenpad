#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
runtime="$repo_root/vendor/goldeneye/lib/N64ModernRuntime"
output="$repo_root/build-runtime-reliability-tests"
mkdir -p "$output"
clang++ -std=c++20 -O1 -g -ftrivial-auto-var-init=pattern \
    -fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer \
    -Wno-deprecated-literal-operator \
    -I"$runtime/ultramodern/include" \
    -I"$runtime/thirdparty" \
    -I"$runtime/thirdparty/concurrentqueue" \
    -I"$runtime/librecomp/include/librecomp" \
    -I"$runtime/N64Recomp/include" \
    "$repo_root/Tests/runtime_reliability.cpp" \
    "$runtime/ultramodern/src/input.cpp" \
    "$runtime/ultramodern/src/mesgqueue.cpp" \
    "$runtime/librecomp/src/cont.cpp" \
    -o "$output/runtime-reliability"
"$output/runtime-reliability"
