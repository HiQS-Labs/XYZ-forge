# RELAY · GH613 final correction check
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh613-final-correction-check): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/claude-turn.py`, `utils/py/consult.py`, `test/gh610-claude-subscription.sh`, and the GH613 plan/evidence
- Reviewer: codex   ·   Producer: operator
- Started: 2026-09-13
- Definition of Done: Prior full implementation review in relay-system/gh613-final.md approved 0c3da099. Check corrections since that reviewed revision: stderr now uses resolved tick_repo_root to avoid .xyz containment (targetroot-fixed.log); programmatic Claude preamble explicitly denies script execution; the registered test now drives full consult wall and real idle timeouts and asserts failure, no running child, removed worktree (focused-e2e-final.log: 12 tests and 4 handoffs pass). The plan now has its required goal key. Current fingerprints are in the final provenance row. Verify these changes and retained earlier behavior; reuse the earlier full-sweep review, inspect complete changed functions. Full gate is running independently on 83995bf3; do not claim it passed. Review only, no tests or mutations in this linked worktree. Emit literal VERDICT: PASS/FAIL and Basis:, swept file: yes. Only write this relay.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — codex — Round 1

VERDICT: PASS
Basis: The bounded corrections satisfy this turn's Definition of Done. Reused the approved full-source review attested to 0c3da099 in relay-system/gh613-final.md and inspected complete current main functions and the registered test. No additional blocking pre-existing defect identified within that scope. This is source and recorded-evidence review only; the independent full gate on 83995bf3 is not established as passing. No git commands or artifact/test execution performed.
swept file: yes

- [Pass] Durable stderr now uses the coordination root returned by the claim helper, before containment begins (`utils/py/claude-turn.py:85`, `utils/py/claude-turn.py:94`). Recorded target-root evidence includes “vendored-subdir TURN_ROOT commits” and “12 pass, 0 fail” (`TESTS-RESULTS/2026-09-14+GH-613/targetroot-fixed.log:1`). Fix: none required.
- [Pass] Programmatic Claude receives the explicit seat-specific instruction “only Read/Grep/Glob are available; inspect source without executing probe scripts,” with the same actual read-only tool list and auth/request restriction flags retained (`utils/py/consult.py:568`, `utils/py/consult.py:572`, `utils/py/consult.py:575`). This qualifies the generic programmatic preamble for this seat. Fix: none required.
- [Pass] Full consult wall and real idle cases assert exit 5, zero answers/one failure, a child readiness marker, no running child, the distinct timeout diagnostic, and only the original registered worktree (`test/gh610-claude-subscription.sh:117`). The absent-or-zombie check establishes no running child, not complete zombie reaping. Recorded evidence says “Ran 12 tests in 32.495s” and includes all four successful handoff checks (`TESTS-RESULTS/2026-09-14+GH-613/focused-e2e-final.log:15`). Fix: none required.
- [Pass] Retained behavior includes unconditional relay result validation and subsequent RTL enforcement (`utils/py/claude-turn.py:195`, `utils/py/claude-turn.py:239`), strict consult result classification (`utils/py/consult.py:691`), timeout failure accounting (`utils/py/consult.py:729`), and preservation/error exit on failed Git cleanup (`utils/py/consult.py:848`). Fix: none required.
- [Pass] All four current SHA-256 fingerprints match the final provenance row, including the registered test (`TESTS-RESULTS/2026-09-14+GH-613/provenance.jsonl:10`). The plan contains “goal: Close the accepted native Claude routing, isolation, result, cleanup and effort gaps.” (`PROJECT/2-WORKING/GH-613-CLAUDE-REVIEW-FIXES.md:15`). Fix: none required; operator retains final gate and acceptance bookkeeping.

Coverage limitation: graph project XYZ-forge is a different checkout, generation 2026-09-01T15:54:30Z; coverage reports changed Python metadata and a missing test. Current source and the explicitly reusable prior sweep supply the evidence instead.

relay closed (Approved), no further turn needed. Operator owns the independent full gate and final publication bookkeeping.


### Attestation · relay-drive — 2026-09-14T01:48:14Z
task: RELAY-gh613-correction
reviewer: codex
status: Approved
reviewed-head: 2cbfc53afd7922e881919612cc78a7b9c2d9eb3d
added-range: 4727+3019
added-sha256: 27f33dabd3c2ea86849636e3c9a90641fd5fdd0d1959f7622cc457184f6c453d
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
