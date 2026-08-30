---
gh_issue: 102
source: https://github.com/HiQS-Labs/XYZ-forge/issues/102
title: "GH-102: Unify Telemetry Schema & Inspection Tooling Across Fuzzing (utils/fuzzing) and ATE (utils/ate)"
status: Complete
created: 2026-08-20
updated: 2026-08-20
owner: orchestrator
doc_type: feedback
effort: 2
complexity: 2
risk: 1
phases: 4
goal: >
  Unify the telemetry data contract (schema_version: "1.0") and inspection tooling across
  deterministic synthetic fuzzing (utils/fuzzing/fuzz-loop.sh) and combinatorial variation sweeps
  (utils/ate/scripts/run_variations.py), while keeping their execution engines decoupled.
---

# GH-102: Unify Telemetry Schema & Inspection Tooling Across Fuzzing and ATE

## Status

| What was just completed | What's next |
|---|---|
| **Phases 1–4 Complete (2026-08-20):** Standardized schema 1.0; instrumented `fuzz-loop.sh` with argv-safe emission and sub-second timing; updated `run_variations.py` token source triage; expanded `checkin.py` with nearest-rank percentiles and compare mode; verified via `gh102-telemetry-schema.sh` (8/8 fuzz pass); archived receipts in `TESTS-RESULTS/2026-08-20+GH-102/`; CommandCode GLM-5.2 review approved. | Commit, push, and close Issue #102. |

## Table of contents
- [Definition of Done](#definition-of-done)
- [Phase 1: Telemetry Schema & fuzz-loop.sh Instrumentation](#phase-1-telemetry-schema--fuzz-loopsh-instrumentation)
- [Phase 2: Universal Inspection CLI (checkin.py)](#phase-2-universal-inspection-cli-checkinpy)
- [Phase 3: ATE Schema Parity & Variation Benchmark](#phase-3-ate-schema-parity--variation-benchmark)
- [Phase 4: Synthetic Validation & Review Relay](#phase-4-synthetic-validation--review-relay)

---

## Definition of Done

This effort is complete only when all five criteria are verified:
1. **Schema 1.0 Standardization:** Both `utils/fuzzing/fuzz-loop.sh` and `utils/ate/scripts/run_variations.py` emit valid JSONL records conforming to `schema_version: "1.0"` with standardized fields (`run_id`, `timestamp`, `engine`, `status`, `exit_code`, `duration_ms`, `turn_count`, `prompt_tokens`, `completion_tokens`, `total_tokens`, `tokens_source`, `classification`).
2. **Deterministic Fuzzing Telemetry:** `fuzz-loop.sh --jsonl <path>` emits structured per-test execution telemetry without altering standard stdout output.
3. **Universal Inspection CLI:** `utils/ate/scripts/checkin.py` parses and summarizes both Fuzzing and ATE variation logs, computing status distributions, latency statistics, and token metrics.
4. **Synthetic Verification Suite:** `test/synthetic/gh102-telemetry-schema.sh` validates schema correctness and parser compatibility across both engines (**PASS** under `fuzz-loop.sh`).
5. **Receipts & Relay Review:** Test outputs archived in `TESTS-RESULTS/2026-08-20+GH-102/` and reviewed via `/relay-xyz` with CommandCode + GLM-5.2.

---

## Phase 1: Telemetry Schema & fuzz-loop.sh Instrumentation

### Objectives
- Add `--jsonl <path>` flag and `FUZZ_JSONL_PATH` environment variable support to `utils/fuzzing/fuzz-loop.sh`.
- Format records with millisecond precision and explicit nullability for token counts (`tokens_source: "unsupported"`).

---

## Phase 2: Universal Inspection CLI (checkin.py)

### Objectives
- Refactor `utils/ate/scripts/checkin.py` to auto-detect `engine: "fuzz_loop"` vs `engine: "ate_variations"`.
- Support `--summary`, `--tail <n>`, and `--compare <file1> <file2>`.
- Output summary tables with status breakdown, pass rate %, latency percentiles, and token usage.

---

## Phase 3: ATE Schema Parity & Variation Benchmark

### Objectives
- Ensure `utils/ate/scripts/run_variations.py` emits `engine: "ate_variations"` matching schema 1.0.
- Execute trial run and save receipts to `TESTS-RESULTS/2026-08-20+GH-102/`.

---

## Phase 4: Synthetic Validation & Review Relay

### Objectives
- Author `test/synthetic/gh102-telemetry-schema.sh`.
- Conduct `/relay-xyz` review with CommandCode and GLM-5.2.
