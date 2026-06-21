---
title: Cost observability for coordination systems (xyz + relay)
slug: cost-observability-plan
status: Draft — awaiting relay review
owner: Noel (operator) · Claude (producer)
created: 2026-06-15
updated: 2026-06-20
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

| What was just completed | What's next |
|---|---|
| **Phase 3 — Dogfood + cost comparison** ✅ shipped: real Gemini relay run with `-o json` cost capture validated end-to-end (preamble-skip fix in `parseGeminiStats`); synthetic xyz fixture + real relay run analyzed; `COST-COMPARISON.md` generated from `tick analyze --format json`; `FEEDBACK-2026-06-15.md` point 5 closed. `cost.sh` **24/24**; full suite **22/22**. | **Done — all three phases shipped** |

## Table of contents

- [Phase 1 — Capture raw cost signals at the source](#phase-1--capture-raw-cost-signals-at-the-source)
- [Phase 2 — Extend the deterministic analyzer to compute cost](#phase-2--extend-the-deterministic-analyzer-to-compute-cost)
- [Phase 3 — Dogfood + the xyz-vs-relay cost comparison](#phase-3--dogfood--the-xyz-vs-relay-cost-comparison)
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
- [x] **Comparison report:** `PROJECT/2-WORKING/COST-COMPARISON.md` — table: system × {tokens, wall-clock,
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

## Deferred / backlog

Items consciously NOT done, so they don't masquerade as covered. Each says why + what unblocks it.

- [ ] **Codex token capture** — no `parseCodexStats` yet; the Codex CLI's usage/stats output format
      isn't probed. `codex-turn.sh` already persists its transcript, so the data exists to parse later.
      *Unblocks when:* someone runs `codex exec` and inspects its end-of-turn usage block (mirror of the
      `gemini -o json` probe). Until then Codex turns are a known token gap (Phase 2 renders it as partial).
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
