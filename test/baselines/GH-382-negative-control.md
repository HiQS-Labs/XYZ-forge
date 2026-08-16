# GH-382 — recorded negative control (#419)

Test:     `test/gh382-marathon-memory-telemetry.sh`
Baseline: `commit 45896f5b9d363dbeebfd64fa6f917578be476b77` — `utils/py/marathon_drive.py`, `src/analyze.js`, `src/events.js`, `bin/tick`
Date:     2026-08-15

## Defect Summary

Before GH-382, marathon phase runs and relay turns provided no memory telemetry visibility. Host memory status (compressor size and free swap) was not sampled at phase boundaries, turn subprocess peak RSS was unmeasured, no warning was emitted when host free swap reached critical levels, and end-of-run cost summaries in `tick analyze` reported token and wall-clock figures without memory consumption.

## Verification & Controls

`test/gh382-marathon-memory-telemetry.sh` verifies that:
1. **Phase Boundary Telemetry:** Host memory (compressor and free swap) is sampled and logged at phase start and phase complete boundaries on macOS (`vm_stat` / `sysctl`) and Linux (`/proc/meminfo`).
2. **Subprocess RSS Attribution:** Peak RSS of builder and reviewer turn subprocesses is captured separately and recorded in `cost.memory` events.
3. **Low-Swap Warning:** A critical warning line appears in run output when host free swap drops below 1024 MB.
4. **End-of-Run Analysis:** `tick analyze` (`--- cost ---` section) includes memory metrics (`compressor peak`, `swap free min`, and per-agent `turn peak RSS`).
5. **Negative Control:** Repositories without recorded memory events omit the memory section in `tick analyze`, preserving backwards compatibility with historical runs.
