# Smoke (c): a day with no deploy (run 2, on the candidate after final QA round 1)

Executor: a fresh sub-agent, read-only (4 `Read` calls: the skill, `yesterday-silent.md`, `today-nodeploy.md`, `pr-facts.md`; no writes, no `gh`). Whole proposed body below, verbatim; nothing published. `pr-facts.md` still lists PR #104 as an open bundle, so a deploy-shaped PR is present, but no ledger or checklist plans a deploy. Run 1 is in git history at `179e96fa0`.

```markdown
# Daily Work Ledger — 2026-11-25 (fictional example)

Goal: ship Release X (official count 4 items, progress bar 50%).

## Items

Reviews first, then by person. Each line is work to do or a verified fact. None is a sign-off.

### Reviews and merge steps
- [ ] Item 3: add the search filter (PR #103). Carried from 2026-11-24.
  - Live state: head aaa1111, CI green, no conflicts, not draft.
  - Past review: Reviewer B's review verdict is "approved" at head aaa1111, which is the current head. This is a review record, not a merge sign-off.
  - Current review requests: none recorded in this read.
  - To do: the PR owner and Reviewer B decide on the merge. Not merged as of this read.

### Dev C
- [ ] Item 4: write the release notes. Carried from 2026-11-24, no PR yet and no new evidence.

### Done, verified as merged on the integration branch
- [x] Item 1: fix the export button (PR #101). Merged. Deployment unverified.
- [x] Item 2: update the help page (PR #102). Merged. Deployment unverified. Yesterday's ledger showed this item as "approved by Reviewer B". It is now confirmed merged.

### New / parked / dropped
- New: none. Parked: none. Dropped: none.

### Checked and not checked
- No deploy is planned today, so there is no deploy run sheet.
- Comments and feedback since local midnight: none supplied in this run, so none are listed.
- Slack: not checked (no connector read).
- Anything needing a production or VM read: not checked.

## Completion estimate
Formula: sum of item shares x done fraction. Change log:
- 2026-11-24: no change.
- 2026-11-25: no change. Item shares are unchanged because no linked evidence changes them. Items 1 and 2 were already counted done at 50%.

## SOP
- Reviews before merges. A ledger is a plan, not an approval.
```

Questions the executor raised: none from step 5a ("Step 5a applies only when a ledger or linked deploy checklist plans a deploy today, and neither ledger does"). It also asked whether to publish (the skill's go-ahead rule) and, as its own note, whether to add PR #104 as an item.

## Observations against A4(c)

- No run sheet and no gate questions: yes. The draft itself states "No deploy is planned today, so there is no deploy run sheet" as a checked-and-not-checked note; that is a statement, not a sheet.
- Goal header, estimate formula and SOP intact: yes.
