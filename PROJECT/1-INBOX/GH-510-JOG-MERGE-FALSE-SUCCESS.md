---
title: "GH-510: jog's operator-confirmed merge path ignores gh pr merge failure and records the task completed"
status: Parked
created: 2026-09-08
updated: 2026-09-08
owner: unassigned
goal: make handle_landing_boundary park on a failed or skipped merge instead of returning completed, at both the operator-confirmed path and the no-PR-found fall-through
gh_issue: 510
source: https://github.com/HiQS-Labs/XYZ-forge/issues/510
doc_type: defect
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/505
  - https://github.com/HiQS-Labs/XYZ-forge/issues/509
context_tags: [jog, merge-gate, false-success, queue-state]
non_goals:
  - Refactoring the two merge blocks into one helper (optional, not required by the fix)
  - Any part of the #505 / #509 reviewer-integrity design
  - Changing what jog does with a parked task after it halts
effort: 8
complexity: 2
risk: 2
---

# GH-510 — jog reports a failed merge as a completed task

## Status

| What was just completed | What's next |
|---|---|
| Issue #510 filed; defect verified at `7464fbbb` against all three merge call sites in `jog_run.py` | Park + rate, then fix `:1467` to match `:1432` and make the no-PR case park |

## Why

`handle_landing_boundary()` is the only place jog decides whether a task landed.
Its return value drives both the recorded queue status and whether the queue keeps
going (`jog_run.py:1679-1686`). One of its three merge paths does not look at
whether the merge worked.

`gh pr merge` refuses for ordinary reasons — conflict, failing required check,
branch protection, a closed PR, an expired token. On the operator-confirmed path
every one of those is recorded as `completed`, `tasks_processed` increments, and
jog advances to the next task on a `development` that never received the change.

## Verified findings (at `7464fbbb`)

| # | Finding | Evidence | Sev |
|---|---|---|---|
| 1 | Operator-confirmed merge result is discarded; `completed` returned unconditionally | `jog_run.py:1467` — bare `subprocess.run`, no `capture_output`, no `returncode` test, then `return True, "completed", None` at `:1471` | High |
| 2 | Two sibling call sites in the same file do check | `jog_run.py:1432-1435` (auto-merge, parks with stderr) and `:430-435` (marathon receipt, parks with stderr). The correct shape already exists twice. | — |
| 3 | No-PR-found falls through to `completed` on both paths | `if pr_num and pr_num.isdigit():` guards the merge at `:1426` and `:1459`; both fall through to `return True, "completed", None`. `pr_view.returncode` is never checked, so a failing `gh` is indistinguishable from "no PR exists". | High |

## Fix

1. `:1467` — capture the result; on non-zero return `False, "parked", f"merge failed: {stderr}"`, matching `:1432-1435`.
2. Both paths — treat "no PR found" as a park, not a completion; check `pr_view.returncode` so a `gh` failure is not read as an absent PR.

Optional and out of scope: collapse the two near-identical blocks into one helper.

## Acceptance check

Fixture stubs `gh` to exit non-zero on `pr merge`; asserts
`handle_landing_boundary(..., auto_merge=False)` returns `(False, "parked", ...)`.
**Must go red against current `development`** — verify that before landing the fix,
or the test proves nothing. Control: stubbed `gh` exiting 0 still returns
`(True, "completed", None)`. Second case: `gh pr list` returning empty must park.
Tests belong beside `test/gh376-relay-drive-lock-parity.sh`.

## Rating rationale — 2026-09-08

`rated 70/70/50/90` (pri/sev/appeal/effort; effort scores cheapness).

- **Severity 70.** Wrong recorded state at the one boundary where jog decides a task
  landed, plus a queue that keeps running against a base that never got the change.
  Consequence is corrupted governance state and dependent work built on a false
  premise, recoverable by re-reading GitHub. Below the 80+ band because nothing is
  lost or corrupted on disk and the merge itself simply did not happen — the truth
  is still available from `gh`. Above the middle because the failure is silent at
  exactly the point a human stops watching.
- **Priority 70.** Severity-led. Raised slightly by how cheap the fix is and by the
  correct pattern already existing twice in the same file. Not higher because the
  affected path needs an interactive tty and no `--auto-merge`, so the automated
  lanes are unaffected.
- **Appeal 50.** Neutral — operator supplied no desirability preference.
- **Effort 90.** Three or four lines mirroring an adjacent block, plus one fixture
  test. No design decision, no shared-contract change.

**Recurrence.** Same class = a harness path reporting success it did not verify.
Window 2026-08-25 → 2026-09-08: #505 (relay terminal status trusted without checking
who wrote it) and this issue. Two incidents, distinct mechanisms, same failure shape.
Preceding window not systematically counted — trend **unknown**, not zero. Counts
issues in this repo only.
