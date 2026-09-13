# RELAY · GH-605 plan QA Agy
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-605-plan-qa-agy): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-605-WORK-STATE-PROJECTION.md; read cited source and existing tests, not just this thread.
- Reviewer: agy   ·   Producer: codex-author
- Started: 2026-09-13
- Definition of Done: grounded, bounded plan that repairs state/event defects without inferring activity or introducing another writer; falsifiable tests, explicit follow-ups and safe rollback.

## Questions

1. Is the proposed section-first classifier consistent with live/backfill semantics and metadata-after-review safety? What case is missing?
2. Can the proposed event batch preserve one receipt, rollback, row fences and post-lock dispatch? Inspect perform_write completely.
3. Is read-only work status honest about schema7, missing events, backfill timestamps and stale observations, and does it avoid claiming current-state reconciliation?
4. Omission-diff: compare each audited gap and operator requirements in the plan's scope table with implementation steps. Identify any silent omission or unjustified expansion. Deferred GH-402 work must remain explicit.
5. Are ratings, acceptance/red controls, boundary/rollback, and no-live-board-write policy adequate?

Plan review only. Never run validate.sh or test/*.sh in your linked reviewer worktree. Do not edit production code or the plan. Review inputs are committed. Use textual-only basis for the plan. End with VERDICT: PASS/FAIL/PARKED, swept file: yes/no, and header STATUS consistent with verdict. The driver owns commits; do not run git commit, push, or amend. Use the exact absolute tick path provided by the runtime prompt for token commands.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Producer · 2026-09-13
**Did:** Registered/rated GH-605 and committed bounded plan at f05ecdb1.
**Review this:** Answer the five Questions using actual files and report concrete file:line findings.
**Verification:** Pure-function source probes exposed four live/backfill disagreements; full baseline gate running in a separate disposable clone; implementation not started.
**Open questions:** Identify any overlooked transaction or lifecycle edge.
**Commit:** f05ecdb1

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
