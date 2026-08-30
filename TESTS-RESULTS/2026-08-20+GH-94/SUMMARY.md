# ATE Benchmark Run Summary: GH-94 (2026-08-20)

- **Date:** 2026-08-20
- **Tracking Issue:** [#94](https://github.com/HiQS-Labs/XYZ-forge/issues/94)
- **Active Working Doc:** [`PROJECT/2-WORKING/GH-94-PROGRAMMATIC-TOOL-CALLING.md`](../../PROJECT/2-WORKING/GH-94-PROGRAMMATIC-TOOL-CALLING.md)
- **Campaign Duration:** 180 minutes (3.0 hours)
- **Total Iterations Completed:** 438 runs
- **Evaluator / Classifier:** `google/gemma-4-31b-qat` via local LM Studio
- **Output Files:**
  - [`error_log.jsonl`](error_log.jsonl): 438 structured telemetry variation records (`schema_version: "1.0"`).

## Run Distribution

| Mode | Runs | Density Points Covered |
|---|---|---|
| `json_function_calling` | 224 | 5, 15, 25, 26, 30, 50, 100 tools |
| `programmatic_python` | 214 | 5, 15, 25, 26, 30, 50, 100 tools |
| **Total** | **438** | **Full 28-cell matrix swept repeatedly** |

## Key Findings & Verification

1. **Harness Telemetry Capture:** All 438 iterations executed through `utils/ate/scripts/run_variations.py` and `utils/py/script_runner.py`, emitting structured telemetry records (`schema_version: "1.0"`).
2. **Process Lifecycle & Cleanup Invariance:** Subprocess groups were cleanly managed via `setsid` and PGID signal escalations (`SIGTERM` -> `SIGKILL`), leaving zero leaked background processes after 3 hours of continuous cycling.
3. **Automated Triage Loop:** Local Gemma 4 on LM Studio successfully processed triage classifications across the entire 438-run campaign without operator intervention.
4. **Follow-Up (GH-101 / GH-102):** Live API frontier model evaluations (measuring live token consumption and accuracy curves) are tracked under GH-101 and GH-102.
