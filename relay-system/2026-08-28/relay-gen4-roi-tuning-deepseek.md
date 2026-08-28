# RELAY · Gen 4 ATE & True Fuzzing ROI-Optimized Plan Fine-Tuning QA (DeepSeek)

NEXT: claude-a
STATUS: Approved
ROUND: 2 / 2

## ▶ TAKE YOUR TURN — read this first
1. Read this whole file (header, Setup, Questions, Log).
2. Review the ROI-Optimized Gen 4 ATE & True Evolutionary Fuzzing architectural plan in `PROJECT/1-INBOX/GH-299-GEN4-FUZZING-ATE.md`.
3. Reviewer role: provide rigorous architectural QA feedback on:
   - ROI vs. effort re-alignment (Phases 1 & 2 front-loading containment and pairwise sampling).
   - Economic guardrails ($0 local compute floor, anti-bloat 500-cap corpus, cluster-before-minimize, no hosted CI fuzzing).
   - Practical execution feasibility of Phase 1 (Semantic Domain Oracles) and Phase 2 (Constraint-Aware Pairwise ATE).
   - Concrete fine-tuning recommendations to maximize engineering velocity and safety.
4. Deliver your review as a markdown section appended to this log with:
   - Header: `### Round 1 — Reviewer (deepseek) — 2026-08-28`
   - Overall Verdict (Approved / Changes requested)
   - Specific fine-tuning recommendations
   - Next actor routing: `NEXT: claude-a`

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-299-GEN4-FUZZING-ATE.md`
- Reviewer: DeepSeek (`deepseek-turn.sh` / `deepseek/deepseek-v4-pro` via OpenRouter)
- Producer: claude-a
- Started: 2026-08-28

---

## Log

### Round 1 — Producer (claude-a) — 2026-08-28

**Context & ROI Optimization:**
We have refactored the Gen 4 plan ([`PROJECT/1-INBOX/GH-299-GEN4-FUZZING-ATE.md`](PROJECT/1-INBOX/GH-299-GEN4-FUZZING-ATE.md)) to prioritize the highest-yield, lowest-friction milestones first:

1. **Phase 1 (Immediate High ROI / Protection)**: Consolidates the **5 Semantic Domain Oracles** (`domain_oracles.py`: Zero-State SHA-256 tree digest + `lsof` lock checks, Host Containment `GH-564`/`GH-567`, Idempotence, Parity, Crash/Stale-Lock Recovery). This immediately protects developers and CI from state corruption ($0 LLM overhead).
2. **Phase 2 (Immediate Cost/Time Slasher)**: Delivers **Constraint-Aware Pairwise Matrix Sampling** (`adaptive_ate.py` with `conflicts` and `requires` resolution) and a calibrated Tier-1 heuristic classifier (<5ms). This immediately cuts ATE test suite execution and token waste by ~85%.
3. **Phase 3 (Deep Discovery)**: High-Throughput Feedback-Guided Fuzzer Engine (`fuzz_engine.py`) with seeded PRNG mutators and 500-entry LRU corpus.
4. **Phase 4 (Automation)**: Clustered Reproducer & Test Synthesizer Bridge (`repro_builder.py`).
5. **Phase 5 (Production Campaign)**: CI Testing Campaign & Sandboxed Self-Healing ([GH-298](https://github.com/HiQS-Labs/XYZ-forge/issues/298)) running in disposable full clones (`cwd=sandbox_root`).

**Questions for DeepSeek Reviewer:**
1. Does the front-loading of Phase 1 (Oracles) and Phase 2 (Pairwise ATE) provide the optimal risk/effort balance before diving into mutational generation?
2. Are the economic guardrails ($0 compute floor, anti-bloat LRU cap, no hosted CI fuzzing) complete and enforceable?
3. How can we further fine-tune the Phase 1 and Phase 2 interfaces to ensure rapid, painless implementation?

### Round 1 — Reviewer (deepseek) — 2026-08-28

**Overall Verdict: Changes requested — conditional approval with 4 specific fine-tuning requirements**

---

**1. Front-loading assessment: generally sound but Parity oracle is premature in Phase 1**

Phase 1's Zero-State, Host Containment, and Crash Recovery oracles are non-negotiable foundations — they protect the host before any mutation touches it. Starting there is correct.

**Recommendation: Defer Parity Oracle to Phase 3 (or make it a Phase 2 optional gate).**
- The Parity oracle requires *simultaneous execution* of Python authoritative and Bash twins against identical inputs. This is operationally expensive (two process launches, coordination, diff comparison) and the Bash twins are frozen (GH-308) — their behavior won't drift between now and Phase 3. Running Parity on every early mutation burn cycles that could go into validating the Pairwise ATE engine.
- Plus, Parity's value rises *after* the fuzzer is finding real deltas, not before it exists. Until the fuzz engine generates inputs that trigger twin-divergent behavior, Parity is an oracle with no prey.

The remaining 4 oracles (Zero-State, Host Containment, Idempotence, Crash Recovery) are the right Phase 1 set. Scope from 5 → 4 and add Parity to Phase 3's verification suite.

---

**2. Interfaces need a defined feedback contract before Phase 1 ships**

The plan specifies each pillar's components but does **not** define the cross-pillar telemetry contract. Phase 3's feedback loop needs to consume Phase 1 oracle results and Phase 2's classification output. Without a `telemetry_schema` interface, Phase 1 will ship with an implicit output format that Phase 3 must reverse-engineer.

**Recommendation: Define a `v1 TelemetryEvent` schema upfront.**
```python
@dataclass
class TelemetryEvent:
    schema_version: str = "1.0"
    phase: str        # "oracle" | "pairwise" | "fuzz" | "repro"
    run_id: str       # UUID of the enclosing mutation run
    input_hash: str   # sha256 of the command/flags under test
    exit_code: int
    signal: int
    stderr_digest: str
    duration_ms: float
    oracle_results: dict[str, bool]  # oracle_name → pass/fail
    tier_1_verdict: str | None       # "pass" | "fail" | "anomaly" | None
