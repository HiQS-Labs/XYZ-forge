---
title: "Phase brief: GH-154 marathon-plan.sh <-> Python-port parity gap (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-17
updated: 2026-07-17
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the
  gh154-marathon-plan-parity phase — not itself an active-doc capture; the canonical capture doc is
  GH-154-MARATHON-PLAN-PORT-PARITY.md one level up.
roadmap_exempt: true
---

## Status

| What was just completed | What's next |
|---|---|
| Brief authored 2026-07-17. | Fire this phase via the marathon. |

## Phase: gh154-marathon-plan-parity — port the GH-48 zone model into the JS/Python-layer port

Full context: [GH-154-MARATHON-PLAN-PORT-PARITY.md](../GH-154-MARATHON-PLAN-PORT-PARITY.md).
GitHub issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/154

### The gap

`utils/marathon-plan.sh` supports an explicit zones config (the GH-48 zone model:
`QP_ZONES_CONFIG` / `EXPLICIT_ZONES_CONFIG` / `compileZoneConfig`, see
[GH-48's completed doc](../../3-COMPLETED/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md) for the model
itself). `utils/py/_marathon_plan_node.js` never got this — it still hardcodes a stale
`KERNEL_PATHS` const (line ~21, used ~line 233). Under `XYZ_PYTHON=1`, a repo relying on an explicit
zones config gets materially different output than the shell path would produce.

### What to do

1. Read `utils/marathon-plan.sh`'s `compileZoneConfig` and its `QP_ZONES_CONFIG` /
   `EXPLICIT_ZONES_CONFIG` env-var handling.
2. Port the equivalent logic into `utils/py/_marathon_plan_node.js`, replacing the hardcoded
   `KERNEL_PATHS` list with the ported zone-model resolution wherever the shell path would use it.
3. Add a parity test case (extend `test/marathon-plan.sh`, or add a new
   `test/marathon-plan-parity.sh` if that reads more cleanly) that runs an explicit-zones scenario
   through both the shell path and the `XYZ_PYTHON=1` path and asserts matching output.
4. Port only — do not refactor or rewrite unrelated parts of either file.

### Acceptance / done means

- `utils/py/_marathon_plan_node.js` now handles an explicit zones config equivalently to the shell
  path (verified by the new parity test).
- Full `bash test/marathon-plan.sh` green — no regression to the existing 58 assertions.
- Leave a one-line status update in `GH-154-MARATHON-PLAN-PORT-PARITY.md`'s Status table.
- Note (informational only, not a blocker): GH-110's P3a heredoc-extraction work is described as
  blocked on this reconciliation landing first — no action needed here beyond landing this fix.
