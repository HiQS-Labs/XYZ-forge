# RELAY · GH-605 expanded plan QA Qwen Alibaba
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
-->

NEXT: Producer
STATUS: Escalated
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
6. **Commit only the relay file** (`relay(gh-605-expanded-plan-qa-qwen-alibaba): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-605-WORK-STATE-PROJECTION.md and the existing implementation it cites.
- Reviewer: deepseek   ·   Producer: codex-author
- Started: 2026-09-13
- Definition of Done: an implementation-ready plan satisfying BOTH durable reusable-script repair and verified application to project #4 Rev. 2, without guessing state or bypassing existing writers.  [Unverified — no citation]

## Questions — renewed QA authorized by operator

The operator requested DeepSeek harness -> Alibaba Token Plan -> Qwen 3.8 Max to retry QA.
Previous DeepSeek/OpenRouter failures are historical, not a reason to refuse this new run.
Previous Agy approval covered only the narrower plan, not the expanded two-goal requirement.

1. Omission-diff: compare BOTH operator outcomes at the top of the plan to every concrete implementation step and acceptance check below. List missing mechanisms and tests, not just a summary. Is this plan ready to build as written?
2. Inspect utils/py/releases_app.py (_extract_roadmap_update, perform_write, cmd_roadmap_reconcile_state, _backfill_event_for, cmd_work_reconcile), utils/py/work_connectors/github_board.py and utils/py/board_sync.py. Does the proposed design reuse the real writer and correctly distinguish lifecycle from recent activity? Cite actual file:line evidence.
3. Can existing selection/replay enforce top 10 eligible Ready, 7-day Done, In progress and standalone PR In review without resurrection or stale-state regression? What minimal existing seams need extension?
4. Are read-only evidence collection, issue identity, uncertain-state preservation, dry-run/apply, before/after snapshot, rollback and no-op second run specified sufficiently for the live board? Name unresolved policy choices separately from implementation gaps.
5. Review the existing transaction changes and tests (test/gh549-work-events.sh and test/gh492-roadmap-state-sweep.sh). Are atomicity, metadata-after-review safety, receipt linkage and red controls sound? Give concrete changes for any blocker.

Plan-only. Read actual files; do NOT run validate.sh or test/*.sh in this linked worktree.
Only this relay thread may be edited. Never run git add/commit/amend/push; driver owns commits
despite generic scaffold wording. Append one new block immediately above the marker, preserving
all previous body text. Include exact VERDICT: PASS, FAIL or PARKED and swept file: yes/no,
with Basis: textual only and graded file:line findings. No implementation or board writes.
If Approved, set STATUS Approved and mark the exact runtime token done. Otherwise leave
STATUS Open and release to codex-author. Runtime absolute tick path is authoritative.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Producer · 2026-09-13
**Did:** Renewed QA on the operator-selected Qwen/Alibaba route, capped at two rounds. Latest requirement checkpoint is 9f3de8f0. No implementation exists yet.
**Verification:** Same runtime as verified baseline 38507a23; no changes under utils/py, relay-automation, test or validate.sh. Retained baseline validate: exit 0, 374/374, one sequential retry, identity intact. Saved profile resolves deepseek/alibaba/qwen3.8-max; credential file available, contents never displayed.  [Unverified — no citation]
**Review this:** Assess the expanded plan honestly. It currently labels additional recon/ordered-plan work pending; enumerate the concrete gaps and do not approve based on earlier narrower Agy approval. Focus on the smallest repair that meets both user outcomes.

### System checkpoint · Codex author · 2026-09-13
The requested Qwen/Alibaba attempt returned driver exit 7 after 600 seconds, attributed
timeout-idle-no-progress (0.02 CPU seconds/second, 58 samples, no worktree progress).
No VERDICT was produced. The harness released the claim. This is not a reviewer rejection
or an approval; no second unchanged attempt was launched after the ten-minute stall.

Account-access checks requested by the operator: authenticated GET /models returned HTTP
200 and listed qwen3.8-max. A minimal non-streaming POST /chat/completions using that exact
model returned HTTP 200, model qwen3.8-max, content OK, finish_reason stop, 89 total tokens.
Thus basic authenticated inference works now; remaining quota, subscription/billing status,
streaming and full relay-sized request health are not established by this probe. Investigate
the full request/harness path before repeating a long QA attempt. No credentials retained.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
