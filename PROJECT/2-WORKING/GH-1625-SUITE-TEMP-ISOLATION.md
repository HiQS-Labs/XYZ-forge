---
gh_issue: 1625
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1625
title: "Test suites leave merge-cleanup-shaped folders in the real system temp directory (fixture PRs pr-1 / pr-2)"
status: "In Progress (final QA approved; PR ready, awaiting merge)"
created: 2026-11-25
updated: 2026-11-25
owner: Claude (start-task)
doc_type: bugfix
goal: "The merge-cleanup unit suite runs inside its own temp directory, so it neither leaves fixture landing clones in the real system temp nor runs production scratch pruning against it."
effort: 1
complexity: 1
risk: 1
phases: 1
---

# GH-1625 — merge-cleanup suite temp isolation

## Status

| What was just completed | What's next |
|---|---|
| Plan QA Approved (r3); final QA Approved (r2, `relay-system/2026-11-25/gh1625-final-qa.md`). Fix `ada4644db` + boundary-fixture fix `bbd6ba299`; A1 and A2 recorded in `TESTS-RESULTS/2026-11-25+GH-1625/`. | Full gate at push from the disposable gate clone; PR ready, awaiting merge. |

## Observed problem

Recon runs below used an archive of `origin/development` at `086b657ea` (2026-11-25 ~20:40 local). The task
branch was cut later from `7f2f1cce5`; the acceptance red control (A1 before) is re-run on `7f2f1cce5`
itself so before/after compare one exact base. Neither touched file changed between the two revisions
(checked at implementation time with `git diff --stat 086b657ea 7f2f1cce5 -- test/gh436-merge-cleanup.py test/gh534_phase_*_tests.py skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`).

`merge_cleanup.land_prs` → `_land_prs_loop` creates its landing workdir with
`tempfile.mkdtemp(prefix="merge-cleanup-")` and, in its `finally`, always calls
`prune_retained_scratch(workdir)`, which lists `Path(tempfile.gettempdir())` and removes older
`merge-cleanup-*` / `merge-check-*` folders beyond the newest three
(`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:387-430`, `:2013-2025`, `:2531-2545`).
`run_isolated_check` creates `merge-check-*` folders the same way.

The unit suite drives those paths with fixture PRs (#1, #2) in the developer's real temp
directory. Its only gate entry is `test/gh436-merge-cleanup.sh` → `test/gh436-merge-cleanup.py`,
which also collects `gh534_phase_a/b/c_tests` (`gh436-merge-cleanup.py:1382-1384`). Nothing in any
of the four modules sets `TMPDIR` or `tempfile.tempdir`.

Recon ledger (each module run alone with `TMPDIR=<fresh sealed dir>`, archive of `origin/development`):

| run | result | `merge-cleanup-*`/`merge-check-*` left in the sealed dir | `Scratch pruning` log lines |
|---|---|---|---|
| `test/gh436-merge-cleanup.py` (whole gate suite, 227 tests) | OK | 41 (plus 5 `gh1140-helper-*`) | 67 (66 "skipped: another merge_cleanup.py is running", 1 real pass) |
| `test/gh534_phase_a_tests.py` | OK | 1 | 11 |
| `test/gh534_phase_b_tests.py` | OK | 14 | 10 |
| `test/gh534_phase_c_tests.py` | OK | 26 | 47 |

In the gh436 run, five planted old tool-shaped folders (`merge-cleanup-plant00N/pr-9N-deadbeef-abcdefgh`,
mtime 2026-11-20) were considered by the real pruning pass: `Scratch pruning: removed 0 … kept 5: merge-cleanup-plant005, …`
(the five survived; the log does not say why). The test run therefore applies production
pruning to whatever directory is the system temp. On the operator's Mac, the real temp held 11 fixture
folders from one 16-minute gate window on 2026-11-25 (10:20–10:36), matching the issue.

Root cause: the suite inherits the host temp directory; nothing scopes it. Fix site: the suite's
own entry. Why not in `merge_cleanup.py`: production behaviour (where a real landing keeps its
clones, and what pruning sees) is correct for real runs; the defect is that tests share it.

## Requirements (from the issue)

1. Suites that drive merge-cleanup run with a per-run temp directory and remove it on exit.
2. Existing suites only (GH-831): no new test file, suite or registry entry.

## Plan

Smallest affected surface: the top of `test/gh436-merge-cleanup.py`, the one module every gate run
of these suites goes through (the wrapper `exec`s it; the three phase modules are imported by it).

1. Before `merge_cleanup` and the phase modules are imported, create one directory with
   `tempfile.mkdtemp(prefix="gh436-suite-tmp-")` under the inherited temp dir, set
   `os.environ["TMPDIR"]` to it and reset `tempfile.tempdir = None`, so in-process `mkdtemp`,
   `gettempdir()` (and therefore `prune_retained_scratch`) and every child process resolve inside it.
2. Register `atexit` removal of exactly that directory with `shutil.rmtree(..., ignore_errors=True)`,
   guarded so it removes only a path that equals the created one, has the `gh436-suite-tmp-` basename
   prefix, and whose parent is the original temp dir (GH-177 lesson: never remove an unverified path).
3. Keep it in the Python module rather than the shell wrapper so direct runs
   (`python3 test/gh436-merge-cleanup.py`) are isolated too, and no shell `EXIT` trap is introduced.

Non-goals: changing `merge_cleanup.py` pruning or dry-run behaviour; #1578 (pruning ignores unpushed
commits); isolating the standalone direct runs of `gh534_phase_*_tests.py` (not gate entries; they are
collected via gh436); other suites' temp hygiene (#853 umbrella).

