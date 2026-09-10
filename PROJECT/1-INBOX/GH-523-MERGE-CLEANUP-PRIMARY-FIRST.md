---
title: "GH-523: merge-cleanup never reviews the primary on-disk checkout first, and merges into a tree that cannot receive the landing"
status: Parked
created: 2026-09-09
updated: 2026-09-09
owner: unassigned
goal: make the primary on-disk checkout Phase 0 of merge-cleanup — inspected by identity rather than by scan discovery, and a precondition that refuses the merge sequence when the tree cannot receive the landing
gh_issue: 523
source: https://github.com/HiQS-Labs/XYZ-forge/issues/523
doc_type: defect
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/436
  - https://github.com/HiQS-Labs/XYZ-forge/issues/510
context_tags: [merge-cleanup, skill, worktree-safety, landing-gate, data-loss]
non_goals:
  - Changing the topological PR ordering itself
  - Teardown policy (Phase 6) or WORKTREE-SAFETY.md
  - Auto-fixing the primary (committing, stashing, or switching its branch for the operator)
effort: 3
complexity: 2
risk: 2
---

# GH-523 — merge-cleanup reports everyone's PRs before the operator's own checkout

## Status

| What was just completed | What's next |
|---|---|
| Fixed on `fix/merge-cleanup-primary-first`: Phase 0 by identity + merge refusal; 7 cases, both red controls observed | Gate, PR, land |

## Observed

A run reported the full open-PR matrix and merge order without ever establishing whether the
operator's own on-disk checkout could receive any of it.

**1. The primary is inspected only if a scan happens to find it.** `scan_directories` walks
`SAFE_ROOTS` and filters by `--prefix`; the `PRIMARY_CHECKOUT` tag is applied inside that loop, so
the primary appears only when the walk reaches it and the prefix matches. Reproduced: with
`prefix_filter='marathon'` the real primary is absent from the audit entirely, while
`merge_cleanup.main` still proceeds to merge PRs into it.

**2. Nothing asserts the primary can receive the landing.** Phase 5 merges every PR remotely and
only then runs `git merge --ff-only` plus `wave_reconcile.py`, `releases_app.py` and `pdda.sh`. A
dirty tree, a feature branch, or local commits on `development` absent from origin are therefore
discovered after the merges are irreversible. All three were true of the live primary at once.

Unpushed commits on the integration branch are the sharpest edge: a squash-merge landing skips
them silently.

## Fix

- `scan_directories` force-includes the primary by identity, first in the list, with no duplicate
  row when the scan also reaches it.
- `inspect_primary_landing()` answers the four questions that decide whether a landing is possible
  — integration branch, cleanliness, unpushed commits on that branch, fast-forwardability — and
  never raises.
- `merge_cleanup.py` prints Phase 0 before the audit and refuses to merge (exit 2) when the
  primary is not ready, unless `--allow-unready-primary` is passed. `--integration-branch`
  defaults to `development`.
- `SKILL.md` documents Phase 0 as first and by-identity, and not-ready as a refusal.

## Red controls (observed)

| Mutation | Result |
|---|---|
| force-include removed | `primary vanished from the audit: []` |
| `landing_ready` hardcoded `True` | 3 FAILs: dirty tree, feature branch, unpushed commits |

## Rating rationale — 2026-09-09

`rated 80/85/50/85`

- **Severity 85.** Work-blocking with a data-loss path: merging while the primary holds unpushed
  commits on `development` drops them silently, and reconciliation can run over uncommitted work.
  Recoverable via reflog in most cases, which keeps it below the corruption band.
- **Priority 80.** merge-cleanup is the standing landing path and eight clones currently await it,
  so the defect is live on the next run, not hypothetical.
- **Appeal 50.** Neutral; the operator expressed no preference.
- **Effort/cheapness 85.** One script, one driver, one skill doc, one test file; one sitting.
- **Recurrence.** Window 2026-08-26 → 2026-09-09 versus the preceding 14 days: one observed
  incident (2026-09-09, this issue). GH-436 hardened the same skill's teardown on 2026-09-05, so
  this is the second defect in merge-cleanup inside two weeks, in a different phase. Trend for the
  landing path specifically is unknown — only this run was audited.
