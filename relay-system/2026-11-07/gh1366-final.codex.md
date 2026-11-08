# RELAY · GH-1366 final QA: proportionate wording
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
6. **Commit only the relay file** (`relay(gh-1366-final-qa-proportionate-wording): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `PROJECT/2-WORKING/GH-1366-PROPORTIONATE-REVIEW.md`, `TESTS-RESULTS/2026-11-07+GH-1366/`
- Reviewer: codex   ·   Producer: producer
- Started: 2026-11-07
- Definition of Done: Changed gates retain witnessed-failure evidence; unchanged reruns need no fresh mutation; appendix retains containment subject to North Star proportionality; GH-831 untouched.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Review request
Independent final QA on documentation only. Read the complete policy files and plan/evidence.
Questions: does the final wording meet all three plan steps and preserve GH-831, containment,
and honest evidence? Is verification appropriate for prose? Flag concrete defects, not new machinery.
Plan review nit about reconciliation ownership is separately parked in PARKED/2026-11-07-reconciliation-wording.md.
PDDA passed at recorded revision; two formatting-only wrap/space edits followed. The publication hook
will rerun docs checks at final head. No runtime validation or friction improvement is claimed.
The umbrella remains open; this is not all eight audit recommendations.

## Log

### Reviewer · Round 1

Ship — approved for the bounded documentation change.

VERDICT: PASS
Basis: The final prose meets the three ordered plan steps' textual acceptance criteria; evidence accurately limits its claims to source review and the recorded docs gate. Approval is final source QA, not runtime validation or publication/merge readiness.
swept file: yes

- [Pass] Changed gates retain the red-control requirement: AGENTS.md says "For every new or materially changed decision gate, witness a failure before treating its passing result as evidence" and "Rerunning unchanged coverage does not require a fresh mutation." Its existing-suite/manual routes and all three hollow-check examples remain. This matches GUIDING-PRINCIPLES.md principle 13's "Every new or materially changed decision gate" scope. No correction needed.
- [Pass] Appendix priority remains subject to proportionality: GUIDING-PRINCIPLES.md says "This ordering guides doc-review tie-breakers; it does not exempt a control from" the linked North Star assessment and "Preserve containment". Principle 3 still says "Containment is non-negotiable"; the North Star still excludes a "blanket bypass of containment, verification or protection against data loss." No new bypass or execution authority follows.
- [Pass] GH-831 policy is retained: AGENTS.md's "No new tests" rail still prohibits new suites, registry entries and gate machinery, while allowing existing-suite/manual evidence with provenance. The plan's non-goals explicitly say "Do not amend GH-831". No additional machinery is needed for these prose edits.
- [Pass] Evidence is proportionate and candid: TESTS-RESULTS/2026-11-07+GH-1366/SUMMARY.md says "These are manual textual verdicts, not measured reductions in friction or runtime tests." provenance.jsonl records docs command exit 0 at revision 6ea98fb2400a918fbeb512316c839cb21e74c039 and separately labels final whitespace-only source review. pdda.log:260 reports "no errors, 97 warning(s)". The request discloses the two later formatting edits and final publication rerun; this review does not relabel the earlier gate as a final-head run. No runtime smoke or destructive mutation is warranted.
- [Nit] Whole-file sweep retains the already identified pre-existing reconciliation contradiction: AGENTS.md's ownership section says hosted reconciliation happens "automatically", while its GH-1127 rail says "Development merges reconcile locally". PARKED/2026-11-07-reconciliation-wording.md already records the separate scoped correction against workflow/caller evidence. Keep that disposition; no additional pre-existing defect identified in the complete AGENTS.md, GUIDING-PRINCIPLES.md and active plan textual sweep.

Verification boundary: read-only source/evidence inspection; no Git, executable fixtures, runtime suites, or gate rerun performed. Recorded PDDA results were inspected, not independently re-executed. Publication must obtain its own required final-head check as stated in the request.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
