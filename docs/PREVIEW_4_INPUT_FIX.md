# Preview 4 shared input repair

Status: **iPadOS menu, on-foot controls, and Runway 1.1 tank path physically
accepted; Preview 4 published; reporter Mac verification pending**

Issue: [#17](https://github.com/chrissotraidis/goldenpad/issues/17)

This document is the source-of-truth contract, validation checklist, and
rollback record for the Preview 4 tank/control-style repair. A successful build
or package is not gameplay acceptance. The accepted iPad matrix and the
remaining reporter boundary are recorded below.

## Rejected physical candidate (2026-08-23)

The first `GoldenPad P4 Test` build is not a Preview 4 release candidate. Its
static mapping and generated-patch checks passed, but physical iPad testing
found that the checks did not cover the live mobile input path or mounted
camera invariants:

- controller right-stick look was approximately 30 percent too slow;
- holding Aim allowed synthesized C-left/C-right input to trigger GoldenEye's
  native lean, which appeared as unwanted lateral movement;
- in 1.1 Honey, left-stick Y drove the tank but left-stick X turned the turret
  instead of the hull;
- both left-stick X and right-stick X could therefore turn the turret;
- the hull could not be steered in the tested Honey configuration;
- mounted vertical look escaped GoldenEye's native -20 degree lower limit and
  reached -51.60 degrees, causing the tank model to fill most of the view;
- the mobile host still emitted Honey Fire/Aim/Weapon buttons regardless of
  the selected 1.3/1.4 control style; and
- full analog watch navigation could cross the control-style selector once per
  frame, making intermediate 1.2 and 1.3 selections difficult or impossible.

The visible KF7 Soviet is not a defect. GoldenEye names that weapon `ITEM_AK47`
internally, leaves the current ordinary weapon equipped when Bond enters, adds
tank shells to the inventory, and permits switching between the KF7 and tank
shells while mounted. Preview 4 must preserve that behavior.

The superseding repair uses one shared semantic mapping for Mac, iPhone, and
iPad. Platform hosts may gather different physical devices, but they may not
interpret GoldenEye styles or runtime states differently.

## Physically accepted iPadOS baseline (2026-08-23)

Executable SHA-256
`2b31f8868885712fbad34cef1aea20b1dee48f59fc9d930cbd3fa8b8e82b6b12`
is the accepted controller/on-foot baseline. Physical iPadOS testing confirmed:

- controller connection, left-stick menu navigation, and A-button progression;
- mission startup, normal left-stick movement, and both-axis right-stick look;
- holding left trigger keeps Bond stationary;
- while on-foot Aim is held, the left stick moves GoldenEye's native
  weapon/reticle with the expected polarity and damping;
- the right stick is neutral during on-foot Aim; and
- releasing Aim cleanly restores normal right-stick camera look.

Do not regress or reinterpret those behaviors while closing the tank matrix.
The exact signed ROM-free app, focused source inputs, generated patch halves,
and acceptance manifest are frozen locally in the ignored directory
`build-accepted-p4-on-foot-2b31f886/`. That snapshot is the immediate binary
and source rollback control; it is not a public release artifact.

The final Preview 4 publication applies one requested feel adjustment on top of
this frozen baseline: absolute external-controller normal look and mounted
turret response increase by 20 percent, from 1.56 to 1.872 degrees per frame.
The radial dead zone, response curve, native on-foot manual Aim, left-stick
movement, touch-relative look, mouse-relative look, menus, and tank mapping do
not change.

The same `2b31f886...` build subsequently passed the physical iPadOS Runway
1.1 Honey tank path: native entry, drive, hull steering, turret control, weapon
cycling, KF7 fire, Tank Shell fire, exit/re-entry, return to title, and a later
Facility on-foot regression pass. The tester independently confirmed that
retaining and cycling ordinary weapons while mounted matches original gameplay.
This proves the shared runtime behavior on iPadOS; it does not substitute for
the issue reporter's Mac keyboard/trackpad verification, so issue #17 remains
open through the Preview 4 reporter test.

### Controller-blocking candidate rejected (2026-08-23)

Executable SHA-256
`d6ecd358f1d07dc3fb2b779db0c8ceb6db4532cb380b76210a06aa66c3fc0814`
is also rejected. Physical iPad testing found that an attached controller could
not navigate the front end, so the tank matrix was unreachable. The failed-run
log proved that the controller was connected and routed to Player 1 and that
the bridge received repeated A-button `0x8000` transitions. This ruled out
Bluetooth, ownership, and neutral-lock failure and isolated the regression to
the new non-gameplay translation layer.

The retry removes all new mobile menu translation. Before live gameplay, mobile
now uses the exact accepted raw pass-through path for face buttons, D-pad, left
analog stick, and right stick. Style, Aim, and tank translation begins only
after the established gameplay predicate becomes true. The retry also logs
bounded left-stick active/neutral transitions for discriminating evidence if
the game still fails to consume valid host input.

Physical testing accepted the retry's controller connection, left-stick menu
navigation, A-button progression, mission startup, and normal analog-stick
response. The same run isolated one remaining defect: holding left trigger
entered Aim and correctly suppressed left-stick movement, but right-stick look
became effectively unusable. The log proved that Aim state and near-full-scale
right-stick samples both reached the runtime. The cause was the explicit
controller rate split: 1.56 degrees/frame normally versus 0.173 degrees/frame
while aiming.

Executable SHA-256
`0114fde73308ddfdb95d1bf8d9be939f6eed1502b86db83f0a30e9a76c13bf23`
removed that rate split, but physical testing rejected it as the Aim repair.
It kept driving the ordinary camera directly while Aim was held. That bypassed
GoldenEye's manual-sight fields, inverted the expected vertical response, and
fought the native sight damping/centering behavior.

The superseding candidate restores the original semantic boundary. During
on-foot Aim, the external left stick becomes GoldenEye's native manual-aim
analog stick, character movement is disabled by the game's Aim state, and the
right stick is neutral. GoldenEye therefore owns the weapon, reticle, damping,
and return to center. The adapter reads the live Reverse/Upright option and
compensates it so GoldenPad's default is non-inverted without changing the
user's save. Normal right-stick camera look and mounted-tank turret look retain
their accepted paths. Touch-relative and mouse-relative input remain separate
input surfaces.

Executable SHA-256
`7e8a8cf7230d10b1cb5be0841c37d45ec438603db5f39c7d38e97a7f4c17ec43`
proved the native weapon/reticle behavior in physical testing, including the
correct polarity and damping, but is rejected because it assigned that behavior
to the right stick. The installed successor changes only that physical source:
on-foot Aim reads the left stick and explicitly neutralizes the right stick.

## Scope

The shipped GoldenEye source contains one player-enterable vehicle type: the
tank. Exactly two mission setups contain it:

- Runway (`UsetuprunZ.c`, `PROPDEF_TANK` index 119)
- Streets (`UsetuppeteZ.c`, `PROPDEF_TANK` index 52)

Other `Vehicle` and `Aircraft` props are driven by AI lists, scripted paths, or
cutscenes. They do not use the player tank-entry or tank-control path and do not
receive a host input override.

Preview 4 supports GoldenEye's four original single-controller styles. The
2.1-2.4 two-controller layouts remain outside the Mac single-player input
contract and fall back to Honey semantics at the host boundary.

## Authoritative mapping

GoldenPad bindings are semantic. “Fire” must fire in every style even though
the underlying N64 button changes.

| Style | Tank drive and hull turn | Turret yaw | Fire | Aim | Weapon | Action |
|---|---|---|---|---|---|---|
| 1.1 Honey | N64 analog stick | Native turret state | Z | R | A | B |
| 1.2 Solitaire | C buttons | Native turret state | Z | R | A | B |
| 1.3 Kissy | N64 analog stick | Native turret state | A | Z | R | B |
| 1.4 Goodnight | C buttons | Native turret state | A | Z | R | B |

Shared modern behavior derived from that table:

- W/S always means drive forward/backward while mounted.
- A/D always means turn the tank hull left/right while mounted.
- Mouse/trackpad X and controller right-stick X always turn the turret.
- Mouse/trackpad Y and controller right-stick Y retain vertical look/aim.
- Space, mouse-left, and controller right trigger always mean Fire.
- Shift and controller left trigger always mean Aim.
- Q, controller weapon buttons, and wheel-down always mean next Weapon.
- Wheel-up emits the active style's Weapon+Fire chord for previous Weapon.
- E, mouse-right, and controller action buttons remain native B for
  enter/exit/reload/action in every 1.x style.

On foot, 1.1/1.3 use analog Y for forward/back and native C-left/C-right for
sidestep. Styles 1.2/1.4 use the four C buttons for movement, exactly as the
original layouts require. Holding Aim restores GoldenEye's original division:
the left stick moves the native weapon/reticle without moving Bond, and the
right stick is neutral. Tank entry and startup publish neutral movement/look
until GoldenEye's native run state reaches `TANK_RUN_STATE_RUNNING`.

## Input modes

The host recognizes three mutually exclusive modes:

1. **Watch/menu**: W/S/A/D and menu pointer steps emit digital D-pad input.
   This prevents full analog Y from advancing the control-style selector once
   per game tick and skipping 1.2/1.3. Camera/right-stick look is neutral.
2. **On-foot gameplay**: the accepted modern movement and relative-look paths
   remain active.
3. **Mounted-tank gameplay**: the active 1.x style selects analog or C-button
   tank drive, while relative horizontal look updates the authoritative turret
   target and smoothed orientation directly.

Mac now uses the same strict watch-state predicate as mobile: gameplay requires
`watch_animation_state == 0`, `outside_watch_menu != 0`, and
`open_close_solo_watch_menu == 0`. Tank translation therefore cannot remain
active behind the watch.

## Implementation boundaries

- `Sources/RecompControlMapping.swift` is the single shared host mapping table.
- `Sources/Mac/RecompMacInput.swift` and `Sources/RecompPrototypeInput.swift`
  gather semantic actions, then apply that table once per publish.
- `Support/RecompPrototype/recomp_game_start.cpp` exposes live control style and
  authoritative mounted state, classifies watch/gameplay mode, and reads live
  `insightaimmode` for right-stick scaling.
- `patches/goldeneye64recomp-ios-modern-controls.patch` owns proportional tank
  turret look on the game thread. It updates named GoldenEye globals rather than
  undocumented player/camera offsets.
- Mounted vertical input updates GoldenEye's player pitch. The original render
  path derives `field_2A08` from that pitch, and the original tank update owns
  cannon-elevation clamping and smoothing through
  `g_TankTurretVerticalAngleRelated` and `g_TankTurretVerticalAngle`. GoldenPad
  must not write those elevation accumulators a second time.
- `Config/RecompPrototypeInfo.plist.in` reads the
  `GOLDENPAD_RECOMP_DISPLAY_NAME` Xcode setting. Its normal-build default remains
  `GoldenPad`; preservation-sensitive side-by-side device builds may override
  only that setting and the bundle identifier.
- `RecompiledPatches/patches.c` and `patches_bin.c` must always be regenerated
  together. CMake now rejects stale or missing turret markers.

The tracked `.patch` file, not the ignored `ref/` checkout, is the canonical
game-side change. The generated reference checkout exists only to build and
validate the app.

No ROM, save, EEPROM, settings database, or user Documents data is modified by
this repair.

## Automated checks

Run from the repository root:

```sh
scripts/verify-recomp-input-matrix.sh
git diff --check
cmake --build build-recomp-macos --config Release --target GoldenPadMac
```

`verify-recomp-input-matrix.sh` compiles the real shared mapping source and checks:

- Fire/Aim/Weapon/Action for 1.1, 1.2, 1.3, and 1.4
- on-foot and tank movement for both analog and C-button style families
- Aim and tank-entry movement suppression
- classic-mode and non-gameplay bypass behavior
- neutral-rearmed, one-edge watch/menu navigation
- mobile non-gameplay input retains the accepted raw controller pass-through
- external-controller on-foot Aim routes the left stick through GoldenEye's
  native manual-sight path and neutralizes the right stick, while normal look
  and mounted Aim retain their respective camera/turret paths
- Reverse/Upright compensation and GoldenPad's opt-in vertical inversion have
  the same meaning on iPhone, iPad, and Mac
- the tracked GoldenEye patch applies cleanly and exactly matches the external
  source files used for the build
- the generated patch contains every mounted-state/turret-state marker

Both package scripts run this verifier before staging an archive. Their archive
verifiers require the shared live input-context symbol.

### Final release evidence (2026-08-23)

- GoldenEye MIPS patch compiled and both embedded patch halves regenerated.
- Generated `patches.c` SHA-256:
  `4a829165889a4e736199841c4c4237ee6a03ed97fa1ce6d891dfc864634862ff`
- Generated `patches_bin.c` SHA-256:
  `cb3e439a8eb1587ac11b7fa29551b3f204860f993b9114ebd5331c179bc92bc6`
- Physically accepted signed ARM64 iPad test executable SHA-256:
  `2b31f8868885712fbad34cef1aea20b1dee48f59fc9d930cbd3fa8b8e82b6b12`
- Final version `0.1.0` build `4` unsigned release executable SHA-256:
  `d83361f4daa70014b378aed20b9e26dc7c787d77b0fcd000816d536aecc8e66b`
- Final unsigned IPA SHA-256:
  `ff163b0af6b54596590da8e39cbaff0b388b69f1607ca34f62ce61e7fe144130`
- Final Mac Alpha archive SHA-256:
  `63bec02ad6e323a213f9cb9d15f763a58d6eb7bd4a1a40af6341a4fb8fb333ba`
- The ARM64 iPad and Apple-Silicon Mac targets both compile with the same
  `Sources/RecompControlMapping.swift` implementation.
- Repository ROM/signing-path audit, shared input matrix, tracked-patch parity,
  generated marker checks, and `git diff --check` pass.

The signed test hash identifies the physically accepted 1.56-degree baseline.
The final release hashes include the requested 20 percent increase to 1.872
degrees per frame and have build, matrix, and package proof. The final unsigned
release executable did not receive a second physical-device pass.

### Temporary iPad smoke-test deployment (2026-08-23)

This is a private device test, not a Preview 4 release artifact:

- display name: `GoldenPad P4 Test`
- bundle identifier: `com.chrissotraidis.goldenpad.preview4test`
- source app retained: `com.chrissotraidis.goldenpad.recomp-prototype`
- iPad Release executable SHA-256:
  `2b31f8868885712fbad34cef1aea20b1dee48f59fc9d930cbd3fa8b8e82b6b12`
- the preinstall `Documents` and `Library` backup remains local and untracked;
  no ROM, save, preference, or backup path enters the repository or package
- the P4 Test bundle was reinstalled in place; it was not uninstalled
- the TLB-free ROM, runtime ROM, current save, save backup, and preferences
  plist were read back and remained byte-for-byte unchanged
- the left-stick native manual-Aim candidate was deliberately left closed after
  installation
  so the user, not a CoreDevice launch, performs its first run

The iPad test exercises the shared semantic mapping, aim suppression, tank-state
translation, game-side turret patch, and controller sensitivity. It cannot
accept Mac-only keyboard, trackpad, or mouse gathering.

Device rollback is intentionally narrow: uninstall only
`com.chrissotraidis.goldenpad.preview4test`. Do not uninstall, replace, or clear
the source app. Private ROM, save, preference, backup, and log data remain
outside the repository and must never be committed or packaged.

## Physical acceptance gate

Test the installed iPad build with one extended gamepad first. Mac keyboard,
trackpad, and mouse acceptance follows only after the iPad controller rows pass.

### Runway and Streets, each style 1.1-1.4

- Enter the tank with controller Action and let the hatch transition finish.
- Left-stick Y drives forward/backward.
- Left-stick X turns the hull left/right.
- Right-stick X turns the turret smoothly in both directions and responds to
  small versus large motion without binary stepping.
- Right-stick Y moves the turret up/down without pitching below the native
  mounted limit or filling the view with the tank model.
- Drive, hull-turn, and turret-look simultaneously.
- Right trigger fires only the currently selected weapon. Confirm the retained
  KF7 fires when selected, then change to Tank Shells and confirm the cannon
  fires instead. They must never fire simultaneously. Seeing the KF7 while
  mounted is expected original behavior.
- Hold Aim with left trigger while deliberately moving the left stick in all
  directions: Bond/tank must remain stationary while right-stick aim works.
- Change weapons forward and backward without firing a shell accidentally.
- Open the watch while mounted, navigate in all four directions, and select
  1.1, 1.2, 1.3, and 1.4 one step at a time.
- Close the watch and confirm no stuck drive, turret, Fire, or Aim input.
- Repeat after death/restart and after mission abort/re-entry.

### Regression rows

- Dam or Runway on foot: left-stick movement, both right-stick axes, Fire, Aim,
  Action, Weapon, and Duck. The final Preview 4 right-stick response is 20
  percent faster than the physically accepted `2b31f886...` baseline and 56
  percent faster than the original rejected P4 Test rate.
- On foot, hold left trigger and move the left stick in all directions. Bond
  must remain stationary while the native weapon/reticle follows the left
  stick in all four directions without rotating the ordinary camera directly.
- Confirm the right stick does nothing while on-foot Aim remains held.
- Hold the left stick off-center while Aim remains held: the sight must remain
  at the requested offset rather than being pulled immediately toward center.
  Release the left stick and then Aim, confirming native recentering and a
  clean return to normal right-stick camera look.
- Title, mission select, watch opening/closing, pause, death, and return to title:
  no pointer-capture or navigation regression.
- One touch-only iPad Runway pass after controller acceptance: both look axes,
  movement, Aim, Fire, Action, and Weapon.
- Existing Mac renderer/audio soak and Dam/Surface scene comparisons remain
  mandatory; this input patch does not waive them.

Record each row as PASS/FAIL with style, input device, mission, and build hash.
Do not call Preview 4 accepted from build, launch, or package evidence alone.

## Rollback

Preview 4 is isolated in a focused merge. Preferred rollback after merge:

```sh
git revert <preview-4-input-fix-commit>
```

Then rebuild the external GoldenEye64Recomp reference from the reverted tracked
patch set and regenerate **both** `RecompiledPatches/patches.c` and
`patches_bin.c`. Never restore only one generated half.

Files owned by this focused change:

- `CMakeLists.txt`
- `Config/RecompPrototypeInfo.plist.in`
- `Sources/RecompControlMapping.swift`
- `Sources/Mac/RecompMacInput.swift`
- `Sources/RecompPrototypeInput.swift`
- `Sources/RecompPrototypeApp.swift`
- `Sources/RecompPrototypeAudio.swift`
- `Sources/RecompPrototypeMetalCanvas.swift`
- `Support/RecompPrototype/recomp_game_start.cpp`
- `Support/RecompPrototype/recomp_rt64_surface_stub.cpp`
- `Tests/RecompControlMappingTests.swift`
- `patches/goldeneye64recomp-ios-modern-controls.patch`
- `scripts/package-recomp-macos-alpha.sh`
- `scripts/package-recomp-prototype-ipa.sh`
- `scripts/verify-recomp-input-matrix.sh`
- `scripts/verify-recomp-macos-alpha.sh`
- `scripts/verify-recomp-prototype-ipa.sh`
- `docs/PREVIEW_4_INPUT_FIX.md`

Do not use a broad worktree reset for rollback. This checkout contains unrelated
user-owned edits. Revert the focused commit, regenerate the ignored external
patch pair, rebuild, and rerun the package verifier. If rollback occurs before
commit, construct and review a reverse diff limited to the file list above.
