---
title: Recon GH-1400 supervision composition
status: Reference
created: 2026-11-09
updated: 2026-11-09
owner: Codex
goal: Map downstream composition before changing flywheel instructions.
roadmap_exempt: true
---

# Recon Map — GH-1400 supervision composition

Commit: 39207869450ee7115dcd9b552fb1bcacd15e203b · Mode: grep-only · Lanes: A/B/C/D in one agent

## Status

| What was just completed | What's next |
|---|---|
| Existing downstream owners traced. | Use the canonical GH-1400 plan for the instruction extension. |

## Subject and change class

Flywheel downstream handoff; cross-document instruction change, with no new state authority.
All following source findings are confirmed by file reads; issue proposals remain supplied requirements.

## The seams — where a change here escapes this file

| Seam | Location | Crosses | Breaks if |
|---|---|---|---|
| Execution owner | skills/2-daily/flywheel/SKILL.md:139 | Jog / Marathon | Caller starts a second engine or bypasses prerequisite. |
| Batch selection | skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:491 | PR heads / pinned coordinator | Allowlist mistaken for merge permission or stale pins accepted. |
| Native continuation | skills/1-hourly/handsfree/SKILL.md:43 | Current harness / same conversation | Timers claimed available without receipt/readback. |
| Accounting | skills/2-daily/merge-cleanup/scripts/attempt_record.py:29 | Durable per-PR reservation | Raw edits mistaken for automatically metered repairs. |
| Intake handshake | utils/py/swarm_preflight.py:108 | Prepared contract / execution selection | Readiness label mistaken for actual admission. |

## Call paths in

`flywheel` → existing ordered steps (`skills/2-daily/flywheel/SKILL.md:124`) →
execution owner step 3, review step 4, continuation step 5, authorized landing step 6.
Landing → merge-cleanup pinned selection (`merge_cleanup.py:513`) → required checks
(`merge_cleanup.py:542`) → live merge and reconcile, governed by its skill at lines 339–350.

## State

Merge-cleanup selection writer is `pin_selection` at `merge_cleanup.py:491`; its
consumer `verify_selection` at line 513 checks open/non-draft/exact head before use.
Attempts are owned by `attempt_record.py:48` at the explicit coordinator; its locked
writer is described at lines 1–15. Relay has a separate lane-owned attempt path at
`utils/py/relay_drive.py:247`; `LANE_ATTEMPT_COUNTED` suppresses nested counting.
These are existing distinct scopes, not one interchangeable lease.

## Contracts

`--prs N@sha` constrains selected PRs, not a generator of new work
(`merge_cleanup.py:513–539`). Required checks classify pending/failing/unknown at
lines 542–570. Handsfree requires same-conversation creation, readback and cancellation
(`skills/1-hourly/handsfree/SKILL.md:43–76`). Preflight requires nonempty fix_probes
(`utils/py/swarm_preflight.py:108`); GH-1401 owns preparation, no new label consumer.

## Build, failure and rollback today

No production build change. Flywheel skill text is instruction-only and currently routes
as docs; final changed-path classifier remains authoritative. Merge-cleanup refuses
missing/stale pins, defers failed checks and re-pins changed heads (skill lines 236–250).
Its outcomes distinguish stop/deferred/QA-pending (skill line 337). Raw push hook currently
routes gates (`githooks/pre-push:90`); GH-1399 remains a proposal for enforcement,
not proof of an active universal attempt lease. Rollback is reverting the instruction patch.

## Step N+1 Downstream Checks

- Consumer hop: selection is accepted only for open non-draft PRs and exact pinned head at `merge_cleanup.py:513–539`; then required check states are evaluated at 542–570. No new readiness state is written by this change.
- Retry hop: repaired heads are deferred and require checks plus dry-run re-pin before execute (`skills/2-daily/merge-cleanup/SKILL.md:250`); resume preserves parked attempt history (line 338). Caller must not renew caps.
- Parameter role: `--prs` is a constraint; other discovered PRs do not gain landing eligibility (skill line 241).
- Rollout/rollback: no persisted format change; old/new instruction readers coexist, but undeployed copies retain prior instructions. No deployment is part of this task.

## Unknowns

| Unknown | Why it matters | What would settle it |
|---|---|---|
| Native event/watch capabilities in another harness | Instructions cannot promise a particular API everywhere. | Live capability discovery at each run. |
| Real-world supervision reduction | Text review cannot prove lower runtime/token cost. | A bounded GH-1386 real-work trial with interventions and cost records. |
| Universal fail-closed attempt enforcement | Existing owner wrappers do not intercept every raw edit/gate. | GH-1399 implementation and discriminating receipts. |

## Current-state radius, one line

Flywheel callers, Jog/Marathon execution owners, merge-cleanup pinned batch/repair records and native same-conversation continuation facilities.

No lane was cut off within the instruction scope; broader #1399 enforcement and #1386 runtime qualification were deliberately left with their owners.
