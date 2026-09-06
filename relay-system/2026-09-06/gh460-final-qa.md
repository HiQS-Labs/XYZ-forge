# RELAY · FINAL QA: GH-460 implementation (oracle + smoke + registration + evidence)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-06.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
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
6. **Commit only the relay file** (`relay(gh460-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-06
- Definition of Done (start-task final QA): decide whether the GH-460 implementation is ready
  for a PR to `development`. Verify by reading the named files in this worktree:

  1. Oracle (`test/gh460-oracle.sh`) implements the plan's O1–O4 behavior contracts: SETUP-FAIL
     guard, byte-exact tmpfile capture, whitespace-tolerant wc parse (MEASURE-FAIL exit 8),
     BADRC/LEAK/HIT-EMPTY invariants (exit 9, stderr), EXIT-trap, `$1`-with-absent-maps-to-empty
     input policy, MODEL_ALIASES_FILE unset.
  2. Smoke (`test/gh460-fuzz-resolver-smoke.sh`): shared run contract (seed 7, base glm-5.2,
     timeout-budget 30, --json, fresh corpus, LC_ALL=C, unset override), fail-closed JSON parse,
     floors (executed >= 20, fail/anomaly == 0), exact-value R1-pre pins, wrapper mapping literals.
  3. Registration: `grep gh460 validate.sh` — the smoke is in the TESTS list consumed by
     `ci-local.sh`.
  4. Evidence: `TESTS-RESULTS/2026-09-06+GH-460/` — summaries show resolver seeds 7/8/9 × 500 and
     wrapper seed 11 × 300 all green (fail/anomaly 0), `witnesses.log` 13/13 baseline→red→
     restored-green, `provenance.jsonl` present for every cited run.
  5. No duplicate machinery: no second matcher, no engine changes, no production Bash; the oracle
     reuses the resolver as its own differential reference.

  Graded findings with citations; `swept file:` line; end with line-start `VERDICT: PASS` /
  `VERDICT: FAIL` / `VERDICT: PARKED` then `Basis: <one line>`.


## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
