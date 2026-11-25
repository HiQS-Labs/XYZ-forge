# Smoke (b): guarded reread cancels the deploy

Executor: a fresh sub-agent, read-only (5 `Read` calls: the skill, `yesterday-silent.md`, `today-deploy.md`, `pr-facts.md`, `today-reread-cancelled.md`; no writes, no `gh`). It drafted from the baseline, then applied the skill's step-7 guard with `today-reread-cancelled.md` as the live body. Nothing published.

What the skill told it to do when the live body differed (its words): use the new read as baseline and draft source, redraft, check again, or stop; never overwrite blindly. It redrafted from the new read. Step 5a applies only when a ledger or linked checklist plans a deploy today, and "recomputed if step 7 redrafts" gives no sheet.

## First draft (from the baseline): had one run sheet

The first draft contained "Deploy-day run sheet (a plan, not an approval; read-only by default)", a 7-row table (owner, planned time, method, pass, stop) with the staging go-ahead first, rows 3-7 marked not planned (each missing a field), the known finding on PR #104, and morning questions Q1-Q5. Full text not repeated here; the same shape as `smoke-a-deploy-day.md`.

## Final proposed body (after the guard), verbatim

```markdown
# Daily Work Ledger — 2026-11-25 (fictional example)

Goal: ship Release X (official count 4 items, progress bar 50%).

## Today, grouped by person (reviews first)
- Reviewer B: reviews on record are PR #103 approved at head aaa1111 and PR #104 approved at head bbb2222 (both are the current heads). No current review requests are recorded in the inputs.
- Dev C: Item 4 (release notes).
- No owner named: Item 3 (PR #103: head aaa1111, CI green, no conflicts, not draft).

## Items
- [ ] Item 3: add the search filter (PR #103) — carried
- [ ] Item 4: write the release notes (Dev C) — carried
- [ ] Item 5: the Release X deploy moved to next week; nothing is deployed today. — parked

Done since yesterday (merged on the integration branch; deployment unverified):
- [x] Item 1: fix the export button (PR #101)
- [x] Item 2: update the help page (PR #102). Yesterday's ledger said approved by Reviewer B. The approved head is not recorded in the inputs.

Parked:
- Item 5 (deploy): moved to next week according to the live body edit. The reason and who moved it are not recorded in the inputs.
  - PR #104 (release candidate bundle) is open: head bbb2222, CI green, no conflicts, not draft, approved by Reviewer B at that head. Known finding "slow query on empty filter", grade Should, accepted by Lead 1 in a PR comment.
  - The earlier deploy plan was removed because no deploy is planned today. Its open gaps (no owner, time or pass criterion for the staging check; no owner or method for the production go-ahead, deploy and late check; the NEW_SEARCH=on staging step copied from last month's checklist and unverified against the code running on staging) need answers before a deploy is planned again.

Dropped: none.

People's feedback since yesterday: none recorded in the inputs. Slack was not checked.

## Completion estimate
Formula: sum of item shares x done fraction. Change log: 2026-11-24, no change. 2026-11-25, no change (no new evidence linked; Items 1 and 2 were already counted).

## SOP
- Reviews before merges. A ledger is a plan, not an approval.
```

## Observations against A4(b)

- The final body has no run sheet and no sheet questions: yes.
- Goal header, estimate formula and SOP intact: yes.
- The cancelled deploy's gaps were kept as a parked item rather than lost (the skill's "nothing is lost" rule): yes.
- Nothing published, no `gh` call: yes.
