---
gh_issue: 1075
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1075
title: merge-cleanup batch record keeps stale per-PR file lists on resume
status: Proposed (1-INBOX — not yet active; deferred by the operator 2026-10-14)
created: 2026-10-14
doc_type: feedback
effort: 1
complexity: 1
risk: 1
phases: 1
---

# GH-1075: batch record keeps stale per-PR file lists on resume

Found in review of #1069 (GH-1064). `batch_record.extend()` appends only PRs it has not seen before.
On `--resume`, a known PR whose branch changed since the batch began keeps the file list captured when
the batch was created. The sweep's `shared_files` can then miss overlaps between landed PRs.

Smallest fix: in `extend()`, refresh `files` and `soft` for already-planned PRs from the current queue.
Keep order and outcomes unchanged. Verify with a manual check (GH-831).

## Merge evidence

- PR #1069 merged 2026-10-15 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
