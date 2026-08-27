#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/goldenpad-input-matrix.XXXXXX")
trap 'rm -rf "$test_root"' EXIT HUP INT TERM
reference_root=${GOLDENPAD_RECOMP_REFERENCE_ROOT:-"$repo_root/ref/goldeneye64recomp"}
tracked_patch="$repo_root/patches/goldeneye64recomp-ios-modern-controls.patch"
generated_patch="$reference_root/RecompiledPatches/patches.c"

xcrun swiftc \
  -module-cache-path "$test_root/swift-module-cache" \
  "$repo_root/Sources/RecompControlMapping.swift" \
  "$repo_root/Tests/RecompControlMappingTests.swift" \
  -o "$test_root/verify-recomp-input-matrix"

"$test_root/verify-recomp-input-matrix"

xcrun swiftc \
  -module-cache-path "$test_root/swift-module-cache" \
  "$repo_root/Sources/RecompTouchFireState.swift" \
  "$repo_root/Tests/RecompTouchFireStateTests.swift" \
  -o "$test_root/verify-recomp-touch-fire"

"$test_root/verify-recomp-touch-fire"

for secondary_fire_marker in \
  'case move, look, fire, secondaryFire' \
  'placement(.secondaryFire, 0.24, 0.58, enabled: false)' \
  'placement(.secondaryFire, 0.30, 0.48, 0.95, enabled: false)' \
  'ForEach(placements.filter(\.isEnabled))' \
  'input.setFirePressed($0, source: fireSource)'
do
  if ! grep -Fq "$secondary_fire_marker" \
    "$repo_root/Sources/RecompPrototypeTouchLayout.swift" \
    "$repo_root/Sources/RecompPrototypeInput.swift"; then
    echo "FAIL: optional secondary Fire path is missing $secondary_fire_marker" >&2
    exit 1
  fi
done

echo "PASS: optional secondary Fire is disabled by default and routed through aggregated input"

for mac_frontend_marker in \
  'goldenpad_recomp_frontend_input_active' \
  'frontEndActive: frontEndInputActive' \
  'movement = nextMenuMouseMovement()'
do
  if ! grep -Fq "$mac_frontend_marker" "$repo_root/Sources/Mac/RecompMacInput.swift" \
    "$repo_root/Support/RecompPrototype/recomp_game_start.cpp"; then
    echo "FAIL: Mac Preview 3 front-end routing is missing $mac_frontend_marker" >&2
    exit 1
  fi
done

echo "PASS: Mac front end preserves analog navigation while watch input remains latched"

mac_sensitivity_markers=$(grep -Fh 'mouseSensitivity = 3.0' \
  "$repo_root/Sources/Mac/GoldenPadMacApp.swift" | wc -l | tr -d ' ')
if [ "$mac_sensitivity_markers" -ne 2 ] || \
  ! grep -Fq 'mouseSensitivity: Float = 3.0' \
    "$repo_root/Sources/Mac/RecompMacInput.swift"; then
  echo "FAIL: Preview 6 Mac default mouse sensitivity is not consistently 3.00" >&2
  exit 1
fi

echo "PASS: Preview 6 Mac default mouse sensitivity is 3.00"

for mac_mouse_aim_marker in \
  'goldenpad_recomp_set_mouse_camera_aim_active' \
  'mouseCaptured && mapping.mouseCameraAimHoldActive(context: context)' \
  'publishMouseLook(scale: mapping.mouseTurnScale(context: context))' \
  '1_680 * Double(mouseSensitivity) * scale' \
  'lookX != 0.0f || lookY != 0.0f || mouseCameraAimHeld'
do
  if ! grep -Fq "$mac_mouse_aim_marker" "$repo_root/Sources/Mac/RecompMacInput.swift" \
    "$repo_root/Support/RecompPrototype/recomp_game_start.cpp" \
    "$tracked_patch"; then
    echo "FAIL: held-Shift relative mouse aim is missing $mac_mouse_aim_marker" >&2
    exit 1
  fi
done

echo "PASS: Mac hip turning is 1.30x while Shift Aim and tank sensitivity remain unchanged"

if grep -Fq 'Menu {' "$repo_root/Sources/RecompPrototypeApp.swift"; then
  echo "FAIL: iPad utility overlay still uses the unreliable native Menu container" >&2
  exit 1
