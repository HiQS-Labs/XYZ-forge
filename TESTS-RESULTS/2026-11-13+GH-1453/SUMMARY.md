# GH-1453 manual checks: Jog checkpoint, local state and one reconcile

Code under test: `utils/py/jog_run.py` at `f2eec6528` (unchanged through `7be8cfc02`, which adds the
skill text). Base for red controls: `6c0c76bb5`. Platform: macOS, Python 3.

The checkpoint has no suite, and the repo adds none (GH-831). These are manual checks driven by
`fixture-checks.py.txt` (run as `python3 fixture-checks.py.txt <cand|base> <rev> <source-clone> <workdir>`).
Each check builds its own fixture: a local bare origin, a primary clone with the primary pin in its
local git config, a publication clone, and an `other` clone that plays another session. Ledger
writes go through the supported CLI and the canonical Jog writers. `XYZ_WORK_CONNECTORS=0` keeps
every write local. Nothing touches GitHub or the maintained primary.

| Check | Candidate | Base `6c0c76bb5` |
|---|---|---|
| A1 moved, disjoint | PASS: reconciled and published; remote row and wake's queue row both present | red: rejected push, `ContractError`, journal `committed` |
| A2 behind at start, stale tracking ref | PASS: starts, reconciles, publishes | red: `checkpoint requires primary HEAD at published origin/development` |
| A3 overlap and restore | PASS: named stop for GH-1315, exit 2 from the command line, no traceback, primary restored | not run (base has no reconcile) |
| A3 control (no overlap) | PASS: same fixture reconciles | not run |
| A4 unmoved (preservation) | PASS | PASS (same parent, subject and console line) |
| A5 rerun after a stop | PASS: publishes, no task dispatched | not run |
| A6 skill text | PASS: 17 listed messages all found in `jog_run.py` | red: section absent |
| A7 moved again during publication | PASS: two reconciles, one publish, `attempt_count` 1 | not run |
| A8 code-only movement | PASS: one merge commit, ledger files byte-equal to the checkpoint | not run |
| A9 adopted view | PASS: view committed with the checkpoint; foreign file still refused | red: `checkpoint refuses unrelated changes: [' M RELEASES-PREVIEW.html']` |
| A10 publication-only resume | PASS: merge recognised and published, no new receipt, row B unchanged | red: resume ran the orphan scan (receipts 2920 to 2921, row reset to pending) |
| A11 restore after partial view output | PASS: no `MERGE_HEAD`, tree equals the checkpoint commit, no backup; retry publishes | not run |
| A12 view conflict without a ledger change | PASS: view regenerated, nothing unmerged | not run |

Logs: `candidate-A1-A12.log` (12 checks, 0 failed), `base-red-controls.log` (5 checks, each showing
the stated base behaviour), `a6-skill-text.log`. Fixture paths in the logs are replaced with
`<fixture>` and `<task-clone>`.

## What these checks do not show

- A writer refusal during replay (plan step 4.7) has no fixture. The overlap check runs first, and no
  input was found that passes it and still makes a writer refuse. The conversion is read, not run.
- A11 writes the partial output directly instead of making a generator fail. It measures the restore,
  not a real generator failure.
- The checks drive `JogCheckpoint` and the writers directly; A3 and A5 also run the `jog run` command
  line. No builder or reviewer turn was dispatched, so this is not evidence about a full multi-task run.
- A9 shows the adopted-view gap is real on base: any repo with `RELEASES-PREVIEW.html` at its root has
  its checkpoint refused after one queue write. This repo has no such file.
- One reviewed deviation from the plan: `finish()` aborts this wake's own merge if a previous run died
  while it was open (journal has `source` and `MERGE_HEAD` exists). Not exercised by a fixture.

## Existing suites

Run in a disposable gate clone; logs `gh280-jog-marathon-adapter.log` and `jog-queue.log` in this folder.
