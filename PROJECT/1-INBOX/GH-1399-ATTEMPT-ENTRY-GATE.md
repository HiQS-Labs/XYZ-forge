---
gh_issue: 1399
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1399
title: Attempt accounting at qualification entry
status: Captured
created: 2026-11-10
updated: 2026-11-10
owner: Codex
goal: Refuse unaccounted task qualification through existing gate boundaries while preserving legitimate harness and administrative flows
---

## Status

| What was just completed | What's next |
|---|---|
| Canonical issue and remote verified; isolated task clone and read-only entry/state recon complete | Resolve candidate binding and completed-attempt semantics, reproduce controls, then independent Codex plan QA |

## Request and scope

Issue1399 requests fail-closed qualification/pre-push accounting, automatic binding for standard harnesses and instructional start-task/workhorse flows, a supported manual repair entry, preserved consumed rounds, and unchanged non-task administrative routing. No merge or deployment is authorized by this start-task invocation.

## Acceptance

- [ ] Unaccounted mutation on a task branch is refused at push and direct local qualification boundaries.
- [ ] A valid canonical reservation or candidate-bound completed receipt permits the same qualification.
- [ ] Lane and merge-repair histories retain all consumed rounds; no migration/reset silently replenishes budgets.
- [ ] Reconciliation and docs-only integration-root updates retain existing ci-route behavior.
- [ ] Main and adjacent paths include archived/completed attempts, nested counted ownership and disposable full verification clones.
- [ ] Independent Codex plan and final QA Approved, applicable focused/final gates pass; ready PR targets development.

## Intake and rating rationale — 2026-11-10

Proposed75/60/50/35: priority follows the operator's next dependency after1400/1401; severity60 is observed accounting/audit drift with recoverable supervision cost, not evidence of data loss. Appeal50 is neutral: issue's initial60 is a proposal, with no explicit operator score identified. Cheapness35 reflects the traced producer/consumer and clone-transfer seams, broader than the issue's narrow-hook estimate40. No existing ledger rating/override found. Recent windows2026-10-27..11-10 versus10-13..10-26: one reported bypass class in1399 citing1386/1397;1387 is distinct history-retention behavior, not a second bypass incident. Coverage limited; trend unknown, not zero.

## Current recon

See `PROJECT/2-WORKING/recon-gh1399-attempt-entry-gate.md`. Base68367d6682737b5bcdb324c1bede6def53c197a2. Prior-art scan matched1403 only; its documentation explicitly delegates enforcement to1399 and does not solve this issue. No1399 clone, canonical task doc, roadmap row or open matching PR existed at pickup.

## Constraints and design questions

Existing lane fire files and merge-cleanup JSON reservations remain their respective accounting authorities. No parallel ledger, scheduler, runner, test suite or registry entry. The requested guard extends existing qualification boundaries; documented operator bypasses and unsafe-worktree refusal remain unchanged. A counter or truthy LANE_ATTEMPT_COUNTED alone is not a reservation. Bindings must cover both active work and legitimately completed/archived work, including separate full qualification clones. Merely requiring outcome=in_progress is incorrect.

A qualification guard can detect missing accounting, not infer logical repair episodes inside an authorized reservation. This limitation must remain explicit. Production implementation has not started; plan and authority/binding decision remain pending.

## Reversibility

Costly: a bad predicate could block every task publication or qualification. Rollback must revert the reader and its producer integrations together; retain all existing attempt bytes and historical receipts. No new source of truth or destructive migration.
