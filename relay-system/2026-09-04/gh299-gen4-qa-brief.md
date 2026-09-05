# GH-299 Gen 4 ATE — QA brief for the reviewer (agy)

Branch: `feat/gh299-gen4-ate` (5 phase commits on top of `development`).
Plan of record: `PROJECT/2-WORKING/GH-299-GEN4-FUZZING-ATE.md` (read its Status + QA gates tables first).

## What landed (one module per phase, one suite per phase)

| Phase | Module | Suite | Claim to verify |
|---|---|---|---|
| 0 | `utils/py/telemetry_schema.py` | (embedded `--mode suite`) | one JSONL contract shared by every pillar; torn lines detected |
| 1 | `utils/py/domain_oracles.py` | `test/gh-gen4-phase1-domain-oracles.sh` | zero-state, host containment, idempotence, crash-recovery — each with a positive AND a negative control |
| 2 | `utils/py/adaptive_ate.py`, `utils/py/calibrate_tier1.py`, `utils/ate/tier1-calibration.json` | `test/gh-gen4-phase2-adaptive-ate.sh` | 12-flag grid → ≤200 cases, 100% valid 2-way coverage (independent brute-force walk); Tier-1 FN=0 on 50/20 benchmark; tier-2 never invoked on a clean run |
| 3 | `utils/py/fuzz_engine.py` | `test/gh-gen4-phase3-fuzz-engine.sh` | byte-identical seed replay; novelty-capped corpus; smaller-mutant-wins; parity oracle +/- controls; real twin run contained |
| 4 | `utils/py/repro_synth.py` (+ `repro_builder.py --mode synth`) | `test/gh-gen4-phase4-repro-synth.sh` | cluster-before-minimize: 50 same-cause rows → 1 suite; emitted suite passes while defect reproduces and FAILS after the fix |
| 5 | `utils/py/gen4_campaign.py` | `test/gh-gen4-phase5-campaign.sh` | bounded soak in a disposable clone: 0 contamination, host identity + tree unchanged; poison target caught and sandbox restored |

## How to verify (run these; do not trust the doc)

```bash
for m in telemetry_schema domain_oracles adaptive_ate fuzz_engine repro_synth gen4_campaign; do python3 utils/py/$m.py --mode suite | tail -1; done
python3 utils/py/calibrate_tier1.py --verify
for p in 1 2 3 4 5; do bash test/gh-gen4-phase$p-*.sh | tail -1; done
bash test/gh155-phase3-repro-builder.sh | tail -1      # Gen 3 minimizers must be untouched
```

## What to review hardest

1. **Negative controls are real, not vacuous.** For each oracle/classifier, confirm the "(-)" assertion would actually fail if the oracle were a no-op. Name any control that cannot fail.
2. **DRY against Gen 3.** `domain_oracles.py` must import `metamorphic_oracle` primitives, `repro_synth.py` must import `repro_builder` minimizers — flag any re-implementation.
3. **Host safety.** `check_host_containment` refuses a work root inside the host; `gen4_campaign.make_sandbox` refuses a sandbox inside the repo; `fuzz_engine.execute` kills the whole process group on timeout. Try to break each.
4. **Tier-1 honesty.** `calibrate_tier1.py` must exit 1 when FN=0 is unsatisfiable (the suite plants such a benchmark). Confirm the shipped calibration's `score.false_negatives == 0`.
5. **Registry.** All five suites appear in `validate.sh` TESTS and in `utils/ci-route.sh` `SUBSYSTEM_TESTS_ate`; `subsystem_of` maps the new modules to `ate`.
6. **What is NOT claimed.** The Phase-5 bar (>10,000 mutations, multi-hour) is recorded as owed in the doc and CHANGELOG. Confirm no sentence in the doc/CHANGELOG/PR claims it.

## Known findings already recorded (do not re-report; confirm they are recorded)
- 6/12 parity divergences between `codex-turn.sh` default and `XYZ_PYTHON=0` (doc Status row, CHANGELOG).
- `ci-route.sh` mutants classify 100% as Tier-1 *anomaly* (its error output is not usage-shaped) — a calibration gap for the soak triage.
- `validate.sh` removed from default campaign targets after a mutant ran the full gate inside the sandbox.

Verdict format: `APPROVE` or `CHANGES REQUESTED` with a numbered list — each item names a file:line and the exact command that demonstrates it.
