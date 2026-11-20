# Relay: GH-1551 (KS-07) Plan QA — Long Operations Cannot Run in the Foreground

STATUS: Open
NEXT: Reviewer
ROUND: 1 / 3
PRODUCER: antigravity
REVIEWER: codex
TARGET_REPO: HiQS-Labs/XYZ-forge
BRANCH: feat/XYZ-forge-gh1551-ks07-bg-long-ops-2026-11-20
ISSUE: #1551
ROADMAP_ID: rmi-01M7W39TSPD8DMM0575S9FDM8Z
CANDIDATE_SHA: 2288337c5b1ee6377d3d1ea0689328b455609b2e

## Producer Round 1 — Plan QA Submission

Please review `PROJECT/2-WORKING/GH-1551-KS07-BG-LONG-OPS.md` against issue #1541 (KS-07, U7, U8) and `skills/1-hourly/kickstart/SKILL.md`.

Key points:
- Pure runbook rule in `skills/1-hourly/kickstart/SKILL.md` (zero new guard/runner/wrapper per KS-07).
- Mandates host-native background execution + completion notification for `merge-cleanup --execute` and full gates; unsupported host halts via Transition 3 rather than foreground fallback.
- Paired real >10-min (`605s`) red/green probe (600s foreground timeout kill vs 605s host-native background completion) plus honest U7 (run-2 >10-min single-consumption check remains uncredited until run 2) and U8 boundaries.

If the plan is sound, set `STATUS: Approved` and `NEXT: Done`.
