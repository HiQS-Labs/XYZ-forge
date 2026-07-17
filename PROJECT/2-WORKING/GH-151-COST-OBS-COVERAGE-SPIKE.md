---
gh_issue: 151
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/151
title: "Cost observability: reconcile SSOT + fix orphaned Gemini relay-lane token capture"
status: Active (2-WORKING) — captured 2026-07-17 by /10days (11-14 day sweep); Phase 4 discovery spike from PROJECT/1-INBOX/COST-OBSERVABILITY-PLAN.md, still unstarted (findings section empty)
created: 2026-07-06
updated: 2026-07-17
owner: noel
doc_type: spike
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not shipping any parser or capture code in this phase — probe and record only (PDDA discovery-phase contract).
  - Not deciding Phase 7's (#153) Codex parser here — that stays hard-gated on this spike's findings.
  - No $/pricing conversion, no LLM-based cost scoring — this repo's cost-observability track stays deterministic.
related:
  - PROJECT/1-INBOX/COST-OBSERVABILITY-PLAN.md
  - src/cost.js
  - relay-automation/consult.sh
  - relay-automation/claude-turn.sh
goal: >
  Run the Phase 4 coverage-truth spike from COST-OBSERVABILITY-PLAN.md: probe whether Codex and agy
  expose a usable per-turn usage surface, confirm the Gemini relay-lane capture path is genuinely
  orphaned (no live turn shim feeds it), confirm claude-turn.sh's new metering is live and correct,
  and write the three go/no-go findings back into the plan doc so Phase 5-7 can proceed.
roadmap_exempt: false
---

# GH-151 · Cost observability Phase 4 — coverage-truth spike

Captured by the `/10days` 11-14 day sweep (2026-07-17). Full phase detail, checklist, and QA gate
live in [COST-OBSERVABILITY-PLAN.md](../1-INBOX/COST-OBSERVABILITY-PLAN.md) Phase 4 — this doc is
the GH-numbered pointer `swarm-preflight.sh --gh-issue 151` needs; do not duplicate the checklist
here, read it there.

**Why still open:** a 2026-07-06 post-ship coverage audit found the capture lane drifted from the
original Phase 1-3 plan — `gemini-turn.sh` was retired for cost-blind `agy-turn.sh`, orphaning
`parseGeminiStats`; `claude-turn.sh` gained new metering nothing else knew about. Three follow-on
issues were filed (#151/#152/#153); this is the first, gating, discovery-only slice. No commit or
PR has touched this since filing — the plan doc's own "Findings written back" section is still the
placeholder text.

## Swarm Preflight Contract

> Discovery-only phase: the artifact is the plan doc itself (findings written back), not new code.
> `path_absent`/`grep_present` on the placeholder marker so preflight can tell "spike done" from
> "spike not yet run" without a code diff to inspect.

```json
{"target":{"repo":".","ref":"main"},"gate":"bash validate.sh","fix_probes":[{"type":"grep_present","path":"PROJECT/1-INBOX/COST-OBSERVABILITY-PLAN.md","pattern":"to be filled by the spike"}],"artifacts":["PROJECT/1-INBOX/COST-OBSERVABILITY-PLAN.md"],"remediation":{"source":"self#phase-4","criteria":"Probe Codex exec + agy print-mode usage surfaces, confirm the Gemini relay-lane path has no live caller besides consult.sh's legacy alias, confirm claude-turn.sh metering emits a real .tick/events/*tokens* record, and write all findings + the three go/no-go decisions into the plan doc's 'Findings written back' section, replacing the placeholder text; validate.sh stays green (doc-only change)."},"lanes":{"agy_safe":["PROJECT/1-INBOX/COST-OBSERVABILITY-PLAN.md"],"orchestrator_only":[]}}
```

*Contract auto-drafted by /10days from the issue text and the plan doc's Phase 4 checklist —
artifacts/lanes not yet operator-verified.*
