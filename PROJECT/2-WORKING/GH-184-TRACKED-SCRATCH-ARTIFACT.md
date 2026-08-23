---
title: "GH-184: committed scratch artifact .relay-scratch/probe_telemetry.json makes every real turn a tracked-file mutation"
status: active
created: 2026-08-23
updated: 2026-08-23
owner: orchestrator (Claude Code)
goal: nothing under the sanctioned-disposable .relay-scratch/ lane is ever tracked, so its by-design discard can never dirty a clone
gh_issue: 184
source: https://github.com/HiQS-Labs/XYZ-forge/issues/184
branch: gh-184/tracked-scratch-artifact
doc_type: bugfix
effort: 1
complexity: 1
risk: 1
related:
  - "#113 — the containment/scratch-lane seam this artifact lives on; disjoint write-set, wave-compatible"
  - "#174 — Gen 3.5 umbrella (Part G new finding); #177 — soak results §3.5"
---

# GH-184 — remove the tracked scratch artifact

## Status

| What was just completed | What's next |
|---|---|
| capture doc + preflight contract written; auto-filed per SOP §1 (2026-08-23); queued as Bulkhead wave candidate (release 0.7.3, #179) | Operator fires the marathon lane per MARATHON-PLAN; builder executes ## Plan, reviewer verifies ## Acceptance |

Release 0.7.3 "Bulkhead" manifest member. Gen 3.5 soak (#177 §3.5): PR #160 accidentally
committed `.relay-scratch/probe_telemetry.json`. A shim driven through its real-turn path
outside a worktree exits 0 ("token-only move") while rtl's sanctioned non-worktree discard of
`.relay-scratch/` deletes the tracked file — a success-shaped exit plus a tracked-file mutation,
invisible to the Phase 1 zero-mutation oracle (`--help` scope) and the Phase 5 anomaly oracle
(rc-based).

## Bug

See #184 for the deterministic reproduction (`git status` shows ` D
.relay-scratch/probe_telemetry.json` after one real-turn run).

## Plan

1. `git rm .relay-scratch/probe_telemetry.json` — it is regenerable probe output; the lane is
   disposable by design (GH-91).
2. `test/gh184-no-tracked-scratch.sh`: guard deriving offenders from `git ls-files
   .relay-scratch/` every run (empty required; mirrors gh1-adoption-guard's derived-from-source
   pattern — no hand-maintained list). Register in `validate.sh` TESTS.
3. The durable hardening (per-probe zero-mutation oracle so fuzzer-driven real turns can never
   silently mutate a host clone) stays tracked in #174 Part F task 6 — out of this lane's scope.

## Acceptance

`git ls-files .relay-scratch/` returns nothing; gh184 guard green and registered; soak §3.5
repro (`RELAY_AGENT=… bash relay-automation/agy-turn.sh`) leaves `git status` clean.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/gh184-no-tracked-scratch.sh" } ],
  "artifacts":     [ ".relay-scratch/probe_telemetry.json", "test/gh184-no-tracked-scratch.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh184-no-tracked-scratch.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "no .relay-scratch/ content tracked; derived guard green; real-turn repro leaves git status clean" },
  "lanes":         { "agy_safe": [ "test/gh184-no-tracked-scratch.sh" ], "orchestrator_only": [ ".relay-scratch/", "validate.sh" ] }
}
```
