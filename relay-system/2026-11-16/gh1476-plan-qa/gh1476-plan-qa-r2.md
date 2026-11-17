# RELAY · GH-1476 OL-09 plan QA round 2
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-16.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(gh1476-plan-qa-r2): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1476-RAW-TASK-PREPARATION.md` revised at `c9168dc77` (round-1 reviewed `b76b62b1`; `git diff 8293b014 c9168dc77` touches only this plan). This is a PLAN review, round 2 of 3 total plan-review rounds. No source has been written; the plan must be approved before implementation.
- Round 1 (FAIL, preserved, do not edit): `relay-system/2026-11-16/gh1476-plan-qa/gh1476-plan-qa.md` Reviewer · Round 1 block (B1, S1-S6, N1-N3) and orchestrator notes `PRIMARY-PLAN-QA.md`. The plan's own dispositions are its section `## Round 1 dispositions and falsifying scenario matrix`; the Producer did not append a block to the round-1 thread, so grade the revised plan text itself.
- Reviewer: claude-review (same-provider Claude subscription route, one review turn, read-only)   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: the revised plan is a coherent, proof-honest, minimal instruction-only slice for OL-09 (umbrella #1400) that resolves round-1 B1 and S1-S6 without contradicting live consumer lines, does not claim OL-10 runtime admission or OL-09 operational verification, and keeps #1400's OL-09 checkbox unchecked.

### Operational envelope and non-goals

Local developer harness; instruction (SKILL.md prose) changes only. Out of scope and themselves findings if the plan requires them: new test suites or `validate.sh` entries (GH-831), runtime code, new schema/queue/state/readiness database, daemon, installed-skill mutation, amendment of #1328, numeric global research ceilings, live backlog execution. Reject speculative enterprise machinery. Scope is the needed minimal changes, not a rewrite of 10days.

### Files to read (all at the committed head)

- The plan, in full, and the round-1 thread block and `PRIMARY-PLAN-QA.md` above.
- `skills/1-hourly/conveyor/SKILL.md` (whole file, 71 lines).
- `skills/3-weekly/10days/SKILL.md` (whole file, 571 lines).
- `skills/2-daily/jog/SKILL.md` `## Preparation handoff (GH-1439)`; `skills/2-daily/flywheel/SKILL.md` where it references 10days/Jog.
- `skills/1-hourly/start-task/SKILL.md` `## Task rating policy`.
- `decisions/2026-11-04-gh1333-closure-appeal-row-at-start.md` (D-b / G6b); `PROJECT/PDDA.md` near lines 261 and 291.
- Optional, if `gh` works: `gh issue view 1476` and `gh issue view 1400 -R HiQS-Labs/XYZ-forge`. If it does not, say so; the orchestrator already read #1400 OL-09 = "Raw intake and research policy are implemented and verified".

### Questions

1. Round-1 closure: for each of B1, S1, S2, S3, S4, S5, S6 (and N1-N3), state Resolved / Partly / Not resolved with the revised plan line that resolves it. Re-run the B1 sweep: after plan:39's widened edit list, does any live 10days or Conveyor line still route an unknown, held or low-risk item to EXCLUDE or silent drop? Check 10days:73-75, 220, 232, 244, 253-254, 264, 288, 316-320, 389-393, 401, 430, 545-546 and Conveyor whole-file. Cite `file:line`.
2. Daily-goal ownership: plan:23 says "Conveyor owns explicit issue/daily-goals intake" and holds unlinked goals. Is that grounded in a live Conveyor line, or does the slice add a new Conveyor intake rule? Is it consistent with conveyor:19 (`No synthetic backlog`, one clarification) and conveyor:23 (`/idea`)? Is "daily-goals issue" defined precisely enough that an implementer cannot invent a new intake surface or issue-creation authority?
3. Selected-before-research primary write: plan:39 moves the committed-selection write to "before research dispatch" in Step 4 and rewords Conveyor Step 4 pickup as "committed preparation selection before dispatch per #1328". Is that consistent with D-b/G6b (decision:8, selection = commitment to an actual execution batch), with 10days:393 (pickup so `marathon-plan.sh` discovers rows in Step 5), and with the non-goal "no #1328 amendment"? Is the Step 3 `roadmap rate`/`--force` write (10days:253-254) unambiguously removed? Walk an unrated candidate EXCLUDEd/HELD at Step 3 and an INCLUDEd one to Step 5: expected zero writes for the first, a row before `marathon-plan.sh --write --deep` for the second.
4. Read-only child restriction: does plan:39 fence research children off from Conveyor Steps 3-6 (capture publication, pickup, preparation PR, marker comment, label) and from ledger writes, and name the parent as the sole advancer? Can a child that "follows the canonical Conveyor policy" still reach a write step?
5. Medium / deep / reuse / deferral: are (a) the medium default for selected unprepared work, (b) deepen triggers (no numeric global caps), (c) freshness reuse vs 10days Step 5 `--deep`, and (d) explicit batch-scoped risk deferral each concrete enough that an implementer cannot research the whole window, skip research, collide "deep" terminology, or apply deferral implicitly? Does "Do not repeat medium research already evidenced by Step 3" reopen S1's ambiguity (is the Step 3 validity subagent now a research child or not)? Is S4's budget record (parent selection/recon note) an existing record or new machinery?
6. Scenario falsifiers: plan:47 requires each row to name the old instruction giving the wrong result, the revised owner/line and the expected output, but the table at plan:49-62 has two columns. For every row, is there a concrete red control (old `file:line`) that the unchanged text fails and the revised text would pass? Name each row lacking one, and any round-1 S6 scenario (f)-(j) missing. Does any row pass on unchanged text (invalid red control)?
7. OL-09 remains unchecked: does plan:40 (and plan:62, 72-73) unambiguously forbid ticking #1400 OL-09 on this PR, with no conditional path to tick from paper evidence alone? Any wording implying OL-10 admission refusal is implemented?
8. Ratings: does the revision cover 10days:232 (malformed `ovr` at Step 2), 250 (appeal from clarity), 253 (`--force` clear), 316-320 (editable `rating_ovr` frontmatter vs start-task:410 read-back only), consistent with start-task's rating policy?
9. Over-engineering / missing: flag ceremony or new machinery introduced by the revision, and anything still missing for a minimal correct slice.

Grade each finding `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`, cite `file:line` or a quoted span, and include `Observed input:` / `Affected scope:` / `Falsifier:` for any finding requesting a change. End with `VERDICT: PASS|FAIL|PARKED` and a non-empty `Basis:`. Include `swept file: yes|no`. Set `STATUS: Approved` only on PASS. Do not edit the plan, the round-1 thread or any source; append only to this file.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
