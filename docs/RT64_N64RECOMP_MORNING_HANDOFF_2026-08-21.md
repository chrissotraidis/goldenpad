# GoldenPad recomp morning handoff — 2026-08-21

## Accepted baseline

The installed `GoldenPadRecompPrototype` build is the accepted mainline
baseline. The 2026-08-21 physical-iPad test successfully selected and launched
multiple missions, including Bunker, and sustained normal gameplay. The Xbox/
MFi controller mapping felt responsive for movement, looking, aiming and
firing. The former right-edge blue line and the severe Bunker blue-void
rendering failure were not visible in the final run. High-resolution RT64 output
looked substantially better than the earlier MGB64 baseline.

The accepted installed/local app executable SHA-256 is
`addd13724a405237585aa3835000a220283996bc83c980b6263ea5c3735a4826`.

This acceptance is intentionally scoped. A few intermittent map glitches were
still observed, multiplayer was not exercised, and the lifecycle failure below
ended the run. Keep the former MGB64 app as a deprecated fallback while this
recomp build becomes GoldenPad's main development baseline.

## Morning worklist

1. **Screenshot/background return can freeze gameplay.** During a mission, the
   tester took an iPad screenshot, returned to GoldenPad, and found gameplay
   completely frozen. The app process remained alive. Persistent diagnostics
   recorded `host became inactive`, `host became active`, a stale-audio discard,
   and then a watchdog with RT64 counters fixed at `dl=11144`, `vi=11143`, and
   `presented=11051`. There was no new GoldenPad `.ips` crash report at 1:00 AM.
   Treat this as a lifecycle hang, not a confirmed process crash. Reproduce and
   diagnose it tomorrow; do not fold a speculative fix into tonight's baseline.
2. **The optional center reticle is misplaced.** Enabling it placed the reticle
   at the extreme top-right beside the three-dot button rather than at the
   center of the rendered game viewport. The 1:00 AM screenshot records the
   bad placement.
3. **Add `Return to Main Menu` to the three-dot menu.** Start opens GoldenEye's
   watch, but the tester could not find a reliable route from an active mission
   back to mission select/title. This should be an explicit host-menu action,
   with a confirmation if it discards mission progress.
4. **Make graphics-setting application clear.** Toggling N64 three-point
   filtering, 2x MSAA, and Native N64 versus Automatic high resolution produced
   no obvious immediate visual change. Establish whether each setting is live
   or restart-only, then communicate that in the UI. If a restart is required,
   provide an explicit restart/apply flow instead of leaving the result
   ambiguous.
5. **Exercise multiplayer with multiple physical controllers.** Do not assume
   multiplayer becomes available merely because another controller connects.
   Verify controller enumeration, player-port assignment, touch-overlay
   behavior and an actual multiplayer match with at least two controllers.
6. **Record intermittent map glitches by stage and location.** The final missions
   were overwhelmingly stable, but the tester still saw occasional geometry or
   map glitches. Capture stage, room, camera angle and diagnostics when one is
   reproduced. Do not reopen the rejected camera-basis experiment, which made
   gameplay unplayably slow.
7. **Retest physical-speaker audio.** Runtime counters showed no drops or
   underruns in the accepted run, but occasional static was reported in earlier
   physical listening. Keep this as a listening gate rather than treating queue
   health alone as final audio acceptance.

## Preserved evidence

- User screenshot: `Screenshot 2026-08-21 at 1.00.22 AM.png` (kept outside the
  repository because it is a private gameplay capture).
- Current and previous bounded application logs were copied from
  `Library/Application Support/GoldenPadRecomp/Logs` before relaunching or
  rebuilding.
- The current log SHA-256 is
  `8996f3cc5936f5d12d424b336365f9cdca490810d6a34c6f878924d2b1aecd7a`.
- The previous log SHA-256 is
  `c1a3e2d7d498515a25e062662cde57854292d4cb98116d3f3487136fa6aa6fbf`.
- The most recent pre-existing CPU-resource report was also copied for later
  comparison; its SHA-256 is
  `b5d17d962435f86dd054b7faeac7976842fc2b905dfb7522d866fe29637f0f73`.
- Raw logs, `.ips` files, ROM data, saves and gameplay captures remain private
  local evidence and are not committed.

## Release boundary

The final run is strong physical evidence for a public tech-demo baseline, not
proof that every mission, multiplayer, screenshot/resume path or audio route is
release-complete. Tomorrow's first gate is the screenshot/background-return
freeze; the other work should remain small and independently verifiable.
