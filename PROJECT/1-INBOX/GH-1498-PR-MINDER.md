---
gh_issue: 1498
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1498
title: "pr-minder: manually invoked PR remediation pass with an age-based stale ladder"
status: Active — Plan QA
created: 2026-11-16
updated: 2026-11-16
owner: start-task lane
goal: A manually invoked /pr-minder skill that moves each eligible open PR in the current repo one step toward landing or a clean exit, with remediation scaled to real author-activity age.
doc_type: enhancement
effort: 3
complexity: 3
risk: 2
phases: 1
related:
  - GH-1184 (daily-planner Stalled & stale report; shares thresholds and activity clock)
  - GH-571 (merge queue research; deferred phase 3)
  - GH-1383 (merge-sequence umbrella)
  - GH-1248 (outer-loop design rules borrowed; no code dependency)
context_tags: [pr-minder, skills, merge-cleanup, weekly-planner, stale-prs]
---

# GH-1498 — pr-minder

## Status
| What was just completed | What's next |
|---|---|
| Clone `XYZ-forge-gh1498-pr-minder-2026-11-16` off `origin/development@f346d8908`; recon; plan drafted; rated | Codex/agy relay plan QA |

The issue body is the specification. This doc records only the decisions recon forced and the execution plan.

## Recon findings that change the issue's sketch

Base `f346d8908`.

1. **The activity history can't ride on the bulk PR fetch.** Adding `commits` to `gh pr list --limit 300` fails: `GraphQL: ... requesting up to 1,000,000 possible nodes which exceeds the maximum limit of 500,000` (observed 2026-11-16). So `get_open_prs` (`planner_core.py:326`) stays unchanged. A new paginated GraphQL reader `fetch_pr_activity` fetches 50 PRs per page with `commits(last:10)`, `comments(last:20)`, `reviews(last:5)` and `createdAt`, about 1.8k nodes per page.
2. **pr-minder's own branch-sync commits are identified by message, not by receipts.** The issue's sketch identified pr-minder commits through local receipt SHAs. Receipts are per-device, and `/daily-planner` can't see them, so its age would stay wrong on any other Mac. GitHub's update-branch commit has a fixed headline: `Merge branch '<base>' into <head>`. The clock ignores every commit with that headline for the PR's own base and head, whoever clicked. Syncing a branch with its base isn't author progress, so this rule is correct for humans too, and it works on every device. Receipts stay as the audit log only.
3. **One home for the clock.** `author_activity(pr, activity)` lives in `planner_core.py` beside `_age_days` (`:1229`). pr-minder already imports `planner_core` for holds, so this adds no new module.
4. **`hold_label` and `refresh_pr_with_retry` import cleanly.** `merge_cleanup.py` imports its sibling modules (`scan_clones`, `toposort_prs`, `attempt_record`; `:27–54`), so pr-minder puts the merge-cleanup `scripts/` dir on `sys.path` before importing. Bundle resolution follows the daily-planner contract (`skills/2-daily/daily-planner/SKILL.md:14`): `PLANNER_ENGINE` / `MERGE_CLEANUP_DRIVER` env overrides, then repo layout (`skills/3-weekly/...`, `skills/2-daily/...`), then a flat installed layout (`../weekly-planner/scripts`).
5. **The planner's `/daily-planner` path** calls `collect_stalled_stale(prs, ...)` at `:1726` after `get_open_prs` at `:1869`. Adoption means: fetch activity once in the stalled path, pass it in, use it for PR age and the displayed date (`:1514–1516`), and rewrite `AGE_DISCLOSURE` (`:1214`). An activity-fetch failure becomes a coverage gap that falls back to `updatedAt`, matching the existing fail-open contract at `:1871–1876`. Issue rows keep `updatedAt`, and the report says so.

## Preflight bet check

