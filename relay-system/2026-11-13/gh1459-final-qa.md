# RELAY: GH-1459 — Daily Work Ledger GH Issue & Checkout Calibration Final QA

ARTIFACT: skills/3-weekly/weekly-planner/scripts/planner_core.py
PRODUCER: claude
REVIEWER: codex
ROUND_CAP: 3
STATUS: Reviewing
NEXT: codex

---

## Log

## Round 1 — Producer (claude)

### Summary
Implemented and verified issue #1459 (`daily-planner: shared Daily Work Ledger GH issue, carryover, checkout calibration, and vendored repo support`) across `skills/3-weekly/weekly-planner/scripts/planner_core.py`, `skills/2-daily/daily-planner/SKILL.md`, `skills/3-weekly/weekly-planner/SKILL.md`, `PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md`, and `TESTS-RESULTS/2026-11-13+GH-1459/`.

Before answering the questions below, state in 2-3 sentences of your own words what this document/code does and what its riskiest assumption is. A response that skips this paraphrase or copies sentences verbatim from the artifact is invalid.

### Implementation & Verification Summary
1. **Shared Engine (`skills/3-weekly/weekly-planner/scripts/planner_core.py`, commit `ffdb82de4`):**
   - Added `--mode ledger`, `--repo-mode {auto,forge,vendored,gh-only}`, `--publish-ledger`, `--ledger-issue <n>`, `--ledger-tz <tz>`, and `--allow-delegate-comment` (plus `from __future__ import annotations` for Python 3.9+ compatibility).
   - Extended `scan_local_checkout` to inspect linked git worktrees via `git worktree list --porcelain` (`worktrees`, `worktree_branches`) and read-only `.tick` claims via canonical `<tick-bin> claims --json` (`tick_claims`, `tick_claimed_issues`).
   - Added `find_or_create_daily_ledger_issue` using `/repos/{slug}/issues?state=all&per_page=100` with unconditional pagination when a page returns 100 rows, exact first-line marker `<!-- xyz-daily-ledger: repo=<owner/repo> date=<YYYY-MM-DD> tz=<TZ> v=1 -->` + title + `daily-ledger` label + trusted-author verification, lowest-`number` tie-break (`duplicate_issues`), and `previous_issue` carry-over resolution across up to 14 prior calendar days.
   - Added `parse_ledger_comment` (enforcing first-line `<!-- xyz-daily-ledger-claim: ... -->` marker and comment-author match unless `--allow-delegate-comment` + trusted bot) and `sync_daily_ledger_comment` (preserving the original `started:` timestamp on same-day `PATCH` and verifying existing comment authorship before `PATCH`).
   - Added `fetch_pr_review_threads` via bounded `gh api graphql` (`reviewThreads(first:100)`) and `run_daily_ledger` / `format_daily_ledger_markdown` producing the 4-panel Calibration Digest (`DAILY-LEDGER.md` + `daily-ledger.json`).
2. **Skill Documentation (`skills/2-daily/daily-planner/SKILL.md`, `skills/3-weekly/weekly-planner/SKILL.md`):**
   - Documented `--mode ledger`, `--repo-mode`, `--publish-ledger`, the 4-step `/recon` + `/debug-mantra` grounding ladder, and separation from Rebalance `/daily`.
3. **Verification (`TESTS-RESULTS/2026-11-13+GH-1459/`, commit `462022e87`):**
   - Executed 31 offline negative & positive controls (`smoke-results.txt`: `31 PASS / 0 FAIL`) plus a live read-only scan against `HiQS-Labs/XYZ-forge` (`live-run-DAILY-LEDGER.md`, `live-run-daily-ledger.json`), and recorded `provenance.jsonl` + `SUMMARY.md`.
   - Verified `check_inventory_ratchet.py --check` (`clean (matches baseline, 0 new scripts/connects)`), `pdda.sh run` (`no errors`), and `pytest test/test_python_layer.py` (`21 passed`).

### Questions for Reviewer (codex)
1. **Diff & Contract Alignment:** Does the implementation in `skills/3-weekly/weekly-planner/scripts/planner_core.py`, `skills/2-daily/daily-planner/SKILL.md`, and `skills/3-weekly/weekly-planner/SKILL.md` faithfully implement all requirements and Round 1–3 Plan QA fixes in `PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md` without regressions to `--mode weekly` or `--mode daily`?
2. **Security, Spoofing & Fail-Closed Degrade:** Are there any remaining defects in issue/comment marker parsing, authorship verification, pagination, GraphQL `reviewThreads` error handling, or read-only default behavior?
3. **Verification Sufficiency:** Are the recorded outputs and provenance in `TESTS-RESULTS/2026-11-13+GH-1459/` complete, truthful, and sufficient to close all 5 Acceptance items, or are any `[P0]`/`[P1]` changes requested before opening the PR?
