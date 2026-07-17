---
gh_issue: 154
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/154
title: "port-drift: marathon-plan shell heredoc vs utils/py/_marathon_plan_node.js diverged (py missing GH-48 zone model)"
status: Triaged 2026-07-16 during a recent-issues sweep — parity gap confirmed still present;
  no commits have touched either file since the issue was filed (2026-07-06).
created: 2026-07-06
updated: 2026-07-16
owner: noel
doc_type: bug
complexity: 2
risk: 2
effort: 3
phases: 1
ratings_provisional: true
non_goals:
  - Not resuming GH-110 P3a's heredoc-extraction work in this lane — sequence this parity fix first,
    since GH-110 P3a is explicitly blocked on it
  - Not a rewrite of the zone model itself — port the existing shell logic as-is
related:
  - utils/marathon-plan.sh
  - utils/py/_marathon_plan_node.js
  - PROJECT/3-COMPLETED/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md
goal: >
  Port the GH-48 zone model (QP_ZONES_CONFIG / compileZoneConfig) from the shell implementation
  (utils/marathon-plan.sh) into the JS/Python-layer port (utils/py/_marathon_plan_node.js), which
  currently lacks it entirely (hardcodes a stale pre-GH-48 KERNEL_PATHS list instead), and add a
  parity check so the two implementations can't silently diverge again.
roadmap_exempt: false
---

# GH-154 · marathon-plan.sh ↔ Python-layer port parity gap

## Status

| What was just completed | What's next |
|---|---|
| **Fixed and verified 2026-07-17** via the GH208-154-149-198 marathon (codex builder, agy reviewer, Approved). Ported `compileZoneConfig`/`QP_ZONES_CONFIG`/`QUEUE_PLAN_ZONES_FILE` into `utils/py/_marathon_plan_node.js` (confirmed present, matching the shell path). Also had to teach `utils/marathon-plan.sh`'s `XYZ_PYTHON=1` dispatcher to translate a `--zones-config PATH` CLI flag into the `QUEUE_PLAN_ZONES_FILE` env var before exec'ing `utils/py/marathon_plan.py` (a Python subprocess wrapper around the same `_marathon_plan_node.js`), so the flag survives the shell→Python→Node handoff. Two new parity assertions in `test/marathon-plan.sh`: "explicit zones dry-run output matches between shell and XYZ_PYTHON=1" and "rendered MARATHON-PLAN doc matches between shell and XYZ_PYTHON=1". Full `bash test/marathon-plan.sh`: 60/60 (up from 58). | Closed out — nothing further for this lane. GH-110 P3a (heredoc extraction) is now unblocked. |

## Findings

The shell implementation (`utils/marathon-plan.sh`) gained the GH-48 zone model (explicit
`--zones-config` / `QUEUE_PLAN_ZONES_FILE` support via `compileZoneConfig`) after the Python-layer
port (`utils/py/_marathon_plan_node.js`) was written, and the port was never updated — it still uses
a hardcoded kernel-path list. Under `XYZ_PYTHON=1`, any repo relying on an explicit zones config
would get materially different (wrong) marathon-plan output than the shell path.

## Phase 0 — Port and regression-verify

### Checklist

- [x] Ported `compileZoneConfig` and `QP_ZONES_CONFIG`/`EXPLICIT_ZONES_CONFIG` handling from
      `utils/marathon-plan.sh` into `utils/py/_marathon_plan_node.js` (also wired
      `--zones-config` → `QUEUE_PLAN_ZONES_FILE` through `utils/marathon-plan.sh`'s
      `XYZ_PYTHON=1` dispatcher so the flag reaches the Node script via the Python wrapper)
- [x] Added 2 parity test cases in `test/marathon-plan.sh` (explicit-zones dry-run output,
      rendered MARATHON-PLAN doc) asserting shell and `XYZ_PYTHON=1` paths match
- [x] Full `bash test/marathon-plan.sh` green: 60/60 (58 existing + 2 new)

### QA checklist — Phase 0

- [ ] Port only — no unrelated cleanup of `_marathon_plan_node.js`
- [ ] Sequenced ahead of GH-110 P3a (which is blocked on this reconciliation, not the reverse) — do
      not let this lane collide with any concurrent P3a heredoc-extraction work on the same file

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/marathon-plan.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/py/_marathon_plan_node.js", "pattern": "QP_ZONES_CONFIG" }
  ],
  "artifacts": [ "utils/marathon-plan.sh", "utils/py/_marathon_plan_node.js", "test/marathon-plan.sh" ],
  "remediation": { "source": "self#phases", "criteria": "Phase 0 checklist in this doc" },
  "lanes": { "agy_safe": [ "utils/py/_marathon_plan_node.js", "test/marathon-plan.sh" ], "orchestrator_only": [] }
}
```
