# GoldenEye and GoldenPad control contract

Updated: 2026-08-23

This is the authoritative control reference for GoldenPad. It describes what
the reconstructed GoldenEye game actually does, what GoldenPad currently adds,
and which behavior Preview 3 is allowed to change. It applies to iPhone, iPad,
Mac, touch, keyboard/mouse, connected controllers, single-player, and local
split-screen.

The statements labelled **GoldenEye fact** are confirmed in the pinned
reconstructed source under `ref/007`. Statements labelled **Current host**
describe GoldenPad code. Statements labelled **Preview 3 decision** are product
rules, not claims about the original game.

## Product contract

**GoldenEye fact:** GoldenEye receives one N64 stick, a D-pad, four C-buttons,
and N64 face/shoulder buttons. GoldenEye itself assigns their meanings according
to the active native control style and native options.

**Preview 3 decision:** GoldenPad may translate modern hardware into those N64
inputs or provide a clearly named direct-camera adapter. It must not silently
pretend that every GoldenEye control style gives the same meaning to a stick or
button.

Preview 3 development and acceptance use **GoldenEye 1.1 Honey**. The other
native styles remain valid and must not be overwritten. Until a GoldenPad
adapter reads the live style and translates against it, that adapter is
Honey-only. Unsupported combinations must fall back to raw N64 input or show a
clear warning.

## The native input pipeline

`MoveBond` in `ref/007/src/game/bondview2.c` is the principal gameplay input
interpreter. It receives the current N64 stick X/Y, current button bits, and
previous button bits. It then:

1. removes a five-unit analog dead zone;
2. selects action buttons from the active control style;
3. decides whether the stick means walking/turning or looking;
4. interprets D-pad and C-button directions;
5. enters or leaves manual sight aim using the native Aim Control option;
6. applies native vertical polarity, auto-aim, look-ahead, crouch, lean, weapon,
   action, and firing behavior.

`cur_player_get_control_type()` in `ref/007/src/game/options.c` returns the live
style from `g_CurrentPlayer->cur_player_control_type_0`. This is the value a
future host-facing getter must expose. Swift must not hard-code an RDRAM address
or keep a second copy of the native style in `AppStorage`.

## Native 1.x styles

The labels shown on the in-game controller screens are defined by
`game_control_styles` in `ref/007/src/game/options.c`. The enum values are
`CONTROLLER_CONFIG_HONEY`, `CONTROLLER_CONFIG_SOLITARE` [source spelling],
`CONTROLLER_CONFIG_KISSY`, and `CONTROLLER_CONFIG_GOODNIGHT` in
`ref/007/src/bondconstants.h`.

### Normal movement and look

| Native input | 1.1 Honey | 1.2 Solitaire | 1.3 Kissy | 1.4 Goodnight |
| --- | --- | --- | --- | --- |
| Analog Y | Walk forward/back | Continuous vertical look | Walk forward/back | Continuous vertical look |
| Analog X | Turn left/right | Turn left/right | Turn left/right | Turn left/right |
| D-pad or C up/down | Digital vertical look | Step forward/back | Digital vertical look | Step forward/back |
| D-pad or C left/right | Sidestep left/right | Sidestep left/right | Sidestep left/right | Sidestep left/right |

The controller-screen shorthand calls the Honey/Kissy analog stick **Move** and
the Solitaire/Goodnight stick **Look**. The more exact runtime behavior above
matters for adapters: Honey analog X is turning, not strafing. In every 1.x
style, native left/right sidestep comes from `L_JPAD | L_CBUTTONS` and
`R_JPAD | R_CBUTTONS` in `MoveBond`.

For Honey/Kissy, C or D up/down changes the vertical view and the analog Y axis
walks. For Solitaire/Goodnight, C or D up/down becomes digital forward/back and
analog Y becomes continuous pitch. `MoveBond` sets `disableLookAhead` for
Solitaire/Goodnight because their analog stick is the look control.

### Action buttons

| Native input | 1.1 Honey | 1.2 Solitaire | 1.3 Kissy | 1.4 Goodnight |
| --- | --- | --- | --- | --- |
| Z trigger | Fire | Fire | Aim | Aim |
| Either L or R trigger | Aim | Aim | Change weapon | Change weapon |
| A button | Change weapon | Change weapon | Fire | Fire |
| B button | Action | Action | Action | Action |
| Start | Pause/watch | Pause/watch | Pause/watch | Pause/watch |

