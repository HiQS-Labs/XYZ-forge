# Issue state is the authority for "done"; docs found by number; one completion sweep — GH-1333

Recorded 2026-11-03. The operator approved three of the #1333 recommendations. The canonical rule text is in [PROJECT/PDDA.md](../PROJECT/PDDA.md), under "Canonical document model" and "Lifecycle".

1. **The GitHub issue's state is the only authority for "done".** The `PROJECT/` folder of a `GH-<n>-` doc and its ledger row's section are views of that state. When they disagree, the issue wins.
2. **Every reader finds a `GH-<n>-` doc by issue number, never by a stored path.** Stored paths (the ledger's `doc_path`) are a cache. Moving a doc can no longer break a reference: 45 ledger `doc_path` values were stale on 2026-11-03, and the #722 stall was a moved artifact path.
3. **One idempotent sweep, keyed on current issue state, replaces per-merge moves.**
   - It covers `1-INBOX` and `2-WORKING`.
   - Closed as completed goes to `3-COMPLETED`; closed as not planned goes to `4-MISC`.
   - It repoints the ledger row in the same commit.
   - It runs from the merge-cleanup batch and `start-marathon` Step 2.
   - It never closes an issue.

Why: "done" was stored three times, and the only automatic writer fired on a PR merge with a closing keyword. Manual closes, bulk closes, `Refs`-only lane PRs and merges in the GitHub UI all left the copies disagreeing. On 2026-11-03 that left 25 closed issues with active docs. The measurements and the code trace are in #1333.

Status: **policy decided, not yet implemented.** Until the sweep and the reader changes land, `wave_reconcile.py --pr N` still moves docs on a closing-keyword merge, and `pdda.sh issue-doc-sync` flags what it misses. No code, ledger row or doc location changed with this record.

Not decided here, and still open in #1333:
- who closes an issue after verified completion (decision 2);
- the appeal axis, and when a ledger row is created (decision 3);
- whether to retire the folders entirely. That is to be decided about a month after the sweep runs, on whether anything but people browsing still reads them.

Expected signal: once the sweep runs, `issue-doc-sync` warning (a) stays at zero across merge-cleanup batches, and no ledger `doc_path` points at a missing file. Revisit if the sweep moves a doc whose issue was reopened, or if a reader is found still resolving by stored path.

Rollback: the policy is text. Revert this record and the PDDA.md edits. The sweep, once built, only moves files with `git mv` and rewrites ledger cache fields, and both can be reverted by commit.
