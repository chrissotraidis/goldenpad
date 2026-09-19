#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-diagnostics-tests.XXXXXX")
trap 'rm -rf "$work"' EXIT
xcrun clang++ -std=c++20 -O2 -fobjc-arc "$root/Tests/PerformanceDiagnosticsTests.mm" \
    "$root/Support/RecompPrototype/performance_diagnostics.mm" -framework Foundation -framework Metal -o "$work/native"
"$work/native" "$work/runtime.log"
xcrun clang -c "$root/Tests/diagnostics_stubs.c" -o "$work/stubs.o"
xcrun swiftc "$root/Sources/GoldenPadDiagnostics.swift" "$root/Tests/GoldenPadDiagnosticsTests.swift" "$work/stubs.o" -o "$work/swift"
"$work/swift"
xcrun swiftc -typecheck "$root/Sources/GoldenPadDiagnostics.swift" "$root/Sources/GoldenPadIssueReport.swift"
