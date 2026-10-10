---
title: "GH-912 — Isolate ambient harness discovery overrides in gates"
status: Complete
created: 2026-10-03
updated: 2026-10-09
owner: Codex
goal: Prevent operator harness-location overrides from selecting another checkout in gate fixtures.
gh_issue: https://github.com/HiQS-Labs/XYZ-forge/issues/912
related: [912, 949]
effort: 2
complexity: 2
risk: 2
phases: 1
---

# GH-912 — Gate environment isolation

Implementation and acceptance are owned by the shared [GH-949 plan](../2-WORKING/GH-949-ATE-REMEDIATION.md). Existing issue: https://github.com/HiQS-Labs/XYZ-forge/issues/912. Preserve explicit fixture-level overrides while clearing ambient locator variables at the existing runner boundary. This separately rated issue shares one implementation PR with GH-949.
