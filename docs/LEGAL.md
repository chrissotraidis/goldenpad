# Legal and provenance policy

GoldenPad is an unofficial research and preservation project. It is not
affiliated with or endorsed by Nintendo, Rare, Microsoft, MGM, Danjaq, EON
Productions, or any other rights holder. No trademark license is claimed.

## Hard rules

- Use only user-supplied, legally obtained original retail Nintendo 64 data.
- Never use the leaked/unreleased XBLA build, leaked source, proprietary SDK
  source, or dependencies with unclear/incompatible provenance.
- Never commit, push, package, publish, document, or capture a ROM or extracted
  asset file. A small set of user-approved, downsampled in-game promotional
  screenshots may be tracked separately from the app/package; they do not grant
  rights in the depicted game content and must retain the project's unofficial
  developer-preview attribution.
- Never bundle or prepopulate a ROM or ROM-derived media in an app, IPA,
  archive, test fixture, CI cache, app container, or release. A user-supplied
  source may exist temporarily in that user's private Files storage for import;
  GoldenPad closes source access after copying validated bytes into volatile
  core memory.
- Never commit credentials, keys, certificates, profiles, or private data.
- Audit tracked and staged files before each commit and push.

The repository `.gitignore` excludes local references, common ROM formats,
ROM-derived output, saves, packages, signing material, and build products.
Ignore rules are necessary but are not a substitute for a staged-file audit.

## Practical decision

Development may continue with the primary GoldenEye64Recomp/N64ModernRuntime/
RT64 path and with MGB64 Legacy under the same disclosed community decomp/static-
recomp boundary used by comparable ports. Supplying a user's own ROM keeps
retail data out of the repository and package, but it does not itself grant
redistribution rights in reconstructed or translated game code. Upstream
licenses cover their authors' work; they cannot license copyrights held by the
game's rights holders. This is a release-risk disclosure, not a production
stop. Paid access, store release, or claims of fully cleared redistribution
remain behind qualified legal review. ROM-free diagnostic contracts and
behavioral test schedules provide engineering evidence only; they do not cure
or expand redistribution rights.

## Source boundary

- Matching decompilation and static recompilation carry the same unresolved
  copyright boundary seen in other community N64 ports: a public repository or
  project license does not grant rights in the original game. That uncertainty
  is disclosed here; it is not treated as a GoldenEye-specific development
  blocker.
- The shipped Preview 2 runtime uses statically generated GoldenEye64Recomp game
  code, N64ModernRuntime, N64Recomp components, RT64, Plume, and their transitive
  dependencies. The distributed package must carry its required notices and
  exact GPL text, and the corresponding-source boundary must remain available
  for distributed GPL components. No dependency license authorizes publishing
  retail-derived inputs; if a distribution obligation cannot be satisfied
  without exposing them, distribution requires qualified legal review or must
  stop.
- MGB64 is the legacy comparison/fallback core. Its MIT license applies to
  first-party port work, while the decompiled game remains attributed to its
  rights holders. GoldenPad may build that independently reconstructed retail
  N64 code under the same noncommercial research/developer-preview model used
  by comparable community ports, without claiming ownership or guaranteed
  redistribution rights.
- The MGB64 tree also retains Nintendo/SGI/Rare SDK-lineage material for its
  matching-N64 target. GoldenPad must compile only MGB64's native source surface:
  no `src/libultra/**` or `src/libultrare/**` implementation file may enter
  the Apple target. The exact upstream native SDK-surface guard must pass before
  every core build.
- `n64decomp/007` remains a provenance/symbol reference. GoldenPad uses MGB64's
  documented native build surface rather than directly packaging the matching
  N64 source tree.
- HarkinianPad integration code/art is all rights reserved and is reference-only.
- GoldenEye64Recomp and N64ModernRuntime carry GPL-3.0 obligations; N64Recomp,
  RT64, Plume, and other dependencies retain their own terms. GoldenPad must
  satisfy the combined obligations for every distributed binary.
- `docs/source-license-manifest.tsv` machine-classifies the configured MGB64
  Legacy source target. The primary AOT package has a different dependency
  boundary enforced by `scripts/verify-recomp-prototype-ipa.sh` and the exact
  notice/license set described in `docs/SOURCE_LICENSES.md`.

The current touch editor and input mapper are original Swift implementation.
HarkinianPad was used only to identify product-level control requirements, and
the clean GoldenEye decomp was used only to verify public N64 button constants;
no reference source was copied into GoldenPad.

The tracked RT64/Plume/MGB64 patches and GoldenPad RT64/MGB64 bridge/shim files are
narrow integration work against the exact commits in `RESEARCH.md`. They
contain no ROM data, extracted media or generated shader output. The MGB64 core
and the public source inputs for the primary runtime are compiled from ignored
exact upstream checkouts and are never copied wholesale into this repository.

The following MGB64 audio, volatile-ROM, asset-placeholder, and SDK-source guard
details apply to `GoldenPad Legacy`, not to the primary Preview 3 runtime.
The mobile audio build compiles MGB64's native clean-room synth, decoder and
sequence modules. Matching-target Nintendo/SGI/Rare SDK-lineage audio
implementations remain excluded by the same source guard as the rest of the SDK
tree; the Apple output bridge and PCM ring are project-owned code.
Verification applies the patches only inside an ignored reference checkout and
removes them on exit; generated Metal products and static archives remain
untracked build artifacts.
ROM state begins null/zero. Only the existing exact SHA-1 validator may pass
normalized bytes to the core-owned heap; the C boundary rechecks size, header
and internal title. Replacement zeroes the prior allocation before freeing it,
and no bridge writes retail bytes to persistent storage. Renderer lifecycle
frames remain empty until the validated game main loop starts.
MGB64's one-byte native asset-symbol placeholders contain no extracted content;
the validated runtime table replaces them with private owned-buffer offsets.

## ROM validation

The first supported revision is the US retail ROM after normalization to
big-endian Z64 bytes:

`SHA-1 abe01e4aeb033b6c0836819f549c791b26cfde83`

V64 and N64 byte orders may be accepted, but the app must normalize in private
temporary storage or memory before hashing. A filename is never validation.

## Packaging gate

Before any IPA/archive is shared:

1. enumerate every archive member;
2. scan names, sizes, hashes, magic bytes, strings, and high-entropy blobs;
3. reject ROM headers, known ROM hashes, extracted media, saves, dev paths,
   local references, credentials, signing files, and undocumented binaries;
4. verify the installed app requires user-selected retail data;
5. record the audit command and result in `docs/WORKLOG.md`.

Every game-bearing IPA must carry `ThirdPartyNotices.txt`. The primary package
verifier also requires `COPYING-GPL-3.0.txt` and notices for
GoldenEye64Recomp, N64ModernRuntime, N64Recomp, RT64, Plume, re-spirv, and
Zstandard. The separate Legacy verifier requires the MGB64,
n64-fast3d-engine, cgltf, jsmn, and stb_image notices. A notice set from one
runtime does not satisfy the other runtime's package gate.

This policy is conservative engineering guidance, not legal advice. Development,
private builds, source publication, and a clearly labelled free ROM-free
developer preview may proceed with the boundary above. Paid access, commercial
distribution, official-store submission, or any claim of guaranteed
redistribution rights remains a separate qualified-legal-review gate.
