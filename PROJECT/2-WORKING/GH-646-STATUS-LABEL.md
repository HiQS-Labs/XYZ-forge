---
gh_issue: 646
source: https://github.com/HiQS-Labs/XYZ-forge/issues/646
title: Shared in-progress task label
status: In progress — writer refresh and independent final review
created: 2026-09-16
updated: 2026-09-17
owner: Codex
goal: Make explicit task starts and confirmed issue endings visible through the same in-progress label in the existing XYZ ledger and GitHub connector.
branch: feat/gh646-writer-refresh
doc_type: implementation
effort: 3
complexity: 3
risk: 3
phases: 4
---

# GH-646 — Shared in-progress task label

## Status

| What was just completed | What's next |
|---|---|
| A fresh review found and the branch fixed both ordinary-update admission and direct terminal-cleanup identity gaps; 40 focused label tests pass and both restored-bypass mutants fail as intended. | Finish the reopened bounded review, then run one final qualifying gate in a disposable clone before a PR is opened. |

## Goal and scope

An explicit accepted start sets the literal `in-progress` value on the existing `roadmap_items` row and, only when explicitly configured, projects the same GitHub issue label. A confirmed completed or cancelled issue clears it through the existing reconciliation path. The ledger is authoritative; readers only display evidence.

The implementation extends the current roadmap writer, migration/dump path, existing connector registry, Express admission, and wave reconciliation. It does not add a service, a second database, a scheduler, a generic label system, natural-language start inference, or a bidirectional GitHub sync.

## Reversibility and blast radius

This is **Costly** because schema 009 changes the ledger dump and writer contract. Existing schema-008 data remains readable with `status_label` unavailable; rollback is disabling the opt-in connector and retaining a pre-migration backup, never restoring an old database over newer work. The affected surfaces are roadmap writes, dump/rebuild, Express admissions, reconciliation, connector payloads, and readers of work evidence. No production migration, connector enablement, label write, or live closure pilot is authorized by this work.

Reader safety is settled separately: normal SQLite coordination sidecars are allowed for passive readers, while task records, database structure, and GitHub labels remain immutable to readers. This writer plan neither relies on nor changes that reader behavior.

## Ordered delivery plan

1. Reconcile the retained writer commits against current `origin/development`, preserving only the writer, migration, qualified identity, Express, reconciliation, connector, and focused regression changes. -> Expect no Flight Deck, Daily, generated view, or unrelated harness changes in the diff.
2. Verify the nonempty focused fixtures for explicit starts, duplicate starts, schema migration/dump compatibility, same-number foreign identities, native issue-versus-PR checks, outage/replay, closure/reopen, Express dry runs, and exact-row reconciliation. -> Expect each protection to be covered by an existing red control and the refreshed source revision recorded.
3. Run a new bounded independent final relay review of the refreshed source and the complete acceptance map. -> Expect an explicit Approved verdict, or a named blocker; do not reuse or extend the historical capped review.
4. After approval, run the applicable final qualifying gate exactly once in a separate disposable full clone, inspect the final diff, and publish a PR against `development` only if the gate and review are green. -> Expect a verified PR head, accurate limitations, and no merge, deployment, live migration, connector enablement, or pilot claim.

## Acceptance checks

- An accepted explicit start persists one owned `in-progress` label; metadata, capture, rating, imports, and CLIO mentions do not start work.
- Exact repository identity prevents same-number, foreign, malformed, or pull-request records from borrowing authority.
- GitHub projection is opt-in, writes only this label, preserves other labels, and leaves durable local state and replay evidence intact when remote work fails.
- Confirmed terminal state clears only this label; merged PR plus open issue, quiet activity, and a reopened issue without a fresh start do not imply completion or active work.
- Old schemas remain readable, new dumps preserve the field, and existing consumers keep their marker/event compatibility.
- Final review and qualification describe any unresolved environment or baseline failure precisely rather than treating it as a pass.

## Current evidence and stop rules

The refreshed branch contains a selective replay of the original writer implementation and late identity fixes. The reviewer found that ordinary legacy active appearance could establish the new label without qualified admission; the repair limits establishment to `accepted_start=True`. The reopened review also found that direct terminal cleanup did not prove the returned native issue identity; the repair reuses the native issue guard before a closure reason can queue the exact-row terminal mutation. The focused suite now passes 40 Python tests; deliberate appearance and closure-identity mutants both fail. This is implementation evidence only. The final qualifying gate has not yet run on this refreshed branch.

Stop and report rather than expand scope if qualified identity cannot reach the existing connector, a migration/dump contract is ambiguous, the bounded reviewer finds a correctness gap, or the final gate fails after one scoped repair/retest. Do not resolve hosted reconciliation debt, merge-cleanup race conditions, Flight Deck rendering, or Daily integration in this producer lane.
