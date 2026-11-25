# Smoke (b): guarded reread cancels the deploy (run 3, on skill commit `540e04421`)

Executor: a fresh sub-agent, read-only (5 `Read` calls: the skill, `yesterday-silent.md`, `today-deploy.md`, `pr-facts.md`, `today-reread-cancelled.md`; no `ls`, no writes, no `gh`). It drafted from the baseline, then applied the skill's step-7 guard with `today-reread-cancelled.md` as the live body. Nothing published. Earlier runs are in git history (`179e96fa0`, `11eca2dd6`).

What the skill told it to do when the live body differed (its words): re-read before `gh issue edit`; if changed, "use the new read as baseline and draft source, redraft, check again, or stop"; never overwrite blindly. It used the re-read body as the new baseline and redrafted. Step 5a applies only when a deploy is planned today, so the redraft adds "no run sheet, no morning questions and no deploy note".

## First draft (from the baseline), verbatim

````markdown
# Daily Work Ledger — 2026-11-25 (fictional example)

Goal: ship Release X (official count 4 items, progress bar 50%).

## Deploy-day run sheet
Plan only, not an approval. Deploy docs: the team's deploy checklist, linked from the repo deploy docs (not restated here). Any later server write needs the operator's explicit approval for that action, with backups made first.

| Step | Owner | Planned time | Exact method | Pass looks like | Stops the deploy |
|---|---|---|---|---|---|
| GATE: Staging go-ahead | Lead 1 | 10:00 | Comment on PR #104 on GitHub | Comment from Lead 1 present at the current head bbb2222 | Any open Must finding |
| GATE: Staging deploy | Dev A | 11:00 | Repo deploy script, run from the shared build machine with the deploy key. Fallback machine: not recorded (question 4). | Health page shows build bbb2222 AND 3 sample orders listed | Health page red. Also (timer, added by this draft): a re-check set for just before 11:00, not at the 10:00 go-ahead, that PR #104 head is still bbb2222 and no Must finding opened after the go-ahead. A go-ahead at an older head does not count. |
| GATE: Staging after-deploy check | Dev C | NOT SET | Run the saved search query against staging (access not stated) | NOT SET (must name what it saw, e.g. row count or named items) | NOT SET |
| GATE: Production go-ahead | NOT NAMED | "this evening", no clock time | NOT SET | NOT SET | NOT SET |
| GATE: Production deploy | NOT NAMED | NOT SET | NOT SET | NOT SET | NOT SET |
| GATE: Production late-evening after-deploy check | NOT NAMED | late evening, no clock time | NOT SET | NOT SET (must name what it saw) | NOT SET |
| Support: access check (sign-ins, VPN, Docker, free disk) for the shared build machine and deploy key | NOT NAMED | before 11:00, time not set | NOT SET | NOT SET | NOT SET |
| Support: early rehearsal of the staging deploy method | NOT NAMED | NOT SET | NOT SET | NOT SET | NOT SET |
| Support: staging host config NEW_SEARCH=on | NOT NAMED | NOT SET | Host read or run needed (none done here) | NOT SET | NOT SET |

Gates with a missing field are not planned. These are the 4 not-planned gates: staging after-deploy check, production go-ahead, production deploy, and production after-deploy check. The deploy script and the NEW_SEARCH row are not verified. See questions 1-6.

Known review findings on included PRs (listed once):
- PR #104: "slow query on empty filter", grade Should, accepted by Lead 1 in a PR comment.
- PR #103: none known.

## Morning questions (unanswered, need an owner)
1. Dev C: what time is the staging after-deploy check, and what must it have seen to count as a pass (row count or named items)? What stops the deploy if it fails?
2. Who gives the production go-ahead, at what clock time, and how (comment, message)?
3. Who deploys to production, at what time, and by what method? Who does the late-evening production after-deploy check, at what time, and what must it have seen?
4. Dev A: are sign-ins, VPN, Docker and free disk on the shared build machine confirmed? Which fallback machine is used if it fails?
5. Who runs an early rehearsal of the deploy method, and when?
6. NEW_SEARCH=on was copied from last month's checklist. It is a claim, not a fact. Whoever owns the staging host: does the code running there (commit recorded on the host) support this flag, and who sets it and when? No host read was done here.

