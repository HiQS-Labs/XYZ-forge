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

## Requirements

- **R1 (smoke, standing):** `test/gh460-fuzz-resolver-smoke.sh` runs the engine (pinned seed 7,
  ≥20 iterations) with this exact oracle target (base argv = one placeholder; `fuzz_engine.py:223`
  inserts every mutant token, so the wrapper reads only `"$1"` and the plan bounds mutants to
  single-token relevance):
  `bash -c 'unset MODEL_ALIASES_FILE; t=$(mktemp) || { echo "SETUP-FAIL" >&2; exit 8; }; trap 'rm -f "$t"' EXIT; bash relay-automation/resolve-model-alias.sh "$1" >"$t" 2>/dev/null; rc=$?; bytes=$(wc -c <"$t"); wc_rc=$?; if [ $wc_rc -ne 0 ] || [ -z "$bytes" ]; then echo "MEASURE-FAIL" >&2; exit 8; fi; bytes=$(printf '%s' "$bytes" | tr -d '[:space:]'); case $bytes in ''|*[!0-9]*) echo "MEASURE-FAIL" >&2; exit 8;; esac; case $rc in 0|1|2) ;; *) echo "BADRC:$rc" >&2; exit 9;; esac; [ $rc -eq 1 ] && [ "$bytes" -gt 0 ] && { echo "LEAK-STDOUT-ON-MISS" >&2; exit 9; }; [ $rc -eq 0 ] && [ "$bytes" -eq 0 ] && { echo "HIT-EMPTY-ON-MATCH" >&2; exit 9; }; exit 0' _ {mutant}`
  — the byte parse strips surrounding whitespace (macOS `wc -c` pads with leading spaces:
  `/usr/bin/wc -c </dev/null` yields `       0`; the whitespace-stripped value must be exactly
  one decimal integer) and the tmpfile carries an EXIT-trap cleanup so no failure path leaves
  captures behind.
  — byte-exact stdout via tmpfile (`wc -c`; command substitution would hide newline-only leaks),
  diagnostics on **stderr** (the engine records stderr, `fuzz_engine.py:244,326`, and discards
  stdout), `unset MODEL_ALIASES_FILE` so an inherited env cannot turn iterations into rc-2
  usage exits (`resolve-model-alias.sh:32,59-61`). Violation invariants: rc outside 0/1/2
  (BADRC), stdout bytes on a miss (LEAK), empty stdout on a hit (HIT-EMPTY). A wc failure is a
  measurement error (`MEASURE-FAIL`, nonzero), never accepted as a valid miss observation.
  Pre-fuzz direct invocations pin the environment by asserting EXACT observed values (not mere
  oracle pass — the oracle also accepts rc 2, so rc-2-only environments must fail here): the
  known hit `glm-5.2` must observe rc 0 with nonempty output, and the independently observed
  miss `totally-unknown-model-xyz` must observe rc 1 with zero output bytes; otherwise the test
  fails — a missing/unreadable table must not produce an all-rc-2 green run. The test parses the engine's JSON summary (`fuzz_engine.py:339,470`),
  fails closed on missing/malformed JSON, and asserts `executed >= 20`, `counts.fail == 0`,
  `counts.anomaly == 0`.
- **R1b (gate registration):** register the smoke in `validate.sh`'s TESTS list (next to
  `model-alias.sh`, ~line 102) so `ci-local.sh`'s qualifying suite derives it too
  (`ci-local.sh:246,269`). An unregistered test does not continuously guard.
