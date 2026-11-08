# GH-1269 smoke and verification (manual check; no new suite — GH-831)

| Check | Revision | Result | Log |
|---|---|---|---|
| Red control: `smoke.py` on pre-fix `ledger_merge.py` | before 72be48e2 | 4 FAIL / 1 PASS: same-date order rewritten; attempt 2 refuses with "changelog preamble or existing history changed" (the LTVera #874 handoff) | `red-control-prefix.log` |
| Smoke main path (LTVera #874 shape) + 3 adjacent paths + guard | 72be48e2 | 5/5 PASS | `smoke-candidate.log` |
| GH-789 manual matrix, disposable full clone | 72be48e2 | 19/27 ok; all `ChangelogUnitCases` and the clone-level B1 cases (`test_ledger_plus_changelog_resolves_without_loss`, `test_changelog_only_conflict_and_dry_run`, `test_base_edit_hands_off_before_any_writer_or_file_change`) pass | `gh789-matrix-candidate.log` |
| GH-789 matrix baseline (pre-fix `ledger_merge.py`, same clone) | HEAD~1 file | identical 8 failures | `gh789-matrix-baseline.log` |

**Main path:** base has history; development adds six 2026-10-29 sections in non-sorted heading order;
the PR adds one 2026-10-30 section. Output = preamble + PR section + development's text verbatim.

**Adjacent paths:** (a) attempt 2 on the repaired head against the same tip is a no-op instead of a
refusal; (b) attempt 2 after development gained a section prepends the PR block and keeps the new tip
verbatim; (c) a block present on both sides (an earlier sync) is kept once.

**Limit:** the matrix's 8 end-to-end `run_main` cases fail identically before and after this change
(exit-code drift from later features: batch QA exit 4, merge-policy output). They are an unregistered
GH-789 evidence script, not a gate; this change does not touch `run_main`. The end-to-end landing is
covered by the full pre-push gate's registered merge-cleanup suites.
