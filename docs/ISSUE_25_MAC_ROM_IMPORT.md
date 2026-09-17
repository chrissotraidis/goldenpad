# Issue #25: Mac ROM import

## Problem and fix

Published Mac Preview 7 imports only the exact prepared NTSC-U TLBFREE image.
The iPhone/iPad release performs conversion automatically. The README described
manual conversion as legacy-only without explaining that the Mac still needed
it, and the Mac error gave no actionable distinction.

The Mac build 2 candidate now links the existing mobile GEP1 converter and
bundles its checksum-pinned conversion resource. The picker accepts `.z64`,
`.v64`, `.n64`, and `.rom`; byte order is detected from content. Supported original
NTSC-U and already prepared inputs both work through the same import entry point.
Conversion runs away from the UI thread, followed by exact output verification
and replacement of the stored copy. Failed imports leave the previous file and
ready state intact. The original input is never modified. Concurrent imports
are suppressed, and progress/errors appear in setup and settings.

The TLBFREE validator moved unchanged from the game startup unit to the shared
import unit so the real importer and Mac store can be tested without the game
runtime. The mobile target already links both units; its import behavior is
unchanged.

The package verifier now requires the converter/validator symbols, the exact
GEP1 resource, and Mac bundle build 2. The packaging script defaults to the
issue-specific candidate name instead of overwriting a Preview 7 filename.

## Recovered build inputs and patch precedence

The old Mac build cache referenced temporary AOT/runtime/reference directories
that no longer existed. For this candidate, private sources were regenerated
from a verified local TLBFREE copy in an ignored directory, using the existing
local recompiler, reference source, and Mac runtime/renderer archives. The
original checkout and its build products were not modified.

The first reconstructed build rendered the intro but stalled entering the
gunbarrel. A native stack sample located the busy loop in the original
`musicTrack1Play`, despite the generated patch containing `yield_self_1ms`.
Both original and replacement functions had weak Clang symbols; Xcode's object
path ordering selected the original in the new directory layout.

The Mac patch translation unit now uses strong, noinline definitions through
`recomp_patch_attributes.h`. Generated originals retain their weak symbols.
The package audit requires strong `musicTrack1Play` and
`bondwalkItemGetAutomaticFiringRate` replacements. This prevents directory names
from silently deciding whether these critical patches are active. The override
now applies to both Apple targets; the same weak-symbol ambiguity exists in the iOS build.

## Validation

- Read the installed iPad GoldenPad build 8 app inventory and copied its
  `Documents/GoldenEye_TLBFREE.z64` read-only. No device app, save, setting, or
  source file was changed.
- Its SHA-256 matched the supported output:
  `7ec491ee3164851d0995e3e8ad19999df5e3028be6ba3729c4ac16c31a9c0959`.
- The real C++ importer and Swift Mac store passed prepared-input tests for all
  byte orders, replacement, self import, refresh/reopen, rejection of truncated,
  altered and invalid-header inputs, unreadable input, and temporary cleanup.
  Each rejected replacement preserved the existing valid file. Prepared inputs
  also remained importable without a conversion resource.
- The full ARM64 Release target built successfully. Existing shared control,
  touch-fire, Mac frontend and patch-source checks passed.
- The app's real picker imported the iPad-derived file into isolated test storage,
  and its stored output hash matched. The corrected build advanced through the
  gunbarrel sequence.
- Packaging checked the ad-hoc signature, architecture, dependencies, absence
  of ROM/save/signing files and private build paths, conversion resource hash,
  required runtime symbols, and strong patch replacements.

The iPad contains the prepared runtime file. The modernization inventory also
located the original retail input in the local references. Its normalized SHA-1
matched `abe01e4aeb033b6c0836819f549c791b26cfde83`. Original-retail conversion
passed for every supported byte order, including missing and corrupt conversion
resource cases that preserve the prior stored file. Reporter-device acceptance and broad gameplay are
separate from import and startup validation. No public release is claimed here.

## Repeat the focused import test

```sh
scripts/verify-recomp-macos-rom-import.sh \
  /path/to/N64ModernRuntime \
  /path/to/vanilla_to_tlbfree.gep1 \
  /path/to/verified/GoldenEye_TLBFREE.z64 \
  /optional/path/to/original-NTSC-U.z64
```

All generated sources, game data, logs, build products, and candidate archives
stay outside tracked source. The test creates disposable private storage and
never writes to the supplied files or the normal GoldenPad container.

## Local candidate

- Filename: `GoldenPad-0.1.0-issue25-test.1-macos-arm64-alpha.zip`
- Bundle version: `0.1.0` build `2`
- ZIP SHA-256: `37841eefcea17b53c8184c6708500c83ad2e2efa5f1f5dba9cc8dda2ba8c97a0`
- Ad-hoc-signed app-content SHA-256:
  `b397d6868b762df311a44029825dd92645ced7b8064ceefb3986c7d40992fbb6`
- Startup telemetry progressed beyond 5,400 rendered display lists after the
  patch-precedence correction; the initial failing build stopped near 1,002.

This is a local test candidate, not a replacement for the published Mac release.
