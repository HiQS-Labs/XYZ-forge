---
gh_issue: 1387
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1387
title: Preserve successful lane attempt history
status: In progress
updated: 2026-11-08
owner: Codex
goal: Retain exact attempt history without changing live budget semantics
created: 2026-11-08
doc_type: bugfix
---

# Preserve successful lane attempt history

## Status

| What was just completed | What's next |
|---|---|
| Exact-byte baseline RED/fixed GREEN, adjacent controls, focused suites and independent final QA Approved | 408/408 full gate passed; publish ready PR for parent outer inspection, awaiting merge |

Marathon and standalone relay success currently unlink `.tick/attempts/<lane>`. GH1254 gate-only recovery lost exactly two records (SHA256 d2565905a3f76fb1f98294f476b29515b3a671d28e6e27ac75c4f8924cd6aff2); the supervisor restored them before checkpoint publication. Merged evidence: TESTS-RESULTS/2026-11-08+GH-1358-rehearsal/clock/recovery/success-counter-repair.json and gate-start.json.

Scope: preserve exact old attempt bytes in unique archives inside the existing attempt artifact area before clearing the live budget. Keep existing success reset boundary and nested LANE_ATTEMPT_COUNTED ownership. Failed fresh executions still accumulate; successful reset permits a new budget. Gate-only success captures the pre-reset count for its existing result receipt. No new queue, ledger, runner, suite or gate.

Acceptance: baseline RED and fixed GREEN for actual two-record payload; failed gate, gate-only retry, post-approve failure, standalone/nested relay, repeated success, new execution/cap, archive-error controls. Existing focused suites and one reserved full gate in disposable full clone; independent plan and final QA; ready PR to development, no self-merge.

Duplicate/owner search: attempt history and attempt reset searched all issues on 2026-11-08; read #279, #1006, #1254 and #1358. They own broader retry/recovery/qualification, not this focused retained-byte defect. Parent umbrella #1386; qualification #1358 remains open.

Setup/repair rubric 1B: successful/retried work retains inspectable attempt-budget history while legitimate budget semantics remain correct. Small artifact-preservation fix, not a framework. 120 minutes from 2026-11-08T23:44:07Z; 2 builder attempts, 3 repair rounds/blocker, <=1800s full gate only after parent host-slot grant. Subscription Codex; tokens unknown. Agent-assisted, not unattended qualification. No primary working-tree writes, cleanup, schedule, exposure or merge.

Proposed PRS 85/80/50/85: observed audit data loss requiring manual reconstruction; narrow shared-runtime fix. One concrete incident on Nov 8; recent-window search cannot establish recurrence rate, unknown trend. Appeal neutral. Reversibility Easy: revert code, archives remain inspectable; no schema migration.

## Ordered implementation and proof

1. Extend shared `rtl.py` with archive-before-reset: atomically rename the live attempt file into a unique directory under `.tick/attempt-history/`, preserving exact bytes. Missing file is a no-op; errors propagate with the source path. Both existing reset callers retain the counted guard. -> expect archives survive repeated success, no live counter after success, failure retains live bytes.
2. Capture Marathon gate-only count before reset in the existing result state; leave reset before post-approve exactly where it is. -> expect receipt count 2, no additional dispatch, post-approve failure retains archive.
3. Replay baseline and candidate using actual GH1254 two-record payload and existing driver fixtures in a disposable full clone. -> expect baseline loss, candidate retention; failed gate/fresh executions, nested relay and archive-error controls discriminate.
4. Independent final QA, then parent-reserved full gate and normal push/ready PR to development. -> expect exact source SHA, passing checks and parent outer inspection; no merge or cleanup.

## Plan QA and dispositions

Independent Codex review approved with conditions (receipt `relay-system/2026-11-08/gh1387-plan.codex.md`). All accepted: preserve before reset with unique archives and visible failure; cover standalone Relay and nested counted guard; retain existing pre-post-approve reset boundary; capture gate-only count. Fresh execution IDs never reset failed budgets (`jog_run.py`); archive is passive evidence, never a budget input. No new subsystem or gate.

## Rubric and cost

Capability is retained audit bytes plus unchanged live budget behavior, not a PR count. Baseline and candidate replay decide whether the bounded fix works. Start 23:44:07Z; fixed deadline 2026-11-09T01:44:07Z. Budget 120 minutes, two builder attempts, three repair rounds per blocker, one full gate capped at 1800 seconds only with parent reservation. Agent-assisted. Tokens unknown. Primary working tree/index/ledger and peer refs untouched; task-branch object writes authorized. No global skill installation; flywheel pinned to PR1378 commit 7c382a594057d2992b9dace28569adfd6130db00, fetched via GitHub.


## Delivery evidence

Scoped rubric PASS: exact original history survives success, failed attempts still accumulate, new post-success budget starts at one. Full gate 408/408 on dc02fa19a; initial406/408 and both focused repair controls retained. One builder session, one import-order repair and one caller-environment repair; no extra worker dispatch. Plan/final independent QA Approved. Evidence and actual costs: `TESTS-RESULTS/2026-11-08+GH-1387/SUMMARY.md`. Not merged or unattended-qualified; #1254/#1358 remain open.
