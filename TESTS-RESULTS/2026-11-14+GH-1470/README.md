# GH-1470: conflict hubs and clean-first landing passes

Verified source revision: `5d1d69c32f553dd7ca71aa91975986a98f9906fe`.
Subsequent task commits retain evidence and update governance only; the push hook gates the final head.
All mutation-bearing checks ran in disposable full gate clones, never either maintained primary.

## Acceptance evidence

`manual-check-driver.py.txt` reuses the existing gh534 LedgerFixture (temporary bare origin and fake gh)
and calls the real forecast, formatter, comparison, selection writer and CLI. It is retained evidence,
not a registered suite or a new file under `test/` (GH-831).
`manual-check-run.log`: 10 scenarios, OK, exit 0:

- H1: two base hubs plus six clean members; exact pass lists and hub/clean counts; pass 1 alone is direct.
- H2: degree-selected hub is labelled a greedy heuristic.
- H3: distributed conflicts stay group.
- H3b: a simulated conflicting second fold stays group.
- H3c: even with fewer than three conflicts, a bad clean fold or a majority waiting on a hub stays group.
- H4/H4b: failed fetch, failed merge-tree and unknown clean fold withhold advice.
- H5: a hard dependent waits with its hub.
- H6: disjoint and one-small-conflict shapes retain plain direct.
- H7: real CLI dry-run output, explicit-decision refusal, pass-aware comparison, whole-queue override,
  stale heads, pass-1 execution (only clean PRs merge), and a fresh pass-2 dry run with new pins.
  Exit 4 after the fixture landing means sweep pending; pass-2 dry run exit 3 is the expected B1 handoff.

## Red controls

`red-control.log`: the same H1 queue on `origin/development` at
`e0586fc30c002df7e2d88341247143ddd4264e9c` recommends group for 4 of 8 PRs and prints no pass list.
The driver asserts that pre-fix behavior (exit 0); this is the witnessed old behavior, not acceptance.
`small-queue-red-control.log`: H3c at `83de02a7e` (before the small-queue correction) exits 1 with
`AssertionError: 'direct' != 'group'`. Final H3c passes, establishing rejection of that unchanged defect.

## Existing coverage and governance

`existing-suite-summary.txt`: 227 checks, OK, exit 0. `pdda.log`: exit 0, no errors, 689 warnings
(historical issue-state lookups unavailable in the local-origin clone and existing governance drift).
`releases-check.log`: clean, 0 failures, 10 existing warnings. Live GH-1470 was separately verified OPEN.
The existing collector includes the merge-cleanup parity guard. The CLI flag list remains unchanged.
The canonical teardown instructions follow `scan_directories`: prefix filtering precedes discovery,
the primary is explicitly added and preserved, and Phase 6 refreshes only the resulting checkout list.
`--prefix` does not suppress dangling-symlink pruning; the skill states this limit.

Independent review did not run. No new test suite, flag, landing gate, or deployment was added.
