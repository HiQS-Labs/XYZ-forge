---
title: "GH-712: Offline Jev vs Tier-1/Gemma ATE triage replay, then a gated --classifier shadow flag"
status: Active
created: 2026-09-18
updated: 2026-09-18
owner: Claude Code (start-task)
goal: measure whether TypeSafe Jev can replace the local Gemma classifier for the three structured ATE triage fields, offline first, and add a default-off shadow flag only if the replays are clean
gh_issue: 712
source: https://github.com/HiQS-Labs/XYZ-forge/issues/712
doc_type: project
context_tags: [ate, gen4, classifier, typesafe-jev]
non_goals:
  - any change to the $0 Tier-1 classifier, its calibration file, or the FN floor
  - Gen 4 telemetry changes (stderr_digest only; Tier-2 over anomaly rows is Lane C in GH-709)
  - a new runner, daemon, SDK dependency, or live ATE run in this issue
effort: 2
complexity: 2
risk: 1
phases: 3
---

# GH-712 — Offline Jev vs Tier-1/Gemma ATE triage replay

Lane B of [GH-709](https://github.com/HiQS-Labs/XYZ-forge/issues/709). Issue: [GH-712](https://github.com/HiQS-Labs/XYZ-forge/issues/712).

## Status

| What was just completed | What's next |
|---|---|
| Plan approved r2 (agy). Phase 1 landed (`utils/py/jev_triage.py`, `test/gh712-jev-triage.sh` 16/16). Phase 2 live replays done: benchmark FN = 1 of 24 (gate missed), GH-141 status 100% / category 4.2% (gate missed against a Gemma reference that is itself wrong on inspection). Phase 3 not started. | Final relay QA on the committed diff + evidence → full `./validate.sh` once in a disposable clone → push through the gate → PR to `development` with the negative result. Any re-gate (threshold 0.48, confidence floor, hand-labelled category reference) is a separate operator decision. |

## QA gates

| Phase | Gate | Evidence |
|---|---|---|
| 1 | `bash test/gh712-jev-triage.sh` green with a mocked endpoint: green control (every canned answer matches its label → FN = 0, FP = 0, floor met), red control (the same fixture with one known-fail answered `pass` → FN = 1, floor not met), empty benchmark refused (exit 2), rows carry `model` + 64-hex hashes and no stderr text, severity/category agreement counted per row | 16/16 on 2026-09-18 (commit `8ef27a2a`) |
| 2 | `TESTS-RESULTS/2026-09-18+GH-712/SUMMARY.md`: benchmark FN = 0 on 24 known-fail rows at argmax + recorded `fn_zero_threshold`; GH-141 agreement ≥ 90% status and ≥ 80% category (severity reported, not gating); homogeneity caveat; model pinned `jev-1.13.0`; token totals; hashes | **Missed** 2026-09-18: FN = 1 (`fn_zero_threshold` 0.48; the rc=0 `Segmentation fault` row, status confidence 0.05); status 100%, category 4.2% (Gemma's `auth_failure` vs Jev's `env_missing` on `RELAY_AGENT required` — Gemma's reference is wrong on inspection), severity 49%. [SUMMARY](../../TESTS-RESULTS/2026-09-18+GH-712/SUMMARY.md) |
| 3 | `bash test/ate-run-variations.sh` green; `--classifier gemma` (default) produces the same `classification` keys as before; `--classifier jev` exercised by the Phase 1 test via the mock, never live in CI | **Not started** — Phase 2 gate missed; `run_variations.py` untouched |

## Observed problem

`utils/ate/scripts/run_variations.py` triages every variation with a local Gemma in LM Studio (`ask_gemma`, `CLASSIFY_PROMPT` → `{status, severity, category, likely_cause}`). That ties ATE to a running LM Studio and a 31B model; the 2026-08-22 soak also showed prompt-rule fragility (17 false HIGH `no_edit` verdicts, fixed by `expects_edits`). Three of the four fields are closed-set decisions. The operator asked whether Jev, a typed decision API, gives the same verdicts offline before anyone touches the live loop.

## Recon (base `origin/development` `ea5c8e40`, clone `XYZ-forge-gh712-jev-triage`, branch `feat/gh712-jev-ate-triage`)

- Classify seam: `run_variations.py:488-507` — `args.mock_classifier or not args.lmstudio_model` → deterministic mock dict; else `CLASSIFY_PROMPT.format(...)` with 1,500-char stdout/stderr tails → `ask_gemma()` → dict written as `classification` on the `error_log.jsonl` row. `--mock-classifier` is the existing pluggable seam; the flag lands beside it.
- Tier-1: `utils/py/adaptive_ate.py:317 tier1_classify(exit_code, signal, stderr, duration_ms, thresholds) -> (verdict, reason)`, verdict ∈ pass|fail|anomaly. `utils/py/calibrate_tier1.py:103 score(rows, thresholds)` defines FN (label fail → verdict pass) and FP (label pass → verdict fail); `--verify` exits 1 on any FN. `--emit-benchmark FILE` writes 74 rows `{label, exit_code, signal, stderr, duration_ms}`.
- GH-141 log: `TESTS-RESULTS/2026-08-22+GH-141/error_log.jsonl`, 143 rows with `command, exit_code (all 2), edited (all False), stdout, stderr, classification{status,severity,category,likely_cause}`; Gemma: 126 `auth_failure` / 14 `config_error` / 2 `env_failure` / 1 `env_missing`, 73 high / 70 critical, all `fail`.
- Gen 4 telemetry (`telemetry_schema.py`) keeps `stderr_digest`, not text → out of scope here (Lane C).
- Jev contract, verified live 2026-09-18: `POST https://api.typesafe.ai/v1/systemone`, `{state, model, questions}`; Choice → `choice, probabilities, confidence`; Score → `score, legend, confidence`; response `model` versioned; `usage.input_tokens`. `requests` is already a documented dependency of `run_variations.py` (`pip install requests pyyaml`), so the module reuses it; `utils/py/` scripts otherwise use stdlib only, so the module falls back to `urllib` when `requests` is absent.
- Tests: bash suites `test/gh<N>-*.sh` with `PASS/FAIL` counters and `lib/fixture-guard.sh`; `test/ate-run-variations.sh` covers the runner; `./validate.sh --tier 2 --subsystem ate`-style focused runs exist.

## Requirements

1. `utils/py/jev_triage.py`: `build_questions(expects_edits)` — three **Choice** questions: status pass/fail; severity none/low/medium/high/critical (Choice, not Score, so agreement compares exact labels — QA r1 nit); category crash/auth_failure/bad_diff/timeout/no_edit/config_error/env_failure/env_missing/ok (the union of the prompt's examples and every value Gemma emitted in GH-141 — QA r1). `build_state(row)` (command, exit_code, signal, edit_applied, expects_edits, 1,500-char tails — same tails as the Gemma prompt). `Client.classify(state, expects_edits) -> dict` returning the Gemma-shaped dict with `likely_cause=None` plus `classifier="jev"`, `model`, per-field `confidence` and `probabilities`, request/response sha256. Stdlib `urllib` only (no `requests`, no dual path — QA r1); key from `TYPESAFE_API_KEY` or `--key-file`; endpoint override `TYPESAFE_API_URL`. Retry: at most 3 attempts on 429/5xx, sleeping `retry-after` when present else 2 s, then raise. The mock is `--mock-responses FILE`, a JSON list of canned response bodies replayed in order (QA r1).
2. CLI replays: `jev_triage.py benchmark --rows FILE --out DIR` → confusion vs label at argmax, FN, FP, agreement with `tier1_classify` (anomaly rows listed), **and** `fn_zero_threshold` = the minimum P(fail) Jev assigned to any known-fail row (the highest decision threshold at which FN = 0) with the FP count at that threshold — one recorded number, no calibration subsystem (QA r1). `jev_triage.py errorlog --log FILE --out DIR` → per-field agreement with the row's existing `classification` plus the Gemma→Jev pair counts. Both write `<out>/rows.jsonl` (index/run_id, verdicts, confidence, request/response sha256; never stderr text) and `<out>/summary.json`; empty input exits 2.
3. Phase 3 (conditional): `run_variations.py --classifier {gemma,jev}` default `gemma`; `jev` path calls `jev_triage.classify` and stores `classifier`/`model` on the row; the `gemma` path is untouched byte-for-byte except reading the new arg.

## Non-goals

- Changing `tier1_classify`, its calibration JSON, or the FN floor; changing `CLASSIFY_PROMPT`; any Gen 4 file.
- A live ATE run, LM Studio, or a soak in this issue.
- A TypeSafe SDK, `requests`, a queue, or any retry beyond the three-attempt loop.
- Replacing `likely_cause`; Jev cannot generate it.

## Smallest affected surface

- New: `utils/py/jev_triage.py` (~220 lines), `test/gh712-jev-triage.sh` (~120 lines, mock only), `test/fixtures/gh712/` (6 benchmark-shaped rows + 4 error-log rows + canned responses), `TESTS-RESULTS/2026-09-18+GH-712/`.
- Phase 3 only: `utils/ate/scripts/run_variations.py` (+1 arg, +1 branch at the classify seam, ~15 lines) and `skills/ate/SKILL.md` (one paragraph naming the flag).
- Touched: this doc, `CHANGELOG.md` at iteration end.

## Dependencies and risks

- Key: the operator's local secrets file, passed as `--key-file` or `TYPESAFE_API_KEY`; never committed or logged. Risk: dynamic rate limits → backoff; a failed replay is reported as failed, never partially summarized.
- Phase 3 depends on Phase 2's FN = 0 gate. If it fails, Phase 3 is recorded as not started and the issue closes with the offline evidence only.
- Rollback: delete the new files; Phase 3's diff is one arg and one branch.

## Ordered implementation

1. Phase 1: write `jev_triage.py` + fixtures + `test/gh712-jev-triage.sh`; run it → green; red control (fixture known-fail with canned `pass`) → FN = 1 and test asserts it.
2. Phase 2: emit the 74-row benchmark to `$TMPDIR`; live `benchmark` replay → `TESTS-RESULTS/2026-09-18+GH-712/benchmark/`; live `errorlog` replay on GH-141 → `.../errorlog/`; write `SUMMARY.md`.
3. Gate (concrete, QA r1): benchmark FN = 0 on the 24 known-fail rows at argmax; GH-141 agreement with Gemma ≥ 90% on `status` and ≥ 80% on `category`. Severity agreement is reported but does not gate: Gemma itself split 126 identical auth failures 73 high / 70 critical, so its severity labels are not a consistent reference. If any gating number is missed: stop after step 2, record it here and on the issue, Phase 3 not started.
4. Phase 3 (conditional): `--classifier` flag; extend `test/gh712-jev-triage.sh` with a mocked `run_variations.py --classifier jev --mock…` row check; `bash test/ate-run-variations.sh` green.
5. Focused checks during iteration: `bash test/gh712-jev-triage.sh`, `bash test/ate-run-variations.sh`. Full gate once on the final commit: `./validate.sh` from a separate disposable clone.
6. Final Codex relay QA; `CHANGELOG.md`; push through the pre-push gate; PR to `development`.

## Acceptance checks

- `bash test/gh712-jev-triage.sh` fails on: empty benchmark accepted, FN ≠ 0 on the green control, FN ≠ 1 on the red control, a response missing `model`, hashes absent from `rows.jsonl`, or stderr text present in `rows.jsonl`.
- `SUMMARY.md` states FN/FP/anomaly-agreement for the benchmark, per-field agreement for GH-141 with the homogeneity caveat, `jev-1.13.0` on every row, total input tokens, and the Phase 3 decision.
- Phase 3 (if landed): `test/ate-run-variations.sh` green; a mocked `--classifier jev` run writes `classifier: "jev"` and `likely_cause: null` on the row; default run unchanged.
