---
title: "L2 brief — #241 no peer token release on timeout-kill"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  A timeout-killed commandcode turn must leave the token recoverable for a same-role retry, never released to the peer.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L2 — #241: no peer token release on a timeout-killed turn

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Issue: #241 · Wave 1 · depends_on L1

## Goal
In `utils/py/commandcode-turn.py`: when the turn is timeout-killed (exit 7 path), the shim must NOT `tick release --to <peer>`. Leave the token recoverable for a retry of the SAME role (release back to the driver/claimer, or a `task.failed`-style event) so the relay's NEXT: header and the token agree and a retry needs no fresh task id.

## Facts
#241's log sequence: killed at 900s cap (`timeout-idle-no-progress`, cpu=0.00, empty transcript) → "produced no tracked changes" → `tick release --to` peer — a failed review became a silent skip, and the spent task id was unclaimable. Codex verified the mechanism: `rtl.enforce` is called after the timeout (`commandcode-turn.py:91,120`) and its normal nonterminal path releases to the peer (`relay-turn-lib.sh:1530`). Route the killed path around that release.

## Rules
Python twin authoritative (`utils/py/commandcode-turn.py`; the `.sh` is a frozen twin). Register the suite in `validate.sh` TESTS. `bash validate.sh` green before done.

## Acceptance / Guard
`test/gh648-l2-token-aftermath.sh`: fixture turn killed at a short cap → token state shows NOT released to the peer; same-role retry is possible without a fresh task id; a healthy turn still releases normally (no regression).
