# GoldenPad two-device LAN netplay loop

Date: 2026-08-28

## Outcome

Produce a ROM-free diagnostic GoldenPad build that can be installed on one
iPhone and one iPad. One device hosts a nearby room, the other discovers and
joins it, both become ready, and the host starts the same stock four-player
GoldenEye match on both devices. Each device owns one player slot and renders
only that player's quadrant.

This is a LAN feasibility build, not a public-internet multiplayer release.
The accepted Preview build, user ROM, saves, and ROM bytes are out of scope and
must remain unchanged.

## Architecture under test

- GoldenPad presents the room UI from its existing three-dot native overlay.
- Apple's local peer transport advertises and discovers a GoldenPad service on
  the current Wi-Fi network.
- The room host is authoritative only for membership, player-slot assignment,
  ready/start state, ordered input frames, and checksum comparison. It does not
  simulate the GoldenEye world for the clients.
- Every device runs the full deterministic GoldenEye simulation locally.
- The host emits one monotonically numbered four-port input bundle per logical
  frame and may lead the native consumer by at most four frames.
- Each peer labels its local sample for exact future frame N+4. The host waits
  for every connected player's exact sample and never reuses last-known input.
- The runtime consumes frame N after the following three ordered frames have
  arrived. Missing authoritative input stops or visibly faults the experiment;
  a client must not silently invent a different future.
- Each client periodically reports the canonical game-state checksum already
  defined by the determinism experiment. Any mismatch is a visible desync.
- Player 1 receives the top-left crop, Player 2 the top-right crop, Player 3
  the bottom-left crop, and Player 4 the bottom-right crop. Unoccupied ports
  remain neutral.

## Why LAN first

LAN isolates the synchronization question from accounts, a global room
directory, relay hosting, NAT traversal, moderation, and Internet latency. A
successful two-device LAN match proves that GoldenPad can transport real input
between independent Apple devices while keeping their simulations aligned.
Only then is a public lobby service worth building.

## Gates

### G1 - Preserve and document the baseline

- Prior 16,000-poll deterministic traces remain reproducible.
- The isolated experiment branch is clean before implementation.
- The accepted Preview and main dirty checkout are untouched.

### G2 - Protocol contract

- A versioned room message carries room identity, peer identity, player slot,
  readiness, start seed/epoch, ordered input frame, and checksum sample.
- Decode rejects a wrong protocol or build compatibility identifier.
- Slot assignment is stable for the lifetime of a room.
- A host-only test proves ordering, the four-frame producer cap, neutral
  unoccupied ports, and missing-frame failure.

### G3 - Nearby room lifecycle

- The host advertises one discoverable room.
- A second peer can browse, request entry, receive Player 2, toggle Ready, and
  receive the same start seed/epoch as the host.
- Disconnect returns the affected slot to neutral and visibly ends the test.
- The Info.plist explains local-network use and declares only the diagnostic
  Bonjour service.

### G4 - Runtime bridge

- The native input layer publishes only the local assigned player's controls.
- The host orders four-port input bundles; both runtimes consume the same
  numbered bundles.
- The deterministic scheduler is enabled only while the LAN test is active.
  Input is latched at one real VI boundary rather than at arbitrary controller
  polls. A stock file-menu/game-thread barrier plus the following VI parks both
  runtime threads before frame 1.
- Stock GoldenEye is entered through ordinary controller input; no ROM patch or
  replacement multiplayer menu is written into the game.
- The native layer selects the assigned quadrant without resizing RT64's
  drawable.

### G5 - One-Simulator validation

- At most the dedicated iPad Simulator is booted.
- Pure protocol/ordering tests pass outside Simulator.
- A host companion or loopback peer proves discovery/session exchange against
  the one Simulator when feasible.
- The diagnostic app launches, presents the LAN lab, and remains graphically
  stable during the validation window.

### G6 - Device artifact and physical gate

- Build an ARM64 device app with a diagnostic bundle identifier so installing
  it cannot replace the accepted Preview or its data.
- Package a ROM-free IPA and record its SHA-256.
- Verify no ROM, save, provisioning secret, or private source path is present.
- Hand off exact iPhone/iPad steps and pass/fail evidence to capture: discovery,
  join, slot, ready/start, both assigned views responding, frame health, and
  checksum agreement.

## Stop conditions

- No second Simulator may be opened.
- Stop on any risk to the accepted Preview, ROM, saves, signing material, or
  unrelated user changes.
- Stop and record evidence if the protocol cannot bound missing input, if the
  two simulations disagree canonically, or if device networking requires a
  materially different architecture.
- Do not describe public Internet matchmaking as implemented. A later Internet
  phase requires a small directory/relay service after this LAN gate passes.

## Definition of done

The diagnostic IPA and source are reproducible; all host and one-Simulator
gates pass; and the remaining two-physical-device check is a short, explicit
install-and-play procedure rather than an architectural unknown.

## Execution status

- G1 baseline preservation: PASS.
- G2 protocol contract: PASS.
- G3 nearby room lifecycle: PASS with one iPad Simulator plus a real macOS
  companion peer.
- G4 runtime bridge: PASS on the host/runtime seam; cross-device checksum
  agreement remains the physical gate. Input is VI-latched, bootstrap timing
  state is normalized at authoritative frame 1, and protocol v3 carries exact
  N+4 peer samples instead of reusing a latest value.
- G5 one-Simulator validation: PASS for synchronization, with renderer follow-up
  open. Immediate, 2,000 ms delayed, and extended fixed-seed runs matched at
  every common checksum sample; the extended peer reached frame 1,020. Active
  telemetry reported `sim 60.0`, `net 60.0`, `buffered 3`, and `misses 0`.
  Simulator rendering remained dark/corrupted in both LAN and offline control
  runs. Comparable presentation counters were nearly identical, so this is an
  existing renderer issue rather than a measured LAN regression. Physical
  image quality and framing remain part of G6.
- G6 artifact: INSTALLED AND READY FOR PHYSICAL PLAY. The signed ROM-free v3
  IPA was independently verified and installed in place on both paired
  devices. Its SHA-256 is
  `ae6a479f82f6055ac77aebcd43efd08e540f729fdc09503be1bd77876d77bf33`.
  Pre/post-install manifests for the ROM, converted ROM, active save, backup
  save, and preferences matched byte-for-byte on the iPad and iPhone. Both v3
  apps launched successfully, and no Simulator remained booted.

See `NETPLAY_LAN_RESULTS.md` for evidence, artifact checksum, and the exact
physical procedure.
