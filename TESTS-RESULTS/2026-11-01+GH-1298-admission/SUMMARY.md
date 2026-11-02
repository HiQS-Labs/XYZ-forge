# GH-1298 step 1: admission census over the open backlog

- **Measured:** 2026-11-01 on `origin/development` `aba59100`, 298 open issues. Script: `admission_census.py` (read-only; reuses the marathon planner's own admission states, the #1251 fail-closed slice, then runs the live preflight dry run on each planner-ready issue). Raw: `census.json`, `census-summary.json`, `preflight-<n>.json`.
- **Result: 6 of 298 open issues (2.0%) are admissible**: #670, #1263, #1264, #1265, #1266, #1267. Phase 0 (2026-10-27) found 0 of 281.

| Stage | Issues | Share |
|---|---:|---:|
| No ledger row | 202 | 67.8% |
| Needs a Preflight Contract | 67 | 22.5% |
| Planner-ready | 8 | 2.7% |
| Needs a capture doc | 7 | 2.3% |
| Deferred | 6 | 2.0% |
| Already landed (live probes) | 4 (#141, #275, #423, #492) | 1.3% |
| Open in the ledger but marked completed | 2 (#193, #591) | 0.7% |
| Unrated | 2 | 0.7% |

The 8 planner-ready issues went through the live preflight dry run: **6 READY** (rc 0), **#355 STALE** (rc 4), **#1098 AMBIGUOUS** (rc 7; it is also delivered by merged PR #1274). No admissible issue has an open PR or a merged PR that closes it.

## What this says

1. **The same two stages still dominate.** 202 issues (68%) have no ledger row and 67 (22%) have no Preflight Contract: 90% of the backlog is blocked before readiness is even asked. Phase 0 found 73% and 64 respectively.
2. **The gain is new, well-formed intake, not repaired backlog.** Five of the six admissible issues (#1263 to #1267) were filed on 2026-10-30 with contracts; the sixth, #670, dates from 2026-09-17. The 269 older issues in the two big blocked stages were not repaired in bulk.
3. **Live evidence caught what field checks pass.** Four issues the Phase 0 field checks called admissible are now correctly "already landed", and #355 and #1098 pass the planner but fail live preflight (STALE, AMBIGUOUS).
4. **The largest single lever is already filed.** #1267 (`hq park --gh-issue`) registers an already-filed issue (capture doc plus ledger row). It targets the 202-issue stage, and it is itself admissible.

## Limits

- **Not the Phase 0 method.** Phase 0's survey script is not in the repo, so its field checks cannot be replayed. This census uses the planner's states, which include #1251's fail-closed rules, so stage counts are comparable in kind, not in definition. The open-issue base also differs (298 vs 281).
- **Exclusion windows.** Delivered-by-merged-PR and open-PR links use the newest 300 PRs of each kind (the window `init` freezes); older ones are not seen. This census found no hit on the six admissible issues.
- **Acceptance fidelity.** #670 passes preflight although its issue has no `## Acceptance` section (`acceptance_fidelity: unknown`). Admissible here means preflight-ready, not reviewed.
- **No authority.** The census is a measurement; it admits nothing and writes no ledger or issue.
- **Single snapshot.** One run, no trend.
