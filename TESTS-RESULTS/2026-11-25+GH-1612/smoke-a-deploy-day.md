# Smoke (a): deploy day, deploy only in today's first body (run 2, on the candidate after final QA round 1)

Executor: a fresh sub-agent with no author conclusions, read-only (4 `Read` calls: the skill, `yesterday-silent.md`, `today-deploy.md`, `pr-facts.md`; no writes, no `gh`, no network). Skill read through its path in this clone. Steps 1-5's GitHub reads were replaced by the fictional files in `inputs/`. Whole proposed body below, verbatim; nothing published.

Run 1 (earlier commit `a0e59c02d`, still in git history at `179e96fa0`) used seven columns and put support rows ahead of a later gate; final QA round 1 found that, and step 5a was reworded to "six columns ... Gate rows first ... then support rows ..., each in time order". This is the re-run.

```markdown
# Daily Work Ledger — 2026-11-25 (fictional example)

Goal: ship Release X (official count 4 items, progress bar 50%).

## Deploy-day run sheet

This sheet is a plan, not an approval. Nothing in it signs off a merge, deploy or test. Any later server write needs the operator's explicit approval for that specific action, with backup ZIPs made first and their paths reported. Deploy docs: the repo deploy docs (linked from the team's deploy checklist). The checklist is not restated here.

Gate rows (first), then support rows, each in time order. "unset (Qn)" means the field is missing, so that step is NOT PLANNED until the morning question is answered.

| Step | Named owner | Planned time | Exact method (where it runs, which access) | What a pass looks like | What stops the deploy |
|---|---|---|---|---|---|
| G1. Staging go-ahead | Lead 1 | 10:00 | Comment on PR #104. Timer: the go-ahead only counts at the current head, so re-read PR #104's head SHA and CI at 10:00, right before G2. | A comment from Lead 1 is present at head bbb2222. CI is green and the head is still bbb2222 at the time of the re-read. | Any open Must finding. The head is no longer bbb2222. |
| G2. Deploy to staging | Dev A | 11:00 | Runs the repo's deploy script from the shared build machine with the deploy key. | Health page shows build bbb2222 and 3 sample orders listed (the order identifiers are not recorded here). | Health page red. G1 has not passed. |
| G3. After-deploy check on staging | Dev C | unset (Q1) | Run the saved search query against staging. Which query and which access: unset (Q1). | unset (Q1) | unset (Q1) |
| G4. Production go-ahead | unset (Q2) | unset (Q2). The ledger says only "this evening", with no clock time. | unset (Q2). Timer: it only counts right before the production deploy, so re-read head, CI and findings at that moment. | unset (Q2) | unset (Q2) |
| G5. Production deploy | unset (Q3) | unset (Q3) | unset (Q3), including where it runs and with which access. | unset (Q3) | unset (Q3) |
| G6. Late-evening after-deploy check on production | unset (Q4) | unset (Q4) | unset (Q4) | unset (Q4) | unset (Q4) |
| S1. Access check for the staging deploy (sign-ins, VPN, Docker, free disk, deploy key loads) | Dev A (proposed; confirm in Q5) | By 09:30 (proposed, before the 10:00 go-ahead) | On the shared build machine. The fallback machine is unset (Q5). | Deploy key loads. The build machine is reachable. The free-disk figure is recorded as a number in a PR #104 comment. | Any item fails and no fallback machine is named, so G2 is not safe to start. |
| S2. Early rehearsal of the G3 method | Dev C (proposed; confirm in Q1) | Before 11:00 (proposed) | Run the saved search query against staging as it runs now, before the deploy. | The query runs and returns the named items or count that Dev C records in a comment, so an empty result cannot read as "all on". | The query cannot run or returns nothing. G3 then stays NOT PLANNED. |
| S3. Staging host config: set NEW_SEARCH=on | unset (Q6) | unset (Q6) | Copied from last month's checklist, so a claim, not a fact. First, someone confirms from the staging host's recorded commit that the code running there reads NEW_SEARCH. That is a host read or run and is not done from this ledger. A change on the staging host is a server write. | unset (Q6) | The running code does not support the flag. The operator has not approved this specific write. Backups are not made first. |

Known review findings on included PRs (listed once):
- PR #104 (head bbb2222): "slow query on empty filter", grade Should, accepted by Lead 1 in a PR comment. No other findings were provided for #104.
- PR #103: no findings were provided. Whether #104 includes #103 is unknown (Q7).

### Morning questions (answer in a comment on this issue)
1. G3: Dev C, what clock time is the staging after-deploy check? Which exact saved query and which access? What must a pass have seen (for example, a result count or named items, not just "no errors")? What stops the deploy? Also confirm Dev C owns the S2 rehearsal and its time.
2. G4: Who gives the production go-ahead, at what clock time, and by what method (for example, a comment on PR #104 at the current head)?
3. G5: Who deploys to production, at what clock time, from where, with which access? What does a pass look like, and what stops it?
4. G6: Who does the late-evening production after-deploy check, at what time, with what method? What must a pass have seen, and what stops it?
5. S1: Which machine is the fallback if the shared build machine or its deploy key is unavailable? Is Dev A the right owner for the access check? Who checks production access?
6. S3: Is NEW_SEARCH=on still needed for this build? If so, who confirms from the staging host's recorded commit that the running code supports it, and when? Who asks the operator to approve the write? The flag was copied from last month's checklist.
7. Which PRs does the PR #104 "release candidate bundle" include? In particular, does it include PR #103 (the search filter), which is still unmerged and which G3 and S3 may depend on?

## Items

### Done (verified against the integration branch)
- [x] Item 1: fix the export button. PR #101 is on the integration branch (merged, verified). Deployment unverified (no deploy evidence read).
- [x] Item 2: update the help page. PR #102 is on the integration branch (merged, verified). Yesterday's "approved by Reviewer B" was not re-checked against a head in this refresh. Deployment unverified.

### Carried
Reviews and deploy gates first, then by person.
- Lead 1: the G1 staging go-ahead for Item 5 (see run sheet).
- Dev A: the G2 staging deploy and the S1 access check for Item 5 (see run sheet).
- Dev C:
  - [ ] Item 4: write the release notes. No new GitHub evidence of progress was provided.
  - The G3 after-deploy check and the S2 rehearsal for Item 5, both pending Q1.
- [ ] Item 3: add the search filter (PR #103). The owner is not recorded in this ledger. Live state: head aaa1111, CI green, no conflicts, not draft. Reviewer B approved at head aaa1111, which is the current head. Still unmerged. Merging is not decided here.

### New
- [ ] Item 5: deploy the Release X candidate (PR #104) to staging today, then to production this evening. Live state of PR #104: head bbb2222, CI green, no conflicts, not draft. Reviewer B approved at head bbb2222, which is the current head. One known finding (Should), accepted by Lead 1 (see run sheet). Nothing has been deployed. Deployment unverified. Production steps are NOT PLANNED until Q2 to Q4 are answered.

### Parked
- None.

### Dropped
- None.

## Feedback from people (changes today's work)
- No review, issue or PR comments beyond the PR states above were provided to this refresh. The only open finding is the accepted Should on PR #104. Nothing is waiting on an unanswered question except Q1 to Q7 above.
- Slack was not checked.

## Completion estimate
Formula: sum of item shares x done fraction. Change log: 2026-11-24, no change. 2026-11-25, no change: PR #101 and PR #102 are verified on the integration branch, which matches the two items already counted in the 50% progress bar. No item share changed, and no linked evidence calls for one.

## SOP
- Reviews before merges. A ledger is a plan, not an approval.
```

## Observations against A4(a)

- Exactly six columns (header row has six cells), checked below by `awk` on this file: yes.
- Gate rows G1-G6 before support rows S1-S3, each group in time order: yes.
- One sheet, directly after the goal header, before everything else: yes.
- The owner-but-no-time gate (G3) and the no-owner gates (G4-G6) are asked as morning questions Q1-Q4: yes.
- Goal header, estimate formula and SOP intact: yes.
- Executor-added "proposed" owners and times for S1 and S2 are labelled "proposed; confirm" and asked (Q1, Q5), not presented as planned.