`MoveBond` implements this as two action families:

- Honey/Solitaire: `shootButtons = Z`, `aimButtons = L | R`, and
  `invButtons = A`.
- Kissy/Goodnight: `shootButtons = A`, `aimButtons = Z`, and
  `invButtons = L | R`.

“Change weapon” is more than a simple held button. A rising edge on the weapon
button advances; holding the weapon button while pressing Fire selects in the
opposite direction. The same action/weapon combination can detonate remote
mines. A semantic host adapter must therefore preserve button edges and valid
combinations, not only final high-level commands.

### Manual sight aim

**GoldenEye fact:** Aim is a mode, stored at runtime as
`g_CurrentPlayer->insightaimmode`. In Hold mode it follows whether an aim button
is down. In Toggle mode a rising aim-button edge flips it. This is implemented
in `MoveBond` using `cur_player_get_aim_control()`.

While manual sight aim is active in any 1.x style:

- the analog stick controls fine manual gun aim; large deflection also drives
  aim-turn/vertical movement;
- D-pad/C left and right lean left and right;
- D-pad/C down requests a lower crouch position. The reconstructed 1.x
  `crouchUp` expression uses `~buttons` with the up masks and is
  counterintuitive; the precise release/C-up behavior must be confirmed in a
  native runtime trace rather than “corrected” from intuition;
- for weapons whose flags disable crouch, D-pad/C up/down controls zoom instead;
- normal auto-aim and normal look-ahead are disabled for the aiming interval;
- Fire remains the style-specific Fire button.

This context sensitivity is why a GoldenPad setting cannot globally relabel a
C direction as only “sidestep.” C-left/C-right means sidestep during normal
Honey gameplay and lean during native manual aim. C-up/C-down means native
vertical look during normal Honey gameplay but crouch-state/zoom input while
aiming. The source-level `crouchUp` ambiguity above remains an explicit open
verification item.

### Reverse/Upright polarity

`game_options_entries` assigns stored value 0 to **Reverse** and value 1 to
**Upright**. `MoveBond` applies the selected polarity to analog pitch and the
digital up/down look directions after decoding the control style. The internal
variable name `invertPitch` is counterintuitive: code should use the option's
public meaning, not infer behavior from that local name.

## Native game-owned options

These options are defined in `game_options_entries` in
`ref/007/src/game/options.c` and applied in `MoveBond` or
`bondviewMovePlayerUpdateViewport` in `ref/007/src/game/bondview2.c`.

| GoldenEye option | Exact native choices | Runtime meaning | GoldenPad rule |
| --- | --- | --- | --- |
| Look Up/Down | Reverse / Upright | Selects native vertical look polarity after style decoding. | Do not present a duplicate as though it changes the save option. |
| Auto-Aim | Off / On | Enables native X/Y target assistance outside manual sight aim. | Game-owned only. |
| Aim Control | Hold / Toggle | Hold follows aim-button state; Toggle flips on a rising edge. | Host touch latching must be explicitly separate. |
| Sight On-Screen | Off / On | Controls GoldenEye's own gun sight visibility in solo. | Not the same as GoldenPad's center overlay. |
| Look Ahead | Off / On | Enables native automatic movement-centering/look-ahead behavior. | Game-owned only; native code suppresses it for 1.2/1.4. |
| Ammo On-Screen | Off / On | Controls the native ammo display. | Game-owned only. |
| Screen | Full / Wide / Cinema | Changes the native viewport. | Separate from RT64 output resolution. |
| Ratio | Normal / 16:9 | Changes the native aspect calculation. | Separate from GoldenPad window/device aspect. |

### Aim Hold/Toggle compatibility

GoldenPad's current touch **Aim button: Hold/Toggle** setting controls whether
the host keeps N64 R held. GoldenEye's native **Aim Control: Hold/Toggle**
controls how the game interprets the resulting R edge/state. They are not the
same option.

| GoldenPad touch button | GoldenEye Aim Control | Result under 1.1 Honey |
| --- | --- | --- |
| Hold | Hold | Direct press-to-aim and release-to-exit. |
| Hold | Toggle | Each new touch press toggles native aim; touch release does nothing in the game. |
| Toggle | Hold | GoldenPad latches R; each host toggle enters or exits aim. |
| Toggle | Toggle | Two latches interact. Turning the host latch off creates no native rising edge, so state is confusing and can appear stuck. Do not recommend this combination. |

