---
gh_issue: 1050
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1050
title: "marathon memory telemetry: no false low-swap warning on hosts with no swap"
status: Active
created: 2026-11-15
updated: 2026-11-16
owner: noelsaw1
doc_type: bug
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Changing the 1024MB threshold or compressor telemetry
  - Changing tick cost / tick analyze schemas
goal: >
  A host with no swap configured gets no "free swap is critically low" warning at phase
  boundaries, while a host with real low free swap still does.
roadmap_exempt: true
---

# GH-1050 · No false low-swap warning without swap

## Status

| What was just completed | What's next |
|---|---|
| Captured with source evidence and a reproduction at `4635abe09`/`be0a37520` (GH-1400 dogfood round). | Implement in `_phase_memory_sample` and extend the gh382 suite. |

## Evidence (development `be0a37520`)

- `utils/py/marathon_drive.py:1137` parses only `free=` from `sysctl -n vm.swapusage`; `:1172` warns when `swap_free_mb < 1024` without checking total.
- Linux branch (`:1161`) reads only `SwapFree:`; same gap.
- Reproduced with a stubbed `total = 0.00M used = 0.00M free = 0.00M`: `warn: host free swap is critically low (0MB < 1024MB)`.
- Open PRs #1467 and #1417 touch other hunks of `marathon_drive.py` (about lines 1004-1051, 3211, and `_lane_key`/attested lines); neither touches `_phase_memory_sample`. Recheck at admission.

## Three states to distinguish

1. **No swap configured** (total parsed and equal to 0): no warning; `swap_free` omitted from the telemetry line and from `tick cost` (no false 0MB minimum).
2. **Real low free swap** (total > 0, free < 1024MB): warning unchanged.
3. **Total not parsed**: behave exactly as today (report and warn on free if free parsed; nothing if free unparsed). Only a parsed total of 0 means no swap.

## Acceptance

- [ ] darwin stub `total = 0.00M used = 0.00M free = 0.00M` produces no low-swap warning and no `swap_free=` bit.
- [ ] darwin stub `total = 3072.00M used = 2560.00M free = 512.00M` still produces `warn: host free swap is critically low (512MB < 1024MB)`.
- [ ] Linux `/proc/meminfo` parsing also reads `SwapTotal:` and applies the same no-swap rule (verified by diff review; the suite's swap case is darwin-only).
- [ ] `test/gh382-marathon-memory-telemetry.sh` gains the no-swap case next to the existing low-swap case; all its cases pass.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh --auto development",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/py/marathon_drive.py", "pattern": "SwapTotal" }
  ],
  "artifacts": [
    "utils/py/marathon_drive.py",
    "test/gh382-marathon-memory-telemetry.sh"
  ],
  "remediation": {
    "source": "issue#1050",
    "criteria": "_phase_memory_sample parses swap total (sysctl total= and /proc/meminfo SwapTotal:), treats total 0 as no swap with no warning and no swap_free report, keeps the real low-swap warning; gh382 suite covers no-swap and low-swap."
  }
}
```
