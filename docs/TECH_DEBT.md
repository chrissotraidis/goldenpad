# Technical debt and upstream watch

Updated: 2026-08-16

This document records upstream changes that can materially improve GoldenPad,
the evidence required before adopting them, and the known debt that should be
retested when those changes land. It is an upgrade ledger, not a mandate to
replace working foundations whenever an upstream percentage changes.

## Current decision

Keep GoldenPad on the exact MGB64 pin
`cd9b58f5f91291579b8e551aa925aab000d311cf` until a newer, public MGB64 commit
can be inspected and passes the gates below.

The GoldenEye decompilation tracker reached **99.5%** on 2026-08-16. That is an
important signal because MGB64 is built on that decompilation and its maintainer
has said the near-complete source is being used for further engine and
performance work. It does **not** make the raw decompilation a replacement for
MGB64: the decomp reconstructs the game code, while MGB64 supplies the native
renderer, ROM loader, audio, input, save, portability, and platform layers that
GoldenPad integrates.

The practical change is sequencing:

1. preserve the current known GoldenPad baseline;
2. watch for the next public MGB64 engine/source update;
3. evaluate that update in an isolated reference checkout;
4. rebase GoldenPad only after texture, performance, build, legal, and package
   evidence is better than the current pin.

Do not switch GoldenPad to the raw decompilation, rewrite Fast3D/TMEM, or migrate
to RT64 solely because the matching percentage increased.

## 2026-08-16 upstream snapshot

