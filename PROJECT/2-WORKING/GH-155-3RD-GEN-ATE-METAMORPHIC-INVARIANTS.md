---
gh_issue: 155
source: https://github.com/HiQS-Suite/XYZ-forge/issues/155
title: "3rd Gen ATE & Fuzzing: Phase 1 Metamorphic Invariants & Sandbox Hardening"
status: Active (2-WORKING — Phase 1 in progress)
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
goal: >
  Execute Phase 1 of 3rd Gen Agentic ATE & Fuzzing (#155): build deterministic $0 metamorphic
  invariant assertion oracles (zero-mutation on read-only/help/dry-run invocations, idempotence over
  repeated sequential/parallel executions, and strict canonical use-boundary sandbox containment per
  GH-567) before introducing autonomous explorer loops.
---

# GH-155: 3rd Gen ATE & Fuzzing — Phase 1 Metamorphic Invariants & Sandbox Hardening

## Status

| What was just completed | What's next |
|---|---|
| **Intake & Plan Ratification (2026-08-22)**: Umbrella issue #155 opened, brainstormed, and refined via GLM/operator review into a 5-phase execution plan anchored on deterministic ground first. Dedicated standalone clone `xyz-gh155-3rd-gen-ate-p1` provisioned. | **Phase 1 Implementation**: Author `utils/py/metamorphic_oracle.py`, harden `test/lib/fixture-guard.sh` with resolved canonical path assertions (GH-567), and author regression suite `test/gh155-phase1-metamorphic-invariants.sh`. |

## Architectural Bets & Invariants

1. **Deterministic Ground First ($0 LLM Overhead):** Consolidate scattered guards into reusable, deterministic per-entry-point assertion oracles before connecting paid or local LLM mutation loops.
2. **Full-Clone Isolation (GH-564):** All fuzzing and oracle runs execute in separate standalone full clones, never in linked worktrees sharing `.git/config`.
3. **Use-Boundary Path Containment (GH-567):** Sandbox paths are verified as canonical resolved descendants of `$WORK` at every function boundary where they are used.
4. **No-New-Bash Rail (GH-551):** All oracle logic is implemented in authoritative Python in `utils/py/`.
5. **No Manufactured Work (GH-45):** Invariants must be falsifiable and verified against actual counterexamples.

## 5-Phase Roadmap Summary

- **Phase 1 (Active — This Work)**: Metamorphic Invariant Assertions & Sandbox Hardening (Zero-Mutation, Idempotence, Realpath Containment).
- **Phase 2**: Differential Multi-Harness Cross-Testing Oracle (`agy`, `codex`, `claude`, `pi`, `commandcode`, `deepseek`).
- **Phase 3**: Hermetic Reproducer & Delta Minimization (`utils/py/repro_builder.py`).
- **Phase 4**: Gated Autonomous Self-Healing Builder Loop (`deepseek-v4-pro` in disposable full clones).
- **Phase 5**: 4-Family Active Explorer Agent (Argv Grammar, Env Presence, Path Canonicalization, Process Limits).

## Phase 1 Execution Plan

### 1. Zero-Mutation Oracle (`utils/py/metamorphic_oracle.py`)
- Evaluates entry points (`validate.sh`, `utils/py/*.py`, `relay-automation/*.sh`) under read-only / diagnostic invocations (`--help`, `-h`, `--version`, `--print-mode`, `--check`, `--dry-run`).
- Snapshot before & after: git status, untracked files, SHA-256 tree digest, `.git/config` hash.
- Invariant: Byte delta == 0.

### 2. Idempotence & Anti-Flakiness Oracle
- Executes deterministic probes sequentially and concurrently across workers.
- Invariant: Exit codes, stdout semantics, and telemetry digests must be identical across repeated runs, detecting nondeterministic `mktemp` races.

### 3. Use-Boundary Realpath Containment (`test/lib/fixture-guard.sh`)
- Hardens `require_fixture` to resolve canonical paths (`realpath "$p"` must start with `realpath "$WORK"/`), preventing traversal escapes like `$WORK/../../repo`.

### 4. Verification Suite
- `test/gh155-phase1-metamorphic-invariants.sh`: Asserts zero-mutation, idempotence, and containment invariants against all core entry points.
