# Restore the original promotion policy

Pinned flywheel7c382a59 Mode1B recovery, start2026-11-09T02:54:00Z, cutoff04:24:00Z. Restore the exact pre1389 policy bytes and finish1384/1386 bookkeeping. No flywheel installation or1378 merge,1390 implementation,1327/1388 batch, cleanup, schedule or promotion.

The earlier779ffe506 restoration was capped without a passing gate. This recovery cherry-picks its policy onto published e695d326 and retains the prior failed/capped evidence in draft1391. Normal qualification is still pending at this commit.

Discrimination: temporary live policy differs from original-policy.json (expected RED for byte equality); this restored file matches the nonempty original bytes exactly. Original SHA256:375ac61e7589b6a7ae6da78da2a696dd1c95f193a512bd5b25ac3af58b2cf259. Restores promotion cadence and hosted sweep declaration, removes temporary canary/local sweep; no workflow is dispatched.

Plan: independent source/recovery QA; normal push gate in separate disposable full clone (<=1800s, max2 recovery attempts); exact-head hosted checks; approved no-delete merge and individual canonical reconciliation stages; actual unpublished writes gated from separate clone, otherwise fresh nonempty remote equality without a no-op push. Never invoke the known unsafe full publication fallback. Finish clean primary equal live origin and retain failures.

Rubrics: real policy drift eliminated only after durable merged bytes match; distinguish old temporary bytes, local restore and actual live publication; record start/end, gates, repairs and human interventions, tokens unknown. Existing1390 counters remain exhausted; max3 routine rounds per new blocker, no cap reset. This is agent-assisted setup/recovery, not formal unattended execution or a real multi-PR speedup trial.
