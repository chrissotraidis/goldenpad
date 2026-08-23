#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
runtime_source="$repo_root/Support/RecompPrototype/recomp_game_start.cpp"
mobile_source="$repo_root/Sources/RecompPrototypeInput.swift"
stub_source="$repo_root/Support/RecompPrototype/recomp_rt64_surface_stub.cpp"
tracked_patch="$repo_root/patches/goldeneye64recomp-ios-modern-controls.patch"

require_marker() {
    marker=$1
    source_file=$2
    if ! grep -Fq -- "$marker" "$source_file"; then
        echo "FAIL: missing probe contract marker '$marker' in $source_file" >&2
        exit 1
    fi
}

require_marker 'std::atomic<bool> fireRateProbeEnabled = false;' "$runtime_source"
require_marker 'ProcessInfo.processInfo.arguments.contains("--fire-rate-probe") ? 1 : 0' "$mobile_source"
require_marker 'constexpr uint32_t kFireRateWindowTicks = 100;' "$runtime_source"
require_marker 'constexpr uint32_t kFireRateProbeRunLimit = 3;' "$runtime_source"
require_marker 'if (!fireRateProbeEnabled.load(std::memory_order_acquire)) {' "$runtime_source"
require_marker 'extern "C" void goldenpad_recomp_fire_rate_player_sample(' "$runtime_source"
require_marker 'extern "C" void goldenpad_recomp_fire_rate_guard_sample(' "$runtime_source"
require_marker 'extern "C" void goldenpad_recomp_set_fire_rate_probe_enabled(int32_t) {}' "$stub_source"
require_marker 'goldenpad_recomp_fire_rate_player_sample(' "$tracked_patch"
require_marker 'goldenpad_recomp_fire_rate_guard_sample(' "$tracked_patch"
require_marker 'chrlvFireWeaponRelated(chr, hand);' "$tracked_patch"

probe_bodies=$(sed -n \
    '/extern "C" void goldenpad_recomp_fire_rate_player_sample(/,/extern "C" void goldenpad_recomp_set_two_player_test_mode(/p' \
    "$runtime_source")
if printf '%s\n' "$probe_bodies" | grep -Eq 'MEM_W|writeGameWord|_return<'; then
    echo "FAIL: TD-01 observation body contains a game-memory or return-value write" >&2
    exit 1
fi

for verifier in \
    "$repo_root/scripts/verify-recomp-prototype-host.sh" \
    "$repo_root/scripts/verify-recomp-prototype-ipa.sh"
do
    require_marker 'goldenpad_recomp_set_fire_rate_probe_enabled' "$verifier"
done

echo "PASS: TD-01 probe defaults off and requires the explicit launch argument"
echo "PASS: player and guard observation hooks, bounded windows, and ROM-free stub are present"
echo "PASS: observation bodies contain no RDRAM or recompiled return-value writes"
echo "NOTE: this static contract does not prove cadence, gameplay feel, or physical behavior"
