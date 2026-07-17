---
gh_issue: 152
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/152
title: "Cost observability: auto-surface tick analyze cost at end of driven runs"
status: Active (2-WORKING) — captured 2026-07-17 by /10days (11-14 day sweep); Phase 6 of PROJECT/1-INBOX/COST-OBSERVABILITY-PLAN.md, not started (no driver calls tick analyze today)
created: 2026-07-06
updated: 2026-07-17
owner: noel
doc_type: feature
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not recomputing any cost number in the driver — reuses tick analyze --format json verbatim (DRY).
  - Not changing the event schema or analyzer logic — this phase only renders an existing report.
  - No $/pricing conversion, no LLM-based cost scoring.
related:
  - PROJECT/1-INBOX/COST-OBSERVABILITY-PLAN.md
  - relay-automation/relay-drive.sh
  - relay-automation/watchdog.sh
  - src/analyze.js
goal: >
  Have driven relay/marathon runs print the tick analyze cost block (human/md, floor markers
  preserved) at end-of-run, behind a non-disturbing opt-in/opt-out env toggle, so the operator stops
  needing a manual `tick analyze` pull to see what a run cost.
roadmap_exempt: false
---

# GH-152 · Cost observability Phase 6 — auto-surface cost at end of driven runs

Captured by the `/10days` 11-14 day sweep (2026-07-17). Full phase detail, checklist, and QA gate
live in [COST-OBSERVABILITY-PLAN.md](../1-INBOX/COST-OBSERVABILITY-PLAN.md) Phase 6 — this doc is
the GH-numbered pointer `swarm-preflight.sh --gh-issue 152` needs; do not duplicate the checklist
here, read it there.

**Why still open:** confirmed via a repo-wide grep that neither `relay-drive.sh` nor
`marathon-drive.sh` calls `tick analyze` at completion — the only existing `tick analyze` callers
are `poll.sh` (parked-claim liveness) and `watchdog.sh` (same), neither of which is an end-of-run
cost summary. No commit or PR references #152. Distinct from #151 (discovery spike, gates this) and
#153 (Codex parser, downstream of #151) — this phase is purely "render an existing report," so it
does not need to wait on #151's findings.

## Swarm Preflight Contract

> Scoped to `relay-drive.sh` as the first fireable slice (the turn-level driver every marathon lane
> ultimately runs through) — a real end-of-run cost summary here already covers same-day marathon
> lanes; extending to `marathon-drive.sh`'s own top-level summary is a natural follow-on, not
> required for this contract's gate to pass.

```json
{"target":{"repo":".","ref":"main"},"gate":"bash validate.sh","fix_probes":[{"type":"grep_absent","path":"relay-automation/relay-drive.sh","pattern":"tick analyze"}],"artifacts":["relay-automation/relay-drive.sh"],"remediation":{"source":"issue#152","criteria":"relay-drive.sh emits the tick analyze --format json cost block (human/md rendering) to its run summary/stderr at completion, preserving floor/partial (>=, coverage X/Y) markers; gated by a non-disturbing env toggle (default-on acceptable only if additive); a forced analyze error never fails the driven run itself; validate.sh stays green."},"lanes":{"orchestrator_only":["relay-automation/relay-drive.sh"]}}
```

*Contract auto-drafted by /10days from the issue text and the plan doc's Phase 6 checklist —
artifacts/lanes not yet operator-verified. `relay-drive.sh` is flagged `orchestrator_only` (not
`agy_safe`) since it's a containment-sensitive driver, per this repo's own lane-scoping convention
for driver scripts.*
