# Smoke (a): deploy day, deploy only in today's first body

Executor: a fresh sub-agent with no author conclusions, read-only (4 `Read` calls: the skill, `yesterday-silent.md`, `today-deploy.md`, `pr-facts.md`; no writes, no `gh`, no network). Skill read through its path in this clone. Steps 1-5's GitHub reads were replaced by the fictional files in `inputs/`. Whole proposed body below, verbatim; nothing published.

```markdown
# Daily Work Ledger — 2026-11-25 (fictional example)

Goal: ship Release X (official count 4 items, progress bar 50%).

## Deploy-day run sheet (staging today, production this evening)

This sheet is a plan, not an approval. Deploy docs: see the repo deploy docs and the team's deploy checklist (linked there). A row missing owner, time or method is NOT PLANNED and is asked in "Morning questions" below. Nothing here has been checked on a host. Any server write (deploy, config change) needs the operator's explicit approval for that specific action, with backup ZIPs made and confirmed first.

| # | Step | Owner | Planned time | Exact method (where, access) | Pass looks like | Stops the deploy |
|---|------|-------|--------------|------------------------------|-----------------|------------------|
| 1 | Staging go-ahead (gate) | Lead 1 | 10:00 | Comment on PR #104 on GitHub, from Lead 1's own account | A comment from Lead 1 that names head bbb2222 (the current head of PR #104) | Any open Must finding; a new head on PR #104 after the comment |
| 2 | Pre-deploy re-check of PR #104 (only counts right before the deploy; timer: run it immediately before step 4 starts, because a push or a changed review after the 10:00 go-ahead would make step 1 stale) | NOT PLANNED: owner not named (Dev A proposed, to confirm) | NOT PLANNED: set to just before 11:00 | GitHub read-only: head SHA, CI, reviews endpoint | Head is still bbb2222, CI green, Reviewer B's approval is still at bbb2222, no open Must finding | Head differs from bbb2222; CI red; approval at an older head; open Must finding |
| 3 | Early rehearsal of the deploy method and access: sign-in to the shared build machine, deploy key present, free disk, VPN/Docker if needed; name the fallback machine | NOT PLANNED: owner not named | NOT PLANNED: time not set (must be well before 11:00) | Shared build machine with the deploy key; fallback machine: NOT NAMED | Owner confirms sign-in works, deploy key is usable, disk is free, and names the fallback machine | Any access failure with no fallback machine named |
| 4 | Deploy PR #104 to staging | Dev A | 11:00 | Repo's deploy script, run from the shared build machine with the deploy key | Health page shows build bbb2222 AND the 3 sample orders are listed (both seen, not just "no errors") | Health page red |
| 5 | Staging config change: set NEW_SEARCH=on | NOT PLANNED: no owner, time or method | NOT PLANNED | NOT PLANNED. This step was copied from last month's checklist, so it is a claim, not a fact. It is valid only if the code running on staging supports the flag, and the staging host's recorded commit says what runs. Only a host read can settle that; this ledger makes none. | Not defined until the owner confirms the flag is supported at the commit running on staging | Flag not supported by the code on staging; no explicit operator approval for this server write; no backup ZIPs made and confirmed |
| 6 | Staging after-deploy check: run the saved search query against staging | Dev C | NOT PLANNED: no time given | Run the saved search query against staging (where it runs and with which access: NOT STATED) | NOT PLANNED: no pass criterion. It must name what it has to see (for example an expected row count or named items), so a query that matches nothing cannot read as "all on" | Not defined yet |
| 7 | Production go-ahead (gate) | NOT PLANNED: "someone from the team" is not an owner | NOT PLANNED: "this evening" is not a time | NOT PLANNED: no method | Not defined until owner and method exist | Not defined yet |
| 8 | Deploy PR #104 to production | NOT PLANNED: no owner (the earlier plan names no production deploy step at all) | NOT PLANNED: "this evening" | NOT PLANNED: no method, access or fallback machine | Not defined yet | Not defined yet |
| 9 | Late-evening after-deploy check on production | NOT PLANNED: nobody named | NOT PLANNED | NOT PLANNED | Not defined until the check names what it must have seen | Not defined yet |

Known review findings on included PRs:
- PR #104 (head bbb2222): "slow query on empty filter", grade Should, accepted by Lead 1 in a PR comment. It is not a Must, so it does not stop the deploy by itself.
- PR #103 (head aaa1111): no known findings in the supplied review facts. Whether #103 is included in the #104 bundle is not recorded (see question 8).

## Reviews and PR state (live state at drafting)

Past reviews (reviews endpoint):
- PR #103, head aaa1111: Reviewer B approved at head aaa1111. CI green, no conflicts, not draft.
- PR #104, head bbb2222: Reviewer B approved at head bbb2222. CI green, no conflicts, not draft.
- Both approvals are for the heads shown. They are not merge or deploy sign-offs. If either PR gets a new head, its approval must be re-checked.

Current review requests: none reported in the supplied PR facts.

## Items

Done (verified merged on the integration branch since yesterday):
- [x] Item 1: fix the export button. PR #101 merged (Dev A). Merged only: not deployed, deployment unverified.
- [x] Item 2: update the help page. PR #102 merged. Yesterday's note said approved by Reviewer B. The approved head is not in the supplied facts. Merged only: deployment unverified.

Carried:
- [ ] Item 3: add the search filter (PR #103). Needs a merge decision from the people who own it. Live state: head aaa1111, CI green, no conflicts, approved by Reviewer B at aaa1111. Not merged.
- [ ] Item 4: write the release notes (Dev C). No progress evidence in the supplied facts. Carried unchanged.

New:
- [ ] Item 5: deploy the Release X candidate (PR #104) to staging today, then production this evening. Planned in the run sheet above. Production steps are not yet plannable (see Morning questions).

Parked: none.
Dropped: none.

## By person

- Reviewer B: reviews on #103 and #104 done at the heads above. No review request recorded for today.
- Lead 1: staging go-ahead on PR #104 (run sheet row 1).
- Dev A: staging deploy (row 4); proposed for the pre-deploy re-check (row 2, to confirm).
- Dev C: Item 4 release notes; staging after-deploy check (row 6, time and pass criterion missing).
- Unassigned (asked below): rows 2, 3, 5, 7, 8, 9.

## Feedback from people

No issue or PR comment feedback was supplied for this run beyond the finding recorded above. Slack was not checked.

## Morning questions

1. Staging after-deploy check (row 6): Dev C, what time, where does the saved search query run, with which access, and what must it show (expected row count or named items)?
2. Production go-ahead (row 7): who gives it, at what time, and by what method?
3. Production deploy (row 8): who deploys, at what time, by what method, with which access, and which fallback machine?
4. Late-evening production check (row 9): who does it, at what time, by what method, and what must it have seen?
5. NEW_SEARCH=on (row 5): does the code at bbb2222 support the flag, and what commit is staging running now? Who applies the change, when, and before or after the deploy? The owner has to read the host to answer this. If approved, it is a server write and needs the operator's explicit approval for that action plus backup ZIPs first.
6. Deploy access (row 3): who rehearses sign-in, deploy key, disk and VPN/Docker on the shared build machine, when, and which machine is the fallback?
7. Pre-deploy re-check (row 2): confirm the owner (Dev A proposed) and that it runs just before 11:00.
8. Is PR #103 (search filter) part of the #104 bundle, or does it merge separately, and in what order?

## Completion estimate
Formula: sum of item shares x done fraction. Change log: 2026-11-24, no change. 2026-11-25, no change: Items 1 and 2 were already counted done on 2026-11-24, and their merges are now verified (PR #101, PR #102 on the integration branch). Item 5 is new and outside the official count of 4, so no share changed.

## SOP
- Reviews before merges. A ledger is a plan, not an approval.
```

## Observations against A4(a)

- One six-column sheet (plus a `#` column), directly after the goal header, before everything else: yes.
- The owner-but-no-time gate (row 6, staging after-deploy check) and the no-owner gates (rows 7, 8, 9) are asked as morning questions 1-4: yes.
- Goal header, estimate formula and SOP intact: yes.
- Evidence-style passes (row 4 names the build and the 3 sample orders): yes.
- Gate ordering: chronological, not strictly "all gates before steps" (the production go-ahead is row 7). The skill's "gates first" line lists go-ahead, deploy and after-deploy checks as the gates, so this reading is consistent; noted as an observation, not a defect.
