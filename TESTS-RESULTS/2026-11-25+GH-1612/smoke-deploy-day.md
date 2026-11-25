# Smoke: deploy day (single run)

One manual check (GH-831: no new test). A fresh sub-agent with no author conclusions, read-only (4 `Read` calls: the skill, `inputs/yesterday-silent.md`, `inputs/today-deploy.md`, `inputs/pr-facts.md`; no writes, no `gh`, no network). The skill was read through its path in this clone; steps 1-5's GitHub reads were replaced by the fictional files in `inputs/`. Whole proposed body below, verbatim; nothing was published.

Input: yesterday's ledger is silent on deploys; today's first body plans a staging deploy and a production deploy, with one complete gate, one gate with an owner but no time, gates with no owner, a config change copied from an older checklist, and a PR with an accepted finding.

````markdown
# Daily Work Ledger — 2026-11-25 (fictional example)

Goal: ship Release X (official count 4 items, progress bar 50%).

## Deploy-day run sheet (a plan, not an approval)

Deploy docs: the repo deploy docs linked from the team's deploy checklist (link not in the inputs; nothing restated here). Live state used: PR #104 head bbb2222, CI green, no conflicts, not draft, reviewed by Reviewer B at head bbb2222. Current review requests: not recorded. Nothing is verified as deployed (deployment unverified). A trial merge of the planned merge order was not run for this draft.

Gate rows first, then support rows, each in time order. Cells marked NOT PLANNED are missing fields, asked in "Morning questions" below.

| Step | Named owner | Planned time | Exact method (where it runs, which access) | What a pass looks like | What stops the deploy |
|---|---|---|---|---|---|
| G1. Go-ahead for staging | Lead 1 | 10:00 | Comment on PR #104 on GitHub | Comment from Lead 1 present at the current head (bbb2222) | Any open Must finding |
| G2. Deploy to staging | Dev A | 11:00 | Repo deploy script, run from the shared build machine with the deploy key (fallback machine: NOT PLANNED, Q6) | Health page shows build bbb2222 and 3 sample orders listed | Health page red |
| G3. After-deploy check on staging | Dev C | NOT PLANNED (Q3) | Run the saved search query against staging (where it runs and with which access: NOT PLANNED, Q3) | NOT PLANNED (Q3): must name what it has to have seen, so an empty result cannot read as "all on" | NOT PLANNED (Q3) |
| G4. Go-ahead for production | NOT PLANNED, no name (Q2) | "this evening" is not a time (Q2) | NOT PLANNED (Q2) | NOT PLANNED (Q2) | NOT PLANNED (Q2) |
| G5. Deploy to production (Item 5) | NOT PLANNED, no row existed (Q1) | NOT PLANNED (Q1) | NOT PLANNED (Q1) | NOT PLANNED (Q1) | NOT PLANNED (Q1) |
| G6. Late-evening after-deploy check on production | NOT PLANNED, nobody named (Q4) | NOT PLANNED (Q4) | NOT PLANNED (Q4) | NOT PLANNED (Q4) | NOT PLANNED (Q4) |
| S1. Access check: sign-ins, VPN, Docker, free disk on the build machine; name the fallback machine | NOT PLANNED (Q6) | before 11:00, exact time NOT PLANNED (Q6) | NOT PLANNED (Q6) | Each item confirmed usable, fallback machine named in G2 | Any item unusable with no fallback ready |
| S2. Rehearsal of the S3 head re-check (same method, run early) | NOT PLANNED (Q7) | NOT PLANNED (Q7) | Same method as S3 | Rehearsal reads PR #104 head and review head and reports both SHAs | Method cannot read the head or the review |
| S3. Re-check just before the deploy (timer set for just before 11:00, not for the 10:00 go-ahead; repeat just before any production deploy) | NOT PLANNED (Q7) | just before 11:00 | NOT PLANNED (Q7) | PR #104 head is still bbb2222, Reviewer B's review is at that head, Lead 1's go-ahead comment is at that head, no open Must finding | Head moved since the go-ahead, or a new Must finding. Why a timer: the go-ahead only covers the head it saw |
| S4. Config change on the staging host: set NEW_SEARCH=on | NOT PLANNED (Q5) | NOT PLANNED (Q5) | NOT PLANNED (Q5) | NOT PLANNED (Q5) | NOT PLANNED (Q5) |

