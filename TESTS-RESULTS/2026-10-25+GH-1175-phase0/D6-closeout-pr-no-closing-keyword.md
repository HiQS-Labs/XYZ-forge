TITLE: marathon-closeout PR body has no `Closes #<issue>`: a merged Jog lane leaves its issue open and its doc in 2-WORKING

## Observed (GH-1175 Phase 0, PR #1225, 2026-10-26)
`marathon-closeout.sh` opened PR #1225 for issue #416 with body "Automated marathon closeout for phase `gh-416-doc-trues-up-batch` (GH-561)." `closingIssuesReferences` was `[]`. wave_reconcile treats a non-closer as mention-only (GH-202), so a merge would have left #416 OPEN and the doc in 2-WORKING. Fixed by hand by appending `Closes #416` before the merge.

## Proposed remedy (for review)
When the receipt/invocation carries `issue`, closeout writes `Closes #<issue>` in the PR body. Lanes without an issue are unchanged. Acceptance: next Jog lane PR shows the issue in `closingIssuesReferences`; manual receipt under TESTS-RESULTS/.
