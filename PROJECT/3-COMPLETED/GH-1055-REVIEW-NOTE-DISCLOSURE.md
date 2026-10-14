---
gh_issue: 1055
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1055
title: Neutral disclosure for skipped independent review
status: Complete
created: 2026-10-14
doc_type: feedback
---

Operator requests the same brief disclosure rule in start-task and relay-xyz: Independent review did not run. Missing review alone supplies no code finding or severity and must not generate a blocking issue or inferred operator/setup failure. Actual code findings and explicit repository gates stay separate, and approval status remains truthful.

Scope: two skill paragraphs; no runtime/gate behavior change. Rating rationale: priority60 (operator-selected workflow clarity), severity20 (process-note amplification, not a code defect), appeal50 (neutral), effort90 (small wording change). No override. Deployment follows canonical-source publication.
