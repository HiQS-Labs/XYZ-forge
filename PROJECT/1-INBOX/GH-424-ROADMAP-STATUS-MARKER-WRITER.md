---
title: roadmap_items.status_marker has no CLI writer — in releases-mode a row can never leave 🆕
status: Proposed (1-INBOX — not yet active)
created: 2026-09-04
owner: noelsaw1
gh_issue: 424
source: https://github.com/HiQS-Labs/XYZ-forge/issues/424
doc_type: feature
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Deriving the marker from raw_text. That is the rejected option, and rejecting it is the point.
  - Automating the reconciler — GH-421, which this unblocks.
  - Backfilling the 50 existing 🆕 rows. Once the verb exists that is a separate, reversible data pass.
  - Touching ROADMAP.md — GH-269.
related:
  - GH-421 (blocked by this)
  - GH-269 (a DB that cannot express "done" is not a replacement for the file)
goal: >
  Give roadmap_items.status_marker a CLI writer — an explicit, enum-validated --status-marker on
  `roadmap update` — and close the rollback-journal gap that leaves RELEASES.generated.md ahead of a
  rewound DB.
---

# GH-424: the ledger cannot say "done"

> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.

## The gap

`status_marker` has no CLI writer. `roadmap update` exposes `--raw-text` and `--section` but no
marker argument (`releases_app.py:3322-3368`, `:4984-4989`); `roadmap repoint` writes only
`doc_path` and `raw_text` (`:3277-3289`). The only thing that ever set it was `roadmap sync`,
parsing it out of the legacy markdown line (`:3475-3534`) — a deliberate no-op in releases-mode
(`:3374-3385`).

**Measured: 50 rows sit at `🆕`, including work that has shipped.**

## The shape — explicit enum, not derivation

Two reviewers split on this and the second was right. Codex proposed extending `roadmap update` to
*derive* the marker from the new `raw_text`. agy rejected it: deriving a DB column by re-parsing a
markdown bullet reintroduces exactly the markdown-as-schema coupling releases-mode exists to remove.

```
releases roadmap update --issue-num <N> --status-marker <marker> [--section <s>] [--raw-text <t>]
```

Validated against the closed set already in the data — `🆕`, `🚧`, `✅` — rejecting anything else so
the column cannot gain a fourth value by typo. The DB is truth; the marker is set, not inferred.

## Also in scope: the journal misses a tracked artifact

`wave_reconcile.py`'s rollback journal snapshots `releases.db`, `releases.sql`, and four views —
`ROADMAP-DASHBOARD.md`, `RELEASES-PREVIEW.html`, `LEADERBOARD.html`, `LEADERBOARD.md`
(`wave_reconcile.py:679-696`). It does **not** snapshot `RELEASES.generated.md`, which is
generation-stamped and verified by `releases check` (`releases_app.py:4129-4137`).

Confirmed live: DB generation `398`, file marker `398`, check prints
`OK: RELEASES.generated.md generation marker matches (398)`. Every ledger write keeps it in step —
which is why a partial rollback breaks it. Rewind the DB and leave the view ahead, and the next
`releases check` fails `generation-mismatch`, **after** a rollback the tool reported as successful.
The receipt chain survives (`op_receipts` restores with the DB); the trio diverges.

Two fixes, both here because GH-421's writes are unsafe without them:

1. Add `RELEASES.generated.md` to the journal's snapshot set.
2. Move the snapshot **before** the first ledger mutation rather than inside `run_subprocesses`
   (`wave_reconcile.py:670-710`, `:987-993`).

## Proof — §13

**Reds, witnessed before the fix:**

- enumerate every CLI invocation that could plausibly move a row off `🆕` and record that each
  leaves the column unchanged
- rewind the DB one generation with `RELEASES.generated.md` in place; record the
  `generation-mismatch` failure
- inject a failure between two ledger writes; show the journal restores DB and dump but not the
  generated view

**Greens:**

- `--status-marker` rejects an out-of-enum value rather than storing it
- setting the marker leaves `doc_path`, `section`, `raw_text` untouched unless separately given
- after the snapshot fix, an injected failure restores DB, dump, **and** every generated artifact
  byte-for-byte, and `releases check` comes back clean

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "utils/py/releases_app.py", "pattern": "status-marker" } ],
  "artifacts":   [
    "utils/py/releases_app.py",
    "utils/py/wave_reconcile.py",
    "test/gh424-roadmap-status-marker.sh",
    "test/baselines/GH-424-negative-control.md"
  ],
  "remediation": { "source": "issue#424", "criteria": "`roadmap update --status-marker` sets the column through a receipted write and rejects any value outside the enum; the rollback journal snapshots RELEASES.generated.md before the first ledger mutation, so an injected failure restores DB, dump and every generated artifact byte-for-byte and releases check comes back clean" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
