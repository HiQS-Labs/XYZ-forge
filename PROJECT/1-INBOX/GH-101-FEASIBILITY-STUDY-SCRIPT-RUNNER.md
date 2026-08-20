---
issue: 101
title: "Feasibility Study: Promoting Programmatic Script Runner (script_runner.py) into Core Relay & Consult Runtimes"
state: INBOX
created: 2026-08-20
---

# GH-101: Feasibility Study — Promoting `script_runner.py` into Core Relay & Consult Runtimes

## Context & Motivation
GH-94 established `utils/py/script_runner.py` as a hardened utility for executing model-generated scripts with AST serialization normalization, PGID process-group timeout containment (`setsid`), and fail-closed macOS seatbelt sandboxing (`sandbox-exec`).

Evaluating whether to promote `script_runner.py` into core XYZ runtime layers (`consult.py`, `.relay-scratch/` diagnostics, and programmatic relay turns) is governed by this canonical 3-test qualification checklist (adopted from Fable 5's review). Each item is a binary machine-checkable gate; a test passes only when every box under it is checked.

## Phased Qualification Gate Checklist

### Test 1 of 3 — Architectural Review & Feasibility ✅ PASSED (Remediations Landed at HEAD)
- [x] Independent architectural review of PR #100 completed and adjudicated (Codex CLI turn + Fable 5 QA review).
- [x] Integration touchpoints named (`utils/py/consult.py`, `.relay-scratch/`, `relay-turn-lib`/`relay-drive`).
- [x] **Blocker resolved:** Runner **fails closed** when `--containment-root` is set but no sandbox backend (`sandbox-exec`/`bwrap`) resolves (`utils/py/script_runner.py:102`, verified by `test/synthetic/gh94-containment-invariants.sh` Test #6).
- [x] **Blocker resolved:** Containment scope explicitly documented in docstrings and threat models as write-only kernel containment + PGID process management, with read/network unconfined (requiring disposable full clones per GH-564 for untrusted repos).
- [x] PR #100 body + `SUMMARY.md` corrected to stop citing the deleted `gh94-tool-calling-benchmarks.jsonl` and accurately describe the 438-run campaign as a harness lifecycle and triage stress test.

### Test 2 of 3 — Consult & Diagnostic Probe Dogfooding ⚪ NOT STARTED (Gated on GH-102)
- [ ] `script_runner.py` wired as an optional execution backend in `utils/py/consult.py` behind a flag (default off).
- [ ] Single-turn Python execution benchmarked head-to-head vs sequential JSON tool calls on a real task, **with a model actually called** (replaces the removed synthetic baseline).
- [ ] Benchmark emits live `tokens_source: "api_usage"` records — not `"unsupported"` — proving the telemetry path is exercised end to end.
- [ ] Results show a measurable win (tokens and/or latency and/or accuracy) at the high-tool-count end, or the "26-tool" hypothesis is explicitly retired.
- [ ] No containment regression: Test 1 blockers remain fixed under the consult call path.

### Test 3 of 3 — Relay Turn Integration & Marathon Stress ⚪ NOT STARTED
- [ ] `--tool-mode programmatic` exposed in `relay-drive`/`relay-turn-lib`, default off.
- [ ] End-to-end marathon run with process-group containment validated under real load.
- [ ] Zero leaked child processes and zero out-of-root writes across the full marathon (post-run sentinel assertions on a real, non-scratch-shaped checkout).
- [ ] Fail-closed containment verified on a host **without** `sandbox-exec`/`bwrap` (i.e. the Linux default), not only on a macOS box that happens to have the backend.
- [ ] Promotion decision recorded in `HARNESS-MODELS-REGISTRY.md` per the §4 promotion rules (three reviewable end-to-end successes), replacing the current "hypothesis" note.

### Overall Promotion Gate
- [x] Test 1 ✅ → [ ] Test 2 ✅ → [ ] Test 3 ✅ → **Promote `script_runner.py` into core runtimes**

## Cross-References
- **Runner & Synthetic Harness:** [GH-94](../../PROJECT/2-WORKING/GH-94-PROGRAMMATIC-TOOL-CALLING.md) · [#94](https://github.com/HiQS-Suite/XYZ-forge/issues/94) · [PR #100](https://github.com/HiQS-Suite/XYZ-forge/pull/100)
- **Unified Telemetry & Frontier Variation Sweeps:** [GH-102](GH-102-UNIFIED-TELEMETRY-TOOLING.md) · [#102](https://github.com/HiQS-Suite/XYZ-forge/issues/102)
