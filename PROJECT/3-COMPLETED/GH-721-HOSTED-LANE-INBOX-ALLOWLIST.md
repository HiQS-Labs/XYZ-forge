---
title: "GH-721: wave-reconcile.yml publish allowlist never admits 1-INBOX, so every hosted run since GH-698 item 2 refuses its own doc moves"
status: Complete
created: 2026-09-20
updated: 2026-09-21
owner: Claude Code (merge-cleanup → workhorse)
gh_issue: 721
source: https://github.com/HiQS-Labs/XYZ-forge/issues/721
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
goal: >
  Let the hosted reconcile lane publish the 1-INBOX deletion side of a closed-issue capture
  promotion, and pin the guard to RECONCILE_FOLDERS so the writer and the guard cannot drift apart again.
---

# GH-721 — hosted lane publish allowlist admits `1-INBOX`

Issue: [GH-721](https://github.com/HiQS-Labs/XYZ-forge/issues/721). Found by `/merge-cleanup` on
2026-09-20 while landing #719: the hosted run for #714 and the scheduled catch-up both failed at
the publish guard after ~70 min of work.

## Status

| What was just completed | What's next |
|---|---|
| Root cause pinned from runs 35530081997 and 35537102291; one-token allowlist fix in `.github/workflows/wave-reconcile.yml`; `test/gh421-auto-wave-reconcile.sh::test_publish_allowlist_and_plan_lands` extended (red on the unfixed workflow, green on the fix, non-issue inbox note still refused); evidence in `TESTS-RESULTS/2026-09-20+GH-721/`. | Land via `/merge-cleanup`; the first hosted run after landing must publish the 23 pending `1-INBOX → 3-COMPLETED` promotions and this doc's own promotion. |

## Observed problem

Every hosted `wave-reconcile.yml` run ends with
`Refusing undeclared reconciliation artifacts: ['PROJECT/1-INBOX/GH-103-…', … 23 paths …]`.
Nothing has been published by the hosted lane since #705 landed on 2026-09-18.

## Root cause

GH-698 item 2 (#705) set `RECONCILE_FOLDERS = ("2-WORKING", "1-INBOX")` in
`utils/py/wave_reconcile.py`, so `validate_and_update_doc` now promotes closed-issue captures out
of `1-INBOX` (write `3-COMPLETED/…`, `os.unlink` the source). The publish step diffs with
`--no-renames` so both sides of the move are listed, and its doc allowlist
(`PROJECT/(?:2-WORKING|3-COMPLETED|4-MISC)/…`, last touched 2026-09-09 in #495) rejects the
`1-INBOX` deletion. Writer and guard were widened nine days apart.

## Smallest affected surface

- `.github/workflows/wave-reconcile.yml` — add `1-INBOX` to the alternation; the existing
  `(?:GH-)?[0-9]+-` prefix keeps non-issue inbox notes refused.
- `test/gh421-auto-wave-reconcile.sh` — the existing `test_publish_allowlist_and_plan_lands`
  case gains the `1-INBOX` deletion side of a move (positive) and `PROJECT/1-INBOX/scratch-note.md`
  (still refused).

No reconciler, ledger, or report-step change.

## Acceptance checks

- [x] New test case is red against the `origin/development` workflow with exactly the production
  message (`red-unfixed-workflow.log`) and green with the fix (`gh421-green.log`, 31/31).
- [x] Existing negative cases (`utils/py/unexpected.py`, arbitrary `TESTS-RESULTS/…`, malformed
  wave SHAs) and the new non-issue inbox note stay refused.
- [ ] First hosted run after landing publishes instead of refusing (verified at closeout).

## Merge evidence

- Fixture runs and the full gate: `TESTS-RESULTS/2026-09-20+GH-721/` (`provenance.jsonl`).

## Lessons Learned (For Future Agents)

- A hosted publish guard is a second copy of the writer's folder list. When a reconciler grows a
  folder (GH-698 item 2), grep `.github/workflows/` for the previous list on the same PR; the
  guard now carries a comment naming `RECONCILE_FOLDERS` so the next widening finds it.
- The failure is expensive to notice: the run does all its `--qualify` work first and refuses at
  the very end, and `hosted_lane_report.py` posts to the alert issue rather than the PR. When
  `/merge-cleanup` reports a landed PR whose hosted run "completed unsuccessfully", read the last
  `Refusing` line before falling back to the local writer — the fallback hides the class.
