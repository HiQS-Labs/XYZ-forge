---
title: Deploy-day run sheet in the /yesterday-today morning run
status: In Progress
created: 2026-11-25
updated: 2026-11-25
owner: Noel Saw
branch: docs/XYZ-forge-gh1612-run-sheet-2026-11-25
gh_issue: 1612
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1612
doc_type: feature
complexity: 1
risk: 1
effort: 1
phases: 1
non_goals:
  - Scripts, helper code, a new skill or a new subsystem (prompt-only edit of one existing skill)
  - Restating any deploy procedure (link the repo's own deploy docs instead)
  - Executing, approving or scheduling any deploy step, or any server access
  - Installing or deploying the skill
goal: >
  On a deploy day, the morning ledger refresh puts one run sheet at the top of today's ledger:
  one row per step, gates first, each with a named owner, a planned time, an exact method,
  what a pass looks like and what stops the deploy. Gates missing any of these become
  questions. On a day with no deploy the skill adds nothing.
---

# GH-1612 — Deploy-day run sheet in `/yesterday-today`

## Status

| What was just completed | What's next |
|---|---|
| Intake, rating and this plan written. | Codex plan QA (relay-xyz), then the edit, smoke, final QA, one push. |

## Requirement (operator brief, 2026-11-25)

"Add the short run sheet for any deploy day every morning." Seven lessons, encoded briefly and generically:
(1) a gate with no owner, time and method is a morning question, not prose, including who deploys, who gives the go-ahead and when, and who does after-deploy checks (also a late-evening one);
(2) test each step against the real code and target environment first, and a step from an older checklist is a claim;
(3) check access early (sign-ins, VPN, Docker, disk) and name the fallback machine;
(4) a pass is evidence, not absence;
(5) some checks only count right before the deploy, so use a timer and rehearse the method early;
(6) known review findings per included PR are listed once with grade and who accepted them, and a new finding is first compared with earlier reviewer views;
(7) read-only by default, the sheet is a plan and never an approval, server writes need explicit per-action approval and backups first.

Constraints: about 20 to 30 added lines, file under about 140 lines, plain English, repo-agnostic, generic examples only, no client, product, people, host or private-link names, no new tests or scripts (GH-831), one validator-checklist line in step 8.

## Rating rationale (2026-11-25)

`rated 30/10/50/90` (pri/sev/appeal/effort).

- **Severity 10.** Without it the skill still works; the cost is deploy gates left as prose. No data is lost.
- **Priority 30.** Direct operator ask, used on deploy mornings; not urgent.
- **Appeal 50.** Neutral; none supplied.
- **Effort 90.** About 30 added lines in one `SKILL.md`.
- **Recurrence.** Windows 2026-11-11 to 2026-11-25 versus 2026-10-28 to 2026-11-10: one operator-reported incident class (an unplanned gate found on a deploy day); the earlier window is unknown. Trend unknown.

## Recon (base `b479f74e0`)

- **Subsystem extended:** `skills/2-daily/yesterday-today/SKILL.md` (107 lines, merged in PR #1602). Its morning flow is steps 1-9; step 5 already collects the live state of every open PR in the ledger, step 7 writes today's body, step 8 holds the validator checklist (items 1-5).
- **Existing deploy docs:** deploy procedure belongs to each target repo's own docs; the skill links them by reference and names the step. No deploy procedure is restated.
- **Overlap:** `daily-planner` (per-operator claim comments) and `todo-list` do not own a deploy run sheet; nothing similar exists (`prior_art_recon.py` found only this issue).
- **Registration:** the `ARCHITECTURE.md` Skills Index row for `yesterday-today` stays accurate; no catalog edit.
- **Gate route:** a single `skills/2-daily/*/SKILL.md` edit plus docs is the docs route (`utils/ci-route.sh`), confirmed before the push.

## Preflight bet

- **Outcome sought.** Deploy-day gates are planned or loudly flagged each morning, and a "pass" always carries evidence.
- **Smallest viable bet.** A new step 5a (about 25 lines) between "live state of every PR" and "classify", one sentence in step 7 putting the sheet first, one validator line in step 8. Not built: a template file, a script, a deploy checker.
- **Alternatives rejected.** A separate `/deploy-day` skill (the trigger is the morning ledger refresh and a second skill would split it); a template file (more surface than prose rows).
- **Rollback.** Revert the commit; the skill is not installed by this change.

## Plan

1. Edit `skills/2-daily/yesterday-today/SKILL.md`: add step `5a. Deploy-day run sheet` with the six row columns and the seven lessons as short bullets; add "run sheet first" to step 7; add one validator line (item 6) to step 8. Keep numbering of steps 6-9 unchanged. Trim elsewhere if the file would pass about 135 lines.
2. Smoke (GH-1088), from the consumer entry point: read the skill through its path in this clone and dry-run step 5a read-only against two fictional ledgers, one with a planned deploy (expect one run sheet, gates first, an ownerless gate raised as a question) and one without (expect nothing added). Record under `TESTS-RESULTS/2026-11-25+GH-1612/`.
3. Final relay QA (Codex via relay-xyz), then the single push through the pre-push gate (attempt budget 2, reserved) and PR against `development`.

## Draft wording (step 5a, to be inserted after step 5)

```
## 5a. Deploy-day run sheet (only when a deploy is planned today)

Applies when yesterday's or today's ledger, or a linked deploy checklist, plans a deploy today.
If none does, add nothing. The sheet is the first section of today's body (step 7). Link the
repo's own deploy docs and name the step; do not restate a deploy procedure.

One row per step, gates first (go-ahead, deploy, after-deploy checks): step | named owner |
planned time | exact method (where it runs, with which access) | what a pass looks like |
what stops the deploy.

- A gate with no owner, time and method is not planned. Ask it as a morning question, never carry
  it as prose. That includes who deploys, who gives the go-ahead and when, and who does the
  after-deploy checks (a late-evening one too).
- Test each step against the real code and the target environment before writing it. Example: a
  config change on a staging host is valid only if the code running there supports it (read that
  host's recorded commit). A step copied from an older checklist is a claim, not a fact.
- Check access early (sign-ins, VPN, Docker, free disk) and name the fallback machine in the row.
- A pass is evidence, not absence: each check says what it must have seen (row counts, named
  items), so a query that matched nothing cannot read as "all on".
- Some checks only count right before the deploy. Put a timer on them and say why in the row,
  and rehearse the method early.
- List known review findings on every included PR once, with grade and who accepted each. A new
  finding: first see whether a reviewer already considered it.
- Read-only by default. The sheet is a plan, never an approval: a server write needs the
  operator's explicit approval for that action, with backups first.
```

Step 7 gains one clause ("a run sheet from step 5a goes first"). Step 8 gains item 6: "If a deploy is planned, is the run sheet first, one row per step with owner, time, method, pass evidence and stop condition, ownerless gates asked as questions, and no approval implied? On a no-deploy day, was nothing added?"

## Acceptance

Unchanged base `b479f74e0` must fail each assertion; the control is recorded.

- [ ] A1 Run sheet text: the skill contains step 5a with all six columns, "gates first", the no-deploy "add nothing" rule, and one bullet per lesson 1-7 (checker prints line numbers). Red control: base prints missing; a copy with the lesson-4 bullet removed reports it missing.
- [ ] A2 Size and shape: added lines within 20-30 (plus the two small edits), file under about 140 lines, steps 6-9 keep their numbers, step 8 has a run-sheet line. Red control: base shows 107 lines and no run-sheet line.
- [ ] A3 Privacy scan: one fixed-pattern `rg -n -i` over the skill, this plan and the evidence folder (client, product, people, host names, emails, private links), after confirming each is nonempty. Red control: a planted string is found.
- [ ] A4 Smoke: with-deploy dry-run yields one sheet with gates first and the ownerless gate as a question; without-deploy dry-run adds nothing; zero writes (`git status --porcelain` clean outside `TESTS-RESULTS/`, no `gh` write in the log).
- [ ] A5 Diff invariant: changed paths limited to the skill, this plan, `releases.db`/`releases.sql`, `relay-system/`, `TESTS-RESULTS/`; no `test/` path (GH-831).
- [ ] A6 Delivery: final QA receipt committed, PR base `development`.

## Verification

Docs route: `utils/pdda/pdda.sh run` and `ci-local.sh --fast` on the final approved commit, then the one push (hook decides the route). No new suite or registry entry; checks are manual and recorded under `TESTS-RESULTS/` with provenance.

## Risks

- A sheet read as a go-ahead → the text says "plan, never an approval" and server writes need per-action approval and backups first.
- The file grows past its size budget → trim existing prose, not the new rows.
