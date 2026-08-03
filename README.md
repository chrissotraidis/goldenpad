# GoldenPad

<p align="center">
  <img src="Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" width="128" alt="GoldenPad app icon">
</p>

GoldenPad is an early research project for a native iPhone and iPad port of the
original retail Nintendo 64 game. It targets statically recompiled Apple ARM64
game code and Metal rendering—not a general N64 emulator.

## Current status

Research, an Apple Silicon desktop feasibility baseline, and the first native
iPhone/iPad foundation are complete. The SwiftUI shell renders through Metal,
builds for ARM64 simulator and device SDKs, and privately validates Z64, V64,
and N64 retail dumps without retaining them. Atomic settings/save persistence
and common touch/Game Controller snapshots are also live. The host includes
exact N64 button masks, modern and southpaw dual-stick presets, and separately
persisted phone/tablet touch layouts with move, size, visibility, opacity,
sensitivity, dead-zone and gyro settings. It does not run the title or gameplay
yet, but the first production-core gate now passes: all 135 MGB64 game
translation units plus 28 upstream native system/asset glue units and one
GoldenPad mobile OS adapter compile into 164-object ARM64 archives for
both Apple mobile SDKs. GoldenPad links and executes a deterministic upstream
game-code probe on iPhone and iPad. MGB64's complete native Metal backend now
also compiles for both SDKs after excluding two macOS-only display-sync writes.
Its Fast3D interpreter now compiles as a separate two-object ARM64 archive for
both SDKs without SDL or desktop OpenGL symbols, and the UIKit host supplies
MGB64's exact `platformGetMetalLayer` boundary. The complete Fast3D/Metal closure
now links into opt-in ARM64 Simulator and device apps and presents real,
ROM-free empty frames through MGB64's backend. Sequential phone/tablet launches
proved backend initialization and first-frame encoding at full drawable size.
After the existing SHA-1 gate, linked-core builds can now hand the normalized
retail data to MGB64 as a volatile in-memory copy; sequential phone/tablet proof
confirmed the handoff, followed by complete app-container removal.
The native file/resource table is now patched to exact offsets inside that
owned buffer, including the Dam background resource. The real MGB64 scheduler
and its graphics-client queues now initialize without SDL on both mobile SDKs;
MTKView now delivers a bounded cooperative retrace after that state is ready,
with sequential phone/tablet proof at full drawable size.
The same host also exposes the exact `UIView`/`CAMetalLayer` pair RT64 expects.
All 56
generated Metal shaders compile for both Apple mobile SDKs, the complete
210-object RT64 static library and its 246-object dependency closure link into
GoldenPad, and the real Metal device/command-queue/swapchain initializes on
both iPhone and iPad simulators. MGB64 is the selected production-core
candidate; the remaining portable platform closure and title/menu startup are
the next build gates.
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
