# RELAY · PR1044 expanded landing review
NEXT: codex
STATUS: Open
ROUND: 1 / 3

## Setup
Operator requests merging PR1044 and Skills Army deployment, explicitly choosing repair/review of the full expanded planner scope. Review the complete final diff against origin/development. Original peer head b706ac89 is preserved in ancestry; ledger conflicts were resolved disjointly through the supported writer at 5f2b8bb8. Production repair is80338e0d; this packet adds only immutable evidence.

Scope: skills/1-hourly/recon/SKILL.md, skills/2-daily/review-code/SKILL.md, weekly-planner/SKILL.md + scripts/planner_core.py, daily-planner/SKILL.md, capture and metadata. N+1 requires exact consumer behavior, logical boundary through wrappers, retry/parameter roles and conditional rollout compatibility. Existing neutral skipped-independent-review notes must survive. Planner must ground native input in successful complete live GitHub data; preserve native empty/filter-empty; scope repo rows; exclude cut releases; retain ratings/risk/build metadata on common DB/CLI path; retain deferred vision work; keep held/cyclic dependents out of landing instructions; do not classify ordinary validation receipts as held. Team/blocker prose is calibrated to actual implementation.

Verification already run in separate disposable full clone:26 manual outcomes (original five failed witnesses, repaired passes, in-memory guard negative control, original five fixture replay), live weekly generation, source ledger hashes unchanged, manifest12 shipped/8 dialed-in for0.6.0, existing GH777 inventory ratchet plus negative control. Receipts and exact probe inputs under TESTS-RESULTS/2026-10-14+GH-1043. The unapproved new test suite is removed; original input is retained only as manual evidence. Full publication gate remains pending after QA.

Review source first, especially degraded native input, dependency ordering, holds, selected repository, release metadata and daily downstream rendering. Graph project XYZ-forge generation2026-09-01 is stale and lacks planner paths; use exact source and bounded reads. Read-only review; do not run test/*.sh, validate.sh, or mutate any artifact other than this thread. No new code/tests, no git commands. One-off nonmutating in-memory checks are allowed, with no bytecode or generated files. Report actual actionable bugs with file:line; unknowns stay unknown, do not invent unrelated scope.

## Log
### Round1 · Producer
Implemented the bounded repairs; all recorded focused/manual verification passed. Independent final review is requested before publication/merge.

## Reviewer instructions
APPEND your whole review block at ABSOLUTE EOF after all existing text. Do not insert above any current block or marker. Change only NEXT/STATUS/ROUND in the header. Write VERDICT: PASS, FAIL, or PARKED and a nonempty Basis. On PASS set STATUS: Approved, NEXT: —, and mark task RELAY-GH1044-LANDING-20261014 done. Keep actionable findings concise and confidence grounded. This thread is the sole allowed writable path.
