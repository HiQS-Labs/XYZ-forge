# Recon Map — GH-474 Option B: replace the guard's table classifier with the renderer's dropped-row signal

Commit: `2e4f8d48` · Mode: grep-only (no knowledge graph) · Lanes: A–D, run serially in the main
context. Radius is two files plus five call sites; a four-agent fan-out would have been ceremony.

## Subject and change class

Subject: the decision path in `githooks/dashboard-staleness-guard.sh` that answers *"did the renderer
silently drop a roadmap row?"*, and the `--check` contract of `utils/roadmap-dashboard.sh` it
currently infers that answer from.

Change class: **contract change** — but see the headline finding, which shrinks it to a local edit.

## Headline finding — the signal already exists and is being discarded

The plan in #474 proposed giving `--check` a new machine-readable result for "rows were dropped".
**That is not necessary.** Tracing the renderer top to bottom:

| Line | What happens |
| --- | --- |
| `utils/roadmap-dashboard.sh:23,30` | `MODE` defaults to `write`, `--check` sets it to `check` |
| `utils/roadmap-dashboard.sh:43` | `RENDERED="$TMP_DIR/ROADMAP-DASHBOARD.md"` |
| `utils/roadmap-dashboard.sh:89` | the node render runs — **unconditionally, in both modes** |
| `utils/roadmap-dashboard.sh:200-203` | every unparseable line is pushed onto `droppedRows` |
| `utils/roadmap-dashboard.sh:217-220` | `roadmap-dashboard: warning: dropped N unparseable row(s): <ids>` → **stderr** |
| `utils/roadmap-dashboard.sh:251` | *only now* does the `MODE == "check"` branch compare and exit |

So `--check` **already emits the dropped-row warning on stderr, by name, with the row ids** — the
exact fact the guard needs. The guard then throws it away:

```bash
# githooks/dashboard-staleness-guard.sh:123
if bash "$TMP_PROJ/utils/roadmap-dashboard.sh" --check >/dev/null 2>&1; then
```

`2>&1` sends the warning to `/dev/null` alongside stdout. Having discarded the direct answer, the
guard falls back to guessing from table names — the classifier at `:147-178` that has now gone short
twice.

**Consequence: Option B is a one-file change.** `utils/roadmap-dashboard.sh` does not need to change
at all.

## The seams

| Seam | Location | Crosses | Breaks if |
| --- | --- | --- | --- |
| `--check` exit contract | `utils/roadmap-dashboard.sh:251-263` | 5 consumers (below) | a new exit code is introduced — **avoided by this design** |
| stderr capture | `githooks/dashboard-staleness-guard.sh:123` | guard ↔ renderer | stderr stays redirected to `/dev/null` |
| table classifier | `githooks/dashboard-staleness-guard.sh:147-178` | guard ↔ ledger schema | deleted by this change; nothing else reads it |
| guard invocation | `githooks/pre-push:88-93` | every push in every clone with the hook | the guard's exit semantics change (they do not — still 0/1) |

## Call paths in

```
git push
  └─ githooks/pre-push:88-93
       └─ githooks/dashboard-staleness-guard.sh <repo> <local_sha> <remote_sha>...
            ├─ :105-113   classify range: touched_ledger? touched_dashboard?
            ├─ :120-127   git archive local_sha -> TMP_PROJ, run roadmap-dashboard.sh --check
            │               ^^ the render happens here; the dropped-row warning is emitted and discarded
            ├─ :131-140   drift branch  -> refuse (unchanged by this plan)
            └─ :142-178   no-drift branch -> TABLE CLASSIFIER (the thing being deleted)
```

## Contracts — the five consumers of `--check`

This is the reason the exit contract must **not** change. Every one treats non-zero as failure, and
today a dropped row with a matching artifact exits **0**:

| Consumer | Line | Shape |
| --- | --- | --- |
| the guard | `githooks/dashboard-staleness-guard.sh:123` | `if ... --check >/dev/null 2>&1` |
| `test/gh269-roadmap-retired.sh` | `:26` | `if --check; then pass else fail` |
| `test/gh280-jog-marathon-adapter.sh` | `:1021`, `:1033` | `--check && pass \|\| fail` (twice) |
| `test/gh57-live-merge-resolve.sh` | `:290` | `ok "staged dashboard matches a fresh render (--check in sync)"` |
| `test/roadmap-dashboard.sh` | `:49-55` | `rc -eq 0 → pass`, else "committed artifact is stale" |

Introducing exit `2` for "rows dropped" would newly fail all four test consumers the first time a
fixture contains a malformed row. Reading stderr instead leaves all five untouched.

## State

Read sites: the guard reads `releases.sql` diffs (classifier — being deleted) and the renderer's
output. Write sites: none; this change writes nothing. Source of truth is `releases.db`; the
`droppedRows` array is transient per-render state, already surfaced on stderr and nowhere persisted.

## Build, failure and rollback today

- Build: no build step; both files are shell.
- Failure today: the guard refuses with a **false** "a parked row was dropped" message for any ledger
  write touching an unclassified table (8 remain: `doc_lines`, `grandfather_entries`, `legacy_lines`,
  `manifest_items`, `manifest_state_events`, `releases`, `repos`, `schema_migrations`).
- Failure after: the guard refuses only when the renderer actually reports dropped rows, and names
  them.
- Rollback: revert one file. `git revert` of a single commit; no data, no schema, no generated
  artifact.

## Unknowns

| Unknown | Why it matters | What would settle it |
| --- | --- | --- |
| Does the warning survive `git archive` into `TMP_PROJ`? The guard renders from a commit-pinned projection, not the worktree. | If the projection lacks `releases.db`, the render there may fail for an unrelated reason and never reach the warning. | Run the guard against a commit containing a known malformed row and capture stderr — `test/gh257-roadmap-ledger-fixes.sh:212-255` already builds exactly that fixture and can be extended to assert it. |

One unknown, and it is the one that must be resolved by a runnable check rather than by reading —
recorded rather than smoothed over.

## Current-state radius, one line

Every developer and agent pushing to this repo with the hook installed, via `githooks/pre-push`; no
data, no published artifact, and no other repo — the guard is per-clone and writes nothing.
