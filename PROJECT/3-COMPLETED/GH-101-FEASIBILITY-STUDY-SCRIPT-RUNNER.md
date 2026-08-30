---
gh_issue: 101
source: https://github.com/HiQS-Labs/XYZ-forge/issues/101
title: "GH-101: Feasibility Study — Promoting `script_runner.py` into Core Relay & Consult Runtimes"
status: Complete
created: 2026-08-20
updated: 2026-08-20
owner: orchestrator
doc_type: feedback
effort: 3
complexity: 3
risk: 2
phases: 3
goal: >
  Evaluate the feasibility, safety, and performance of promoting utils/py/script_runner.py
  from a standalone test/ATE utility into core XYZ runtime workflows across a canonical 3-test
  qualification ladder.
---

# GH-101: Feasibility Study — Promoting `script_runner.py` into Core Relay & Consult Runtimes

## Status

| What was just completed | What's next |
|---|---|
| **Qualification Ladder Complete (2026-08-20):** Tests 1, 2, and 3 passed and verified. Programmatic tool mode promoted to Production-Ready (A-Grade) across `consult.py` and `relay_drive.py` with full fail-closed sandboxing, throwaway worktree isolation, and committed test receipts. | Final verification gate & issue closeout. |

## Phased Qualification Gate Checklist (Canonical Definition of Done)

### Test 1 of 3 — Architectural Review & Feasibility ✅ PASSED
- [x] Independent architectural review of PR #100 completed and adjudicated (Codex CLI turn + Fable 5 QA review).
- [x] Integration touchpoints named (`utils/py/consult.py`, `.relay-scratch/`, `relay-turn-lib`/`relay-drive`).
- [x] **Blocker resolved:** Runner **fails closed** when `--containment-root` is set but no sandbox backend (`sandbox-exec`/`bwrap`) resolves (`utils/py/script_runner.py:102`, verified by `test/synthetic/gh94-containment-invariants.sh` Test #6).
- [x] **Blocker resolved:** Containment scope explicitly documented in docstrings and threat models as write-only kernel containment + PGID process management, with read/network unconfined (requiring disposable full clones per GH-564 for untrusted repos).
- [x] PR #100 body + `SUMMARY.md` corrected to stop citing the deleted `gh94-tool-calling-benchmarks.jsonl` and accurately describe the 438-run campaign as a harness lifecycle and triage stress test.

### Test 2 of 3 — Consult & Diagnostic Probe Dogfooding ✅ PASSED
- [x] `script_runner.py` wired as an optional execution backend in `utils/py/consult.py` behind `--tool-mode programmatic` (default off / standard).
- [x] Fail-closed containment: `consult.py` enforces throwaway worktree isolation, pre-creates `.relay-scratch/`, and refuses to run if sandbox engines are absent when programmatic mode is requested.
- [x] Paired frontier variation benchmark in `utils/ate/` logging both `tool_count` and `tool_schema_bytes` across tiers [5, 15, 25, 26, 30, 50, 100].
- [x] Negative controls included (deliberately broken tool schema per tier asserting error detection).
- [x] Benchmark emits structured telemetry with honest `tokens_source` triage, evaluated via `checkin.py --compare`.
- [x] No containment regression: zero outer `.git` or worktree contamination across runs.

### Test 3 of 3 — Relay Turn Integration & Marathon Stress ✅ PASSED
- [x] `--tool-mode programmatic` exposed in `relay-drive`/`relay-turn-lib`, default off.
- [x] Multi-turn and marathon stress testing with process-group containment validated under real load.
- [x] Zero leaked child processes and zero out-of-root writes across the full lifecycle (verified in `test/synthetic/gh101-relay-programmatic-stress.sh`).
- [x] Fail-closed containment verified on a host **without** `sandbox-exec`/`bwrap` (`test/synthetic/gh101-relay-programmatic-stress.sh` Test #2).
- [x] Promotion decision recorded in `HARNESS-MODELS-REGISTRY.md` per the §4 promotion rules (three reviewable end-to-end successes), promoting `script_runner.py` to Production-Ready (A-Grade).

## Overall Promotion Gate
- [x] Test 1 ✅ → [x] Test 2 ✅ → [x] Test 3 ✅ → **`script_runner.py` Promoted into Core Runtimes**

## Cross-References
- **Parent Research Track:** [GH-94](../../PROJECT/3-COMPLETED/GH-94-PROGRAMMATIC-TOOL-CALLING.md) · [#94](https://github.com/HiQS-Labs/XYZ-forge/issues/94) · [PR #100](https://github.com/HiQS-Labs/XYZ-forge/pull/100)
- **Unified Telemetry Contract:** [GH-102](../../PROJECT/3-COMPLETED/GH-102-UNIFIED-TELEMETRY-TOOLING.md) · [#102](https://github.com/HiQS-Labs/XYZ-forge/issues/102)
- **Discussion Sync:** [Relay #709506](../../relay-system/2026-08-20/709506-agent2agent-gh-102-telemetry-architecture-gh-101-test-2-consult-dogf.md)
