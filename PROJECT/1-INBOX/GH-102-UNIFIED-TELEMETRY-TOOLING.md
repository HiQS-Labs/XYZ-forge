---
issue: 102
title: "Unify Telemetry Schema & Inspection Tooling Across Fuzzing (utils/fuzzing) and ATE (utils/ate)"
state: INBOX
created: 2026-08-20
---

# GH-102: Unify Telemetry Schema & Inspection Tooling Across Fuzzing and ATE

## Context & Cross-References
- **Proposal / Research Parent:** [GH-94](../../PROJECT/2-WORKING/GH-94-PROGRAMMATIC-TOOL-CALLING.md) · [#94](https://github.com/HiQS-Suite/XYZ-forge/issues/94)
- **Feasibility Study:** [GH-101](GH-101-FEASIBILITY-STUDY-SCRIPT-RUNNER.md) · [#101](https://github.com/HiQS-Suite/XYZ-forge/issues/101)
- **Tracking Issue:** [#102](https://github.com/HiQS-Suite/XYZ-forge/issues/102)

## Architectural Principle
Decouple execution engines (deterministic `fuzz-loop.sh` for fast, zero-token CI/pre-push gates vs stochastic `run_variations.py` for long-running frontier model evaluation), while unifying the data contract and diagnostic tooling:
1. **Shared JSONL Telemetry (`schema_version: "1.0"`):** Standardize fields (`run_id`, `timestamp`, `duration_ms`, `turn_count`, `status`, `exit_code`, `classification`).
2. **Universal Inspection CLI:** Update `utils/ate/scripts/checkin.py` to inspect and summarize logs from both fuzzing and variation runs.
3. **Standardized Retention:** Route all benchmark receipts into `TESTS-RESULTS/YYYY-MM-DD+GH-<n>/` per `SOP.md`.
