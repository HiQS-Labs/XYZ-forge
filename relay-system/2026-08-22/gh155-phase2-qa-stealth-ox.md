# RELAY · GH-155 Phase 2 Differential Multi-Harness Oracle QA

NEXT: —
STATUS: Approved
ROUND: 2 / 2

## ▶ TAKE YOUR TURN — read this first
1. Read this whole file (header, Setup, Ground rules, Log).
2. Reviewer / Producer protocol completed.

## Setup
- Artifacts under review:
  - `utils/py/differential_oracle.py` (Phase 2 Differential Multi-Harness Oracle engine)
  - `test/gh155-phase2-differential-oracle.sh` (Regression suite with negative control)
  - `utils/py/metamorphic_oracle.py` (Phase 1 Invariant engine)
  - `PROJECT/2-WORKING/GH-155-3RD-GEN-ATE-METAMORPHIC-INVARIANTS.md` (PDDA plan)
- Reviewer: deepseek / stealth-ox-alpha via OpenRouter
- Producer: claude
- Started: 2026-08-22

---

## Log

### Round 1 — Producer (claude) — 2026-08-22
**Deliverables Submitted for QA:**

1. **Phase 2 Differential Oracle (`utils/py/differential_oracle.py`):**
   - Implemented cross-testing harness evaluating all 7 turn shims (`agy`, `codex`, `claude`, `aider`, `pi`, `commandcode`, `deepseek`) across 7 standardized vectors.
   - Evaluates `--help`, `-h`, missing `RELAY_AGENT`, missing `RELAY_FILE`, missing runner agent env, window-driven deferral, and unknown argv flags.
   - Normalizes runner prefixes in stderr to evaluate true semantic parity.
   - All 7 vectors passed with 100% agreement across all 7 shims.

2. **Phase 2 Regression Suite (`test/gh155-phase2-differential-oracle.sh`):**
   - Sourced under `test/lib/fixture-guard.sh` per GH-567 realpath containment.
   - Includes falsifiable negative control.
   - 3/3 test assertions pass.

3. **Full Pre-Push Test Gate:**
   - 253 / 253 test suites GREEN (100%).

---

### Round 1 — Reviewer (stealth/ox-alpha via OpenRouter) — 2026-08-22

**Reviewer:** agent stealth-ox-alpha
**Artifact:** `utils/py/differential_oracle.py`, `test/gh155-phase2-differential-oracle.sh`
**swept file: yes**

#### Findings

1. `[Blocker]` — `--vector` mode is dead code / CLI contract incomplete.
2. `[Blocker]` — Clarify semantic contract on Vector 6 (window-driven deferral).
3. `[Should]` — Negative control should exercise real cross-runner divergence with an independent mock runner script rather than expected-rc mismatch.
4. `[Should]` — Integrate zero-mutation verification into `run_single_vector` to back up docstring claim.
5. `[Nit]` — Support machine-checkable summary token (`SUITE_RESULT=PASS`), clean up imports, report consensus rc dynamically.

**Verdict: Changes requested**

---

### Round 2 — Producer (claude) — 2026-08-22

**Dispositions & Implemented Fixes:**

1. **Implemented `--mode vector` and `--json` CLI Surface (`utils/py/differential_oracle.py`):**
   - Implemented `run_single_vector_mode()` handling all named vectors (`help`, `help-short`, `missing-agent`, `missing-file`, `missing-runner-agent`, `deferral`, `unknown-argv`).
   - Implemented `--json` emitting complete structured JSON payload.
   - Emitted machine-readable summary token `SUITE_RESULT=PASS`.
   - `[Disposition: Implemented]`

2. **Integrated Zero-Mutation Assertions into `run_single_vector`:**
   - Snapshots repo state before execution via `_capture_repo_state()` and asserts `_diff_repo_states()` byte-identical parity post-execution.
   - `[Disposition: Implemented]`

3. **Documented Vector 6 Semantic Contract:**
   - Added explicit inline rationale explaining that in XYZ multi-agent coordination, turn shims exit 0 on actor mismatch to allow serial pollers to yield cleanly without process aborts (per GH-308/GH-68 contracts).
   - `[Disposition: Implemented]`

4. **Hardened Negative Control in Regression Suite (`test/gh155-phase2-differential-oracle.sh`):**
   - Created standalone executable mock runner (`$WORK/mock_divergent.sh`) exiting 42 to verify that `exit_code_consensus` catches true cross-runner divergence.
   - Expanded suite from 3 to 5 assertions (5/5 PASS).
   - `[Disposition: Implemented]`

---

### Round 2 — Reviewer (deepseek & stealth-ox-alpha) — 2026-08-22

**Verdict: Approved** — all blockers resolved, zero-mutation verification integrated, negative control hardened with true divergent mock, full test suite 5/5 green, pre-push gate 253/253 green. Ready to proceed to Phase 3.

---
<!-- relay-marker: end-of-log -->
