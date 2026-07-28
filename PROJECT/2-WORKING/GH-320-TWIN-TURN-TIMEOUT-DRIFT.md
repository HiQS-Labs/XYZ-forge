---
title: "Python turn-taker twins cap turns at 300s while their Bash twins and headers document 900s/600s"
status: "Active (2-WORKING) — found 2026-07-28 when it killed an agy review turn mid-relay. Three Python defaults aligned + parity test landed on branch marathon/gate-and-fleet-integrity-2026-07-28 (PR #318); promote to 3-COMPLETED on merge."
created: 2026-07-28
updated: 2026-07-28
owner: unassigned
gh_issue: 320
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/320
doc_type: bugfix
complexity: 1
risk: 3
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Changing what the timeout ceilings should BE — only that both lanes and the docs agree on one number.
  - Auditing past exit-7 turns that may have been this rather than a genuinely hung model.
  - Extending parity checking to other Bash/Python constants beyond the turn timeout.
related:
  - utils/py/agy-turn.py, utils/py/codex-turn.py, utils/py/claude-turn.py
  - relay-automation/agy-turn.sh, relay-automation/codex-turn.sh, relay-automation/claude-turn.sh
  - test/gh320-twin-timeout-parity.sh
goal: >
  The per-turn wall-clock ceiling an operator reads in a shim's header is the ceiling that actually
  applies, regardless of which lane executes.
---

# GH-320 — the executing Python lane caps turns at a third of the documented budget

## Status

| What was just completed | What's next |
|---|---|
| Found live when it killed the agy review turn for PR #318 at 300 s on a 900 s documented budget. Three Python defaults aligned with their Bash twins (900 / 900 / 600) and `test/gh320-twin-timeout-parity.sh` landed, registered in `validate.sh`, 10 pass / 0 fail. | Merge PR #318, then promote to `3-COMPLETED`. Open question below is deliberately not addressed here. |

## Symptom

```
agy-turn: agy -p exceeded 300s wall-clock cap — killed
relay-drive: RELAY_EXIT=7
```

The turn was driven through `relay-automation/agy-turn.sh`, whose header reads *"RELAY_TURN_TIMEOUT_S
— per-turn wall-clock ceiling in seconds (default: 900)"* and whose code is
`turn_timeout="${RELAY_TURN_TIMEOUT_S:-900}"`. Nothing in the environment set 300.

## Mechanism

XYZ has been Python-default since GH-264, so the `.sh` entry point `exec`s its Python twin — and the
twin carried a different number:

| shim | Bash default (and header) | Python default | effect |
|---|---|---|---|
| `agy-turn` | 900 | **300** | one third of the documented budget |
| `codex-turn` | 900 | **300** | one third |
| `claude-turn` | 600 | **300** | one half |
| `aider-turn` | 900 | 900 | consistent |
| `pi-turn` | 900 | 900 | consistent |

Because the Python lane executes, **300 s was the real ceiling** for three of five turn-takers while
every operator-facing document said otherwise. The failure surfaces as `exit 7` — *turn timeout /
hang* — which reads as a hung model rather than as a misconfigured ceiling. That misattribution is
the expensive part: the natural response to a hung turn is to retry it, which burns another turn at
the same wrong cap.

## Why the GH-308 freeze did not cover this

GH-308 freezes the Bash twins so Python can be authoritative. A freeze stops the twins drifting
**forward**; it says nothing about values that had **already** diverged before the banners landed,
and nothing in the suite compared the two numbers. Freezing a file is not the same as reconciling it.

## Fix

- Align the three Python defaults with their Bash twins (900 / 900 / 600).
- `test/gh320-twin-timeout-parity.sh`, registered in `validate.sh`. For all five shims it reads the
  default out of **both** files and compares them — **no expected value is hardcoded**, because a
  third copy of the number would just be a third thing to drift. It separately asserts that each Bash
  header's documented `(default: N)` matches that file's own code, since the header is what misled.

## Open question (deliberately not answered here)

The turn timeout is one constant. Nothing establishes that it is the only one that diverged before
the freeze. A general Bash↔Python constant-parity sweep is the right follow-on and belongs to GH-308
Phase 2, not to this fix.
