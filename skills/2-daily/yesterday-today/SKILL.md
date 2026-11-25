---
name: yesterday-today
description: >-
  Refresh today's planned-work ledger (one GitHub issue per working day) from yesterday's
  ledger, after checking every claim in it against GitHub. Reads yesterday's ledger, verifies
  what was really merged, reviewed or approved, reads people's feedback on issues and PRs,
  rewrites today's ledger body (done / carried / new / parked / dropped) while keeping its goal
  header and % completion estimate, then gets one independent low-effort review. Use for
  "yesterday-today", "update today's ledger from yesterday", "refresh today's work ledger".
  Use daily-planner instead to post your own claim comment on a "Daily Work Ledger" issue
  (per-operator, never rewrites the body); use this skill to rewrite the shared ledger body.
metadata:
  argument-hint: "[repo] [today's ledger issue URL, if the title search will not find it]"
---

# /yesterday-today: refresh today's ledger from verified yesterday evidence

A ledger is a plan, not an approval. This skill never merges, deploys, tests or writes to a
server, and nothing it writes may imply that someone signed off. Reads are free; the one write
is the body edit in step 7. Where the repo uses [`daily-planner`](../daily-planner/SKILL.md)'s
"Daily Work Ledger" issues, reuse its conventions (exact title pattern, shared ledger timezone,
lowest issue number wins among same-date duplicates) with plain read-only `gh`. Do not run
its engine: it writes `temp/planner/*` and picks the newest earlier ledger, not yesterday.

## 1. Resolve the dates and both issues (read-only)

- Today is the operator's local date. Yesterday is the latest working day strictly before it
  (Monday reads Friday; a holiday or day off shifts it again).
- Find each issue by the repo's ledger title convention (`daily-planner`'s `Daily Work Ledger — YYYY-MM-DD`
  or the team's own), then by the ledger's own "This week's ledgers" links.
- Confirmed absent (a successful empty lookup) is different from lookup failed or incomplete:
  report the second as "unavailable", never "missing".
- Today's ledger lookup unavailable: stop before drafting, report it as unavailable, make no
  offer to create it (it may exist).
- Today's ledger confirmed absent: stop, offer to create it, write nothing.
- Yesterday's ledger absent or unavailable: stop before drafting and name the gap. Never treat
  yesterday as empty or quietly use an older issue.

## 2. Read yesterday's ledger

Read its body and every comment. Every checkbox is a claim, not evidence. List the claims.

## 3. Verify each claim against GitHub

- Merged commits on the integration branch (not just "PR closed").
- PR reviews from the reviews endpoint, not issue comments: verdict, reviewer and `commit_id`.
  The PR's overall approved flag can be for an older head than the current one.
- Comments since local midnight, including people's own end-of-day progress comments.
- Label each claim: approved, merged, deployed, or "approved at an older head". "Deployed"
  needs evidence visible in GitHub (release, deploy comment, run), and the ledger
  links it; otherwise write "deployment unverified". Anything that would need a production or
  VM read is "not checked" (an expired cloud login is the usual reason). Never write to a server.

## 4. Read people's feedback

Read review bodies, issue comments and PR comments in full. Keep only what changes today's work:
findings, refusals, warnings for a deploy, offers, questions nobody has answered. A Slack read is
optional and only if a connector is available; say in the ledger when it was not checked.

## 5. Live state of every open PR in the ledger

Head SHA, CI, conflicts, draft state, past reviews and current review requests (report these
separately). To see conflicts that "mergeable" hides, trial-merge the planned merge order in a
throwaway local clone, never in a working checkout.

## 5a. Deploy-day run sheet (only when a deploy is planned today)

Applies when yesterday's ledger, today's ledger or a linked deploy checklist plans a deploy
today; otherwise add nothing. The sheet is the first section of today's body, read from step 7's
baseline and recomputed if step 7 redrafts. Link the repo's deploy docs; do not restate a procedure.

One row per step, six columns: step | named owner | planned time | exact method (where it runs, with
which access) | what a pass looks like | what stops the deploy. Gate rows first (go-ahead, deploy,
after-deploy checks), then support rows (access, rehearsal, config), each in time order.

- A gate missing any field (above all owner, time or method) is not planned. Ask it as a morning
  question, never carry it as prose: who deploys, who gives the go-ahead and when, who does the
  after-deploy checks (a late-evening one too).
- Check each step against the real code and target environment using what is recorded (repo, PR,
  deploy log). Example: a staging config change is valid only if the code running there supports it
  (the host's recorded commit says what runs). A step from an older checklist is a claim, not a
  fact. If only a host read or run could settle it, ask it as an owner's step; no host read here.
- Check access early (sign-ins, VPN, Docker, free disk) and name the fallback machine in the row.
- A pass is evidence, not absence: each check says what it must have seen (row counts, named
  items), so a query that matched nothing cannot read as "all on".
- Some checks only count right before the deploy. Put a timer on them and say why in the row;
  plan an early rehearsal of the method as its own row.
- List known review findings on every included PR once, with grade and who accepted each. A new
  finding: first see whether a reviewer already considered it.
- Read-only by default. The sheet is a plan, never an approval: any later server write needs the
  operator's explicit approval for that action, with backups made first.

## 6. Classify and order

Every open item becomes exactly one of: done, carried, new, parked, dropped. Nothing is lost.
Group by person, with reviews and deploy gates first. Word items as work to do, not as approvals.

## 7. Rewrite today's body, then publish with a guard

- The first successful read of today's body is both the saved baseline (write it to a file) and
  the source of the draft. Keep the ledger's goal/target header (official count, progress bar,
  items list), scope rule, SOP sections and the % completion estimate with its formula,
  components and dated change log. The header is whatever this ledger uses; do not assume a
  release name. Change an item's share only with linked evidence, under that ledger's own
  estimate rule, and add a dated change-log row even when nothing changed. The 5a run sheet goes first.
- Immediately before `gh issue edit <n> --body-file <file>`, re-read the live body. Same as the
  baseline: edit. Changed: use the new read as baseline and draft source, redraft, check again,
  or stop. Read failed: stop. Never overwrite blindly. Confirm the edit with a read-back.
- Publishing changes a shared issue: do it when the invocation asked for the update; otherwise
  show the draft and get the operator's go-ahead first.

## 8. One independent validation

After a confirmed write, start one low-effort, read-only Codex `gpt-6.2-astra` sub-agent. Give it
only the two issue URLs and this checklist, never your conclusions; it fetches the published
body itself:

1. Is each "done" item backed by merged work, and each approval tied to the right head?
2. Is anything from yesterday lost (every open item done, carried, new, parked or dropped)?
3. Does today's feedback list match what people actually wrote?
4. Are the goal header, scope rule, SOP sections and estimate (formula, change log) intact?
5. Does any wording imply a merge, deploy or test sign-off?
6. Deploy day: run sheet first, six columns, gates first, any gate missing a field asked as a
   question? No deploy: nothing added?

Verify each finding firsthand before changing anything. If the reviewer could not run, say
"independent review did not run" and give the reason; do not substitute a self-review.

## 9. Traps and the reply

- zsh does not word-split an unquoted `$var` in a loop; use arrays or `while read`.
- A proxied `grep` can print a false "0 matches" (GNU-only flags are dropped); use `rg` or
  `git grep` and treat an unexplained zero as unconfirmed.
- No bare @mentions unless the ledger is asking that person something; no personal emails,
  tokens or other secrets in an issue.
- Final chat reply, short: ledger link, what changed, validator verdict, next steps.