**Preview 3 decision:** The UI must call the host option **Touch aim button
behavior**, display the current native Aim Control value, and warn against the
double-toggle combination. Preview 3 acceptance records both settings.

## Persistence and multiplayer ownership

### Single-player

`fileSaveSettingsForFolder` and `fileLoadSettingsForFolder` in
`ref/007/src/game/file2.c` pack these into `save->options`:

- control style (`OPTION_CONTROLTYPE`);
- Reverse/Upright;
- Auto-Aim;
- Aim Control;
- Sight On-Screen;
- Look Ahead;
- Ammo On-Screen;
- Screen and Ratio.

The masks and default set are in `ref/007/src/game/file2.h`. The default control
style is Honey; default options enable Auto-Aim, Sight, Look Ahead, and Ammo.
GoldenPad must preserve the user's GoldenEye save and must not persist a second
native-style selector outside that save.

### Local multiplayer

Multiplayer does not simply reuse the solo folder's active style:

- `controlstyle_player[0...3]` in `ref/007/src/game/front.c` is selected per
  player in the multiplayer control menu.
- `init_player_BONDdata` in `ref/007/src/game/bondview.c` copies each player's
  multiplayer selection into that player's live control type.
- Sight and Auto-Aim are selected as one shared multiplayer combination in
  `mp_sight_adjust_table`; `copy_aim_settings_to_playerdata()` copies it to all
  player records.
- Native 2.1 Plenty, 2.2 Galore, 2.3 Domino, and 2.4 Goodhead consume two N64
  controllers for one player. They are not “two-player mode.”
- The front-end forces players back to a 1.x style when a three- or four-player
  match cannot allocate two controllers per player.

**Current host:** GoldenPad's experimental two-player route is external
controller P1 plus touch P2. Therefore P1 and P2 may have different native
styles. Any host semantic mapping must query the style for the port/player it
is publishing, not assume player 1's style applies to every viewport. The
four-player render test advertises neutral P3/P4; it is not four independent
input support.

The reconstructed source confirms the runtime ownership above. It does not
establish that GoldenPad currently exposes or preserves every multiplayer menu
choice across an app relaunch; that requires runtime testing.

## Current GoldenPad behavior

### Stable Preview 3 on iPhone/iPad

The source of truth for the accepted controls release is tag
`v0.1.0-preview.3`. Preview 3 retains Preview 2 movement as the default and adds
the opt-in sidestep adapter described below.

| Input path | Default Preview 3 behavior | Native assumption |
| --- | --- | --- |
| Touch Move pad | Publishes both axes as the one N64 analog stick. | In Honey, Y walks and X turns. It does not emit C-left/right. |
| Touch Look surface | Queues relative deltas into GoldenPad's direct-camera patch. | Bypasses native C-button look/sidestep and applies camera rotation after native movement. |
| Touch Fire/Aim/Action/Weapon | Emits Z/R/B/A respectively. | Correct semantic labels for Honey/Solitaire only. |
| Touch Duck | Calls a GoldenPad crouch-toggle hook. | Bypasses native Aim+C-down and directly toggles stand/squat. |
| Controller left stick | Publishes both axes as the N64 analog stick. | Honey gives walk + turn. |
| Controller right stick: Modern analog | Publishes a normalized direct-camera vector. | Does not emit C-left/right, so it cannot perform native sidestep. |
| Controller right stick: Original N64 C-buttons | Thresholds right-stick directions into C-up/down/left/right. | Restores native Honey C behavior, including sidestep and aim-context lean/crouch. |
| Controller semantic buttons | Maps Fire/Aim/Action/Weapon to Z/R/B/A. | Correct for Honey/Solitaire; wrong for Kissy/Goodnight. |

`Sources/RecompPrototypeInput.swift` owns these translations.
`Sources/RecompPrototypeTouchLayout.swift` confirms the fixed touch button masks.
The direct-camera and crouch hooks are declared in
`patches/goldeneye64recomp-ios-modern-controls.patch` and implemented by
`recomp_get_camera_inputs` and `goldenpad_recomp_consume_crouch_toggle` in
`Support/RecompPrototype/recomp_game_start.cpp`.

### Rejected accumulated experiment

The quarantined experiment introduced `ModernMovementMapper`: during gameplay
it converted left-stick X beyond 0.30 into digital C-left/C-right and published
analog X as zero. It applied that conversion to touch and to a controller using
Modern analog mode.