The live [GoldenEye decompilation status
tracker](https://raw.githubusercontent.com/kholdfuzion/goldeneyestatus/master/index.html)
reported:

| Surface | Current result |
| --- | --- |
| Overall | 99.5% |
| Files | 193 of 204 |
| `src` | 63,044 bytes; 99.4% |
| `src/game` | 927,056 bytes; 99.8% |
| `src/inflate` | 5,248 bytes; 100.0% |
| `src/libultra` | 20,996 bytes; 87.4% |

This is a fast-moving tracker snapshot, not a stable release identifier. The
current source repository referenced by the tracker,
`github.com/kholdfuzion/goldeneye_src`, was not publicly readable during this
review. The public [n64decomp/007 mirror](https://github.com/n64decomp/007) was
still at `754a0a977efcbc99a46d079a73292e40780e3aab` from 2025-04-25 and was
therefore behind the tracked work. The new 99.5% source delta cannot yet be
audited or incorporated directly.

The public [MGB64 repository](https://github.com/akratch/mgb64) still resolved
to GoldenPad's current `cd9b58f` pin during this review. GoldenPad is not behind
an available public MGB64 commit today. The MGB64 maintainer has publicly
[described taking a step back to improve the engine against the newer
decomp](https://www.reddit.com/r/R36S/comments/1utcfug/goldeneye_native_port_remaster_decompilation_based/)
and break through performance barriers. Treat that as direction and an upgrade
trigger, not as a promised date or verified fix. GoldenEye Depot's
[site](https://goldeneyedepot.com/) and [X account](https://x.com/goldeneyedepot)
remain announcement sources; the live tracker and exact repository commits are
the technical evidence.

## What the decomp progress can improve

Decompilation progress can improve game logic and code-coupled data that choose
textures, calculate texture coordinates, configure tile/TMEM state, or emit N64
display-list commands. It does not replace the texture pixels and palettes that
GoldenPad loads from the user's ROM.

The current MGB64 pin already records three direct candidates for comparison
against the newer decomp:

| Ledger item | Current divergence | Why GoldenPad should retest it |
| --- | --- | --- |
| `FID-0104` | `texWriteLoadToTmemAddr` is a nonmatching native rewrite with pipe-sync, fast-path, and tile-number differences from retail. | It is reached on non-TLUT texture loads and could change emitted texture state. |
| `FID-0119` | `bgTestBulletHitBackground` returns `-1` texture coordinates instead of performing the retail backward display-list scan. | It can affect surface/material identification for bullet impacts. |
| `FID-0071` | The object-hit texture scan treats a display-list boundary differently from retail. | It can select a different impact material, sound, or decal. |

These are comparison targets, not proof that they cause every visible texture
problem and not authorization to patch them from ledger notes alone. Any change
must be re-derived from the newly available source and verified in a scene.

## What the decomp progress will not fix automatically

MGB64's renderer and GoldenPad's mobile integration remain separate sources of
visual and performance debt. The newer decomp will not by itself resolve:

- texture-cache identity keyed too narrowly for format, size, or palette state;
- backend filtering, coverage-alpha, alpha-dither, decal-bias, or TLUT handling;
- textured prop bullet impacts corrupting world texture state;
- room scissoring, sky fallback, or the remaining menu-material brightness
  difference;
- Metal texture allocation and upload behavior in GoldenPad; or
- iOS-only lifecycle, memory, drawable, and physical-device performance issues.

The measured GoldenPad performance result is especially important here. The
three-frame texture recycler reduced warm Simulator samples reaching
`newTextureWithDescriptor` from 811 of 3,217 to 76 of 3,662. The remaining
Simulator-heavy path was XPC-backed texture upload. A decomp percentage does not
make that Metal transfer cheaper. A new MGB64 engine may reduce texture churn or
invalidations, but that must be measured on a physical device rather than
assumed from Simulator behavior.

## Foundation watch matrix

Update this table only when a concrete trigger occurs. Record an exact commit,
tag, or public artifact rather than a social percentage alone.

| Foundation | GoldenPad use | Watch for | Adoption rule |
| --- | --- | --- | --- |
| [akratch/mgb64](https://github.com/akratch/mgb64) | Active game core, Fast3D/Metal renderer, native port services | New commits/releases; decomp imports; renderer, texture-cache, audio, timing, or portability changes | Evaluate first. Update the pin only after all gates pass. |
| [GoldenEye status tracker](https://raw.githubusercontent.com/kholdfuzion/goldeneyestatus/master/index.html) and `kholdfuzion/goldeneye_src` | Source/parity signal feeding MGB64 | Public auditable source, matching milestones, changes touching known fidelity items | Research input only; never integrate private or unavailable source. |
| [n64decomp/007](https://github.com/n64decomp/007) | Public decomp reference | Mirror synchronization and relevant source history | Reference only; preserve provenance and license review. |
| [GoldenRecomp](https://github.com/kholdfuzion/GoldenRecomp) | Static-recomp architecture reference | Public TLB-free ELF/ROM recipe, generated functions, or complete metadata | Reconsider only when a clean public pipeline is reproducible. |
| [N64Recomp](https://github.com/N64Recomp/N64Recomp) and [N64ModernRuntime](https://github.com/N64Recomp/N64ModernRuntime) | Translator/runtime reference | Metadata compatibility and portable runtime improvements | Pin and test only as part of a reproducible GoldenRecomp path. |
| [RT64](https://github.com/rt64/rt64) and its Plume backend | Verified alternative renderer reference | iOS/Metal improvements, texture-pack behavior, shader or backend changes | Do not carry two production renderers; reconsider only for a demonstrated MGB64 blocker. |

Concrete review triggers are:

- a new MGB64 commit, tag, release, or published engine branch;
- the current 99.5% decomp source becoming publicly auditable;
- an upstream change touching `FID-0104`, `FID-0119`, `FID-0071`, texture cache,
  Fast3D, Metal, display-list state, or texture uploads;
- a reproducible GoldenRecomp TLB-free input/metadata pipeline; or
- a material RT64/Plume iOS Metal change that addresses a measured blocker.

## Upgrade gate for a new MGB64 revision

When a trigger lands:

1. Record the upstream URL, exact SHA/tag, date, license/provenance changes, and
   release notes. Confirm the source is public and auditable.
2. Check out the candidate under `ref/`. Do not change GoldenPad's production
   pin yet.
3. Apply GoldenPad's MGB64 patches with `git apply --check`, then rebase each
   conflict deliberately. Do not bulk-copy the candidate tree.
4. Compare the same scenes on current desktop MGB64, candidate desktop MGB64,
   GoldenPad, and a stock reference: Dam cliff/shore/intro, Cradle, Surface,
   menu/briefing materials, glass, and bullet decals.
5. Classify the result before fixing anything:
   - fixed in candidate desktop MGB64: adopt or rebase the upstream fix;
   - broken in candidate desktop MGB64 and GoldenPad: upstream renderer/core
     issue;
   - correct on candidate desktop MGB64 but broken only on iOS: GoldenPad
     Metal/mobile integration issue;
   - visually correct but slow only on iOS: physical-device profiling issue.
6. Recheck `FID-0104`, `FID-0119`, and `FID-0071` against the new source and
   capture scene evidence for any behavior change.
7. Run the maintained Simulator and ARM64 device builds, ROM/data contamination
   checks, source-license manifest, package audit, and upstream-cleanliness
   checks. Keep cold/warm and Simulator/physical performance results separate.
8. Promote the new pin only when the candidate produces no new texture
   corruption, preserves saves and private data boundaries, and improves or
   matches the current baseline.

## Open debt after this review

- Wait for a public MGB64 engine/decomp update; there is no new production pin
  to adopt today.
- Build a repeatable visual comparison set for the scenes named above before
  changing the core pin.
- Re-evaluate the three fidelity-ledger texture/material items against the new
  public source when it appears.
- Keep renderer defects and mobile upload performance in their own evidence
  lanes; do not label them "fixed by decomp" without a measured result.
- Refresh this ledger when a concrete trigger lands, not for every percentage
  tick on the live tracker.
