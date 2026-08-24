---
title: "GH-193: AgentChorus Gen 2 — telemetry, decision-quality metrics, measurable experiments (rename from Agent2Agent)"
status: active
created: 2026-08-24
updated: 2026-08-24
owner: orchestrator (GLM 5.3)
goal: make multi-agent discussion decisions measurable — telemetry, aggregate registry, outcome loop, adversarial/citation experiments — under the renamed AgentChorus skill
gh_issue: 193
source: https://github.com/HiQS-Labs/XYZ-forge/issues/193
branch: feat/agent-chorus-phase1-telemetry
doc_type: feature
effort: 4
complexity: 3
risk: 2
related:
  - "#179 — release 0.7.3 Bulkhead carrier (phases 0-1; later phases may carry into the next release)"
  - "#744618 / #525170 — the live discussions whose frictions (supersession, orphan doorbells) shaped Phase 2"
---

# GH-193 — AgentChorus Gen 2

## Status

| What was just completed | What's next |
|---|---|
| Phase 0 SHIPPED 2026-08-23 (PR #196: rename + shim + compat, gate 258/258) | Phase 1 in flight (telemetry sidecar + index + outcome + data policy + comparator); pause at pilot window per plan |

Release 0.7.3 "Bulkhead" manifest member. Plan of record: the phased v2 plan + consolidated
agent2+agent3 position + DeepSeek sharpenings, all on the issue. Phase gates from the plan:

- Phase 0 — rename (DONE, PR #196)
- Phase 1 — telemetry + aggregate registry + outcome loop + data policy (in flight)
- Phase 2 — lifecycle verbs + verify-citations + guardrail reconciliation
- Phase 3 — experiment flags (steelman, stance prior), gated on ≥10-discussion pilot corpus

## Acceptance

Phase 1 exit criteria (from the plan): one full real discussion completes with telemetry + a
recorded outcome; one aggregate query runs over the pilot corpus via telemetry_index.db; the
comparator (`telemetry audit`) shows zero transcript content. Pilot window default-ON:
2026-08-24 .. 2026-09-08 (declared in EXPERIMENTS.md; hard override AGENT2AGENT_TELEMETRY=0).
