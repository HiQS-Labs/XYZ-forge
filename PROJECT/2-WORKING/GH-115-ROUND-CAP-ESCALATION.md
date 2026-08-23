---
title: "GH-115: marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)"
status: active
created: 2026-08-22
updated: 2026-08-22
owner: orchestrator (Claude Code)
goal: let a relay that is demonstrably converging continue past the round cap, and make cap escalations distinguish stall from progress
gh_issue: 115
source: https://github.com/HiQS-Suite/XYZ-forge/issues/115
branch: gh-115/round-cap-escalation
doc_type: bugfix
effort: 1
complexity: 2
risk: 1
related:
  - "#113 — same marathon-drive seam; shared artifact utils/py/marathon_drive.py"
---

# GH-115 — premature round-cap escalation

## Status

| What was just completed | What's next |
|---|---|
| capture doc + preflight contract written (ready, exit 0); queued as Bulkhead wave 1 (2026-08-22, release 0.7.3 "Bulkhead", #179) | Operator fires the marathon lane per MARATHON-PLAN-2026-08-23.md; builder executes ## Plan, reviewer verifies ## Acceptance |


Release 0.7.3 "Bulkhead" manifest member. Radar 2026-08-22: headless-reliability class.
All four Daybreak waves ended in harness escalations, two of them this exact
`cap-or-close-mismatch` shape, while the underlying relays were productive (wave 4 closed
Approved on its own evidence).

## Bug

`marathon-drive.sh` defaults to `--round-cap 5` per fire. On phases where builder and
reviewer iterate productively past 5 rounds, the runner escalates
`cap/close-mismatch (relay-drive exit 4)` even though the lane is active and converging —
halting automated execution and requiring manual restart.

## Plan

1. Progress-aware extension in `utils/py/relay_drive.py` (authoritative Python lane; the Bash
   twin is FROZEN per GH-308) / `utils/py/marathon_drive.py`: at the cap, if the last round produced new commits or newly
   resolved review items, grant a bounded extension (one increment, hard ceiling 2× cap) and
   record it in the transcript; a round with no progress still escalates exit 4.
2. Per-phase cap override: honor a `round-cap:` key in the phase brief and a CLI flag.
3. Escalation record distinguishes `cap-stalled` from `cap-progressing-extended` so post-run
   triage stops re-litigating productive runs.
4. `test/gh115-round-cap.sh`: scripted relay hitting the cap while progressing → extended then
   approved; hitting the cap stalled → exit 4 unchanged. Register in validate.sh TESTS.

## Acceptance

A converging relay passes its cap without escalation (bounded); a stalled one still exits 4;
gh115 suite green and registered.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/gh115-round-cap.sh" } ],
  "artifacts":     [ "utils/py/relay_drive.py", "utils/py/marathon_drive.py", "test/gh115-round-cap.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh115-round-cap.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "cap with progress extends bounded and is recorded; cap without progress still escalates exit 4; gh115 suite green" },
  "lanes":         { "agy_safe": [ "test/gh115-round-cap.sh" ], "orchestrator_only": [ "relay-automation/" ] }
}
```
