---
gh_issue: 155
source: https://github.com/HiQS-Suite/XYZ-forge/issues/155
title: "3rd Gen ATE & Fuzzing: Metamorphic Invariants, Differential Oracles, Hermetic Reproducers, Self-Healing & Active Explorers"
status: Complete
created: 2026-08-22
updated: 2026-08-23
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
  - https://github.com/HiQS-Suite/XYZ-forge/pull/172
goal: >
  Execute 3rd Gen Agentic ATE & Fuzzing (#155): build deterministic $0 metamorphic
  invariant assertion oracles (Phase 1), differential multi-harness cross-testing oracles (Phase 2),
  hermetic delta-minimizers (Phase 3), autonomous self-healing loops (Phase 4), and the 4-family active explorer (Phase 5).
---

# GH-155: 3rd Gen ATE & Fuzzing — All 5 Phases Complete

## Status

| What was just completed | What's next |
|---|---|
| **All 5 Phases Built & Landed (2026-08-22)**: (1) `utils/py/metamorphic_oracle.py` & `test/gh155-phase1-metamorphic-invariants.sh` (8/8 pass). (2) `utils/py/differential_oracle.py` & `test/gh155-phase2-differential-oracle.sh` (5/5 pass). (3) `utils/py/repro_builder.py` & `test/gh155-phase3-repro-builder.sh` (7/7 pass). (4) `utils/py/self_healer.py` & `test/gh155-phase4-self-healer.sh` (5/5 pass). (5) `utils/py/active_explorer.py` & `test/gh155-phase5-active-explorer.sh` (4/4 pass) providing end-to-end integration from discovery to patch synthesis. Pre-push test gate 100% green. | **Production Deployment & Campaign Execution**: Continuous 3rd Gen ATE runs with local Gemma-4 31B triage and DeepSeek Harness (`dsh`) autonomous healing. |

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
- **Phase 5 (Completed)**: 4-Family Active Explorer Agent (`utils/py/active_explorer.py`).

## Lessons Learned (For Future Agents)

1. **Deterministic Oracles Ground Everything ($0 Cost):** Building deterministic metamorphic invariant oracles and differential multi-runner oracles upfront creates an un-gameable acceptance floor before invoking LLMs.
2. **True Hierarchical ddmin Over Linear Scanning:** Naive 1-by-1 argument/environment pruning is $O(n^2)$ and fails to discover multi-element interactions; Zeller's subset/complement granularity scaling ($n = \min(2n, |S|)$) achieves minimal failing vectors with far fewer evaluation steps.
3. **Hermetic Root Resolution Across CWDs:** Synthesized reproduction test scripts must bake the repository root and explicit `$XYZ_ROOT` fallback while executing with `cd "$ROOT"`, ensuring standalone execution from `/tmp` or disposable sandboxes without ambient CWD sensitivity.
4. **Use-Boundary Physical Realpath Containment (GH-567):** Never rely solely on lexical path prefix checks; always resolve physical paths with `os.path.realpath` to prevent symlink traversal and `..` escape attacks.
