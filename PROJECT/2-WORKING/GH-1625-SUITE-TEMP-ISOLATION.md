---
gh_issue: 1625
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1625
title: "Test suites leave merge-cleanup-shaped folders in the real system temp directory (fixture PRs pr-1 / pr-2)"
status: "In Progress (plan written, awaiting plan QA)"
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
| Reproduced the defect on `origin/development` 086b657ea (all four suite modules leak and call production pruning). Plan written. | Codex plan QA, then implement the one-file change. |

## Observed problem (reproduced 2026-11-25, base `7f2f1cce5`)

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
(kept only because they were not removable git clones). The test run therefore applies production
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

- A1 (red control, before): with `TMPDIR=<sealed S>` containing five planted old tool-shaped folders,
  running `python3 test/gh436-merge-cleanup.py` on the unpatched base leaves ≥1 `merge-cleanup-*` folder
  in S and logs a `Scratch pruning` line naming S. (Observed: 41 folders, pruning line under S.)
- A1 (after): same command on the patched branch leaves 0 `merge-cleanup-*`/`merge-check-*` folders and
  no `gh436-suite-tmp-*` folder in S, the five planted folders are byte-identical (marker files intact),
  and no `Scratch pruning` line names S. The suite result stays OK with the same test count (227).
- A2 (gate path): `bash test/gh436-merge-cleanup.sh` passes in a disposable clone.
- Failure modes caught: a fix that only isolates the wrapper fails A1's direct run; a fix that leaves the
  per-run dir behind fails the "no gh436-suite-tmp-*" check; an empty or vacuous run fails the test count.

## Preflight bet check

- Outcome sought: running the merge-cleanup suite never touches the developer's real temp directory.
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

(filled at handoff)
