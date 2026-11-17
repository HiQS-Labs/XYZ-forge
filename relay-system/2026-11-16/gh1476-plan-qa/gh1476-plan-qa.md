# RELAY · GH-1476 OL-09 plan QA
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
6. **Commit only the relay file** (`relay(gh1476-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1476-RAW-TASK-PREPARATION.md` (committed at `b76b62b1e02ce6c398e30a1975e1262015f8e226`). This is a PLAN review: no source has been written yet; the plan must be approved before implementation.
- Reviewer: claude-review (same-provider Claude subscription route, one review turn, read-only)   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: the plan is a coherent, proof-honest, minimal instruction-only slice for OL-09 (umbrella #1400 criterion OL-09) that can be implemented without contradicting live consumer lines, and that does not claim OL-10 runtime admission or OL-09 operational verification.

### Operational envelope and non-goals

Local developer harness; instruction (SKILL.md prose) changes only. Out of scope and themselves findings if the plan requires them: new test suites or `validate.sh` entries (GH-831), runtime code, new schema/queue/state/readiness database, daemon, installed-skill mutation, amendment of #1328, numeric global research ceilings, live backlog execution. Reject speculative enterprise machinery. Scope is the needed minimal changes, not a rewrite of 10days.

### Files to read (all at the committed head)

- The plan above, in full.
- `skills/1-hourly/conveyor/SKILL.md` (whole file, 71 lines).
- `skills/3-weekly/10days/SKILL.md` (whole file; Guardrails, Steps 2, 3, 4, 5, 6, 8 matter most).
- `skills/2-daily/jog/SKILL.md` section `## Preparation handoff (GH-1439)`; `skills/2-daily/flywheel/SKILL.md` where it references 10days/Jog.
- `skills/1-hourly/start-task/SKILL.md` section `Task rating policy`.
- `decisions/2026-11-04-gh1333-closure-appeal-row-at-start.md` (D-b / G6b: what "selection" means for ledger row creation); `PROJECT/PDDA.md` lines near 261 and 291.
- Optional, read-only, if `gh` works: `gh issue view 1476 -R HiQS-Labs/XYZ-forge` and `gh issue view 1400` (OL-09 / OL-10 rows and the "Current execution alignment" table).

### Questions

1. Does the plan correctly accept RAW requests? Identify which existing entry point(s) a "raw daily-goal" request actually enters through in source (10days Step 1 scan, Conveyor issue IDs, anything else). Is "daily-goal intake" grounded in a real source owner, or is the term undefined for implementation?
2. Medium research default: in 10days, where exactly would the default read-only research child run relative to Step 3's existing subagent fan-out and Step 4/5 selection? Is "selected unprepared work" defined precisely enough that an implementer cannot either research the whole window or select before researching?
3. Deepen-when-warranted and reuse-valid-evidence: are the triggers concrete enough without numeric global defaults? Is "freshness reuse" distinguishable from 10days Step 5 `--deep` (a preflight freshness refresh)?
4. Holds and exclusion: list every live line in 10days (and Conveyor) that would still route an unknown/held item to EXCLUDE or silent drop after the plan's named Step 2/3/8 edits. Check Guardrails, Step 3 sanity-check filter, Step 3 "Prioritization Rules", Step 4 contract sniff test, Step 5 planner Held section, Step 8 Exclusion Ledger. Cite `file:line`.
5. Risk deferral opt-in: does any live line perform an implicit (non-requested) deferral or exclusion based on low risk/consequence that the plan leaves untouched?
6. Ratings: does the plan's neutral-appeal / preserve-override / no-forced-clearing change cover every conflicting line (e.g. appeal rubric, `--force` clear, `ovr` invalidation)? Is it consistent with start-task's rating policy?
7. No ledger writes on shortlist: given D-b/G6b, which live lines in 10days AND Conveyor write ledger rows or ratings before committed execution selection? If 10days is told to "consume Conveyor's policy", could an implementer or runtime agent end up executing Conveyor Steps 3-6 (capture publication, `roadmap pickup`, readiness label) from a 10days research child?
8. OL-10 separation: does any plan wording imply admission refusal is implemented? Does the manual scenario walk (plan step 4) honestly distinguish prose consistency from real model behavior, and does the plan unambiguously forbid ticking #1400's OL-09 checkbox ("implemented AND verified") on this PR alone?
9. Acceptance mapping: for each acceptance bullet, is there a concrete check (old-text red control, expected disposition) that would reject an unchanged or partially changed instruction set? Name any bullet with no rejecting check.
10. Over-engineering: flag anything in the plan that is ceremony or speculative machinery, and anything missing that is needed for a minimal correct slice.

Grade each finding `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`, cite `file:line` or a quoted span, and include `Observed input:` / `Affected scope:` / `Falsifier:` for any finding requesting a change. End with `VERDICT: PASS|FAIL|PARKED` and a non-empty `Basis:`. Include `swept file: yes|no`. Do not edit the plan or any source; append only to this file.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
