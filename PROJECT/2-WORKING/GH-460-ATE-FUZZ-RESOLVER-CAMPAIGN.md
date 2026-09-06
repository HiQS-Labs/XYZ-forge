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
  - new production Bash — the invariant oracle is a committed test/gh460-oracle.sh; test/ files are GH-551-exempt
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

## Requirements (behavior contracts; executable syntax lives in `test/gh460-oracle.sh` — the one runnable source)

**Shared run contract (applies to the smoke and BOTH campaigns):** fuzz mode with `--base "glm-5.2"`,
`--cwd <repo-root>`, `--timeout-budget 30`, `--json` with summary redirected to a file (REQUIRED —
the engine prints a human summary without it, `fuzz_engine.py:466-469`), fresh EMPTY corpus and
telemetry/summary paths per run, shipped alias table with `MODEL_ALIASES_FILE` unset,
`LC_ALL=C`. Green per run: engine exit 0 AND a nonempty valid JSON summary (fail-closed on
missing/malformed) AND parsed `executed >= <floor>` with `counts.fail == 0`,
`counts.anomaly == 0` (exit status alone is insufficient — `fuzz_engine.py:330-335,470`).
The environment policy (unset override, shipped table, locale) applies to raw preconditions and
wrapper observations too, not only inside the oracle.

**The oracle script** (`test/gh460-oracle.sh`, GH-551 test/-exempt; invoked as
`fuzz_engine.py --target 'bash test/gh460-oracle.sh {mutant}'` from the shared-run `--cwd`):

- **O1** `unset MODEL_ALIASES_FILE`; capture file created under the per-run temporary directory
  owned and cleaned by the outer test/campaign runner; an in-target EXIT trap (installed
  immediately after successful capture creation) is ALSO required as best-effort cleanup — the
  engine SIGKILLs target process groups on timeout (`fuzz_engine.py:247-254,265-270`), which no
  in-target trap survives, hence the outer ownership; mktemp failure → `SETUP-FAIL` (exit 8).
- **O2** runs `relay-automation/resolve-model-alias.sh "$1"` capturing stdout BYTE-EXACTLY to
  the capture file (never command substitution — it strips newline-only leaks); resolver stderr
  passes through. Input mapping: the FIRST actual mutant argument is the input; absent input
  maps to the empty string; additional arguments are ignored (documented, bounded).
- **O3** fail-closed measurement: resolver rc captured; `wc -c` rc checked; raw wc output
  validated as optional surrounding whitespace around exactly one decimal integer — internal
  whitespace, split digits, empty output, and wc failure all emit `MEASURE-FAIL` (exit 8);
  whitespace-padded valid counts are ACCEPTED (macOS pads: `/usr/bin/wc -c </dev/null` yields
  `       0`).
- **O4** invariants: resolver rc outside 0/1/2 → `BADRC:<rc>` (exit 9); miss with any stdout
  bytes → `LEAK-STDOUT-ON-MISS` (exit 9); hit with zero stdout bytes → `HIT-EMPTY-ON-MATCH`
  (exit 9); otherwise exit 0. Every oracle-owned diagnostic goes to STDERR (the engine discards
  target stdout, `fuzz_engine.py:244,326`).

**The smoke test** (`test/gh460-fuzz-resolver-smoke.sh`, registered in `validate.sh`'s TESTS list
next to `model-alias.sh` so `ci-local.sh:269` derives it): R1 (shared run contract, floor 20) —
plus, before fuzzing, direct EXACT-value pins: known hit `glm-5.2` observes rc 0 with nonempty
output; observed miss `totally-unknown-model-xyz` observes rc 1 with zero bytes (invoking the
resolver directly — the oracle also accepts rc 2, so an all-rc-2 environment fails here); both
must also pass the oracle. Wrapper mapping checks through `model_alias.resolve_model_slug`:
`glm-5.2` → `z-ai/glm-5.2`; `deepseek v4 pro` → `deepseek/deepseek-v4-pro`; observed-miss input
→ identity; empty input → identity.

**R2 (red control + falsification witnesses; witnessed once in this effort, evidence in
`test/baselines/gh460-campaign/`):** with a cp-backup installed and restoration handlers
(restore-on-exit AND restore-on-failure/interruption) in place BEFORE mutation, and an asserted
EXACT one-site resolver replacement, each witness runs the direct oracle on a pinned input and
must produce the exact stderr diagnostic + oracle exit, then restore to green (baseline → red →
restored-green evidence per witness): (a) terminal miss `exit 1` → `exit 3`
(`resolve-model-alias.sh:128` only; not the usage exit `:52`, not tier exits) → `BADRC:3`;
(b) terminal miss → `printf 'LEAK\n'; exit 1` → `LEAK-STDOUT-ON-MISS`; (c) SEPARATE bare-newline
witness — terminal miss → `printf '\n'; exit 1` → also `LEAK-STDOUT-ON-MISS` (catches regression
to command-substitution capture, which strips the newline and would pass); (d) tier hit
`printf '%s\n' "${canonicals[$i]}"` → no-output → `HIT-EMPTY-ON-MATCH`; (e) MEASURE-FAIL
witnesses: a PATH-shim `wc` exiting 1 (failed wc), wc output with split digits, and wc output
that is empty — all → `MEASURE-FAIL` exit 8; plus the padded-valid-count acceptance control. An
unrelated failure is not a witness.

