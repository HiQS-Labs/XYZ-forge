# RELAY · GH-712 Jev ATE triage plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-18.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh712-codex-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **GH-712-JEV-ATE-TRIAGE.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-18

### Artifact — GH-712-JEV-ATE-TRIAGE.md
```
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
| Intake parked + rated 55/25/50/70; promoted; recon of the Tier-1 classifier, the Gemma classify seam and both replay datasets done; plan drafted. | Codex relay plan QA → Phase 1 module + test → Phase 2 live replays → Phase 3 shadow flag only if gates pass → final QA → PR to `development`. |

## QA gates

| Phase | Gate | Evidence |
|---|---|---|
| 1 | `bash test/gh712-jev-triage.sh` green with a mocked endpoint: FN/FP/agreement math on a fixture, empty benchmark refused (exit ≠ 0), red control (known-fail forced `pass`) counted as FN = 1 | pending |
| 2 | `TESTS-RESULTS/2026-09-18+GH-712/SUMMARY.md`: benchmark replay FN = 0 on 24 known-fail rows (else Phase 3 does not start); GH-141 agreement table per field with the homogeneity caveat; model pinned `jev-1.13.0`; token totals; hashes | pending |
| 3 | `bash test/ate-run-variations.sh` green; `--classifier gemma` (default) produces the same `classification` keys as before; `--classifier jev` exercised by the Phase 1 test via the mock, never live in CI | pending / conditional |

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

1. `utils/py/jev_triage.py`: `build_questions(expects_edits)` (status Choice pass/fail, severity Score none/low/medium/high/critical, category Choice crash/auth_failure/bad_diff/timeout/no_edit/config_error/env_failure/ok — the category set is the union of the prompt's examples and what Gemma actually emitted in GH-141), `build_state(row)` (command, exit_code, edit_applied, expects_edits, 1,500-char tails — same tails as the Gemma prompt), `classify(state, *, endpoint, key, model="jev-1.13.0") -> dict` returning the Gemma-shaped dict with `likely_cause=None` plus `classifier="jev"`, `model`, `confidence`, `probabilities`, `usage`. Endpoint and key come from `TYPESAFE_API_URL` / `TYPESAFE_API_KEY` or `--key-file`; the mock is `--mock-dir DIR` returning canned JSON per request hash (no network). Retries on 429/5xx with backoff honoring `retry-after`, 5 attempts, then raise.
2. CLI replays: `jev_triage.py benchmark --rows FILE --out DIR` → confusion vs label, FN, FP, and agreement with `tier1_classify` (anomaly rows listed); `jev_triage.py errorlog --log FILE --out DIR` → per-field agreement with the row's existing `classification`. Both write `<out>/rows.jsonl` (index/run_id, verdicts, confidence, request/response sha256) and `<out>/summary.json`; empty input exits 2.
3. Phase 3 (conditional): `run_variations.py --classifier {gemma,jev}` default `gemma`; `jev` path calls `jev_triage.classify` and stores `classifier`/`model` on the row; the `gemma` path is untouched byte-for-byte except reading the new arg.

## Non-goals

- Changing `tier1_classify`, its calibration JSON, or the FN floor; changing `CLASSIFY_PROMPT`; any Gen 4 file.
- A live ATE run, LM Studio, or a soak in this issue.
- A TypeSafe SDK, a queue, or a retry framework beyond the five-attempt loop.
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
3. Gate: FN = 0 on 24 known-fail rows and no per-field systematic disagreement that the operator would reject (report it either way). If not met: stop after step 2, record it here and on the issue.
4. Phase 3 (conditional): `--classifier` flag; extend `test/gh712-jev-triage.sh` with a mocked `run_variations.py --classifier jev --mock…` row check; `bash test/ate-run-variations.sh` green.
5. Focused checks during iteration: `bash test/gh712-jev-triage.sh`, `bash test/ate-run-variations.sh`. Full gate once on the final commit: `./validate.sh` from a separate disposable clone.
6. Final Codex relay QA; `CHANGELOG.md`; push through the pre-push gate; PR to `development`.

## Acceptance checks

- `bash test/gh712-jev-triage.sh` fails on: empty benchmark accepted, FN math wrong on the red-control fixture, mock responses missing a `model` field, or hashes absent from `rows.jsonl`.
- `SUMMARY.md` states FN/FP/anomaly-agreement for the benchmark, per-field agreement for GH-141 with the homogeneity caveat, `jev-1.13.0` on every row, total input tokens, and the Phase 3 decision.
- Phase 3 (if landed): `test/ate-run-variations.sh` green; a mocked `--classifier jev` run writes `classifier: "jev"` and `likely_cause: null` on the row; default run unchanged.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Definition of Done and review questions (Reviewer: answer every numbered item)

**Goal.** Pre-implementation QA of the GH-712 plan (embedded above). No code exists yet; you are grading the plan, its recon claims, and its acceptance checks.

**Operational envelope.** One local developer CLI module (`utils/py/jev_triage.py`, ~220 lines), one bash test with a canned-response mock (no network in CI), a results directory, and — only if Phase 2's FN = 0 gate passes — a default-off `--classifier` flag beside the existing `--mock-classifier` seam in `utils/ate/scripts/run_variations.py`. Grade against this envelope and the repo's commensurate-complexity standard. Do not ask for retry frameworks, queues, SDKs, multi-tenant threat models, or a live soak.

**Read in the worktree (read-only):** the embedded plan; `utils/py/adaptive_ate.py` (`tier1_classify`, ~line 317); `utils/py/calibrate_tier1.py` (`score`, ~line 103; `--emit-benchmark`); `utils/ate/scripts/run_variations.py` lines 50–136 (`CLASSIFY_PROMPT`, `ask_gemma`) and 480–510 (classify seam); `test/ate-run-variations.sh`; the first 3 rows of `TESTS-RESULTS/2026-08-22+GH-141/error_log.jsonl`; `skills/ate/SKILL.md` architecture section.

**Questions.**

1. Recon grounding: do the cited line ranges and behaviours (`tier1_classify` verdict set, `score()` FN/FP definitions, the `mock_classifier or not lmstudio_model` branch, the 1,500-char tails, the GH-141 row shape) match the code? Cite `file:line` for each confirmation or disagreement.
2. Extends, not duplicates: does Phase 3 route through the existing `classification` dict and log writer, or does it introduce a second write path? Is `likely_cause=None` on the Jev path acceptable for `compile_issue.py` consumers (check how `compile_issue.py` reads `likely_cause`)?
3. FN floor for a probabilistic classifier: the plan scores Jev's pass/fail Choice at argmax and requires FN = 0 on the 24 known-fail rows. Is argmax the right decision rule, or should the plan also record the probability threshold at which FN reaches 0? Do not propose a calibration subsystem; one recorded number is the ceiling.
4. Category set: the plan uses crash / auth_failure / bad_diff / timeout / no_edit / config_error / env_failure / ok (prompt examples ∪ Gemma's GH-141 output). Gemma also emitted `env_missing` once. Should the set be exactly Gemma's observed vocabulary, the prompt's, or the union, for the agreement metric to be honest?
5. Severity as a Score with legend none/low/medium/high/critical: is comparing Jev's `score` (rounded to the nearest level) against Gemma's string label a fair agreement metric? Name any better one-line alternative.
6. Mock design: `--mock-dir` keyed by request sha256 vs a simpler ordered `--mock-responses FILE`. Which is commensurate with a ~120-line bash test? Pick one.
7. Acceptance checks: does `test/gh712-jev-triage.sh` as described detect the actual failures (empty input accepted, wrong FN math, missing `model`, missing hashes)? Is the red control (known-fail with canned `pass` → FN = 1) sufficient? Anything missing that would let a broken scorer pass?
8. Phase 3 gate: "no systematic disagreement the operator would not accept" is not falsifiable. Propose one concrete threshold for the GH-141 agreement (per field) that gates Phase 3, given the set is all-failure and Gemma's own labels are not ground truth.
9. Secrets and publication: can anything in `TESTS-RESULTS/2026-09-18+GH-712/` leak the key or add text not already public in the GH-141 log? Is `rows.jsonl` with hashes + verdicts (no stderr) the right level?
10. Rating: is `rated 55/25/50/70` grounded (appeal must stay 50 unless the operator set it; effort scores cheapness)?
11. Over/under-engineering: name anything in the plan that is machinery beyond the envelope, and anything the envelope needs that the plan omits.

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix and a `file:line` or quoted-span citation; every behaviour-change request carries `Observed input:` / `Affected scope:` / `Falsifier:`. Then a Verdict. `swept file: yes|no` line required.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
