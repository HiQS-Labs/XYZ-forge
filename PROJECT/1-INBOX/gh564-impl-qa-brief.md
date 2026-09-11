# GH-564 — implementation QA brief

Implementation review. The plan passed three rounds of plan QA
(`relay-system/2026-09-10/gh564-plan-qa.md`, 9 blockers, all folded in, escalated at the cap; the
operator chose to build). Review the **code**, not the plan's design choices, unless the code
departs from them.

- Branch `feat/gh564-work-backfill-review-ready`, head `3bd0df6a`, base `59b692b2` (= #559's head;
  this PR stacks on #559). Diff: `git diff 59b692b2..HEAD`. **Read whole files** (GH-268).
- Plan + acceptance map: `PROJECT/2-WORKING/GH-564-WORK-BACKFILL-REVIEW-READY.md` — the check
  table (21a–23) and the "Implementation notes" section, which records where the build departed
  from the plan and why.
- Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/564

## Files

| File | What |
|---|---|
| `utils/py/releases_app.py` | `_AlreadyRecorded`, `_latest_event(only_source/exclude_source)`, `_emit_work_event(unless_latest_in, only_source, exclude_source, terminal)`, `cmd_work_emit` (now a caller), `_backfill_event_for`, `cmd_work_backfill`, `_repo_identity_for_scan`, `_linked_issues`, `_scan_review_ready`, the scan hooked into `cmd_work_reconcile`, `work backfill` subparser |
| `utils/py/work_connectors/github_board.py` | `DEFAULT_STATUS_MAP["completed"]` |
| `test/lib/gh-prlist-wrapper.sh` | new test seam for `gh pr list` |
| `test/gh549-work-events.sh` | legs 21–23 (+46 assertions, 109 total) |

## Definition of Done — answer each explicitly

1. Is every acceptance criterion on #564 satisfied, at `file:line`?
2. Is the transactional idempotence actually atomic? `mutate` runs inside `perform_write` after
   `WriterLock` + `BEGIN IMMEDIATE`; `_AlreadyRecorded` rides the existing abort path. Is there a
   window, and does the abort path really leave nothing on the chain (receipt, generation, journal)?
3. The producer-scoped views (`only_source`/`exclude_source`) plus `terminal`: is the ping-pong
   closed in **both** directions, and can a terminal claim ever be missed or wrongly applied?
4. `--repo` resolution and the fail-soft boundary in `_scan_review_ready` — can anything in that
   function exit `work reconcile` non-zero or skip dispatch?
5. `_backfill_event_for`'s ordered rules against the live distribution (Completed/🆕 ×40,
   Deferred/🚧 ×1, "In progress"/🆕 ×5).
6. Are any of the 46 new assertions vacuous? The plan doc discloses three that were on first
   draft; be hardest on 21a, 21e and 21f.
7. Pre-existing defects in touched files are in scope (GH-268). Say explicitly if none.

## Already disclosed — not new findings

Stacked on #559 (cannot merge first). `_linked_issues` duplicates `merge_cleanup.CLOSES_RE` on
purpose (a ledger verb must not import a skill script). No historical backfill of `review_ready`
for PRs that were open before this landed — `reconcile` picks them up on its first run.
