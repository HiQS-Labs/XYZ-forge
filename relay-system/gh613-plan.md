# RELAY · GH613 implementation plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(gh613-implementation-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-613-CLAUDE-REVIEW-FIXES.md` and its cited source files
- Reviewer: codex   ·   Producer: operator
- Started: 2026-09-13
- Definition of Done: Evaluate the five accepted Opus findings and surgical implementation plan, auth/request settings parity, native restricted tools, no duplicate mechanisms, compatibility and falsifiable evidence. Review the source paths needed for plan claims; do not run test/*.sh or validate.sh in this linked worktree. Only write this relay. Emit literal standalone VERDICT: PASS or FAIL and Basis: text, swept file: yes. Approve when implementable; no speculative scope expansion. All production changes remain pending.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — codex — round 1

swept file: yes
VERDICT: FAIL
Basis: The five changes are bounded and mostly implementable, but timeout acceptance conflates two different runners, cleanup has an uncovered existing failure path, and the completed spike lacks the required attributable evidence.

- [Pass] Routing, result validation and effort fixes target existing seams: `relay-automation/claude-turn.sh:9`, `relay-automation/consult.sh:9`, `utils/py/claude-turn.py:184`, and `utils/py/claude_cli.py:52`. Keep the proposed shared helpers, unconditional strict result parser, and native restriction flags; no parallel mechanism is needed. Plan step 2 explicitly requires flags “identically to auth and inference” and step 4 preserves “cli-default”.
- [Blocker] R1 — Name which runner S4 covers. Plan lines 93–107 promise wall/idle descendant termination plus token cleanup as existing guarantees, but `utils/py/claude-turn.py:186` uses plain `subprocess.run(... timeout=...)`, with neither an owned process group nor idle enforcement; consult alone uses `start_new_session=own_group` (`utils/py/consult.py:243`) and `kill_existing` (`utils/py/consult.py:304`). Concrete fix: explicitly scope wall/idle descendant assertions to consult and separate relay error/token/worktree assertions if that is the accepted finding; if relay descendant cleanup is intended, name the minimal integration with the existing process-group helper and its wall-time regression in the implementation steps. Do not imply that adding tests alone provides relay group termination or idle detection.
- [Should] R2 — Full-source sweep found an existing cleanup defect directly relevant to S4: after `git worktree remove` fails, `utils/py/consult.py:841` through `:848` prunes and manually `shutil.rmtree`s the remaining linked worktree, suppressing errors. This violates the repository worktree rail and can still report an answered consult without successful cleanup. Concrete fix: add a bounded cleanup failure case to the plan; preserve the directory and report the failed Git removal with an actionable path, using Git worktree operations only. Assert the failure cannot silently count as successful cleanup. Other accepted pre-existing Claude defects are already represented by the five planned changes; this is an additional sweep finding.
- [Should] R3 — Phase 0 is not independently attributable yet. `TESTS-RESULTS/2026-09-14+GH-613/boundary-spike.jsonl:1` contains a sanitized answer and booleans only; it does not record CLI version, auth/request argv, whitelisted auth outcome, or the probe/assertion provenance supporting plan lines 64–74. The evidence directory contains only that file, without `provenance.jsonl` required by AGENTS.md. Concrete fix: retain a secret-free provenance receipt and the reproducible marker/assertion procedure, including a witnessed negative control; include the auth/settings-parity evidence or mark that portion pending. Do not store credentials or real private-file contents.

Review scope: entire plan, entire Python Claude adapter, relay runner, consult runner, process-group helper and GH610 fixture; shell dispatch boundaries inspected. Verify-tier graph lookup found no current-worktree project (all 62 entries paginated); nearest XYZ-forge generation 2026-09-01T15:54:30Z has missing/changed coverage for the additions. Exact local source reads supplied the evidence; no graph completeness claim. No source, probe, test, gate, or Git command was run, and no production artifact was changed. This is plan QA, not implementation validation.

Handing off to Producer (operator) — address R1–R3 in the plan, log each disposition, then request the next reviewer turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
