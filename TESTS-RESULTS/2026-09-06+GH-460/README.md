# GH-460 — ATE/Fuzz campaign evidence (2026-09-06)

Standing fuzz target for the model-alias resolver, per the plan
`PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md` (issue #460; oracle
`test/gh460-oracle.sh`, engine `utils/py/fuzz_engine.py`).

## Results (final oracle, commit b1b1d9b2)

| Run | Seed | Iterations | Result |
|---|---|---|---|
| smoke (`test/gh460-fuzz-resolver-smoke.sh`) | 7 | 20 | green — executed 20, fail 0, anomaly 0 |
| resolver campaign | 7 | 500 | green — executed 500, fail 0, anomaly 0 |
| resolver campaign | 8 | 500 | green — executed 500, fail 0, anomaly 0 |
| resolver campaign | 9 | 500 | green — executed 500, fail 0, anomaly 0 |
| wrapper-floor differential campaign | 11 | 300 | green — executed 300, fail 0, anomaly 0 |
| R2 witnesses (rc-3, LEAK, NEWLINE-ONLY-LEAK, HIT-EMPTY, MEASURE-FAIL failed-wc/split-digits/empty, padded-valid acceptance) | — | — | 24/24 assertions, each baseline → red → restored-green (`witnesses.log`) |

**1,820 fuzzed inputs, zero counterexamples; 8 negative-control/acceptance witnesses, all
attributable (baseline → red → restored-green).** Per the #460 loop contract a null campaign is
a valid result; the committed smoke remains as permanent coverage.

## Layout

- `seed{7,8,9}/`, `wrapper-seed11/` — summary.json + telemetry.jsonl per campaign.
- `wrapper-seed11-failed-attempt/` — preserved 300/300-failure adapter attempt (transcription
  error, dispositioned; NOT a resolver defect) per the loop contract's "never silently erase".
- `witnesses.log` — per-witness baseline/red/restored-green transcript.
- `provenance.jsonl` — one line per cited run; `replay.sh` — runnable campaign replay.

Environment: macOS (arm64), `LC_ALL=C`, `MODEL_ALIASES_FILE` unset, shipped alias table, fresh
empty corpus per run, `--timeout-budget 30`.