- **R2 (red control, deterministic + attributable):** the smoke itself (not only fuzzed
  mutants — `fuzz_engine.py:114-127` mutates every parent and never executes the base unchanged)
  ALSO invokes the same oracle directly on a pinned miss input (`totally-unknown-model-xyz`,
  witnessed to miss at HEAD) and asserts pass. Red protocol, in order: (a) `cp` the resolver to a
  backup and `trap` restore-before-exit covering failure/interruption; (b) mutate EXACTLY the
  terminal miss exit — the `exit 1` at `resolve-model-alias.sh:128` — to `exit 3` (not the usage
  exit at `:52`, not the tier loops); (c) run the direct oracle on the pinned miss → it must exit
  9 with `BADRC:3` on stderr (telemetry/PR records this — a syntax error, timeout, or missing
  JSON does not qualify as the red witness); (d) restore, re-run direct oracle + smoke → green,
  with a fresh corpus dir per run (corpus state affects generation, `fuzz_engine.py:298`).
  **Negative-control witnesses** — the LEAK and HIT-EMPTY invariants get their own
  cp-backed/trap-restored mutation witnesses, each requiring the exact stderr diagnostic, oracle
  exit 9, and restored green (an unrelated failure is not a witness): LEAK — terminal miss
  `exit 1` → `printf 'LEAK\n'; exit 1`, direct oracle on the pinned miss must emit
  `LEAK-STDOUT-ON-MISS`; NEWLINE-ONLY-LEAK — terminal miss → `printf '\n'; exit 1` (one bare
  newline) must ALSO emit `LEAK-STDOUT-ON-MISS` — this is the control that falsifies a
  regression to command-substitution capture, which would strip the newline and pass; HIT-EMPTY
  — the four tier `printf '%s\n' "${canonicals[$i]}"` statements → no-output, direct oracle on
  the known hit `glm-5.2` must emit `HIT-EMPTY-ON-MATCH`; MEASURE-FAIL — a PATH-shim `wc` that
  exits 1 must make the oracle emit `MEASURE-FAIL` with exit 8 (witnesses the fail-open path
  fixed above). The padded-count positive control is the known-hit precondition itself: on
  macOS the observed byte count arrives whitespace-padded and MUST be accepted. Oracle temp
  captures live in a per-run temporary directory owned and cleaned by the outer test/campaign
  runner (the engine SIGKILLs target process groups on timeout — `fuzz_engine.py:247-254,265-270`
  — so no cleanup inside a killed target can be relied on). Smoke/red runs execute
  in a disposable full clone per the AGENTS.md `test/*.sh` rail — the resolver body has no git
  writes, but the rail covers the test script, not its target.
