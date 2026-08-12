# GH-386 — recorded negative control (#419)

Test:     `test/gh386-turn-budget-honesty.sh` (TEST_SOFT_FAIL=1)
Baseline: `f17f33ab57f3a28c2ef109bfd4163ea37be41817` — the two claude-turn twins at 600s, and both swarm-preflight twins with the
          300/600/900 ladder and the dead `RELAY_TURN_TIMEOUT_S=<n>` suggestion.
Date:     2026-08-11

Part C is the assertion worth watching. It exercises the shipped ladder across a range of
artifact sizes and requires every emitted budget to be at least the shared default. Pre-fix
the ladder bottoms out at **300**, so the packet advises SHORTENING a turn in a sentence whose
own words promise headroom — and that is the state a PARTIAL fix leaves behind: raise the
claude default to 900, forget the ladder, and small phases start being told to use 300.

## PRE-FIX — the control is OBSERVED failing

```
== test: gh386-turn-budget-honesty ==
  workdir: <tmp>
-- A: every builder shares one wall-clock default
  FAIL: GH-386: a builder still differs — claude-turn.py=600 claude-turn.sh=600. An undocumented per-agent cap is what killed a turn mid-edit.
  FAIL: GH-386: the raised cap carries no rationale — the next reader will assume 600 was deliberate
-- B: the packet points at turn_timeout_s, not a dead env var
  FAIL: GH-386: utils/py/swarm_preflight.py's packet text still cites the stale '300s default' — no turn script has defaulted to 300 since GH-320
  FAIL: GH-386: utils/swarm-preflight.sh's packet text still cites the stale '300s default' — no turn script has defaulted to 300 since GH-320
  FAIL: GH-386: utils/py/swarm_preflight.py still prints a bare RELAY_TURN_TIMEOUT_S=<n> as the suggestion — nothing reads it
  FAIL: GH-386: utils/swarm-preflight.sh still prints a bare RELAY_TURN_TIMEOUT_S=<n> as the suggestion — nothing reads it
  FAIL: GH-386: utils/py/swarm_preflight.py does not name the field that applies the budget
  FAIL: GH-386: utils/swarm-preflight.sh does not name the field that applies the budget
  PASS: marathon.sh really does apply the plan's turn_timeout_s to the phase
-- C: no suggestion may fall below the shared default
  FAIL: GH-386: could not find the sizing ladder to exercise — this test has gone vacuous and must be repaired, not ignored

  gh386-turn-budget-honesty: 1 passed, 9 failed
```

## POST-FIX — one cap, and a suggestion that names the field which applies it

```
== test: gh386-turn-budget-honesty ==
  workdir: <tmp>
-- A: every builder shares one wall-clock default
  PASS: all five builders default to 900s on BOTH lanes
  PASS: the claude shim records WHY the cap is not a cost control (CLAUDE_MAX_BUDGET is)
-- B: the packet points at turn_timeout_s, not a dead env var
  PASS: swarm_preflight.py: the packet text no longer cites the stale '300s default'
  PASS: swarm-preflight.sh: the packet text no longer cites the stale '300s default'
  PASS: swarm_preflight.py: the suggestion is no longer a dead env-var assignment
  PASS: swarm-preflight.sh: the suggestion is no longer a dead env-var assignment
  PASS: swarm_preflight.py: names turn_timeout_s, the field marathon.sh actually reads
  PASS: swarm-preflight.sh: names turn_timeout_s, the field marathon.sh actually reads
  PASS: marathon.sh really does apply the plan's turn_timeout_s to the phase
-- C: no suggestion may fall below the shared default
  PASS: across every artifact size, the lowest suggestion is 900s — never below the 900s default

  gh386-turn-budget-honesty: 10 passed, 0 failed
```
