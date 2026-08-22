# Preview 3 control plan

Updated: 2026-08-22

Preview 3 is an iteration on the accepted Preview 2 runtime. Its scope is
controls and native Mac usability. It does not include renderer changes,
multiplayer expansion, timing changes, networking, or the quarantined stacked
experiment.

## Baseline and isolation

- Base: `origin/main` at `788667e`, whose runtime matches tag
  `v0.1.0-preview.2`.
- Work branch: `codex/preview3-controls`.
- The installed Preview 2 iPad build remains the stable comparison and is not
  overwritten during implementation.
- The accumulated experiment remains separately documented and is not an IPA
  input for Preview 3.

## Candidate implemented

### iPhone and iPad

- Preserve Preview 2 movement as the default.
- Add an opt-in Honey sidestep adapter for both touch and controller input.
- Keep forward/back analog; translate left/right to native C-left/C-right.
- Use press/release hysteresis to avoid edge chatter.
- Publish a neutral movement frame when the adapter changes.
- Activate only during single-player gameplay when GoldenEye reports 1.1 Honey.
- Keep the existing experimental two-player route on Preview 2 mappings until
  the runtime exposes an authoritative style for each player port.
- Preserve raw Preview 2 input in menus, the watch, unknown states, and every
  other native control style.
- Show the live native style and explicitly separate GoldenEye-owned options
  from GoldenPad adapter settings.

### macOS

- Make Control bindable and the new-install crouch default while preserving
  existing saved bindings.
- Reclaim keyboard focus once when automatic gameplay capture begins.
- Treat GoldenEye control-lock, watch, and multiplayer-menu states as
  non-gameplay input states.
- Give deliberate keyboard movement priority over controller drift.
- Preserve fast relative mouse motion in a wide Mac-only accumulator.
- Compensate the old implicit threefold aimed-mouse slowdown.

## Verification completed

- `git diff --check`: pass.
- ARM64 Simulator isolated host build/verifier: pass.
- Native ARM64 Mac Release build with the pinned local AOT/runtime/RT64 inputs:
  pass.
- Simulator host executable SHA-256:
  `803d463099219f1b25b3f916002da4c342f540255b19fc942eb89df65822c75c`.
- Mac candidate executable SHA-256:
  `b8523e78880684f7862b6fc9c4567b449f9b82a5f65606405a00b549459bf9bd`.
- The Mac binary exports the new gameplay/style getters and wide mouse queue;
  the Simulator binary contains both movement choices and the multiplayer
  fallback label.

These checks establish compilation and linkage only.

## Physical acceptance still required

1. On Preview 2, record the control: touch movement, touch look, controller
   Modern, controller N64 C-buttons, watch/menu navigation, and one mission.
2. Install Preview 3 only after a separately identifiable IPA exists.
3. With 1.1 Honey, test Preview 2 movement first and confirm no difference.
4. Enable Sidestep with left/right and test touch, then controller Modern:
   forward/back, sidestep, diagonal movement, look, aim/lean, pause/watch, death,
   restart, background/foreground, and controller reconnect.
5. Change GoldenEye to 1.2, 1.3, and 1.4 and confirm the adapter falls back to
   Preview 2 input rather than mislabelling actions.
6. On Mac, wait until the Dam intro ends. Test W/S, A/D, Control twice, slow and
   fast mouse sweeps, aimed and hip-fire sensitivity, movement plus mouse,
   Escape release/recapture, window focus loss/recovery, and idle controller
   drift.

## Explicitly open

- Touch/controller physical acceptance for issue #8.
- Crouch-hook synchronization with native crouch, zoom restrictions, death,
  and mission transitions.
- GoldenEye Look Ahead versus direct Mac mouse pitch while moving.
- Semantic Fire/Aim/Weapon mappings for Kissy and Goodnight.
- Renderer artifacts, local multiplayer quality, native timing authenticity,
  and network multiplayer feasibility remain separate later work.

Do not call the candidate Preview 3, package it for distribution, close issue
#8, or merge it to `main` until the relevant physical acceptance gates pass.
