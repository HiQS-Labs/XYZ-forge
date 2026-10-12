---
gh_issue: 1025
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1025
title: "start-task prior-art scan misses merged PRs, issues and sibling repos, and fails silently in cloud sessions"
status: Complete
created: 2026-10-11
updated: 2026-10-12
owner: Claude
goal: "/start-task finds an existing fix (recently merged PR or completed issue) before planning new work, in local and cloud sessions"
branch: fix/XYZ-forge-gh1025-prior-art-merged-issues-2026-10-11
doc_type: bugfix
effort: 1
complexity: 2
risk: 1
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Scanner extended (merged PRs, issues, `--repo`, REST fallback, `existing_fix_candidates`); `start-task` Step 1 stops on a candidate; `gh777-start-task-prior-art` green with stub-gh list and REST paths (red at base). | PR review/merge. |

## Ask

`/start-task` should check whether a recent PR or an issue already fixes the ask before planning.
`utils/py/prior_art_recon.py` only listed open PRs in the current repo, never searched issues,
and returned nothing in cloud sessions, where `gh pr list` (GraphQL) is refused.

## Plan

1. `prior_art_recon.py`: search open PRs, PRs merged in the last `--since-days` (default 30) and
   issues in any state via `gh pr|issue list --search`, which matches titles and bodies. Add a
   repeatable `--repo OWNER/NAME`. On a `gh ... list` failure, fall back to repo-scoped REST
   (`gh api repos/{owner}/{repo}/pulls|issues`, 100 most recently updated) and filter locally.
   Report merged PRs and issues closed as completed as `existing_fix_candidates`.
2. `start-task` Step 1: stop and confirm with the user when a candidate appears; search by hand
   when the scan reports a GitHub error. Step 4 wording matches the new coverage.
3. Extend `test/gh777-start-task-prior-art.sh` with a stub `gh` (list and REST modes). No new suite.

## Acceptance map

| Check | Evidence |
|---|---|
| Merged PRs and completed issues surface as fix candidates; open issues do not | stub-gh assertions, both modes |
| Sibling repo scanned via `--repo` | stub call log |
| REST fallback works when `gh ... list` fails | stub `rest` mode; live cloud run returned PR #1018 for `--query slug` |
| Old script fails the extended suite | red control: `unrecognized arguments: --repo` |