- **Outcome sought:** fewer PRs reach landing in a conflicted or abandoned state, and the operator sees which stale PRs need a keep-or-retire call.
- **Smallest viable bet:** one script plus a SKILL.md and one shared clock helper. Writes are limited to `update-branch`, two owned labels and one owned comment. Not built: daemon, merge queue, closing, conflict resolution, Jog dispatch, caps, risk tiers, flaky reruns.
- **Alternative rejected:** extend `/daily-planner` to act. Rejected because it is a read-only report by design (#1184 out-of-scope list), and adding writes there would mix reporting and acting.
- **Rollback:** plan mode is the default. Deleting `skills/2-daily/pr-minder/` removes the feature. The planner change reverts as one commit. PR-side writes are owned labels and comment, plus merge commits that squash away.

## Plan

Smallest affected surface: new `skills/2-daily/pr-minder/{SKILL.md,scripts/pr_minder.py}`, and `planner_core.py` (one reader, one helper, the stalled-path wiring, the disclosure text).

1. **`planner_core.py`: clock.**
   - Add `fetch_pr_activity(repo_root, gh_repo) -> dict[int, dict]` (paginated `gh api graphql`; raises on failure).
   - Add `author_activity(pr, act) -> (datetime | None, complete: bool)`: the latest of non-sync commits, review submissions, and comments without the `<!-- pr-minder` marker. Falls back to `createdAt`. `complete=False` when all 10 fetched commits are sync merges, or 20 comments are all marker comments.
   - Wire it into the stalled path and rewrite `AGE_DISCLOSURE`.
   - *Verify:* `python3 planner_core.py --mode stalled` on the primary repo runs, and every PR row shows an author-activity date at or before its `updatedAt`.
2. **`pr_minder.py`: plan mode + `explain`.**
   - Resolve bundles. Fetch `get_open_prs`, `detect_merge_sequence`, `fetch_pr_activity`, plus one extra `gh pr list --json number,mergeStateStatus,isCrossRepository,maintainerCanModify,headRefOid,createdAt`.
   - Holds: engine holds ∪ `HOLD_LABELS` ∪ `OWNER_HOLD_RE` ∪ `hold_label`.
   - Stack: predicate `baseRefName == other.headRefName`, transitive with a cycle guard. A held ancestor makes the child report-only. Otherwise the child takes `max(own rung, nearest non-held ancestor rung)`.
   - Drift: `gh api repos/{o}/{r}/compare/{base}...{headSha}` → `behind_by`.
   - Conflict files: `git fetch origin pull/N/head` then `git merge-tree --write-tree --name-only origin/<base> FETCH_HEAD` in the current checkout. This is object-only, with no working tree change. On failure, show "unknown".
   - Rung, precedence and bundle selection exactly as the issue's ladder. Print the table.
   - *Verify:* run on the primary repo with plan mode; check that holds such as #1024 appear as held.
3. **`--apply`.**
   - Pre-write `refresh_pr_with_retry`; abort if state, labels, head SHA or base changed.
   - Writes: `gh pr update-branch`, then a head SHA check. `gh label create --force` for the two owned labels on first use. `gh pr edit --add-label/--remove-label`. Owned comment create, or `gh api -X PATCH issues/comments/{id}`. Writes are never retried.
   - Receipts: `intent`/`result` JSONL under `~/.local/state/pr-minder/<owner>/<repo>/actions.jsonl` (overridable by `PR_MINDER_STATE`). The per-episode `update-branch` cap counts `result: ok` update-branch receipts for this PR since the episode start, which is the author-activity time.
   - The kill switch is a `paused` file in the state dir.
4. **SKILL.md**: one pass, current repo only, plan by default, the ladder, the deferred list, bundle resolution.
5. **CHANGELOG.md** entry.

Explicit test non-scope (GH-831): no new test files and no registry entries. Verification is a recorded manual check under `TESTS-RESULTS/2026-11-16+GH-1498/`:
- a fake `gh` on `PATH` that serves canned JSON for one PR per rung × {clean-behind, DIRTY, failing}, plus held, stacked-under-held, unknown and race cases, and logs every write verb;
- the red controls: plan mode logs zero writes, while `--apply` against the same shim logs writes (proves the shim can fail); a head-SHA race aborts the write;
- a second `--apply` run logs zero writes (idempotency);
- a real read-only plan-mode run on this repo, which is the smoke test's main path.

No `--apply` runs against real PRs in this task. That would be an outward write on other people's PRs and needs the operator's explicit go.

**Gates.** `utils/ci-route.sh` decides the route. A new `skills/` script plus `planner_core.py` means the full route: `ci-local.sh` once, on the final commit, in a disposable `-gate` clone. Also run the publisher suites `test/gh620*` and `test/gh589*`, because a folder is added under `skills/`.

**Dependencies.** None open. **Risks.**
- The GraphQL page size could still hit node limits on a repo with huge PRs; the fix is page size 50 with a fallback to 20 on a node-limit error.
- A `gh` field-name drift fails the run closed.

## Acceptance map (from the issue)

Each issue checkbox maps to plan step 1–3, with evidence in the manual-check receipt. The "first error line" in failing-check comments is replaced by the failing check name plus its details URL from `statusCheckRollup`. Disposition: Ponytail. Fetching job logs costs a large download per PR, and the link is one click away.

## RELEASES rating (2026-11-16)

`rated 55/40/50/45`.
- **pri 55:** operator-requested and next in line. It unblocks the landing cost seen in #1383/#1475.
- **sev 40:** no crash or data loss. 9 of 12 open PRs are conflicting and landing repair dominates batch cost, so this is work-slowing friction.
- **appeal 50:** neutral; no operator score given.
- **effort 45:** about 1–2 days for one script, one helper and a manual check.

Recurrence: conflict-at-landing churn was cited across #1374/#1375/#1380 and #1475. There is no clean incident count, so the trend is unknown.
