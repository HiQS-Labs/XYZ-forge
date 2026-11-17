---
gh_issue: 1498
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1498
title: "pr-minder: manually invoked PR remediation pass with an age-based stale ladder"
status: Active — Final QA
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
| Plan QA approved (Codex r3); implemented; manual check 13/13 with bad candidates rejected; smoke green | Full gate in a disposable clone, then final relay QA |

The issue body is the specification. This doc records only the decisions recon forced and the execution plan.

## Recon findings that change the issue's sketch

Base `f346d8908`.

1. **The activity history can't ride on the bulk PR fetch.** Adding `commits` to `gh pr list --limit 300` fails: `GraphQL: ... requesting up to 1,000,000 possible nodes which exceeds the maximum limit of 500,000` (observed 2026-11-16; the command and output will be retained in the manual-check receipt). So `get_open_prs` (`planner_core.py:326`) stays unchanged. A new paginated GraphQL reader, `fetch_pr_activity`, fetches 50 PRs per page with these connections:
   - `commits(last:10){commit{oid committedDate messageHeadline committer{email} parents(first:2){totalCount}}}`
   - `comments(last:20){createdAt body}`
   - `reviews(last:10){submittedAt}`
   - `reviewThreads(last:20){comments(last:1){createdAt}}`
   - `createdAt`, plus `pageInfo.hasPreviousPage` on each history connection.
