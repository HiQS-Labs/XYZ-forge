# ATE Benchmark Run Summary: GH-94 (2026-08-20)

- **Date:** 2026-08-20
- **Tracking Issue:** [#94](https://github.com/HiQS-Suite/XYZ-forge/issues/94)
- **Active Working Doc:** [`PROJECT/2-WORKING/GH-94-PROGRAMMATIC-TOOL-CALLING.md`](../../PROJECT/2-WORKING/GH-94-PROGRAMMATIC-TOOL-CALLING.md)
- **Campaign Duration:** 180 minutes (3.0 hours)
- **Total Iterations Completed:** 438 runs
- **Evaluator / Classifier:** `google/gemma-4-31b-qat` via local LM Studio
- **Output Files:**
  - [`error_log.jsonl`](error_log.jsonl): 438 structured telemetry variation records (`schema_version: "1.0"`).
  - [`gh94-tool-calling-benchmarks.jsonl`](gh94-tool-calling-benchmarks.jsonl): Empirical density benchmark comparison across 5–100 tools.

## Run Distribution

| Mode | Runs | Density Points Covered |
|---|---|---|
| `json_function_calling` | 224 | 5, 15, 25, 26, 30, 50, 100 tools |
| `programmatic_python` | 214 | 5, 15, 25, 26, 30, 50, 100 tools |
| **Total** | **438** | **Full 28-cell matrix swept repeatedly** |

## Key Findings & Verification

1. **Telemetry Capture:** All 438 iterations recorded structured telemetry (`duration_ms`, `turn_count`, `prompt_tokens`, `completion_tokens`, `tokens_source`) cleanly.
2. **Containment Invariance:** Subprocess groups were cleanly reclaimed via `setsid` and PGID signal escalations (`SIGTERM` -> `SIGKILL`), leaving zero leaked background processes.
3. **Automated Triage:** Gemma on LM Studio successfully classified iterations without manual human intervention.
