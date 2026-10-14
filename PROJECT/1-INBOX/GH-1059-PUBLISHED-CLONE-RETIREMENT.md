---
title: "GH-1059: Retire fully published task checkouts before merge"
gh_issue: 1059
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1059
status: "Proposed (1-INBOX — active)"
created: 2026-10-14
doc_type: feature
effort: 2
complexity: 2
risk: 3
---

# GH-1059: Published task checkout retirement

Operator requests automatic retirement after the branch and PR are fully pushed to origin, without waiting for merge. Reuse merge-cleanup's safety and teardown paths; preserve unpublished or active state. See the linked issue for acceptance and the explicit policy decision.
