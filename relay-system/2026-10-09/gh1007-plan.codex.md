# RELAY · GH-1007 SWE plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-1007-swe-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1007-SWE-GOVERNANCE.md`, existing `skills/1-hourly/swe/SKILL.md`, and read-only proposed `.relay-artifacts/SKILL.md`
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-10-09
- Definition of Done: The user requests three-domain/four-axis surgical SWE governance, earned tests and separate CI admission, advisory performance baselines in existing task records, and independent plan/final QA. Grade the plan before implementation.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Review questions and envelope

This is a local instruction-only skill revision. Commensurate complexity is required;
no new suite, runner, gate, dashboard, enterprise policy machinery, or runtime code.
Source files: read the plan, full current SWE, seeded proposal, architecture SWE row,
recon's SWE references, and start-task's relevant lifecycle/test restrictions.

1. Does the plan satisfy every user requirement and preserve source-first deployment,
   bounded review, permission, rating and dependency rules? Check persisted rating 75/55/50/85.
2. Is scope surgical and reuse-first? Flag accidental parallel governance or performance machinery.
3. Is verification meaningful without new tests? Does each manual scenario detect a real
   instruction failure, and does the validator red control avoid pretending format proves behavior?
4. Dedicated omission-diff pass: list current SWE claims with no equivalent in the proposal.
   Distinguish deliberate removal of arbitrary SOLID/FSM/scaffold/dual-sync prescriptions from
   an accidental loss of safety, migration, rollback, or consumer contracts. The plan explicitly
   retains Pillar 0 and Blast anchors at implementation, so their proposed headings are not final.
5. Are the performance statements honest about pipeline vs product, noise and baselines?

Use phase-qa's concrete acceptance and commensurate DRY/observability lens; this is a
single ordered unphased docs task, not a request to impose phase scaffolding or SOLID ceremony.
Grade only evidence-backed issues. Record file:line or quoted-span support. Reviewer writes
only this relay file. Do not run test suites, pytest, validate.sh, or executable fixtures.
No self-commit: the driven shim commits your permitted relay change. Set STATUS: Approved
only if genuinely approved; otherwise return specific findings for the author.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
