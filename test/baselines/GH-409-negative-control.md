# GH-409 — recorded negative control (#419)

Test:     `test/gh409-claim-leak.sh` (TEST_SOFT_FAIL=1)
Baseline: `72cdc3bf7a48c588084cbba68f4bc571f0bc7da2` — bin/tick, utils/py/rtl.py, utils/py/marathon_drive.py at pre-fix content
Date:     2026-08-11

Read the pre-fix run as the incident itself: case 2 leaks two claims, and cases 3 and 4 then
fail at the cap without ever exercising their own paths. That cascade is what wedged a live
marathon on 2026-08-07 — and is why the suite reaps between cases, so each one is measured.

## PRE-FIX — the control is OBSERVED failing

```
== test: gh409-claim-leak ==
  workdir: <tmp>
-- case 1: agent exits non-zero, twice, then a healthy turn
  PASS: two crashed turns leave 0 claims held (not 0)
  PASS: a healthy turn after two failures still runs (exit 0)
  PASS: the third turn did real work (HEAD moved), so it was not merely tolerated
-- case 2: worktree setup fails before the agent ever launches
  FAIL: GH-409: 2 claim(s) leaked from the worktree-failure path (exit 5 above enforce)
  FAIL: GH-409: turn 3 exited 5 after two worktree-setup failures
-- case 3: containment rejects the turn (exit 6) before enforce
  FAIL: GH-409: 2 claim(s) leaked from the containment path (exit 6 above enforce)
  FAIL: GH-409: turn 3 exited 5 after two containment rejections
-- guard: a successful turn's handoff is not clobbered by the release-on-exit path
  PASS: the successful turn's handoff to the peer survives the release-on-exit path

  gh409-claim-leak: 4 passed, 4 failed
```

## POST-FIX — same file, same assertions, green

```
== test: gh409-claim-leak ==
  workdir: <tmp>
-- case 1: agent exits non-zero, twice, then a healthy turn
  PASS: two crashed turns leave 0 claims held (not 0)
  PASS: a healthy turn after two failures still runs (exit 0)
  PASS: the third turn did real work (HEAD moved), so it was not merely tolerated
-- case 2: worktree setup fails before the agent ever launches
  PASS: two worktree-setup failures leave 0 claims held
  PASS: a healthy turn runs after two worktree-setup failures
-- case 3: containment rejects the turn (exit 6) before enforce
  PASS: two containment rejections leave 0 claims held
  PASS: a healthy turn runs after two containment rejections
-- guard: a successful turn's handoff is not clobbered by the release-on-exit path
  PASS: the successful turn's handoff to the peer survives the release-on-exit path

  gh409-claim-leak: 8 passed, 0 failed
```
