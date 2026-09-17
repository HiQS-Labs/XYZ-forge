---
title: "L7 brief — #242 post-kill checkout state (Wave 2)"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  A timeout-killed driven run leaves the operator checkout on the branch/HEAD it started on.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L7 — #242: timeout-killed run leaves the operator checkout switched (Wave 2)

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Issue: #242 · Wave 2 · depends_on L6

## Goal
A timeout-killed driven run must leave the operator's checkout on the branch/HEAD it started on. #242: the killed run left the operator checkout switched to development. Find the switch site in `utils/py/relay_drive.py` / `utils/py/rtl.py` (branch/worktree setup before the turn, no restore on the kill path), and make the kill path restore or never touch the operator checkout.

## Rules
Python twins authoritative. Register the suite in `validate.sh` TESTS. `bash validate.sh` green.

## Acceptance / Guard
`test/gh648-l7-checkout-aftermath.sh`: fixture run killed at a short cap → the fixture checkout's starting branch/HEAD is unchanged; a healthy run still switches as designed.
