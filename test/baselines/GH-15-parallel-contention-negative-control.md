# GH-15 parallel contention negative control — `test/gh528-parallel-contention-retry.sh`

Recorded 2026-08-17. Per the standing rule: a check never observed failing is not evidence.

## What had to be falsifiable

PR #20 (merged as e0178f6/25f1182) extended `test/gh528-parallel-contention-retry.sh` with three new
probes (Parts 2 and 3) that reproduce the two mechanisms GH-15 found:

1. **Stdin-swallowing re-run**: the serial re-run loop inherited the caller's stdin — which is the
   `$RESULTS` file itself — so a re-run suite that merely read stdin (SWALLOWER) drained every
   result line recorded after it, silently losing a real, always-failing suite (VICTIM).
2. **Missing result line**: a suite whose worker died before writing a result line (KILLER) was
   uncounted everywhere — neither re-run nor reported.

The control is a **revert-and-replay**, not a mutation pair: reverting `validate.sh` to its
pre-#20 content (commit `f411d31`, the frozen manifest state before this fix) while keeping the
current (post-#20) `test/gh528-parallel-contention-retry.sh` — which carries the new probes — makes
the new assertions fail against the old mechanism, and pass again once `validate.sh` is restored.

Scratch copy: `~/xyz-disposable/gh15-negcontrol` (disposable clone, never `/tmp`, never the primary
clone). `validate.sh` was swapped for `f411d31`'s content, then restored via `git checkout --`
after the observation — the repo tree itself was never mutated.

## PRE-FIX — the control is OBSERVED failing

```
== test: gh528-parallel-contention-retry ==
  PASS: a parallel failure is re-run serially before it is believed
  PASS: a suite that passes alone is counted as passed, matching the sequential verdict
  PASS: the contended suite is named in a warning (an incomplete lane list cannot fail silently)
  PASS: the lock lane is derived from TESTS, so both paths run the same set of suites
  FAIL: GH-15: the retry lost a pooled failure whose predecessor's re-run read stdin — the results file is not a suite's stdin
  FAIL: GH-15: the probe run exited 0 with an always-failing suite — a green verdict on a failed suite
  PASS: the stdin-reading suite is counted by its alone verdict and named in the contention warning
  FAIL: GH-15: a probe suite never reached the summary — a result line was lost
  FAIL: GH-15: a suite whose worker died without a result line was lost — the catch-up did not classify it
  gh528-parallel-contention-retry: 5 pass, 4 fail (TEST_SOFT_FAIL=1, exit 1)
```

The four assertions that FAIL pre-fix are the point: they pin the exact two mechanisms GH-15
found (stdin-swallowing re-run, missing result line). The five that PASS pre-fix are the
pre-existing GH-528 contract, unaffected by this fix — confirming the new probes are additive,
not a rewrite of what already worked.

## POST-FIX — same probes, same file, green

```
== test: gh528-parallel-contention-retry ==
  PASS: a parallel failure is re-run serially before it is believed
  PASS: a suite that passes alone is counted as passed, matching the sequential verdict
  PASS: the contended suite is named in a warning (an incomplete lane list cannot fail silently)
  PASS: the lock lane is derived from TESTS, so both paths run the same set of suites
  PASS: a failure recorded after a stdin-reading re-run is still re-run and reported (GH-15)
  PASS: a surviving failure still fails the run (the retry cannot launder a real failure)
  PASS: the stdin-reading suite is counted by its alone verdict and named in the contention warning
  PASS: every pooled suite is classified exactly once — the verdict rests on complete evidence
  PASS: a suite with no result line is re-run alone and classified — never silently uncounted
  gh528-parallel-contention-retry: 9 pass, 0 fail (exit 0)
```

## Stranger-run verification (acceptance criterion 3)

Ten consecutive `bash validate.sh --parallel 4` runs in a disposable full clone
(`~/xyz-disposable/gh15-verify`, durable location, gate hooks installed via
`bash githooks/install.sh`), cloned from the merged `fix/gh-15-parallel-contention-retry` branch:

| Run | Exit | Notes |
|---|---|---|
| 1 | 0 | clean, no contention warnings, no failures |
| 2 | 0 | clean |
| 3 | 0 | clean |
| 4-10 | (recorded separately as they complete — see orchestrator session log) | |

Zero failing runs observed across the runs completed at time of this record. Full ten-run tally
finalized in the same orchestrator session that authored this control.