**R3 (campaigns):** resolver oracle — seeds {7,8,9} × ≥500 iterations under the shared run
contract. Wrapper-floor campaign — seed 11 × ≥300 through `model_alias.resolve_model_slug`.
**Pre-fuzz adapter preflight (both actual campaign targets):** before any campaign, each target
string must pass a syntax check (`bash -n` for the oracle; `ast.parse` for the wrapper) and a
decoded-argument check (the exact decoded argv prefix + one sample mutant maps the sample to the
wrapper input — this is the control that catches the round-3 constant-input adapter). The
wrapper adapter must additionally pass, pre-campaign and directly: the two distinct literal hit
cases, the observed miss, and the empty case (from R1-pre). Adapter policy = O2's: first actual
mutant is the input, absent maps to empty, extras ignored; fixed valid repo root; the resolver is
independently invoked per mapped input to derive the expectation. Wrapper expectation: empty
input stays empty; otherwise successful nonempty stripped resolver output is expected and every
resolver failure/empty output falls back to the literal input (`model_alias.py:41-61`); string
type and the nonempty floor are asserted. Every counterexample dispositioned on #460 per the
loop contract.

**R3b (evidence):** `test/baselines/gh460-campaign/` commits per-campaign seeds, initial corpus
state, JSON summaries, telemetry JSONL, target/base/timeout/environment identity, regression
inputs + replay commands, and `provenance.jsonl` for every run cited in the PR (AGENTS.md §6) —
including baseline/red/restored-green evidence for every R2 witness. Seed-only replay is
insufficient with differing corpus state (`fuzz_engine.py:122,298`); regression success after a
future fix is asserted from pinned inputs, not from replaying a surviving corpus id
(`:185-190` replaces/evicts).

**R4 (defect routing):** spec'd defects → #457; new defects → filed + fixed under #460 with
corpus-derived regression tests. Any runtime (production) fix is separately scoped, rated, and
rollback-analyzed before implementation — this PR's test-only rating covers smoke/registry/
evidence only.


## Implementation order (one list, verification inline)

1. Write `test/gh460-oracle.sh` (O1–O4) and `test/gh460-fuzz-resolver-smoke.sh` (shared run
   contract, floor 20, R1-pre pins and wrapper mapping checks); register the smoke in
   `validate.sh`'s TESTS list next to `model-alias.sh`.
   -> `bash test/gh460-fuzz-resolver-smoke.sh` exits 0 printing the executed count;
   `grep gh460 validate.sh` shows the registration; the oracle passes `bash -n` and its decoded
   engine argv mapping is verified (one mutant in, one input).
2. Witness R2: run the five witness families (rc-3, LEAK, NEWLINE-ONLY-LEAK, HIT-EMPTY,
   MEASURE-FAIL variants), each baseline → red → restored-green with evidence files.
   -> all observed; evidence lands in `test/baselines/gh460-campaign/`.
3. Campaigns (R3): resolver seeds 7/8/9 × 500 + wrapper seed 11 × 300 under the shared run
   contract. -> summaries + telemetry + provenance committed under
   `test/baselines/gh460-campaign/`; counterexamples (if any) triaged on #460 before the PR.
4. Final Codex relay QA on the committed implementation; PR to `development`.

## Risks & rollback

- Risk: a campaign counterexample reveals a real resolver defect → that is the loop working;
  triage per the loop contract on #460 (fix + pinned regression test under #457/#460 routing).
- Risk: flaky smoke in CI → the matcher is deterministic; replay from seed adjudicates; a
  genuinely nondeterministic resolver is itself a finding.
- Rollback: **Easy** — revert the PR (delete the two test files, registry line, evidence dir).
- **Execution boundary (required):** smoke, red-control, and gate runs execute in a SEPARATE
  DISPOSABLE FULL CLONE — never a linked worktree, never a stateful task clone (AGENTS.md GH-564
  rail governs the clone boundary; it covers `test/*.sh` execution, and the resolver's absence
  of git writes does not exempt the test script). The R2 mutation protocol's backup/restoration
  handlers are installed before any mutation, with restoration on failure/interruption.
- Ratings rationale: pri 60 (operator-directed; guards model selection that silently misrouted
  turns 2026-09-05), sev 40 (coverage for a consequence-bearing defect class; no direct data
  loss), appeal 50 (neutral), effort 70 (engine exists; small diff). Recurrence: one distinct
  incident in a 14-day lookback; no same-class reports found.
