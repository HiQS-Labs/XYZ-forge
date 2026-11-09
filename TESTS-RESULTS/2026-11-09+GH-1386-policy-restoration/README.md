# Restore the original promotion policy

Pinned flywheel7c382a59 Mode1B recovery, start2026-11-09T02:54:00Z, cutoff04:24:00Z. Restore the exact pre1389 policy bytes and finish1384/1386 bookkeeping. No flywheel installation or1378 merge,1390 implementation,1327/1388 batch, cleanup, schedule or promotion.

The earlier779ffe506 restoration was capped without a passing gate. This recovery cherry-picks its policy onto published e695d326 and retains the prior failed/capped evidence in draft1391. Normal qualification is still pending at this commit.

Discrimination: temporary live policy differs from original-policy.json (expected RED for byte equality); this restored file matches the nonempty original bytes exactly. Original SHA256:375ac61e7589b6a7ae6da78da2a696dd1c95f193a512bd5b25ac3af58b2cf259. Restores promotion cadence and hosted sweep declaration, removes temporary canary/local sweep; no workflow is dispatched.

Plan: independent source/recovery QA; normal push gate in separate disposable full clone (<=1800s, max2 recovery attempts); exact-head hosted checks; approved no-delete merge and individual canonical reconciliation stages; actual unpublished writes gated from separate clone, otherwise fresh nonempty remote equality without a no-op push. Never invoke the known unsafe full publication fallback. Finish clean primary equal live origin and retain failures.

Rubrics: real policy drift eliminated only after durable merged bytes match; distinguish old temporary bytes, local restore and actual live publication; record start/end, gates, repairs and human interventions, tokens unknown. Existing1390 counters remain exhausted; max3 routine rounds per new blocker, no cap reset. This is agent-assisted setup/recovery, not formal unattended execution or a real multi-PR speedup trial.

## Fresh recovery qualification

2026-11-09T02:56:03Z–03:05:09Z: first normal full push408/408GREEN; hook543s, outer545.367s. Source898801a3, separate full clone, before/after HEAD/origin/bare/localidentity unchanged. No retry, bypass or1390 repair. Subsequent evidence-only normal publication and hosted exact-head checks remain separate; durable restoration still requires merge/reconciliation.

## Durable restoration and bookkeeping

PR1392 exact4e9b4691 hosted42554551752 SUCCESS, merged 4394c7c4cf65871fc33f40945b1fb13d88fbc45a. Canonical individual reconciliation also reran1384 after corrective issue1381 closure; recovery inventory uncertainty stays separate. Fresh runtime gate1/2 passed, no new blocker repair or1390 counter reset. Final publication and SHA are recorded in issue1386.

## Completion filing and explicit skill installation

Original policy was durably restored by1392 merge4394c7c4 and normal reconciliation/publicationf5009284 (docs87s, caller266.550s). The Refs-only1384 issue document still needed the supported explicit delivered-issue1381 path; it now moved to3-COMPLETED and its existing ledger row was repointed, with no unrelated sweep or force.

The user subsequently explicitly requested Flywheel installation through Skills Army HQ, overriding this recovery's earlier no-install boundary without authorizing1378 merge. Only intake.py/sync.py mutated the existing Pulse collection and owned links. Clean pinned unmerged7c382a59 source, digestcda1bbb7eead243fa264d644767a8c31391d239387b6e16604b1b1e2637d30ab, receipt matches,6configured links readable, Pulse commit27fc810df. Initial STALE_PULSE_COLLECTION warning cleared after supported clean fast-forward; final warnings/errors empty. GUI discovery remains unverified, Grok Mac staging only. No deployed file/link hand edits.

Recovery outcomes are agent-assisted. One full qualification attempt used, no failed qualification/retry or new blocker repair in this window; earlier1390 counters unchanged. The nonblocking source-CLI primary identity refusal is retained. Human input: explicit recovery authorization and later installation request; no routine approval intervention requested. Tokens unknown. Final elapsed/publicationSHA and process closeout are recorded in issue1386 after normal final bookkeeping publication. No1378/1388 landing,1327fix,1390 implementation, cleanup, schedule or promotion.
