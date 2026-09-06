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
  - new production Bash — the invariant oracle inlines into the --target string; test/ files are GH-551-exempt
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
- Call sites (inspected): `deepseek-turn.py:231-233` (DEEPSEEK_MODEL canonicalization;
  provider validated earlier at `:200-203`), `review_xyz.py:629,85`. No other lane is known to
  canonicalize at runtime among the inspected shims (codex/agy/commandcode/pi take model ids
  verbatim); any wrapper change must re-verify callers.
- Prior probes (dated producer observations, 2026-09-05): tier-2 squash rewrite of bare ids
  (the #457 incident; mitigated by removing the colliding row, commit `96c21555` — the tier-2
  matcher at `resolve-model-alias.sh:97-104` is unchanged, so a future colliding row re-arms it);
  tier-4 substring over-match (`qwen`→`qwen/qwen3-coder`, `glm`→`z-ai/glm-5.2`).
- The fuzz engine: `--mode fuzz --target "<cmd> {mutant}"`, seeded PRNG, four mutator families,
  feedback-guided corpus, `--mode replay --id`, per-mutant process-group kill.

## Requirements (behavior contracts; executable syntax lives in `test/gh460-oracle.sh` — the one runnable source, per the round-6 disposition)

**The oracle script** (`test/gh460-oracle.sh`, GH-551 test/-exempt; invoked as
`fuzz_engine.py --target 'bash test/gh460-oracle.sh {mutant}'` from `--cwd <repo-root>`):

