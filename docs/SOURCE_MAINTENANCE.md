# Source maintenance checkpoint — 2026-09-17

Modernization applies to GoldenPad, but is **not complete**. The primary build
is a hybrid of patch-prepared public dependencies and private generated game
code. It cannot currently be rebuilt from the public app archive alone.
The Legacy source manifest does not cover the primary runtime.

This checkpoint accompanies [PR #27](https://github.com/chrissotraidis/goldenpad/pull/27).
Public source was `2610863d4497ad3e01aa0cc05961f7859e44053d` at inspection.
Published iOS Preview 8 and Mac Preview 7 remain the accepted release references.
Local issue-25 candidates are not a completed source migration or public release.

## Actual source graph

| Component | Baseline / identity | Role and existing preparation | Maintenance decision |
| --- | --- | --- | --- |
| [GoldenEye64Recomp](https://github.com/cblock85/GoldenEye64Recomp) | `a787fe0d95e8278fcba5ba2d768fa6a606e75f55` | GPL-3.0; handwritten host and game patches; `goldeneye64recomp-ios-prototype-render-trace.patch` and `goldeneye64recomp-ios-modern-controls.patch`; private AOT and patch generation | Preserve upstream history; separate permitted handwritten changes from generated game output before selecting a maintained branch. |
| N64ModernRuntime accepted build reference | `e75e0de77e8377d4954fe7b511c0d1cf608e7ded` | GPL-3.0; `n64modernruntime-ios-aot.patch`; runtime, saves, audio, queues; contains N64Recomp and nested libraries | Unresolved: this commit is absent from the available checkout and both documented GitHub repositories. Do not silently replace the pin. |
| GoldenEye64Recomp's vendored runtime | Git tree `fb2bb121643d3e0e84f7f430a34f59f0955bc5de` at `a787fe0` | Source available for local reconstruction; its `.gitmodules` entry does not make the tracked directory a gitlink | Local candidate source only. Applying the AOT patch succeeds, but equivalence to the accepted runtime has not been established. |
| [RT64](https://github.com/rt64/rt64) | `5473732a822a4423b5696e7cb18fecc425a59875` | MIT; `rt64-ios-sdk.patch` plus `rt64-ios-embedded.patch`; Apple renderer and generated shaders | Existing effective changes can move to a genuine fork after platform tree/output comparison. Keep nested dependency pins. |
| [Plume](https://github.com/renderbag/plume) | `d890ac899e505fb30040e037a4037cdeca68f033` | MIT; `plume-ios-metal.patch`; mobile additionally uses `plume-ios-simulator-query.patch`; Mac uses `plume-macos-main-queue-coalescing.patch` | Preserve distinct platform preparation; do not combine pacing/query changes without comparison. |
| [MGB64](https://github.com/akratch/mgb64) | `cd9b58f5f91291579b8e551aa925aab000d311cf` | MIT core; Legacy only; its own source restrictions and manifest | Separate retained fallback. Its manifest is not evidence for the primary AOT source closure. |

The later local N64ModernRuntime checkout at
`589bbf018a3e6d3646ddf7de1e7919f1b7e99bb1` is research history, not an accepted
upgrade. GitHub returned “No commit found” for the accepted `e75e0de` reference
under both `N64Recomp/N64ModernRuntime` and `kholdfuzion/N64ModernRuntime`.
This does not establish that the missing commit never existed; it establishes
that the documented fetch path cannot currently reproduce it.

Private LAN/deterministic-clock runtime copies also exist. They contain
experimental changes, including a different VI callback location and clock
hooks. They are not substitutes for the shipping runtime. Simulator resource
limit patches are diagnostic-only. No LAN feature is included in this scope.

## Preservation and observed failures

Complete snapshots of the original dirty checkout and issue-25 worktree,
including nested working sources, ignored/private inputs and Git history, were
preserved outside the checkout on the **same physical disk**. Independent copies
were restored and all 218,517 original-checkout and 9,175 candidate-worktree
manifest entries matched. An independent clone from the all-ref Git bundle
restored candidate commit `137674eb131c89f83d681a106a83fd9d599db18f`.

The attached iPad's Documents, Library and tmp were copied read-only; all 12
copied files passed the independent restore hash comparison. No installation,
uninstall, save reset or settings change was performed. Device identifiers,
private paths, user data and manifests remain in the private backup ledger.

The accepted artifacts were downloaded anonymously and matched GitHub's hashes:

| Artifact | SHA-256 |
| --- | --- |
| iOS Preview 8 unsigned IPA | `773223b7ed7787c18526fb63281a6a3e4960b87adb0a912b0c2b77d0f1312a1b` |
| Mac Preview 7 ARM64 ZIP | `5189dcb5c7089f5ba45e7dbe17d67be9186148da20bce0c2c60e7156f78d71b8` |

The old build caches reference removed temporary runtime/AOT directories.
The surviving iOS renderer archive contains `apple-ios26.5.0` Metal libraries;
it is not a valid replacement for the Preview 8 iOS-17 shader contract.
The dependency rebuild now handles the system Bash's empty-array behavior when
no explicit Metal toolchain is selected. Patch symbols are made strong on both
Apple targets so source-directory ordering cannot select the original weak
function instead of its required replacement.

## Remaining implementation and release gates

1. Recover the accepted runtime source/tree and generation-tool identities, or
   explicitly establish a replacement baseline with matched behavior checks.
   Preserve the current `e75e0de` contract until that decision is supported.
2. Snapshot the exact old prepared trees for mobile and Mac. Move the permitted
   handwritten changes to upstream-connected component histories, compare file
   hashes/modes and generated outputs, then pin immutable commits and nested
   sources. Ordinary builds should consume these trees without applying patches.
   No fork or replacement pin is claimed by this checkpoint.
3. Supply exact corresponding sources, notices and build/generation inputs for
   the selected binary. The GPL runtime is statically linked with private
   generated game code. The public archive excludes that generated code and
   does not include the exact accepted runtime. Whether the necessary source
   delivery can be reconciled with the restricted game-derived inputs remains
   unresolved; a source URL and bundled license texts do not resolve it.
   See [the existing project boundary](LEGAL.md) and
   [GPLv3 sections 1 and 6](https://www.gnu.org/licenses/gpl-3.0.html).
4. Restore the deliverable source archive independently, build both shipping
   targets, inspect exact packages and perform the agreed runtime checks before
   publishing a new release. Private candidate/package success does not satisfy
   this source-delivery gate. No root license grant has been invented.

These are concrete limits of the current inputs. The old preparation mechanism
remains available because a behavior-preserving replacement has not yet been
proved. Generated game sources, retail inputs and device data must stay private.

## Rollback

The private backup ledger records absolute paths and verification results.
For a disposable source restore, clone its `all-history.bundle`, check out the
required recorded revision, then overlay the matching checkout snapshot while
preserving the new clone's `.git`. Restore nested working sources from the same
snapshot; do not run a hard reset on the original dirty checkout.

For app rollback, use the preserved accepted package and the existing bundle
and signing identity for an in-place update. Verify identity compatibility and
preserve the device backup first. The public unsigned IPA requires signing;
it is not itself proof that an in-place device rollback has been exercised.
