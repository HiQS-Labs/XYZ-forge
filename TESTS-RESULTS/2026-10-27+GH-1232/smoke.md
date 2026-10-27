# GH-1232 manual smoke (GH-1088)

- Date: 2026-10-27, operator Mac, python3 3.14.7
- Disposable full clone: `XYZ-forge-gh1232-jog-promotion-probe-schema-2026-10-27-verify`, cloned from the task branch at `81feed72`; `git status --porcelain` was empty after the runs.
- Script: [smoke.py](smoke.py) calls `promote_contract_to_working(..., interactive=False)`, with the primary pin and the clone commit stubbed. Red control: the same script loading `jog_run.py` from base `5cab70c8`.
- No suite was added (GH-831).

## Fix (81feed72)

```
[9001] main: well-formed contract, no frontmatter probes
      -> PROMOTED: PROJECT/2-WORKING/GH-9001-SMOKE.md
[9002] adjacent: no probes anywhere
      -> PARKED: unreviewed-probe-contract (no valid probes in unattended mode)
[9003] adjacent: command probe 'true' (lint)
      -> PARKED: unreviewed-probe-contract (no valid probes in unattended mode; contract probe 1: trivial probe pattern rejected: 'true')
[9004] adjacent: non-object probe
      -> PARKED: unreviewed-probe-contract (no valid probes in unattended mode; contract probe 1 malformed: not an object)
[9005] adjacent: no execution (command would touch a marker)
      -> PROMOTED: PROJECT/2-WORKING/GH-9005-SMOKE.md
marker .promotion-ran exists after all cases: False
```

## Base 5cab70c8 (red control)

```
[9001] main: well-formed contract, no frontmatter probes
      -> PARKED: unreviewed-probe-contract (no valid probes in unattended mode)
[9002] adjacent: no probes anywhere
      -> PARKED: unreviewed-probe-contract (no valid probes in unattended mode)
[9003] adjacent: command probe 'true' (lint)
      -> PARKED: unreviewed-probe-contract (no valid probes in unattended mode)
[9004] adjacent: non-object probe
      -> PARKED: unreviewed-probe-contract (no valid probes in unattended mode)
[9005] adjacent: no execution (command would touch a marker)
      -> PARKED: unreviewed-probe-contract (no valid probes in unattended mode)
marker .promotion-ran exists after all cases: False
```

## Verdict

PASS.
- **Main path:** promotes on the fix and parks at base.
- **Adjacent paths on the fix:**
  - no probes still parks;
  - `true` parks with the lint reason;
  - a non-object entry parks with a malformed reason;
  - a marker-writing command probe was not executed (no marker).

The marker case promotes because promotion checks only the shape. Preflight evaluates the probe next.
