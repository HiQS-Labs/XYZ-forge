---
gh_issue: 94
source: https://github.com/HiQS-Suite/XYZ-forge/issues/94
title: "GH-94: Programmatic Tool Calling & Code-Mode Execution for Harnesses, Telemetry, and Containment"
status: Active
created: 2026-08-19
updated: 2026-08-19
owner: orchestrator
doc_type: feedback
effort: 3
complexity: 3
risk: 2
phases: 4
goal: >
  Evaluate the architectural transition from structured JSON tool calling to programmatic code-mode
  execution: benchmark the "26 tool" tipping point in custom runner adapters, add deterministic synthetic
  containment fuzzing via fuzz-loop.sh, instrument ATE with token/latency metrics, and define the
  telemetry and model registry evidence standards.
---

# GH-94: Programmatic Tool Calling & Code-Mode Execution for Harnesses, Telemetry, and Containment

## Status

| What was just completed | What's next |
|---|---|
| **Phases 1–4 complete (2026-08-20):** `utils/py/script_runner.py` implemented with AST serialization normalization and PGID timeout cleanup; synthetic suites `gh94-script-serialization.sh` and `gh94-containment-invariants.sh` passing under `utils/fuzzing/fuzz-loop.sh` (7/7 PASS); `utils/ate/scripts/run_variations.py` instrumented with structured telemetry (`duration_ms`, `turn_count`, `prompt_tokens`, `completion_tokens`, `tokens_source`); variation matrix authored in `utils/ate/variations.tool-calling.yaml`; benchmarks committed in `test/baselines/gh94-tool-calling-benchmarks.jsonl`; `HARNESS-MODELS-REGISTRY.md` updated with Section 3.1 & 26-tool tipping point decision rule. | Complete full qualifying validation (`./validate.sh` / `ci-local.sh`) and review summary. |

