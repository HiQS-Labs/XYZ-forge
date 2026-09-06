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

## Recon summary (full map committed on this branch: `PROJECT/1-INBOX/recon-model-aliasing.md`;
historical-incident evidence: commit `96c21555` on this branch removed the colliding alias —
the pre-fix rewrite reproduces by restoring that row)

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

- **R1 (smoke, standing):** `test/gh460-fuzz-resolver-smoke.sh` runs the engine (pinned seed 7,
  ≥20 iterations) with the oracle inlined verbatim (not delegated): the target is
  `bash -c 'out=$(bash relay-automation/resolve-model-alias.sh "$1" 2>/dev/null); rc=$?; [ $rc -le 2 ] || { echo "BADRC:$rc"; exit 9; }; [ $rc -ne 1 ] || [ -z "$out" ] || { echo "LEAK-STDOUT-ON-MISS"; exit 9; }; exit 0' _ {mutant}`
  from `--cwd <repo-root>` — resolver rc must be 0/1/2, stdout empty on miss, nonempty on hit.
  The test parses the engine's JSON summary (`fuzz_engine.py:339,470`), fails closed on
  missing/malformed JSON, and asserts `executed >= 20`, `counts.fail == 0`, `counts.anomaly == 0`
  (an empty run is a failure — "an empty input passes every check").
- **R1b (gate registration):** register the smoke in `validate.sh`'s TESTS list (next to
  `model-alias.sh`, ~line 102) so `ci-local.sh`'s qualifying suite derives it too
  (`ci-local.sh:246,269`). An unregistered test does not continuously guard.
- **R2 (red control, witnessed + attributable):** install the cp-backup FIRST
  (`cp resolve-model-alias.sh /tmp/...`, restored unconditionally before the smoke re-run, even
  on failure), then sed-inject `exit 3` on the terminal miss path (`resolve-model-alias.sh:124`,
  NOT the usage exit at `:52` or tier exits). Use a pinned input witnessed to MISS at HEAD
  (`totally-unknown-model-xyz`, as in `test/model-alias.sh`) so the mutant is the only variable;
  the smoke must go red with telemetry showing the oracle caught rc 3 for that input. A syntax
  error, timeout, or missing JSON does NOT qualify as the red witness. Use a fresh corpus dir for
  the red run (existing corpus state affects generation, `fuzz_engine.py:298`).
- **R3 (campaigns):** 3 seeds (pinned in the evidence dir) × ≥500 iterations against the
  resolver; plus the wrapper-floor campaign through `resolve_model_slug` (≥300 iterations,
  string model inputs + the fixed valid harness root only). Every counterexample dispositioned
  on #460 per the loop contract.
- **R3b (durable evidence):** commit `test/baselines/gh460-campaign/` containing per-campaign
  seeds, JSON summaries, telemetry JSONL, any regression inputs (exact argv + replay command),
  and `provenance.jsonl` for every run cited in the PR (AGENTS.md §6). Do not depend on
  ephemeral corpus ids — `fuzz_engine.py:185-190` replaces/evicts entries; regression success
  after a fix is asserted from the pinned input, not from replaying a surviving corpus id.
  Campaign evidence and cited-run provenance land in the PR.
- **R4 (defect routing):** defects already spec'd → #457; new defects → filed + fixed under
  #460 with corpus-derived regression tests.

## Non-goals

- No engine changes; no new *production* Bash — the oracle inlines into the `--target` string
  and `test/` files are exempt from the GH-551 rail; no tier-4 semantics changes (#450); no
  D1/D2/D3 fixes here (#457); no cache/latency (#346).
- Campaign scope bounded to string model inputs and the fixed valid harness root.
  Bycatch for #457: `model_alias.py:17`'s "never raises" docstring exceeds the implementation
  for invalid root types (`resolver_path` runs outside the try, `:31,44`) — a contract finding
  to route, not fuzz.

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
  and touch nothing under git control (corpus/telemetry under `temp/`, gitignored). Gate runs
  that execute the wider suite use a separate disposable full clone (AGENTS.md).
- Reversibility: **Easy** — test-only PR; rollback = revert (delete the test file + registry
  line + evidence dir). Ratings rationale: pri 60 (operator-directed; guards model selection
  that silently misrouted turns 2026-09-05), sev 40 (coverage for a consequence-bearing defect
  class; no direct data loss), appeal 50 (neutral), effort 70 (engine exists; small diff).
  Recurrence: one distinct incident in a 14-day lookback; no same-class reports found.
