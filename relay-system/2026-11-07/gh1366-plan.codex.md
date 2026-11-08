# RELAY · GH-1366 plan QA: two-file wording only
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-07.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh-1366-plan-qa-two-file-wording-only): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1366-PROPORTIONATE-REVIEW.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`
- Reviewer: codex   ·   Producer: producer
- Started: 2026-11-07
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log



## Review request
Read the plan and governing paragraphs. Pure documentation scope; no runtime or test-policy amendment.
Questions: 1. Does the planned wording faithfully reuse principle 13's existing scope?
2. Does the appendix clarification preserve containment and operator control?
3. Are verification, rating and non-goals proportionate and complete?
Do not demand runtime machinery for this two-paragraph clarification. Review only; no artifact edits.

### Reviewer · Round 1

Ship — plan approved for the bounded two-paragraph clarification.

VERDICT: PASS
Basis: The acceptance criteria are the plan's ordered implementation and the three explicit review questions below Setup; the Setup Definition of Done remains a scaffold placeholder. Approval covers the plan, not implementation, runtime behavior, or merge readiness.
swept file: yes

- [Pass] Existing scope reused: principle 13 says "Every new or materially changed decision gate needs a recorded demonstration that it fails for the right reason". Plan step 1 adopts that same predicate, preserves the rationale/examples and existing-suite/manual routes, and explicitly exempts only fresh mutation on unchanged coverage reruns. Implement as scoped; no additional mechanism needed.
- [Pass] Containment and operator authority retained: plan step 2 makes appendix ordering "a doc-review tie-breaker applied subject to the North Star proportionality assessment". The North Star already says this is "not a blanket bypass of containment, verification or protection against data loss"; principle 3 says "Containment is non-negotiable". Preserve those boundaries in final wording and link the canonical North Star rather than restating a new exception policy.
- [Pass] Verification and rating are proportionate: the plan calls for "record manual evidence and provenance", the "classified docs gate", and "independent final QA"; its boundary explicitly says "text review is not a runtime pass". The two consumer cases distinguish changed gates from unchanged reruns. Rating rationale discloses "no complete incident census, unknown trend" and no override; no unsupported measured improvement is claimed. Carry out those existing checks after implementation; no runtime smoke or new suite is warranted by these prose edits.
- [Nit] Whole-file sweep found pre-existing reconciliation wording drift in AGENTS.md: its ownership section says the hosted workflow "automatically reconciles docs, ledger, and views" after a development merge and calls local reconciliation an "emergency fallback"; the later GH-1127 rail says "Development merges reconcile locally". This can misdirect a cold reader, but neither planned paragraph depends on it. Cheapest correction is a separate scoped wording reconciliation against the canonical GH-1127 procedure; do not expand this two-paragraph slice to repair it. No other additional defect identified in this textual sweep of the three artifacts.

Verification boundary: source inspection only; no executable fixtures, suites, or Git commands run. Implementation evidence and final QA remain pending as the plan states.

Relay closed (Approved), no further turn needed. Producer may proceed with the approved plan outside this closed plan-QA relay.


### Attestation · relay-drive — 2026-11-08T04:53:11Z
task: gh1366-plan
reviewer: codex
status: Approved
reviewed-head: ab8558aa4298291b724a31b2512b824a915156e1
added-range: 6163+2785
added-sha256: 1c23215c37a5d34e37ea278f1820ad50b3f6181b539b8d778d3406cbab267747
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
