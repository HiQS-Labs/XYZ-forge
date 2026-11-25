---
title: A /yesterday-today skill that refreshes today's work ledger from verified yesterday evidence
status: In progress
created: 2026-11-25
updated: 2026-11-25
owner: Noel Saw
branch: docs/XYZ-forge-gh1601-yesterday-today-2026-11-25
gh_issue: 1601
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1601
doc_type: feature
complexity: 1
risk: 1
effort: 1
phases: 1
non_goals:
  - Scripts, helper code or a new subsystem (prompt-only skill)
  - Changing daily-planner, its engine or its Daily Work Ledger claim comments
  - Creating a missing ledger issue without operator confirmation, merging, deploying or testing anything a ledger mentions
  - Installing or deploying the skill into any Skills Army collection or app
  - Any write to a server
goal: >
  An agent asked to "update today's ledger from yesterday" follows one short skill that checks
  every claim in yesterday's ledger against GitHub, reads people's feedback, rewrites today's
  ledger body (done / carried / new / parked / dropped) without losing its goal header or
  completion estimate, and gets one independent low-effort review of the result.
---

# GH-1601 — `/yesterday-today`: refresh today's work ledger from verified yesterday evidence

## Status

| What was just completed | What's next |
|---|---|
| Issue filed, clone provisioned, plan drafted; plan QA round 1 (FAIL, 6 Should) revised. | Plan QA round 2, then write the skill, index row, smoke receipt, final QA. |

## Requirements (operator brief, 2026-11-25)

The operator's own wording of the routine, done by hand that morning: review yesterday's work ledger issue and see what was completed by everyone; confirm the findings against GitHub activity; read people's feedback on issue comments and PRs; find today's ledger issue and update it from what was completed, what carries over and what starts new today; spin up a low-effort Codex `gpt-6.2-astra` sub-agent to validate the updated ledger; keep the % completion estimate and the goal/target header in the body. The run taught nine things the skill must carry, briefly:

1. Resolve "yesterday" and "today" in the operator's local timezone (the last working day across weekends/holidays); find both issues by title and "This week's ledgers" links; if today's is missing, stop and offer to create it; never overwrite blindly (save the old body, check the live body is unchanged right before `gh issue edit --body-file`).
2. A checkbox is a claim, not evidence: verify with merged commits on the integration branch, PR reviews (verdict, reviewer, `commit_id`), and comments since local midnight; distinguish approved, merged, deployed and "approved at an older head"; reviews are only on the PR reviews endpoint; check people's own end-of-day comments.
3. Feedback: read review bodies and comments in full; extract only what changes today (findings, refusals, deploy warnings, offers, unanswered questions); optional Slack read, and say when not checked.
4. Live state of every open PR in the ledger (head, CI, conflicts, draft, requested reviewers); a throwaway-clone trial merge of the planned order shows conflicts "MERGEABLE" hides.
5. Classify every open item done / carried / new / parked / dropped; group by person, reviews and deploy gates first; a ledger is a plan, not an approval.
6. Keep the goal/target header (official count + progress bar, items list), scope rule, SOP sections and the % estimate with formula and dated change log; change a share only with linked evidence under that ledger's own rule; add a dated row even when unchanged; the header is generic, not hardcoded to one release.
7. Publish, then one independent validation by a low-effort read-only Codex `gpt-6.2-astra` sub-agent given the two issue URLs and a checklist, never the author's conclusions; verify each finding firsthand before fixing; say so if it could not run.
8. Traps: zsh does not word-split unquoted `$var` in loops; production/VM reads may need a fresh cloud login (report as not checked, never write to servers); a proxied grep can give false "0 matches"; no bare @mentions unless asking that person something; no personal emails or secrets in an issue.
9. The final chat reply is short: ledger link, what changed, validator verdict, next steps.

Constraints: check existing skills first (`daily-planner`, `daily`, `where-are-we-at`, `weekly-planner`, `todo-list`); reuse by reference; prompt-only; no new tests; plain English; repo-agnostic; about 130 lines; generic examples only.

## Rating rationale (2026-11-25)

`rated 30/10/50/85` (pri/sev/appeal/effort).

- **Severity 10.** A missing skill costs operator time and invites an unverified ledger; no data is lost or corrupted.
- **Priority 30.** Operator asked for it directly; the routine runs every working day. Not urgent: it was done by hand this morning.
- **Appeal 50.** Neutral; the operator set no appeal.
- **Effort 85.** One instruction-only `SKILL.md` and a few pointer edits; no code.
- **Recurrence.** Window 2026-11-11 to 2026-11-25 versus 2026-10-28 to 2026-11-10: one operator-run incident in the recent window (the by-hand run on 2026-11-25); earlier window unknown (no issue found by search). Trend unknown.

## Recon (base `ac0e8b65b`)

