---
title: "GH-949 — ATE lifecycle, oracle and environment remediation"
status: Captured
created: 2026-10-03
updated: 2026-10-03
owner: Codex
goal: Repair all nine GH-435 campaign findings and the known GH-912 test-environment leak through existing implementations.
gh_issue: https://github.com/HiQS-Labs/XYZ-forge/issues/949
related: [949, 912, 435, 948]
effort: 3
complexity: 3
risk: 3
phases: 3
---

# GH-949 — ATE remediation

## Status

| What was just completed | What's next |
|---|---|
| Umbrella issue created; fresh task clone pinned to development 3fbed72f | Complete recon, ratings and plan relay QA before implementation |

## Intake

Canonical issue: https://github.com/HiQS-Labs/XYZ-forge/issues/949.
Campaign evidence: https://github.com/HiQS-Labs/XYZ-forge/issues/435#issuecomment-5966506066 and evidence PR https://github.com/HiQS-Labs/XYZ-forge/pull/948.
Execution scope: F1–F9 and K1/GH-912. No rejected installer hypothesis, normal-success descendant policy change, new suite, gate, engine or framework. Shared helper changes are Costly until caller compatibility is verified; rollback is a revert of focused commits. Plan and recon are being grounded before production changes.
