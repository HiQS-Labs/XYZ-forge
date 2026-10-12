# RELAY · GH1022 Phase7 declared-work census final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-11.
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
6. **Commit only the relay file** (`relay(gh1022-phase7-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: whole utils/py/releases_app.py, relay-automation/marathon.sh, skills/3-weekly/weekly-planner/scripts/planner_core.py and issue_intake.py; Phase7 plan/weekly skill/manual evidence under TESTS-RESULTS/2026-10-11+GH-1022/phase7-*
- Reviewer: codex · Producer: author
- Started: 2026-10-12
- Definition of Done: Independently sweep every changed owner in full, including preexisting defects and actual applicable covering fixtures. Review this genuinely new held read-only census implementation against approved Phase7 plan; ownership/identity, raw NULL-gh facts, stable generation/head/runtime, conflict/provenance retention, no writes/signals/connector/dispatch/global-idle claim, legacy outputs and preparation runtime compatibility. Source candidate290566bf. Existing/manual controls only: no individual new CI tests/cases/registrations authorized. No live Marathon/Jog, publication, production action or primary/deployed skill edits. Use own normal new-scope cap3; corrective accumulation R6FAIL/1028 and approved Phase6 remain immutable, do not reset them. Not full1022/W7–11 or merge authority.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1

VERDICT: PARKED
Basis: Candidate is implemented; independent final review is pending, not approved.

Review the exact current source and all four owners in full. Candidate290566bf implements the approved Phase7 census. Manual owner/core reads: Jog24/work15/observer8/core12; existing preparation runtime controls19. Evidence and measured complete source hashes are committed. Negative controls established UNKNOWN for missing/malformed/foreign/conflicting observations, metadata ownership, journal/generation errors and final runtime drift. Available raw unknown responses remain retained. Fixtures and stdout artifacts write owned local temporary state; census readers do not write. No permanent CI tests/cases/registrations added.

No reviewer source edits, subagents, suite/fixture executable runs, network/connectors/live actions, or Git writes except this relay; harmless in-memory source probes permitted. Existing covering suites run independently in the separate disposable verification clone. Cite concrete observed input/scope/falsifier for behavior-change findings. Preserve prior corrective accumulation R6FAIL6/6/MediumGH1028 and Phase6Approved3/3; own new-scope cap3 is not a reset. Census is only W7 prerequisite; remaining W7–11 and full1022 remain active. Handing off to Reviewer(codex)—take this final new-scope turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