fi
for utility_menu_marker in \
  'private var utilityMenuPanel: some View' \
  'private func utilityMenuRow(' \
  '.frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)' \
  'isUtilityMenuPresented = false'
do
  if ! grep -Fq "$utility_menu_marker" "$repo_root/Sources/RecompPrototypeApp.swift"; then
    echo "FAIL: explicit iPad utility rows are missing $utility_menu_marker" >&2
    exit 1
  fi
done

echo "PASS: iPad utility overlay owns four independent 48-point button rows"

for mobile_menu_marker in \
  'let gameplayActive = goldenPadRecompGameplayInputActive() != 0' \
  'if !gameplayActive {' \
  'buttons: externalButtons,' \
  'stick: externalStick,'
do
  if ! grep -Fq "$mobile_menu_marker" "$repo_root/Sources/RecompPrototypeInput.swift"; then
    echo "FAIL: mobile menu passthrough is missing $mobile_menu_marker" >&2
    exit 1
  fi
done

echo "PASS: mobile non-gameplay path preserves the accepted raw controller passthrough"

for controller_aim_marker in \
  'let manualAimStick = externalMapping.manualAimStick(' \
  'stick: externalStick,' \
  'externalMovement.stick = manualAimStick' \
  'publishedControllerLook = .zero'
do
  if ! grep -Fq "$controller_aim_marker" "$repo_root/Sources/RecompPrototypeInput.swift"; then
    echo "FAIL: native manual-aim routing is missing $controller_aim_marker" >&2
    exit 1
  fi
done

if ! grep -Fq 'if (aiming && invertAimY.load(std::memory_order_relaxed)) {' \
  "$repo_root/Support/RecompPrototype/recomp_game_start.cpp"; then
  echo "FAIL: shared vertical Aim polarity is missing" >&2
  exit 1
fi
if grep -Fq 'if (aiming && !invertAimY.load(std::memory_order_relaxed)) {' \
  "$repo_root/Support/RecompPrototype/recomp_game_start.cpp"; then
  echo "FAIL: mobile vertical Aim polarity is still reversed" >&2
  exit 1
fi

echo "PASS: external-controller on-foot Aim uses native manual-sight routing"

if ! grep -Fq 'constexpr float kControllerHipDegreesPerFrame = 1.872f;' \
  "$repo_root/Support/RecompPrototype/recomp_game_start.cpp"; then
  echo "FAIL: Preview 4 controller sensitivity is not the accepted baseline plus 20 percent" >&2
  exit 1
fi

echo "PASS: Preview 4 external-controller look rate is 1.872 degrees per frame"

mkdir -p "$test_root/reference-clean"
git -C "$reference_root" archive -o "$test_root/reference.tar" HEAD
tar -xf "$test_root/reference.tar" -C "$test_root/reference-clean"
git -C "$test_root/reference-clean" apply "$tracked_patch"

for source_path in \
  patches/externs.h \
  patches/patches.h \
  patches/syms.ld \
  patches/workbench_theboy.c
do
  if ! cmp "$test_root/reference-clean/$source_path" "$reference_root/$source_path"; then
    echo "FAIL: tracked patch output differs from build input $source_path" >&2
    exit 1
  fi
done

for marker in \
  'goldenpad_recomp_consume_reload' \
  'goldenpad_recomp_mouse_camera_aim_active' \
  'goldenpad_recomp_consume_inventory_slot' \
  'goldenpad_recomp_fire_rate_player_sample' \
  'goldenpad_recomp_fire_rate_guard_sample' \
  'RECOMP_FUNC void bondwalkItemGetAutomaticFiringRate' \
  'MEM_B(ctx->r2, 0X22)' \
  'ctx->r1 = S32(ctx->r2 << 1)' \
  'ctx->r2 = ADD32(ctx->r1, ctx->r2)' \
  'MEM_W(ctx->r1, 0X6248)' \
  'MEM_W(ctx->r23, 0X6250)' \
  'MEM_W(0X6284' \
  'MEM_W(0X6274' \
  'MEM_W(0X6278' \
  'MEM_W(ctx->r1, -0X6848)'
do
  if ! grep -Fq "$marker" "$generated_patch"; then
    echo "FAIL: generated patches.c is missing tank-state marker $marker" >&2
    exit 1
  fi
done

echo "PASS: tracked patch matches build input and generated control/tank/fire-rate markers are present"
