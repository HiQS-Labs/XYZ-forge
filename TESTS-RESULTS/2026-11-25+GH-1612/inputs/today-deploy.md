# Daily Work Ledger — 2026-11-25 (fictional example)

Goal: ship Release X (official count 4 items, progress bar 50%).

## Items
- [ ] Item 3: add the search filter (PR #103)
- [ ] Item 4: write the release notes (Dev C)
- [ ] Item 5: deploy Release X candidate (PR #104) to staging today, then production this evening.

## Deploy plan (from the team's deploy checklist, linked in the repo deploy docs)
- Go-ahead for staging: Lead 1, at 10:00, by a comment on PR #104. Pass: comment present from Lead 1 at the current head. Stop: any open Must finding.
- Deploy to staging: Dev A, 11:00, runs the repo's deploy script from the shared build machine with the deploy key. Pass: health page shows build bbb2222 and 3 sample orders listed. Stop: health page red.
- After-deploy check on staging: Dev C, method: run the saved search query against staging. (no time given, no pass criterion given)
- Production go-ahead: someone from the team, this evening. (no owner named, no method)
- Late-evening after-deploy check on production: nobody named yet.
- Config change on the staging host: set flag NEW_SEARCH=on (copied from last month's checklist).

## Completion estimate
Formula: sum of item shares x done fraction. Change log: 2026-11-24, no change.

## SOP
- Reviews before merges. A ledger is a plan, not an approval.
