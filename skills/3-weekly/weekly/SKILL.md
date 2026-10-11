---
name: weekly
description: >-
  Prepare held GitHub intake for an accumulating, branch-backed weekly Jog or Marathon
  proposal. Uses shared 10days discovery and the existing weekly/daily planner core.
  This staged implementation exposes a read-only complete intake preview; ledger
  reconciliation, freeze and dispatch enforcement remain unavailable. Does not auto-fire.
---

# Weekly — held issue intake preview

This entry point is distinct from `/weekly-planner` (team outline) and `/daily-planner`
(closure pivot). Never invoke the whole `/10days` workflow to collect weekly issues:
its unattended rating/promotion/dispatch exception does not apply here.

**Capability status:** staged foundation for [#1022](https://github.com/HiQS-Labs/XYZ-forge/issues/1022).
Only shared discovery and a held preview are implemented. No executable weekly
proposal, `auto-yyyy-mm-dd` lifecycle, durable checkpoint, ledger reconciliation,
frozen approval packet or dispatch/resume/landing enforcement ships here. Keep the
workflow held; do not claim the umbrella complete or enable scheduling/execution.

1. Resolve the shipped harness with `/relay-xyz`'s `find-harness.sh --root`; require
   `skills/3-weekly/weekly-planner/scripts/issue_intake.py` and Python3 in that harness. A copied skill must use
   this selected harness, never assume cwd is Forge or another skill is installed.
   Set `HARNESS` to its returned root. Confirm the swept repo and explicit timestamp.
2. Run the existing core's new, opt-in intake mode:
   ```bash
   PYTHONDONTWRITEBYTECODE=1 python3 "$HARNESS/skills/3-weekly/weekly-planner/scripts/planner_core.py" \
     --repo-root "$TARGET_ROOT" --gh-repo "$TARGET_REPO" --mode weekly-intake \
     --since "$SINCE"
   ```
   `SINCE` is an ISO timestamp with timezone (e.g. `2026-10-05T00:00:00Z`);
   no Monday/Friday/timezone defaults are inferred. `--intake-file PATH` optionally
   carries every prior observed member and re-fetches its current issue state.
   Pass explicitly known carryovers/dependencies in that complete prior snapshot;
   dependency expansion and initial backfill policy remain unimplemented.
3. Inspect `complete`, `issues`, `prs`, `pages`, `holds` and qualified `identity`.
   All updated states (including closed/reopened), all supplied previous members,
   and all open PR pages/files are read. PR entries in the issues endpoint are
   excluded. Duplicate conflicts, foreign URLs, malformed data, partial/offline
   reads or changed PR metadata return UNKNOWN/nonzero. Never advance a checkpoint
   or write a ledger from an incomplete report. Pagination completeness means
   transport completion, not an atomic GitHub snapshot.
4. Treat every result as HELD: `dispatch_allowed` is always false. The reused
   merge sequencing and audit are labeled advisory; their legacy CI/dependency/
   closure heuristics do not establish readiness or acceptance. A closed issue,
   completed doc bucket or linked PR cannot establish criterion delivery.

The preview prints JSON only; it performs authenticated read requests and no
connector writes, DB commits, scratch/output writes, branches, checkpoints,
fetches or dispatch. Setting `PYTHONDONTWRITEBYTECODE=1` also prevents Python import
cache files. Redirecting stdout is an explicit caller-owned local file write;
that output is an observation artifact, never approval or an executable plan.
10days preserves its 10/0 open-updated 200-item scan and document lookup interfaces.

## Required continuation before freeze or dispatch

Continue the canonical [GH-1022 plan](../../../PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md)
and full current issue checklist. Extend existing canonical writers/planners;
never add a second backlog, scoring engine, orchestrator, or `JOG.yaml` contract.
All relevant issues need canonical captures via `hq_render_capture` and RELEASES
CLI registration/reconciliation preserving GIDs, owner ratings/status/overrides,
with `XYZ_WORK_CONNECTORS=0` for unmerged planning writes. Source implementation
belongs on its feature branch; eventual planning uses isolated full clones and
`auto-yyyy-mm-dd`. Concurrent ledger state must reconcile through sanctioned APIs.

The unimplemented shared safety protocol requires independent code-aware evidence
for every acceptance criterion on exact target HEAD/plan hash/planning commit;
already delivered work becomes no-op, partial work narrows/regenerates, overlapping
active work or conflicting/unknown evidence holds. Recheck immediately before fire,
each phase and resume, and separately before landing for duplication/regressions.
Exact operator approval names the immutable packet/order/reviewer/budget and cannot
survive material drift. Preserve #752/#1020 recovery holds, existing active-run limits
and separate landing authority. Never use these instructions as proof runtime gates
exist. No dispatch entry point is added in this staged skill.

Every individual new CI test, including cases in existing suites, requires explicit
operator approval identifying it. Proposals stay outside executable write-sets until
approved. Existing checks/manual negative controls may run in disposable full clones;
no installation, schedule, real Marathon/Jog, merge or deployment is authorized by
running this skill. Recheck exact `weekly` names/aliases before separately approved
Skills Army deployment; preserve weekly-planner/daily-planner routing.
