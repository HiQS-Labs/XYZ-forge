# Smoke (c): a day with no deploy (run 3, on skill commit `540e04421`, two independent executions)

Executors: two fresh sub-agents, each read-only (4 `Read` calls: the skill, `yesterday-silent.md`, `today-nodeploy.md`, `pr-facts.md`; no `ls`, no writes, no `gh`). Whole proposed bodies below, verbatim; nothing published. `pr-facts.md` lists PR #104 as an open "release candidate bundle", so a deploy-shaped PR is present, but no ledger or checklist plans a deploy. Both executions are reported; earlier runs are in git history (`179e96fa0`, `11eca2dd6`; the run-2 body carried a "no deploy run sheet" note that final QA round 2 called a Blocker, and step 5a now says "otherwise add nothing (no section, question or note)").

## Execution 1

````markdown
# Daily Work Ledger — 2026-11-25 (fictional example)

Goal: ship Release X (official count 4 items, progress bar 50%).

## Items

### Reviews and gates first
- [ ] Item 3: add the search filter (PR #103) - carried from 2026-11-24. Live state: head aaa1111, CI green, no conflicts, not draft. Reviewer B's approval is recorded at head aaa1111, which is the current head. Still to do: the merge decision, which this ledger does not make. Deployment: not planned in this ledger.
- [ ] PR #104: release candidate bundle - new today (not in yesterday's ledger, not part of the official count of 4). Live state: head bbb2222, CI green, no conflicts, not draft. Reviewer B's approval is recorded at head bbb2222, which is the current head. Known finding, listed once: "slow query on empty filter", grade Should, accepted by Lead 1 in a PR comment. Owner: not named in the sources, to be assigned.

### Dev C
- [ ] Item 4: write the release notes (Dev C) - carried from 2026-11-24. No new evidence on GitHub.

### Done (verified on the integration branch)
- [x] Item 1: fix the export button (PR #101, Dev A) - merged, on the integration branch. Deployment unverified.
- [x] Item 2: update the help page (PR #102) - merged, on the integration branch. Yesterday this was only "approved by Reviewer B"; it has since merged. Deployment unverified.

### Parked
- None.

### Dropped
- None.

## People's feedback that changes today's work
- PR #104: the "slow query on empty filter" finding above (grade Should, accepted by Lead 1).
- Slack was not checked.

## Completion estimate
Formula: sum of item shares x done fraction.
Change log:
- 2026-11-24: no change.
- 2026-11-25: no change. Items 1 and 2 are now merged (PRs #101, #102), which matches the 2 of 4 already counted. Progress bar stays at 50%. PR #104 is outside the official count, so no share changed.

## SOP
- Reviews before merges. A ledger is a plan, not an approval.
````

Questions raised: none ("Step 5a therefore adds no run sheet, question or note").

## Execution 2

````markdown
# Daily Work Ledger — 2026-11-25 (fictional example)

Goal: ship Release X (official count 4 items, progress bar 50%).

## Items

Evidence checked: merged state, PR reviews and live PR state came from GitHub reads. Slack was not checked. A ledger is a plan, not an approval.

### Reviews first (Reviewer B)
- [ ] Review work on PR #103 (Item 3): a review by Reviewer B is recorded at head aaa1111, which is the current head. Past reviews and current review requests are separate facts. No open review request is listed in the live state read.
- [ ] Review work on PR #104 (new, below): a review by Reviewer B is recorded at head bbb2222, which is the current head. No open review request is listed in the live state read.

### Dev A
- [x] Item 1: fix the export button. PR #101 is on the integration branch (verified merged). Merge only; deployment unverified.

### Dev C
- [ ] Item 4: write the release notes. Carried from yesterday. No new evidence of progress was found.

### Not yet assigned in yesterday's ledger
- [x] Item 2: update the help page. PR #102 is on the integration branch (verified merged since yesterday). Merge only; deployment unverified. Yesterday's note said "approved by Reviewer B". The head that approval was on was not re-checked in this pass.
- [ ] Item 3: add the search filter. Carried from yesterday. PR #103 has head aaa1111, CI green, no conflicts, not draft. Today's work is to bring it to its merge decision. Nothing here is a merge approval.

### New today
- [ ] PR #104, release candidate bundle. Head bbb2222, CI green, no conflicts, not draft. It is outside the official count of 4, and the count is unchanged. Known review finding (listed once): "slow query on empty filter", grade Should, accepted by Lead 1 in a PR comment. Today's work is to decide how it is handled alongside Items 3 and 4.

### Parked
- None.

### Dropped
- None.

## Completion estimate
Formula: sum of item shares x done fraction. Change log: 2026-11-24, no change; 2026-11-25, no change (Items 1 and 2 were already counted done yesterday, and no share changed without linked evidence).

## SOP
- Reviews before merges. A ledger is a plan, not an approval.
````

Questions raised: none ("'Release candidate bundle' in PR #104 is not a deploy plan, so I added no run sheet, question or note").

## Observations against A4(c)

- No run-sheet section, no gate questions and no status note about a run sheet in either body (`rg -i 'run.?sheet'` over the two bodies is empty): yes. Goal header, estimate formula and SOP intact in both: yes.
- Execution 1 contains the item-level phrase "Deployment: not planned in this ledger." on Item 3, in the same family as the base skill's "deployment unverified" labels. It is not a run-sheet note and the skill does not forbid item-level deployment labels; recorded so the reader can judge. Execution 2 has no such phrase.
