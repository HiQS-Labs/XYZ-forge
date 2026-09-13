# RELAY · GH605 implementation QA
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
6. **Commit only the relay file** (`relay(gh605-implementation-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-605-WORK-STATE-PROJECTION.md; utils/py/releases_app.py; utils/py/board_sync.py; utils/py/work_connectors/github_board.py; test/test_gh605_work_state.py; test/test_gh605_board_policy.py; test/gh492-roadmap-state-sweep.sh; validate.sh; TESTS-RESULTS/gh605-implementation/
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-09-13
- Definition of Done: controlling expanded plan implemented safely, deterministic checks substantiate claims, all implementation blockers resolved before live apply. This first QA round has known integration failures: do not approve while they remain.

## Specific implementation QA questions

Read the controlling expanded plan and current files in full, not just the latest diff.
First code checkpoint1e918e83; correction7e24f54a; base development561123d0. Read committed
SUMMARY.md/provenance.jsonl. GLM and Qwen findings are embodied in the controlling plan.
The historical narrower Agy/DeepSeek gates are superseded by the controlling final Codex loop.
The operator requires reusable scripts AND later verified live Rev.2 application. No live
apply is permitted before code approval; lack of application now is expected, not a blocker
to approving a correct code candidate. Current code/test defects ARE blockers.

1. Do section-first transitions, metadata-only updates, batched sweep events and rollback
   follow the real shared writer contract, including mixed-repo ownership and idempotence?
2. Does read-only work status actually avoid all DB/sidecar/config/cursor writes (including
   WAL-mode-without-existing-sidecars), refuse ambiguous identity, distinguish real jog/start
   provenance from backfill, and invalidate only genuine superseding lifecycle transitions?
3. Does the planner enforce top10, stable ties/override,3day starts,7day terminal state,
   explicit PR links, draft/non-draft precedence, reopen/unknown/duplicate/foreign preservation?
4. Are the REAL GitHub resolver/snapshot/collector queries valid and bounded? Independently
   adjudicate the known owner-resolution and extra-brace findings. Do mocks detect these?
   Proposed minimum fix: repositoryOwner union fragments, correct brace, focused mock tests.
5. Can saved preview tampering/drift/future dates, missing options, same-status replaced item,
   audit failure before/after requests or a lost response cause an unintended/unaudited write?
   Does conditional restore report partial/indeterminate states honestly, preserve newly added
   cards, validate target and exact item identity, and clear originally unset status safely?
6. Are the tests meaningful nonempty integration fixtures? Known full gate fail is registry
   census .sh372 versus listed374. Prefer thin .sh test entry points and restoration of the
   original runner plumbing over broad unrelated census changes. One URI test omitted Git
   metadata. Report missing load-bearing acceptance tests beyond those known failures.
7. Are there unsafe interactions in surrounding touched code, duplicated writers/subsystems,
   misleading docs, or any premature success/ship claims? Rating80/65/50/45 rank240 remains
   saved and appropriate. No migration of primary checkout, scheduler, delete, merge or deploy.

Output one concise graded verdict with file:line evidence, concrete minimal fixes and
explicit swept file declaration. Address every known finding, then additional material ones.
Review-only: edit this relay file only. No code edits, no real network mutations, no config
changes, no full/test/*.sh suites in this linked worktree. Deterministic probes may use
isolated temp fixtures without touching repo state; parent executes full-clone runtime tests.
Finish within15minutes. Set NEXT Producer / STATUS Open and release to codex-author on
changes requested; only genuine complete approval may set Approved. No git commands—the
driver owns the relay-file commit. Three review rounds maximum.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
