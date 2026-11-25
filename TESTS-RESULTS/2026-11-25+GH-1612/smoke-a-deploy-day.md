# Smoke (a): deploy day, deploy only in today's first body (run 3, on skill commit `540e04421`)

Executor: a fresh sub-agent with no author conclusions, read-only (4 `Read` calls: the skill, `yesterday-silent.md`, `today-deploy.md`, `pr-facts.md`; no writes, no `gh`, no network). Skill read through its path in this clone. Steps 1-5's GitHub reads were replaced by the fictional files in `inputs/`. Whole proposed body below, verbatim; nothing published.

Run history: run 1 (`179e96fa0`) used seven columns with support rows ahead of a gate (final QA round 1). Run 2 (`11eca2dd6`) fixed that but timed the head recheck at the 10:00 go-ahead, an hour before the 11:00 deploy it said it protected (final QA round 2). Step 5a now says the timer is "set for just before the deploy itself (not the earlier go-ahead)"; this is the re-run on that text.

````markdown
# Daily Work Ledger — 2026-11-25 (fictional example)

Goal: ship Release X (official count 4 items, progress bar 50%).

> This ledger is a plan, not an approval. Nothing here records a merge, deploy or test sign-off. Any later write to a server needs the operator's explicit approval for that specific action, with backup ZIPs made and confirmed first.

## Deploy-day run sheet (plan only)

Deploy docs: the repo's deploy docs, as linked from the team's deploy checklist (link not supplied in this run; add it here). Nothing from those docs is restated below.

Gate rows come first (go-ahead, deploy, after-deploy checks), then support rows, each in time order. A row marked NOT PLANNED is missing a field and is asked in "Morning questions" below, not carried as prose.

