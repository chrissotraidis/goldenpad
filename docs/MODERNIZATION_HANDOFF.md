# Modernization handoff — 2026-09-17

Repository: `chrissotraidis/goldenpad`.
[PR #27](https://github.com/chrissotraidis/goldenpad/pull/27) remains a draft.
See [the source audit](SOURCE_MAINTENANCE.md) for exact pins, preparation paths,
backup verification and unresolved release gates.

## Local candidates

Both artifacts were built from clean source commit
`ff2bdcd` using Xcode 26.6 (17F113). They are private test candidates,
not public releases. This handoff adds documentation after that build.

| Platform | Artifact / build | SHA-256 |
| --- | --- | --- |
| iOS/iPadOS | `GoldenPad-0.1.0-maintenance-test.1-unsigned.ipa`, build 9 | `7bdc52cc30c95d9b4a9c05402ceed1729feac38604d4769cd153033b5a570a13` |
| Apple Silicon Mac | `GoldenPad-0.1.0-issue25-test.2-macos-arm64-alpha.zip`, build 2 | `37841eefcea17b53c8184c6708500c83ad2e2efa5f1f5dba9cc8dda2ba8c97a0` |

The iOS package passed the ARM64, unsigned-package, bundle/build, iOS-17 Metal,
strong game-patch symbol, conversion-resource, notice and private-data/path
checks. Renderer static-library and link checks passed for device and Simulator.
No build-9 hardware install or gameplay acceptance is claimed. The Mac package
reproduced the earlier tested candidate byte-for-byte. Source provenance for the
reconstructed runtime remains distinct from accepted-runtime equivalence.

The public releases remain iOS Preview 8 and Mac Preview 7. Neither release nor
its tags were changed. Issue #25 receives a progress reply linking the fix,
explicitly stating that it is not yet a released download.

## Canonical checklist handoff

[Portfolio checklist](https://app.notion.com/p/3dcceacc88a5810395c2e00ab6173d08)

The initial exact-card update was saved and read back as **In progress**, hybrid
private AOT/patch-prepared public dependencies, new release not yet qualified.
The final connector refresh failed with a transport error. **Notion update
pending** until a fresh fetch, targeted edit and readback succeed.

Proposed exact `PORT-ID: chrissotraidis/goldenpad` update:

- Workflow: Blocked.
- Source status: Hybrid private AOT/patch-prepared dependencies; no migration
  merged. Missing accepted-runtime source and incomplete corresponding-source
  delivery prevent declaring a behavior-preserving migration complete.
- Release status: Public iOS Preview 8 and Mac Preview 7 unchanged. Local iOS
  build 9 and Mac build 2 candidates passed package audits; not published.
- Owner/task: Codex, `codex/issue-25-mac-rom-guidance`, PR #27.
- Last checked: 2026-09-17; implementation `ff2bdcd`; public main `2610863`.
- Next action: Recover the accepted `e75e0de` runtime source or establish a
  replacement baseline with comparison evidence, then resolve exact primary
  source delivery before migrating/publishing.
- Evidence: source-audit and handoff links; real retail conversion/preservation
  tests; both Apple builds/package checks; iOS-17 renderer rebuild; complete
  private backup/independent restore; accepted download hashes; no device
  install/gameplay or completed source migration claimed.

Preserve the original audit, existing checked/unchecked gates and other cards.
Recompute workflow totals from a fresh page, not these notes. Do not modify the
reusable prompt or the separate portfolio tracker.
