# RELAY · GH-280 Jog Marathon recalibration plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-27.
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
6. **Commit only the relay file** (`relay(gh280-jog-marathon-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-280-JOG-MARATHON-RECALIBRATION.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-280-JOG-MARATHON-RECALIBRATION.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: codex
- Started: 2026-08-27
- Definition of Done: the plan is implementable without creating dual execution authority. Grade:
  (1) the Jog/Preflight/Marathon/wave-reconcile ownership split against the cited code and Recon Map;
  (2) whether `marathon-invocation@1` and `marathon-drive/result@1` are sufficient, additive process
  contracts with terminal coverage and root/`.xyz` path safety; (3) whether the opt-in adapter and
  cold-start behavior prevent duplicate turns, tokens, branches, and queue projections; (4) whether
  resume, gate-only retry, rebuild, landing, and lifecycle reconciliation have unambiguous authority,
  idempotency, and fail-closed checks; (5) whether the staged rollout and bounded legacy fallback are
  proportionate to risk; (6) whether every phase has falsifiable QA, including real non-simulated root
  and vendored evidence in separate full clones; and (7) whether the plan accidentally weakens
  builder/reviewer separation, attempt caps, Tick append-only history, protected-branch behavior,
  best-effort Marathon PR semantics, or frozen-twin policy. Read the full plan, Recon Map, and relevant
  implementation surfaces; identify missing decisions or unjustified new APIs. Review the plan only:
  no implementation exists in this branch.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
