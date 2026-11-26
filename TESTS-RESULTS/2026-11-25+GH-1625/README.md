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

The before run removing all five planted folders shows a test run can delete tool-shaped folders that are
not its own when pruning reaches the real temp dir. The probe forced every pass to run; on an unforced run
the "another merge_cleanup.py is running" guard skips most passes (66 of 67 in recon), so the deletion is
less frequent there, not absent. Raw summaries: `a1-before-summary.txt`, `a1-after-summary.txt`
(`<S>` substituted for the scratch path).