2. **Maintenance sync commits are identified by a conservative, device-independent predicate.** It replaces the issue's receipt-SHA idea; Codex plan QA F1. A commit is maintenance (not author activity) only when **all** of these hold:
   - it has exactly 2 parents;
   - its headline matches GitHub's server-merge pattern `^Merge branch '[^']+' into .+$`. This is name-independent, so a later branch rename or retarget can't flip a historical sync into "author activity" (Codex plan QA r2);
   - its committer email is `noreply@github.com` (a server-side merge).

   Everything else counts as author activity. That includes a single-parent commit with that headline, and any local merge.
   - *Why not receipts:* they are per-device, so `/daily-planner` on another Mac would still mis-age the PR.
   - *Accepted boundary (an intentional change from issue §3, which excluded only pr-minder's own commits):* a human clicking GitHub's "Update branch" is also treated as maintenance, because syncing with base isn't author progress. A conflict resolved in GitHub's web conflict editor that keeps the default message also matches the predicate. Such a PR then looks staler, so it may escalate a rung early. The only writes involved are labels and a comment; there is no close. The comment says "web-editor conflict resolutions with the default message are not counted as activity".
   - A commit whose OID appears in a local `ok` update-branch receipt is also maintenance (a union with the predicate, never a replacement). Receipts remain the audit log and feed the per-episode `update-branch` cap. On another device without those receipts the name-independent predicate still holds.
   - **Completeness:** each connection gives "latest qualifying item" when it contains at least one qualifying item, or when `hasPreviousPage` is false. Otherwise that connection is incomplete. `reviewThreads` is ordered by thread creation, not by latest reply, so it counts as complete only when `hasPreviousPage` is false. Reviews (each reply submits a review) carry recency. If any connection is incomplete, or the GraphQL call fails for that PR, the result is `unknown`. In pr-minder, `unknown` means no writes for that PR. In the planner, that PR falls back to `updatedAt` and is listed by number in the disclosure.
3. **One home for the clock.** `author_activity(pr, activity)` lives in `planner_core.py` beside `_age_days` (`:1229`). pr-minder already imports `planner_core` for holds, so this adds no new module.
4. **`hold_label` and `refresh_pr_with_retry` import cleanly.** `merge_cleanup.py` imports its sibling modules (`scan_clones`, `toposort_prs`, `attempt_record`; `:27–54`), so pr-minder puts the merge-cleanup `scripts/` dir on `sys.path` before importing. Bundle resolution follows the daily-planner contract (`skills/2-daily/daily-planner/SKILL.md:14`): `PLANNER_ENGINE` / `MERGE_CLEANUP_DRIVER` env overrides, then repo layout (`skills/3-weekly/...`, `skills/2-daily/...`), then a flat installed layout (`../weekly-planner/scripts`).
5. **The planner's `/daily-planner` path** calls `collect_stalled_stale(prs, ...)` at `:1726` after `get_open_prs` at `:1869`. Adoption means: fetch activity once in the stalled path, pass it in, use it for PR age and the displayed date (`:1514–1516`), and rewrite `AGE_DISCLOSURE` (`:1214`). An activity-fetch failure becomes a coverage gap that falls back to `updatedAt`, matching the existing fail-open contract at `:1871–1876`. Issue rows keep `updatedAt`, and the report says so.

## Preflight bet check

- **Outcome sought:** fewer PRs reach landing in a conflicted or abandoned state, and the operator sees which stale PRs need a keep-or-retire call.
- **Smallest viable bet:** one script plus a SKILL.md and one shared clock helper. Writes are limited to `update-branch`, two owned labels and one owned comment. Not built: daemon, merge queue, closing, conflict resolution, Jog dispatch, caps, risk tiers, flaky reruns.
- **Alternative rejected:** extend `/daily-planner` to act. Rejected because it is a read-only report by design (#1184 out-of-scope list), and adding writes there would mix reporting and acting.
- **Rollback:** plan mode is the default. Deleting `skills/2-daily/pr-minder/` removes the feature. The planner change reverts as one commit. PR-side writes are owned labels and comment, plus merge commits that squash away.

## Plan

Smallest affected surface: new `skills/2-daily/pr-minder/{SKILL.md,scripts/pr_minder.py}`, `planner_core.py` (one reader, one helper, the stalled-path wiring, the disclosure text), and `merge_cleanup.py` (`body` added to `refresh_pr`'s field list).

1. **`planner_core.py`: clock.**
   - Add `fetch_pr_activity(repo_root, gh_repo) -> dict[int, dict]` (paginated `gh api graphql`; raises on failure).
   - Add `author_activity(pr, act) -> (datetime | None, complete: bool)`: the latest of non-maintenance commits, review submissions, review-thread comments, and issue comments without the `<!-- pr-minder` marker, under the completeness rule in recon #2. It falls back to `createdAt` only when every connection is complete and empty.
   - Wiring stays local to the stalled path, so `fetch_pr_activity` runs only in `stalled`/`daily` modes. Exceptions are caught inside `run_stalled_scan` and become a coverage gap; they never raise past it.
   - `collect_stalled_stale` gains an optional `activity=None` parameter. Existing callers and fixtures that omit it keep today's `updatedAt` behaviour.
   - Rewrite `AGE_DISCLOSURE` to describe the author clock, and list the PRs that fell back to `updatedAt`.
   - *Verify:* see the manual-check assertions A5/A6 below. These need a strictly older age; equality with `updatedAt` is not enough.
2. **`pr_minder.py`: plan mode + `explain`.**
   - Resolve bundles. Fetch `get_open_prs`, `detect_merge_sequence`, `fetch_pr_activity`, plus one extra `gh pr list --json number,mergeStateStatus,isCrossRepository,maintainerCanModify,headRefOid,createdAt`.
   - Holds: engine holds ∪ `HOLD_LABELS` ∪ `OWNER_HOLD_RE` ∪ `hold_label`.
   - Stack: predicate `baseRefName == other.headRefName`, transitive with a cycle guard. A held ancestor makes the child report-only. Otherwise the child takes `max(own rung, nearest non-held ancestor rung)`.
   - Drift: `gh api repos/{o}/{r}/compare/{base}...{headSha}` → `behind_by`.
   - Conflict files: `git fetch origin pull/N/head` then `git merge-tree --write-tree --name-only origin/<base> FETCH_HEAD` in the current checkout. This is object-only, with no working tree change. On failure, show "unknown".
   - Rung, precedence and bundle selection exactly as the issue's ladder. Print the table.
   - *Verify:* run on the primary repo with plan mode; check that holds such as #1024 appear as held.
3. **`--apply`.**
   - Before each write, call `refresh_pr_with_retry`. `refresh_pr`'s field list (`merge_cleanup.py:504–505`) gains `body`, a one-token change that existing consumers ignore (Codex F3). Re-evaluate the **full** hold union on the refreshed title, body and labels: `hold_label`, `HOLD_LABELS`, `OWNER_HOLD_RE`, and `detect_merge_sequence([refreshed])` for the engine's title/body phrases. Abort, with an `aborted` receipt, if the PR is now held, or if its state, head SHA or base changed.
   - Writes: `gh pr update-branch`, then a head SHA check. `gh label create --force` for the two owned labels on first use. `gh pr edit --add-label/--remove-label`. Owned comment create, or `gh api -X PATCH issues/comments/{id}`. Writes are never retried.
   - Receipts: `intent`/`result` JSONL under `~/.local/state/pr-minder/<owner>/<repo>/actions.jsonl` (overridable by `PR_MINDER_STATE`). The per-episode `update-branch` cap counts `result: ok` update-branch receipts for this PR since the episode start, which is the author-activity time.
   - The kill switch is a `paused` file in the state dir.
4. **SKILL.md**: one pass, current repo only, plan by default, the ladder, the deferred list, bundle resolution.
5. **CHANGELOG.md** entry.

Explicit test non-scope (GH-831): no new test files and no registry entries. Verification is a recorded manual check under `TESTS-RESULTS/2026-11-16+GH-1498/`. It uses a fake `gh` on `PATH` that serves canned JSON, keeps state across calls (labels and comments it was asked to write are served back on the next call), and logs every write verb. Every assertion below has a pinned expected outcome and a **controlled bad candidate** that must make it fail. The bad candidates are throwaway local edits made during the check; they are recorded and then discarded, never committed.

| # | Issue checkbox | Assertion | Bad candidate that must fail it |
|---|---|---|---|
| A1 | zero writes | plan mode → 0 write verbs logged; the shim exits non-zero on any write | `--apply` against the same shim → write detector fires (proves the detector can fail) |
| A2 | rung matrix | one PR per rung × {clean-behind, DIRTY, failing} plus draft, drift-bump and rung-4 cases → exact action per the ladder table; rung 4 has no writes | thresholds off by one (`>` instead of `>=`) → a boundary case changes action |
| A3 | holds | each of the 4 hold sources plus a child of a held ancestor → 0 writes | drop `hold_label` from the union → its case writes |
| A4 | idempotency | second `--apply` on shim state left by the first → 0 writes | comment lookup ignoring the marker → a second comment is created |
| A5 | shared age, pr-minder | stale PR with recent maintenance commit + marker comment + label (so `updatedAt` = today), author activity 20 days old → pr-minder reports 20d | clock using `updatedAt` → reports 0d |
| A6 | shared age, planner (production path) | the A5 PR through the real `planner_core.py --mode stalled` entry (fake `gh` serving both the bulk list and the history query) → the generated report's row shows the 20-day-old date. A history-query error → the report is still produced and its disclosure lists that PR number as an `updatedAt` fallback | the production call at `:1726` left without the fetch/pass-through → the report shows today's date |
| A7 | cap / escalation | 2 `ok` update-branch receipts in this episode, PR still behind → no third update-branch; at 14 days → rung 3 | cap check removed → third update-branch issued |
| A8 | author reset | new single-parent author commit → rung 0, owned labels removed, foreign `stale` label kept. A maintenance merge → no reset. The same maintenance merge after only `headRefName` changes, and separately after only `baseRefName` changes → still no reset | headline-only predicate → the single-parent "Merge branch…" commit is dropped and nothing resets. A current-name predicate → the rename case resets falsely |
| A9 | race | head SHA changes between measure and write → 0 writes + an `aborted` receipt; body gains `owner decision: hold` → same | pre-write check without `body` → the body-hold case writes |
| A10 | receipts | every write has a paired `intent` + `result`; a shim-forced failure gives `result: failed` | result line skipped on failure → unpaired intent |
| A11 | completeness | `hasPreviousPage` with no qualifying item, or GraphQL error → `unknown`, 0 writes | fallback to `createdAt` → a stale action is taken |
| A12 | failing-check comment | failing check rendered as name + details URL; a missing URL renders "link unavailable" | — (render check) |

Smoke test: a real read-only plan-mode run on this repo (main path), plus a second plan-mode run immediately after (adjacent path: identical output and zero writes).

No `--apply` runs against real PRs in this task. That would be an outward write on other people's PRs and needs the operator's explicit go.

**Gates.** `utils/ci-route.sh` classifies these skill paths as docs (`:63–69`). The full `ci-local.sh` run is **deliberately chosen**, not routed: the change touches `merge_cleanup.py` and planner code that `/daily-planner` consumes, and the issue's acceptance asks for `./validate.sh`. It runs once, on the final commit, in a disposable `-gate` clone. Also run the publisher suites `test/gh620*` and `test/gh589*`, because a folder is added under `skills/`.

**Dependencies.** None open. **Risks.**
- The GraphQL page size could still hit node limits on a repo with huge PRs; the fix is page size 50 with a fallback to 20 on a node-limit error.
- A `gh` field-name drift fails the run closed.

## Acceptance map (from the issue)

Each issue checkbox maps to the assertions A1–A12 above; the gates checkbox maps to the Gates paragraph. **Spec deviation (kept visible):** the "first error line" in failing-check comments is replaced by the failing check name plus its details URL from `statusCheckRollup`. Disposition: Ponytail. Fetching job logs costs a large download per PR, and the link is one click away.

## RELEASES rating (2026-11-16)

`rated 55/40/50/45`.
- **pri 55:** operator-requested and next in line. It unblocks the landing cost seen in #1383/#1475.
- **sev 40:** no crash or data loss. 9 of 12 open PRs are conflicting and landing repair dominates batch cost, so this is work-slowing friction.
- **appeal 50:** neutral; no operator score given.
- **effort 45:** about 1–2 days for one script, one helper and a manual check.

Recurrence: conflict-at-landing churn was cited across #1374/#1375/#1380 and #1475. There is no clean incident count, so the trend is unknown.
