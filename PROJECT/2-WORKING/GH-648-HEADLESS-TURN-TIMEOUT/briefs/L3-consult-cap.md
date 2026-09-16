---
title: "L3 brief — #276/#480 consult cap policy (partial results, 600s default, truthful kills)"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  Consult surfaces a marked PARTIAL answer at the cap, raises the default cap to 600s, and kills only with truthful reason labels.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L3 — #276 + #480: consult cap policy (partial results, bigger default, truthful kills)

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Issues: #276, #480 · Wave 1 · depends_on L2

## Goal
In `utils/py/consult.py`:
1. Default per-advisor cap 300s → 600s (env override `CONSULT_TIMEOUT` stays).
2. On cap: surface the advisor's PARTIAL output — flush the transcript's substantive content marked `PARTIAL — hit the Ns cap, no verdict` — instead of the bare `advisor failed or exceeded the cap` line. #480's receipt: 5,505 lines of genuine audit work discarded at the cap.
3. Consume L1's reason model at the kill site (`consult.py:306`): a kill justified by an idle signal must carry the truthful label (`idle-unknown` when no in-flight check succeeded). Decide in-lane whether `idle-unknown` extends once or kills-labeled — either is fine; document the choice in the suite.

## Rules
Python twin authoritative (`utils/py/consult.py`; `relay-automation/consult.sh` is frozen). Register the suite in `validate.sh` TESTS. `bash validate.sh` green.

## Acceptance / Guard
`test/gh648-l3-consult-cap.sh`: (a) default cap reads 600; (b) a stub advisor killed at the cap leaves a marked PARTIAL answer the consumer can read; (c) an idle-killed advisor's failure line carries the truthful reason label; (d) a completing advisor is unaffected.
