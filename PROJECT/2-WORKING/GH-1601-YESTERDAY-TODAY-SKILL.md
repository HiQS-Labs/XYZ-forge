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
| Issue filed, clone provisioned, plan drafted. | Plan QA (Codex via relay-xyz), then write the skill, index row, changelog, smoke receipt. |

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

- **`daily-planner --mode ledger`** (`skills/2-daily/daily-planner/SKILL.md`, "Daily Work Ledger", GH-1459): finds "Daily Work Ledger — YYYY-MM-DD" issues by title regex in a ledger timezone, verifies per-operator claim comments by their first-line marker, carries one operator's unfinished items, calibrates checkouts. It publishes per-operator comments. It does **not** verify checkbox claims against PR reviews, read people's feedback, or rewrite the ledger body, and it assumes that title pattern. Reuse by reference: use its discovery where the repo follows it; fall back to title or "This week's ledgers" links otherwise.
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

1. **Write `skills/2-daily/yesterday-today/SKILL.md`** (extends no code; reuses `daily-planner` ledger discovery by reference). Frontmatter `name: yesterday-today`; description with triggers ("yesterday-today", "update today's ledger from yesterday", "refresh today's work ledger") and the when-to-use-versus-`daily-planner` sentence. Steps, each short:
   1. Resolve yesterday and today in the operator's local timezone (last working day on weekends/holidays); find both ledger issues; stop and offer to create a missing today ledger.
   2. Read yesterday's ledger and its comments. Treat every checkbox as a claim.
   3. Verify each claim: merged commits on the integration branch, PR reviews (verdict, reviewer, `commit_id`, from the reviews endpoint), comments since local midnight, people's own end-of-day comments. Label approved / merged / deployed / approved at an older head.
   4. Read feedback in full (reviews, issue and PR comments); keep only what changes today's work. Optional Slack read; say when not checked.
   5. Live state of every open PR in the ledger (head, CI, conflicts, draft, reviewers); throwaway-clone trial merge of the planned order.
   6. Classify every open item done / carried / new / parked / dropped; group by person, reviews and deploy gates first; a ledger is a plan, not an approval.
   7. Rewrite today's body keeping the goal header, scope rule, SOP sections and % estimate with formula and dated change log (change a share only with linked evidence; add a dated row even when unchanged). Save the old body; re-read the live body immediately before `gh issue edit --body-file`.
   8. One independent validation by a low-effort read-only Codex `gpt-6.2-astra` sub-agent given the two issue URLs and the checklist, never the author's conclusions; verify each finding firsthand; say so if it could not run.
   9. Traps and the short final reply.
2. **`ARCHITECTURE.md`:** one Skills Index row in the `2-daily` table.
3. **`CHANGELOG.md`:** only if the repo's `CHANGELOG_WRITES` mode asks for a branch write (default `off`/`landing`: skipped).
4. **Smoke receipt** under `TESTS-RESULTS/2026-11-25+GH-1601/`: read the skill from its consumer entry point and dry-run steps 1–2 read-only against a real ledger pair; no private content.

## Acceptance

- [ ] A1 `skills/2-daily/yesterday-today/SKILL.md` exists, `name: yesterday-today`, under ~130 lines, with the triggers and the daily-planner boundary sentence. Red control: `ls skills/*/yesterday-today` is empty on base `ac0e8b65b`.
- [ ] A2 Each of the nine lessons in the issue brief appears as a step or trap (checked by reading the file against a list, recorded in the receipt). Red control: base has no such file.
- [ ] A3 The file has no client names, people's names, hostnames, emails or private details (`git grep -n -i` over the new files for the example repo's name, its logins and its host names returns nothing; `rg` used, not GNU-only flags).
- [ ] A4 `ARCHITECTURE.md` lists `yesterday-today`; `test/path-integrity.sh` and `test/gh589-skill-viewer.sh` pass; docs gate `utils/pdda/pdda.sh run` has zero errors.
- [ ] A5 Smoke, main path: from the consumer entry point (`skills/2-daily/yesterday-today/SKILL.md` through the clone), steps 1–2 resolve both example issues and list yesterday's checkboxes read-only. Adjacent path: a missing-today case (a date with no ledger) stops with the offer-to-create message and writes nothing.
- [ ] A6 No new test file or registry entry in the diff (GH-831).

## Verification

Docs route only: `utils/pdda/pdda.sh run`, plus the two existing suites above run once. No new suite. Smoke is a manual check under `TESTS-RESULTS/`.

## Risks

- Wording read as permission to publish a ledger or merge/deploy → the skill says "plan, not approval" and requires the live-body re-read before any edit.
- Overlap with `daily-planner` confuses triggers → one explicit when-to-use sentence in the description.
- Reviewer model unavailable → skill says to report "validation did not run" rather than self-approve.
