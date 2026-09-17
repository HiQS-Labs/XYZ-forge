# RELAY · GH-666 narrow probe plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-16.
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-666-narrow-probe-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-666-AGY-MODEL-PROBE.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-666-AGY-MODEL-PROBE.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: producer
- Started: 2026-09-16
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer — producer — Round 1

VERDICT: PARKED
Basis: Independent plan review pending.
swept file: yes

Operational envelope: local developer CLI, one model-validation probe, accidental
relative writes. Commensurate stdlib fix only; no distributed/OS-sandbox/process
framework. Read the actual repo plan (not the external placeholder), its recon,
utils/py/agy-turn.py (662 lines; bounded reads through EOF), relevant existing
test/agy-turn.sh model cases and RELEASES rating read-back. No full historical
changelog audit is required for this prospective local-probe plan; that is not
the code being changed. No tests/programs or source edits in the valued clone.

Questions:
1. Does the traced unsafe call before RTL/snapshot and existing auth-probe pattern
   justify a temporary model-probe cwd without changing validation semantics?
2. Are refusal/cleanup and baseline/ablation caller-preservation checks sufficient
   and commensurate, with explicit limitations for absolute writes/detached children?
3. Are blast radius, rollback, rating 90/85/50/85 and distinct observed versus
   unknown recurrence grounded, and is the plan free of duplicate systems/writers?
4. Do the gate/QA/PR steps preserve unrelated GH-661 work and refuse readiness
   on existing base failures, without claiming skipped gates or promotion?

Only append a cited verdict here. Claim the env-pinned token; on PASS set STATUS
Approved and tick DONE while owned (do not release Producer). Otherwise hand back
findings within cap3. No source edits, Git commands or heavy tests.
Handing off to Reviewer — review the narrow plan and give the cited verdict.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
