# RELAY · GH1022 Phase7 declared-work census plan
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
6. **Commit only the relay file** (`relay(gh1022-phase7-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md Phase7 and GH-1022-WEEKLY-INTAKE/recon-remaining-boundaries.md; relevant owner seams in releases_app.py, marathon.sh progress observer, planner_core.py and issue_intake.py
- Reviewer: codex · Producer: author
- Started: 2026-10-12
- Definition of Done: Review genuinely new read-only declared-work census plan; existing-owner reuse, typed qualified/held evidence, no writes/global-quiescence/dispatch claim; legacy compatibility and existing/manual verification only. Own normal new-scope cap3 from prior authorization. No corrective R6/Phase6 reset or full1022 approval.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1

Current source baf67495; actual deployed-source qualification snapshot bc4/d09. Phase6 source77e99f17 Approved3/3 andnormalfull409/Python21, Ubuntu407/407 (gh123fixed),smokeSUCCESS. Source unchanged. This new plan adds canonical Marathon/Jog/lifecycle read envelope, one-shot existing-observer read action and thin shared-normalization/core observation adapter. No implementation yet. Read Phase7 and reconmap; verify the listed owner seams before approving. Propose the smallest adequate envelope/observer shape and reject a second reader/runner/registry/framework. Existing observer context is optional, not global authority; receipt/heartbeat markers don't prove criterion delivery/authenticity/stopped descendants. Preserve landed logical productRoot attribution, legacy outputs/filter/order/ownership, defaults and 10days scan/find-doc policy. Missing/malformed/foreign/drifting inputs ->held UNKNOWN/nonzero, never success-empty, migrations/recovery/signals/leases/connector config/secrets/DB/audit/context writes.

Caller authority list is explicit; no inferred primary/fleet scan. Terminal/carryover scope is explicit/all. Existing IO containment/runtime path+byte binding must remain real. Root/head/generation/context read completeness remains distinct from code readiness, delivery and dispatch. Full W7–W11 staysactive; globalwriter/rollover,strictreadiness,freeze/approval/effectguards are not claimed. R6FAIL6/6/MediumGH1028 andGH1027unapprovedtests unchanged; Phase6closedApproved3/3—not reopened. This is newly planned read capability, no review reset/relabel or checkrestart.

No source edits/suites/pytest/fixture executables/agents/network/connectors/live operations; onlythisrelay, harmlessin-memory source queries permitted. Bounded owner-seam plan review; full-file final QA after implementation. State actionable input/scope/falsifier/severity and unknowns; no speculative blockers. No new CI cases/gates/runners requested. LastScopeModel receipt authenticity/human/cost/fleet questions remain explicit unknowns for later scopes, not excuses to build mechanisms now. Handing off to Reviewer(codex)—take the genuinelynew plan turn within cap3.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
