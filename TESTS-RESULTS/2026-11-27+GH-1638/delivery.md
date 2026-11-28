# GH-1638 directory seed delivery

`rtl_worktree_begin` now replaces the checkout copy of an allowlisted directory with the current host tree. It checks each parent physically before creating anything beneath it. If clearing or copying fails, setup returns nonzero without printing a worktree path. It requests Git-managed removal and leaves the worktree in place with a diagnostic if removal fails.

## Manual red and green check

The probe sourced `relay-turn-lib.sh` on Darwin arm64 with Bash 3.2.57. It stubbed Git's worktree creation and removal and the signature callback, then ran the actual `rtl_worktree_begin` against host and checkout directories under `.relay-scratch/`. The checkout had stale top-level and multi-segment entries plus a retired child. The host had current content and a nested child.

| Check | Before | Candidate |
|---|---|---|
| Directory shape and contents | Setup returned 0. The check found `seeded/seeded`, stale content at the original paths, and the retired child still present. | Setup returned 0. The nested duplicate was absent, current content and the nested child were present, and the retired child was absent. |
| Ordinary file and multi-segment directory | Ordinary file passed. The multi-segment entry kept stale content. | Ordinary file, existing multi-segment entry, and multi-segment entry with missing checkout parents passed. |
| Copy failure, failed clear, and clear reporting success without removing the destination | | Each returned 1 with empty stdout. The removal stub recorded the teardown request. |
| Failed copy with teardown refused | | Returned 1 with empty stdout and logged the refusal. The fixture worktree still existed. |
| Parent symlink pointing outside the worktree | | Returned 1 with empty stdout. The external target had no new child. |
| `.`, `..`, and empty path segments | | Each returned 1 with empty stdout. |
| Leaf symlink and Git pointer | | Replaced the leaf symlink with a real directory and preserved its external target. Refused to seed over the worktree's `.git` pointer. |

Baseline probe exit 1. Candidate probe exit 0 with 34 passing assertions. `bash -n relay-automation/relay-turn-lib.sh` passed.

The first probe attempt reached the signature callback before it was stubbed. Its `xargs git hash-object` path was read-only and that attempt is excluded from the results. The reported runs stubbed the callback. The [prepared real-worktree probe and discrimination matrix](../2026-11-27+GH-1658-runA-prep/matrix.txt) provide separate prep evidence.

## Vendored package

Regenerated the package with `bash skills/1-hourly/relay-automation/make-pkg.sh`. Before regeneration, the packaged library matched the baseline and differed from the candidate. After regeneration, a Python `tarfile` check confirmed that the manifest matched all 18 expected regular members and that each member matched its live file byte-for-byte.

The relay forbids running the repository scripts in this turn. `bash test/relay-pkg-freshness.sh` remains unverified as a script. The harness owns the configured `bash test/worktree-isolation.sh` gate.

| Artifact | SHA-256 |
|---|---|
| Baseline library | `4ef9162a3bed2736001b9d75973c53d9f248277023f0186783a56b912a38ee11` |
| Candidate library | `49d3ecb23aec17f1aca6ed6d046aaee385b156de0317177ce84bb50a53b2663c` |
| Regenerated package | `d9638f90215f80b1748c4432944efe5985e123a9899bde955976005e6ab6045f` |
