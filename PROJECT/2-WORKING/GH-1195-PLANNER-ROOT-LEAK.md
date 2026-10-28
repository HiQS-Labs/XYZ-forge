---
gh_issue: 1195
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1195
title: "marathon-plan Python engine reads the primary clone's ledger from a sibling clone (XYZ_HARNESS wins over the script's own tree)"
status: active
created: 2026-10-24
updated: 2026-10-24
owner: claude-fable-5-1 (start-task, 2026-10-24)
doc_type: bugfix
complexity: 1
risk: 2
effort: 1
phases: 1
ratings_provisional: false
rating: 72/70/50/92
non_goals:
  - Changing `harness_home()` precedence itself (GH-1001 fixed the vendored case; a global `XYZ_HARNESS` is a supported way to point a foreign repo at a harness).
  - `marathon_drive.py:1122` (`default_root = repo_root()`), the same class on the drive side; jog already passes `--target-root` (#1100/#1104). Tracked separately if it bites.
  - Any change to `wave_reconcile.py`, `_marathon_plan.py` or the Bash planner.
  - New tests, suites or registry entries (GH-831).
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1127 (local reconcile is the default; this bug refuses a local reconcile whenever the primary's stale ledger yields a finding attributable to the PR's closed issues)
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1100 (same leak class on the jog → marathon-drive side, fixed by #1104)
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1001 (harness_home precedence; vendored copy must win over XYZ_HARNESS)
  - utils/py/marathon_plan.py:112-114, utils/py/harness_paths.py:31-60, utils/marathon-plan.sh:26-28
goal: >
  `bash utils/marathon-plan.sh` run from any clone reads THAT clone's releases.db, PROJECT/2-WORKING and
  ROADMAP, whether or not the shell exports a global XYZ_HARNESS, so a local wave_reconcile from a sibling
  landing clone no longer rolls back on the primary's stale ledger.
---

# GH-1195 · marathon-plan reads the primary clone's ledger from a sibling clone

## Status

| What was just completed | What's next |
|---|---|
| Plan QA Approved r2 (`b7baa523`). Fix landed as `5623dfd7`; row admitted (`--accepted-start`). Checks A/B/smoke green with red controls in disposable clones; six focused suites green (`TESTS-RESULTS/2026-10-24+GH-1195/SUMMARY.md`). | Tier-3 `ci-local.sh` running in the `-gate` clone; final Codex QA; ready PR against development (do not merge). |

## Observed (ground truth)

`utils/marathon-plan.sh` defaults to the Python engine (`XYZ_PYTHON` unset → 1). The wrapper exports
`XYZ_ROOT` and `PYTHONPATH` to **its own** clone (`utils/marathon-plan.sh:26-28`) and execs
`utils/py/marathon_plan.py`, which resolves its default root as `repo_root()` with no arguments
(`marathon_plan.py:112-114`). `harness_home()` (`harness_paths.py:31-60`) prefers `XYZ_HARNESS` when it
is set and is a directory, before falling back to this file's own location. On this device
`~/.zshrc:67` exports `XYZ_HARNESS="$HOME/Documents/GH Repos/XYZ-forge"` for every login shell, so from
any sibling clone the engine's `ROOT`, and therefore `<ROOT>/releases.db` (`_marathon_plan.py:815`),
`PROJECT/2-WORKING` and `ROADMAP.md`, all belong to the **primary** clone.

Measured in the task clone (2026-10-24, login env):

```text
repo_root()        = <primary clone>                          ← the primary
anchor on own file = <task clone: XYZ-forge-gh1195-planner-root-leak-2026-10-24>
```

Red control (recorded, `TESTS-RESULTS/2026-10-24+GH-1195/before-fix-red-control.txt`): with this
clone's `releases.db` moved away, `bash utils/marathon-plan.sh --format json` still loaded a ledger
and produced a report — planner **rc=4** (drift findings), not the rc=3 "cannot read releases.db" that
reading this clone would give — and it wrote `PROJECT/2-WORKING/MARATHON-PLAN-2026-10-24.md` into the
**primary** clone (`before-fix-primary-write.diff`, reverted by hand). That run used the live primary as
the alternate clone; the plan's check A below repeats it only against disposable clones and with
`--dry-run`. The 2026-10-24 #1192 landing hit exactly this:
`wave_reconcile.py --pr 1192` wrote the clone's rows to Completed, then the planner step saw the
primary's still-parked GH-763 row, reported `already-closed`, and rolled everything back. The
operator workaround was `QUEUE_PLAN_ROOT="$PWD"`.

The issue's note that `XYZ_HARNESS` was unset in that shell was wrong: the variable comes from
`~/.zshrc` and is present in every login shell on this device. The issue's root-cause paragraph is
otherwise exact.

## Smallest fix (one line, one writer)

`utils/py/marathon_plan.py:112`: `default_root = repo_root(anchor_file=__file__)`.

`harness_home(anchor_file=<existing file>)` returns `dirname(file)/../..`: the clone root in a
canonical checkout, `<repo>/.xyz` in a vendored one, where `repo_root()` then returns
`dirname(.xyz)` as today. The `XYZ_HARNESS` and `__main__`-under-`.xyz` branches are never consulted,
which is the same precedence GH-1001 established for a script running from inside a vendored copy.
`QUEUE_PLAN_ROOT` still overrides. The Bash engine already does this (`marathon-plan.sh:97/102`
derive `ROOT` from `_here_parent`), so the fix brings the Python engine to the wrapper's own rule.

Alternatives rejected: (a) have `wave_reconcile.py` export `QUEUE_PLAN_ROOT` — fixes one caller and
leaves every direct `marathon-plan.sh` run wrong; (b) change `harness_home()` precedence — a shared
resolver used by every harness tool, blast radius far beyond this defect, and a global `XYZ_HARNESS`
is a supported configuration for foreign repos.

Rollback: revert the one line.

## Verification (GH-831: no new tests; receipts under `TESTS-RESULTS/2026-10-24+GH-1195/`)

All checks run in **two disposable sibling clones**, never the live primary: clone **A** (the
candidate, where the planner runs) and clone **B** (the alternate, which `XYZ_HARNESS` points at).
Every planner run uses `--dry-run` so no plan file is written anywhere; the planner's own exit status
is captured directly (`rc=$?` on the planner command, not on an outer transcript). Each receipt is
listed in `provenance.jsonl` (artifact, sha256, exit code, revision).

1. **Manual check A (missing-DB red → green).** In A, move `releases.db` aside; `XYZ_HARNESS=<B>`;
   run `bash utils/marathon-plan.sh --dry-run --format json; echo rc=$?`. Reverted code: a ledger
   loads and a report renders (planner rc 0/4/5 depending on B's drift state) because it read B.
   Fixed code: planner **rc=3** with `marathon-plan: cannot read releases.db` (or the no-table
   variant) because it now reads A. Both runs leave B's tree byte-identical (`git -C B status
   --porcelain` empty before and after). Restore A's ledger.
2. **Manual check B (resolver).** In A, `PYTHONPATH=utils/py python3 -c` printing `repo_root()` vs
   `repo_root(anchor_file='utils/py/marathon_plan.py')`: the first names B (the retained misfire), the
   second names A. Add a simulated vendored anchor (`<tmp>/consumer/.xyz/utils/py/marathon_plan.py`
   with `os.path.isfile` patched for that one path) and assert the anchored root is
   `<tmp>/consumer`; this is the only vendored observation, since the vendored suites stub the
   planner (see 4).
3. **Smoke, main path (distinguishable ledgers).** Make A and B differ observably: in B add one
   roadmap row via `releases_app.py roadmap add` for a sentinel issue URL (B is disposable, so this
   write is contained). In A, unpinned: `bash utils/marathon-plan.sh --dry-run --format json` must
   **not** mention the sentinel (it read A). Reverted code mentions it (it read B). **Adjacent path
   (override precedence):** in A with `QUEUE_PLAN_ROOT=<B>`, the same command **does** mention the
   sentinel: the override still wins over the anchor. Relative doc paths in the JSON are not a root
   signal (`_marathon_plan.py:1245-1266` renders none), so the sentinel row is the observable.
4. **Existing suites and their actual boundary:** `bash test/marathon-plan.sh` pins the engine
   contract with `QUEUE_PLAN_ROOT` set (`:49-61`) and so exercises the override, not the default
   root; `bash test/wave-reconcile.sh` covers the reconciler's planner call; the vendored suites
   `test/gh358-wave-reconcile-vendored-paths.sh:57` and `test/gh429-wave-reconcile-vendored-observe.sh:39`
   replace the planner with stubs and prove only tool resolution, not the vendored planner's root.
   All four must stay green; the vendored root behaviour is witnessed by check 2's anchored probe.
   Final gate chosen by `utils/ci-route.sh` on the changed paths, run once on the final commit.
5. **Deferred (issue acceptance bullet 2).** The end-to-end closing-issue `wave_reconcile.py --pr N` without
   `QUEUE_PLAN_ROOT` needs a merged closing PR; this PR's own landing (it closes #1195) is that witness and its
   outcome is recorded on the issue at landing time. See `TESTS-RESULTS/2026-10-24+GH-1195/SUMMARY.md`.

## Rating rationale (2026-10-24)

`rated 72/70/50/92`. Severity 70: a local `wave_reconcile` (the GH-1127 default) that closes an
issue is refused and rolled back whenever the primary's stale ledger yields a finding attributable to
that PR's reconciled issues (`wave_reconcile.py:1735-1752`; unrelated stale findings only warn) — the
normal state for a closing PR during a
landing; work is not lost (rollback is clean) but the landing cannot complete without an env override.
Priority 72: it sits on the landing path of every PR and on the #1200 factory lifecycle (step 5).
Recurrence: one measured incident (#1192, 2026-10-24); #1187 the same day passed only because it closed
no issue; the same leak class was fixed on the jog side in #1100/#1104 (2026-10-16). Appeal 50 neutral.
Effort 92: a one-line change at a traced seam with existing covering suites.
