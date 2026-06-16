---
title: Cost observability for coordination systems (xyz + relay)
slug: cost-observability-plan
status: Draft — awaiting relay review
owner: Noel (operator) · Claude (producer)
created: 2026-06-15
branch: main
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

| Most recently completed phase | What's next |
|---|---|
| **Phase 1 — Capture raw cost signals** ✅ shipped: `cost.tokens`/`cost.human` events, `tick cost` verb, `parseGeminiStats` (verbatim from `gemini -o json`), headless token capture wired into `gemini-turn.sh`, transcripts default to `$TMPDIR`. `cost.sh` 14/14; full suite **22/22** green. | **Phase 2 — Extend the deterministic analyzer to compute cost** |

## Table of contents

- [Phase 1 — Capture raw cost signals at the source](#phase-1--capture-raw-cost-signals-at-the-source)
- [Phase 2 — Extend the deterministic analyzer to compute cost](#phase-2--extend-the-deterministic-analyzer-to-compute-cost)
- [Phase 3 — Dogfood + the xyz-vs-relay cost comparison](#phase-3--dogfood--the-xyz-vs-relay-cost-comparison)
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

- [ ] **Sum tokens:** total `tokens_in`/`tokens_out` across the run and per agent.
      *Observable:* `tick analyze --format json` includes `cost.tokens_total` and `cost.tokens_by_agent`.
- [ ] **Wall-clock:** report total run-window (already exists) PLUS per-task durations and a per-agent
      active-time total.
      *Observable:* json output includes `cost.walltime_by_task` with one entry per completed task.
- [ ] **Human-minutes:** sum `cost.human` events into `cost.human_minutes_total`.
      *Observable:* json shows the operator-entered total; absent input → `0`, never null.
- [ ] **Cost-per-unit-of-work:** divide each cost by the run's output denominator (files touched,
      passing tests, tasks done) → `cost.tokens_per_task`, `cost.tokens_per_done`, `cost.walltime_per_done`.
      *Observable:* json shows the ratios; denominator of 0 reports `n/a`, never divide-by-zero.
- [ ] **Render in human + md:** add a `## Cost` block to the `--write` markdown section alongside the
      existing auto-analyzed coordination block.
      *Observable:* `tick analyze --write <file>` adds a Cost section without disturbing the existing one.
- [ ] **Structured JSON log (folds in ROADMAP Phase 4 R4):** the json format is the SIEM-ingestible
      timestamped record; note this closes/advances R4. Include a `run_type: symmetric | asymmetric`
      flag so downstream scripts never blind-compare an asymmetric run as head-to-head _(Gemini r1 [Nit])_.
      *Observable:* json validates against a one-line schema check and carries `run_type`.
- [ ] **Loud partial signal:** when token coverage is incomplete, the cost total renders as a FLOOR,
      not an exact sum — the human/md output says `tokens: ≥N (partial: 2/3 tasks instrumented)` so a
      reader never mistakes a floor for the truth _(Gemini r1 [Should])_.
      *Observable:* a run with one uninstrumented task prints the `≥`/`partial` marker, not a bare number.

### QA checklist — Phase 2

- [ ] **DRY:** cost rendering reuses the existing format dispatch (human/md/json), not a parallel printer.
- [ ] **SOLID (open/closed):** adding cost is additive — no edits to the concurrency/parked-claim functions.
- [ ] **Observability:** json is the source of truth; human/md are views over it.
- [ ] **Determinism litmus:** same events in → identical cost out, across two runs and two machines.
- [ ] **Edge cases:** zero cost events (old runs) → cost section renders zeros/`n/a`, never crashes.
- [ ] **No-silent-cap:** if any task is missing a token signal, the report SAYS so (e.g. "tokens: partial,
      2/3 tasks instrumented") rather than silently summing an undercount.
- [ ] **Anti-goal check:** still no LLM call anywhere in `analyze.js`.

---

## Phase 3 — Dogfood + the xyz-vs-relay cost comparison

**Intent:** run BOTH systems on the same fixture, capture cost via Phases 1–2, and produce the one
artifact the feedback doc was missing: an honest cost-per-unit comparison of xyz vs relay.

### Checklist (each item is observable)

- [ ] **xyz run with cost on:** run a 2-lane xyz build on a fixture; confirm `cost.tokens` + walltime captured.
      *Observable:* `tick analyze` for that run shows non-zero `cost.tokens_total` and per-task walltime.
- [ ] **relay run with cost on:** run a relay (this very review, or a fresh fixture) with the same capture.
      *Observable:* the relay run's events include `cost.tokens` from each turn-taker.
- [ ] **Operator logs human-minutes for both** via `tick cost --human-minutes`.
      *Observable:* both runs show a non-zero `cost.human_minutes_total`.
- [ ] **DETERMINISTIC transcript write (the reminder you flagged):** after each headless turn, a SCRIPTED
      step copies the temp transcript into `relay-system/<YYYY-MM-DD>/<slug>.<agent>-transcript.md`.
      This must be a script line in the relay driver / dogfood runner — NOT a prompt instruction to the
      agent (agents forget in headless mode, and the safety guard deletes in-tree logs anyway).
      *Observable:* after the run, the transcript file exists under `relay-system/<date>/` and is committed.
- [ ] **Comparison report:** write `experiments/coordination-layer/COST-COMPARISON.md` with a table:
      system × {tokens, wall-clock, human-min, files, passing tests, tokens/done, walltime/done}.
      *Observable:* the file exists, every cell filled from analyzer json (no hand-typed numbers).
- [ ] **Update the feedback doc:** add the cost numbers under its "Cross-system takeaway", closing point 5.
      *Observable:* `FEEDBACK-2026-06-15.md` cites real cost-per-unit figures, not "not measured".

### QA checklist — Phase 3

- [ ] **DRY:** the transcript-copy step lives in the driver once; both `gemini-turn`/`codex-turn` inherit it.
- [ ] **SOLID:** the comparison report is generated FROM analyzer json; no metric is recomputed by hand.
- [ ] **Observability:** every number in COST-COMPARISON.md is traceable to a json field + a run id.
- [ ] **Apples-to-apples caveat (load-bearing):** the report must state that xyz ran the independent
      halves and relay ran the coupled piece — they are NOT the same difficulty of work, so cost
      compares the SYSTEMS-on-their-fit-work, not a head-to-head on identical tasks.
- [ ] **Determinism litmus:** regenerating the report from the same events yields the same numbers.
- [ ] **No-silent-cap:** if a transcript copy fails, the run reports it (don't claim "transcript saved"
      when the file is absent).
- [ ] **Reversibility:** the comparison doc + transcripts are additive files; nothing destructive.

---

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
