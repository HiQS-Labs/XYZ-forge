---
title: "GH-791: repair merge-batch regressions"
status: Complete
created: 2026-09-24
updated: 2026-09-25
owner: Codex
goal: Restore bounded cleanup polling, correct hosted-run attribution, and the inventory gate.
gh_issue: https://github.com/HiQS-Labs/XYZ-forge/issues/791
---

## Status

| What was just completed | What's next |
|---|---|
| PR #794 merged at `0ae3452a`; local fallback reconciliation, RELEASES check and issue-doc sync passed after the hosted qualification failed on three unrelated suites. | GH-796 continues with #795 and remediated #765; hosted failures remain tracked under #790 and existing follow-ups. |

## Scope and recon

The reviewed batch ends at `337813e0`; #761 and #783 are the preceding merges named by #791.
#787 and #753 both added mergeability polling; their combined `land_prs` calls wait twice.
#753 also adopts unrelated hosted workflow runs as evidence for the current landing.
#783 froze the script inventory before #723 added the GitHub-label connector.

Entry path: cleanup CLI -> `land_prs` -> one bounded mergeability refresh -> landing ->
`run_post_merge_reconcile` -> `wait_for_hosted_reconcile`. GitHub workflow identity must match
one of the PR or merge SHAs before its success can skip the local reconciler. An unidentified
active run can delay the writer, but cannot attest this landing. Existing local fallback retains
its independent active-workflow guard. Inventory changes only admit the already-landed connector;
the ratchet must still reject a new rogue script. The newly added hosted-lookup suite also
used a local-only skill alias; its import now uses the canonical tracked package path.

Reversibility: Easy; focused code/test/baseline edits can be reverted. No merge or clone teardown
is executed by regression fixtures. The primary checkout stays untouched.

## Verification

Run existing merge-cleanup tests and new mocked foreign/unknown workflow cases. Observe failures
against the batch state, then passes against repairs. Run the inventory positive and negative
controls. Run the full macOS gate in a separate full clone and preserve evidence with provenance.
Review roadmap, express, labels, vendor, HQ, watchdog, and bridge checks as part of the batch audit.
Unknown: real GitHub eventual-consistency timing is modeled with controlled workflow responses.

## Outcome

The full-gated revision is `14640c75`. [Review and committed receipts](../../TESTS-RESULTS/2026-09-24+GH-791/REVIEW.md)
include all negative controls and final validation. GH-793 records the unrelated intermittent
idle-control failure and is held; no unrelated runtime fix is included.

Post-merge reconciliation evidence and provenance: `TESTS-RESULTS/2026-09-25+GH-796/pr794-reconciliation/`. The hosted failure is retained and is not a passing qualification.
