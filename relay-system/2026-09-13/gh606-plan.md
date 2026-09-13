# RELAY · GH-606 End of Week plan QA
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
6. **Commit only the relay file** (`relay(gh-606-end-of-week-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-606-END-OF-WEEK-SKILL.md` and `PROJECT/2-WORKING/recon-end-of-week.md`
- Reviewer: codex   ·   Producer: producer
- Started: 2026-09-13
- Definition of Done: Review the entire plan against the user contract captured in its requirements and source-traced seams. This is an instructions-only skill; no runtime changes. Answer:
  1. Are GitHub default-branch discovery, seven-day window, HiQS cached reader and canonical board/config discovery grounded and portable?
  2. Does authorized metadata/board correction stay through existing writers, preserve unrelated state and handle fail-soft/unsupported cases honestly?
  3. Are all six tasks, two goals, top-ten issue content, severity titles and bounded recital/resume/completion behavior covered?
  4. Are acceptance checks falsifiable and verification proportional, without requiring a live business-data sweep to validate docs?
  5. Are blast radius, no-script-change limit and ratings reasonable? Identify concrete blockers only; do not expand scope into repairing existing runtime gaps.
Cite source/plan lines. Read only; update only this relay file. Do not run tests or mutate git/config outside the relay protocol.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — codex — round 1

VERDICT: PASS
Basis: The complete plan and Recon Map meet the instructions-only Definition of Done; no concrete blocker or additional pre-existing defect was found in either reviewed document. Approval is for authoring the skill, not evidence of implementation or live weekly correctness.
swept file: yes

- [Pass] Discovery and coverage are explicit: `PROJECT/2-WORKING/GH-606-END-OF-WEEK-SKILL.md:42` pins the seven-day UTC window; `:88` separates consumer/harness roots and GitHub default discovery; `:128` refuses unsupported branch substitution. The existing rejection is present at `utils/py/wave_reconcile.py:1899`. Retain these requirements in the skill.
- [Pass] HiQS is a cached snapshot, not historical completeness: `PROJECT/2-WORKING/recon-end-of-week.md:43` and `:62` describe the reader and missing-data limits; Rebalance `src/rebalance/mcp/tools/index.py:247` explicitly reads without recomputing, and `src/rebalance/ingest/next_actions.py:1566` reads the latest cache row. Plan `:130` and `:133` reject empty/truncated-source all-clears. Retain those branches.
- [Pass] Configuration and writes use existing seams: `utils/py/device_config.py:32` resolves the explicit config override; `utils/py/work_connectors/github_board.py:97` merges board defaults into connector settings; `utils/py/board_sync.py:532` selects `repos[0]`. Plan `:73` through `:93` require prior/resulting values, concurrent-change checks, override preservation, authoritative landed state and identity matching. `utils/py/work_connectors/__init__.py:82` supplies the stated per-process `XYZ_WORK_CONNECTORS=0` control. Retain the effective-config check before dispatch.
- [Pass] Unsupported/fail-soft outcomes remain honest: recon `:54` through `:60` requires diagnostics, bounded pending batches, cursor progress and fresh board read-back; plan `:131` and `:132` distinguish lifecycle projection and zero-exit failure. No runtime-gap repair is required by this plan.
- [Pass] All six tasks, two goals, up-to-ten evidenced issue items, justified severity prefixes and script-recommendation-only scope are explicit at plan `:38` through `:51`; bounded recital/resume/completion and issue reuse are explicit at `:53` through `:57` and `:135`. Retain this contract without adding tasks.
- [Pass] Proportional proof and scope are specified at plan `:115` through `:142`: documentation scenarios are distinguished from live execution, deterministic validation needs a witnessed negative control, and sanitized evidence has a committed destination. Plan `:65`, `:73` and `:153` reasonably separate easy authoring rollback from future cross-system operational risk and proposed ratings. Ratings read-back remains an explicit Phase 1 checklist item at `:109`, not a claimed completed check.

Verification limits: Read both artifacts in full and inspected the material source seams above; no tests, runtime artifacts, git commands or business-data actions were run. Graph coverage reports XYZ generation 2026-09-01T15:54:30Z with changed/untracked paths and Rebalance generation 2026-09-02T03:54:57Z with excluded/changed reader paths; direct current-source reads support the cited claims. This is a bounded plan review, not an exhaustive runtime audit.

Handoff: relay closed (Approved), no further turn needed. Producer may proceed to the approved skill-authoring phase; the harness owns the relay commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
