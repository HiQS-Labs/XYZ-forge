---
gh_issue: 155
source: https://github.com/HiQS-Suite/XYZ-forge/issues/155
title: "3rd Gen ATE & Fuzzing: Metamorphic Invariants, Differential Oracles, Hermetic Reproducers & Self-Healing Loops"
status: Active (2-WORKING — Phases 1-4 complete, Phase 5 next)
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
  - https://github.com/HiQS-Suite/XYZ-forge/pull/171
goal: >
  Execute 3rd Gen Agentic ATE & Fuzzing (#155): build deterministic $0 metamorphic
  invariant assertion oracles (Phase 1), differential multi-harness cross-testing oracles (Phase 2),
  hermetic delta-minimizers (Phase 3), and autonomous self-healing loops (Phase 4) before introducing the 4-family active explorer (Phase 5).
---

# GH-155: 3rd Gen ATE & Fuzzing — Phases 1, 2, 3 & 4

## Status

| What was just completed | What's next |
|---|---|
| **Phases 1, 2, 3 & 4 Built (2026-08-22)**: (1) `utils/py/metamorphic_oracle.py` & `test/gh155-phase1-metamorphic-invariants.sh` (8/8 pass). (2) `utils/py/differential_oracle.py` & `test/gh155-phase2-differential-oracle.sh` (5/5 pass). (3) `utils/py/repro_builder.py` & `test/gh155-phase3-repro-builder.sh` (7/7 pass). (4) `utils/py/self_healer.py` (4/4 internal assertions) & `test/gh155-phase4-self-healer.sh` (5/5 pass) providing gated dual-acceptance and regression self-healing with iterative feedback recovery. Pre-push test gate 100% green. | **Phase 5 (4-Family Active Explorer Agent)**: Connect generative fuzzing explorers (Argv Grammar, Env Presence, Path Canonicalization, Process Limits) directly into the metamorphic invariants and self-healing loop. |

## Architectural Bets & Invariants

1. **Deterministic Ground First ($0 LLM Overhead):** Consolidate scattered guards into reusable, deterministic per-entry-point assertion oracles before connecting paid or local LLM mutation loops.
2. **Full-Clone Isolation (GH-564):** All fuzzing, healing, and oracle runs execute in separate standalone full clones, never in linked worktrees sharing `.git/config`.
3. **Use-Boundary Path Containment (GH-567):** Sandbox paths are verified as canonical resolved descendants of `$WORK` at every function boundary where they are used.
4. **No-New-Bash Rail (GH-551):** All oracle and self-healing logic is implemented in authoritative Python in `utils/py/`.
5. **No Manufactured Work (GH-45):** Invariants must be falsifiable and verified against actual counterexamples.

## 5-Phase Roadmap Summary

- **Phase 1 (Completed)**: Metamorphic Invariant Assertions & Sandbox Hardening (Zero-Mutation, Idempotence, Realpath Containment).
- **Phase 2 (Completed)**: Differential Multi-Harness Cross-Testing Oracle (`agy`, `codex`, `claude`, `aider`, `pi`, `commandcode`, `deepseek`).
- **Phase 3 (Completed)**: Hermetic Reproducer & Delta Minimization (`utils/py/repro_builder.py`).
- **Phase 4 (Completed)**: Gated Autonomous Self-Healing Builder Loop (`utils/py/self_healer.py`).
- **Phase 5 (Active Next)**: 4-Family Active Explorer Agent (Argv Grammar, Env Presence, Path Canonicalization, Process Limits).
