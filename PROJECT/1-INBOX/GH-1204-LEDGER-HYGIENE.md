---
gh_issue: 1204
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1204
title: "Audit C: add logical SQLite ledger hygiene and safe maintenance"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-24
updated: 2026-10-24
owner: noelsaw
doc_type: plan
effort: 3
complexity: 3
risk: 2
phases: 5
rating: "pri/sev/appeal/effort 80/75/75/70 · calc 300"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1201
  - https://github.com/HiQS-Labs/XYZ-forge/issues/768
goal: Keep PRS pointers, lifecycle, and derived views clean through read-only reporting and receipted preview-first repairs, with storage maintenance driven by evidence.
---

# GH-1204 — SQLite ledger hygiene

## Quad Concepts

- Canonical planning state has stale logical pointers → extend PRS with non-mutating hygiene reporting and existing repair verbs.
- Storage cleanup is often mistaken for logical hygiene → measure freelist/size and avoid routine compaction or deletion.

## Measured baseline

Read-only checks found integrity `ok`, no foreign-key violations, zero freelist pages, no WAL/SHM sidecars, and a 1,441,792-byte DB. The ledger has 391 roadmap rows and 961 work events. Three rows have blank `doc_path`; 49 point to nonexistent local docs (48 Completed, one Deferred); one issue URL is shared by two Completed rows that require classification; no active row lacks a PRS rating.

Routine `VACUUM` is not currently justified. Extend existing PRS/reconciliation surfaces rather than adding a cleanup daemon or hand-editing DB/dumps.

## Phases

1. Add a read-only hygiene report to the existing CLI for blank/missing/nonexistent paths, duplicate identities, lifecycle inconsistencies, ratings, derived views, and native state. Failed/empty extraction must not report clean.
2. Repair current findings through existing receipted verbs; repoint or explicitly exempt each case and classify rather than auto-merge the #111 pair.
3. Surface reports through current reconciliation/doc-hygiene workflows; retain preview-first `roadmap reconcile-state` semantics for GitHub lifecycle changes.
4. Track freelist/page counts and size. Permit storage operations only at measured thresholds with backup, exclusive write boundary, and post-checks.
5. Document report-on-reconcile plus operator-invoked repair; consider scheduling only if drift recurs between existing reconciliation points.

## Acceptance

- The report reproduces baseline classes and distinguishes legitimate relationships from defects.
- Every stale pointer is repaired or exempted without silent merge/deletion.
- Read-only reporting leaves DB, dump, and derived files byte-unchanged.
- Existing receipt, dump, lifecycle, and reconciliation checks pass with negative controls.
- Storage operations have measured triggers, rollback copies, and integrity/dump verification.

## Non-goals

No automatic retention purge, routine `VACUUM`, direct hand edits, second ledger, or new cleanup state database.

## Merge evidence

- PR #1209 merged 2026-10-28 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
