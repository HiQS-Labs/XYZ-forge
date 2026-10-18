The fixture sources are already committed in this PR's history; no duplicate test file is needed.

Red: `git show 03fb2fd9:test/gh436-merge-cleanup.py > temp/gh436-before-publisher-fixture.py`, then run its single `TestMergeCleanupOrchestration.test_reconcile_pr_proceeds_on_a_ready_primary` against the final runtime from a disposable clone with `PYTHONPATH=$PWD/test`. Expected: assertion2!=0 because the synthetic primary has no origin.

Green: the same existing test at `007a14ad`, with the final publisher mocked and its resolved primary call asserted. It passes; the retained logs/provenance pin the execution. The runtime at7dc1ed0a is byte-identical to007a14ad; only the fixture's realpath assertion changed.
