# GH-549 — gate provenance

Branch: `feat/gh549-work-events-connectors`
Qualifying commit: `f68c4621`
Environment: disposable full clone `~/marathon-clones/xyz-gh549-gate5`, un-sandboxed, independent `.git`

| Run | Commit | Result |
|---|---|---|
| Full `./validate.sh` | **`f68c4621`** | **369 / 369 PASS** — the qualifying run |
| Baseline control | `52938679` (development, no GH-549 code) | 368 / 368 PASS |
| `test/gh549-work-events.sh` | `f68c4621` | 42 / 42 |
| `test/gh402-board-sync.sh` | `f68c4621` | 34 / 34 (was 29; +5 for criterion 2) |
| `test/gh405-mock-board-harness.sh` | `f68c4621` | 19 / 19 (was 15; +4 for scope detection) |
| `test/gh436-merge-cleanup.py` | `f68c4621` | 37 / 37 |

## What the gate found, and why the baseline exists

Five gate runs, and the first four each found something.

1. `365/369` — two real defects of mine. `gh139-pipe-grep-guard` caught my suite piping
   `sqlite3` into `grep -q`, which discards the producer's exit status, so a broken probe would
   have read as a missing trigger. `ci-route` pins the releases subsystem's suite count, which
   registering this work legitimately changed.
2. `368/369` — `gh35-test-tiers` failed on `caller nice=15, worker nice=20, wanted 25`. That was
   my own `nice -n 10 ./validate.sh` wrapper hitting macOS's nice ceiling of 20, not a product
   fault. Re-run without the wrapper rather than explained away, because a receipt from a
   distorted environment attests nothing.
3. `368/369` — `gh57-releases-fuzz` exited **4**, which is that suite's own writer-lock
   contention refusal code. `validate.sh` re-runs a suite alone only on `rc=1`, so `rc=4`
   bypassed its contention handling and went straight to the failed list.
4. `368/369` — `jog-queue` this time. A *different* ledger-writer suite each run, each passing
   cleanly alone.

A rotating single failure is easy to wave through as flake. The baseline control run on
`development` came back **368/368 clean**, which made it attributable: `_record_work_event` was
running `_table_exists` — a `sqlite_master` query — inside every ledger write's transaction,
before the dict lookup that would have told it there was nothing to emit. 22 of the 27 ops are
non-eventful, so the common path paid a schema query for an event it was never going to write,
lengthening exactly the critical section those concurrent-writer suites race against.

After the fix, run 5 is `369/369`, and the run's own GH-528 contention count fell from 11-13
suites to 2 — corroboration from a number nobody was optimising for.
