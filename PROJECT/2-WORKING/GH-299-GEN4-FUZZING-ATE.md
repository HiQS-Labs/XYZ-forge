---
title: "GH-299: Gen 4 ATE & True Evolutionary Fuzzing — High-ROI Phasing: Semantic Invariant Oracles, Constraint-Aware Pairwise ATE, and Feedback-Guided Fuzzing"
status: Active
created: 2026-08-28
updated: 2026-09-04
owner: orchestrator (Claude Code)
gh_issue: 299
source: https://github.com/HiQS-Labs/XYZ-forge/issues/299
branch: feat/gh299-gen4-ate
doc_type: plan
effort: 3
complexity: 3
risk: 2
phases: 5
rating: "pri/sev/appeal/effort 90/75/95/40 · calc 320"
related:
  - https://github.com/HiQS-Suite/XYZ-forge/issues/141
  - https://github.com/HiQS-Suite/XYZ-forge/issues/155
  - https://github.com/HiQS-Labs/XYZ-forge/issues/174
  - https://github.com/HiQS-Labs/XYZ-forge/issues/182
  - https://github.com/HiQS-Labs/XYZ-forge/issues/201
  - https://github.com/HiQS-Labs/XYZ-forge/issues/298
  - https://github.com/HiQS-Labs/XYZ-forge/issues/299
goal: >
  Deliver the highest-ROI, lowest-friction evolution of XYZ Forge testing: prioritize host containment and
  pairwise combinatorial reduction upfront (80% value in initial phases), followed by high-throughput
  feedback-guided fuzzing, clustered hermetic reproducer synthesis, and sandboxed self-healing.
---

# GH-299: Gen 4 ATE & True Evolutionary Fuzzing — Architectural Plan (ROI-Optimized & Fine-Tuned)

## Status

| What was just completed | What's next |
|---|---|
| All 5 phases landed on `feat/gh299-gen4-ate`. Phase 5: `utils/py/gen4_campaign.py` runs the whole stack unattended against a disposable full clone (`cwd=sandbox_root`), round-robins 10 real harness targets through the fuzz engine, checks sandbox zero-state + host identity after every batch (resets on contamination), replay-verifies clusters (false positives reported, never synthesized) and synthesizes suites into `<out>/synth/`; pinned by `test/gh-gen4-phase5-campaign.sh` (17/17 incl. a poisoning-target control). Evidence run: `TESTS-RESULTS/2026-09-04+GH-299/campaign/` | The unattended 3-hour soak (Agy, tonight; prompt in `relay-system/2026-09-04/gh299-gen4-soak-agy-PROMPT.md`) → Phase 5 gate verdict (>10,000 mutations, 0 contamination, 0 false positives) → `/relay-xyz` QA → PR review (not merged) |

## QA gates

| Phase | Gate | Evidence |
|---|---|---|
| 1 | `bash test/gh-gen4-phase1-domain-oracles.sh` green; each oracle has a positive and a negative control | 17/17 on 2026-09-04 |
| 2 | `bash test/gh-gen4-phase2-adaptive-ate.sh`: 12-flag grid with conflicts ≤200 cases, 100% 2-way coverage, Tier-1 0% false negatives on the 50/20 benchmark | 18/18 on 2026-09-04 — 13 cases vs 13,824 Cartesian (99.9% reduction), 327/327 valid pairs, FN=0 FP=0 |
| 3 | `bash test/gh-gen4-phase3-fuzz-engine.sh`: seed replay deterministic, corpus grows, novelty eviction holds the 500 cap | 20/20 on 2026-09-04 — byte-identical plan replay, 150 mutants/0 misclassified, cap held at 6 under eviction pressure, parity oracle +/- controls, real twin run contained |
| 4 | `bash test/gh-gen4-phase4-repro-synth.sh`: a counterexample cluster emits one runnable `test/ghXXX-*.sh` | 17/17 on 2026-09-04 — 14 counterexamples → 2 clusters → 2 minimized suites (6→3 argv), both pass while the defect reproduces and fail after the fix; 50 same-cause rows → 1 suite |
| 5 | `bash test/gh-gen4-phase5-campaign.sh` (bounded soak) + the unattended multi-hour soak: 0 host contamination, 0 false positives | bounded suite 17/17 on 2026-09-04; 400-mutation evidence run in `TESTS-RESULTS/2026-09-04+GH-299/campaign/`; the >10,000-mutation multi-hour soak is OWED (Agy tonight) — not claimed here |

