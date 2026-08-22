# Preview 2 in-app ROM import

Preview 2 removes Preview 1's Finder-and-`xdelta` setup from the normal user
path. The app accepts the user's original NTSC-U GoldenEye 007 ROM, performs the
required TLB-free transformation locally, verifies the result, and launches the
existing runtime against the same `Documents/GoldenEye_TLBFREE.z64` contract.

This is an onboarding change, not a runtime migration. Rendering, audio, input,
saves, graphics settings, touch layouts, and game startup remain on the Preview
1 code path after setup.

## Data contract

- Accepted input: the exact supported NTSC-U retail ROM in `.z64`, `.v64`,
  `.n64`, or `.rom` byte order, plus an already valid TLB-free file for Preview
  1 compatibility.
- Rejected input: every other region, revision, size, header, or content hash.
- Transformation: GoldenEye64Recomp's GEP1 patch from pinned revision
  `a787fe0d95e8278fcba5ba2d768fa6a606e75f55`.
- Pinned patch SHA-256:
  `5a079d5b3750afcb027e46367e318b884eadabbd238a450a70f95e3976ded263`.
- Verified output size: `12,653,664` bytes.
- Verified output SHA-256:
  `7ec491ee3164851d0995e3e8ad19999df5e3028be6ba3729c4ac16c31a9c0959`.
- Destination: `Documents/GoldenEye_TLBFREE.z64`, excluded from device backup
  and protected until the first unlock after restart.

After validation, the primary librecomp runtime also maintains a second full
copy at `Application Support/GoldenPadRecomp/<game_id>.z64`. That copy is needed
by the current runtime-selection path, but unlike the Documents copy it is not
yet explicitly backup-excluded or assigned a file-protection class. TD-12 tracks
that storage/privacy hardening. Both copies must be preserved and hash-checked
during any update or migration.

The package includes transformation data, not a complete ROM. The original
selected file is read through the system document picker and is not copied into
GoldenPad. Both generated copies remain private user data and must never enter
the repository, build tree, IPA, diagnostics, or release assets.

## Launch state machine

1. Check the existing destination without starting Metal or the game runtime.
2. If it is valid, enter the unchanged Preview 1 game view immediately.
3. If it is missing or invalid, show the setup view and system file picker.
4. Normalize byte order in memory and validate the exact retail hash.
5. Apply the bounded GEP1 stream into a uniquely named temporary file.
6. Validate the exact TLB-free size and hash.
7. Set private-file metadata, then atomically move or replace the destination.
8. Create the existing Metal/game view only after the destination is valid.

Any read, format, revision, patch, output, protection, or write failure leaves
the prior destination untouched and presents a specific recovery message.

## Preview 2 gates

- [x] ROM-free host compiles.
- [x] Complete AOT/RT64 Simulator app compiles and contains the pinned patch.
- [x] Native conversion succeeds from the private real `.v64` retail dump.
- [x] The same conversion succeeds from `.z64` and `.n64` byte-order fixtures
  derived from that dump, and all three inputs produce byte-identical output.
- [x] An already valid TLB-free input is accepted for Preview 1 compatibility.
- [x] A separate signed iPhone test bundle converted the real retail input to
  the exact expected output hash, then reached live display-list, VI,
  presentation, input, and audio progress on the existing runtime.
- [x] A configure-time guard now rejects a clean GoldenEye64Recomp checkout if
  the maintained iOS render-context patch is absent; this prevents RT64's
  unwritable first-launch data-path crash from entering another build.
- [ ] Exercise first install, wrong ROM, cancellation, low-storage/write
  failure, and in-place Preview 1 upgrade in the app UI.
- [ ] Complete hands-on gameplay, touch, controller, physical-speaker audio,
  background/foreground, relaunch, and save/config preservation on iPhone.
- [ ] Repeat first-import and gameplay acceptance on physical iPad.
- [x] Audit and checksum the exact unsigned Preview 2 IPA before publication.
  The 18-member archive passed at SHA-256
  `704bdf68f67d1f0925fd1844ab865c263a79e105a6349ef410f365602e6c77e3`
  and reproduced byte-for-byte on a second packaging pass.

Network or peer-to-peer multiplayer is explicitly outside this change. It must
not be coupled to ROM onboarding or advertised until its own synchronization,
compatibility, transport, and physical multi-device gates pass.