- **O1** `unset MODEL_ALIASES_FILE`; mktemp capture file with `SETUP-FAIL` guard (exit 8) and an
  EXIT-trap cleanup (captures may also live in the runner-owned per-run directory, which the
  engine's SIGKILL on timeout cannot be relied on to clean — `fuzz_engine.py:247-254,265-270`).
- **O2** runs `relay-automation/resolve-model-alias.sh "$1"` capturing stdout byte-exactly to
  the temp file (never command substitution — it strips newline-only leaks); stderr passes through.
- **O3** fail-closed measurement: resolver rc captured; `wc -c` rc checked; raw wc output
  validated as optional surrounding whitespace around exactly one decimal integer (macOS pads —
  `/usr/bin/wc -c </dev/null` yields `       0`); any violation emits `MEASURE-FAIL` (exit 8).
- **O4** invariants: rc outside 0/1/2 → `BADRC:<rc>` (exit 9); miss with stdout bytes →
  `LEAK-STDOUT-ON-MISS` (exit 9); hit with empty stdout → `HIT-EMPTY-ON-MATCH` (exit 9);
  otherwise exit 0.

**The smoke test** (`test/gh460-fuzz-resolver-smoke.sh`, registered in `validate.sh`'s TESTS list
next to `model-alias.sh` so `ci-local.sh:269` derives it):

- **R1** runs the engine: seed 7, ≥20 iterations, `--base "glm-5.2"`, `--timeout-budget 30`,
  `--json` (REQUIRED — human summary otherwise, `fuzz_engine.py:466-469`), `LC_ALL=C`, fresh
  corpus + summary/telemetry paths per run. Parses the JSON summary fail-closed (missing/malformed
  = failure) and asserts `executed >= 20`, `counts.fail == 0`, `counts.anomaly == 0`.
- **R1-pre (environment pins, EXACT observed values):** a known hit `glm-5.2` observes rc 0 with
  nonempty output; an observed miss `totally-unknown-model-xyz` observes rc 1 with zero output
  bytes (invoking the resolver directly, not only through the oracle — the oracle also accepts
  rc 2, so an all-rc-2 environment must fail here); both must pass the oracle too. Plus wrapper
  mapping checks: `glm-5.2` → `z-ai/glm-5.2`; `deepseek v4 pro` → `deepseek/deepseek-v4-pro`;
  observed-miss input → identity; empty input → identity (through
  `model_alias.resolve_model_slug`, reusing the resolver as its own differential reference).

**R2 (red control + negative-control witnesses, witnessed once in this effort, evidence in
`test/baselines/gh460-campaign/`):** with a cp-backup + trap-restored resolver copy, each
mutation is exercised through the direct oracle on a pinned input and must produce the exact
stderr diagnostic + oracle exit, then restore to green: (a) terminal miss `exit 1` → `exit 3`
(`resolve-model-alias.sh:128` only) → `BADRC:3`; (b) terminal miss → `printf 'LEAK\n'; exit 1`
→ `LEAK-STDOUT-ON-MISS` (catches regression to command substitution — a bare `printf '\n'`
newline-only variant is caught by byte counting, not substitution); (c) tier hit
`printf '%s\n' "${canonicals[$i]}"` → no-output → `HIT-EMPTY-ON-MATCH`; (d) a PATH-shim `wc`
exiting 1 → `MEASURE-FAIL`. An unrelated failure is not a witness; fresh corpus dir per run
(`fuzz_engine.py:298`).

**R3 (campaigns):** 3 seeds {7,8,9} × ≥500 iterations (resolver oracle) + wrapper-floor campaign
seed 11 × ≥300 through `model_alias.resolve_model_slug` (string inputs + fixed valid root;
wrapper output must equal the resolver-derived expectation per iteration — resolver invoked as
the observation, never a second matcher). Green per run: engine exit 0 AND nonempty valid JSON
summary AND `executed >= <floor>` with `counts.fail == 0`, `counts.anomaly == 0`. Fresh corpus +
paths per run; `LC_ALL=C`; unset `MODEL_ALIASES_FILE`.

**R3b (evidence):** `test/baselines/gh460-campaign/` commits seeds, JSON summaries, telemetry
JSONL, target/base/timeout/environment identity, regression inputs + replay commands, and
`provenance.jsonl` for every run cited (AGENTS.md §6) — including baseline/red/restored-green.

**R4 (defect routing):** spec'd defects → #457; new defects → filed + fixed here with
corpus-derived regression tests. Any runtime (production) fix is separately scoped, rated, and
rollback-analyzed before implementation — this PR's test-only rating covers smoke/registry/
evidence only.


## Implementation order (one list, verification inline)

1. Write `test/gh460-oracle.sh` (O1–O4) and `test/gh460-fuzz-resolver-smoke.sh` (R1 + R1-pre);
   register the smoke in `validate.sh`'s TESTS list (R1b line next to `model-alias.sh`).
   -> `bash test/gh460-fuzz-resolver-smoke.sh` exits 0 printing the executed count;
   `grep gh460 validate.sh` shows the registration.
2. Witness R2: run the four mutation witnesses (each cp-backed/trap-restored, exact diagnostic,
   restored green). -> all four observed; evidence files land in `test/baselines/gh460-campaign/`.
3. Campaigns (R3): resolver seeds 7/8/9 × 500 + wrapper seed 11 × 300, green criteria as specified.
   -> summaries + telemetry + provenance committed under `test/baselines/gh460-campaign/`;
   counterexamples (if any) triaged on #460 before the PR.
4. Final Codex relay QA on the committed implementation; PR to `development`.

## Risks & rollback

- Risk: a campaign counterexample reveals a real resolver defect → that is the loop working;
  triage per the loop contract on #460 (fix + pinned regression test under #457/#460 routing).
- Risk: flaky smoke in CI → the matcher is deterministic; replay from seed adjudicates; a
  genuinely nondeterministic resolver is itself a finding.
- Rollback: **Easy** — revert the PR (delete the two test files, registry line, evidence dir).
- Ratings rationale: pri 60 (operator-directed; guards model selection that silently misrouted
  turns 2026-09-05), sev 40 (coverage for a consequence-bearing defect class; no direct data
  loss), appeal 50 (neutral), effort 70 (engine exists; small diff). Recurrence: one distinct
  incident in a 14-day lookback; no same-class reports found.