- **`daily-planner --mode ledger`** (`skills/2-daily/daily-planner/SKILL.md:128-183`, GH-1459; engine `skills/3-weekly/weekly-planner/scripts/planner_core.py`): finds "Daily Work Ledger — YYYY-MM-DD" issues by title regex in a ledger timezone, verifies per-operator claim comments by their first-line marker, carries one operator's unfinished items, calibrates checkouts. It publishes per-operator comments. Its review step covers the operator's own PRs and review requests for claims and remediation; it does **not** verify a team ledger's checkboxes against PR reviews and heads, read people's feedback, or rewrite the ledger body. It assumes that title pattern, and the engine writes `temp/planner/*` even without `--publish-ledger`. Reuse by reference: use its discovery where the repo follows it; fall back to title or "This week's ledgers" links otherwise.
- **`daily`** (Rebalance's prompt-log synthesizer, outside this repo) and **`where-are-we-at`** (topic status via recon/merge-cleanup) answer different questions; neither updates a ledger issue.
- **`weekly-planner`** owns the weekly plan and its shared engine; **`todo-list`** turns an assistant list into serial work and owns the issue closeout procedure. Neither carries yesterday-to-today ledger refresh.
- **`relay-xyz`** is the reviewer path for QA of this change; the skill's own validation step is a separate, low-effort read-only Codex review of the ledger, not a relay.
- **Registration surface** for a new skill: `ARCHITECTURE.md` Skills Index (alphabetical within tier, `2-daily`); `skills/README.md` says the index row is part of the change. `test/gh589-skill-viewer.sh` computes counts from disk, so it needs no edit.
- **Gate route.** Expected docs route (`utils/ci-route.sh`): `skills/2-daily/<name>/SKILL.md` is not on the full-gate skill list; confirm before push.
- **Worked example (read-only, external, not copied into this repo):** a team's yesterday/today ledger pair. Its target structure: goal header with official count and progress bar, scope rule, per-item list, estimate with formula and dated change log, "what yesterday finished (checked against GitHub)", "what people said that changes today", "today in order", SOP sections, by-person checkboxes (carried / new), parked list, week's ledger links.

## Preflight bet

- **Outcome sought.** The ledger refresh is repeatable and honest: every claim checked, feedback read, nothing lost, no implied approval.
- **Smallest viable bet.** One `SKILL.md` (~130 lines) that sequences existing tools (`gh`, `git`, daily-planner discovery, `relay-xyz`/Codex for validation). Not built: scripts, templates engine, scheduler, Slack integration.
- **Alternatives rejected (Mode before skill, GH-1299).** (a) A `--mode` of `daily-planner`: its ledger mode is per-operator claim comments over an engine; the body-refresh needs the verification and feedback ladder and a different publish rule (replace one issue body), so adding it to the engine would add code the operator ruled out. (b) A section in `todo-list` or `where-are-we-at`: neither owns a ledger issue; their triggers would blur. The operator also asked for a named skill.
- **Rollback.** Revert the commit; the skill is not installed anywhere by this change.

## Plan

1. **Write `skills/2-daily/yesterday-today/SKILL.md`** (about 130 lines, no code). Frontmatter `name: yesterday-today`; description with triggers ("yesterday-today", "update today's ledger from yesterday", "refresh today's work ledger") and one sentence on use versus `daily-planner` (that skill posts per-operator claim comments; this one rewrites the ledger body from verified team evidence). **Reuse by convention, not by running the engine:** the skill borrows `daily-planner`'s documented title pattern, ledger timezone idea and "lowest issue number wins among same-date duplicates" rule, and does the lookups with plain read-only `gh`. It does not run `planner_core.py --mode ledger`, because that command writes `temp/planner/*` files even without `--publish-ledger` (`planner_core.py:3299,3325-3331`) and picks the newest existing earlier ledger, not the resolved previous workday (`:2283-2300`). Steps:
   1. **Resolve dates and issues (read-only).** Today and yesterday in the operator's local timezone; on a weekend or holiday, yesterday is the last working day (check the ledger's own "This week's ledgers" links and holiday notes). Find each issue by title pattern, falling back to those links. Distinguish *confirmed absent* (a successful empty lookup) from *lookup failed or incomplete* (report "unavailable", never "missing"). If today's ledger is confirmed absent, stop and offer to create it; write nothing.
   2. **Read yesterday's ledger body and comments.** Treat every checkbox as a claim.
   3. **Verify each claim** with GitHub reads: merged commits on the integration branch; PR reviews from the reviews endpoint (verdict, reviewer, `commit_id`); comments since local midnight; people's own end-of-day comments. Label each as approved, merged, deployed or "approved at an older head". "Deployed" needs linked evidence visible in GitHub (a release, deploy comment or run); otherwise say "deployment unverified". Anything needing a production or VM read is reported "not checked"; the skill never writes to a server.
   4. **Read people's feedback in full** (review bodies, issue and PR comments); keep only what changes today. Optional Slack read; say when it was not checked.
   5. **Live state of every open PR in the ledger:** head, CI, conflicts, draft, past reviews and current review requests (reported separately). A trial merge of the planned order is done only in a throwaway local clone.
   6. **Classify** every open item done / carried / new / parked / dropped; group by person, reviews and deploy gates first. A ledger is a plan, not an approval: no wording that implies merge, deploy or test sign-off.
   7. **Rewrite today's body**, keeping the ledger's goal/target header (official count, progress bar, items list), scope rule, SOP sections and the % completion estimate with its formula, components and dated change log. A share changes only with linked evidence under that ledger's own estimate rule; add a dated row even when nothing changed. **Publish guard:** save the old body to a file; re-read the live body immediately before `gh issue edit --body-file`. Live body equals the saved one: edit. Live body changed: rebase the draft on the live text and repeat the check, or stop. Read failed: stop. Edit only after the operator's go-ahead if the invocation did not already ask for the update.
   8. **Validate once, after a confirmed write:** a low-effort, read-only Codex `gpt-6.2-astra` sub-agent is given only the two issue URLs and the checklist (never the author's conclusions) and fetches the *published* body itself. Verify each finding firsthand before fixing; if the reviewer cannot run, say "independent review did not run".
   9. **Traps and final reply.** zsh does not word-split an unquoted `$var` in a loop; expired cloud login means "not checked"; a proxied `grep` can print a false "0 matches" (use `rg` or `git grep`); no bare @mentions unless asking that person something; no personal emails or secrets in an issue. Final chat reply: ledger link, what changed, validator verdict, next steps.
2. **`ARCHITECTURE.md`:** one Skills Index row in the `2-daily` table (no other catalog pins a skill list: `skills/README.md:13`; the viewer test derives counts from disk).
3. **`CHANGELOG.md`:** only if the repo's `CHANGELOG_WRITES` mode asks for a branch write (default: skipped).
4. **Evidence** under `TESTS-RESULTS/2026-11-25+GH-1601/`: `SUMMARY.md` (smoke receipt: resolved dates, checkbox count, stop message, which read commands ran), the check logs, and `provenance.jsonl`.
5. **Final relay QA** (Codex via relay-xyz) on the implemented skill, this plan's acceptance map and the evidence, then push through the pre-push gate and open the PR against `development`.

## Acceptance

Unchanged base `ac0e8b65b` must fail each delivery assertion; each control is run and its observed output recorded.

- [ ] A1 `skills/2-daily/yesterday-today/SKILL.md` exists, is nonempty, and has frontmatter `name: yesterday-today`, the three trigger phrases and the `daily-planner` boundary sentence, in at most about 130 lines. Observation: a script prints the file's existence, line count and parsed frontmatter name; on base it prints `missing`.
- [ ] A2 Nine-point checklist: for each of the nine requirement items above, the exact line number in the skill that carries it (recorded in `SUMMARY.md`). Red control: the same checker run against a copy of the skill with one item's lines removed reports that item missing.
- [ ] A3 Privacy scan: one `rg -n -i` command with a fixed pattern list (the example repo's name, its people's logins and names, hostnames, `@` addresses) over the named deliverables (`SKILL.md`, the plan doc, `TESTS-RESULTS/2026-11-25+GH-1601/*`, the `ARCHITECTURE.md` diff) after confirming each is nonempty. Red control: the same scan over a temp copy with one planted forbidden string reports it.
- [ ] A4 `ARCHITECTURE.md` contains the exact row `| [yesterday-today](skills/2-daily/yesterday-today/SKILL.md) |` (absent on base); `test/path-integrity.sh` and `test/gh589-skill-viewer.sh` pass.
- [ ] A5 Smoke, from the consumer entry point (the skill read through its path in this clone): steps 1-2 against a real ledger pair, read-only; then step 1 against a date with a confirmed-absent ledger, which prints the offer-to-create stop. Record resolved dates, checkbox count, the stop text and the exact read commands; show a zero-write check (`git status --porcelain` clean outside `TESTS-RESULTS/`, no `gh issue edit/create` in the command log). A failed lookup must read "unavailable", not "missing".
- [ ] A6 Diff invariant on the nonempty candidate diff: changed paths are only `skills/2-daily/yesterday-today/SKILL.md`, `ARCHITECTURE.md`, the plan doc, `releases.db`/`releases.sql`, `relay-system/`, `TESTS-RESULTS/`; no path under `test/` and no `validate.sh` change (GH-831). Red control: the checker rejects a diff listing a synthetic `test/new-suite.sh`.
- [ ] A7 Delivery: final relay QA receipt committed, `provenance.jsonl` present in the evidence folder, PR base is `development`.

## Verification

Docs route (`utils/ci-route.sh`): `utils/pdda/pdda.sh run`, plus the two existing suites above, run once on the final commit. No new suite or registry entry. The checks above are manual, recorded under `TESTS-RESULTS/` with `provenance.jsonl`.

## Risks

- Wording read as permission to publish a ledger or merge/deploy → the skill says "plan, not approval" and requires the live-body re-read before any edit.
- Overlap with `daily-planner` confuses triggers → one explicit when-to-use sentence in the description.
- Reviewer model unavailable → skill says to report "validation did not run" rather than self-approve.
