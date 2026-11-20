# Relay: GH-1547 (KS-04) Plan QA — kickstart_status.py Thin Derived Read-Only Status Report

STATUS: In Progress
NEXT: Reviewer
ROUND: 1 / 3
PRODUCER: antigravity
REVIEWER: codex
TARGET_REPO: HiQS-Labs/XYZ-forge
BRANCH: feat/XYZ-forge-gh1547-ks04-kickstart-status-2026-11-20
ISSUE: #1547 (parent arc #1541 v5 KS-04 + U3 + U10)
ROADMAP_ID: rmi-01M7W0NS5BZNRPBKBJP51QQ5M1

## Producer Round 1 — Plan QA Submission

Please review the implementation plan in `PROJECT/2-WORKING/GH-1547-KS04-KICKSTART-STATUS.md` for **GH-1547 (KS-04)** against `#1541` v5 KS-04, U3, U10, and GH-831 (no new test suites).

### Key Design Decisions
1. **Thin derived read-only report only:** reads existing records (`run_record.py:parse_record`, `pr_minder.py --json --no-conflict-files --repo-root <target-root>`, pinned `LANDING_CLONE` `.tick/merge-cleanup/<slug>/pr-*.json` + remote PR state, log age + U3 liveness, final-QA head vs latest landed SHA, attributable stop reason). Never writes refs/locks/state, never acts as a readiness engine.
2. **U3 Liveness strictness:** `waiting` / `quiet` / `stale-candidate` / `confirmed-stopped` / `unknown`, where log age alone NEVER yields `confirmed-stopped` and NEVER authorizes `attempt_record.py finish` or redispatch.
3. **U10 Pinned-clone isolation:** reads attempt records strictly from the run record's `LANDING_CLONE:` (explicit `--landing-clone` override only for isolated fixture replay, with mismatch warning if both differ), and pairs every in-progress attempt with remote PR state (`gh pr view` or `--remote-prs-json`, defaulting to `unknown` when unavailable).
4. **Clean forward seams:** final-QA staleness (KS-13) and attributable verbatim stop reason (KS-05) are structured cleanly so KS-05/KS-06/KS-13 plug in without rewriting KS-04.
5. **Paired verification + GH-1527 read-only check:** deterministic offline fixtures + live read-only check with `git` shim and before/after `git show-ref`, `FETCH_HEAD`, `git count-objects`.

### Review Checklist
1. Does the plan satisfy every KS-04, U3, and U10 requirement in `#1541` v5 without overbuilding a readiness engine or adding a new test suite?
2. Are all fail-closed edge cases covered (unapplied amendments even with legacy parse warnings, unattributable escalation-reason files, missing remote PR state, log age vs stopped-ownership separation, read-only invariant)?
3. If clean, append your review block and set `STATUS: Approved` and `NEXT: Done`. Otherwise list numbered findings and set `NEXT: Producer`.
