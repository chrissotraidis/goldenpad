# Local multiplayer roadmap

Updated: 2026-08-21

## Immediate Preview 2 priority

GoldenPad's immediate multiplayer goal is deliberately narrow: a stable,
playable two-player local match on iOS and iPadOS using an external controller
for Player 1 and touch controls for Player 2. The original multiplayer menus,
horizontal split-screen layout, match rules and save behavior must remain owned
by GoldenEye.

The former RT64 KSEG1 address-mask crash is repaired. Source tracing found that
the GoldenEye64Recomp sky, scissor, fade and depth-clear patches could affect the
full framebuffer while GoldenEye renders players sequentially into separate
viewports. Because the player render order is shuffled each frame, one player's
work could erase the other and produce the observed flashing, black frame
regions and partial geometry.

The Preview 2 candidate now constrains those operations to the active player
viewport and preserves the selected game framebuffer. On 2026-08-21, an ARM64
iPad Simulator build entered and sustained a real two-player Temple match using
controller Player 1 plus touch Player 2. Both horizontal views remained visible
through more than 11,000 presented VI updates, Player 1 movement changed only
its camera, and Player 2 FIRE registered independently. A later physical-iPad
four-player run of executable SHA-256
`0976dcdfd17de60beda8e8e60ccff3fc81da7da0b2ef43f159cdea061149677d`
kept all four views coherent and did not reproduce the former large
black/checkerboard corruption. Slight lighting flicker remained, so this is a
stable experimental render baseline rather than final multiplayer acceptance.

The repair gate is:

1. preserve GoldenEye's selected back framebuffer during every player pass;
2. constrain sky, background, fade and depth-clear operations to the current
   player's logical viewport;
3. enter and sustain a real two-player match with both views continuously
   visible and independently controlled;
4. preserve accepted single-player rendering, controls, audio, saves and
   lifecycle behavior; and
5. preserve the accepted physical-iPad render baseline and complete normal
   physical iPhone/iPad input-routing checks before local multiplayer is
   described as fully supported.

Three/four-player layout, online networking and enhanced multiplayer graphics
are not part of this first repair.

## Validation matrix for the immediate repair

- Temple: baseline horizontal split-screen and sustained movement in both views.
- Facility or Bunker: indoor portals, doors and fade transitions.
- Cradle or another outdoor map: fog, sky fill and long-distance geometry.
- Pause/watch, death/fade and return-to-menu paths.
- Native N64 and Automatic high-resolution output; 2x MSAA on and off.
- iPad and iPhone landscape layouts, without a live console or long recording
  during hands-on performance acceptance.

Build/install/process evidence proves only that the candidate runs. Acceptance
requires both views to remain visually stable while Player 1 controller and
Player 2 touch input operate simultaneously.

## Deferred local multiplayer work

The following work is valuable but must not delay the two-player repair.

### Three and four players

GoldenEye uses half-width left/right viewports for three- and four-player
matches. RT64 may require explicit extended-GBI viewport origins so the left and
right players remain anchored to their widescreen halves. This is a separate
gate after horizontal two-player split-screen is accepted.

The iOS/iPadOS test build now includes an opt-in **Experimental four-player
render test** beneath the existing two-player input test. It advertises controller
Player 1, touch Player 2 and neutral Players 3/4 through the same bounded port
bridge. It never injects host button presses and makes the extra ports visible
only while explicitly enabled.

On 2026-08-21, the ARM64 iPad Simulator reported all four ports, GoldenEye
selected four players, and a real Temple match opened with four correctly placed
quadrants. Controller Player 1 movement and touch Player 2 FIRE/ACTION registered
independently; neutral Players 3/4 remained stationary. Player 1's pause/watch
UI stayed confined to the upper-left quadrant while the other three views
remained intact. All four views were still intact after 10,773 presented VI
updates. The later physical-iPad run kept every quadrant coherent across 3,336
consecutive frame comparisons and 54,652 presented VI updates, with zero audio
drops or underruns. Real Player 3/4 controller routing remains open; macOS still
needs platform-appropriate assignments because it has no touch input.

### Enhanced multiplayer visuals

The current recomp already disables distance-based model LOD almost everywhere;
Jungle remains an unexplained exception. GoldenEye also applies independent
multiplayer reductions to fog/view distance, flying debris, shattered glass,
smoke lifetime, scorch marks, cartridge casings and stage props.

These should be evaluated as three independently measurable groups:

1. view distance and model LOD;
2. transient effects and their fixed buffers; and
3. decorative world props omitted by multiplayer setup data.

Higher RT64 output resolution does not remove the original game-side memory,
display-list or per-frame work limits. Before lifting a limit, record remaining
stage-pool memory, graphics/vertex buffer headroom, peak active effect counts,
frame cadence and physical-device thermal behavior. Do not restore AI, collision,
paths, spawn logic or other gameplay-bearing single-player objects under a
visual-quality setting.

### Network multiplayer

Online and peer-to-peer play require deterministic simulation, ROM/build/mod
compatibility, synchronized input and lifecycle/reconnect behavior. They remain
research work only. No network compatibility claim should be made until local
two-, three- and four-player behavior is stable and deterministic.

## Sequencing

1. Preserve the physically coherent experimental render baseline and complete
   the remaining two-player input/lifecycle matrix.
2. Validate real three/four-controller routing separately from the accepted
   neutral-port four-player render diagnostic.
3. Extend the diagnostic to macOS with platform-appropriate assignments.
4. Restore enhanced visual groups individually behind instrumentation.
5. Reassess networking only after local multiplayer is reliable.
