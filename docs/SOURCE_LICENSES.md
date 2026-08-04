# Production source licenses

GoldenPad's production source inventory is generated from the configured
game-bearing Xcode target at the pinned MGB64 commit. The machine-readable
manifest is [`source-license-manifest.tsv`](source-license-manifest.tsv).

## Current inventory

| Boundary | Files | Meaning |
| --- | ---: | --- |
| Original-game decompilation | 161 | GoldenEye-derived code; no MGB64 MIT grant or claim of ownership |
| MGB64 first-party port code | 52 | MIT, subject to MGB64's notice and original-game exclusions |
| GoldenPad project code | 19 | Project-authored; no outbound license is currently declared |
| n64-fast3d-engine | 1 | Custom BSD-style terms; binary redistribution only when asset-free |
| n64-fast3d-engine + Perfect Dark | 1 | Custom asset-free-binary terms plus Perfect Dark MIT |
| cgltf + embedded jsmn | 1 | MIT |
| stb_image | 1 | MIT or public-domain option |

The inventory lists 236 source inputs. It includes single-header implementations
that enter the binary through MGB64's `decor_assets.c` and `texpack_stb.c`, even
though Xcode does not list those headers as standalone compilation units.

This is a provenance and license-obligation map, not a claim that the original
game code has been relicensed. The unresolved decompilation redistribution
boundary remains stated in [`LEGAL.md`](LEGAL.md). The app bundle includes
`ThirdPartyNotices.txt` for MGB64, n64-fast3d-engine, Perfect Dark, cgltf, jsmn
and stb_image; the package verifier requires it.

## Verification

After configuring or building the production target:

```sh
./scripts/generate-source-license-manifest.sh
./scripts/verify-source-license-manifest.sh
```

The verifier regenerates the inventory from the configured Xcode target and
fails on any added, removed or unclassified source. Regeneration must accompany
every production source-set change.
