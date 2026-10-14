---
title: "Recon contracts across vendored artifacts and runtime"
status: "Proposed (1-INBOX - not yet active)"
created: 2026-10-12
owner: agent-b
gh_issue: 1052
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1052
doc_type: spike
complexity: 2
risk: 1
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Implement changes to recon or review-code
  - Introduce a universal contract framework or formal-specification tooling
  - Add a test suite or global gate
related:
  - GH-1043
  - GH-955
  - GH-950
  - GH-951
  - GH-963
  - GH-1011
  - GH-1013
goal: >
  Decide whether recon and review-code should conditionally trace contracts from
  canonical source through generated or vendored artifacts to downstream runtime.
  Deliver practical trigger/skip guidance grounded in existing checks and recent
  real failures, without burdening local-only changes.
---

# GH-1052 - Recon contracts across vendored artifacts and runtime

> 1-INBOX capture, not the active-work doc. On promotion to `PROJECT/2-WORKING/`, add the status
> table and per-phase QA gates (`PROJECT/PDDA.md`).

## Key concepts
- Distribution is a contract chain: canonical source and owner -> generated, copied, or vendored artifact -> downstream runtime.
- Apply the extra trace only when a change touches that chain; reuse existing parity, drift, and runtime checks.
- Keep this distinct from GH-1043's immediate runtime consumer, retry, and solver-parameter checks.

## Idea
Assess whether recon and review-code should conditionally trace producer, artifact, and downstream-runtime contracts for generated, copied, or vendored changes, and recommend the smallest practical guidance.

## Why
Recent work includes a central downstream publisher (#955/#956), adapted downstream ownership (#950/#951), publisher parity gaps (#963), an interrupted live re-vendor (#1011), and a local absolute path leaking into downstream artifacts (#1013). The current N+1 proposal (#1043/#1044) sharpens runtime tracing, but these distribution failures cross from Forge source into a separate artifact and its host runtime. Existing safeguards already cover parts of this: `xyz_mini_sync.py` models managed/seed/adapted files and provides `--check`; Skills Army sync uses `skill_drift_check.py`; and `test/xyz-vendor.sh` exercises the materialized runtime in an ESM host. The spike should determine whether a small conditional recon prompt composes these checks or merely repeats existing coverage.

## Phase 0 - Explore and scope

### Checklist
- [ ] Trace `relay-automation/xyz-vendor.sh` through target `.xyz/` to a real runtime entry point, including its existing verification.
- [ ] Trace one standalone or deployed-skill path through its source/ownership rules, published artifact, and downstream consumer.
- [ ] Review relevant recent issue and PR evidence; separate distinct incidents from recurring boundary failures.
- [ ] Recommend exact conditional wording for recon/review-code, or explain why existing lanes suffice; state trigger and skip conditions.
- [ ] Reuse existing verification. Keep local-only changes out of scope; no implementation, new suite, or global gate in this spike.

### QA checklist - Phase 0
- [ ] Findings cite actual code and existing checks for both runtime vendoring and skill distribution.
- [ ] Proposed guidance verifies artifact ownership/portability and real downstream use without duplicating GH-1043.
- [ ] Rollout/rollback compatibility is conditional on relevant persisted or external contract changes.
- [ ] Recommendation names a clear skip path and does not impose vendor analysis on local-only edits.