That does create a digital sidestep path under Honey, but physical acceptance
rejected it because it replaced Preview 2's horizontal analog behavior rather
than offering a clearly isolated option. It must not be promoted as the fix.
Its useful finding is narrower: C-left/C-right is the correct native Honey
semantic, but wholesale replacement of the established movement axis is not an
acceptable default.

### Preview 3 Mac adapter

`Sources/Mac/RecompMacInput.swift` currently assumes Honey:

- W/S publishes positive/negative N64 analog Y;
- during gameplay A/D emits digital C-left/C-right; in menus A/D returns to N64
  analog X;
- left mouse emits Z (Fire), right mouse emits B (Action), and middle click plus
  the wheel emit bounded A or A+Z weapon-cycle pulses;
- Shift emits R (Aim), E emits B (Action), Q emits A (Weapon), R requests a
  native reload, C requests crouch, and Escape emits Start without changing
  pointer capture;
- Delete releases pointer capture without sending a GoldenEye button. Losing
  app focus, including Command-Tab, also releases all held input;
- Space is unassigned by default and Control remains bindable. A one-time
  migration moves the experimental Control/Crouch default back to C without
  replacing a different user-selected binding;
- number keys 1–9 and 0 select owned inventory indices 1–10. Out-of-range slots
  are ignored and never fabricate an item;
- mouse motion and controller right-stick motion use the direct-camera bridge.

While Shift is held, W/S is deliberately withheld from the N64 stick. Under
Honey, GoldenEye reinterprets that stick as manual-aim pitch, which caused the
reported Shift+W downward movement. Mouse aim remains active; aimed keyboard
movement is stationary rather than producing a second competing look axis.

The Mac host also switches between menu and gameplay mappings through
`goldenpad_recomp_desktop_gameplay_active`. That predicate is not identical to
the more restrictive mobile gameplay predicate: it treats any nonzero value in
three watch-state fields as gameplay. Mode classification controls mouse
capture and whether A/D is analog menu navigation or C-button sidestep, so
Preview 3 must validate the title, mission load, watch opening, watch closing,
pause, death, and return-to-title transitions independently from key-focus
validation.

The direct-camera bridge currently detects aiming by testing fixed N64 R
(`0x0010`). That matches Honey/Solitaire but not Kissy/Goodnight, whose Aim
button is Z. Consequently its aim sensitivity and host vertical adjustment are
not style-correct outside Honey/Solitaire.

The Mac crouch key uses GoldenPad's direct crouch hook, not native Aim+C-down.
The game-side consumer now reads GoldenEye's current crouch position and calls
its native crouch adjustment function. It does not keep a second host latch,
and it respects the weapon flag that disables crouching. Runtime stance still
requires hands-on acceptance; a linked callback alone is not proof.

### Direct-camera limitations

The patch function `goldenpadApplyModernTouchControls` runs after
`lvlViewMoveTick`, then adds relative yaw/pitch directly to
`g_CurrentPlayer->vv_theta` and `vv_verta`. As a result:

- it does not naturally inherit the live 1.x mapping;
- it does not emit C buttons and therefore cannot itself sidestep, lean,
  crouch, or zoom;
- GoldenEye's Reverse/Upright decode happens earlier in native `MoveBond`, so
  GoldenPad maintains separate direct-camera vertical handling;
- on iPhone/iPad and Mac that host aim inversion currently uses different
  conditional logic in `recomp_get_camera_inputs`;
- aim-rate selection assumes R means Aim.

These are confirmed implementation boundaries, not proof that the direct-camera
approach must be discarded. Preview 3 must make the boundary explicit and test
it against Honey.

## Issue #8: Cannot sidestep

Reported behavior:

> You can't sidestep with touch controls or with a controller connected. Using
> “N64 C buttons” rectifies the physical controller but not touch.

### Source-backed diagnosis

1. In Honey, native sidestep is C-left/C-right or D-pad left/right. Analog X is
   turn.
2. Preview 2's touch Move pad publishes analog X/Y and its Look surface uses the
   direct-camera bridge. Neither path emits C-left/C-right.
3. A controller in Modern analog mode has the same absence: right-stick motion
   becomes direct camera motion, not C-button input.
4. Selecting Original N64 C-buttons explicitly converts physical right-stick
   directions to C directions, so native sidestep becomes reachable.
5. There is no equivalent touch option in Preview 2, exactly matching the
   reporter's follow-up.

