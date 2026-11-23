# Batch 1380 preservation inventory

Read-only post-incident inventory, 2026-11-08. No recovery, restoration, deletion, cleanup, branch rewriting or worktree recreation was performed.

## Proven preserved, not restored

- Primary is clean/published at `1c2bd89eb7e4176f8333d338a74d2113bb581a32`. PR 1377 merged as `8677bab38f93c7a00c12f071395ef199f41bf062`; PR 1379 merged as `9d2ecf868217777e0add829e707eb64dd2942da6`. Reconciliation commit is the primary tip above.
- All five probed commits exist as commit objects and are ancestors of published development, including evidence heads `678dd75ad310902e61bdff8e10a7757c7d8aa517`, `0e503ac12`, and `18e5df165030677a4ad3db1b46f7bc66459d09f3`. See inventory.json and refs/reflogs/unreachable JSON; ancestry proves committed reachability, not ignored-file preservation.
- Logical deployment root is the retained `gh1358-live-deployment-dr61f_tg`. Its `runner` and `publisher` Git directories exist; each has captured refs, reflogs, stashes, ignored/untracked status and a successful read-only fsck in retained-git-inventory.json. Two GH1254 sibling full clones likewise survive. Local absolute root mapping is retained separately in the primary's `temp/gh1380-preservation/local-root-map.json`; it is not published.
- Deployment files: 20,593 regular files / 363,584,272 bytes indexed; primary Jog1254 state: 20 files / 175,953 bytes; two sibling clones: 9,702 and 10,200 files. The manifest excludes Git internals, node_modules, Python caches and virtual environments, and does not follow directory symlinks. Git internals are evaluated by separate Git inventories. Omission is explicit, not a completeness claim.
- Held `held-gh1254-final-result/marathon-result.json`: 5,748 bytes, SHA-256 `9997616be15806c692a2d5ad8cda8786294fed352652d13741106637b0fb32db`. Parent independently reported that same nonempty size before this inventory.
- Runner attempt file: 52 bytes, two nonempty record lines, SHA-256 `d2565905a3f76fb1f98294f476b29515b3a671d28e6e27ac75c4f8924cd6aff2`. Raw records/configuration/receipt contents are not printed or copied here. This demonstrates the current two-record artifact survives, not that every prior state has been recovered.
- Four retained repositories returned fsck exit 0. Manifest traversal reported zero file-read errors. Neither fact proves lost files never existed.

## Unknown loss and next recovery actions

- The provisioned linked worktree `t3-59b86d54` is missing and absent from Git's registered worktree list. There is no pre-removal ignored/untracked inventory available to this session. Completeness and recoverability of those bytes are UNKNOWN.
- No Trash movement, backup manifest, or recovery location for that entire worktree was established. macOS denied Trash listing. Native Git worktree removal is strongly inferred from the exact-version CLI source; runtime removal stdout was not retained.
- Preserve every retained deployment/runner/publisher/gate/source clone, ignored receipt, attempt file, ref, reflog, unreachable object and local root map. Do not run GC, prune, delete, recreate the missing path, or restore over surviving state.
- A separate recovery owner should compare any pre-incident backups/snapshots and retained manifests against the old worktree's known dependencies. Restore only to a new, explicitly approved location after inventory and a preservation plan. No such restoration is claimed here.

## Causal evidence and correction

Installed gh 2.101.0, exact-version source: https://github.com/cli/cli/blob/v2.101.0/pkg/cmd/pr/merge/merge.go#L494 . With --delete-branch, a PR branch checked out in another linked worktree invokes WorktreeRemove. Our #1377 command, branch and registered path match. This is a strong source-based inference, with the missing-runtime-stdout qualifier retained. It bypassed the intended separation between landing and Phase 6 cleanup. Track removing the flag and correcting dry-run text under #1381. No implementation is included in this evidence PR.
