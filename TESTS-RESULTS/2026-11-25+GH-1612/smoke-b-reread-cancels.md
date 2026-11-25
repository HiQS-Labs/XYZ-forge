# Smoke (b): guarded reread cancels the deploy (run 2, on the candidate after final QA round 1)

Executor: a fresh sub-agent, read-only (5 `Read` calls: the skill, `yesterday-silent.md`, `today-deploy.md`, `pr-facts.md`, `today-reread-cancelled.md`, plus one `ls` of `inputs/`; no writes, no `gh`). It drafted from the baseline, then applied the skill's step-7 guard with `today-reread-cancelled.md` as the live body. Nothing published. Run 1 is in git history at `179e96fa0`.

What the skill told it to do when the live body differed (its words): use the new read as baseline and draft source, redraft, check again, or stop; never overwrite blindly. It redrafted from the new read. Step 5a applies only when a ledger or linked checklist plans a deploy today, and "recomputed if step 7 redrafts" gives no sheet.

## First draft (from the baseline), verbatim

````markdown
# Daily Work Ledger — 2026-11-25 (fictional example)

Goal: ship Release X (official count 4 items, progress bar 50%).

## Deploy-day run sheet (plan only, not an approval; any later server write needs the operator's explicit approval for that action, with backups made first)
Deploy docs: see the repo deploy docs and the team deploy checklist linked from PR #104. Procedure is not restated here.

| Step | Owner | Planned time | Exact method | What a pass looks like | What stops the deploy |
|---|---|---|---|---|---|
| G1. Staging go-ahead | Lead 1 | 10:00 | Comment on PR #104 (GitHub). Re-check just before the deploy that the head is still bbb2222 (Reviewer B's review is at bbb2222; a newer head voids it). | Comment from Lead 1 at current head bbb2222 | Any open Must finding |
| G2. Staging deploy | Dev A | 11:00 | Repo deploy script, run from the shared build machine with the deploy key | Health page shows build bbb2222 AND 3 sample orders listed | Health page red |
| G3. Staging after-deploy check | Dev C | NOT SET | Run the saved search query against staging | NOT SET (must name what it has to have seen, e.g. row count or named items) | NOT SET |
| G4. Production go-ahead | NOT NAMED ("someone from the team") | "this evening" (no time) | NOT SET | NOT SET | NOT SET |
| G5. Production deploy | NOT NAMED (no row in the checklist) | NOT SET | NOT SET | NOT SET | NOT SET |
| G6. Late-evening production after-deploy check | NOT NAMED | NOT SET | NOT SET | NOT SET | NOT SET |
| S1. Access check (sign-ins, VPN, Docker, free disk) for the shared build machine and deploy key | NOT NAMED | before 11:00 (no time) | Not recorded; fallback machine not named | Deploy script starts on the named machine; deploy key accepted | Access fails and no fallback machine named |
| S2. Early rehearsal of the G3 method (saved search query) | NOT NAMED | before G2 (no time) | Not recorded | The query returns named items or a known row count, so an empty result cannot read as "all on" | Query errors or returns nothing |
| S3. Staging host config: set NEW_SEARCH=on | NOT NAMED | NOT SET | Unconfirmed (copied from last month's checklist; no host read here) | NOT SET | Parked: not planned until the code on staging is confirmed to support NEW_SEARCH |

G3 to G6 and S1 to S3 are not planned: each lacks an owner, a time or a method. They are asked below, not carried as prose.

Known review findings on included PRs:
- PR #104 (head bbb2222, CI green, no conflicts, not draft): "slow query on empty filter", grade Should, accepted by Lead 1 in a PR comment. Reviewer B's review is at bbb2222 (a review, not a deploy sign-off).
- PR #103 (head aaa1111, CI green, no conflicts, not draft): no finding in the live read. Reviewer B approved at aaa1111, which is the current head. It is not stated whether #103 is part of the #104 bundle.

## Morning questions
1. Dev C and Lead 1: what time is the staging after-deploy check (G3), and what must it have seen to pass (row count or named items)?
2. Who gives the production go-ahead (G4), at what time, and by what method?
3. Who deploys production (G5), at what time, and from which machine with which access?
4. Who does the late-evening production after-deploy check (G6), at what time, and what must it have seen?
5. Dev A: which machine, VPN, Docker and disk checks apply (S1), and what is the fallback machine?
6. Who rehearses the saved search query early (S2)?
7. Does the code running on staging (the host's recorded commit) support NEW_SEARCH (S3)? Whoever owns the host should read it. Is PR #103 inside the #104 bundle?
8. Header says official count 4 but Item 5 is listed with no share. Is it counted?

## Items
Done since yesterday (merged on the integration branch per live PR state):
- [x] Item 1: fix the export button (PR #101, merged by Dev A)
- [x] Item 2: update the help page (PR #102, merged; Reviewer B's yesterday approval, head not shown in this read)

Carried:
- [ ] Item 3: add the search filter (PR #103)
- [ ] Item 4: write the release notes (Dev C)

New:
- [ ] Item 5: deploy Release X candidate (PR #104) to staging today, then production this evening. See run sheet and questions above.

Parked: S3 NEW_SEARCH config change (see S3).
Dropped: none.

People's feedback: none supplied for this draft. Slack not checked.

## Completion estimate
Formula: sum of item shares x done fraction. Change log: 2026-11-24, no change. 2026-11-25, no change to shares or the 50% bar: Items 1 and 2 were already counted as done and their merges are confirmed (PR #101, #102); Item 5 has no share and is not in the official count of 4.

## SOP
- Reviews before merges. A ledger is a plan, not an approval.
````

## Final proposed body (after the guard), verbatim

````markdown
# Daily Work Ledger — 2026-11-25 (fictional example)

Goal: ship Release X (official count 4 items, progress bar 50%).

## Items
Done since yesterday (merged on the integration branch per live PR state):
- [x] Item 1: fix the export button (PR #101, merged by Dev A)
- [x] Item 2: update the help page (PR #102, merged; Reviewer B's yesterday approval, head not shown in this read)

Carried:
- [ ] Item 3: add the search filter (PR #103; Reviewer B's review is at head aaa1111, the current head; CI green, no conflicts, not draft)
- [ ] Item 4: write the release notes (Dev C)

Parked:
- [ ] Item 5: the Release X deploy moved to next week; nothing is deployed today. (Wording comes from the 2026-11-25 edit to today's body; the reason was not checked against GitHub.) PR #104 (release candidate bundle) stays open at head bbb2222, CI green, no conflicts, not draft. Reviewer B's review is at bbb2222. One known finding, "slow query on empty filter", grade Should, was accepted by Lead 1 in a PR comment. None of this is a deploy sign-off.

New: none.
Dropped: none.

People's feedback: none supplied for this draft. Slack not checked.

## Completion estimate
Formula: sum of item shares x done fraction. Change log: 2026-11-24, no change. 2026-11-25, no change to shares or the 50% bar: Items 1 and 2 were already counted as done and their merges are confirmed (PR #101, #102); Item 5 has no share and is not in the official count of 4.

## SOP
- Reviews before merges. A ledger is a plan, not an approval.
````

## Observations against A4(b)

- First draft: one six-column sheet, gate rows G1-G6 before support rows S1-S3, first after the goal header: yes.
- Final body after the cancelling reread: no sheet and no sheet questions: yes. Goal header, estimate formula and SOP intact: yes.
- The cancelled deploy's gaps were kept as a parked item rather than lost: yes (Item 5, parked).
- Nothing published, no `gh` call: yes.
