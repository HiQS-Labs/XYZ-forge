---
gh_issue: 1395
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1395
title: Reduce redundant REST reads in reconciliation workflows
status: Proposed (1-INBOX — not yet active)
created: 2026-11-09
doc_type: bugfix
effort: 3
complexity: 3
risk: 3
phases: 1
---

# GH-1395: reconciliation REST reads

Related tracking: https://github.com/noelsaw1/noels-cross-project-tasks/issues/80

Measure repeated sweeps in a legitimate workflow, distinguish CLI counts from HTTP resource usage,
and reduce redundant native REST reads at their source. Preserve owned issue identity, PR rejection,
two-observation consistency, freshness, error refusal and transactional concurrency controls.

Acceptance: same-workflow red/green measurements, existing suite coverage and recorded malformed,
missing and changed-state counterexamples; independent plan/final QA; reviewable development PR.
No new service, cache subsystem, gate or suite. No attribution to a principal consumer without evidence.

Prior 90 native plus 90 closure CLI counts are fixture measurements, not historical wire volume.
