---
title: "GH-460 — ATE/Fuzz campaign vs the model-alias resolver: counterexamples must land as fixes"
status: Active
created: 2026-09-06
updated: 2026-09-06
owner: orchestrator (Claude Code)
gh_issue: 460
source: https://github.com/HiQS-Labs/XYZ-forge/issues/460
doc_type: plan
complexity: 2
risk: 2
effort: 4
phases: 1
revision: 1
ratings_provisional: false
rated: 60/40/50/70
recon: PROJECT/1-INBOX/recon-model-aliasing.md
related:
  - GH-457
  - GH-141
  - GH-299
  - GH-450
non_goals:
  - engine changes to utils/py/fuzz_engine.py — used as-is (GH-299)
  - new Bash files — the invariant oracle inlines into the --target string (GH-551)
  - tier-4 matcher semantics — #450 owns the matcher contract work
  - D1/D2/D3 defect fixes — #457 owns those; this loop feeds them
  - cache/latency work — #346
goal: >
  Make the Gen4 fuzz engine a standing oracle over resolve-model-alias.sh and
  model_alias.resolve_model_slug: a committed smoke test with a witnessed red control,
  seeded 500+-iteration campaigns with every counterexample dispositioned on #460
  (fix + pinned replayable regression test, or documented non-defect with the oracle
  narrowed), and zero untriaged counterexamples at close.
---

# GH-460 — ATE/Fuzz campaign vs the model-alias resolver

## Status

| What was just completed | What's next |
|---|---|
| Intake parked + rated (60/40/50/70); wiring demonstrated on 2026-09-05 (#457 comment, seed 7, 30/30 clean) | Codex plan QA, then items 1–3 below |

## Why this issue exists

The 2026-09-05 model-aliasing incident (#457, D1) showed the resolver's failure modes are
*semantic* (gateway-blind rewrite), but nothing continuously guards its *structural* contract
(exit codes ∈ {0,1,2}; stdout empty on miss; wrapper never raises/never empty). The Gen4 fuzz
engine (GH-299) is built for exactly this shape — pure function over argv — and was demonstrated
against the resolver on 2026-09-05 (#457, fuzzing comment): seed 7, 30 iterations, 30/30 clean.
#141 asks for exactly this kind of real adoption. This plan commits the smoke as a standing
test, runs real campaigns, and enforces the loop contract: **every counterexample → fix +
pinned replayable regression test, or documented non-defect with the oracle narrowed.**

## Recon summary (full map: `PROJECT/1-INBOX/recon-model-aliasing.md`, primary clone)

- `resolve-model-alias.sh` — pure function of (argv, static table) → (slug, rc 0|1|2); four
  matching tiers, file-order-wins; `MODEL_ALIASES_FILE` accepts pipes.
- `utils/py/model_alias.py` `resolve_model_slug` — never raises, never empty for non-empty
  input; caller literal is the floor; 10 s ceiling.
- Call sites: `deepseek-turn.py:231-235` (DEEPSEEK_MODEL), `review_xyz.py`; no other lane
  canonicalizes at runtime.
- Prior probes: tier-2 squash rewrite of bare ids (the #457 incident, fixed at HEAD
  `96c21555`); tier-4 substring over-match (`qwen`→`qwen/qwen3-coder`, `glm`→`z-ai/glm-5.2`).
- The fuzz engine: `--mode fuzz --target "<cmd> {mutant}"`, seeded PRNG, four mutator families,
  feedback-guided corpus, `--mode replay --id`, per-mutant process-group kill.

## Requirements

- **R1 (smoke, standing):** `test/gh460-fuzz-resolver-smoke.sh` runs the engine (pinned seed,
  ≥20 iterations) with the structural-contract oracle; asserts `executed ≥ 20` (an empty run is
  a failure — "an empty input passes every check") and `fail == 0`, `anomaly == 0`.
- **R2 (red control, witnessed):** with the resolver mutated to violate the contract
  (`exit 3` on miss — a cp-backup edit, restored after), the smoke test must go red. Witnessed
  in this effort's PR description, not asserted.
- **R3 (campaigns):** ≥3 seeds × ≥500 iterations against the resolver; plus the wrapper-floor
  campaign through `resolve_model_slug` (never-raises / never-empty / passthrough-on-miss).
  Every counterexample dispositioned on #460 per the loop contract.
- **R4 (defect routing):** defects already spec'd → #457; new defects → filed + fixed under
  #460 with corpus-derived regression tests.

## Non-goals

- No engine changes; no new Bash files (the oracle inlines into the `--target` string, GH-551);
  no tier-4 semantics changes (#450); no D1/D2/D3 fixes here (#457); no cache/latency (#346).

## Implementation order (one list, verification inline)

1. Write `test/gh460-fuzz-resolver-smoke.sh` (engine invocation, pinned seed 7, 20 iterations,
   invariant target from the #457 comment; assert `executed ≥ 20 && fail == 0 && anomaly == 0`).
   -> `bash test/gh460-fuzz-resolver-smoke.sh` exits 0 with the executed-count printed.
2. Witness the red control: cp the resolver to a backup, sed-inject `exit 3` on the miss path,
   run the smoke (expect exit ≠ 0), restore from the backup, re-run (expect green).
   -> red then green, both observed; noted in the PR.
3. Campaigns: 3 seeds × 500 iterations (resolver) + wrapper-floor campaign (≥300 iterations).
   -> engine summaries captured; counterexamples (if any) triaged on #460 before the PR.
4. Final Codex relay QA on the committed diff, then PR to `development`.

## Risks & rollback

- Risk: flaky fuzz failure in CI from a genuinely nondeterministic resolver (none known — the
  matcher is deterministic; replay from seed adjudicates). Rollback: revert the PR; the test
  file is self-contained and touches no other surface.
- The campaigns run in this task clone only; they spawn short-lived bash/python subprocesses
  and touch nothing under git control (corpus/telemetry under `temp/`, gitignored).