Risks / rollback: tests that compare paths with `gettempdir()` now see the per-run dir; the sealed
`TMPDIR` runs above already show all 227 tests pass with a non-default temp dir. Rollback is reverting
one hunk.

## Acceptance checks (manual, recorded under `TESTS-RESULTS/2026-11-25+GH-1625/`; no new tests, GH-831)

Setup for A1 (both runs, fresh each time): a sealed parent S with five planted old tool-shaped folders
`merge-cleanup-plant00N/pr-9N-deadbeef-abcdefgh/marker`. Record before the run: the sorted list of S's
entries and a SHA-256 of each planted tree (`find … -type f | sort | xargs shasum -a 256`). Run from a
disposable archive of the revision under test with `TMPDIR=S`.

Enumeration probe (manual, temporary, never committed; disposable archive copies only), two edits to
`prune_retained_scratch` in `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`:
1. Make passes deterministic: replace `other = _other_merge_cleanup_running()` (L396 on `7f2f1cce5`) with
   `other = False`, so the early return at L397-399 never fires (in the recon, 66 of 67 calls returned there).
2. Record the real listing: immediately before `for d in root.iterdir():` (L406), append `str(root)` to the
   file named by `GH1625_PRUNE_TRACE`. Only a pass that actually reaches the directory listing writes a line.
Set `GH1625_PRUNE_TRACE=<file outside S>` for the run. The same two edits go into the before and after copies.

- A1 before (red control, on `7f2f1cce5`): `python3 test/gh436-merge-cleanup.py` →
  (a) ≥1 **new** `merge-cleanup-*`/`merge-check-*` entry in S (entries minus the recorded list);
  (b) the trace file is non-empty and contains the resolved S path.
- A1 after (patched branch): same setup and command →
  (a) 0 new `merge-cleanup-*`/`merge-check-*` entries in S and no `gh436-suite-tmp-*` entry left in S;
  (b) the trace is **non-empty** and every line is a path under `S/gh436-suite-tmp-*`, none equal to S
      (an empty trace fails the check: it would mean pruning was never observed);
  (c) the five planted trees' checksums equal the recorded ones;
  (d) the suite prints `OK` with the same test count as the before run (227 at recon).
- A2 (gate path, no probe): `bash test/gh436-merge-cleanup.sh` passes in a disposable full clone.
- Failure modes caught: a fix that only isolates the wrapper fails A1's direct run; a fix that leaves the
  per-run dir behind fails (a); pruning still listing the inherited parent fails (b) even if nothing is
  deleted or logged; touching the plants fails (c); a vacuous or partial run fails (d).

## Preflight bet check

- Outcome sought: running the merge-cleanup suite leaves no fixture folders beside the developer's real
  temp contents and never runs pruning over that directory (its one per-run child is created there and
  removed on exit).
- Smallest viable bet: ~10 lines at the top of the existing suite entry module. Not building: a shared
  fixture library, changes to production pruning, or isolation for unrelated suites.
- Alternative rejected: setting `TMPDIR` in `test/gh436-merge-cleanup.sh` — misses direct Python runs and
  needs an `EXIT` trap (the GH-177 hazard class). Patching `prune_retained_scratch` in tests — leaves the
  fixture folders behind and hides the shared-directory cause.
- Rollback: revert the hunk.

## Rating (PRS, 2026-11-25)

`rated 45/45/50/85`. Severity 45: today the harm is clutter and misleading pruning counts in real landing
logs; the data-loss path (a test run pruning an operator's real retained landing clone) is reachable in
code (production pruning runs against the real temp during the suite) but needs #1578's missing
unpushed check to lose work, and was not observed. Priority 45, severity-led; no operator deadline.
Appeal 50 neutral. Effort 85: one module, existing suite verifies. Recurrence: unknown trend (first report).

## Lessons Learned

NO_ENTRY. Candidate: suites that call production code using `tempfile.gettempdir()` should scope `TMPDIR` in the suite entry. Edit verdicts: bootstrap `helped` (A1 before/after); boundary-fixture fix `helped` (A2). Already covered by the #853 suite-isolation umbrella, so no separate lesson row.
