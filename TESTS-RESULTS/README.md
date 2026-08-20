# Test Results & Artifacts (`TESTS-RESULTS/`)

This directory contains committed execution artifacts, benchmark datasets, and structured telemetry logs from autonomous testing campaigns (such as ATE variation runs, fuzzing loops, and harness evaluations).

## Purpose

Per repo rail **Rule 6 ("Verified beats plausible" / GH-430)**, claims cited in issues, PRs, ROADMAP entries, or model registries must be backed by retained, verifiable evidence. This directory provides a permanent, auditable home for these empirical test receipts.

## Directory Structure

Each testing campaign is recorded in a dedicated subfolder following the naming convention:

```
TESTS-RESULTS/
├── README.md
└── YYYY-MM-DD+GH-<issue-number>/
    ├── SUMMARY.md                          # Human-readable rollup & configuration details
    ├── error_log.jsonl                     # Structured telemetry & classifier output
    └── <benchmark-name>.jsonl              # Raw baseline measurements & metrics
```

### Contents of Each Folder

1. **`SUMMARY.md`**: Overview of the run, duration, model/harness under test, variations matrix, and high-level findings.
2. **`error_log.jsonl`**: Machine-readable JSONL records containing versioned schemas (`schema_version: "1.0"`), iteration metrics (`duration_ms`, `turn_count`, `prompt_tokens`, `completion_tokens`, `total_tokens`), command outputs, and local LLM classifications.
3. **Receipts & Baselines (`*.jsonl`)**: Raw trial outputs backing entries in `HARNESS-MODELS-REGISTRY.md` or active working docs.

## How to Inspect Results

To inspect recent runs or summarize triage distributions:

```bash
python3 utils/ate/scripts/checkin.py --tail 50 \
  --log "TESTS-RESULTS/YYYY-MM-DD+GH-<issue-number>/error_log.jsonl"
```
