---
title: "L8 brief — #397 zero-output turn is not a completed review (Wave 2)"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  relay-drive --review-once must classify a zero-output reviewer turn as failure, not exit-5 review coverage.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L8 — #397: zero-output turn must not read as a completed review (Wave 2)

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Issue: #397 · Wave 2 · depends_on L7

## Goal
`relay-drive --review-once` reports a shim that wrote nothing as exit 5 "non-approval handback" — a failed turn reads as a successful review round. In `utils/py/relay_drive.py`: distinguish "reviewer produced nothing" (a failed/handback-for-retry turn, exit 3-class no-progress) from "reviewer requested changes" (a real exit-5 review). Zero output must never count as review coverage.

## Rules
Python twin authoritative. Register the suite in `validate.sh` TESTS. `bash validate.sh` green.

## Acceptance / Guard
`test/gh648-l8-zero-output-handback.sh`: a zero-output reviewer turn yields the failure classification (not exit 5); a substantive changes-requested review still yields exit 5; an approval still closes Approved.