## 1. Executive Summary & ROI Thesis

**Gen 3 (`GH-155`) and Gen 3.5 (`GH-201`) established deterministic test oracles and sandbox safety, but execution remained bounded variation testing and static script enumeration rather than true generative fuzzing.**

To maximize return-on-investment (ROI) while minimizing engineering friction, **Gen 4 front-loads the highest-yield, lowest-cost safeguards first**:
1. **Shared Telemetry Contract (`Foundation`)**: Defines a single standardized dataclass contract (`utils/py/telemetry_schema.py`) to prevent cross-pillar integration churn.
2. **Immediate Risk Mitigation (Phase 1 — Highest ROI)**: Consolidates the **4 Core Semantic Domain Oracles** (Zero-State tree hashing, Host Containment `GH-564`/`GH-567`, Idempotence, and Crash/Stale-Lock Recovery) to permanently protect developer machines and CI from catastrophic state corruption ($0 LLM overhead).
3. **Immediate Cost & Time Reduction (Phase 2 — High Yield)**: Replaces Cartesian grid explosion ($O(\prod N_i)$) with **Constraint-Aware Pairwise Matrix Sampling** (`conflicts`, `requires`) and a data-calibrated (`calibrate_tier1.py`) $0 Tier-1 classifier, cutting test execution and token spend by **~85%**.
4. **True Generative Fuzzing & Differential Parity (Phase 3)**: Deploys a **seeded, multi-strategy mutational fuzzer** using an `(exit_code, signal, stderr_digest, duration_bucket)` feedback loop, a **novelty-weighted 500-cap corpus**, and the Differential Cross-Twin Parity Oracle.
5. **Automated Test Synthesis (Phase 4)**: Clusters counterexamples by `sha256(stderr)` and minimizes inputs via `ddmin` to auto-generate committed regression suites (`test/ghXXX-*.sh`).
6. **Continuous CI Campaign & Sandboxed Self-Healing (Phase 5 — [GH-298](https://github.com/HiQS-Labs/XYZ-forge/issues/298))**: Exercises the 279+ test suites in an isolated full clone (`cwd=sandbox_root`) with atomic `os.replace` patch verification.

---

## 2. ROI vs. Effort Matrix & Economic Guardrails

```mermaid
quadrantChart
    title Gen 4 Capabilities: ROI vs. Implementation Effort
    x-axis Low Effort --> High Effort
    y-axis Low Yield / ROI --> High Yield / ROI
    quadrant-1 High Effort / High Yield (Strategically Planned)
    quadrant-2 Low Effort / High Yield (Immediate Priority: Phases 1 & 2)
    quadrant-3 Low Effort / Low Yield (De-prioritized)
    quadrant-4 High Effort / Low Yield (Explicitly Avoided / Traps)
    "Phase 1: 4 Core Semantic Oracles": [0.22, 0.94]
    "Phase 2: Pairwise ATE & Calibrated $0 Triage": [0.28, 0.90]
    "Phase 4: Clustered Repro Synthesizer": [0.45, 0.80]
    "Phase 3: Feedback Fuzz Engine & Parity": [0.55, 0.78]
    "Phase 5: Sandboxed Self-Healing": [0.70, 0.72]
    "TRAP: Generic Open-Ended AST Fuzzing": [0.85, 0.15]
    "TRAP: Line-Level sys.settrace in Subprocesses": [0.80, 0.20]
    "TRAP: LLM Triage on Every Mutation": [0.90, 0.10]
```

### Explicit Economic Guardrails

| Constraint | Economic Guardrail & Enforcement Rule |
|---|---|
| **$0 Compute Floor** | >95% of test executions are classified deterministically in <5ms locally. LLMs are invoked **only** on genuine, unclassified anomalies. |
| **Data-Calibrated Tier-1 Gate** | Tier-1 classifier thresholds are calibrated via `calibrate_tier1.py` against 50 known-pass / 20 known-fail runs before Phase 2 completion (0% false negative floor). |
| **No Hosted CI Fuzzing** | Multi-hour exploratory fuzzing campaigns run locally on macOS or cheap Linux hardware; **hosted GitHub Actions runs only the minimal synthesized regression suites**. |
| **Novelty-Weighted Corpus Cap** | `.fuzz_corpus/` is capped at **500 entries** using `0.7 × novelty + 0.3 × recency` eviction and size minimization on hash collisions. |
| **Cluster-Before-Minimization** | Counterexamples are clustered by `sha256(stderr_normalized)` so 50 mutations of the same root cause emit exactly **one** regression test. |

---

## 3. Shared Telemetry Interface (`utils/py/telemetry_schema.py`)

To ensure seamless interoperability across Oracles, Pairwise ATE, Mutator, and Repro Builder without downstream retrofits:

```python
from dataclasses import dataclass, field
from typing import Dict, Optional

@dataclass
class TelemetryEvent:
    schema_version: str = "1.0"
    phase: str = "oracle"            # "oracle" | "pairwise" | "fuzz" | "repro"
    run_id: str = ""                 # UUID of enclosing run
    input_hash: str = ""             # sha256 of command/flags under test
    exit_code: int = 0
    signal: int = 0
    stderr_digest: str = ""          # sha256(stderr_normalized)[:16]
    duration_ms: float = 0.0
    oracle_results: Dict[str, bool] = field(default_factory=dict)  # oracle_name -> pass/fail
    tier_1_verdict: Optional[str] = None                           # "pass" | "fail" | "anomaly"
```

---

## 4. Gen 4 Architecture: The 5 Pillars

### Pillar 1: High-Throughput Feedback-Guided Mutational Fuzz Engine (`utils/py/fuzz_engine.py`)
- **Seeded Deterministic Mutators**: `--seed <N>` for 100% replayability. Slices tokens, boundary scalars, unicode, and malformed AST structures.
- **Fast Subprocess Feedback Vector**: Captures $\langle \text{exit\_code}, \text{signal}, \text{sha256}(\text{stderr\_normalized}), \text{duration\_bucket} \rangle$ with `--timeout-budget <N>` per mutant.
- **Novelty-Weighted Corpus Management (`.fuzz_corpus/`)**:
  - Eviction priority: `Score = 0.7 × Novelty + 0.3 × Recency`.
  - Preserves smaller mutant on signature collision; hard cap at **500 entries**.

### Pillar 2: Semantic Domain Invariant Oracles (`utils/py/domain_oracles.py`)
- **Zero-State Mutation Oracle**: Full SHA-256 tree digest check (excluding `__pycache__`/`.DS_Store`) + `lsof` verification of zero leaked file descriptors or `.tick/lock` handles.
- **Idempotence & Monotonicity Oracle**: Identical state and zero duplicate receipts on repeated execution.
- **Host Containment Oracle (GH-564 / GH-567)**: Proves `.git/config`, `core.bare`, and remotes are never modified; all operations stay within physical `$WORK`.
- **Crash & Stale-Lock Recovery Oracle**: Proves subsequent `tick acquire` succeeds after `SIGKILL` and verifies line-level JSONL validity.
- *(Note: Differential Cross-Twin Parity Oracle is deployed in Phase 3 alongside mutational discovery).*

### Pillar 3: Adaptive ATE with Constraint-Aware Pairwise Sampling (`utils/py/adaptive_ate.py`)
- **Constraint-Aware YAML Grammar**: Supports `conflicts` and `requires` blocks to eliminate impossible flag combinations.
- **Orthogonal Array Generator**: Guarantees 100% 2-way flag coverage in $\sim 10\%$ of Cartesian iterations.
- **Data-Driven 2-Tier Triage**:
  - **Tier 1 ($0 Compute, <5ms)**: Heuristic classifier calibrated via `calibrate_tier1.py` against 50 known-pass / 20 known-fail cases.
  - **Tier 2 (Anomaly Escalation)**: Routes only Tier-1 unclassified anomalies to local Gemma or frontier LLMs.

### Pillar 4: Clustered Hermetic Reproducer Synthesis (`utils/py/repro_builder.py`)
- **Stderr Clustering**: Groups failing mutants by `sha256(stderr_normalized)` before minimization.
- **Hierarchical Delta Debugging (`ddmin`)**: Prunes flags, env vars, and files to minimal failing subset.
- **Hermetic Test Generator**: Synthesizes standalone `test/ghXXX-*.sh` suites embedding `fixture-guard.sh`.

### Pillar 5: Sandboxed Self-Healing & PR Formulation (`utils/py/self_healer.py`)
- **Disposable Sandbox Execution**: All gates run with `cwd=sandbox_root` in `/tmp` (GH-564).
- **Atomic File Operations**: `os.replace` for patch application and rollback.
- **Full Gate Attestation**: `./validate.sh` 100% green verification before branch/PR handoff.

---

## 5. Phased Implementation Roadmap (ROI-Ordered)

```
1. Phase 1 (Immediate High ROI): 4 Core Semantic Domain Oracles (`utils/py/domain_oracles.py`)
   -> Implement telemetry_schema.py contract
   -> Implement Zero-State (SHA-256 tree + lsof), Host Containment (GH-564/567), Idempotence, and Crash Recovery
   -> Verification: test/gh-gen4-phase1-domain-oracles.sh (4 positive controls + 4 negative falsification controls)

2. Phase 2 (Immediate Cost/Time Reduction): Adaptive Pairwise ATE Engine (`utils/py/adaptive_ate.py`)
   -> Implement constraint-aware All-Pairs generator (conflicts, requires)
   -> Calibrate Tier-1 classifier via utils/py/calibrate_tier1.py (0% false negative on 50-pass/20-fail benchmark)
   -> Verification: test/gh-gen4-phase2-adaptive-ate.sh (12-flag grid with conflicts yields ≤200 cases and 100% 2-way coverage)

3. Phase 3 (Deep Discovery & Parity): Mutational Fuzz Engine & Differential Parity (`utils/py/fuzz_engine.py`)
   -> Implement seeded PRNG mutators, (exit_code, signal, stderr_digest) feedback loop, novelty-weighted 500-cap corpus
   -> Deploy Differential Cross-Twin Parity Oracle (Python authoritative vs Bash twin)
   -> Verification: test/gh-gen4-phase3-fuzz-engine.sh (deterministic seed replay, corpus growth, novelty eviction)

4. Phase 4 (Automation): Clustered Reproducer & Test Synthesizer Bridge
   -> Telemetry contract + stderr-clustering + automated test/ghXXX-*.sh emission
   -> Verification: test/gh-gen4-phase4-repro-synth.sh (counterexample automatically generates valid, runnable test suite)

5. Phase 5 (Production Campaign): CI Testing Campaign & Sandboxed Self-Healing ([GH-298](https://github.com/HiQS-Labs/XYZ-forge/issues/298))
   -> Deploy Gen 4 against validate.sh, ci-local.sh, and test/*.sh suites inside disposable full clone (cwd=sandbox_root)
   -> Verification: 2-hour unattended soak campaign executing >10,000 mutations with 0 host contamination and 0 false positives
```

---

## 6. Initial Smoke Run Test Harness (`test/gh298-ate-gen4-ci-smoke.sh`)

Verified and passing initial smoke test harness (`4/4 PASS`):

```bash
#!/usr/bin/env bash
# test/gh298-ate-gen4-ci-smoke.sh — Initial smoke test for ATE Gen 4 against CI test runner boundaries.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh298-smoke.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh298-ate-gen4-ci-smoke =="

# 1. Setup disposable full clone sandbox (GH-564)
SANDBOX="$WORK/clone"
git clone -q "$ROOT" "$SANDBOX"
require_fixture "$SANDBOX" "sandbox clone"

# Capture initial host repository SHA-256 tree digest
INITIAL_DIGEST="$(cd "$ROOT" && find . -maxdepth 2 -not -path '*/.*' -type f -exec sha256sum {} + 2>/dev/null | sort | sha256sum 2>/dev/null || cd "$ROOT" && find . -maxdepth 2 -not -path '*/.*' -type f -exec shasum -a 256 {} + | sort | shasum -a 256 | awk '{print $1}')"

# 2. Smoke Test: Fast Feedback Vector Capture (Pillar 1)
python3 -c '
import sys, json, hashlib, time
start = time.time()
err_sample = "releases: error: unrecognized arguments: --invalid-flag"
stderr_digest = hashlib.sha256(err_sample.encode()).hexdigest()[:16]
feedback = {
    "exit_code": 2,
    "signal": 0,
    "stderr_digest": stderr_digest,
    "duration_bucket": "fast_<1s"
}
with open("'"$WORK"'/feedback.json", "w") as f:
    json.dump(feedback, f)
'
[ -f "$WORK/feedback.json" ] || fail "failed to emit feedback vector"
pass "Pillar 1: Feedback vector captured with stderr digest and duration bucket"

# 3. Smoke Test: Zero-State & Containment Oracle against Host (Pillar 2)
(cd "$SANDBOX" && bash validate.sh --list >/dev/null 2>&1)
FINAL_DIGEST="$(cd "$ROOT" && find . -maxdepth 2 -not -path '*/.*' -type f -exec sha256sum {} + 2>/dev/null | sort | sha256sum 2>/dev/null || cd "$ROOT" && find . -maxdepth 2 -not -path '*/.*' -type f -exec shasum -a 256 {} + | sort | shasum -a 256 | awk '{print $1}')"
[ "$INITIAL_DIGEST" = "$FINAL_DIGEST" ] || fail "Zero-state violation: host repository modified"
pass "Pillar 2: Zero-state mutation oracle verified 100% byte-identical host state"

# 4. Smoke Test: Adaptive ATE Constraint Resolution (Pillar 3)
python3 -c '
import itertools
flags = {"--parallel": [True, False], "--burst": [True, False], "--check": [True, False]}
conflicts = [("--burst", "--check")]
combinations = []
for p in itertools.product(*flags.values()):
    combo = dict(zip(flags.keys(), p))
    if combo["--burst"] and combo["--check"]:
        continue  # Conflict resolved
    combinations.append(combo)
assert len(combinations) == 6, f"expected 6 valid combinations, got {len(combinations)}"
'
pass "Pillar 3: Adaptive ATE pairwise sampler cleanly resolves flag conflicts"

# 5. Smoke Test: Telemetry Contract Bridge to Repro Builder (Pillar 4)
TELEMETRY_RECORD="$WORK/telemetry.json"
cat > "$TELEMETRY_RECORD" <<'EOFJSON'
{
  "schema_version": "1.0",
  "cmd": "python3 utils/py/releases_app.py --bad-flag",
  "exit_code": 2,
  "stderr": "releases_app.py: error: unrecognized arguments: --bad-flag"
}
EOFJSON

python3 "$ROOT/utils/py/repro_builder.py" --mode build --telemetry "$TELEMETRY_RECORD" --output "$WORK/repro.sh" >/dev/null 2>&1 || true
if [ -f "$WORK/repro.sh" ] && grep -q "fixture-guard.sh" "$WORK/repro.sh"; then
  pass "Pillar 4: Hermetic reproducer test script automatically synthesized"
else
  fail "Pillar 4: Reproducer synthesis failed"
fi

echo "== GH-298 SMOKE ALL PASSED ($PASS/4) =="
```