This is a host input-reachability defect, not evidence that GoldenEye's native
sidestep code is broken.

### Preview 3 resolution contract

Preview 3 must provide sidestep as an **opt-in modern movement mode** on touch
and controller while leaving Preview 2 movement as the default until the new
mode passes physical acceptance.

The first low-risk candidate is:

- **Original movement:** left stick remains the N64 analog stick; Honey X turns.
- **Modern movement (Honey):** left-stick Y remains analog walk; left-stick X
  produces C-left/C-right sidestep; right touch/right stick remains direct look.

The first candidate is intentionally style-limited and digitally stepped. It
must include threshold hysteresis and a neutral boundary when modes change. It
must not silently activate for Solitaire/Goodnight, where C-up/down are also
movement, or for an unknown style. An analog-strafe host patch could be
investigated later, but it is more invasive than restoring reachability and is
not required to close issue #8.

The option passes only if all of these are true on physical hardware:

- touch can sidestep left/right in 1.1 Honey while continuing forward/back;
- touch can still turn/look smoothly with the Look surface;
- controller Modern movement has the same reachable actions;
- Original movement is behaviorally unchanged from Preview 2;
- watch/menu navigation does not inherit gameplay remapping;
- aim changes C-left/right to native lean rather than simultaneous sidestep;
- reconnect, overlay, background/foreground, and P1/P2 ownership changes publish
  neutral state before a new owner resumes;
- no candidate becomes the default before explicit hands-on acceptance.

## Preview 3 compatibility rules

### Required settings separation

GoldenPad settings must visibly separate:

1. **GoldenEye controls:** read-only live style and native option values, with
   a note that they are changed inside GoldenEye.
2. **GoldenPad input adapter:** touch layout, modern/original movement, direct
   look sensitivity, dead zone/curve, mouse capture, keyboard bindings, and
   host-only overlays.

Rename ambiguous settings:

- `Aim button` -> **Touch aim button behavior**;
- `Invert vertical aim` -> **Invert GoldenPad direct aim** (unless redesigned
  to honor the native value directly);
- `Center reticle` -> **GoldenPad center marker**;
- `Duck button` -> **GoldenPad crouch toggle**.

### Native versus semantic button mapping

Button customization must use one declared model:

- **Native N64 mapping:** labels bindings N64 A, B, Z, L, R, and C directions.
  The active GoldenEye style supplies the meaning.
- **Semantic mapping:** labels bindings Fire, Aim, Weapon, and Action, then
  translates each action from the live per-player native style.

The current UI claims semantic mappings but emits fixed Honey/Solitaire buttons.
Preview 3 may safely ship native mappings for every style and a semantic modern
adapter for Honey only. It must not show Fire/Aim/Weapon labels under
Kissy/Goodnight while still emitting Z/R/A.

### Platform-specific implications

**Touch:** Touch needs its own Original/Modern movement choice. Controller-only
right-stick settings cannot solve touch reachability. Host Touch Aim and
GoldenEye Aim Control must be displayed together.

**Controller:** Original N64 C-buttons is a native compatibility path, not a
modern twin-stick layout. Modern look plus modern sidestep must be tested as a
separate adapter mode.

**Keyboard/mouse:** Preview 3's baseline is Honey. W/S is analog walk, A/D is
native C sidestep, mouse is direct look, and action buttons follow Honey.
C is the crouch default; Control remains an optional binding. Escape pauses and
Delete releases the pointer. GoldenPad must verify window first-responder/focus
before blaming GoldenEye movement, and make direct-camera aim detection use live
aim state or live style rather than fixed R.

**Crouch:** Native crouch lowering is contextual Aim+C-down; the pinned source's
1.x `crouchUp` expression is counterintuitive and requires a runtime trace
before documenting an exact stand command. The GoldenPad one-key toggle is a
host convenience that bypasses the native crouch path. It must be labelled as
such and tested for synchronization, weapon zoom conflicts, death/restart,
mission transitions, and player-port changes.

### Preview 3 released adapter

Preview 3 is a narrow control-only update from Preview 2:

- mobile **Movement adapter** defaults to **Preview 2 movement**;
- opt-in **Sidestep with left/right** preserves analog Y, converts horizontal
  touch/controller movement to C-left/C-right with 0.30 press and 0.20 release
  thresholds, and activates only in live single-player 1.1 Honey gameplay;
- switching movement modes publishes one neutral movement frame before the new
  mapping resumes;
