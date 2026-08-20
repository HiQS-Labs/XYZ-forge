---
gh_issue: 101
source: https://github.com/HiQS-Suite/XYZ-forge/issues/101
title: "GH-101: Feasibility Study — Promoting `script_runner.py` into Core Relay & Consult Runtimes"
status: Active
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
| **Test 1 Passed (2026-08-20):** Architectural review completed; fail-closed sandbox and threat model scoping landed at HEAD; codified 3-test qualification checklist. | Execute Test 2 (consult.py programmatic tool mode dogfooding, paired variation benchmark with tool_schema_bytes, and synthetic validation). |

## Phased Qualification Gate Checklist (Canonical Definition of Done)

### Test 1 of 3 — Architectural Review & Feasibility ✅ PASSED
- [x] Independent architectural review of PR #100 completed and adjudicated (Codex CLI turn + Fable 5 QA review).
- [x] Integration touchpoints named (`utils/py/consult.py`, `.relay-scratch/`, `relay-turn-lib`/`relay-drive`).
- [x] **Blocker resolved:** Runner **fails closed** when `--containment-root` is set but no sandbox backend (`sandbox-exec`/`bwrap`) resolves (`utils/py/script_runner.py:102`, verified by `test/synthetic/gh94-containment-invariants.sh` Test #6).
- [x] **Blocker resolved:** Containment scope explicitly documented in docstrings and threat models as write-only kernel containment + PGID process management, with read/network unconfined (requiring disposable full clones per GH-564 for untrusted repos).
- [x] PR #100 body + `SUMMARY.md` corrected to stop citing the deleted `gh94-tool-calling-benchmarks.jsonl` and accurately describe the 438-run campaign as a harness lifecycle and triage stress test.

### Test 2 of 3 — Consult & Diagnostic Probe Dogfooding 🚧 ACTIVE
- [ ] `script_runner.py` wired as an optional execution backend in `utils/py/consult.py` behind `--tool-mode programmatic` (default off / standard).
- [ ] Fail-closed containment: `consult.py` enforces throwaway worktree isolation, pre-creates `.relay-scratch/`, and refuses to run if sandbox engines are absent when programmatic mode is requested.
- [ ] Paired frontier variation benchmark in `utils/ate/` logging both `tool_count` and `tool_schema_bytes` across tiers [5, 15, 25, 26, 30, 50, 100].
- [ ] Negative controls included (deliberately broken tool schema per tier asserting error detection).
- [ ] Benchmark emits structured telemetry with honest `tokens_source` triage, evaluated via `checkin.py --compare`.
- [ ] No containment regression: zero outer `.git` or worktree contamination across runs.

### Test 3 of 3 — Relay Turn Integration & Marathon Stress ⚪ PENDING
- [ ] `--tool-mode programmatic` exposed in `relay-drive`/`relay-turn-lib`, default off.
- [ ] End-to-end marathon run with process-group containment validated under real load.
- [ ] Zero leaked child processes and zero out-of-root writes across the full marathon (post-run sentinel assertions on a real, non-scratch-shaped checkout).
- [ ] Fail-closed containment verified on a host **without** `sandbox-exec`/`bwrap` (i.e. the Linux default), not only on a macOS box that happens to have the backend.
- [ ] Promotion decision recorded in `HARNESS-MODELS-REGISTRY.md` per the §4 promotion rules (three reviewable end-to-end successes), replacing the current "hypothesis" note.

## Overall Promotion Gate
- [x] Test 1 ✅ → [ ] Test 2 ✅ → [ ] Test 3 ✅ → **Promote `script_runner.py` into core runtimes**

## Cross-References
- **Parent Research Track:** [GH-94](../../PROJECT/3-COMPLETED/GH-94-PROGRAMMATIC-TOOL-CALLING.md) · [#94](https://github.com/HiQS-Suite/XYZ-forge/issues/94) · [PR #100](https://github.com/HiQS-Suite/XYZ-forge/pull/100)
- **Unified Telemetry Contract:** [GH-102](../../PROJECT/3-COMPLETED/GH-102-UNIFIED-TELEMETRY-TOOLING.md) · [#102](https://github.com/HiQS-Suite/XYZ-forge/issues/102)
- **Discussion Sync:** [Relay #709506](../../relay-system/2026-08-20/709506-agent2agent-gh-102-telemetry-architecture-gh-101-test-2-consult-dogf.md)
