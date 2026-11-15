---
gh_issue: 1356
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1356
title: "Flywheel Batch 2: autonomous supervisor outerloop run across critical targets (#1296, #1288, #1287, #1254, #1344)"
status: Partial (attempt terminal; acceptance incomplete)
created: 2026-11-07
owner: unassigned
doc_type: experiment
complexity: 3
risk: 2
effort: 3
phases: 1
ratings_provisional: true
non_goals:
  - no manual step-by-step nudging during the run window
  - no unbounded repair loops (strictly 3 rounds per blocker per #1328)
  - no new test files (GH-831)
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1328
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1298
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1332
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1345
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1353
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1296
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1288
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1287
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1254
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1344
goal: >
  Execute the first full-scale autonomous software factory flywheel campaign under declared supervisor outer-loop (FACTORY_SUPERVISED=1), exercising decoupled intake pickup, cap-stall relay receipt tail recovery, and multi-hour push-along across critical XYZ Forge issues.
---

## Key concepts

- Outerloop supervision: declared via `FACTORY_SUPERVISED=1`.
- Decoupled intake: pickup from `PROJECT/1-INBOX/` creates ledger rows only at execution start (GH-1345).
- Cap-stall resilience: `jog retry-gate` accepts relay-receipt-only tails committed after cap stalls (PR #1354).
- 3-gate bounded repair: maximum 3 diagnosis/repair rounds per blocker (#1328 Rule R2).

## Status

| What was just completed | What's next |
|---|---|
| Terminal attempt accounting committed: agent-assisted PARTIAL / NOT QUALIFIED; issue remains open. | Retain unmet acceptance and prior repair counters; see the closeout evidence matrix. |

## Idea

Conduct the first "real" autonomous software factory flywheel campaign targeting XYZ Forge's most critical and severe open issues (#1296, #1288, #1287, #1254, #1344). An autonomous supervisor outerloop oversees a sub-session worker, monitors execution via a 10-minute heartbeat watchdog over several hours, intervenes when lanes stall using the newly landed cap-stall resilience mechanism, and captures receipts.

## Why

Exercises and validates the complete flywheel pipeline under realistic multi-task load. Proves that decoupled backlog supply, automated admission preflight, isolated worktree execution, and stall recovery function without human intervention.

## Phase 0 — Explore & scope

### Checklist

- [ ] Create disposable runner clone and verify pre-push gate configuration.
- [ ] Verify `FACTORY_SUPERVISED=1` is exported and recognized.
- [ ] Pick up target issues (#1296, #1288, #1287, #1254, #1344) using `roadmap pickup` (GH-1345 cutover verified).
- [ ] Run `swarm_preflight.py` dry-run across picked-up lanes.
- [ ] Enqueue tasks into `jog_queue` and dispatch `jog run` in background.
- [ ] Arm 10-minute watchdog loop for up to 3 hours to monitor liveness and intervene on cap stalls.
- [ ] Capture telemetry, cycle times, and qualification receipts under `TESTS-RESULTS/`.

### QA checklist — Phase 0

- [ ] At least 3 target issues picked up with valid ratings and ledger rows created at pickup time.
- [ ] Preflight dry-run confirms `stale=0, blocked=0, ambig=0` on all picked up lanes.
- [ ] Sub-session executes inside isolated worktree without polluting the primary workspace.
- [ ] Stall recovery tested: `jog retry-gate` accepts relay receipt tail on at least one cap-stalled lane.
- [ ] Run strictly bounded to 3 repair rounds per blocker (#1328).
- [ ] No new tests created (GH-831).

## Ratings rationale

pri 90 / sev 80 / appeal 85 / effort 50 (validates core product flywheel on live severe issues).

## Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "python3 -m pytest test/test_python_layer.py && bash test/gh280-jog-marathon-adapter.sh",
  "fix_probes": [
    { "type": "path_absent", "path": "TESTS-RESULTS/2026-11-07+GH-1356/SUMMARY.md",
      "note": "pre-run: results summary does not exist until campaign completes" }
  ],
  "artifacts": [ "TESTS-RESULTS/2026-11-07+GH-1356/SUMMARY.md" ],
  "artifacts_new": [ "TESTS-RESULTS/2026-11-07+GH-1356/SUMMARY.md" ],
  "remediation": {
    "source": "issue#1356",
    "criteria": "Execute autonomous supervisor outer-loop campaign across critical targets, recording telemetry, cap-stall recoveries, and landed PR receipts in TESTS-RESULTS/2026-11-07+GH-1356/SUMMARY.md."
  }
}
```

## Merge evidence

- PR #1361 merged 2026-11-08 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1324 merged 2026-11-08 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Terminal attempt accounting

Agent-assisted partial / not qualified; NOT acceptance-complete. Issue remains open. Full live-acceptance matrix and preserved friction history: `TESTS-RESULTS/2026-11-08+GH-1356-closeout/SUMMARY.md`. No unmet criterion waived; no further #1344 attempt or stale #1345 dispatch.

## Merge evidence

- PR #1357 merged 2026-11-07 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- commit 0b24095502b9 landed 2026-11-07 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- commit feb2196b8b30 landed 2026-11-07 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- commit 938a96e60542 landed 2026-11-08 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- commit 70847aa14bdf landed 2026-11-08 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- commit 15c8d356756c landed 2026-11-08 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- commit bc2d79398ed4 landed 2026-11-08 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
