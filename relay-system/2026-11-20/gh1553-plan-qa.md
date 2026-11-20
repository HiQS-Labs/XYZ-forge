# Relay: GH-1553 (KS-06) Plan QA — Amendments Are Applied, Not Just Acknowledged

STATUS: Open
NEXT: Reviewer
ROUND: 1 / 3
PRODUCER: antigravity
REVIEWER: codex
TARGET_REPO: HiQS-Labs/XYZ-forge
BRANCH: feat/XYZ-forge-gh1553-ks06-amendment-enforcement-2026-11-20
ISSUE: #1553
ROADMAP_ID: rmi-01M7W3BP6KV0Q0WYC7KFVZV750
CANDIDATE_SHA: 09619196f1a8936f649d66c3cda02933064d30db

## Producer Round 1 — Plan QA Submission

Please review `PROJECT/2-WORKING/GH-1553-KS06-AMENDMENT-ENFORCEMENT.md` against issue #1541 (KS-06, U2/U11/U12), `skills/1-hourly/kickstart/scripts/run_record.py`, and `skills/1-hourly/kickstart/SKILL.md`.

Key points:
- Reuses KS-15's `run_record.py` v1 parser/dispositions (`applied`, `superseded`, `escalated`) and adds a small read-only `check-amendments` subcommand (exit 2 on unresolved/escalated/parse errors, exit 0 only when zero unresolved remain).
- Codifies in `kickstart/SKILL.md` that the run record is authoritative (thread messages are wake-ups only), mandates checking before every landing and on every resume, and enforces crash-after-ack blocking until resolved.
- Paired red/green manual controls for the 03:12Z amendment (#1495/#1496) and crash-after-acknowledgement resume block.

If the plan is sound, set `STATUS: Approved` and `NEXT: Done`.
