---
title: "GH-509: Relay terminal authorization — prove a review happened without trusting builder-writable state"
status: In progress
created: 2026-09-08
updated: 2026-09-08
owner: agent-b
goal: a terminal relay status counts only when the driver watched a reviewer-role turn write it, and the driver stamps that observation with the reviewed head and a digest of the reviewer's block
gh_issue: 509
source: https://github.com/HiQS-Labs/XYZ-forge/issues/509
branch: fix/gh505-relay-reviewer-integrity
doc_type: defect
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/505
context_tags: [relay, review-integrity, governance]
non_goals:
  - see the shared plan
effort: 40
complexity: 4
risk: 4
---

# GH-509 — relay terminal authorization

Shared plan, issue map, phases and checks: [GH-505-RELAY-REVIEWER-INTEGRITY.md](GH-505-RELAY-REVIEWER-INTEGRITY.md).
This issue owns **Phase 1** (driver-attested terminal status) and the consumer side of **Phase 3**.

Option chosen by the operator from the six written on the issue: **2 + 1** — roles from the
invocation, driver as the only writer of a counting verdict, the attestation block as the
evidence. Options 3, 4, 5 are explicit non-goals; option 6's audit trail falls out of the
attestation block for free.
