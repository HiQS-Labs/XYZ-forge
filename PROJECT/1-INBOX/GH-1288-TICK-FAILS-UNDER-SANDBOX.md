---
gh_issue: 1288
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1288
title: "factory-primitive tick fails (rc 1) under the GH-1280 sandbox profile on a clean root"
status: Parked (1-INBOX — prerequisite for a stateful factory-primitive campaign)
created: 2026-10-31
updated: 2026-10-31
owner: unassigned
doc_type: feedback
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Assuming a harness defect before the sandbox denial is identified
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1280
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1248
goal: >
  Name what `tick` needs that the campaign sandbox profile denies, then either widen the
  profile narrowly or document the limit. Full evidence and acceptance are in the issue.
---

## Key concepts

- GH-1280 disposition D5: clean `init` → `tick` is rc 0 unsandboxed, rc 1 under `profile-long.sb`.

## Merge evidence

- PR #1290 merged 2026-10-31 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
