---
title: "Post-merge regression QA: development merges 2026-10-29 → 2026-11-01 (21 PRs)"
status: In progress
created: 2026-11-01
updated: 2026-11-01
owner: noelsaw1
gh_issue: 1308
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1308
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
non_goals:
  - Items 9-12 of #1308 (validate.sh receipt policy, teardown defence in depth, GH-831 test cases, relay render note), which need Noel's decision
  - Any new test suite or validate.sh registration (GH-831)
  - The pre-existing weekly-planner Skills Index gap (#936)
related:
  - GH-1270 / #1274 (delivered map), GH-1279 / #1282 (canaries, Codex arm), GH-1258 / #1268 (idea skill)
  - GH-722 / #1305 (sibling scan), GH-1235 / #1253 (Jog land message), GH-1273, GH-1280, GH-1250 (reconcile drift)
goal: >
  Land the eight minor fixes from the #1308 review, each with its own red control. The Stage B
  canary init then succeeds again, and delivered issues stay held however many PRs have merged.
---

# GH-1308: post-merge QA fixes

The full review, with a root cause and remediation for each finding, is in
[#1308](https://github.com/HiQS-Labs/XYZ-forge/issues/1308). This doc tracks the fix PR only.

## Ratings

`rated 60/55/50/75`.

- **Priority 60:** finding 1 blocks the documented GH-1279 Stage B init today and silently drops delivered-holds as merges accumulate.
- **Severity 55:** finding 1 can propose already-delivered work as ready. Finding 2 removes the Codex call cap at default settings.
- **Appeal 50:** neutral.
- **Effort 75:** cheap. The fixes are small and local.

## Plan

This counts as a simple change: eight independent fixes, each obvious, local and reversible, and each named with its exact fix in #1308. No design decision is open, because items 9–12, which do need one, are excluded. Plan QA is skipped for that reason; final Codex QA still applies.

Each fix below is verified as listed.

1. **`harness.py` `init_from_prs`.** Add a `gh_json_all` helper with a 10000 limit that refuses a possibly truncated snapshot. Use it for the issue-state list and the merged-PR list.
   - Verify: the Stage B canary init passes.
   - Red control: the pre-fix code fails on `canary-stale-05`.
2. **`harness.py` init validation.** `--adapter codex` requires `--max-call-cost > 0`.
   - Verify: init with defaults is refused, and init with `0.01` is accepted.
3. **`harness.py` `tick`.** Re-read the tick's status after `_reconcile`.
   - Verify: a crash-act tick re-run returns `uncertain`; the pre-fix code returns `started`.
4. **`skills/1-hourly/idea/SKILL.md`.** Prefix the tool paths with `"$HQ_ROOT"/`, and stop on an empty `TARGET`.
5. **`scan_clones.py` `sibling_root`.** Refuse any parent that equals, or is an ancestor of, a NEVER_DELETE root.
   - Verify with a probe, and with `gh534` and `gh436`.
6. **`merge_cleanup.py`.** Correct the Jog-failure message.
7. **Governance.** Promote the #1250, #1273 and #1280 docs, and complete the #1273 and #1280 rows through `releases_app.py`.
   - Verify: `check` is clean and PDDA `issue-doc-sync` no longer warns on them.
8. **Gate.** Run the classified route on the final commit in a disposable clone, then a Codex final QA through `relay-xyz`.

Rollback: revert the PR. Every change is local.

## Status

| What was just completed | What's next |
|---|---|
| Fixes 1–7 (`324bd483`) and the #1250 bundle promotion (`23f8f2ac`) are done, with retained checks passing (`checks-run.txt`). Codex final QA approved in round 2 (`relay-system/2026-11-01/gh1308-final-qa.md`). The full gate result on the final commit is in `TESTS-RESULTS/2026-11-01+GH-1308/gate.txt`. | Ready PR against development; merge only on Noel's go. Items 9–13 of #1308 await Noel's decisions. |
