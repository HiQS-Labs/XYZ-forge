---
issue: 101
title: "Feasibility Study: Promoting Programmatic Script Runner (script_runner.py) into Core Relay & Consult Runtimes"
state: INBOX
created: 2026-08-20
---

# GH-101: Feasibility Study — Promoting `script_runner.py` into Core Relay & Consult Runtimes

## Context & Motivation
GH-94 established `utils/py/script_runner.py` as a hardened utility for executing model-generated scripts with AST serialization normalization and PGID process-group timeout containment (`setsid`). While currently used for testing and ATE variation runs, there is high potential value in promoting it to core XYZ runtime layers.

## 3-Phase Qualification Ladder
1. **Test 1 of 3 (Architectural Review & Feasibility Analysis):** Initial review from Codex CLI via `/relay-xyz` on PR #100, capturing initial critique and integration considerations.
2. **Test 2 of 3 (Consult & Diagnostic Probes):** Prototype single-turn Python diagnostic scripts in `utils/py/consult.py` and `.relay-scratch/`.
3. **Test 3 of 3 (Relay Turn Integration & Marathon Validation):** Wire optional `--tool-mode programmatic` flag in `relay-drive` and evaluate under full marathon load.

## Status
- **Phase 1 (Active):** Reviewing PR #100 with Codex CLI; capturing first-pass review into issue #101.