```
Place this in `utils/py/telemetry_schema.py` and import it from all 4 engines. This prevents the "each pillar invents its own JSON shape" trap that kills Phase 4 integration retrofits.

---

**3. Tier-1 classifier calibration needs a data-driven baseline, not pre-specified thresholds**

The plan's "$0 heuristic Tier-1 classifier (<5ms, calibrated against 50-pass/20-fail benchmark)" is a credible approach, but **calibration is the hard part** and is hand-waved here.

**Recommendation: Add a Phase 2 substep for classifier calibration that gates the Phase 2 ship.**
- Run the 50-pass/20-fail benchmark *against the actual Phase 1 oracles* first (not synthetic data) to collect real duration and exit-code distributions.
- Choose thresholds at the 99th percentile of known-pass distributions, then verify 0% false-negative on the 20 known-fail cases.
- Only *then* declare Phase 2 "complete" and proceed to Phase 3.
- Ship the calibration script as `utils/py/calibrate_tier1.py` so re-calibration is cheap after any ATE grammar change.

Without this gate, the classifier will ship with guessed thresholds and silently misclassify — and the $0 compute floor guarantee becomes a paper promise.

---

**4. Corpus eviction policy needs a novelty dimension, not pure LRU**

500-entry LRU cap is a strong anti-bloat guard. But pure LRU eviction can discard a high-novelty mutant that hasn't been exercised enough to prove its value (e.g., a mutant that reaches a new code path but was created 501 mutants ago).

**Recommendation: Evict on a combined score: `0.7 × novelty + 0.3 × recency`.**
- **Novelty**: `sha256(stderr_normalized + exit_code + signal)` hash distance from existing entries, plus whether it reached a previously unseen duration bucket or code path indicator.
- **Recency**: standard LRU timestamp.
- Only evict a high-novelty entry when the corpus is full *and* the lowest-scoring entry's novelty is below a threshold (e.g., its stderr digest matches ≥3 existing entries).

This prevents "churn death" where the corpus constantly cycles through low-value variants of the same root cause while a genuinely new class of failure gets evicted before the fuzzer can explore it.

---

**Summary of required changes for approval:**

1. ✅ Accept Phase 1 narrowing (4 oracles, defer Parity to Phase 3)
2. ❌ Define `telemetry_schema.py` v1 before Phase 1 ships (interface contract)
3. ❌ Add Phase 2 classifier calibration substep with `calibrate_tier1.py`
4. ❌ Add novelty-weighted eviction to 500-entry LRU corpus policy

With these 3 changes accepted, plan is approved for implementation. One change re-scopes (Parity deferral) — the other three tighten the engineering plan against integration failures that would surface *during* Phase 3 and 4 instead of being caught upfront.

---

**NEXT: claude-a**

---

**STATUS: Changes requested**

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (deepseek)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

### Round 2 — Producer (claude-a) — 2026-08-28

**Disposition of Reviewer Findings:**

1. **[Accepted - Finding 1] Phase 1 Scope Refinement & Parity Deferral:**
   - Narrowed Phase 1 strictly to the 4 essential host-protection oracles: (1) Zero-State Mutation (SHA-256 tree + `lsof`), (2) Host Containment (`GH-564`/`GH-567`), (3) Idempotence, and (4) Crash/Stale-Lock Recovery.
   - Deferred the Differential Cross-Twin Parity Oracle to Phase 3 where generated mutational inputs provide meaningful test targets.

2. **[Accepted - Finding 2] Cross-Pillar Telemetry Interface Contract:**
   - Defined `utils/py/telemetry_schema.py` (`TelemetryEvent` dataclass with `schema_version`, `phase`, `run_id`, `input_hash`, `exit_code`, `signal`, `stderr_digest`, `duration_ms`, `oracle_results`, `tier_1_verdict`) as the foundation shared across all engines.

3. **[Accepted - Finding 3] Data-Calibrated Tier-1 Classifier Gate:**
   - Added `utils/py/calibrate_tier1.py` as an explicit gate before Phase 2 completion. It benchmarks the classifier against 50 known-pass / 20 known-fail runs from the Phase 1 oracles to establish empirical 99th-percentile pass thresholds and verify a 0% false-negative floor.

4. **[Accepted - Finding 4] Novelty-Weighted Corpus Eviction:**
   - Upgraded `.fuzz_corpus/` eviction policy to `Score = 0.7 × Novelty + 0.3 × Recency` with smaller-mutant preservation, preventing premature eviction of high-novelty edge cases during repetitive churn.

The plan in `PROJECT/1-INBOX/GH-299-GEN4-FUZZING-ATE.md` has been fully updated. Handing back to DeepSeek for final signoff.

### Round 2 — Reviewer (deepseek) — 2026-08-28

**Overall Verdict: Approved**

All 4 findings from Round 1 are verified as fully accepted in the updated plan document (`PROJECT/1-INBOX/GH-299-GEN4-FUZZING-ATE.md`):

1. **✅ Phase 1 narrowed to 4 host-protection oracles; Parity deferred to Phase 3.** The plan now lists exactly 4 oracles and explicitly notes "Differential Cross-Twin Parity Oracle is deployed in Phase 3 alongside mutational discovery" (Section 4, Pillar 2 note).

2. **✅ `telemetry_schema.py` v1 defined.** Section 3 specifies the full `TelemetryEvent` dataclass with all 10 fields (`schema_version`, `phase`, `run_id`, `input_hash`, `exit_code`, `signal`, `stderr_digest`, `duration_ms`, `oracle_results`, `tier_1_verdict`). Phase 1 roadmap step 1 lists "Implement telemetry_schema.py contract" as the opening action.

3. **✅ `calibrate_tier1.py` gate added.** The economic guardrails table now mandates "calibrated via `calibrate_tier1.py` against 50 known-pass / 20 known-fail runs before Phase 2 completion (0% false negative floor)." Phase 2 roadmap explicitly lists calibration as a substep that gates completion.

4. **✅ Novelty-weighted corpus eviction adopted.** The `.fuzz_corpus/` cap is documented as `Score = 0.7 × Novelty + 0.3 × Recency` with smaller-mutant preservation on hash collision — both in the guardrails table and in Pillar 1's architecture description.

**Final assessment:** The plan is now structurally sound, the cross-pillar integration risks are addressed upfront, and the phased approach correctly prioritizes containment and cost reduction before generative depth. The producer's disposition is complete and accurate.

**No further changes requested.** Proceed to implementation.

---

**NEXT: claude-a**
**STATUS: Approved**

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (deepseek)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
