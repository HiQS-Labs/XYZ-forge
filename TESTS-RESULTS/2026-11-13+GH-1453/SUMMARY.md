# GH-1453 manual checks: Jog checkpoint, local state and one reconcile

Code under test: `utils/py/jog_run.py` at `0e8ade643`, and the fixtures in `candidate-A1-A14.log` were
built from that commit. It is the Codex-approved implementation (`33c8682c3`) plus one later change:
three ledger reads now go through `releases_app.connect(readonly=True)` instead of opening SQLite
directly. The first push was refused by the full gate on exactly that (`gh777-inventory-ratchet`:
direct connect sites 32 to 35). Codex has not reviewed those three lines; all 14 checks were rerun on
them. Base for red controls: `6c0c76bb5`. Platform: macOS, Python 3.

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
| A6 skill text | PASS on the final wording: 22 listed message starts all found in `JogCheckpoint`, all 23 `ContractError` literals in the class listed, closed-list, scope and definition sentences present | red: section absent |
| A7 moved again during publication | PASS: two reconciles, one publish, `attempt_count` 1 | not run |
| A8 code-only movement | PASS: one merge commit, ledger files byte-equal to the checkpoint | not run |
| A9 adopted view | PASS: view committed with the checkpoint; foreign file still refused | red: `checkpoint refuses unrelated changes: [' M RELEASES-PREVIEW.html']` |
| A10 publication-only resume | PASS: merge recognised and published, no new receipt, row B unchanged | red: resume ran the orphan scan (receipts 2920 to 2921, row reset to pending) |
| A11 restore after partial view output | PASS: no `MERGE_HEAD`, tree equals the checkpoint commit, no backup; retry publishes | not run |
| A12 view conflict without a ledger change | PASS: view regenerated, nothing unmerged | not run |
| A13 own interrupted merge | PASS: run killed with its merge open and the target recorded; the rerun restores it and publishes | not run |
| A14 a merge this wake did not start | PASS: rerun refuses by name; the operator's merge and its file are still there | not run |

Logs: `candidate-A1-A14.log` (14 checks, 0 failed), `base-red-controls.log` (5 checks, each showing
the stated base behaviour), `a6-skill-text.log`. Fixture paths in the logs are replaced with
`<fixture>`, `<fixture-dir>` and `<task-clone>`.

## Correction to the first evidence run (final QA round 2, F4)

The first two runs of A1, A2 and A7 read the other session's roadmap priority from the other
session's own clone, which holds that value whether or not the reconcile preserved it. The reader now
opens `releases.db` from the bare origin's `development` (`Fx.remote_pri`). Rerun on `33c8682c3`:
published priority `[61]` (A1), `[62]` (A2), `[65]` (A7). A1 also records the same reader on the
origin before the other session's write, `[60]`, so the reader can tell a kept write from a lost one.
The earlier logs are in git history at `95c3421ac`.

## What these checks do not show

- A writer refusal during replay (plan step 4.7) has no fixture. The overlap check runs first, and no
  input was found that passes it and still makes a writer refuse. The conversion is read, not run.
- A11 writes the partial output directly instead of making a generator fail. It measures the restore,
  not a real generator failure.
- The checks drive `JogCheckpoint` and the writers directly; A3 and A5 also run the `jog run` command
  line. No builder or reviewer turn was dispatched, so this is not evidence about a full multi-task run.
- A9 shows the adopted-view gap is real on base: any repo with `RELEASES-PREVIEW.html` at its root has
  its checkpoint refused after one queue write. This repo has no such file.
- One addition beyond the approved plan: a rerun restores a merge only when the journal recorded that
  merge's target before opening it and `HEAD` is still the journal's commit (A13). Any other open merge
  is refused and left alone (A14). The first version inferred ownership from the journal alone; final
  QA round 1 caught that it could abort an operator's merge.
- A6's reverse direction matches each `ContractError` literal in the class by its leading text, so it
  shows every Jog-authored stop is listed, not that the wording of each explanation is right.

## Existing suites

Run at `f4626d09b` (before the round 1 fixes, which touch only `JogCheckpoint`) in a disposable full gate clone, identity unchanged before and after:
`gh280-jog-marathon-adapter` 227 pass, 0 fail; `jog-queue` 34 passed, 0 failed. Logs are in this folder.
Neither suite exercises `--checkpoint-root`; they show the rest of Jog did not regress.
