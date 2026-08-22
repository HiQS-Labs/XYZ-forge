---
gh_issue: 155
source: https://github.com/HiQS-Suite/XYZ-forge/issues/155
title: "3rd Gen ATE & Fuzzing: Metamorphic Invariants & Differential Oracles"
status: Active (2-WORKING — Phase 1 & 2 complete, Phase 3 next)
created: 2026-08-22
updated: 2026-08-22
owner: noelsaw1
doc_type: plan
effort: 3
complexity: 3
risk: 2
phases: 5
rating: "pri/sev/appeal/effort 85/70/90/50 · calc 295"
related:
  - https://github.com/HiQS-Suite/XYZ-forge/issues/141
  - https://github.com/HiQS-Suite/XYZ-forge/issues/142
  - https://github.com/HiQS-Suite/XYZ-forge/issues/156
  - https://github.com/HiQS-Suite/XYZ-forge/pull/150
  - https://github.com/HiQS-Suite/XYZ-forge/pull/157
  - https://github.com/HiQS-Suite/XYZ-forge/pull/160
goal: >
  Execute 3rd Gen Agentic ATE & Fuzzing (#155): build deterministic $0 metamorphic
  invariant assertion oracles (Phase 1) and differential multi-harness cross-testing oracles (Phase 2)
  before introducing hermetic delta-minimizers (Phase 3) and autonomous self-healing loops (Phase 4).
---

# GH-155: 3rd Gen ATE & Fuzzing — Phases 1 & 2

## Status

| What was just completed | What's next |
|---|---|
| **Phase 1 & Phase 2 Built (2026-08-22)**: (1) `utils/py/metamorphic_oracle.py` (29/29 assertions) & `test/gh155-phase1-metamorphic-invariants.sh` (8/8 pass) asserting zero-mutation, idempotence, and canonical realpath containment (GH-567). (2) `utils/py/differential_oracle.py` (7/7 vectors across 7 shims) & `test/gh155-phase2-differential-oracle.sh` (3/3 pass) validating cross-runner contract consensus and failure-mode parity. Full pre-push test gate 100% green. | **Phase 3 (Hermetic Reproducer & Delta Minimization)**: Author `utils/py/repro_builder.py` to ingest failing telemetry records, generate standalone executable `repro.sh` test cases, and perform automated hierarchical delta minimization. |

## Architectural Bets & Invariants

1. **Deterministic Ground First ($0 LLM Overhead):** Consolidate scattered guards into reusable, deterministic per-entry-point assertion oracles before connecting paid or local LLM mutation loops.
2. **Full-Clone Isolation (GH-564):** All fuzzing and oracle runs execute in separate standalone full clones, never in linked worktrees sharing `.git/config`.
3. **Use-Boundary Path Containment (GH-567):** Sandbox paths are verified as canonical resolved descendants of `$WORK` at every function boundary where they are used.
4. **No-New-Bash Rail (GH-551):** All oracle logic is implemented in authoritative Python in `utils/py/`.
5. **No Manufactured Work (GH-45):** Invariants must be falsifiable and verified against actual counterexamples.

## 5-Phase Roadmap Summary

- **Phase 1 (Completed)**: Metamorphic Invariant Assertions & Sandbox Hardening (Zero-Mutation, Idempotence, Realpath Containment).
- **Phase 2 (Completed)**: Differential Multi-Harness Cross-Testing Oracle (`agy`, `codex`, `claude`, `aider`, `pi`, `commandcode`, `deepseek`).
- **Phase 3 (Active Next)**: Hermetic Reproducer & Delta Minimization (`utils/py/repro_builder.py`).
- **Phase 4**: Gated Autonomous Self-Healing Builder Loop (`deepseek-v4-pro` in disposable full clones).
- **Phase 5**: 4-Family Active Explorer Agent (Argv Grammar, Env Presence, Path Canonicalization, Process Limits).
