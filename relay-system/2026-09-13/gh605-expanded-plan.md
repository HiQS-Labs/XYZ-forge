# RELAY · GH605 expanded plan after GLM and Qwen
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
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
6. **Commit only the relay file** (`relay(gh605-expanded-plan-after-glm-and-qwen): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-605-WORK-STATE-PROJECTION.md
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-09-13
- Definition of Done: revised controlling specification closes GLM/Qwen blockers and is ready to implement both reusable scripts and live Rev.2 application safely.

Read the full plan; September13 expanded revision supersedes historical narrow steps. Inspect
utils/py/releases_app.py, utils/py/board_sync.py, utils/py/work_connectors/github_board.py,
utils/py/work_connectors/__init__.py and relevant test/gh549-work-events.sh,
test/gh492-roadmap-state-sweep.sh, test/gh402-board-sync.sh as source only.
1. Are top10 eligibility/order/demotion, recent-start evidence, PR handling and7dayDone specified
   and consistent with operator requirements? Does any decision silently invent activity?
2. Are current-state collection completeness, identities, reopens and unknown preservation safe?
3. Does the ordered plan reuse actual writer/config seams and preserve legacy behavior while
   blocking raw replay on a policy-managed board? Is the batch transaction rollback scope sound?
4. Are saved-preview preflight, locking, partial-write reports, restore/new-card limits and
   deterministic negative controls sufficient? Name only concrete build-blocking gaps, not newscope.
5. Does the implementation acceptance close both outcomes rather than just diagnostics?

Only this relay thread is writable. Do not run tests/validate, edit code, git add/commit/push,
or change board/config; the driver owns commits notwithstanding scaffold text. Append concise
graded file:line findings and exact VERDICT: PASS/FAIL/PARKED and swept file: yes/no, Basis textual
only. If approving set STATUS Approved and mark runtime token done; otherwise release to
codex-author. Current explicit user instruction authorizes this renewed review after GLM/Qwen;
do not re-block on historical exhausted DeepSeek attempts or demand another harness diagnosis.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
