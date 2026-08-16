# GH-408 — recorded negative control (#419)

The control this repo requires is not a sentence asserting it happened. Both runs are below,
same test file, same machine, differing only in whether the three fixed sources are present.

Test:     `test/gh408-tick-failure-visibility.sh` (TEST_SOFT_FAIL=1, so one run enumerates every gap)
Baseline: `72cdc3bf7a48c588084cbba68f4bc571f0bc7da2` — the three sources at their pre-fix content
Sites:    bin/tick (claim exit status), utils/py/rtl.py (claim_task_or_exit), utils/py/marathon_drive.py (run_tick_loud)

## PRE-FIX — the control is OBSERVED failing

```
== test: gh408-tick-failure-visibility ==
  workdir: <tmp>
-- belt 1: tick claim exit status
  PASS: a won claim exits 0 (won: T-one claimed by agy)
  PASS: an idempotent re-claim by the holder still exits 0
  PASS: second claim, still under the cap, exits 0
  FAIL: GH-408: a cap-blocked claim exited 0 — no caller can detect it by status. out=lost: claim limit reached (holding T-one, T-two) — finish or release first
  PASS: the cap-hit message says 'claim limit reached'
  PASS: the cap-hit message names BOTH held tasks (T-one, T-two)
  FAIL: losing to another owner must exit non-zero and name it — rc=0 out=lost: T-one already claimed by agy
  FAIL: a spent task must not be claimable with exit 0 — rc=0 out=lost: T-one is done — not claimable
  → 'T-one' is spent; use a fresh per-relay id (e.g. --relay-task RELAY-<your-slug>)
  PASS: the spent-task message keeps its GH-18 remedy pointer
  PASS: a usage error still exits 2, distinct from a lost claim
-- belt 2: rtl.claim_task_or_exit (every turn's path)
  PASS: claim_task_or_exit still refuses to run the turn (exit 5)
  FAIL: GH-408: the 'claim limit reached' line was discarded — stderr was: agy-turn: could not establish token ownership of TURN-3 (claimer=none, expected agy) — refusing to run so the turn cannot commit with the token open under the old owner; inspect `tick info TURN-3`
  FAIL: the surfaced message must name what is held — stderr: agy-turn: could not establish token ownership of TURN-3 (claimer=none, expected agy) — refusing to run so the turn cannot commit with the token open under the old owner; inspect `tick info TURN-3`
  FAIL: a cap hit must not tell the operator to INSPECT 'tick info' — that token is healthy. stderr: agy-turn: could not establish token ownership of TURN-3 (claimer=none, expected agy) — refusing to run so the turn cannot commit with the token open under the old owner; inspect `tick info TURN-3`
  FAIL: 'tick info' is named without warning that it misleads here — stderr: agy-turn: could not establish token ownership of TURN-3 (claimer=none, expected agy) — refusing to run so the turn cannot commit with the token open under the old owner; inspect `tick info TURN-3`
  FAIL: a cap hit must point at the remedy for a cap hit — stderr: agy-turn: could not establish token ownership of TURN-3 (claimer=none, expected agy) — refusing to run so the turn cannot commit with the token open under the old owner; inspect `tick info TURN-3`
  PASS: the other-owner branch still points at 'tick info', which is correct there
  PASS: an other-owner failure is not mislabelled as a cap hit
-- belt 3: marathon_drive.run_tick_loud
  FAIL: run_tick_loud must exit with the failed command's code — got 1
  FAIL: GH-408: run_tick_loud discarded the failure's stdout — captured: Traceback (most recent call last):
  File "<stdin>", line 6, in <module>
AttributeError: module 'marathon_drive' has no attribute 'run_tick_loud'
  FAIL: GH-408: run_tick_loud discarded the failure's stderr — captured: Traceback (most recent call last):
  File "<stdin>", line 6, in <module>
AttributeError: module 'marathon_drive' has no attribute 'run_tick_loud'
  FAIL: run_tick_loud must stay quiet on success — rc=1 out= err=Traceback (most recent call last):
  File "<stdin>", line 4, in <module>
AttributeError: module 'marathon_drive' has no attribute 'run_tick_loud'

  gh408-tick-failure-visibility: 10 passed, 12 failed
```

## POST-FIX — same file, same assertions, green

```
== test: gh408-tick-failure-visibility ==
  workdir: <tmp>
-- belt 1: tick claim exit status
  PASS: a won claim exits 0 (won: T-one claimed by agy)
  PASS: an idempotent re-claim by the holder still exits 0
  PASS: second claim, still under the cap, exits 0
  PASS: a cap-blocked claim exits non-zero (rc=1)
  PASS: the cap-hit message says 'claim limit reached'
  PASS: the cap-hit message names BOTH held tasks (T-one, T-two)
  PASS: a claim lost to another owner exits non-zero and names the owner
  PASS: a claim on a spent (terminal) task exits non-zero
  PASS: the spent-task message keeps its GH-18 remedy pointer
  PASS: a usage error still exits 2, distinct from a lost claim
-- belt 2: rtl.claim_task_or_exit (every turn's path)
  PASS: claim_task_or_exit still refuses to run the turn (exit 5)
  PASS: GH-408: tick's own cap message now reaches the operator's stderr
  PASS: the surfaced message names the held tasks (H-one, H-two)
  PASS: the cap-hit path does not send the operator to the contradicting 'tick info' diagnostic
  PASS: where it does name 'tick info', it marks it as the wrong instrument
  PASS: the cap-hit path names the remedy that actually applies (tick reap)
  PASS: the other-owner branch still points at 'tick info', which is correct there
  PASS: an other-owner failure is not mislabelled as a cap hit
-- belt 3: marathon_drive.run_tick_loud
  PASS: run_tick_loud still propagates the tool's own exit code (3)
  PASS: GH-408: run_tick_loud no longer discards stdout
  PASS: GH-408: run_tick_loud no longer discards stderr
  PASS: a successful tick call stays silent (no new per-phase log noise)

  gh408-tick-failure-visibility: 22 passed, 0 failed
```
