---
ratings_exempt: true
title: Cost observability for coordination systems (xyz + relay)
slug: cost-observability-plan
status: Phases 1–3 shipped ✅; v2 coverage-honesty tranche (Phase 4 spike → 7) OPEN 2026-07-06
owner: Noel (operator) · Claude (producer)
created: 2026-06-15
updated: 2026-07-06
branch: main
gh_issues:
  - 151  # reconcile SSOT + orphaned Gemini relay-lane token capture (Phase 4 spike + 5)
  - 152  # auto-surface tick analyze cost at end of driven runs (Phase 6)
  - 153  # Codex per-turn token capture — parseCodexStats (Phase 7)
related:
  - PROJECT/1-INBOX/FEEDBACK-2026-06-15.md   # the gap this plan closes (point 5: track cost, not just output)
  - src/analyze.js                           # the deterministic analyzer we extend
  - experiments/coordination-layer/ROADMAP.md # Phase 4 R4 (structured JSON logs) overlaps Phase 2 here
problem: >
  The deterministic analyzer (tick analyze / src/analyze.js) measures COORDINATION
  (concurrency %, parked-claims, per-agent counts) but measures ZERO cost. So we can
  report what got built (files, passing tests) but not what it cost (tokens, wall-clock,
  human attention) — which means xyz and relay cannot be compared on cost-per-unit-of-work.
goal: >
  Add three cost signals (tokens, wall-clock, human-minutes) to the SAME deterministic,
  no-LLM analyzer, then produce one honest xyz-vs-relay cost comparison on a real run.
non_goals:
  - No LLM/heuristic scoring of cost — measurement stays deterministic and reproducible.
  - No live pricing/$ conversion — report raw tokens; $ is a downstream multiplication.
  - No new coordination metrics — concurrency/drift/collision logic is untouched.
---

# Cost observability for coordination systems

## Status