## Table of contents
- [Definition of Done](#definition-of-done)
- [Phase 1: Deterministic Script Serialization & Timeout Fuzzing](#phase-1-deterministic-script-serialization--timeout-fuzzing)
- [Phase 2: Worktree Containment & Sandbox Boundary Invariants](#phase-2-worktree-containment--sandbox-boundary-invariants)
- [Phase 3: ATE Metrics Instrumentation (Tokens, Latency & Chaining)](#phase-3-ate-metrics-instrumentation-tokens-latency--chaining)
- [Phase 4: Matrix Benchmarks, Telemetry & Registry Integration](#phase-4-matrix-benchmarks-telemetry--registry-integration)

---

## Definition of Done

This effort is complete only when all five criteria are verified:
1. **Synthetic Suites Passing:** `test/synthetic/gh94-script-serialization.sh` and `test/synthetic/gh94-containment-invariants.sh` execute under `bash utils/fuzzing/fuzz-loop.sh` with exit code 0 (`FUZZ_SUMMARY|status=PASS|failed=0`).
2. **Deterministic Containment Boundary:** The script execution wrapper (`utils/py/script_runner.py` or subagent runner) strictly rejects hostile operations (path traversal `../`, symlink breakouts, `.git/config` tampering), verified by pre- and post-run clone-identity sentinel assertions (`core.bare`, `remote.origin.url`, `HEAD`, `user.email`).
3. **Deterministic Process-Group Cleanup:** A runaway process (`while True: pass`) launched under `setsid` is terminated within `TIMEOUT_S=3` + `GRACE_S=1` via `kill -- -$PGID`; `kill -0 -$PGID` fails (exit 1), leaving zero orphaned children, and returns exit code `124`.
4. **Structured Telemetry Schema:** `utils/ate/scripts/run_variations.py` writes validated JSONL records to an isolated output path with explicit nullability (`prompt_tokens: int | null`, `completion_tokens: int | null`, `tokens_source: "api_usage" | "unsupported"`).
5. **Committed Evidence & Registry Policy:** Multi-model benchmarks covering tool counts `[5, 15, 25, 26, 30, 50, 100]` are committed in `test/baselines/gh94-tool-calling-benchmarks.jsonl` and synthesized into `HARNESS-MODELS-REGISTRY.md` using the quantitative tipping-point decision rule.

---

## Phase 1: Deterministic Script Serialization & Timeout Fuzzing

### Objectives
- Add `test/synthetic/gh94-script-serialization.sh` to exercise:
  - **Literal `\n` vs Real Newline Interpolation:** Verify that models emitting escaped `\n` strings in code payloads are normalized without triggering syntax crashes.
  - **Nested Quotes & Shell Metacharacters:** Assert that complex code blocks with embedded `"`, `'`, `$VAR`, and backticks execute accurately.
  - **Syntax Error Recovery:** Assert that malformed scripts exit cleanly with non-zero status and structured error output rather than wedging stdout or hanging.
  - **PGID Timeout Termination:** Execute a looping script in a new session group (`setsid`), enforce `TIMEOUT_S=3`, send `SIGTERM` and subsequent `SIGKILL` to `-$PGID` after `GRACE_S=1`, assert `kill -0 -$PGID` returns non-zero, and assert the harness exits 124.

### QA Gate 1
- `bash utils/fuzzing/fuzz-loop.sh` runs `test/synthetic/gh94-script-serialization.sh` cleanly with exit code 0 and zero dangling child processes.

---

## Phase 2: Worktree Containment & Sandbox Boundary Invariants

### Objectives
- Define the script execution wrapper boundary and add `test/synthetic/gh94-containment-invariants.sh` to enforce:
  - **Path Boundary Resolution:** Every file read/write initiated by the runner is checked at the use boundary (`cd "$WORK" && pwd -P`) to reject `../` traversal, absolute parent paths, and symlink escapes (GH-567 / GH-1).
  - **Host Clone Invariance:** Snapshot clone identity before and after executing hostile scripts attempting `git config --local`, `git remote set-url`, or `core.bare=true`. Assert zero drift across `core.bare`, `remote.origin.url`, and `HEAD`.
  - **Untracked File Protection:** Confirm that script failure or exception cleanup cannot touch untracked files outside the runner's designated `$WORK` directory.

### QA Gate 2
- Run `bash utils/fuzzing/fuzz-loop.sh` covering `gh94-containment-invariants.sh` with 0 sandbox escapes and byte-identical pre/post git sentinels.

---

## Phase 3: ATE Metrics Instrumentation (Tokens, Latency & Chaining)

### Objectives
- Extend `utils/ate/scripts/run_variations.py` to record:
  ```json
  {
    "schema_version": "1.0",
    "run_id": "run-20260820-01",
    "variation_id": "var-50-tools-code",
    "model": "qwen/qwen3.8-max",
    "tool_mode": "python_script",
    "tool_count": 50,
    "duration_ms": 1840,
    "turn_count": 1,
    "prompt_tokens": 820,
    "completion_tokens": 140,
    "total_tokens": 960,
    "tokens_source": "api_usage",
    "status": "pass"
  }
  ```
  - Explicit nullability: if provider token counts are unavailable, emit `prompt_tokens: null`, `completion_tokens: null`, `total_tokens: null`, and `tokens_source: "unsupported"`.
- Support `--log-file <path>` to allow isolated output validation during dry-runs.

### QA Gate 3
- Execute `python3 utils/ate/scripts/run_variations.py --dry-run --minutes 1 --log-file "$TMPDIR/test-metrics.jsonl"` and validate all records against the schema specification.

---

## Phase 4: Matrix Benchmarks, Telemetry & Registry Integration

### Objectives
- Author `utils/ate/variations.tool-calling.yaml` sweeping:
  - **Tool Density:** `[5, 15, 25, 26, 30, 50, 100]` tools registered.
  - **Execution Mode:** `[json_function_calling, programmatic_python]`.
  - **Task Complexity:** Fixed 3-step chained repo query & transform task fixture.
  - **Models Evaluated:** Claude Sonnet 3.7 / 3.5, Codex CLI, Qwen 3.8-Max, DeepSeek-V4.
- **Quantitative Decision Rule:** Programmatic tool calling is recommended over JSON function calling when:
  $$\text{Total Cost}_{\text{Code}} < \text{Total Cost}_{\text{JSON}} \quad \text{OR} \quad \text{Wall Clock Time}_{\text{Code}} < 0.60 \times \text{Wall Clock Time}_{\text{JSON}}$$
  provided task accuracy $\ge 95\%$.
- Commit raw benchmark receipts to `test/baselines/gh94-tool-calling-benchmarks.jsonl` and update model recommendations in `HARNESS-MODELS-REGISTRY.md`.

### QA Gate 4
- Documented benchmark evidence committed in `test/baselines/gh94-tool-calling-benchmarks.jsonl`, updated `HARNESS-MODELS-REGISTRY.md`, and full `./validate.sh` passing.