| Step | Named owner | Planned time | Exact method (where it runs, with which access) | What a pass looks like | What stops the deploy |
|---|---|---|---|---|---|
| Staging go-ahead (PR #104) | Lead 1 | 10:00 | A comment on PR #104, written from Lead 1's own GitHub login | A comment from Lead 1 is present and names the current head bbb2222, and the findings list on PR #104 has been read and shows no open Must finding (today: one Should finding, accepted, see below) | Any open Must finding |
| Deploy to staging | Dev A | 11:00 | Dev A runs the repo's deploy script from the shared build machine with the deploy key | The staging health page shows build bbb2222 and lists 3 sample orders | Health page red; also anything that fails the pre-deploy re-check row below |
| After-deploy check on staging | Dev C | NOT PLANNED: no time | Run the saved search query against staging. NOT PLANNED: which saved query, where it runs and with which access are not stated | NOT PLANNED: no pass criterion (must name what the query has to return, such as row counts or named items, so that an empty result cannot read as "all on") | NOT PLANNED: no stop condition |
| Production go-ahead | NOT PLANNED: nobody named | "This evening" only | NOT PLANNED: no method | NOT PLANNED | NOT PLANNED |
| Production deploy | NOT PLANNED: item 5 says "production this evening" but the checklist has no row and no deployer | NOT PLANNED | NOT PLANNED | NOT PLANNED | NOT PLANNED |
| Late-evening after-deploy check on production | NOT PLANNED: nobody named | Late evening (exact time NOT PLANNED) | NOT PLANNED | NOT PLANNED (must say what the check has to have seen) | NOT PLANNED |
| Access check: sign-ins, VPN, Docker, free disk on the shared build machine, deploy key usable | Dev A (proposed, to confirm) | Early, before 10:00 (proposed) | Run on the shared build machine; fallback machine NOT NAMED (to be named in this row) | Each item seen working, written down by name (for example "deploy key listed", "free disk: N GB"), not just "no errors" | Any access item missing and no named fallback machine |
| Rehearsal of the staging after-deploy check method | Dev C (proposed, to confirm) | Early, before 11:00 (proposed) | A dry run of the saved search query. Where it runs is to be settled with the operator, because running anything against a server needs the operator's explicit approval | The query returned the named items or counts the check will later require | Query fails or returns nothing when it should return something |
| Pre-deploy re-check of the go-ahead (timer, set just before the 11:00 deploy, not at the 10:00 go-ahead) | Dev A (proposed, to confirm) | Just before 11:00 (proposed 10:50) | Re-read PR #104 on GitHub: head SHA, CI, Lead 1's go-ahead comment, findings list. Why the timer: the head can move after 10:00, and a go-ahead tied to an older head does not cover a newer one | Head is still bbb2222, CI green, go-ahead comment names bbb2222, no open Must finding | Head differs from bbb2222, CI not green, go-ahead names another head, or a new Must finding |
| Production pre-deploy re-check (same timer rule, just before the production deploy) | NOT PLANNED | NOT PLANNED (set once the production deploy time exists) | Same method as the staging re-check | Same as the staging re-check, against the production candidate head | Same as the staging re-check |
| Config change on the staging host: set NEW_SEARCH=on | NOT PLANNED: no owner | NOT PLANNED: no time, and no order against the staging deploy | NOT PLANNED: no method. This is a claim copied from last month's checklist, not a fact. It is valid only if the code running on staging supports the flag; the host's recorded commit (not supplied here, and no host read was made) would say. It is also a server write, so it needs the operator's explicit approval and backups first | NOT PLANNED | NOT PLANNED |

### Known review findings on included PRs
- PR #104: "slow query on empty filter", grade Should, accepted by Lead 1 in a PR comment (listed once; no new finding found today).
- PR #103: no known finding reported.

## Live state of open PRs (read at drafting time)
- PR #103 (search filter): head aaa1111, CI green, no conflicts, not draft. Past review: Reviewer B approved at head aaa1111, which is the current head. Current review requests: not reported in the supplied facts.
- PR #104 (release candidate bundle): head bbb2222, CI green, no conflicts, not draft. Past review: Reviewer B approved at head bbb2222, which is the current head. Current review requests: not reported in the supplied facts.
- Trial-merge of the planned merge order: not supplied in this run, so unchecked.
- Merged since yesterday: PR #101 and PR #102 are on the integration branch.

## Feedback from people
- Comments since local midnight and Slack: none supplied in this run, and Slack not checked.
- Open finding: see "Known review findings" above.

## Items

### Done (verified against the integration branch)
- [x] Item 1: fix the export button (PR #101). Merged, on the integration branch. Deployment unverified.
- [x] Item 2: update the help page (PR #102). Merged, on the integration branch. Deployment unverified. Yesterday's "approved by Reviewer B" was not re-checked against a head in this run.

### Carried (reviews and deploy gates first, grouped by person)
- Lead 1:
  - [ ] Staging go-ahead for PR #104 at 10:00 (run-sheet row 1).
- Dev A:
  - [ ] Deploy to staging at 11:00 (run-sheet row 2), plus the access check and pre-deploy re-check rows, owners to confirm.
- Reviewer B:
  - [ ] Review verdicts recorded: PR #103 at head aaa1111, PR #104 at head bbb2222 (both current heads). Re-review is needed only if either head changes.
- Dev C:
  - [ ] Item 4: write the release notes. No progress evidence was supplied.
  - [ ] Staging after-deploy check (run-sheet row 3), not yet planned: time, saved query, pass criterion and stop condition are missing.
- No named owner:
  - [ ] Item 3: add the search filter (PR #103). Review verdict recorded at the current head, CI green, no conflicts, not draft, not merged. Work to do: a merge decision by whoever holds that role.
  - [ ] Production go-ahead, production deploy and late-evening production check (run-sheet rows 4-6): owner, time and method are missing for all three.
  - [ ] NEW_SEARCH=on on the staging host: owner, time and method missing, and its validity is unchecked.

### New
- [ ] Item 5: deploy the Release X candidate (PR #104) to staging today, then production this evening. Planned only as far as the run sheet shows; the production half is not yet planned.

### Parked
- None.

### Dropped
- None.

## Morning questions (asked, not assumed)
1. Who deploys to production this evening, and at what time?
2. Who gives the production go-ahead, when, and by what method (for example a comment on which PR, from which login)?
3. Who runs the late-evening production after-deploy check, at what time, by what method, and what must it have seen to count as a pass?
4. Dev C: at what time is the staging after-deploy check, which saved query is it, where does it run and with which access, and what must it return (row counts or named items) to count as a pass?
5. Who sets NEW_SEARCH=on on the staging host, when, and how? Is that code on staging (is PR #103 inside the PR #104 bundle, and what commit does the staging host record)? It is a server write, so it needs your explicit approval and backup ZIPs first.
6. Which machine is the fallback if the shared build machine or the deploy key is unavailable? Does anyone need VPN, Docker or free disk checked first?
7. Please confirm the proposed owners and times for the access check, the rehearsal, and the pre-deploy re-check (Dev A, Dev C, Dev A).

## Completion estimate
Formula: sum of item shares x done fraction. Change log: 2026-11-24, no change. 2026-11-25, no change (items 1 and 2 are already counted done; no item share changed and no linked evidence supports changing one).

## SOP
- Reviews before merges. A ledger is a plan, not an approval.
````

## Observations against A4(a)

- One six-column sheet, the first section after the goal header (a one-line "plan, not an approval" quote sits between them): yes.
- Gate rows (staging go-ahead, staging deploy, staging check, production go-ahead, production deploy, late-evening check) before support rows (access, rehearsal, pre-deploy re-check, production re-check, config): yes.
- The timer: the re-check row is "set just before the 11:00 deploy, not at the 10:00 go-ahead", proposed 10:50, with the reason stated: yes (fixes the run-2 observation).
- The owner-but-no-time gate (staging after-deploy check) and the no-owner gates are asked as morning questions 1-4: yes.
- Goal header, estimate formula and SOP intact: yes.
- Executor-added owners and times for support rows are labelled "proposed, to confirm" and asked (question 7), not presented as planned.
