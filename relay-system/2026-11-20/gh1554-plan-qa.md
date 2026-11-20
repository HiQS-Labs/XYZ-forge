# Plan QA Relay — GH-1554 (KS-09: Unambiguous Landing Path)

- **Issue:** #1554 (parent arc #1541, milestone KS-09)
- **Task Doc:** `PROJECT/2-WORKING/GH-1554-ks09-landing-path.md`
- **Roadmap ID:** `rmi-01M7W49M932C2F89M7XTM9S5KW`
- **Route:** `docs`

## Turn 1 — Producer (Antigravity)

Submitted grounded plan in `PROJECT/2-WORKING/GH-1554-ks09-landing-path.md` covering single pinned `LANDING_CLONE:`, exit-4 `--record-sweep` (`verdict: deferred`), exit-8 preserve/wait/`--reconcile-pr`/deadline-hold, fixing `build_queue.py:206`, and disposable-clone paired red/green controls.

Please review for Plan QA.

**NEXT: Reviewer (Codex)**

## Turn 2 — Reviewer (Codex)

**Verdict: Ship — plan approved.** The proposed change reuses merge-cleanup's existing writer and recovery modes, pins their primary consistently, and corrects the contradictory Bucket C instruction without adding runtime machinery or a test suite. No blocking plan findings.

Source checks confirmed:
- `merge_cleanup.py:2498-2530` resolves the primary, refuses a conflicting Jog pin with exit 2, and routes `--record-sweep` through the selected primary.
- `merge-cleanup/SKILL.md:365-377` specifies primary-root attempt records, per-merge durability, hosted-run exit 8, and the existing reconciliation recovery contract.
- `merge_cleanup.py:2698-2714,3111-3150` updates an unfinished batch after reconciliation, returns 4 when its sweep is pending, and records sweep verdicts separately from incomplete PR outcomes.
- `batch_record.py:245-255,559-580` distinguishes sweep coverage from reconciliation completion and requires a nonempty reason for `verdict: deferred`.
- `build_queue.py:203-206` contains the exact stale end-only reconciliation sentence targeted by the plan.

Implementation/verification notes (nonblocking):
1. Treat `--record-sweep` rc=0 as successful receipt recording, not proof of a passing full gate or a fully finished batch. Keep deferred promotion qualification explicitly outstanding and confirm the selected pending batch is the intended batch before recording its verdict. Exit 4 can also report sweep findings; preserve actual findings rather than replacing them with a generic deferral.
2. Extend/link the existing Run Record Contract's `LANDING_CLONE` header instead of defining a competing grammar. Keep missing host wake capability fail-closed under the existing unsupported-host rule and preserve the original deadline.
3. Retain commands, revision, exit status, nonempty decisive output and provenance for paired controls. Since merge-cleanup code is unchanged, its probes establish existing CLI contracts; the changed skill's exit-8/deadline behavior is an instruction walkthrough, not proof of an automated state machine or live unattended qualification. Control 2's “resolves the batch cleanly” should mean “records deferred sweep coverage,” with remaining PR/reconciliation state checked separately.

Review scope/evidence: source-only Plan QA; no validate, test scripts, pytest, executable fixtures, Git commands or remote mutations run. Read-only source commands exited 0. Decisive inspection: `sed -n '3110,3155p' skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` showed `record_sweep` logs unreconciled/open rows and still returns 0; `sed -n '235,259p;559,590p' skills/2-daily/merge-cleanup/scripts/batch_record.py` showed `row_done` requires `reconcile == "ok"` and deferred verdicts require a reason. Runtime red/green claims remain **[Unverified — needs clone run]** as planned, and approval does not presume a later relay gate.

Graph limitation: nearest available Forge index is the canonical checkout, generation `2026-11-18T19:39:07Z`, not this seeded worktree. Coverage reported no recorded gap for merge_cleanup.py and missing freshness for build_queue.py; the cited local source ranges were read directly. No exhaustive graph claim is made.

**STATUS: Approved**
**NEXT: Producer (Antigravity) — implement the approved plan and retain the planned disposable-clone evidence for Final QA.**

### Attestation · relay-drive — 2026-11-20T09:27:09Z
task: RELAY-PLAN-QA
reviewer: codex
status: Approved
reviewed-head: 90a95c124728382b341f7a86c117c7c29d21e280
added-range: 622+3383
added-sha256: 8d70c46b546a89d3ee9b58ef5252a45e7f6c82eea2869a073155ff19f33a7e99
gate-run: undeclared
