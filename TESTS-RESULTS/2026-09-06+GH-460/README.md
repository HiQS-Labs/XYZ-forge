# GH-460 — ATE/Fuzz campaign evidence (2026-09-06)

Standing fuzz target for the model-alias resolver, per the plan
`PROJECT/2-WORKING/GH-460-ATE-FUZZ-RESOLVER-CAMPAIGN.md` (issue #460; oracle introduced by this
PR as `test/gh460-oracle.sh`, driven by `utils/py/fuzz_engine.py`).

## Results

| Run | Seed | Iterations | Result |
|---|---|---|---|
| smoke (`test/gh460-fuzz-resolver-smoke.sh`) | 7 | 20 | green — executed 20, fail 0, anomaly 0 |
| resolver campaign | 7 | 500 | green — executed 500, fail 0, anomaly 0 |
| resolver campaign | 8 | 500 | green — executed 500, fail 0, anomaly 0 |
| resolver campaign | 9 | 500 | green — executed 500, fail 0, anomaly 0 |
| wrapper-floor campaign (`model_alias.resolve_model_slug`, differential) | 11 | 300 | green — executed 300, fail 0, anomaly 0 |
| R2 mutation witnesses (rc-3, LEAK, NEWLINE-ONLY-LEAK, HIT-EMPTY, MEASURE-FAIL ×3, padded-valid) | — | — | 13/13, each baseline → red → restored-green (`witnesses.log`) |

**Zero counterexamples across 2,620 fuzzed inputs + 13 witnessed controls.** Per the #460 loop
contract, a null campaign is a valid result; the committed smoke remains as permanent coverage.

## Replay

Per-run summaries carry the full engine parameters. Resolver campaigns replay with:

    python3 utils/py/fuzz_engine.py --mode fuzz \
      --target 'bash test/gh460-oracle.sh {mutant}' --base "glm-5.2" --seed <7|8|9> \
      --iterations 500 --timeout-budget 30 --cwd <repo-root> \
      --corpus <fresh>/.fuzz_corpus --telemetry-out <fresh>/telemetry.jsonl --json

Environment: macOS (arm64), `LC_ALL=C`, `MODEL_ALIASES_FILE` unset, shipped alias table, fresh
empty corpus per run. Corpus directories are not committed (regenerable from seed+base under the
recorded environment; the engine's corpus evolution is seed-deterministic given that state).

## Provenance

`provenance.jsonl` — one line per cited run (timestamp, command, expected/actual exit, notes).
