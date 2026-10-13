# Merge-cleanup replay drops an admitted roadmap label

Observed during [merge batch #1003](https://github.com/HiQS-Labs/XYZ-forge/issues/1003): the existing `skills/2-daily/merge-cleanup/scripts/ledger_merge.py::replay_ops` add/rate/update path omits an added row's `status_label`. PR #953's GH-949/GH-912 rows and PR #966's GH-964 row carried `in-progress`, but replay readback returned NULL. Batch repair explicitly reaffirmed those qualified open-issue admissions through `roadmap update --accepted-start`; original timestamps were not backdated.

Evidence: `TESTS-RESULTS/2026-10-08+GH-1003/pr-953/ledger-readback.txt`, its committed provenance, and the independent merge-resolution review. A general helper fix is outside this landing batch. Before another admitted-row replay, decide how the existing writer should retain qualified lifecycle intent without inventing historical starts, then verify with the existing coverage or a recorded manual control.
