---
title: Marathon Plan F (2026-07-07) — validate.sh's 9 pre-existing failing tests
status: Lanes 1-9 STALE as of 2026-07-17 (all 9 tests currently pass — see Status); only Lanes
  10-11 are fireable. Recommend closing #170 pending operator confirmation.
created: 2026-07-07
updated: 2026-07-17
owner: noel
branch: main
doc_type: project
source: triaged 2026-07-07 during GH-158/161/162/164 housekeeping pass, when validate.sh's
  pre-existing 9 failures were confirmed (again) to be unrelated to that day's merges
generated_by: hand-authored (9 lanes under one umbrella issue, same-day triage, not ledger-ranked;
  Lane 10 added same day after live-reviewing GH-171's fix; Lane 11 added 2026-07-17 as a GH-172
  follow-up)
lanes: [174, 215]
execution: parallel Sonnet subagents, one per lane — independent write-sets, no builder/reviewer
  relay needed for any single lane
roadmap_exempt: true
goal: >
  Nine independent lanes, one per currently-failing validate.sh gate, all tracked under a single
  umbrella issue (#170) since none were substantial enough alone to warrant their own GH issue, but
  collectively are 9 real, independent, parallel-safe fixes. Two (analyze.sh, relay-token-
  collision.sh) are confirmed flaky and need multi-run verification, not just one green pass; the
  other seven are deterministic single- or few-assertion bugs in unrelated files. Lane 10 (#174) was
  added the same day: a Bash/Python parity gap found while reviewing GH-171's fix live — agy-turn.py
  never got the claim-before-launch guard agy-turn.sh just gained. Lane 10 was re-scoped 2026-07-17:
  the guard itself already landed via GH-172's Phase 0 audit (commit 7e9e683), so only the missing
  dedicated regression test remains. Lane 11 (#215) was added the same day: GH-172's cutover
  recommendation named one residual Bash/Python parity gap (utils/py/consult.py's missing
  degraded-panel stamping) as the sole blocker to a Python-default main cutover. **2026-07-17: Lanes
  1-9 (#170) found STALE** while building this doc's Swarm Preflight Contract — all 9 tests now
  pass, root cause of the flip unconfirmed; not fireable pending operator review of #170.
---

# Marathon Plan F — 2026-07-07 · validate.sh's 9 pre-existing failing tests

> Sibling of [Plan D](MARATHON-PLAN-2026-07-07-D-EXPLORE-IDEAS.md) and
> [Plan E](MARATHON-PLAN-2026-07-07-E-BUILD.md), but a different shape: all 11 lanes here fix
> **pre-existing test failures / coverage gaps**, not new features — the deliverable per lane is a
> passing `test/<file>.sh` plus (for the two flaky lanes) proof across repeated runs, not just one.
> Lanes 1-9 came from same-day triage of `validate.sh`'s red gates; Lane 10 was added same day after
> live-reviewing a real production fix (GH-171) surfaced a Bash/Python parity gap, then re-scoped
> 2026-07-17 once its code fix landed via GH-172; Lane 11 was added 2026-07-17 as a direct GH-172
> cutover-recommendation follow-up. **2026-07-17: Lanes 1-9 found STALE — see Status below. Only
> Lanes 10-11 are currently fireable.**

## Status

| What was just completed | What's next |
|---|---|
| All 9 failures triaged 2026-07-07 to concrete failure signatures, filed under umbrella issue [#170](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/170), doc authored with a fix direction per lane. Separately, GH-171 (a real production no-progress bug, found live in sleuth-app's marathon) was root-caused and fixed same day (branch `fix/gh-171-chain-root-cause`, commit `b00ee48`, independently verified: 60/0 on `test/marathon-drive.sh` incl. its new GH-171 regression, zero regressions across `codex-turn`/`agy-turn`/`aider-turn`/`claude-turn`) — reviewing it surfaced one parity gap, filed as [#174](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/174) and added here as Lane 10. **2026-07-17:** GH-172's own root-semantics audit marathon landed Lane 10's actual code fix as a side effect (commit `7e9e683`) — confirmed live, `claim_task_or_exit` is already called in `utils/py/agy-turn.py`; #174 re-scoped to just the missing dedicated regression test (not closed, per its own unmet checklist item). GH-172's cutover recommendation also named one residual parity gap (`utils/py/consult.py` degraded-panel stamping) as the sole Python-default-cutover blocker — filed as [#215](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/215) and added here as Lane 11. **Also 2026-07-17:** building this doc's + GH-170's Swarm Preflight Contracts surfaced that `swarm-preflight.sh --gh-issue 170` returns **STALE (exit 4)**. Independently re-ran all 9 Lane 1-9 test files directly (plus 5x repeats each for the two confirmed-flaky Lanes 1/5): **all 9 currently PASS**. Full `bash validate.sh` confirms only the pre-existing `#208` (`worktree-isolation.sh`) gate is red — every one of GH-170's original 9 gates is green repo-wide. Root cause of the flip is **not confirmed** (no code change in this repo explains it, unlike Lane 10's exact-commit fix) — most plausible: an unrelated upstream fix, or environment drift since 2026-07-07 (Lane 7's own triage already flagged device-state sensitivity). | **Lanes 1-9 are not fireable** — recommend closing #170 as stale, flagged to the operator rather than closed unilaterally since the "why" is unconfirmed; re-open with fresh triage if it flips red again. **Fire Lanes 10-11 only** — each is scoped to its own test/source file, no shared write-set. |

## Why this cluster, why now

`validate.sh` has carried these 9 red gates for a while — confirmed pre-existing via two
independent checks today (a parent-commit worktree comparison during the GH-165 review, and a
`git stash` comparison during the GH-158/161/162/164 housekeeping pass). None are urgent/blocking
anything, but they've been accumulating as untracked debt with no issue or plan behind them. This
plan captures and rates all 9 in one pass so they can be picked up as a normal marathon cluster
instead of staying invisible.

## The one safety rule

Two lanes are safe to run concurrently **iff their write-sets are disjoint**. Each lane here targets
a different, unrelated test file and (as far as triage could tell without doing the actual fix) a
different source area — see the collision map below.

## Collision map

| Zone (shared file) | Parallel-safe? | Lane |
|---|---|---|
| `test/analyze.sh` (+ its source) | ⏸ STALE — do not fire | Lane 1 |
| `test/cost.sh` (+ its source) | ⏸ STALE — do not fire | Lane 2 |
| `test/watchdog-relay.sh` (+ its source) | ⏸ STALE — do not fire | Lane 3 |
| `test/deep-research.sh` (+ its fixture) | ⏸ STALE — do not fire | Lane 4 |
| `test/relay-token-collision.sh` (+ its fixture) | ⏸ STALE — do not fire | Lane 5 |
| `test/new-relay.sh` (+ its source/assertion) | ⏸ STALE — do not fire | Lane 6 |
| `test/find-harness.sh` (+ its source) | ⏸ STALE — do not fire | Lane 7 |
| `test/transcript-audit.sh` (+ its source) | ⏸ STALE — do not fire | Lane 8 |
| `test/marathon-plan.sh` (+ `utils/marathon-plan.sh`) | ⏸ STALE — do not fire | Lane 9 |
| `test/marathon-drive.sh` (test-only; source already fixed) | ✅ fireable, only one lane touches this | Lane 10 |
| `utils/py/consult.py` (+ its test) | ✅ fireable, only one lane touches this | Lane 11 |
| independent | ✅ parallel (Lanes 10-11 only) | — |

Lanes 1-9 are STALE as of 2026-07-17 (see Status) — do not fire without re-triaging against #170
first. Lane 10 is test-only (`test/marathon-drive.sh`) since its source fix already landed via
GH-172. **Lane 11 is the one file worth flagging**: `utils/py/consult.py` is a turn-taker/advisor
shim (zone `shim`, not `kernel`), but it should still run alone relative to any *other*
consult.py-touching work if one ever gets added to this plan later.

## Per-lane summary

| # | Test file | Symptom | Class | cx/risk/eff | Fireable? |
|---|-----------|---------|-------|-------------|---|
| 1 | `test/analyze.sh` | SIGPIPE flake, same family as GH-133 | flaky | 2/1/1 | ⏸ STALE 2026-07-17 |
| 2 | `test/cost.sh` | cost-only agent leaks into `agents[]` | deterministic | 2/1/2 | ⏸ STALE 2026-07-17 |
| 3 | `test/watchdog-relay.sh` | self-generated analysis JSON malformed | deterministic | 2/2/2 | ⏸ STALE 2026-07-17 |
| 4 | `test/deep-research.sh` | fixture missing `searchContextSize` | deterministic | 1/1/1 | ⏸ STALE 2026-07-17 |
| 5 | `test/relay-token-collision.sh` | fixture task-name collision | flaky | 2/1/2 | ⏸ STALE 2026-07-17 |
| 6 | `test/new-relay.sh` | possible stale assertion vs. real template | deterministic | 1/1/1 | ⏸ STALE 2026-07-17 |
| 7 | `test/find-harness.sh` | 2 failures, possible env-sensitivity | deterministic | 2/2/2 | ⏸ STALE 2026-07-17 |
| 8 | `test/transcript-audit.sh` | stale-ref output/assertion mismatch | deterministic | 1/1/1 | ⏸ STALE 2026-07-17 |
| 9 | `test/marathon-plan.sh` | 4 assertions, 1 shared root cause in "B:" scenario | deterministic | 2/2/2 | ⏸ STALE 2026-07-17 |
| 10 | `test/marathon-drive.sh` (test-only) | GH-171 vendored-consumer fixture never got an `XYZ_PYTHON=1` agy-leg case; source fix already landed (GH-172) | deterministic (test-coverage gap) | 1/1/1 | ✅ ready |
| 11 | `utils/py/consult.py` (+ test) | Python consult port missing the Bash degraded-panel `SINGLE-MODEL — NOT RECONCILED` stamping | deterministic (parity gap) | 2/1/2 | ✅ ready |

Full diagnostic detail (exact failure output, fix direction per lane) lives in
[GH-170's doc](GH-170-VALIDATE-FAILING-TESTS.md#findings-2026-07-07-triage) for Lanes 1-9,
[GH-174's doc](GH-174-AGY-PY-CLAIM-GUARD.md) for Lane 10 (re-scoped 2026-07-17 — read the Status
table there first, the original checklist's item 1 is already done), and
[#215](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/215) /
[GH-172-CUTOVER-RECOMMENDATION.md](../3-COMPLETED/GH-172-CUTOVER-RECOMMENDATION.md) for Lane 11 — each lane should
read its own section before starting.

## Recommended waves

**Wave 1 — parallel (2 fireable lanes ‖):** Lane 10 ‖ Lane 11

Lanes 1-9 are STALE (see Status) and excluded from firing until #170 is re-triaged or closed. No
kernel track. No lane blocks another.

## Execution contract

- **Path:** each fireable lane runs as a worktree-isolated Sonnet subagent (or a codex/agy relay via
  `marathon-drive.sh` — either execution path is fine, `swarm-preflight.sh` doesn't assume one),
  scoped via `ALLOW_PATHS`/artifact allowlist to its own test file plus whatever source file its
  root cause lives in.
- **Per lane:** root-cause the failure, land the fix with the test passing, and leave a one-line
  status update in this doc's own Status table (or the lane's own capture doc's Status table).
- **Lanes 1-9 are STALE as of 2026-07-17 — do not fire.** `swarm-preflight.sh --gh-issue 170`
  returns exit 4; all 9 tests independently re-verified passing (including 5x repeats for the two
  flaky lanes). See GH-170's own doc Status table for the full evidence trail. If any of these 9
  flips red again, re-triage it fresh rather than reusing this stale scoping.
- **Rated:** all 11 lanes carry provisional cx/risk/eff (`ratings_provisional: true` in all three
  source docs) — same-day triage/discovery (Lanes 1-10) or direct cutover-recommendation follow-up
  (Lane 11), not yet validated against `pdda.sh doc-ready`.
- **Lane 10 is now test-only** — the claim-before-launch guard itself already landed in
  `utils/py/agy-turn.py` via GH-172's Phase 0 (commit `7e9e683`); the only remaining work is
  extending the GH-171 vendored-consumer regression fixture in `test/marathon-drive.sh` to cover the
  agy (reviewer) leg under `XYZ_PYTHON=1`, mirroring the existing codex-leg assertion. Do not
  re-touch `utils/py/agy-turn.py` for this lane — the source fix needs no further work.
- **Lane 11 is a direct port of an already-verified pattern**, not new design — mirror
  `relay-automation/consult.sh`'s existing degraded-panel `SINGLE-MODEL — NOT RECONCILED` stamping
  logic into `utils/py/consult.py`. Do not re-touch the tick-root/cost-routing fix GH-172 already
  landed in this same file.

## How to fire

Only Lanes 10-11 are ready. **Do not run `--gh-issue 170`** for a real fire — it returns
STALE/exit 4 by design (fix not required); reusing it anyway would waste a build turn against
already-passing tests. Confirmed via `--dry-run` on 2026-07-17 for all three:

```
utils/swarm-preflight.sh --gh-issue 174 --dry-run   # ready (exit 0)
utils/swarm-preflight.sh --gh-issue 215 --dry-run   # ready (exit 0)
   → ready packet (candidate/freshness/fix-still-required + lane assignment)
relay-automation/marathon-drive.sh ...   # build→gate→review, contained, one invocation per lane
```

After Lanes 10-11 land: re-run full `validate.sh` and confirm only the pre-existing `#208`
(`worktree-isolation.sh`) gate remains red (same discipline as every other marathon in this repo).
Resolve #170 (close or re-triage) separately — it is not part of this fire.

---

*Source docs:* [GH-170](GH-170-VALIDATE-FAILING-TESTS.md) ·
[GH-174](GH-174-AGY-PY-CLAIM-GUARD.md) ·
[#215](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/215) ·
siblings: [Plan D](MARATHON-PLAN-2026-07-07-D-EXPLORE-IDEAS.md) ·
[Plan E](MARATHON-PLAN-2026-07-07-E-BUILD.md).
