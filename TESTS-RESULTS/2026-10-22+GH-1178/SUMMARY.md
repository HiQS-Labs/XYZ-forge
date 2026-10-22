# GH-1178 verification — 2026-10-22

Base `f243ccfbfb53` (origin/development) · candidate `35d965825404`. Manual check, no new suite (GH-831).

| Check | Result | Receipt |
|---|---|---|
| A2 red control: fixture against base `wave_reconcile.py` | FAIL as expected — #422 left on `PROJECT/2-WORKING/GH-421-fixture.md`, both issue orders | `red-control-f243ccfbf.log` |
| A1/A3/A4 + dry-run: fixture against candidate | PASS — both rows (doc_path + raw_text) at `3-COMPLETED` in both orders; unmoved #500 kept; rerun emits no repoint; dry-run leaves ledger unchanged, one preview per row | `green-35d965825.log` |
| Tier-2 route (`validate.sh --auto f243ccfbf..HEAD`, pdda subsystem incl. wave-reconcile, gh202, gh232, gh358) | rc=0 | `tier2-validate-auto-35d965825.log` |
| Neighbour suites gh421, gh454, gh168 | rc=0 each | `*-35d965825.log` |

The probe (`probe.py.txt`) mirrors `test/gh421-auto-wave-reconcile.sh`'s in-process harness: two
issues (#421, #422) share `GH-421-fixture.md`, a third (#500) has its own unmoved doc.

Smoke (GH-1088): main path = live apply, both issue orders; adjacent paths = rerun of the same PR
and `--dry-run`. All in the probe above.

First attempt (`fd4b988a8`) failed two existing suites, recorded in `first-attempt-gh421-fd4b988a8.log`:
`gh421 test_dry_run_transitions` (duplicate owner repoint preview) and `wave-reconcile.sh` 8/23
(the helper imported `releases_app` before checking rows; that suite's fixture has an empty placeholder
ledger and no `releases_app`). Both fixed in `35d965825`; base ran 23/23 on `wave-reconcile.sh`.

Suites ran in a disposable full clone (`…-gate`), HEAD `35d965825` before and after, tree clean.
