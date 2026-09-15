# RELAY · GH605 expanded plan after GLM and Qwen
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-13.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

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

## Reviewer — codex — Round 1

swept file: yes
VERDICT: FAIL
Basis: Read the entire controlling artifact, including historical sections, and inspected the named writer/connector/test sources without executing them. Verify-tier graph lookup used XYZ-forge generation 2026-09-01T15:54:30Z; coverage reports releases_app changed and other requested code/tests untracked, so findings use current source fallback. Two concrete safety contracts remain build-blocking; historical reviewer exhaustion is superseded and is not a finding.

- [Blocker] **Start evidence needs supersession and provenance rules.** `PROJECT/2-WORKING/GH-605-WORK-STATE-PROJECTION.md:226` accepts a recent non-backfill start without excluding a later stop/return-to-Queue transition. An issue started yesterday and explicitly parked today can therefore be put back In progress. Existing `_extract_roadmap_update` also emits `in_flight` for any metadata edit while the marker is 🚧 (`utils/py/releases_app.py:1445`); fixing future emissions does not make those recent historical rows genuine starts. Specify that contradictory current state/later lifecycle evidence invalidates an earlier start, and that legacy ambiguous update emissions require independent start corroboration or remain unknown. Add exact-selection fixtures for start→park, start→stop, and a pre-fix metadata-only in_flight event; none may manufacture In progress.
- [Blocker] **Journal each remote mutation, including partial add/status outcomes.** Steps 5–6 (`PROJECT/2-WORKING/GH-605-WORK-STATE-PROJECTION.md:279`) say record after success, but the reused writer adds a card before setting its status and returns only after both (`utils/py/board_sync.py:540`). If add succeeds and status fails, a caller-level success journal loses the new item ID and cannot account for the residual card. Specify per-request intent/result recording through the existing writer, persist the returned add ID before status mutation, and record an indeterminate outcome when a response or journal write is lost; stop and read back before retry/restore. Test add-success/status-failure and response-loss boundaries, asserting residual-card evidence and no blind retry. Also correct step 6's “existing writer capability”: `_set_status_option` only sets a String option (`utils/py/board_sync.py:493`); explicitly extend that same writer with field-clear support and an originally-unset restore fixture.
- [Pass] Selection and both required outcomes are explicit: exact eligibility/order and preserved unknown Ready cards (`PROJECT/2-WORKING/GH-605-WORK-STATE-PROJECTION.md:236`), PR/terminal seven-day handling (:217), policy-managed raw replay refusal (:203), shared batch rollback (:253), and independent live read-back/no-op rerun (:295). Preserve these contracts while closing the two gaps above.

Pre-existing defects relevant to this plan are included above (legacy metadata starts and composite add/status failure); other identified existing seams already have explicit repair steps. No tests, source artifacts, board/config mutations, or git commands were run.

Handing off to codex-author (Producer) — resolve both findings in the controlling plan and request the next review turn.

## Producer — Round 2

Both blockers implemented in controlling specification: start evidence now requires latest
unsuperseded lifecycle and provenance; untagged legacy starts cannot prove work. Added explicit
start->park/stop/legacy-metadata fixtures. Existing board writer gains optional per-request
audit callbacks, persisted add ID before set, pending-intent indeterminate recovery and no
blind policy mutation retry. Clear-field support is explicitly new in existing writer.
Review these changes and close if ready. Historical stage-gate text is superseded by the
controlling revision, not an instruction to restart a failed harness route.

## Reviewer — codex — Round 2

swept file: yes
VERDICT: PASS
Basis: Read the whole controlling artifact, including superseded historical sections, and checked the named source seams and relevant test source without executing them. SWE review finds the expanded specification ready to implement both required outcomes. Graph lookup used XYZ-forge generation 2026-09-01T15:54:30Z; coverage reports changed/missing/untracked paths, so conclusions rely on current source fallback, not graph completeness. This approves the plan, not an unbuilt implementation or live application.

- [Pass] **Start-evidence blocker closed.** `PROJECT/2-WORKING/GH-605-WORK-STATE-PROJECTION.md:230` explicitly supersedes starts with later lifecycle evidence, rejects ambiguous historical update emissions and requires consistent current state; :312 names start→park, start→stop and legacy metadata negative fixtures. This addresses the existing marker-only emission at `utils/py/releases_app.py:1445`. No further plan change required; preserve these fixtures in implementation.
- [Pass] **Partial-mutation blocker closed.** `PROJECT/2-WORKING/GH-605-WORK-STATE-PROJECTION.md:288` requires per-request durable intent/result, add-ID persistence before status, indeterminate recovery and no blind policy retry. :298 explicitly adds field-clear support; :303 covers add/status split failure, lost responses and journal failures. These repairs fit the existing composite writer at `utils/py/board_sync.py:524` and string-only setter at :493. No further plan change required.
- [Pass] **Selection, containment and completion remain explicit.** `PROJECT/2-WORKING/GH-605-WORK-STATE-PROJECTION.md:212` specifies qualified identities, complete current-state reads, terminal dates, PR handling and preservation; :243 defines exact Ready eligibility/order; :260 covers shared batch rollback; :279 defines saved-preview preflight and exclusion locking; :296 limits restore and reports residual cards. :306 and :314 require deterministic controls, reusable-command gates, live independent read-back and a no-op rerun. Retain these acceptance boundaries; diagnostics alone cannot close this task.

No additional pre-existing build-blocking defect was found in the full plan sweep. Relevant existing source defects remain explicitly covered by its repair steps; this is not a repository-wide code audit. No tests, source artifacts, board/config changes or git commands were run. Only this relay file was edited.

Relay closed (Approved), no further review turn needed. codex-author may proceed with the approved implementation and its required verification.


### Attestation · relay-drive — 2026-09-13T21:37:38Z
task: RELAY-gh605-expanded-plan
reviewer: codex
status: Approved
reviewed-head: 8cfad6bb8207e6208a72b100086de2d26f94f866
added-range: 9465+2630
added-sha256: 50c58a984b4c78a16fe06a27f82bfa553c00ff19e695a25bca455c1841f8207e
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
