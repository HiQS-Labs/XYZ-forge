---
title: "GH-1051: development-only Pages publishing"
status: Working
created: 2026-10-12
updated: 2026-10-15
owner: Codex
gh_issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1051
branch: fix/XYZ-forge-gh1051-pages-development-2026-10-12
goal: "Align Pages workflow triggers and jobs with the operator's development-only policy."
---

# GH-1051: Pages publishing

## Status

| What was just completed | What's next |
|---|---|
| Operator admitted PR1053 for review and conditional development landing; current-base caller reconciliation preserves the reviewed workflow and all authoritative incoming ledger/history. Original final QA1/3 and earlier full evidence remain historical. | Independent current-base final round2/3, existing focused checks and normal publication/premerge/hosted landing qualification; source-bound results will be retained in the continuation evidence folder. |

Intake base0085ceee5269c9edfa22d77a96e08edf158a8cc5 (development advanced from earlier ecbe7722 preflight; Pages unchanged). Exact-main Pages38326961150 built but deploy was forbidden by github-pages policy permitting onlydevelopment. Operator chose development-only publishing and requested bounded fix/draftPR, not landing or deploy. Currentmain4895148683120b8b6f808d4dcd66267a3754fd2c remains immutable and qualified.

The existing workflow has pushdevelopment/main, unrestricted workflow_dispatch, a shared pages concurrency group, and unguarded build/deploy jobs. Change its four declarations: pushdevelopment only, per-ref concurrency, and development-ref if guards on both jobs. The per-ref group prevents a skipped nondevelopment dispatch from cancelling an activedevelopment publish. Permissions/actions/environment/build remain unchanged. Easy/local/reversible via ordinary PR revert; scope is one workflow, not environment authorization.

This simple change implements an already chosen policy in a fully-read64-line file; separate plan QA is exempt, but independent final native Codex QA and existing validation are required. No new CI tests/cases/params. Existing registeredci-workflow checks action contracts; record manual event/ref acceptance and original red controls for routing. Preserve failed/skipped checks honestly; no live Pages dispatch/deployment is authorized.

Ratings70/45/50/95 (priority operatorurgency; severity intent mismatch/redCI, homepage available; appeal neutral; effortcheapness four declarations). One captured main rejection, trend otherwiseunknown; no rankoverride.

1. Park/rate/admit onlyowned1051 row, then promote this capture toactive.
2. Apply four workflow declarations -> developmentpush/manual admitted; main/tag/othermanual jobs skipped; concurrency groups isolated byref.
3. Existing ci-workflow and recorded original/fixed controls in disposablefullclone -> source-bound nonemptyreceipts; no testchanges.
4. IndependentfinalQA within3rounds, normal applicablepushgate, draftPR/exacthead checks -> report ready for operatormerge decision. No merge/deploy/reconcile or environmentchanges.

Currentmain's old workflow is unchanged; it retains the environment's main refusal until a separately authorized futurepromotion brings the fix. Draft publication does not prove installed/published website behavior.

## Acceptance

- Development-only workflow push filter and job guards, retaining manualdevelopment.
- Nondevelopment dispatch cannot cancel development publication via shared concurrency.
- Environment protection/permissions/actions/build unchanged; no new testcases.
- Existing checks/manual red-green controls and independent QA support draft readiness.

## Merge evidence

Pending; no landing authorized.

## Lessons Learned (For Future Agents)

Workflow intent must match environment source-branch policy. A successful artifact build is not proof of deployment; a rejected new artifact does not establish existing-site downtime.

## Draft verification checkpoint

Full normal push gate passed409/409 at baf31e72 after two built-in serial fixture rechecks; earlier sandbox EPERM refusal is retained under TESTS-RESULTS/2026-10-12+GH-1051/full-baf31e72. No bypass or testchanges. Draft https://github.com/HiQS-Labs/XYZ-forge/pull/1053 targetsdevelopment. Currentdevelopmentb9f07ea5 differs from intake only by externally landed evidence/relay receipts; Pages executable content unchanged. This proof/status-only carrier does not claim a fresh full run on its later SHA. Final exact-head hosted checks remain pending. No merge/deploy authorized.

## Authorized merge continuation — 2026-10-15

The operator explicitly approved taking PR1053 out of draft, finishing its review/checks and merging into development if they pass. Ready status was verified. This supersedes the historical draft-only authorization above; it does not authorize main promotion, workflow dispatch or environment changes. Original native final round1/3 and raw failures remain; the next independent review is cumulative2/3. The earlier local preparation at95ebe8a1 is retained as repair1/2; this current-base caller episode is repair2/2, never reset.

Adopt the qualified1068 reconciliation14081d61, preserve its authoritative Completed states and all existing business rows, and replay only GH1051 through the canonical roadmap writer. Automatic B1 refusal is retained; no SQL union or gate override. Candidate proof, focused checks, final review and normal publication receipts are recorded under `TESTS-RESULTS/2026-10-15+GH-1051-merge/`. The batch plan and actual outcomes are tracked in GitHub issue1086. A passing local publication run is not exact-main promotion qualification.
