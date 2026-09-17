---
title: "L4 brief — #285 revalidate whether the cap kills the child at HEAD"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  Fixture-prove agy-turn's cap behavior at HEAD; close #285 as already-fixed or fix what still reproduces.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L4 — #285 revalidate: does the cap kill the child at HEAD?

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Issue: #285 · Wave 1 · depends_on L3

## Goal
#285 claimed `agy-turn` returns exit 7 at the cap but never kills the child (fixture: `RELAY_TURN_TIMEOUT_S=1` vs 5s stub; codex-turn killed, agy didn't). At HEAD, `utils/py/agy-turn.py` ~`:500` calls `_kill_turn_group(proc)` at the wall cap, so the issue may already be fixed in the Python twin.

First build `test/gh648-l4-285-revalidate.sh` (same fixture shape: short cap vs sleeping stub, both agy and codex twins). Then:
- If agy's cap fires fast (child group dead well before the stub's natural end): close #285 citing the commit that fixed it — put the sha in the suite receipt and the issue close. NO production change.
- If it still reproduces: fix in `utils/py/agy-turn.py` (Python twin only) and keep the suite red→green.

## Rules
`utils/py/agy-turn.py` is in your write-set ONLY for the still-reproduces branch. Register the suite in `validate.sh` TESTS. `bash validate.sh` green.

## Acceptance / Guard
The suite asserts the cap fires fast for BOTH twins (agy, codex) and records which case happened (already-fixed close vs fix landed).
