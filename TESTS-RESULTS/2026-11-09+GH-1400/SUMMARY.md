# GH-1400 instruction smoke

Source: flywheel SKILL entered through its description and existing ordered flow,
then the new composition section. Manual instruction review, not an executed landing.

| Scenario | Observed instruction / expected action | Verdict |
|---|---|---|
| Main: two independently reviewed exact-head PRs, both operator-approved | Step 6 delegates one pinned approved list to merge-cleanup; existing driver owns ordering/reconciliation and record. No per-stage parent dispatch. | PASS (textual) |
| Adjacent: one PR head moves while checks are pending | Wait binds PR/head; stale result cannot prove readiness. Changed head needs fresh eligibility/review/approval as applicable and re-pin. No merge from old evidence. | PASS (textual) |
| Missing accounting before repair | Hold repair and resolve required owner reservation; no edit-first reconstruction or claim that GH-1399 is implemented. | PASS (textual) |
| Prepared capture has readiness label but stale contract | Selected execution owner revalidates; label alone supplies neither automatic selection nor approval. | PASS (textual) |
| Harness has no event continuation or qualifying timer | State continuation is unarmed; preserve handoff, no shell poll substitute or promised wake. | PASS (textual) |

Baseline comparison: pre-change skill linked handsfree and per-PR landing but lacked
this concrete pinned-batch/event-selection/accounting handoff. No runtime decision gate
changed, so no mutation/red-control claim is made. No real PRs landed, watches armed,
schedulers created or cost saving measured. Assertions in the recorded manual command
checked nonempty consumer source and the exact boundary wording; no new suite was added.

Documentation gate: `bash utils/pdda/pdda.sh run` at 37119562c returned 0 in a separate full clone. 0 errors, 659 inherited warnings (642 issue-state/cache, 8 governance, 9 older marathon-QA); LLM readiness skipped. Identity bracket unchanged. PRS check clean (0 failures, inherited warnings). Final changed paths classified docs/tier 1.
