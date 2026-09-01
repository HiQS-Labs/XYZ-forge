---
gh_issue: 365
source: https://github.com/HiQS-Labs/XYZ-forge/issues/365
title: "GH-365: test-suite recalibration — finish tiering, prove parallel equivalence, and define smoke/promotion lanes"
status: Proposed (1-INBOX — not yet active)
created: 2026-09-01
doc_type: feedback
effort: 4
complexity: 4
risk: 3
phases: 4
---

# GH-365 · Test-suite recalibration

## Capture

Recalibrate the suite after GH-347 lands by measuring the new PR critical path, finishing the
fail-closed tier-routing contract, running the owed multi-width equivalence campaign, and deciding
whether an XYZ-specific functional smoke lane adds measured defect-detection value.

The work must keep four decisions distinct: fast feedback, integration drift detection,
self-reported local verification, and independent full sequential macOS promotion evidence.

## Acceptance summary

- Retain a post-GH-347 latency and runner-minute baseline.
- Classify every governed path or fail closed to Tier 3.
- Measure Tier 1/2 on real pushes.
- Prove or bound parallel equivalence with committed multi-width receipts.
- Add a smoke lane only if observed XYZ defects justify it and a witnessed red control falsifies it.
- Preserve full sequential macOS promotion evidence unless a later explicit decision changes it.

See the GitHub issue for the complete Draft 1 strategy, tactics, phases, and non-goals.
