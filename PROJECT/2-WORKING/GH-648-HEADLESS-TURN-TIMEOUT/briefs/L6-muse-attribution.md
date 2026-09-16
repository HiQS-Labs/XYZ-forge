---
title: "L6 brief — #521 muse stall attribution (investigation)"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  Make muse stall/timeout reporting state what was observed using L1's reason model; attribution only, not kill policy.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L6 — #521: muse stall attribution (investigation)

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Issue: #521 · Wave 1 · depends_on L5

## Goal
#521: driven muse turns stall at cpu=0.00 with no relay block; four hypotheses already ruled out in-issue; the issue's own residual is the turn prompt. Grounded review found muse has NO idle-oracle kill path — `utils/py/muse-turn.py` delegates the wall cap to `rtl_run_bounded` (~`:279`) and uses `TurnDiagnostics` only for post-cap attribution (~`:267`).

So this lane is **attribution, not kill policy**: make muse's stall/timeout reporting state what was actually observed (stall vs cap vs unknown) using L1's reason model, and fix whatever mislabels a stalled muse turn in the run log. If the investigation confirms the issue's residual (the turn prompt itself), record that as the receipt — the code change stays attribution-only.

## Rules
Write-set: `utils/py/muse-turn.py` + suite. Python twin authoritative; register the suite in `validate.sh` TESTS; `bash validate.sh` green.

## Acceptance / Guard
`test/gh648-l6-muse-attribution.sh`: a stubbed muse-shaped stall produces a termination record whose label matches what happened (stall-unknown, not "no progress" and not a bare cap); a healthy muse turn is unaffected.
