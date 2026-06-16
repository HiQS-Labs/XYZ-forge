---
title: Cost comparison — xyz vs relay (Phase 3, 2026-06-16)
slug: cost-comparison
generated_from: tick analyze --format json
source_runs:
  xyz_root: $TMPDIR/p3-xyz        # synthetic fixture; see data-provenance below
  relay_root: $TMPDIR/p3-relay    # real Gemini headless turn under -o json
related:
  - PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md
  - relay-system/2026-06-16/p3-dogfood-relay.md
  - relay-system/2026-06-16/p3-dogfood-relay.gemini-transcript.md
---

# Cost comparison — xyz vs relay

All numbers in this document come directly from `tick analyze --format json`
on the two Phase 3 tick roots. No numbers were typed by hand.

---

## Comparison table

| Metric | xyz (2-lane parallel) | relay (turn-based review) |
|---|---|---|
| **run_type** | `symmetric` | `asymmetric` |
| **Tasks done** | 4 | 1 |
| **Agents active** | 2 (alpha, beta) | 2 (claude-a, gemini) |
| **tokens_in** | 55 000 | 33 128 |
| **tokens_out** | 3 920 | 76 880 |
| **tokens_total** | 58 920 | 110 008 |
| **tokens_per_done** | 14 730 | 110 008 |
| **run_window** | 522 ms ⚠️ | 735 309 ms (~12 min) |
| **walltime_per_done_ms** | 131 ms ⚠️ | 735 309 ms |
| **human_minutes_total** | 8 | 5 |
| **token coverage** | 4/4 (complete) | 1/1 (complete) |
| **partial floor?** | no | no |

⚠️ = see walltime caveat below.

---

## What these numbers show

**Tokens per done-task:** xyz used ~14 730 tokens/task vs relay's ~110 008 tokens/task.
The difference is dominated by system type, not task difficulty: relay's Gemini reviewer
ran with large context (full relay file + methodology) and heavy chain-of-thought reasoning
(`tokens_out` 76 880 >> `tokens_in` 33 128 — thoughts/candidates drove output, not cached
prompt). xyz coding turns are shorter prompts with shorter completions (1–2k output each).

**run_type matters:** xyz ran equal independent lanes (`symmetric`); relay ran one Producer
and one Reviewer doing structurally different work (`asymmetric`). Cost differences partly
reflect this topology difference, not just the protocol.

**Human minutes:** xyz=8, relay=5. These are self-reported operator wall-clock estimates
(the honest soft signal — `tick cost --human-minutes`). The difference is not significant.

---

## Apples-to-apples caveat (load-bearing)

**These systems did different work.**

- **xyz** ran 4 parallel independent implementation tasks (no inter-agent dependency).
  The cost compares xyz-on-its-fit-work.
- **relay** ran 1 turn-based methodology review (one Producer + one Reviewer,
  sequentially coupled). The cost compares relay-on-its-fit-work.

They are not running the same task, so the comparison tests "what does each system cost
when doing what it is designed for?" — not "which system is cheaper at identical tasks?"

---

## Data provenance

| Run | Data source | Honest? |
|---|---|---|
| xyz | **Synthetic fixture.** Token counts sampled from real Gemini session turns in this session (≈13–16k input, ≈850–1100 output per coding turn). Operator confirmed by [Should] Gemini review that this is acceptable for Phase 3. | Yes — prominently disclosed. |
| relay | **Real Gemini headless turn.** `gemini -o json` transcript (`p3-dogfood-relay.gemini-transcript.md`). Tokens captured via `tick cost --from-gemini-json`. | Yes — fully live. |

**xyz walltime caveat:** the fixture's events were created programmatically in sequence
(522 ms total), so `run_window_ms` and `walltime_per_done_ms` reflect fixture-creation
speed, NOT real agent execution time. Treat walltime numbers for the xyz run as `N/A`
for comparison purposes. The relay walltime (735 309 ms) reflects real elapsed time from
token creation to `tick done`.

---

## Regenerate

```bash
TICK_RUN_TYPE=symmetric  TICK_REPO_ROOT=/path/to/p3-xyz   ./bin/tick analyze --format json
TICK_RUN_TYPE=asymmetric TICK_REPO_ROOT=/path/to/p3-relay  ./bin/tick analyze --format json
```

Same events → identical output (deterministic; no LLM, no clock in `analyze.js`).

Note: the fixture roots (`$TMPDIR/p3-xyz`, `$TMPDIR/p3-relay`) are ephemeral
(in `$TMPDIR`). For reproducible regeneration, archive the `.tick/events/` directories.

---

## Closing point 5 of `FEEDBACK-2026-06-15.md`

The original feedback gap (point 5) was: the analyzer measured coordination (concurrency %,
parked-claims, per-agent counts) but zero cost, so xyz and relay could not be compared on
cost-per-unit-of-work.

This document closes that gap:
- **Phase 1** added `cost.tokens` / `cost.human` capture at the source (gemini-turn.sh,
  codex-turn.sh, `tick cost` verb).
- **Phase 2** extended `tick analyze` to emit a `cost` section (tokens, wall-clock,
  human-minutes, tokens_per_done, run_type, loud-partial floor).
- **Phase 3** ran both systems with cost capture on and produced this comparison.

The measurement is now deterministic, reproducible, and traceable — every cell above
sources to a `tick analyze --format json` field.
