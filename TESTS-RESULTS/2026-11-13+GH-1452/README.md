# GH-1452 evidence: merge-cleanup planning-time landing forecast

Manual checks and existing-suite results for the forecast added to `skills/2-daily/merge-cleanup`
(AGENTS.md *No new tests*, GH-831: no new suite, only existing coverage plus retained manual checks).
Tested commit: `cc70b1c40143613a3b2d78aa8e00b99d33220e52` (code, SKILL.md, CHANGELOG, working doc).
Later commits on the branch add only this evidence folder and review artifacts; any later code change
reopens these runs. Hashes for every file are in `provenance.jsonl`.

## How the checks ran

- A disposable full clone of the task clone (`git clone --no-local`), checked out at the tested commit.
  Its HEAD and clean status were read before and after each run and did not change.
- `manual-check-driver.py.txt` is the throwaway driver. It subclasses the existing `LedgerFixture`
  (`test/gh534_phase_b_tests.py`: bare origin plus a fake `gh`), adds `refs/pull/N/head` to the fake origin,
  and drives the real `build_landing_forecast`, `pin_selection`, `forecast_comparison` and the real CLI
  (`merge_cleanup.main`). It is kept as a `.txt` evidence file, is not collected by any runner and is not
  registered in `validate.sh`.
- `manual-check-run.log` is its output: 13 scenarios, `Ran 13 tests ... OK`, with one `EVIDENCE` line each.
- `existing-suite-summary.txt`: `python3 test/gh436-merge-cleanup.py` (the collector for the gh534 phase A/B/C
  suites and the parity guard): `Ran 227 tests ... OK`, exit 0. The "ERROR/FAILED" lines inside that log are
  expected output of tests that exercise failure paths. The full log is not retained (about 4,000 lines).
- `real-queue-forecast.log`: the forecast function called read-only against four real open PRs of this
  repository (a disposable GitHub-backed clone as primary). The CLI itself was not pointed at the real
  primary: it refuses a `--primary` other than the pinned Jog primary, which is the right behavior, and the
  fixture scenarios cover the CLI path.

## Scenario map (acceptance item, evidence, red control)

| # | What it shows | Red control witnessed |
|---|---|---|
| S1 | 3 PRs each editing the same lines of `releases.sql` and `CHANGELOG.md`, with development advanced over the same lines, forecast `group`: all conflict alone, both paths potentially B1-eligible, fold stops at #1, #2 and #3 read `conditional` | classifier broken (every merge-tree reads clean): same queue returns no `group` (recommendation null in the `S1 red control` line) |
| S2 | 3 PRs with disjoint new files forecast `direct`, all `clean` in sequence | S1 shows the same code answers differently when conflicts exist |
| S3 | a conflict on `app.py` is `needs review`, churn `high`, recommendation `group` | S2 shows `direct` without it |
| S4 | one PR with no `refs/pull/N/head` (failed fetch) is `unknown`; the recommendation is withheld (`none`); PR #3 reads `conditional` | S2 is the complete disjoint control that still says `direct` |
| S5 | a fetched head that differs from the pinned head is `unknown` | S2 |
| S6 | `git merge-tree` failing for every call (simulated old git, exit 129) makes every PR `unknown`, no recommendation | S2 |
| S7 | one PR conflicting alone with a recorded repair flips `direct` to `group` | the same queue with no attempt record says `direct` (control line in S7) |
| S8 | two PRs clean alone but conflicting with each other: #2 `conflict` in sequence, #3 `conditional`; pair listed | clean-alone result shows it is a cross-PR conflict, not a base conflict |
| S9 | one snapshot holds pins and forecast with equal heads; `verify_selection` accepts it; comparison reads `match` and `override`; wrong order, wrong heads and wrong membership are `stale`; a moved base is `stale` (remote tip, not a cached ref); an old-format pin file still verifies and compares as none | the stale cases are the rejections of a mismatched forecast |
| S10 | two writers in two processes, 40 snapshots each, read continuously: zero torn or incoherent reads, final snapshot coherent | the naive write-pins-then-read-modify-write-forecast pattern is shown producing a forecast attached to another run's pins |
| S11 | CLI: two PRs write no forecast key and print none; three PRs print the table and the advice and persist the forecast; `--scan-only` and a dry run without `--prs` leave the snapshot byte-identical; `--prs-only` forecasts; `--execute` with no `--landing-plan` exits 5, repeats the recommendation, and leaves origin refs, mutating `gh` calls and batch records unchanged; `--execute --landing-plan group` records `match` with the operator's own reason, and the issue block renders the `Forecast (GH-1452)` line | refusal state captured before and after and required equal |
| S12 | after the base moves, a `group` decision against a `direct` forecast is recorded as `override` and `stale: base moved` | S11 shows `match` and not stale |
| S13 | an old caller of `set_landing_plan` records exactly decision, reason, PRs and time; with the argument it also stores the comparison, and it survives reload (S11 reads the record from disk) | the base commit `6c0c76bb5` rejects the new argument with `TypeError`, and has no forecast code |

Note on `S11 two PRs rc=3`: the exit code comes from the existing dry-run landing simulation handing off
the fixture's deliberately conflicting ledger PRs (B1 handoff). It is existing behavior, unrelated to the
forecast, which is why that scenario asserts on the absence of a forecast rather than on the exit code.

## Real queue (plan item f)

Four non-draft open PRs forecast read-only against `origin/development@6c0c76bb5`: all four conflict with
the base on ledger files; #1446 also conflicts on `skills/1-hourly/relay-automation/relay-pkg.tar.gz`
(needs review), so the recommendation is `group`. Cost on this repository: `git clone` 9.2 s wall time and
about 101 MB of `.git` (the forecast clone has no working tree); discovery 1.7 s; the whole forecast 13.5 s
for four PRs (clone, base fetch, four PR fetches, then 4 alone and 6 pair merge-tree runs and 1 fold step,
because the fold stops at the first conflict).

## Not run, with reasons

- The real downstream 6-PR queue from 2026-11-13 (plan case e): it lives in a private repository whose
  owner may be mid-landing; touching its primary or pins is outside this task. The four-PR run above and S1
  stand in for it.
- Forks: the fixture has no fork topology. The forecast fetches `pull/<N>/head` from the base repository,
  which GitHub serves for fork PRs, and verifies each against the pinned head; a missing object is S4.
- The final qualifying gate (`ci-local.sh`) runs once on the final approved commit after final QA; its
  receipt is recorded in the PR, not here.
