# GH-1178 verification — 2026-10-22

Base `f243ccfbfb53` (origin/development) · candidate `35d965825404`. Manual check, no new suite (GH-831).

| Check | Result | Receipt |
|---|---|---|
| A2 red control: fixture against base `wave_reconcile.py` | FAIL as expected — the sibling row is left on the 2-WORKING path in both traversals | `red-control-f243ccfbf.log` |
| A1/A3/A4 + dry-run: fixture against candidate | PASS — both rows' `doc_path` and `raw_text` carry the `3-COMPLETED` destination (and not the source) in both traversals; unmoved #500 kept; rerun emits no repoint; dry-run leaves ledger unchanged, one preview per row | `green-35d965825.log` |
| Tier-2 route (`validate.sh --auto f243ccfbf..HEAD`, pdda subsystem incl. wave-reconcile, gh202, gh232, gh358) | rc=0 | `tier2-validate-auto-35d965825.log` |
| Neighbour suites gh421, gh454, gh168 | rc=0 each | `*-35d965825.log` |

The probe (`probe.py.txt`) mirrors `test/gh421-auto-wave-reconcile.sh`'s in-process harness: one PR
closes #421 and #422, which share one doc; a third row (#500) has its own unmoved doc.
`wave_reconcile` sorts closers, so #421 always runs first. Traversal is therefore set by the doc's
name: `GH-421-fixture.md` = owner first, `GH-422-fixture.md` = sibling first (#421 runs before the
doc has moved). Each log prints the observed traversal (final QA r1 finding: the first receipt
reversed the closing clauses, which sorting undid).

Smoke (GH-1088): main path = live apply, both traversals; adjacent paths = rerun of the same PR
and `--dry-run`. All in the probe above, run against the disposable gate clone at `a529e33e`
(implementation unchanged since `35d965825`).

First attempt (`fd4b988a8`) failed two existing suites, recorded in `first-attempt-gh421-fd4b988a8.log`:
`gh421 test_dry_run_transitions` (duplicate owner repoint preview) and `wave-reconcile.sh` 8/23
(the helper imported `releases_app` before checking rows; that suite's fixture has an empty placeholder
ledger and no `releases_app`). Both fixed in `35d965825`; base ran 23/23 on `wave-reconcile.sh`.

Suites ran in a disposable full clone (`…-gate`), HEAD `35d965825` before and after, tree clean.
