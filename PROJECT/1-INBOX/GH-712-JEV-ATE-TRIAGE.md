---
title: "GH-712: Offline Jev vs Tier-1/Gemma ATE triage replay, then a gated --classifier shadow flag"
status: Proposed (1-INBOX — not yet active)
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

Capture of [GH-712](https://github.com/HiQS-Labs/XYZ-forge/issues/712), Lane B of the
[GH-709 umbrella](https://github.com/HiQS-Labs/XYZ-forge/issues/709). The issue body is the
canonical ask; this doc is the in-repo pointer and execution surface once promoted.

## Ask (from the issue)

1. Benchmark replay: `calibrate_tier1.py --emit-benchmark` (74 rows, 50 pass / 24 fail) through
   Jev as a pass/fail Choice; confusion vs label under the same 0% false-negative floor Tier-1 holds;
   Jev vs `tier1_classify` agreement with Tier-1 `anomaly` rows listed separately.
2. GH-141 log replay: `TESTS-RESULTS/2026-08-22+GH-141/error_log.jsonl` (143 rows) — agreement with
   Gemma per field (`status`, `severity`, `category`); homogeneous set, consistency only.
3. Shadow flag `--classifier {gemma,jev}` (default `gemma`) on `run_variations.py` — only if 1 has
   FN = 0 and 2 shows no systematic disagreement; exercised by a mocked-endpoint test, no live run.

## Acceptance

- `bash test/gh712-jev-triage.sh` green: mocked replay reproduces FN/FP/agreement math, rejects an
  empty benchmark, red control (known-fail forced to `pass`) counts FN = 1.
- `TESTS-RESULTS/2026-09-18+GH-712/SUMMARY.md` with both tables, pinned model ID, token totals,
  request/response hashes; no secrets, no raw stderr beyond what the public log already holds.
- If step 3 lands: `--classifier gemma` log schema unchanged; `test/ate-run-variations.sh` green.

## Rating rationale (2026-09-18)

`rated 55/25/50/70` — pri 55: operator-requested, informs whether ATE can drop the LM Studio
dependency; sev 25: no defect, nothing breaks if skipped; appeal 50 neutral (no operator preference);
effort 70: one module + one test + a guarded flag. Recurrence: n/a (experiment). Uncertainty: rate
limits are dynamic; a 429 storm would slow but not invalidate the replay.