- **R3 (campaigns):** reusable recipe (per run; `--json` is REQUIRED — the engine prints a
  human summary without it, `fuzz_engine.py:466-469`, and the green criteria parse JSON):
  `python3 utils/py/fuzz_engine.py --mode fuzz --target "$ORACLE" --base "glm-5.2" --seed $S --iterations 500 --timeout 30 --cwd <repo-root> --corpus <fresh>/.fuzz_corpus --telemetry-out <fresh>/telemetry.jsonl --json > <fresh>/summary.json`
  with `$S` ∈ {7,8,9} for the resolver, seed 11 pinned for the wrapper campaign, `--timeout-budget 30`
  (the registered full flag name; the engine's current default is 30, `fuzz_engine.py:430`), `$ORACLE` = the R1
  target string, `LC_ALL=C` pinned, fresh corpus and telemetry/summary paths per run. Green
  criteria per run: engine exit 0 AND a nonempty valid JSON summary AND parsed
  `executed >= <floor>` (500 resolver / 300 wrapper), `counts.fail == 0`,
  `counts.anomaly == 0` (exit status alone is insufficient — `fuzz_engine.py:330-335,470`
  distinguish counted failures from counterexamples). Wrapper-floor target — NO `_` sentinel
  (python puts `-c` at argv[0]; without this mapping every mutant is ignored and
  `sys.argv[1]` stays the literal sentinel) — with the differential invariant IN the target
  (wrapper output must equal the resolver-derived expectation on every iteration):
  `python3 -c 'import sys,subprocess; sys.path.insert(0,"utils/py"); from model_alias import resolve_model_slug as r; a=sys.argv[1:]; v=a[0] if a else ""; out=r(v,"."); ref=subprocess.run(["bash","relay-automation/resolve-model-alias.sh",v],capture_output=True); exp=(ref.stdout.decode().strip() or v) if ref.returncode==0 else v; sys.exit(0) if out==exp else (_ for _ in ()).throw(SystemExit(f"DIFF v={v!r} out={out!r} exp={exp!r}"))' {mutant}`
  (extra mutant tokens land beyond a[0]; ignored — single-token relevance bounded as in R1).
  Pre-campaign direct checks in the test, with literal inputs/expected outputs: `glm-5.2` →
  `z-ai/glm-5.2`; `deepseek v4 pro` → `deepseek/deepseek-v4-pro`;
  `totally-unknown-model-xyz` → identity; empty input → identity. Environment/table policy:
  unset `MODEL_ALIASES_FILE`, shipped table, `LC_ALL=C`. Every counterexample dispositioned on
  #460 per the loop contract.
- **R3b (durable evidence):** commit `test/baselines/gh460-campaign/` containing per-campaign
  seeds, initial corpus state (or the empty-corpus-per-run requirement), JSON summaries,
  telemetry JSONL, target/base/timeout/environment identity, any regression inputs (exact argv
  + replay command), and `provenance.jsonl` for every run cited in the PR (AGENTS.md §6) —
  including baseline/red/restored-green evidence from R2. Seed-only replay is insufficient with
  differing corpus state (`fuzz_engine.py:122,298`); do not depend on ephemeral corpus ids
  (`:185-190` replaces/evicts). Regression success after a future fix is asserted from the
  pinned input, not from replaying a surviving corpus id.
- **R4 (defect routing):** defects already spec'd → #457; new defects → filed + fixed under
  #460 with corpus-derived regression tests. Any discovered *runtime* (production) fix is
  separately scoped, rated, and rollback-analyzed before implementation — this PR's test-only
  rating (Easy; 60/40/50/70) covers the smoke/registry/evidence work only and does not
  automatically extend to a matcher or wrapper fix.

## Non-goals

- No engine changes; no new *production* Bash — the oracle inlines into the `--target` string
  and `test/` files are exempt from the GH-551 rail; no tier-4 semantics changes (#450); no
  D1/D2/D3 fixes here (#457); no cache/latency (#346).
- Campaign scope bounded to string model inputs and the fixed valid harness root.
  Bycatch for #457: `model_alias.py:17`'s "never raises" docstring exceeds the implementation
  for invalid root types (`resolver_path` runs outside the try, `:31,44`) — a contract finding
  to route, not fuzz.

## Implementation order (one list, verification inline)

1. Write `test/gh460-fuzz-resolver-smoke.sh` implementing R1 verbatim (engine invocation, seed 7,
   20 iterations, R1 oracle target; assert `executed >= 20 && counts.fail == 0 &&
   counts.anomaly == 0`, fail-closed on bad JSON) + register it in `validate.sh`'s TESTS list (R1b).
   -> `bash test/gh460-fuzz-resolver-smoke.sh` exits 0 with the executed-count printed;
   `grep gh460 validate.sh` shows the registration.
2. Witness the red control: cp the resolver to a backup, sed-inject `exit 3` on the miss path,
   run the smoke (expect exit ≠ 0), restore from the backup, re-run (expect green).
   -> red then green, both observed; noted in the PR.
3. Campaigns: 3 seeds × 500 iterations (resolver) + wrapper-floor campaign (≥300 iterations).
   -> engine summaries captured; counterexamples (if any) triaged on #460 before the PR.
4. Final Codex relay QA on the committed diff, then PR to `development`.

## Risks & rollback

- Risk: flaky fuzz failure in CI from a genuinely nondeterministic resolver (none known — the
  matcher is deterministic; replay from seed adjudicates). Rollback: revert the PR; the test
  file is self-contained; the PR's touched set is the test file, the validate.sh registry line,
  the evidence dir, and the witnessed-and-restored R2 resolver mutation.
- The campaigns and smoke runs spawn short-lived bash/python subprocesses. The PR touches the
  registry, the committed evidence dir, and (during R2 only, restored + witnessed) the resolver
  file. Full-suite gate runs use a separate disposable full clone (AGENTS.md `test/*.sh` rail).
- Reversibility: **Easy** — test-only PR; rollback = revert (delete the test file + registry
  line + evidence dir). Ratings rationale: pri 60 (operator-directed; guards model selection
  that silently misrouted turns 2026-09-05), sev 40 (coverage for a consequence-bearing defect
  class; no direct data loss), appeal 50 (neutral), effort 70 (engine exists; small diff).
  Recurrence: one distinct incident in a 14-day lookback; no same-class reports found.
