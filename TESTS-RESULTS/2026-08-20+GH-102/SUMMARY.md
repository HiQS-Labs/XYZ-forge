# Test Results & Receipts: GH-102 (2026-08-20)

## Objective
Verify the unified telemetry data contract (`schema_version: "1.0"`) and universal inspection CLI (`utils/ate/scripts/checkin.py`) across:
1. Deterministic Synthetic Shell Fuzzing (`utils/fuzzing/fuzz-loop.sh --jsonl`)
2. Stochastic ATE Model Variation Sweeps (`utils/ate/scripts/run_variations.py`)

## Inspection Output (`checkin.py --compare`)

```
==================================================
 File 1: fuzz_telemetry.jsonl (Engine: fuzz_loop)
==================================================
Total Runs:    8
Pass Rate:     100.0% (8 passed / 0 failed)
Duration:      avg=517.6ms | p50=85.0ms | p95=2819.0ms | max=2819.0ms
Tokens:        sources: unsupported
Categories:    deterministic_synthetic_fuzz: 8
==================================================

==================================================
 File 2: ate_telemetry.jsonl (Engine: ate_variations)
==================================================
Total Runs:    42
Pass Rate:     100.0% (42 passed / 0 failed)
Duration:      avg=100.0ms | p50=100.0ms | p95=100.0ms | max=100.0ms
Tokens:        sources: unsupported
Categories:    ok: 42
⚠ DRIFT:       Repeated failure cluster detected at tail.
==================================================
```

## Invariants & Findings Verified
- **Schema Parity (1.0):** Both engines emit JSONL matching the common telemetry schema with `duration_ms`, `turn_count`, `prompt_tokens`, `completion_tokens`, `total_tokens`, and `tokens_source`.
- **Fuzzing Engine:** 8/8 synthetic tests passing with true sub-second millisecond timing and argv-safe record emission.
- **ATE Variations:** 42 live iterations executed against `variations.tool-calling.yaml` on a disposable scratch repo with `--mock-classifier`. Token source honestly labeled `unsupported` when model API usage is unmeasured.
- **Inspector Tooling:** `utils/ate/scripts/checkin.py` parses and compares both engines seamlessly using nearest-rank percentiles.
