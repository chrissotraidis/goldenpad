# GoldenPad Preview 11 — runtime reliability

iPhone/iPad version **0.1.0, build 12**, for iOS/iPadOS 17+.

## Changes since Preview 10

- Correct the runtime controller initialization mask so every connected port is represented.
- Preserve previous button/stick data on a failed controller read while updating its error status; leave unpolled channels untouched.
- Let pending messages for other queues progress when one destination is full. Required completion messages are retained; stale video/audio retrace notifications can expire.
- Guard RT64 presentation against zero-size or inverted video regions.
- Replace undefined null-pointer member-offset arithmetic with standard `offsetof`.

These are focused correctness repairs from the documented upstream research and local validation. They do not establish a frame-rate gain, an A12X crash fix, or a cure for every freeze/disconnect symptom. Online multiplayer remains unsupported; local multiplayer remains experimental. The public Mac package stays on Preview 9.

## Validation and update

The build 12 candidate was installed in place on a physical iPad Pro. An independent readback through a fresh USB file-service connection found all 11 backed-up Documents/Library files byte-identical, including both ROM copies, active and backup saves, and preferences. iPadOS relocated the data container during the update. Remote launch timed out; the owner subsequently opened/tested the app, reported that it worked fine, and approved release on September 25, 2026. This is a general hands-on check, not completion of the full device/controller/lifecycle matrix.

The runtime regression suite passes 11 checks against actual runtime sources with AddressSanitizer and UndefinedBehaviorSanitizer. The release process rebuilds the iPhoneOS app, reruns the input/ROM/package audits, and compares its executable with the accepted candidate before publication. Exact release hashes are in `GoldenPad-0.1.0-preview.11-SHA256SUMS.txt`; source and dependency identities are bundled in `BuildIdentity.txt`.

Download the unsigned IPA from [Preview 11](https://github.com/chrissotraidis/goldenpad/releases/tag/v0.1.0-preview.11). Re-sign with your existing sideloading setup and update in place; do not delete the app. Supply your own supported ROM. Existing diagnostics and **••• → Report a Problem** remain available.

The public software source archive includes pinned public dependencies and build scripts, excludes user ROM/private generated game code, and is not a certification of complete GPL corresponding-source delivery. The existing developer-preview source/licensing review remains open.

See [native-port research and validation](NATIVE_PORT_RESEARCH_2026-09-24.md) and [Discord announcement](DISCORD_PREVIEW_11.md).
