# Smoke (c): a day with no deploy

Executor: a fresh sub-agent, read-only (4 `Read` calls: the skill, `yesterday-silent.md`, `today-nodeploy.md`, `pr-facts.md`; no writes, no `gh`). Whole proposed body below, verbatim; nothing published. Note `pr-facts.md` still lists PR #104 as an open bundle, so a deploy-shaped PR is present but no ledger or checklist plans a deploy.

```markdown
# Daily Work Ledger — 2026-11-25 (fictional example)

Goal: ship Release X (official count 4 items, progress bar 50%).

## Reviews first (past reviews and current review requests, reported separately)
- Reviewer B, past review on PR #103: approved at head aaa1111. That is the current head. This is a recorded review verdict, not a merge sign-off.
- Reviewer B, past review on PR #104: approved at head bbb2222. That is the current head. Same caveat.
- Current review requests on #103 and #104: not in the live-state read, so not stated.
- Reviewer B's yesterday approval on PR #102 is superseded: #102 is now on the integration branch. The head that approval was tied to was not re-checked.

## Items
- [ ] Item 3: add the search filter (PR #103). Carried from yesterday. Live state: head aaa1111, CI green, no conflicts, not draft. Today's work: the merge decision on #103 belongs to the people who own it; this ledger does not make it.
- [ ] Item 4: write the release notes (Dev C). Carried from yesterday. Today's work: Dev C writes the notes. No new evidence was found either way.

## Done since yesterday (verified against the integration branch)
- Item 1: fix the export button (PR #101). Merged: it is on the integration branch. Yesterday's ledger said "merged by Dev A"; who merged it was not verified in this read. Deployment unverified.
- Item 2: update the help page (PR #102). Merged: it is on the integration branch. Yesterday's ledger said only "approved by Reviewer B" (head not verified). Deployment unverified.

## New
- PR #104: release candidate bundle (not one of the 4 official items). Live state: head bbb2222, CI green, no conflicts, not draft.
  - Known finding: "slow query on empty filter", grade Should, accepted by Lead 1 in a PR comment.
  - Today's work: Lead 1 and the PR owner decide how to handle the finding. Nothing here counts #104 toward the official count.

## Parked
- None.

## Dropped
- None.

## People's feedback that changes today's work
- Only the #104 finding above (Should, accepted by Lead 1). No other feedback or end-of-day progress comments were in the supplied reads. Slack: not checked (no connector used).

## Not checked
- Deployment of #101 and #102 (no release, deploy comment or run was linked). No production or VM reads were made.

## Completion estimate
Formula: sum of item shares x done fraction. Change log: 2026-11-24, no change. 2026-11-25, no change: progress bar kept at 50% and no item share changed, because no linked evidence was supplied to change one.

## SOP
- Reviews before merges. A ledger is a plan, not an approval.
```

Questions the executor raised: none from step 5a ("No deploy is planned today, because neither ledger, nor any linked checklist, mentions one. The run sheet was therefore not added"). One optional unrelated question (whether PR #104 counts toward the official count).

## Observations against A4(c)

- Zero run-sheet output, no gate questions: yes. Goal header, estimate formula and SOP intact: yes.
