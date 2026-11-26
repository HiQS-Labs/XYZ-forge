# GH-1625 — A1 before/after (manual check, no new tests; GH-831)

Plan: `PROJECT/2-WORKING/GH-1625-SUITE-TEMP-ISOLATION.md` (Acceptance checks). Script used: a scratch
copy of the suite archived from each revision, run with `TMPDIR=<S>` (a sealed dir holding five old,
tool-shaped `merge-cleanup-plant00N/pr-9N-deadbeef-abcdefgh/marker` folders) and a temporary, uncommitted
probe in `prune_retained_scratch`: `other = False` (so every pass reaches the listing) and one line that
appends `str(root)` to `$GH1625_PRUNE_TRACE` immediately before `for d in root.iterdir():`.

| check | before `7f2f1cce5` | after `ada4644db` |
|---|---|---|
| new `merge-cleanup-*`/`merge-check-*` in S | 36 | 0 |
| `gh436-suite-tmp-*` left in S | 0 | 0 |
| prune listings == S | 138 / 138 | 0 / 138 |
| prune listings under `S/gh436-suite-tmp-*` | 0 | 138 / 138 |
| five planted folders | all 5 **removed** | checksum-identical |
| suite | Ran 227 tests, OK | Ran 227 tests, OK |

The forced before run removed all five synthetic plants, which shows a deletion path for tool-shaped folders
that are not the suite's own once pruning lists the real temp dir. The probe forced every pass to reach the
listing. In the unforced recon on `086b657ea` (plan, "Observed problem"), 66 of 67 passes were skipped by the
"another merge_cleanup.py is running" guard, one pass listed the temp dir, and all five plants survived it.
Loss of real unpushed work was not observed.

The suite also had one boundary test writing fixed `/tmp/test_safe_root` and `/tmp/outside_repo` paths outside
any temp-dir setting (found in final QA); it now uses a per-test `mkdtemp` under the suite dir.

Raw summaries: `a1-before-summary.txt`, `a1-after-summary.txt`
(`<S>` substituted for the scratch path).

## A2 — gate entry, no probe (`bbd6ba299`)

`TMPDIR=<S> bash test/gh436-merge-cleanup.sh` in the disposable gate clone → exit 0, `Ran 227 tests … OK`,
sealed S empty afterwards, `/tmp/test_safe_root` and `/tmp/outside_repo` modification times unchanged,
clone HEAD/`core.bare`/clean state unchanged across the run.