S4 comes from last month's checklist, so it is a claim, not a fact. It is valid only if the code on staging supports the flag. Whether bbb2222 supports NEW_SEARCH, and whether PR #104 contains PR #103 (still open), are not established. Only the owner of a host read or run can settle that (Q5). No host was read for this draft.

Known review findings on PR #104 (listed once): "slow query on empty filter", grade Should, accepted by Lead 1 in a PR comment. No new finding is recorded. PR #103: none recorded.

Read-only by default. Any server write (the staging deploy, the config change, anything on production) needs the operator's explicit approval for that specific action in the current session, with backup ZIPs of everything it touches made, confirmed non-empty and reported first. Approval for one write does not cover the next.

## Morning questions (run-sheet gaps)

1. Production deploy: who deploys, at what clock time, by which method (where it runs, with which access), what does a pass look like, and what stops it?
2. Production go-ahead: which named person, at what clock time, by what method (where it is given), what is the pass, and what stops it?
3. Staging after-deploy check (Dev C): at what time, where does the saved search query run and with which access, what must it have seen to pass (row counts or named items), and what stops the deploy?
4. Late-evening production after-deploy check: who (a late evening one needs a named owner), at what time, method, pass evidence and stop condition?
5. NEW_SEARCH=on on the staging host: who does it, when, by what method, and does the code that will run there (bbb2222, or the commit the host reports) support the flag? Does PR #104 include PR #103? This needs an owner's host check, not a read here.
6. Access for the 11:00 staging deploy: who checks sign-ins, VPN, Docker and free disk on the shared build machine, by when, and which machine is the fallback?
7. Who sets the just-before-deploy timer (S3), at what time, and who rehearses its method early (S2) and when?

## Items

Grouped by person; reviews and deploy gates first.

### Done (merged on the integration branch)
- [x] Item 1: fix the export button (PR #101). Merged, on the integration branch. Yesterday's ledger credited Dev A; not re-verified.
- [x] Item 2: update the help page (PR #102). Merged, on the integration branch. Yesterday's note "approved by Reviewer B" was not re-verified for verdict or head.

### Carried
- Reviewer B (reviews):
  - [ ] Item 3: add the search filter (PR #103). Open. Head aaa1111, CI green, no conflicts, not draft. Review by Reviewer B is approved at head aaa1111, the current head. Current review requests: not recorded.
  - [ ] PR #104 review: approved at the current head bbb2222.
- Lead 1 (gate): staging go-ahead, run-sheet row G1.
- Dev A (gate): staging deploy, row G2.
- Dev C:
  - [ ] Item 4: write the release notes. No progress evidence in the inputs.
  - [ ] Staging after-deploy check, row G3 (gaps in Q3).

### New
- [ ] Item 5: deploy Release X candidate (PR #104) to staging today, then production this evening. Run sheet above; gaps in the Morning questions.

### Parked
- None.

### Dropped
- None.

## People's feedback
- No comment or review body text was in the inputs. Slack: not checked. Production and VM state: not checked.

## Completion estimate
Formula: sum of item shares x done fraction. Change log:
- 2026-11-24: no change.
- 2026-11-25: no change. Items 1 and 2 are confirmed merged, but there is no linked evidence to change any item's share.

## SOP
- Reviews before merges. A ledger is a plan, not an approval.
````

## What this run shows (read it against the two points that were open at the review cap)

- The sheet is the first section after the goal header, six columns, gate rows G1-G6 before support rows S1-S4.
- Every incomplete gate has a question that asks for each of its missing fields: Q1 asks method, where it runs, access, pass and stop for the production deploy; Q3 asks the staging check's access along with time and pass evidence.
- The rehearsal row (S2) rehearses the same method as the timed re-check (S3), and the re-check is timed for just before the 11:00 deploy, not the 10:00 go-ahead.
- The config change copied from an older checklist is marked a claim and not planned; no host read was made.
- Not run: the no-deploy day, the cancelling reread and the step 8 validator. Those cases were exercised on the earlier wording (receipts in git history at `90c4bed52`) and the "otherwise add nothing" rule has not changed since.
