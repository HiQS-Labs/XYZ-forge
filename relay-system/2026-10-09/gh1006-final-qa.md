# RELAY · GH-1006 bounded observation final QA
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
6. **Commit only the relay file** (`relay(gh1006-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup

Operational envelope: macOS local developer harness; opt-in finite observation and active-agent repair-to-PR instructions. No autonomous recovery controller, no new suites/registry/gate machinery, no changes to coordination/containment/review semantics. Grade against this envelope and the approved plan, not speculative enterprise threat models.
Artifact: complete changed files `relay-automation/marathon.sh`, `utils/py/marathon_progress.py`, `relay-automation/README.md`, `skills/1-hourly/relay-xyz/SKILL.md`; whole plan `PROJECT/2-WORKING/GH-1006-BOUNDED-RECOVERY.md`; supporting CHANGELOG, ledger row, package and retained TESTS-RESULTS/2026-10-09+GH-1006. Diff base 7435a38cbcccbb7e3cb6fe11db809a7f6562a8c2, implementation checkpoint 9f7043f4.
Definition of Done: implementation and focused proofs meet every first-delivery acceptance item; whole-file sweep, no speculative controller/writer, coherent run attribution/signal/finite lifecycle, unanimous bounded repair guidance and honest held continuation. Rating remains 80/65/80/45 (qualitative preference interpretation, trend unknown).

Questions:
1. Are the validated opt-in settings, N=6/N=18 and missed-slot outcomes consistent with the plan? Does phase transition or terminal/window expiry introduce an extra check or executor?
2. Does the read-only observer attribute driver receipts and current heartbeat honestly, including whole-second timestamps, foreign/malformed data, optional acceptance and re-verification/duplicate milestones?
3. Does the opt-in serial background/wait preserve status and cancellation, with no promise of stopped descendants? Inspect the logger TERM red control and corrected real launcher latency controls.
4. Does the procedure preserve original deadlines/attempts and exclusions, require three affirmative advisory seats plus independent QA/gates, publish to development and hold unmerged continuation behind #752/#1004? Does it fulfill the refined issue's first-delivery boundary without closing held work?
5. Are retained 51 manual controls and existing 35/17/223 checks attributable and nonempty? No new test suite or gate is permitted; retained manual probe text is evidence, not registered test machinery. Any concrete missing acceptance proof must state failing input/scope/falsifier.
6. Review full changed files for material pre-existing defects; report bounded coverage limitations. Graph generation is stale, helper not indexed; use current source. No mutation-heavy test/suite/fixture may run in this review worktree. Retained producer results are not independent reruns.

Full gate sequencing: classifier says route=full,tier=3. Focused evidence is complete. Per start-task, the single final classified macOS full gate runs AFTER code approval, in a separate disposable full clone, through the pre-push hook. Approval of code is not gate evidence or PR readiness; publication remains blocked until that gate passes and clone identity is intact. Do not approve missing focused evidence, and do not require a second full gate before the final approved runtime revision exists.

Reviewer codex; Producer codex-author. Three-round binding cap. Write only this relay thread; no production edits or push.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
