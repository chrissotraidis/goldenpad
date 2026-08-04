# GoldenPad

<p align="center">
  <img src="Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" width="128" alt="GoldenPad app icon">
</p>

GoldenPad is an early research project for a native iPhone and iPad port of the
original retail Nintendo 64 game. It targets natively compiled Apple ARM64 game
code and Metal rendering—not a general N64 emulator.

## Current status

Research, an Apple Silicon desktop oracle, and the native iPhone/iPad production
path are established. GoldenPad now compiles all 135 MGB64 game translation
units, 70 explicitly audited upstream native system/portable units, and five
project-owned mobile adapters into 210-object ARM64 archives for both Apple
mobile SDKs. A separate five-object Fast3D frontend and the complete native
Metal backend link without SDL, OpenGL, AppKit, matching-target SDK
implementations, ROM data, or extracted media.

After exact SHA-1 validation, the app keeps the supported retail ROM only in a
private core-owned memory buffer, patches MGB64's native resource table, starts
`bossEntry` once on a background thread, and lets the UIKit-owned `MTKView`
drive the cooperative scheduler. The GoldenEye title sequence, front-end menus,
and Dam mission now render natively through Metal. Strict sequential proof passed
on iPhone 16 Pro at 2622×1206 and iPad Pro 11-inch (M4) at 2420×1668; each app
was terminated, uninstalled, and its simulator shut down before the next run.

The setup shell yields to a full-screen landscape gameplay surface after boot.
Phone/tablet touch layouts and `GCController` state feed the real libultra-style
controller boundary; a deterministic end-to-end probe observed movement,
right-stick aim, and `B|Z` in the C host. MGB64's clean-room sequence/SFX
synthesizer decodes the retail banks, pumps on game retraces, and feeds a bounded
22.05 kHz stereo PCM ring consumed by `AVAudioEngine`; both device classes
produced non-zero PCM in runtime proof. The 2 KiB game EEPROM now restores from
and flushes atomically to Application Support across relaunch. A diagnostic
Start script traversed the real controller boundary and authentic front end,
selected Agent/Dam, and reached live gameplay on both simulator classes.
A second game-state probe proved movement, dual-stick aim, fire, B reload/action,
A weapon cycle, and Start pause/watch semantics on both classes. An explicitly
scripted diagnostic also reached the real mission-status/statistics reports and
proved the resulting Dam/Agent EEPROM progression survives relaunch on both
classes. A controller-only Facility probe then advanced through the authentic
next-mission briefing, waited for first-person control, approached the stock
bathroom door cluster, opened model object 159, continued into the next corridor,
and opened model object 155 with normal movement, look and B input on iPhone
followed by iPad. That closes the first chained-world-interaction subgate;
organic objectives and mission completion, physical-device controls,
multiplayer, and final packaging remain open.
A separate promoted Dam route now travels more than 4700 world units from the
stock spawn on both simulator classes using only normal N64 controller frames.
Its read-only objective vector remains unchanged, so this is deliberately
reported as deep traversal rather than objective completion.
A deeper `--dam-nav-probe` derives its route from the retail setup's live
waypoint and linked-door graphs, crosses the two-door Dam interlock through
normal movement and B input, and reaches the upper graph's node 179 within 500
world units. The same binary passed first on iPhone at 15917 units and then on
iPad at 15879; both retained objectives `[0,0,0,0]` with `stateMutation=0`.
This is not the lower bungee graph or organic Dam completion. Hands-on control
feel and the visible FPS counter also remain unaccepted; neither is release
evidence yet.
An exploratory `--dam-bungee-probe` now derives the lower exit pad from the
loaded retail AI command stream, routes across the live waypoint graph, opens
the interlock and padlocked gate through controller input, and observed the
retail room trigger plus forced velocity with `controllerOnly=1` and
`hostMutation=0`. Promotion is still open: repeated clean-phone runs exposed a
stock actor/linked-door collision stop at `open=750/1000`, so the required clean
iPhone then same-binary iPad gate has not passed. This is not yet organic Dam
completion.
The same host also exposes the exact `UIView`/`CAMetalLayer` pair RT64 expects.
All 56
generated Metal shaders compile for both Apple mobile SDKs, the complete
210-object RT64 static library and its 246-object dependency closure link into
GoldenPad, and the real Metal device/command-queue/swapchain initializes on
both iPhone and iPad simulators. MGB64 is the selected production core; RT64
remains a verified optional renderer/reference path.
GoldenRecomp remains a static-recomp reference because its public input pipeline
is incomplete. See [`docs/STATUS.md`](docs/STATUS.md).

## Legal boundary

No ROM or copyrighted game assets are included. Users must supply their own
legally obtained original retail game data. The project does not use the leaked
XBLA build, leaked source, or proprietary matching-target SDK implementation
code. Community decomp/recomp rights concerns and the separate commercial or
official-distribution gate are recorded in [`docs/LEGAL.md`](docs/LEGAL.md).

This project is unofficial and is not affiliated with or endorsed by Nintendo,
Rare, Microsoft, MGM, Danjaq, EON Productions, or any other rights holder.

## Documentation

- [Plan](docs/PLAN.md)
- [Status](docs/STATUS.md)
- [Research and pinned upstreams](docs/RESEARCH.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Building](docs/BUILDING.md)
- [Testing](docs/TESTING.md)
- [Legal and provenance policy](docs/LEGAL.md)
- [Original art provenance](docs/ART.md)
- [Worklog](docs/WORKLOG.md)

Gameplay, controller, multiplayer and final IPA instructions will be added only
as those gates are proven in GoldenPad itself. Contributions must preserve the
provenance and no-ROM rules above.
