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
- Preview 2 remains the tagged rollback comparison. Preview 3 was installed in
  place only after explicit ROM/save/preferences backup and readback.
- The accumulated experiment remains separately documented and is not an IPA
  input for Preview 3.

## Released implementation

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

- Keep Control bindable, make C the new-install crouch default, and migrate only
  the short-lived experimental Control default while preserving other bindings.
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
- Final signed mobile executable SHA-256:
  `6ad969b56b6358e8c2731f97063b3d0dccf28674fdb4939216a289a330d8a72e`.
- Accepted Mac executable SHA-256:
  `a6352c5179ff5822f4af3d1b20e1b02bf0d5d1af46b453c9bceca435b7e59808`.
- Audited unsigned IPA SHA-256:
  `ef2ab9575d5a9df5d7d8d4138caa789625be3407ebc796a4d9339ea1fe6ba777`.
- Audited Mac Alpha archive SHA-256:
  `819bc8eabc1fc84d2a37c1847f68c8832c023f0b0643851ca3f6251244fc32ba`.
- The Mac binary exports the new gameplay/style getters and wide mouse queue;
  the Simulator binary contains both movement choices and the multiplayer
  fallback label.

Compilation and linkage alone were not used for promotion. The final mobile
build was installed in place with byte-identical private-data readback and a
ROM-validated GoldenEye launch; the final Mac controls received hands-on
acceptance. The user accepted Preview 3 as stable for publication.

## Acceptance and follow-up

1. Preview 3 build `3` was installed and launched on the attached iPad with the
   current ROMs, saves, and preferences preserved byte-for-byte.
2. The user accepted the final iPhone/iPad and Mac release as stable, with no
   newly observed major regression.
3. Issue #8 remains open for its reporter to enable Sidestep with left/right
   and verify touch plus controller Modern:
   forward/back, sidestep, diagonal movement, look, aim/lean, pause/watch, death,
   restart, background/foreground, and controller reconnect.
4. Change GoldenEye to 1.2, 1.3, and 1.4 and confirm the adapter falls back to
   Preview 2 input rather than mislabelling actions.
5. Keep the adapter opt-in until reporter confirmation and the broader physical
   matrix are complete.

## Explicitly open

- Touch/controller physical acceptance for issue #8.
- Crouch-hook synchronization with native crouch, zoom restrictions, death,
  and mission transitions.
- GoldenEye Look Ahead versus direct Mac mouse pitch while moving.
- Semantic Fire/Aim/Weapon mappings for Kissy and Goodnight.
- Renderer artifacts, local multiplayer quality, native timing authenticity,
  and network multiplayer feasibility remain separate later work.

Preview 3 is the accepted controls release. Do not close issue #8 or change the
movement default until reporter confirmation and the relevant physical gates
pass.
