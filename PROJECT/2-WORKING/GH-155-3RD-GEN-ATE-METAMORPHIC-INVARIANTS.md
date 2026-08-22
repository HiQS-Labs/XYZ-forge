---
gh_issue: 155
source: https://github.com/HiQS-Suite/XYZ-forge/issues/155
title: "3rd Gen ATE & Fuzzing: Metamorphic Invariants, Differential Oracles & Hermetic Reproducers"
status: Active (2-WORKING — Phases 1, 2, 3 complete, Phase 4 next)
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
  invariant assertion oracles (Phase 1), differential multi-harness cross-testing oracles (Phase 2),
  and hermetic delta-minimizers (Phase 3) before introducing autonomous self-healing loops (Phase 4).
---

# GH-155: 3rd Gen ATE & Fuzzing — Phases 1, 2 & 3

## Status

| What was just completed | What's next |
|---|---|
| **Phases 1, 2 & 3 Built (2026-08-22)**: (1) `utils/py/metamorphic_oracle.py` (29/29 assertions) & `test/gh155-phase1-metamorphic-invariants.sh` (8/8 pass). (2) `utils/py/differential_oracle.py` (7/7 vectors across 7 shims) & `test/gh155-phase2-differential-oracle.sh` (5/5 pass) with QA signoff via OpenRouter `stealth/ox-alpha`. (3) `utils/py/repro_builder.py` (6/6 internal assertions) & `test/gh155-phase3-repro-builder.sh` (6/6 pass) providing deterministic ddmin and hermetic `repro.sh` test synthesis. Pre-push test gate 100% green. | **Phase 4 (Gated Autonomous Self-Healing Builder Loop)**: Connect `dsh` (DeepSeek Harness / `deepseek-v4-pro`) to execute autonomous patch generation against synthesized `repro.sh` test cases in disposable full clones. |

## Architectural Bets & Invariants

1. **Deterministic Ground First ($0 LLM Overhead):** Consolidate scattered guards into reusable, deterministic per-entry-point assertion oracles before connecting paid or local LLM mutation loops.
2. **Full-Clone Isolation (GH-564):** All fuzzing and oracle runs execute in separate standalone full clones, never in linked worktrees sharing `.git/config`.
3. **Use-Boundary Path Containment (GH-567):** Sandbox paths are verified as canonical resolved descendants of `$WORK` at every function boundary where they are used.
4. **No-New-Bash Rail (GH-551):** All oracle logic is implemented in authoritative Python in `utils/py/`.
5. **No Manufactured Work (GH-45):** Invariants must be falsifiable and verified against actual counterexamples.

## 5-Phase Roadmap Summary

- **Phase 1 (Completed)**: Metamorphic Invariant Assertions & Sandbox Hardening (Zero-Mutation, Idempotence, Realpath Containment).
- **Phase 2 (Completed)**: Differential Multi-Harness Cross-Testing Oracle (`agy`, `codex`, `claude`, `aider`, `pi`, `commandcode`, `deepseek`).
- **Phase 3 (Completed)**: Hermetic Reproducer & Delta Minimization (`utils/py/repro_builder.py`).
- **Phase 4 (Active Next)**: Gated Autonomous Self-Healing Builder Loop (`deepseek-v4-pro` in disposable full clones).
- **Phase 5**: 4-Family Active Explorer Agent (Argv Grammar, Env Presence, Path Canonicalization, Process Limits).

## Lessons Learned (For Future Agents)

The Phase 2 differential oracle (`test/gh155-phase2-differential-oracle.sh`) was the first thing to ever
test all 7 turn shims together, and it caught a real, pre-existing cross-shim inconsistency the moment
this PR's post-merge reconcile ran against current `development`: `deepseek-turn.py` had no validation
for `DEEPSEEK_AGENT` (defaulted to `"deepseek"` and silently deferred instead of erroring like the other
6 shims). Fixed with a 1-line parity fix matching `codex-turn.py`'s existing pattern rather than inventing
new validation logic. Takeaway: a new cross-cutting oracle like this one is likely to surface latent bugs
in code it has never exercised before — expect that on first run against a wider surface, not just on the
oracle's own new code.
