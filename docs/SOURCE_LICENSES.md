# Source-license boundaries

GoldenPad has two different game-bearing source boundaries. They must not be
collapsed into one inventory.

The primary Preview 3 AOT/RT64 package is assembled from private generated game
inputs plus exact public GoldenEye64Recomp, N64ModernRuntime, N64Recomp, RT64,
Plume, re-spirv, Zstandard, and project-owned host sources. Its package verifier
requires `ThirdPartyNotices.txt`, the exact GPL-3.0 text, and notices for every
named dependency. Private retail-derived inputs remain excluded from source and
binary distribution.

The machine-readable [`source-license-manifest.tsv`](source-license-manifest.tsv)
is generated from the separately configured **MGB64 Legacy** Xcode target at the
pinned MGB64 commit. It does not inventory the primary AOT binary.

## MGB64 Legacy inventory

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
game code has been relicensed. The unresolved decompilation/static-recompilation
redistribution boundary remains stated in [`LEGAL.md`](LEGAL.md). A Legacy app
bundle includes `ThirdPartyNotices.txt` for MGB64, n64-fast3d-engine, Perfect
Dark, cgltf, jsmn, and stb_image; the Legacy package verifier requires it.

## Verification

After configuring or building the MGB64 Legacy target:

```sh
./scripts/generate-source-license-manifest.sh
./scripts/verify-source-license-manifest.sh
```

The verifier regenerates the inventory from the configured Xcode target and
fails on any added, removed or unclassified source. Regeneration must accompany
every production source-set change.
