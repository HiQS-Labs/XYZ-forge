# GH-426 — recorded negative control (#419)

Tests:    `test/gh426-worktree-leak.sh` and `test/gh410-containment-advisory.sh`
Baseline: `b4f98ce27ead37cd380ffd0e13589abe27c967ac` — `utils/py/agy-turn.py` at its pre-fix content (auth probe inherits the caller's CWD)
Date:     2026-08-11

Two suites, because the fix is proved by an absence as much as by an assertion. GH-410's
C4c used to be a `rm -f "$ROOT/offlane.md"` cleanup block with a NOTE; the cleanup is
deleted and the assertion put in its place, so a returning leak makes that suite start
littering a live repo again instead of quietly tidying up after itself.

## PRE-FIX — both controls OBSERVED failing

### test/gh426-worktree-leak.sh
```
== test: gh426-worktree-leak ==
  workdir: <tmp>
  PASS: containment still fails the turn on an off-lane worktree write (exit 6)
  PASS: the created file is absent from the declared target repo
  FAIL: GH-426: the off-lane creation leaked into the harness repo: ~/Documents/GH Repos/xyz-3-agents-swarm/gh426probe-35081-9214.md
  PASS: the harness repo's git status is unchanged by the turn
  PASS: the agent binary is invoked more than once per turn (2) — the auth probe, then the turn
  FAIL: GH-426: the auth probe still runs with CWD=the harness repo (~/Documents/GH Repos/xyz-3-agents-swarm) — anything it writes lands outside containment and is never reverted
  PASS: the isolation worktree's base repo IS the declared target (criterion 3 holds)

  gh426-worktree-leak: 5 passed, 2 failed
```

### test/gh410-containment-advisory.sh (C4c)
```
== test: gh410-containment-advisory ==
  workdir: <tmp>
  PASS: C1 counts only the 2 bare mentions; [trace]/TICK_REPO_ROOT=/file:///]( are exempt
  PASS: C1b reports the first offending line for the operator
  PASS: C2 an empty or absent transcript yields no finding
  PASS: C3 a transcript citing the real root no longer exits 5 (got 0)
  PASS: C3b the finding is still recorded as an advisory, not silently dropped
  PASS: C4 a real off-lane WRITE in the worktree still fails the turn (exit 6)
  PASS: C4b the off-lane file did not land in the fixture repo
  FAIL: GH-426 regression: the stub's off-lane creation reached the harness root again
  PASS: C5 all five shims enforce rtl.worktree_end() — containment does not vary by builder
  PASS: C5b the prose scan was not copied into the other shims
  PASS: C6 retry-preamble provenance is asserted behaviourally in test/debug-mantra.sh, not by source grep
  gh410-containment-advisory: 10 pass, 1 fail
```

## POST-FIX — the auth probe runs in a throwaway CWD

### test/gh426-worktree-leak.sh
```
== test: gh426-worktree-leak ==
  workdir: <tmp>
  PASS: containment still fails the turn on an off-lane worktree write (exit 6)
  PASS: the created file is absent from the declared target repo
  PASS: the created file is absent from the HARNESS repo (the half GH-410's test never checked)
  PASS: the harness repo's git status is unchanged by the turn
  PASS: the agent binary is invoked more than once per turn (2) — the auth probe, then the turn
  PASS: the auth probe runs outside any real repo (cwd=agy-auth-probe.k_xywxg6)
  PASS: the isolation worktree's base repo IS the declared target (criterion 3 holds)

  gh426-worktree-leak: 7 passed, 0 failed
```

### test/gh410-containment-advisory.sh (C4c)
```
  PASS: C1 counts only the 2 bare mentions; [trace]/TICK_REPO_ROOT=/file:///]( are exempt
  PASS: C1b reports the first offending line for the operator
  PASS: C2 an empty or absent transcript yields no finding
  PASS: C3 a transcript citing the real root no longer exits 5 (got 0)
  PASS: C3b the finding is still recorded as an advisory, not silently dropped
  PASS: C4 a real off-lane WRITE in the worktree still fails the turn (exit 6)
  PASS: C4b the off-lane file did not land in the fixture repo
  PASS: C4c no off-lane creation reached the harness root (GH-426; no cleanup needed here)
  PASS: C5 all five shims enforce rtl.worktree_end() — containment does not vary by builder
  PASS: C5b the prose scan was not copied into the other shims
  PASS: C6 retry-preamble provenance is asserted behaviourally in test/debug-mantra.sh, not by source grep
  gh410-containment-advisory: 11 pass, 0 fail
```