| What was just completed | What's next |
|---|---|
| **Phases 1–3 shipped ✅** (2026-06-16): raw cost signals captured, deterministic analyzer computes cost, `COST-COMPARISON.md` generated from `tick analyze --format json`. **Post-ship coverage audit (2026-07-06)** found the capture lane has drifted from the plan: `gemini-turn.sh` was retired for cost-blind `agy-turn.sh`, so the `parseGeminiStats` **relay** path is orphaned (survives only in `consult.sh:251-255` behind the legacy `gemini` alias); `claude-turn.sh` now meters *its* lane (new since Phase 1); and no driver auto-surfaces cost. Three follow-on issues filed (#151/#152/#153). | **Phase 4 — Coverage-truth spike** (#151): probe Codex + agy usage surfaces, decide reconnect-vs-retire for the Gemini relay path, and write findings back into this doc before its gate can pass. Then Phase 5 reconcile (#151), Phase 6 auto-surface cost (#152), Phase 7 Codex capture (#153). |

## Table of contents

- [Phase 1 — Capture raw cost signals at the source](#phase-1--capture-raw-cost-signals-at-the-source)
- [Phase 2 — Extend the deterministic analyzer to compute cost](#phase-2--extend-the-deterministic-analyzer-to-compute-cost)
- [Phase 3 — Dogfood + the xyz-vs-relay cost comparison](#phase-3--dogfood--the-xyz-vs-relay-cost-comparison)
- [Phase 4 — Coverage-truth spike (discovery gate)](#phase-4--coverage-truth-spike-discovery-gate)
- [Phase 5 — Reconcile the SSOT + fix the coverage-honesty regression](#phase-5--reconcile-the-ssot--fix-the-coverage-honesty-regression)
- [Phase 6 — Auto-surface cost at end of driven runs](#phase-6--auto-surface-cost-at-end-of-driven-runs)
- [Phase 7 — Codex per-turn token capture](#phase-7--codex-per-turn-token-capture)
- [Deferred / backlog](#deferred--backlog)
- [Open questions for the reviewer](#open-questions-for-the-reviewer)

---

## Phase 1 — Capture raw cost signals at the source

**Intent:** get the three raw numbers (tokens, wall-clock, human-minutes) into the event log or a
sidecar that the analyzer can read deterministically. No computation yet — just capture.

### Checklist (each item is observable)

- [x] **Tokens (headless Gemini turns):** `gemini-turn.sh` runs `gemini -o json`, then emits a
      `cost.tokens` event via `tick cost --from-gemini-json` (`parseGeminiStats` sums `stats.models.*`
      verbatim — Q1 resolved: the CLI report IS the source of truth). Best-effort: never fails the turn.
      *Observable:* after a turn, the `.tick/events/*tokens*` file carries non-zero `tokens_out`. ✅ (parser + verb tested in `cost.sh`; live tool-using `-o json` turn validated in Phase 3 dogfood.)
- [~] **Tokens (Codex turns):** **DEFERRED** — Codex's usage/stats output format isn't probed yet, so
      no `parseCodexStats` exists. `codex-turn.sh` persists its transcript (below) so the data is there
      to parse later; until then Codex turns are a known token gap (the loud-partial signal will say so).
- [~] **Tokens (Claude orchestrator turns):** **DEFERRED** — the main-loop harness exposes no
      programmatic per-turn token count to the shell here. Honest gap; revisit if/when a hook exists.
      Not faked.
- [x] **Wall-clock:** confirmed recoverable from existing `task.claimed`→terminal (`done`/`released`/
      `circuit_break`) events — every terminal event already carries `ts`, so per-task duration needs
      NO new capture. (Computation lands in Phase 2; nothing to emit in Phase 1.)
- [x] **Human-minutes:** `tick cost <task> --agent <id> --human-minutes <n>` appends one `cost.human`
      event. Manual by design (only a human knows their own attention).
      *Observable:* `cost.sh` asserts the event carries `human_minutes=12`. ✅
- [x] **Transcript capture (the headless-mode gap):** `GEMINI_LOG`/`CODEX_LOG` now default to a
      `$TMPDIR` path (NOT the repo tree — the guard at `relay-turn-lib.sh:64-65` deletes any in-tree
      log). This is also what makes token capture possible (the json transcript is the token source).
      *Observable:* after a headless turn the temp transcript exists and is non-empty. ✅

### QA checklist — Phase 1

- [x] **DRY:** the shared seam is `tick cost` (the event write) — every turn-taker and the operator
      call the SAME verb. The *parser* (`parseGeminiStats`) is deliberately model-specific (each CLI's
      stats format differs), so it lives in `src/cost.js` and the gemini shim, not a fake-shared blob.
      Correct seam, not copy-paste.
- [x] **SOLID (single responsibility):** capture only writes events; it computes nothing. `parseGeminiStats`
      is pure (no I/O). No analyzer logic leaked into the turn-takers.
- [x] **Observability:** every cost signal is a timestamped JSONL event, greppable by `agent` and `task`
      (filename + payload).
- [x] **Determinism litmus:** `parseGeminiStats` is pure; `tick cost` only writes. The no-regression test
      proves `analyze --format json` is byte-identical before/after cost events are added.
- [x] **No regression:** full suite **22/22**; `analyze` excludes `cost.*` events explicitly
      (`analyze.js:158`), and `cost.sh` asserts the analyze json is unchanged by cost events + that
      cost-only agents don't leak into the per-agent table.
- [x] **Anti-goal check:** no `$`/pricing math; raw tokens only.

---

## Phase 2 — Extend the deterministic analyzer to compute cost

**Intent:** teach `src/analyze.js` to read the Phase-1 signals and emit a cost section in all three
formats (human / md / json), staying 100% deterministic — exactly like the existing metrics.

### Checklist (each item is observable)

- [x] **Sum tokens:** total + per agent (`cost.tokens.{tokens_in,tokens_out,tokens_total}` and
      `cost.tokens.by_agent`). *Observable:* `cost.sh` asserts `tokens_total=10` from two events. ✅
- [x] **Wall-clock:** run-window (existing) PLUS `cost.walltime.by_task` and `cost.walltime.by_agent`
      derived from closed claim windows. *Observable:* json carries both maps (still-open windows skipped). ✅
- [x] **Human-minutes:** summed into `cost.human_minutes_total`; absent input → `0`, never null.
      *Observable:* `cost.sh` asserts total `3` and `0` on a run with none. ✅
- [x] **Cost-per-unit-of-work:** `cost.per_unit.tokens_per_done` + `cost.per_unit.walltime_per_done_ms`;
      denominator 0 → `null` (rendered `n/a`), never divide-by-zero. Denominator is **distinct done-tasks**
      (the hardest-to-game unit — Gemini Q2). *Observable:* `cost.sh` asserts `10/2 → 5`. ✅
- [x] **Render in human + md:** a `### Cost` block in the `--write` markdown (and a `--- cost ---` block
      in human). *Observable:* `--write` adds the Cost section without disturbing the coordination one. ✅
- [x] **Structured JSON log + `run_type`:** the `cost` object is the structured record; `run_type:
      symmetric|asymmetric` is operator-set via `TICK_RUN_TYPE` (invalid/unset → `unspecified`, never
      auto-guessed) _(Gemini r1 [Nit])_. *Observable:* `cost.sh` asserts env honored + garbage rejected. ✅
- [x] **Loud partial signal:** when done-task token coverage is incomplete, totals render as a FLOOR
      (`≥N`) with `coverage: X/Y done-tasks` and an explicit "treat as a lower bound" note _(Gemini r1
      [Should])_. *Observable:* `cost.sh` asserts `partial:true`, `coverage 1/2`, and the md floor marker. ✅

### QA checklist — Phase 2

- [x] **DRY:** cost rendering reuses the existing `renderHuman`/`renderMd` paths and the same `humanDuration`
      helper; json is the report object verbatim. No parallel printer.
- [x] **SOLID (open/closed):** `computeCost` is a new pure function; the concurrency/parked-claim functions
      were not touched. Cost reads `allEvents`, coordination reads the `task.*` filter.
- [x] **Observability:** the `cost` object in json is the source of truth; human/md are views over it.
- [x] **Determinism litmus:** `computeCost` is a pure function of the event log + `TICK_RUN_TYPE`; no clock,
      no randomness. Same events → identical cost. (`cost.sh` re-derives the same numbers each run.)
- [x] **Edge cases:** zero cost events → totals `0`, `per_unit` `null`→`n/a`, no crash (the demo + the
      no-cost-events path exercise this).
- [x] **No-silent-cap:** incomplete coverage renders `≥`/`coverage X/Y` + a "lower bound" note — never a
      bare undercount. (`cost.sh` asserts the marker in md.)
- [x] **Anti-goal check:** no LLM call, no `$`/pricing math in `analyze.js`. Raw tokens only.

---

## Phase 3 — Dogfood + the xyz-vs-relay cost comparison

**Intent:** run BOTH systems on the same fixture, capture cost via Phases 1–2, and produce the one
artifact the feedback doc was missing: an honest cost-per-unit comparison of xyz vs relay.

### Checklist (each item is observable)

- [x] **xyz run with cost on:** 2-lane synthetic fixture (`$TMPDIR/p3-xyz`); 4 tasks (IMPL-A1/A2/B1/B2), 2 agents (alpha, beta). `tick analyze` shows `tokens_total=58920`, coverage `4/4`. ✅
- [x] **relay run with cost on:** fresh relay (`relay-system/2026-06-16/p3-dogfood-relay.md`) driven by `relay-drive.sh` + `gemini-turn.sh` under `-o json`. Real Gemini call; tokens captured via `parseGeminiStats` (with preamble-skip fix). `tokens_total=110008`, coverage `1/1`. ✅
- [x] **Operator logs human-minutes for both** via `tick cost --human-minutes`. xyz=8 min, relay=5 min. ✅
- [x] **DETERMINISTIC transcript write:** transcript copied from `$TMPDIR/p3-gemini-turn.json` to
      `relay-system/2026-06-16/p3-dogfood-relay.gemini-transcript.md` via a scripted shell step (not a
      prompt instruction). File exists and is committed. ✅
- [x] **Comparison report:** `PROJECT/4-MISC/COST-COMPARISON.md` — table: system × {tokens, wall-clock,
      human-min, tokens/done, run_type, coverage}. Every cell from `tick analyze --format json`. ✅
- [x] **Update the feedback doc:** `FEEDBACK-2026-06-15.md` now cites real cost-per-unit figures (point 5
      closed) under "Cost comparison — point 5 closed". ✅

### QA checklist — Phase 3

- [x] **DRY:** transcript copy is a deterministic shell step (one-liner after the relay turn); both
      `gemini-turn.sh` / `codex-turn.sh` inherit the `$TMPDIR`-first log pattern. ✅
- [x] **SOLID:** `COST-COMPARISON.md` is generated from `tick analyze --format json`; no metric
      recomputed by hand. ✅
- [x] **Observability:** every number in `COST-COMPARISON.md` is traced to a json field; the
      comparison doc names the source roots. ✅
- [x] **Apples-to-apples caveat:** `COST-COMPARISON.md` states xyz ran independent coding lanes
      (synthetic fixture, symmetric) and relay ran a turn-based review (real, asymmetric) — they
      are not the same work; cost compares systems-on-their-fit-work. ✅
- [x] **Determinism litmus:** same events → identical output from `tick analyze` (no LLM, no clock
      in `analyze.js`). ✅
- [x] **No-silent-cap:** transcript copy verified (file exists + non-empty); token capture failure
      in first run diagnosed and fixed (`parseGeminiStats` preamble-skip), then confirmed parseable. ✅
- [x] **Reversibility:** `COST-COMPARISON.md` and transcripts are additive; nothing destructive. ✅

---

# v2 — Coverage-honesty tranche (opened 2026-07-06)

> Phases 1–3 shipped the deterministic cost subsystem. A post-ship audit found the **capture side has
> drifted from the plan** and coverage is thinner than "shipped" implies. This tranche re-aligns the
> SSOT with reality, closes the silent regression, and makes cost visible without a manual pull.
> It changes NO anti-goal: still raw tokens only, still no LLM scoring, still no `$` conversion.

## Phase 4 — Coverage-truth spike (discovery gate)

**Intent:** before writing any parser or driver code, probe the *actual* usage surfaces of each live
lane and pin the current-state facts. This is the phase-0-equivalent discovery gate for the tranche:
its **findings must be written back into this doc** (per PDDA's spike rule) before its QA gate can pass.
No production code changes in this phase — probe and record only.

**Verified going in (2026-07-06 audit — to be confirmed/extended by the spike):**
- `relay-automation/gemini-turn.sh` — **retired.** Live turn shims: `agy-turn.sh`, `aider-turn.sh`,
  `claude-turn.sh`, `codex-turn.sh`.
- `parseGeminiStats` / `tick cost --from-gemini-json` — referenced only by `src/cost.js` (def),
  `bin/tick` (verb), `test/cost.sh` (test), and `relay-automation/consult.sh:251-255` (consult
  one-shot, behind the legacy `gemini`/`GEMINI_BIN` alias). **No relay/marathon turn lane feeds it.**
- `relay-automation/claude-turn.sh:210-221` now meters its lane (usage.input_tokens + cache_read,
  output_tokens, total_cost_usd → `tick cost --tool claude`) — new since Phase 1's "Claude DEFERRED".
- `agy-turn.sh` — structurally cost-blind (no `-o json`/usage block); token spend is always a floor of 0.

### Checklist (each item is observable)

- [ ] **Probe Codex usage surface:** run `codex exec` and inspect its end-of-turn output for a
      usage/stats block (JSON or parseable). *Observable:* a captured sample transcript in the findings
      below with the exact field path (or a recorded "no usable surface" verdict). Feeds #153.
- [ ] **Probe agy usage surface:** check `agy` print mode for ANY usage output (flag, stderr, sidecar
      file). *Observable:* findings record either the surface or "structurally cost-blind — confirmed".
- [ ] **Confirm the Gemini relay-lane state:** verify no live turn shim calls `--from-gemini-json`
      and that `consult.sh` is the only remaining caller. *Observable:* the grep result is pasted below.
- [ ] **Confirm claude-lane metering is live + correct:** drive one `claude-turn.sh` turn and confirm a
      `.tick/events/*tokens*` file with non-zero `tokens_out` and `--tool claude`. *Observable:* event file.
- [ ] **Decision record:** write the three go/no-go calls back into this doc — (a) Codex capture
      feasible? (b) agy capture feasible? (c) reconnect vs **retire** the Gemini relay-lane path.
- [ ] **Findings written back** into the section below before this phase's QA gate is checked.

### Findings written back from the spike

_(to be filled by the spike before the QA gate — leave the checklist above unchecked until then.)_

### QA checklist — Phase 4

- [ ] **Discovery-before-build:** no parser/driver code shipped in this phase; only probes + findings.
- [ ] **Findings-back rule:** the "Findings written back" section is populated before the gate passes
      (PDDA discovery-phase contract).
- [ ] **Observability:** every claim in the findings cites a command output or a `file:line`, not memory.
- [ ] **Determinism litmus:** each probe is a re-runnable command; the findings record the exact invocation.
- [ ] **No-silent-cap:** any lane found cost-blind is named explicitly as a floor, not omitted.
- [ ] **Anti-goal check:** no `$`/pricing and no LLM scoring introduced by the probes.

---

## Phase 5 — Reconcile the SSOT + fix the coverage-honesty regression

**Intent:** make the plan, the code, and `CONSUMING.md` tell the *same* honest story, and close the
orphaned-Gemini-lane regression (#151) one way or the other. Gated on the Phase 4 decision.

### Checklist (each item is observable)

- [ ] **Resolve the Gemini relay path:** per the Phase 4 call, either (a) **retire** it — mark
      `parseGeminiStats` / `--from-gemini-json` as consult-only in `src/cost.js` + `bin/tick` help, or
      (b) **reconnect** it to a live lane. *Observable:* the chosen path is reflected in code comments +
      `tick cost --help`, and no doc still implies a live `gemini-turn.sh` relay lane.
- [ ] **Correct the Phase 1 record:** annotate that the Claude *lane* (`claude-turn.sh`) is now metered
      while the *orchestrator* remains deferred (the two were conflated). *Observable:* Phase 1 note updated.
- [ ] **Sync `relay-automation/CONSUMING.md`:** its "cost-blind lanes" statement matches the Phase 4
      findings (which lanes are metered vs floors). *Observable:* `CONSUMING.md` diff.
- [ ] **Prove the floor signal on a real multi-lane run:** drive a run mixing a metered lane (claude)
      and a cost-blind lane (agy), then `tick analyze` renders `≥` + `coverage X/Y` + the lower-bound note.
      *Observable:* the rendered md/human cost block shows the floor marker with correct coverage.

### QA checklist — Phase 5

- [ ] **DRY:** no second source of "which lanes are metered" — `CONSUMING.md` is the prose SSOT, this
      plan links it rather than re-listing.
- [ ] **SOLID:** capture vs report seams unchanged; this phase edits docs + one help string, not analyzer logic.
- [ ] **Observability:** the multi-lane run's floor marker is shown from real `tick analyze` output, not asserted.
- [ ] **No-silent-cap:** the regression fix must not let a cost-blind lane read as `0` exact — it stays a floor.
- [ ] **Reversibility:** doc + comment edits are additive/revertible; no event-schema change.
- [ ] **Anti-goal check:** no `$`/pricing, no LLM scoring.

---

## Phase 6 — Auto-surface cost at end of driven runs

**Intent:** stop requiring a manual `tick analyze` pull. Print the cost block at end-of-run for driven
relay/marathon sessions, honoring the floor/partial markers so cost-blind lanes never read as exact (#152).

### Checklist (each item is observable)

- [ ] **End-of-run cost summary:** the driver emits the `tick analyze` cost block (human/md) to its
      run summary / stderr at completion. *Observable:* a driven run's tail shows the `### Cost` block.
- [ ] **Floor markers preserved:** partial coverage renders `≥` + `coverage X/Y` + the lower-bound note
      in the auto-surfaced output. *Observable:* a mixed metered/blind run shows the marker inline.
- [ ] **Opt-in / non-disturbing:** gated by an env toggle (default-on acceptable only if additive);
      failure to analyze never fails the run. *Observable:* toggling the env removes/keeps the block; a
      forced analyze error still exits the driver green.
- [ ] **No new metric:** reuses the existing `tick analyze` output verbatim — no recomputation in the driver.

### QA checklist — Phase 6

- [ ] **DRY:** the driver calls `tick analyze`; it does not re-derive any cost number itself.
- [ ] **SOLID (single responsibility):** the driver only *renders* an existing report at end-of-run.
- [ ] **Observability:** the surfaced block is the same object `tick analyze --format json` produces.
- [ ] **No-silent-cap:** partial coverage is shown as a floor in the auto output, identical to the manual pull.
- [ ] **Reversibility:** behind an env toggle; removing it restores byte-identical prior driver behavior.
- [ ] **Anti-goal check:** no `$`/pricing, no LLM scoring.

---

## Phase 7 — Codex per-turn token capture

**Intent:** close the Codex token gap by mirroring the Gemini parser (#153). **Hard-gated on Phase 4**
confirming Codex emits a usable usage surface — do NOT build against an un-probed format, do NOT fake.

### Checklist (each item is observable)

- [ ] **Gate check:** Phase 4 recorded a usable Codex usage surface. If not, this phase stays blocked and
      says so (no speculative parser). *Observable:* the Phase 4 decision record shows "Codex feasible: yes".
- [ ] **`parseCodexStats`:** a pure parser in `src/cost.js` mirroring `parseGeminiStats` (no I/O).
      *Observable:* `test/cost.sh` asserts a known token total from a Codex fixture.
- [ ] **Wire `codex-turn.sh`:** emit `cost.tokens --tool codex` best-effort — never fails the turn; loud
      stderr on zero/unparseable. *Observable:* after a Codex turn, `.tick/events/*tokens*` carries
      non-zero `tokens_out` for `--tool codex`.
- [ ] **Coverage rises:** on a Codex-inclusive run, `tick analyze` coverage moves toward `done_tasks`
      (fewer floors). *Observable:* the coverage fraction increases vs a pre-Phase-7 run.

### QA checklist — Phase 7

- [ ] **DRY:** reuses the `tick cost` write seam and the same event schema; only the parser is Codex-specific.
- [ ] **SOLID:** `parseCodexStats` is pure; no analyzer logic changes.
- [ ] **Observability:** each Codex turn writes a timestamped `cost.tokens` event greppable by `--tool codex`.
- [ ] **Determinism litmus:** `parseCodexStats` is a pure function of the transcript; same input → same tokens.
- [ ] **No-silent-cap:** if capture fails, the loud-partial signal still marks the turn as an un-metered floor.
- [ ] **Anti-goal check:** raw tokens only; no `$`/pricing, no LLM scoring.

---

## Deferred / backlog

Items consciously NOT done, so they don't masquerade as covered. Each says why + what unblocks it.

- [ ] **Codex token capture** — **now tracked as Phase 7 (#153)**, gated on the Phase 4 (#151) probe of
      `codex exec`'s usage block. `codex-turn.sh` already persists its transcript, so the data exists to
      parse later. Until then Codex turns are a known token gap (Phase 2 renders it as partial).
- [ ] **Orphaned Gemini relay-lane capture (regression, #151)** — the plan built for `gemini-turn.sh`
      under `-o json`, but that shim was retired for cost-blind `agy-turn.sh`. `parseGeminiStats` /
      `--from-gemini-json` now survives only in `consult.sh:251-255` (legacy `gemini` alias); no relay/
      marathon turn lane feeds it. *Unblocks in:* Phase 4 spike (decide reconnect vs retire) → Phase 5.
- [ ] **Cost never auto-surfaced by drivers (#152)** — `relay-drive.sh` / `marathon-drive.sh` don't run
      `tick analyze`, so a run's cost total is invisible without a manual pull. *Unblocks in:* Phase 6.
- [ ] **Claude orchestrator per-turn tokens** — the main-loop harness exposes no shell-visible per-turn
      token count, so the orchestrator's own tokens aren't captured. *Unblocks when:* a harness hook /
      transcript with usage is available. Deliberately NOT faked with an estimate.
- [x] **Live tool-using `gemini -o json` relay turn** — **VALIDATED in Phase 3.** Real headless
      Gemini turn on `p3-dogfood-relay.md` under `-o json` worked end-to-end. One fix needed:
      `parseGeminiStats` now handles the warning-prefix preamble (warning lines before the JSON
      object). Tokens captured: in=33 128, out=76 880, total=110 008. ✅ (2026-06-16)
- [ ] **`$`/pricing conversion** — out of scope by design (anti-goal). Raw tokens only; a price multiply
      is a trivial downstream step once per-model rates are pinned.

_(Cross-ref: repo-wide backlog lives in `experiments/coordination-layer/BACKLOG.md`; these are plan-local.)_

## Open questions for the reviewer

1. ~~**Token source of truth:**~~ **RESOLVED** — `gemini -o json` emits `stats.models.*.tokens.{input,
   total,...}`; we log it verbatim (`parseGeminiStats`). No wrapper needed. Codex's format is still
   un-probed (its capture is deferred).
2. **Denominator for cost-per-unit:** is `tasks done` the right denominator, or should it be `passing
   tests` / `files touched`? The feedback doc counted tests — but tests-passing is throughput, not
   correctness. Pick the denominator that's hardest to game.
3. **Human-minutes honesty:** a manual `tick cost --human-minutes` is self-reported. Is that acceptable,
   or do we need a wall-clock-of-operator-window proxy? (Self-report is cheap but soft.)
4. **Scope of the comparison:** comparison on the existing P3 run (already done, asymmetric work), or a
   fresh fixture where both systems run the SAME task so the comparison is truly apples-to-apples?
