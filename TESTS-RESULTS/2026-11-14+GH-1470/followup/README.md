# GH-1470 follow-up: Jog precondition and stacked-member blind spot

Verified source revision: `2d1fc4eef05f078038d0a41519f72723a37216ce`.
These checks cover two items from the same 2026-11-14 downstream 12-PR landing that the first GH-1470 commits did not address:

1. Pass 1 stopped after its first merge because the post-merge Jog step refused (`rule=jog-primary`, primary not pinned). The dry run had not checked for this.
2. Stacked lanes were marked CONFLICTING on GitHub after their shared base was squash-merged, while local merge-tree stayed clean.

## Manual check (no new suite, GH-831)

`manual-check-driver.py.txt` builds throwaway local git repositories under the system temp directory, outside any checkout.
It calls the real `ledger_merge.landing_forecast`, `merge_cleanup.format_landing_forecast` and `merge_cleanup.jog_primary_precondition`.
For S5, the harness policy and the Jog row reader are stubbed; the PR-to-row mapping and the message are real.
`manual-check-run.log`: 13 checks pass, exit 0.

- S1: two hubs (one conflicts with the base, one is a pairwise hub) and four clean members. Result: `direct in passes`, exact `--prs` lists, hub/clean counts, and no stacked line.
- S2: hubs are most of the queue. Result: `group`, no passes.
- S3/S3b: a failed head fetch, and an unreadable head that makes merge-tree fail. Result: the recommendation is withheld.
- S4: #103 is built on #102. Result: `Blind spot: stacked members #102/#103 ...` is printed, and the passes advice is unchanged.
- S5: an unpinned primary with PRs that map to open Jog rows (by branch `gh-77`, and by `Closes #78`) produces a warning that names only those PRs. With no mapped PR, or a pinned primary, nothing is printed, and a pinned primary does not read the ledger at all. Unreadable Jog rows produce a "not checked" warning, never silence.

## Red control

`red-control.log`: the same driver against the previous PR head `e060b6ad5`. S1 passes, then the stacked check fails with `KeyError: 'stacked'` (exit 1).
That head had no stacked detection and no `jog_primary_precondition`.

## Existing coverage

`existing-suite-summary.txt`: `test/gh436-merge-cleanup.py` 227 tests OK. `TestParityGuard`: 7 tests OK. PDDA: no errors. `releases_app.py check`: clean.
All of these ran in a disposable local clone of the commit above.

Independent review did not run.
