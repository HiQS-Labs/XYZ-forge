---
issue: 101
title: "Feasibility Study: Promoting Programmatic Script Runner (script_runner.py) into Core Relay & Consult Runtimes"
state: INBOX
created: 2026-08-20
---

# GH-101: Feasibility Study — Promoting `script_runner.py` into Core Relay & Consult Runtimes

## Context & Motivation
GH-94 established `utils/py/script_runner.py` as a hardened utility for executing model-generated scripts with AST serialization normalization, PGID process-group timeout containment (`setsid`), and macOS seatbelt sandboxing (`sandbox-exec`).

While currently used for synthetic testing and ATE variation sweeps, evaluating whether to promote it into core XYZ runtime layers (`consult.py`, `.relay-scratch/` diagnostics, and programmatic relay turns) requires a rigorous 3-test qualification ladder.

## 3-Phase Qualification Ladder

### Test 1 of 3: Architectural Safety & Boundary Review (STATUS: IN PROGRESS)
- **Review Findings (Codex CLI & Fable 5):** Direct promotion to core turns is **Blocked at Test 1**. While `script_runner.py` prevents zombie processes and enforces launch-path containment + macOS seatbelt sandboxing when `--containment-root` is set, executing untrusted model scripts in the live host repository presents severe `.git` corruption risks (GH-564).
- **Gate Requirement to Pass Test 1:** Core turn-taking execution must run within an isolated disposable full clone or containerized environment, with a strictly capability-limited adapter that cannot reach the caller's `.git` objects or refs.

### Test 2 of 3: Consult & Diagnostic Probe Dogfooding (STATUS: PENDING)
- Wire `script_runner.py` as an opt-in execution backend for `consult.py` and `.relay-scratch/` read-only diagnostic probes.
- Validate that diagnostic probes cannot mutate outer worktree state or leak background processes.

### Test 3 of 3: Relay Turn Integration & End-to-End Marathon Stress (STATUS: PENDING)
- Expose optional `--tool-mode programmatic` in `relay-drive.sh` / `relay_drive.py`.
- Benchmark against live frontier API models (measuring empirical cost, token consumption, latency, and accuracy curves per GH-102) under multi-round marathon load.

## Status & Active Next Steps
- **Test 1 Gate:** Remains Open. Sandbox adapter architecture must be designed before Test 2 dogfooding begins.
- **Cross-References:** [GH-94](../../PROJECT/2-WORKING/GH-94-PROGRAMMATIC-TOOL-CALLING.md) (Runner & Harness) · [GH-102](GH-102-UNIFIED-TELEMETRY-TOOLING.md) (Unified Telemetry & API Variation Sweeps).