## Items
Reviews and deploy gates first, grouped by person.

Reviewer B
- [ ] Review of PR #103 and PR #104 is on record as approved at heads aaa1111 and bbb2222 (the current heads). Re-check at merge time. This is a plan, not an approval.

Lead 1
- [ ] Staging go-ahead on PR #104 (see run sheet).

Dev A
- [ ] Item 5: deploy Release X candidate (PR #104) to staging today (see run sheet); production this evening is not yet planned.

Dev C
- [ ] Item 4: write the release notes. No progress evidence found.
- [ ] Staging after-deploy check (see run sheet; gaps asked above).

Unowned / open
- [ ] Item 3: add the search filter (PR #103). Head aaa1111, CI green, no conflicts, not draft, Reviewer B's review approved at aaa1111. Carried.

### Done (since yesterday, verified on the integration branch)
- [x] Item 1: fix the export button, PR #101, merged on the integration branch. Deployment unverified.
- [x] Item 2: update the help page, PR #102, merged on the integration branch, with a Reviewer B approval recorded. Deployment unverified.

Parked: none. Dropped: none.

Feedback read: no new people's feedback recorded in the sources read. Slack not checked.

## Completion estimate
Formula: sum of item shares x done fraction. Change log: 2026-11-24, no change. 2026-11-25, no change (PR #101 and PR #102 merges were already counted yesterday).

## SOP
- Reviews before merges. A ledger is a plan, not an approval.
````

## Final proposed body (after the guard), verbatim

````markdown
# Daily Work Ledger — 2026-11-25 (fictional example)

Goal: ship Release X (official count 4 items, progress bar 50%).

## Items
Reviews first, grouped by person.

Reviewer B
- [ ] Review of PR #103 is on record as approved at head aaa1111 (the current head). Re-check at merge time. This is a plan, not an approval.

Dev C
- [ ] Item 4: write the release notes. No progress evidence found.

Unowned / open
- [ ] Item 3: add the search filter (PR #103). Head aaa1111, CI green, no conflicts, not draft. Carried.
- [ ] Item 5: the Release X deploy moved to next week; nothing is deployed today. (New today; wording kept as in the live body.)

### Done (since yesterday, verified on the integration branch)
- [x] Item 1: fix the export button, PR #101, merged on the integration branch. Deployment unverified.
- [x] Item 2: update the help page, PR #102, merged on the integration branch, with a Reviewer B approval recorded. Deployment unverified.

Parked: none. Dropped: none.

Feedback read: no new people's feedback recorded in the sources read. Slack not checked.

## Completion estimate
Formula: sum of item shares x done fraction. Change log: 2026-11-24, no change. 2026-11-25, no change (PR #101 and PR #102 merges were already counted yesterday).

## SOP
- Reviews before merges. A ledger is a plan, not an approval.
````

Skill gaps the executor reported while following it literally (observations, not defects against the acceptance items): the skill does not say what to do with deploy rows when the live body cancels the deploy mid-run (it read the step-5a trigger as the test and dropped everything); support rows have no times in the baseline, so it ordered them as listed; "3 sample orders listed" has no stated source.

## Observations against A4(b)

- First draft: one six-column sheet, gate rows before support rows, directly after the goal header; the timer is stated in the deploy row as "just before 11:00, not at the 10:00 go-ahead": yes.
- Final body after the cancelling reread: no sheet, no sheet questions, no status note about a sheet: yes (`rg -i 'run.?sheet'` on the final body is empty). Goal header, estimate formula and SOP intact: yes.
- Nothing published, no `gh` call: yes.
