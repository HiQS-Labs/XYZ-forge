# RELAY · GH-605 Kanban Terminal Retention QA (Claude Opus)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded on 2026-09-14.
-->

NEXT: claude-a
STATUS: Approved
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     Pre-existing defects in a file you are touching are IN SCOPE; if you find none, say so explicitly.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no` line.**
     Any `[Pass]` or "verified"/"confirmed" finding MUST carry a quoted span or a `file:line` citation.
     Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh605-kanban-terminal-retention-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268).

## Setup
- Artifacts under review:
  - **utils/py/board_sync.py** (`plan_selection_policy` lines ~280–330)
  - **test/test_gh605_board_policy.py**
- Reviewer: agy (Claude Opus 4.6 Thinking)   ·   Producer: claude-a
- Started: 2026-09-14
- Definition of Done: Thoroughly QA the fix on PR #607 (commit ccc8eb34) that retains completed tasks and merged PRs in Done instead of demoting to Backlog. Answer:
  1. QA1: Does `plan_selection_policy` in `utils/py/board_sync.py` properly retain completed issues (`reason == "COMPLETED"`) and merged PRs (`state in ("CLOSED", "MERGED")` with `merged_at`) on the board in `policy["done"]` rather than demoting them to `policy["backlog"]` when their completion/merge date exceeds `done_lookback_days`?
  2. QA2: Are closed unmerged PRs and issues closed as `NOT_PLANNED` that are already on the board correctly routed to `Backlog` (or preserved)?
  3. QA3: Does the change preserve the "no-card-deletion" invariant and avoid creating duplicate cards or making unauthorized destructive mutations on the GitHub Projects board?
  4. QA4: Do the new unit test cases in `test/test_gh605_board_policy.py` (`test_existing_unset_terminal_card_moves_but_absent_one_is_not_added`, `test_completed_issue_and_merged_pr_older_than_lookback_retained_in_done`) meaningfully exercise these paths and protect against regression?
  5. QA5: Were touched files swept for pre-existing defects or unintended side effects?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### R1 — agy (Reviewer) 2026-09-14

**QA1 — Completed issues retained in Done:** `[Pass]`
Commit ccc8eb34 adds `board_sync.py:320–321`:
```python
elif reason == "COMPLETED" and ident in board_by:
    targets[ident], reasons[ident] = policy["done"], "completed issue retained in Done"
```
This branch fires *after* the `done_lookback_days` window check (L318) and *only* when the
issue already has a board card (`ident in board_by`), so a completed issue older than the
lookback window is retained in Done rather than falling through to the Backlog branch.
Citation: [`board_sync.py:318–321`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh605/utils/py/board_sync.py#L318-L321).

**QA1 (merged PRs):** `[Pass]`
The PR branch at L289–290 was changed from `policy["backlog"], "merged outside Done window"` to
`policy["done"], "merged PR retained in Done"`. A merged PR whose `merged_at` exceeds
`done_lookback_days` is now kept in Done when it already has a board card.
Citation: [`board_sync.py:289–290`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh605/utils/py/board_sync.py#L289-L290).

**QA2 — Closed-unmerged PRs and NOT_PLANNED issues route to Backlog:** `[Pass]`
- Closed-unmerged PRs: L295–296 `targets[ident] = policy["backlog"], "closed unmerged PR"` — unchanged, fires only when `ident in board_by`. Citation: [`board_sync.py:295–296`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh605/utils/py/board_sync.py#L295-L296).
- NOT_PLANNED issues: L322–323 now reads `policy["backlog"], "closed not-planned issue"` (renamed from `"terminal outside Done window"`). The new `reason == "COMPLETED"` guard at L320 ensures only COMPLETED issues hit the retain-in-Done path; NOT_PLANNED falls through to L322 which correctly assigns Backlog. Citation: [`board_sync.py:320–323`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh605/utils/py/board_sync.py#L320-L323).

**QA3 — No-card-deletion invariant / no duplicate cards / no unauthorized destructive mutations:** `[Pass]`
- The change introduces zero new calls to `_add_item`, `_clear_status`, or any delete/remove API. The only mutations are `targets[ident] = …` assignments in the pure planner; actual board writes are downstream in `apply_policy_preview` (unchanged by this commit).
- The L367–368 guard `if ident not in board_by and target == policy["backlog"]: continue` is unchanged, preventing Backlog-only additions.
- Both new retention paths (L289–290 for PRs, L320–321 for issues) guard on `ident in board_by`, so they never create new cards — they only change the target column for existing ones.
- No card is ever deleted anywhere in `plan_selection_policy`. Citation: [`board_sync.py:364–371`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh605/utils/py/board_sync.py#L364-L371).

**QA4 — Test coverage:** `[Pass]`
- `test_existing_unset_terminal_card_moves_but_absent_one_is_not_added` (L162–170): The test was updated to assert `"Done"` instead of `"Backlog"` for a completed issue past the lookback window that already has a board card (present case), and confirms absent issues produce no changes. Also verifies the reason string `"completed issue retained in Done"`. Citation: [`test_gh605_board_policy.py:162–170`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh605/test/test_gh605_board_policy.py#L162-L170).
- `test_completed_issue_and_merged_pr_older_than_lookback_retained_in_done` (L172–186): New test exercises three items on the board: a COMPLETED issue, a MERGED PR (both older than lookback) → both assert `"Done"`; a NOT_PLANNED issue → asserts `"Backlog"`. This is a meaningful regression test that verifies all three paths in one scenario. Citation: [`test_gh605_board_policy.py:172–186`](file:///Users/noelsaw/Documents/GH%20Repos/XYZ-forge-gh605/test/test_gh605_board_policy.py#L172-L186).

**QA5 — Pre-existing defects or unintended side effects in touched files:** `[Pass]`
swept file: yes
Full sweep of `plan_selection_policy` (L220–375) and `test_gh605_board_policy.py` (1030 lines):
- No unreachable branches introduced. The new `elif` at L320 is ordered correctly after the lookback check at L318 and before the existing `elif ident in board_by` at L322; the condition chain is exhaustive and mutually exclusive for COMPLETED vs NOT_PLANNED.
- No type-safety issues: `ident in board_by` is a dict membership test on a tuple key, consistent with the rest of the function.
- Reason string rename from `"terminal outside Done window"` to `"closed not-planned issue"` at L323 is more precise and has no downstream consumers that depend on the old string (reason strings are informational in decisions/changes dicts, not used as programmatic keys).
- No pre-existing defects found in the touched regions.

**VERDICT:** PASS
**Basis:** All five Definition of Done criteria are satisfied. The fix correctly retains completed issues and merged PRs in Done when they already have board cards, while preserving Backlog routing for closed-unmerged PRs and NOT_PLANNED issues. The no-card-deletion invariant is preserved. Both new and updated tests meaningfully exercise the changed code paths. No pre-existing defects found in the touched files.

<!-- Reviewer turn appends below -->
