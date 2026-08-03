# Legal and provenance policy

GoldenPad is an unofficial research and preservation project. It is not
affiliated with or endorsed by Nintendo, Rare, Microsoft, MGM, Danjaq, EON
Productions, or any other rights holder. No trademark license is claimed.

## Hard rules

- Use only user-supplied, legally obtained original retail Nintendo 64 data.
- Never use the leaked/unreleased XBLA build, leaked source, proprietary SDK
  source, or dependencies with unclear/incompatible provenance.
- Never commit, push, package, publish, document, or capture a ROM or extracted
  copyrighted assets in screenshots.
- Never include a ROM or ROM-derived media in an app, IPA, archive, test
  fixture, CI cache, container, or release.
- Never commit credentials, keys, certificates, profiles, or private data.
- Audit tracked and staged files before each commit and push.

The repository `.gitignore` excludes local references, common ROM formats,
ROM-derived output, saves, packages, signing material, and build products.
Ignore rules are necessary but are not a substitute for a staged-file audit.

## Source boundary

- `n64decomp/007` has no discovered license and is research-only.
- MGB64's MIT license applies to its contributors' first-party work, not the
  decompiled game or SDK-lineage inventory. It is research-only unless a file's
  origin and license are independently proven compatible.
- HarkinianPad integration code/art is all rights reserved and is reference-only.
- GoldenRecomp and N64ModernRuntime are GPL-3.0; N64Recomp and RT64 are MIT.
  If used, GoldenPad must satisfy the combined license obligations and publish
  corresponding source for distributed GPL binaries.
- Every incorporated file must have an entry in `docs/RESEARCH.md` or a
  generated third-party manifest identifying its exact source and license.

The current touch editor and input mapper are original Swift implementation.
HarkinianPad was used only to identify product-level control requirements, and
the clean GoldenEye decomp was used only to verify public N64 button constants;
no reference source was copied into GoldenPad.

The tracked RT64 and Plume patch files are narrow integration diffs against the
exact MIT-licensed commits in `RESEARCH.md`. They contain no game code, ROM data
or generated shader output. The verification script applies them only inside an
ignored reference checkout and removes them on exit; generated Metal products
remain untracked build artifacts.

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

This policy is conservative engineering guidance, not legal advice. Public
distribution remains blocked until the static-recomp/decomp source boundary has
been reviewed by qualified counsel or cleared explicitly by the relevant owners.
