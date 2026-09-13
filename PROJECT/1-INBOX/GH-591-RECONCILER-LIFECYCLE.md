---
gh_issue: 591
source: https://github.com/HiQS-Labs/XYZ-forge/issues/591
title: Reconciler provenance lifecycle
status: Proposed (1-INBOX — not yet active)
created: 2026-09-13
doc_type: bugfix
effort: 4
complexity: 4
risk: 3
phases: 4
---
# Reconciler provenance lifecycle

Every merged development PR must reconcile automatically with retained full-suite evidence;
the six-hour catch-up must recover missed work without one legacy row aborting the sweep.
Children: #546 producer and #584 sweep. Recon precedes implementation. Three consecutive merged
PR runs and a scheduled run are the final acceptance evidence. See the sibling
[Recon Map](recon-reconciler-provenance-lifecycle.md).
