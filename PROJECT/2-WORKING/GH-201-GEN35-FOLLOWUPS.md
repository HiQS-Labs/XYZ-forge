---
title: "GH-201: Gen 3.5 follow-ups — remaining ATE hardening arc (tasks 3–8b of #174)"
status: active
created: 2026-08-24
updated: 2026-08-24
owner: orchestrator (GLM 5.3)
goal: carry the remaining post-soak ATE hardening tasks to done — deterministic fixes, closed data path, explorer sharpening, gated Phase 4 autonomy, canary calibration, Gemma sensor
gh_issue: 201
source: https://github.com/HiQS-Labs/XYZ-forge/issues/201
branch: multiple (per-task lanes)
doc_type: feature
effort: 4
complexity: 4
risk: 3
related:
  - "#174 — plan of record (Parts A–H); #177 — soak receipts; #192 — QA follow-ups"
  - "#182 — healer-safety lane (rides Bulkhead); #193 — AgentChorus Gen 2 (parallel track)"
---

# GH-201 — Gen 3.5 follow-ups

## Status

| What was just completed | What's next |
|---|---|
| spun out of #174 2026-08-24 (collision-free tracker); tasks 1+9 already shipped via PR #185 | Task 3 (deterministic fixes) → Task 4 (data path) → Task 6 (explorer+oracle) gate Task 7 (Phase 4 autonomy); Task 8 calibration hour; Task 8b Gemma sensor rides alongside |

Dialed into release 0.9.0 "Cargo" (draft) — the arc spans past Bulkhead's target; #182 (the
near-term healer lane) stays on Bulkhead. Task list + acceptance live on the issue; sequencing
principle unchanged from the #174 pivot: soundness and the closed data path before autonomy.
