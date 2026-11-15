# RELAY · GH1400 implementation final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-15.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1400-implementation-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Final review packet

Review this committed implementation against the NEW implementation slice in
`PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md`; old PR1403 is preserved history.
Read entire changed production files `utils/py/jog_run.py`, `utils/py/releases_app.py`,
Jog instructions, recon/decision and `TESTS-RESULTS/2026-11-15+GH-1400/SUMMARY.md`, scripts,
required inventories, result records, logs and provenance. Review the actual diff against
7dd85cd3a55303818ce61cbcc5d89b246d4a6449. Source changed last at97aa938be; subsequent changes
are evidence/docs and primary-owned rating checkpoint. Plan QA Approved round1/3, retained.

Operational envelope: local operator-invoked bounded Jog wake, synthetic provider-free verification;
no scheduler activation, live LTVera, new API spend, merge or deployment. No new schema/queue/ledger,
framework or tests/registry. Deadline bounds dispatch and worker group; publication/cleanup clocks
remain separate. No correlated loss/power-loss/PID-reuse/context/external-effect exactly-once promise.
Grade commensurate scope, not an unrequested enterprise controller.

Questions:
1. Does actual CLI adoption/continuation and adjacent repeat satisfy the capability gain without
   a duplicate builder or writer? What prevents unchanged code being reported as delivered?
2. Are exact latest issue/execution/target binding, missing/invalid result holds and existing
   attempt accounting preserved? Check latest gate retry cannot fall back to older approval.
3. Are clone/branch/log preservation and stopped/unknown owner exclusions safe within this envelope?
4. Are deadline/cancel ownership and limitations honest? Are stopped/held outcomes visible?
5. Are manual receipts nonempty and complete, with discriminating red controls? They are synthetic
   worker/gate results, not real product approvals. Existing integration227/227 is separate.
6. Any shared valid-history regressions, unaddressed pre-existing defects, scope expansion or
   duplicate subsystem? No new suite/registry may be requested.
7. Rating75/60/50/45 with null override is primary-owned; original accepted-start retained. Is
   the rationale honest? Is whole umbrella coverage proven or must #1400 remain open?

Final classified full gate is pending by workflow order and must run on the final approved
revision. Do not call pending gate green. Review may approve source/evidence subject to that
required publication gate; no ready-PR claim precedes it. Do not run tests/gates or modify source;
only this relay file writable. Read-only bounded source/evidence probes allowed. Source-backed
findings require observed input/scope/falsifier. Maximum3 review rounds, no delegated children.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: producer
- Started: 2026-11-15
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