- experimental two-player mode retains Preview 2 input because native styles
  are per player and the current host getter cannot safely classify both ports;
- the host reads the live style from the current GoldenEye player record and
  displays it without changing GoldenEye's saved option;
- Mac C is the crouch default; the candidate migrates only its experimental
  Control default back to C and preserves any other saved crouch choice;
- Escape sends Start/Pause without releasing capture; Delete explicitly
  releases capture, while application focus loss releases all held input;
- left mouse is Fire, right mouse is Action, Space is unassigned, R reloads,
  middle click/wheel cycles inventory, and 1–9/0 request owned slots 1–10;
- the crouch consumer follows GoldenEye's live stance instead of maintaining a
  separate latch, while reload and slot selection reuse native game functions;
- Shift aim suppresses keyboard stick movement so Honey cannot reinterpret W/S
  as a second manual-aim pitch input;
- keyboard movement wins over idle controller drift;
- automatic mouse capture reclaims keyboard focus once on its rising edge;
- the Mac gameplay predicate now rejects GoldenEye control-lock and multiplayer
  menu states in addition to watch transitions;
- Mac mouse input has a separate wide relative accumulator, so fast sweeps are
  not collapsed to one normalized sample, and aimed sensitivity no longer
  inherits an unexplained threefold slowdown.

The ARM64 mobile and native Mac targets compile, the matched MIPS patch
regenerates and links all crouch/reload/inventory consumers, and the final
artifacts pass their package audits. The user accepted Preview 3 as stable for
publication and specifically accepted the Mac controls. Issue #8 remains open
until its reporter confirms both touch and controller sidestep behavior and the
broader matrix below is complete.

Post-release source review keeps two neutralization gaps open. Presenting the
GoldenPad settings/share sheet does not explicitly release latched touch, and a
controller disconnect-to-none can collapse the two-player diagnostic while
republishing its held touch state as Player 1. The mobile 60 Hz publisher also
uses the default run-loop mode rather than `.common`. These are TD-14/TD-07
debts; Preview 3 acceptance does not waive their transition gates.

**Multiplayer:** Every translation is per port and per active player. A P1
controller success does not validate touch P2. Preview 3 may retain the existing
two-player experimental route, but issue #8 acceptance is first performed in
single-player Honey and then repeated separately for P1 and P2.

## Preview 3 acceptance record

Every control test records:

- build identity and platform;
- input path and player port;
- native style, defaulting to 1.1 Honey;
- Reverse/Upright;
- Aim Control Hold/Toggle;
- Auto-Aim and Sight values;
- GoldenPad Original/Modern movement mode;
- GoldenPad direct-look sensitivity/inversion;
- expected N64 output or host hook;
- observed movement, look, aim, crouch, and menu behavior.

A pass on one path does not establish parity on another. Required paths are
iPhone touch, iPhone controller, iPad touch, iPad controller, Mac controller,
and Mac keyboard/mouse.

## Source evidence index

- `ref/007/src/game/options.c`
  - `game_control_styles`
  - `game_options_entries`
  - `cur_player_get_control_type` / `cur_player_set_control_type`
  - native option getters/setters
- `ref/007/src/game/bondview2.c`
  - `MoveBond`
  - `currentPlayerSetLookAheadSetting`
  - auto-aim getters/setters
  - `bondviewMovePlayerUpdateViewport`
- `ref/007/src/game/file2.c` and `ref/007/src/game/file2.h`
  - `fileSaveSettingsForFolder`
  - `fileLoadSettingsForFolder`
  - `OPTION_*` persistence masks
- `ref/007/src/game/front.c`
  - `MP_controller_configuration_table`
  - `mp_sight_adjust_table`
  - `controlstyle_player`
  - `copy_aim_settings_to_playerdata`
- `ref/007/src/game/bondview.c`
  - `init_player_BONDdata`
- `Sources/RecompPrototypeInput.swift`
  - iPhone/iPad touch and controller translation
  - right-stick modes and quarantined movement candidate
- `Sources/RecompPrototypeTouchLayout.swift`
  - fixed semantic touch-button masks
- `Sources/Mac/RecompMacInput.swift`
  - keyboard, mouse, and Mac controller translation
- `Support/RecompPrototype/recomp_game_start.cpp`
  - direct-camera queue, fixed-R aim check, inversion, and crouch request bridge
- `patches/goldeneye64recomp-ios-modern-controls.patch`
  - game-thread camera/crouch application points
