---
gh_issue: 1609
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1609
title: "Flywheel arc daily ledger — 2026-11-26 — Prove admission"
status: Proposed (1-INBOX — not yet active)
created: 2026-11-25
doc_type: feedback
effort: 3
complexity: 3
risk: 3
phases: 1
---

# Flywheel arc daily ledger — 2026-11-26 — Prove admission

## Outcome

Day 1 of the Nov 26–28 Flywheel proving arc, Pacific time. Planned window: 3 hours including a 30-minute evidence and handback reserve.

## Operating agreement

Planning only. The scoreboard is #1400 (9/20 credited), with separate Kickstart qualification in #1541. The run owner uses Kickstart/Flywheel and existing Conveyor → Jog → Preflight → Marathon and merge-cleanup owners. At launch confirm exact UTC start/end, readiness, capacity, authority and remaining attempts. Keep one execution owner per lane and one long-horizon run in flight. Use independently reviewed/pinned artifacts, exact-head gates, native completion, and a separately approved exact-head landing batch when applicable.

Reserve the last 30 min of every window for evidence and handback. The supervisor keeps the main run moving. Delegate incidental blockers to one isolated repair sub-session at a time, up to 30 min total per day within tighter native ceilings and current authority. A repair qualifies only if it blocks safe dispatch, trustworthy evidence or a needed delivery. Before delegating, pin the lane and its owner. Give the repair its own full clone and write set. Its result is a reviewed candidate or hold receipt. The supervisor adopts a repair only through the normal current-head approval and gate path. Continue independent eligible work with disjoint write sets; park cosmetic, unresolved and unauthorized fixes with owner/reason. Batch operator decisions at the handoff unless safety or authority requires stopping. Primary engineering work explicitly planned for the day is outside the incidental reserve. Repairs/parent interventions are recorded as assisted; preserve holds, attempt budgets, deadlines and approvals.

Use existing suites or isolated manual controls in disposable full clones. Record UTC, exact SHA, role, commands and exits, PR/receipt and worker effects, held items, supervision and next action. Credit only evidenced outcomes. Filing grants no launch or merge authority. Keep the GitHub issues in planning state until launch. Only the authorized launch step adds unchecked task-list lines with one exact local issue reference each, then verifies the generated scope and carried authority. No new scheduler, test suite or production fault injection.

## Day 1 plan

Owner: admission lead with one scoped builder and independent reviewer. This controls-first ledger is a setup/repair plan, not a machine queue input. On the pinned published baseline, replay ready, human-held, dependency-held, stale acceptance and stale reviewed-source cases through the real Jog → Preflight → Marathon entrypoint. Only stub the worker boundary and use disposable local fixtures. If the known #1476 gap persists, make the smallest reviewed change using the current preparation record and existing Jog/Preflight park/history writers. Green means ready dispatches, held/stale cases give zero worker calls, and refreshing the same row preserves global ID, history and attempt budget. Budget the normal independent review and qualifying gate within the primary window. If not green and published, the later live automatic runs default to rehearsal. A candidate awaiting exact-head approval, merge or reconciliation is still a hold.

In parallel, line up Day 2 candidates #1315 and #977 with canonical Conveyor packets, current red reproductions, prior landing/ownership/attempt checks, no overlap and recorded admission decisions. Prefer aligning #1315 preview with the existing apply refusal and remedy, preserving adoption policy; hold a material policy choice without authority. #977 has a documented recurrence, and the inspected production ledger has no Jog row, so verify receipts rather than assume a fresh budget. Keep Day 3's selected candidate raw for its own preparation. Hand back exact evidence, landing decision if needed, and Day 2 go/no-go.

## References

Flywheel scoreboard #1400, outer-loop rubric #1328, admission counterexample #1476, proving-run plan #1418, and Kickstart qualification #1541.

## Related daily ledgers

- Day 1 · Prove admission · https://github.com/HiQS-Labs/XYZ-forge/issues/1609
- Day 2 · Prove continuation · https://github.com/HiQS-Labs/XYZ-forge/issues/1610
- Day 3 · Prove checkpoint recovery · https://github.com/HiQS-Labs/XYZ-forge/issues/1611
