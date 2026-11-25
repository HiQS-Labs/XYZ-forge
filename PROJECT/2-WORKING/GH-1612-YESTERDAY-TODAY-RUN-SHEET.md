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
2. Smoke (GH-1088): run the full drafting flow of A4 below, from the consumer entry point, on fictional ledgers; record under `TESTS-RESULTS/2026-11-25+GH-1612/`.
3. Final relay QA (Codex via relay-xyz), then the single push through the pre-push gate (attempt budget 2, reserved) and PR against `development`.

## Draft wording (step 5a, to be inserted after step 5)

```
## 5a. Deploy-day run sheet (only when a deploy is planned today)

Applies when yesterday's ledger, today's ledger or a linked deploy checklist plans a deploy
today; otherwise add nothing. Read today's side from the same first read of today's body that
step 7 uses as its baseline, and recompute if step 7 redrafts from a newer read. The sheet is
the first section of today's body. Link the repo's deploy docs; do not restate a procedure.

One row per step, gates first (go-ahead, deploy, after-deploy checks): step | named owner |
planned time | exact method (where it runs, with which access) | what a pass looks like |
what stops the deploy.

- A gate missing any field (above all owner, time or method) is not planned. Ask it as a morning
  question, never carry it as prose: who deploys, who gives the go-ahead and when, who does the after-deploy checks
  (a late-evening one too).
- Check each step against the real code and the target environment using what is recorded: the
  repo, the PR, a deploy log. Example: a staging config change is valid only if the code running
  there supports it; that host's recorded commit says what runs. A step copied from an older
  checklist is a claim, not a fact. If only a read or run on the host could settle it, ask it as
  a question and plan it as an owner's step; this skill makes no host read.
- Check access early (sign-ins, VPN, Docker, free disk) and name the fallback machine in the row.
- A pass is evidence, not absence: each check says what it must have seen (row counts, named
  items), so a query that matched nothing cannot read as "all on".
- Some checks only count right before the deploy. Put a timer on them and say why in the row;
  plan an early rehearsal of the method as its own row.
- List known review findings on every included PR once, with grade and who accepted each. A new
  finding: first see whether a reviewer already considered it.
- Read-only by default. The sheet is a plan, never an approval: any later server write needs the
  operator's explicit approval for that action, with backups made first.
```

Step 7 gains one clause ("a run sheet from step 5a goes first and is recomputed on a redraft"). Step 8 gains item 6: "If a deploy is planned, is the run sheet first, one row per step with owner, time, method, pass evidence and stop condition, gates missing a field asked as questions, and no approval implied? On a no-deploy day, was nothing added?"

## Acceptance

Feature checks fail on the unchanged base `b479f74e0`; safeguards (A3, A5, A6) are shown with a controlled bad input. All manual, recorded under `TESTS-RESULTS/` (GH-831).

- [ ] A1 Content: the skill has step 5a with all six columns, "gates first", the no-deploy "add nothing" rule, the today's-body baseline sentence, one bullet per lesson 1-7, and step 8 item 6; checker prints line numbers. Base prints missing for each. Control: a copy with the lesson-4 bullet removed reports it missing.
- [ ] A2 Size and numbering: measured added lines from `git diff --numstat` are within 20-30 for step 5a plus the two small edits, the file is under about 140 lines, and the step headings 1-9 still carry their numbers. Base: 107 lines, no 5a.
- [ ] A3 Privacy: one fixed-pattern `rg -n -i` (client, product, host, email, private-link shapes) plus a manual look for proper names over the skill and the evidence folder, each confirmed nonempty; the plan file is scanned separately and its required `owner` field is listed as project metadata, not a finding. Controls: a planted fictional token and a planted person-name example are both caught; a generic role label passes.
- [ ] A4 Smoke, from the consumer entry point (the skill read through its path in this clone), fictional ledgers, read-only; the whole proposed body is captured and nothing is published. Three drafts: (a) yesterday silent, today's first body plans a deploy with one complete gate, one gate with an owner but no planned time, and one gate with no owner: expect exactly one six-column sheet first, gates first, a morning question for each incomplete gate, the goal header intact; (b) the same case after a simulated guarded reread whose live body cancels the deploy: expect no sheet, header intact; (c) a no-deploy day: expect zero run-sheet output. Replay the base skill on (a) and witness no sheet. Action log shows no `gh` write and no host or deploy operation; checkout state checked separately (`git status --porcelain` clean outside `TESTS-RESULTS/`).
- [ ] A5 Diff invariant: changed paths limited to the skill, this plan, `releases.db`/`releases.sql`, `relay-system/`, `TESTS-RESULTS/`, and the skill diff must be nonempty. Controls: a synthetic `test/new-suite.sh` is rejected, an empty skill diff is rejected.
- [ ] A6 Delivery: a final-QA receipt for the delivered revision is committed and the opened PR's actual base is `development`. Controls: a missing receipt and a wrong-base value are each rejected by the same check.

## Verification

Docs route: `utils/pdda/pdda.sh run` and `ci-local.sh --fast` (a local check only: it skips the suite and keeps no qualifying gate record) on the final approved commit, then the one push, whose hook decides the real route from the changed paths. No new suite or registry entry; checks are manual and recorded under `TESTS-RESULTS/` with provenance.

## Risks

- A sheet read as a go-ahead → the text says "plan, never an approval" and server writes need per-action approval and backups first.
- The file grows past its size budget → trim existing prose, not the new rows.
