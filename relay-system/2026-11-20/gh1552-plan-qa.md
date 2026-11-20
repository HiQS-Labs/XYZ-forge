# Relay: GH-1552 (KS-08) Plan QA — Safe Self-Recovery of a Killed Landing

STATUS: Open
NEXT: Reviewer
ROUND: 1 / 3
PRODUCER: antigravity
REVIEWER: codex
TARGET_REPO: HiQS-Labs/XYZ-forge
BRANCH: feat/XYZ-forge-gh1552-ks08-killed-landing-recovery-2026-11-20
ISSUE: #1552
ROADMAP_ID: rmi-01M7W39V9G92M8W97MX702YQCA
CANDIDATE_SHA: 2aa332a1805d45ac88aebc8a9054bb727137863b

## Producer Round 1 — Plan QA Submission

Please review `PROJECT/2-WORKING/GH-1552-KS08-KILLED-LANDING-RECOVERY.md` against issue #1541 (KS-08), `skills/1-hourly/kickstart/SKILL.md`, and `skills/2-daily/merge-cleanup/scripts/attempt_record.py`.

Key points:
- Zero new runner/wrapper; reuses `attempt_record.py` (`MERGE_CLEANUP_RECORD`, `finish --outcome aborted-*`, `MAX_REPAIRS=2`) and `merge_cleanup.py` (`--reconcile-pr N --execute`, `--resume --execute`).
- Fail-closed two-step precondition: (1) full stopped-ownership proof (owner, lock, builders/checks/push/sessions) + exact record & index lookup preserving repair count; (2) remote PR state check (`MERGED` -> `--reconcile-pr`, `OPEN` unchanged head -> `finish aborted-*` + `--resume`, changed/unknown -> hold).
- Disposable-clone paired red/green checks against real `attempt_record.py`.

If the plan is sound, set `STATUS: Approved` and `NEXT: Done`.
