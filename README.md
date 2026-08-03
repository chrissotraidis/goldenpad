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
and N64 retail dumps without retaining them. It does not run the game yet: the
selected static-recomp core is blocked on a reproducible, provenance-clean
public input pipeline; see [`docs/STATUS.md`](docs/STATUS.md).

## Legal boundary

No ROM or copyrighted game assets are included. Users must supply their own
legally obtained original retail game data. The project does not use the leaked
XBLA build, leaked source, or unclear proprietary dependencies.

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

Controls, controller, multiplayer, save, gameplay screenshots and final IPA
instructions will be added only as those gates are proven in GoldenPad itself.
Contributions must preserve the provenance and no-ROM rules above.
