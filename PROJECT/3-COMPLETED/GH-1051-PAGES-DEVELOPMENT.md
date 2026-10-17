---
title: "GH-1051: development-only Pages publishing"
status: Complete
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
| Operator admitted PR 1053 for review and conditional `development` landing; current-base caller reconciliation preserves the reviewed workflow and all authoritative incoming ledger/history. Original final QA 1/3 and earlier full evidence remain historical. | Independent current-base final round 2/3, existing focused checks and normal publication/premerge/hosted landing qualification; source-bound results will be retained in the continuation evidence folder. |

Intake base `0085ceee5269c9edfa22d77a96e08edf158a8cc5` (`development` advanced from earlier `ecbe7722` preflight; Pages unchanged). Exact-main Pages `38326961150` built but deploy was forbidden by `github-pages` policy permitting only `development`. Operator chose `development`-only publishing and requested bounded fix/draft PR, not landing or deploy. Current `main` `4895148683120b8b6f808d4dcd66267a3754fd2c` remains immutable and qualified.

The existing workflow has `push` `development`/`main`, unrestricted `workflow_dispatch`, a shared `pages` concurrency group, and unguarded `build`/`deploy` jobs. Change its four declarations: `push` `development` only, per-ref concurrency, and `development`-ref `if` guards on both jobs. The per-ref group prevents a skipped non-`development` dispatch from cancelling an active `development` publish. Permissions/actions/environment/build remain unchanged. Easy/local/reversible via ordinary PR revert; scope is one workflow, not environment authorization.

This simple change implements an already chosen policy in a fully-read 64-line file; separate plan QA is exempt, but independent final native Codex QA and existing validation are required. No new CI tests/cases/params. Existing registered `ci-workflow` checks action contracts; record manual event/ref acceptance and original red controls for routing. Preserve failed/skipped checks honestly; no live Pages dispatch/deployment is authorized.

Ratings 70/45/50/95 (priority operator urgency; severity intent mismatch/red CI, homepage available; appeal neutral; effort cheapness four declarations). One captured `main` rejection, trend otherwise unknown; no rank override.

1. Park/rate/admit only owned 1051 row, then promote this capture to active.
2. Apply four workflow declarations -> `development` push/manual admitted; `main`/tag/other manual jobs skipped; concurrency groups isolated by ref.
3. Existing `ci-workflow` and recorded original/fixed controls in disposable full clone -> source-bound nonempty receipts; no test changes.
4. Independent final QA within 3 rounds, normal applicable push gate, draft PR/exact head checks -> report ready for operator merge decision. No merge/deploy/reconcile or environment changes.

Current `main`'s old workflow is unchanged; it retains the environment's `main` refusal until a separately authorized future promotion brings the fix. Draft publication does not prove installed/published website behavior.

## Acceptance

- Development-only workflow `push` filter and job guards, retaining manual `development`.
- Non-`development` dispatch cannot cancel `development` publication via shared concurrency.
- Environment protection/permissions/actions/build unchanged; no new test cases.
- Existing checks/manual red-green controls and independent QA support draft readiness.

## Merge evidence

Pending; no landing authorized.

## Lessons Learned (For Future Agents)

Workflow intent must match environment source-branch policy. A successful artifact build is not proof of deployment; a rejected new artifact does not establish existing-site downtime.

## Draft verification checkpoint

Full normal push gate passed 409/409 at `baf31e72` after two built-in serial fixture rechecks; earlier sandbox EPERM refusal is retained under `TESTS-RESULTS/2026-10-12+GH-1051/full-baf31e72`. No bypass or test changes. Draft https://github.com/HiQS-Labs/XYZ-forge/pull/1053 targets `development`. Current `development` `b9f07ea5` differs from intake only by externally landed evidence/relay receipts; Pages executable content unchanged. This proof/status-only carrier does not claim a fresh full run on its later SHA. Final exact-head hosted checks remain pending. No merge/deploy authorized.

## Authorized merge continuation — 2026-10-15

The operator explicitly approved taking PR 1053 out of draft, finishing its review/checks and merging into `development` if they pass. Ready status was verified. This supersedes the historical draft-only authorization above; it does not authorize `main` promotion, workflow dispatch or environment changes. Original native final round 1/3 and raw failures remain; the next independent review is cumulative 2/3. The earlier local preparation at `95ebe8a1` is retained as repair 1/2; this current-base caller episode is repair 2/2, never reset.

Adopt the qualified 1068 reconciliation `14081d61`, preserve its authoritative Completed states and all existing business rows, and replay only GH-1051 through the canonical roadmap writer. The earlier draft-preparation refusal is retained. This current preflight classified the ledger changes as disjoint; only the GH-1051 row was replayed through the existing writer, with no SQL union or gate override. Candidate proof, focused checks, final review and normal publication receipts are recorded under `TESTS-RESULTS/2026-10-15+GH-1051-merge/`. The batch plan and actual outcomes are tracked in GitHub issue 1086. A passing local publication run is not exact-`main` promotion qualification.
