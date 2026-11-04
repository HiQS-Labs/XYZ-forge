# RELAY · GH-1341 plan QA: todo-list + start-task issue closeout
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-04.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1341-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh1341-plan-qa.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-04

### Artifact — gh1341-plan-qa.md
```
# GH-1341 plan QA packet

Goal: review the PLAN in `PROJECT/2-WORKING/GH-1341-TODO-LIST-CLOSEOUT.md` (read it in full) before
any skill text is written. Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1341 (body + the
2026-11-04 scope-addition comment, both summarised in the plan).

Operational envelope: two Markdown skill instruction files read by a single agent session
(Claude Code / Codex / Cowork / plain chat). No script, helper, test, or gate is being added
(AGENTS.md "No new tests", GH-831). Grade against the stated requirements and commensurate
complexity; do not ask for enterprise machinery, new tooling, or tests.

Files to read:
- PROJECT/2-WORKING/GH-1341-TODO-LIST-CLOSEOUT.md (the plan)
- skills/2-daily/todo-list/SKILL.md (all of it; sections 0-3, note the section 2 wake prompt and section 3 step 4)
- skills/1-hourly/start-task/SKILL.md (Step 9, "Open or update the ready PR and hand off", and the "Skipped independent review" note)
- skills/1-hourly/handsfree/SKILL.md (only to confirm the plan does not change it)
- utils/ci-route.sh around line 336 (full-gate Markdown surfaces)

Questions:
1. Does the plan cover every ask in the issue: trigger points (normal end AND halts), touched-issue
   scope with owner/repo#N, comment content, marker idempotency (edit on rerun), tier behaviour
   (A/B gh + URLs in note, C render in chat), never close/relabel, URLs in final checklist,
   frontmatter description?
2. Is the claim that run end is defined in TWO places (section 3 step 4 and the section 2 wake
   prompt) correct, and are both covered? Any other run-end path missed?
3. Are the gh primitives correct and sufficient (list comments with --paginate and a marker
   match, create via `gh issue comment -R --body-file`, edit via `gh api -X PATCH
   repos/O/R/issues/comments/ID -F body=@F`)? Any quoting/encoding trap worth one line in the skill?
4. Start-task reuse: is "defined once in todo-list section 4, start-task Step 9 names its own marker
   and timing" a sound DRY split, or should the canonical text live in start-task instead? Is the
   nested-run rule (todo-list skips an issue already closed out by a nested start-task in the same run)
   correct and sufficient to avoid double comments?
5. Is the gate route right (docs -> `utils/pdda/pdda.sh run`; neither file is a full-gate surface)?
6. Is the smoke check (read-only marker lookup on #1341: empty -> create branch; after a closeout
   exists -> edit branch) adequate for a docs-only change? Anything over- or under-built?
7. Is the rating 55/35/50/90 (pri/sev/appeal/effort) grounded? appeal must stay 50 (neutral).

Flag anything wrong, missing, mis-scoped or over-engineered, with file:line citations. Set STATUS
Approved if the plan is fit to implement.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
