# GH-712 — Offline Jev vs Tier-1 / Gemma ATE triage replay

Date: 2026-09-18 · Model: `jev-1.13.0` on every response (217/217) · Input tokens: 73,208 (benchmark) + 144,629 (error log) = 217,837 (~$0.009 at $0.042/Mtok) · Live runs, not mocks (`summary.json` → `"mock": false`) · Tool: `utils/py/jev_triage.py` at the commit that carries this directory.

## Decision

**Phase 2 gate missed on both counts → Phase 3 (the `--classifier` shadow flag) was not started.** No change to `run_variations.py`, `tier1_classify`, or the calibration file.

| Gate (plan §Ordered implementation 3) | Required | Observed | Met |
|---|---|---|---|
| Benchmark FN at argmax (24 known-fail rows) | 0 | **1** (4.17%) | no |
| GH-141 `status` agreement with Gemma | ≥ 90% | 100.0% (143/143) | yes |
| GH-141 `category` agreement with Gemma | ≥ 80% | **4.2%** (6/143) | no |
| GH-141 `severity` agreement (reported, not gating) | — | 48.95% (70/143) | n/a |

## Replay 1 — Tier-1 benchmark (`calibrate_tier1.py --emit-benchmark`, 74 rows: 50 pass / 24 fail)

| | Jev pass | Jev fail |
|---|---:|---:|
| label pass (50) | 50 | 0 |
| label fail (24) | **1** | 23 |

- FN = 1, FP = 0. `fn_zero_threshold` = **0.48**: the one missed row carried P(fail) = 0.48; every other known-fail row had P(fail) ≥ 0.48 and every known-pass row had P(fail) < 0.48, so a decision threshold of 0.48 would give FN = 0 and FP = 0. That is one number recorded per the plan, not a tuned threshold — the gate was defined at argmax and is missed.
- The missed row: `exit_code 0`, `stderr "Segmentation fault"`, 2,000 ms. Tier-1 calls it `anomaly` ("rc=0 but stderr looks like crash"). Jev: `status pass` with **confidence 0.05**, `category crash` (0.75), `severity none`. Jev saw the crash (category) but followed the zero exit code for status; the near-zero confidence is the model saying the two signals conflict. A confidence gate would have routed this row to review; the plan did not define one.
- Tier-1 agreement: 65 agree, 0 disagree, 9 Tier-1 `anomaly` rows (8 → Jev `fail`, 1 → Jev `pass`, the row above).
- Category on known-fail rows: crash 9, config_error 7, env_missing 3, env_failure 3, timeout 1, ok 1 (the missed row). Severity: critical 22, none 2 (the missed row and one other rc=0 row).

## Replay 2 — GH-141 error log (143 rows, all exit 2, all `edited: false`, `expects_edits: true`)

| Field | Agreement | Gemma → Jev pairs |
|---|---:|---|
| status | 143/143 (100%) | fail→fail 143 |
| severity | 70/143 (49%) | critical→critical 70, high→critical 73 |
| category | 6/143 (4.2%) | auth_failure→env_missing 103, auth_failure→config_error 23, config_error→env_missing 9, config_error→config_error 5, env_failure→config_error 2, env_missing→env_missing 1 |

What the disagreement is, read against the stderr in the log:

- Every row's stderr ends in `<shim>-turn: RELAY_AGENT required` — a missing required environment variable. Gemma labelled 126 of them `auth_failure`; Jev labelled 103 `env_missing` and 40 `config_error`. On inspection Jev's category is the literal one and Gemma's is not, so the 4.2% figure measures disagreement with a Gemma mislabel, not a Jev error. The plan's gate used Gemma as the reference because it was the only label available; this replay shows GH-141's Gemma categories are not a usable reference for that field. The gate is still missed as written.
- Severity: Jev answered `critical` on all 143 (non-zero exit, per the rule in the question). Gemma split the same failure 73 `high` / 70 `critical`. Jev is the consistent one; this is why severity was reported and not gated.
- Jev is not fully consistent on category either: of 7 distinct stderr tails, 3 received mixed `env_missing` / `config_error` answers across rows (the `command` differs per row, so inputs are not identical). Category confidence: min 0.34, median 0.53. Status confidence: 1.0 on every row.

## Caveats

- The benchmark is the harness's own synthetic 74-row corpus shaped like real failures, not field data; its labels are known by construction.
- GH-141 is homogeneous (one failure cause, 143 times), so agreement there is a consistency check, not a discrimination test — and its Gemma reference is itself wrong on category.
- Two live runs, one model version, no prompt iteration after the first request. Question wording is frozen in `utils/py/jev_triage.py` at this commit.
- `rows.jsonl` carries verdicts, confidence, model, and request/response sha256 per row — no stderr text, no key.

## What would change the decision (operator call, not taken here)

1. Re-gate the benchmark with a recorded decision threshold (0.48) or a confidence floor (route status confidence < 0.5 to Tier-1's `anomaly` path) — 2 of 74 rows had status confidence < 0.5, both the conflicting-signal kind.
2. Replace the GH-141 category reference with a hand-labelled sample before re-measuring category agreement; the current reference cannot be met by a correct classifier.

Both are new decisions with their own gates; neither is implied by this result.
