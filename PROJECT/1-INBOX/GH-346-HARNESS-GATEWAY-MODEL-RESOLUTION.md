---
title: Harness -> gateway -> model resolution is ten hand-maintained allowlists and three re-derived lookups
status: Proposed (1-INBOX — not yet active)
created: 2026-08-31
updated: 2026-08-31
owner: noel
gh_issue: 346
source: https://github.com/HiQS-Labs/XYZ-forge/issues/346
plan_comment: https://github.com/HiQS-Labs/XYZ-forge/issues/346#issuecomment-5481741819
doc_type: bugfix
complexity: 3
risk: 2
effort: 3
phases: 4
ratings_provisional: true
reported_from: aegis-sleuth-slack-bot
harness_commit: 6dd7073
non_goals:
  - Rewriting any turn-taker shim's execution or safety logic (path allowlist, commit-bypass guard,
    worktree isolation). None of that was the friction; the failure surface is the lookup path
    before and around a turn.
  - Merging the OpenRouter alias table with CommandCode's live catalog (original "proposal C").
    Superseded — the recon pass found `device_config.py`'s resolver, not the catalogs, is the real
    unification seam. That work is Phase 3 and needs its own design pass.
related:
  - GH-308 (froze the bash `marathon-drive.sh` lane; allowlist #1 is only reachable via XYZ_PYTHON=0)
  - GH-32 (the RELEASES DB CLI — same "one CLI, one ledger" shape this issue wants for gateways)
goal: >
  Adding or selecting a gateway stops being ten independent hand-maintained allowlists and three
  re-derived per-session lookups, and `harnesses.db` stops recording a model that did not run.
  Phase 0-2 fix confirmed bugs; Phase 3 is gated behind a measured ROI checkpoint.
---

# GH-346 — the lookup path before a turn, not the turn

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Why

Driving `relay-xyz` against a vendored `.xyz/` install, the harness worked correctly every time.
Getting *to* it did not. Three frictions, reproduced independently on a second run
([comment 5481238606](https://github.com/HiQS-Labs/XYZ-forge/issues/346#issuecomment-5481238606)
with a `deepseek-turn.sh` drive):

1. **`find-harness.sh` has no memory across invocations.** `locate → eval --env → cd` ran a
   dozen-plus times in one session because `$HARNESS`/`$TICK` are plain env vars that do not
   survive into the next shell. Each run also re-does the vendored-vs-live diff unconditionally.
2. **Picking a gateway means reading source.** Each shim has a bespoke env contract
   (`AGY_AGENT` vs `CODEX_AGENT` vs `DEEPSEEK_AGENT`; `AGY_MODEL` vs `AIDER_MODEL` vs
   `DEEPSEEK_MODEL`). Nothing is queryable. The strongest evidence: **this issue's own gateway
   list omitted `deepseek-turn`, a shipped, working gateway** — when a careful issue about
   discovery misses a gateway, the lookup surface has to be generated, not curated.
3. **Two disjoint, non-cached model catalogs.** The static `openrouter-model-aliases.yml` (fuzzy,
   OpenRouter lane only) and CommandCode's live `cmd --list-models`. `deepseek/deepseek-v4-pro`
   exists in both, and is *also* hardcoded as `deepseek-turn.py`'s own default — the same slug
   maintained in three places across two layers.

Then the recon pass against live HEAD found the picture is bigger, and found bugs the efficiency
ask never mentioned.

## Key concepts

- **There are 10 independent agent-id allowlists, not 2 and not the 6 the recon found.** The
  recon's table (`file:line`, reachability) is in the
  [plan comment](https://github.com/HiQS-Labs/XYZ-forge/issues/346#issuecomment-5481741819); the
  corrected table of ten is below under *What shipped*.
- **Allowlist #3 (`marathon-agent.sh:35-64`) is the real functional blocker.** It is the `case`
  the `--agent-cmd` dispatcher actually hands off to, keyed on which `*_AGENT` var is set, with no
  branch for deepseek or commandcode. **A fix that only touches `route_agent()` ships something
  that still silently cannot run.**
- **`harnesses.db` is write-only, not a registry.** `HarnessTurnLogger` only writes; the only
  `SELECT`s in the tree are `harness_app.py`'s own report subcommands. An earlier draft proposed
  pointing dispatch at it as "reuse" — that was wrong, it would be new plumbing. Falsified before
  acceptance.
- **The half-built thing that *is* live is `device_config.py`'s 3-tier resolver**
  (env → `~/.xyz/device_config.json` → `GLOBAL_DEFAULTS`). All 7 Python shims already build a
  `HarnessTurnLogger` from it — but only for the telemetry record, never for the `--model` flag
  each shim constructs independently. That split is the real unification target, and it is Phase 3.
- **Model-telemetry drift — the count below is SUPERSEDED; see the CORRECTION section.** QA found
  three of these shims never wrote a row at all (NameError, silently swallowed), so only **two**
  live wrong-model bugs existed. Left in place as the pre-QA reasoning, not as the record:
  `claude-turn.py:97` dispatches `claude-sonnet-4-6` while `:269` logs `anthropic/claude-3-7-sonnet`;
  `commandcode-turn.py:58` dispatches `meta/muse-spark-1.2-contributor` while `:128` logs
  `Qwen/Qwen3.8-Max`; `aider-turn.py:62/64` dispatches one of two values while `:270` logs a third.
  ~~`harnesses.db` records the wrong model for 5 of 8 gateways~~ — **wrong, see CORRECTION**: two
  gateways logged a wrong model, three logged nothing. agy and codex pass no `--model` at all when
  unset, so the slug they logged was chosen by nothing.
- **Safety net worth preserving explicitly.** Both `route_agent()` twins reject an unrecognized id
  with **exit 2 before any tick or worktree mutation**, so a routing mistake cannot leave stuck
  state. Whatever replaces the 10 allowlists must keep that invariant, and Phase 2 tests it.
- **Allowlist #6 has a phantom, in two copies.** `bin/marathon-yaml:95-96` AND
  `src/marathon-yaml.js:114` list `gemini` as reviewer-eligible. No such shim exists anywhere in
  the tree, and `route_agent` — which runs first — has no gemini branch, so it was unreachable.

## CORRECTION after QA — the Phase 0 record was wrong, and worse than stated

QA on this branch (GLM 5.3 via Command Code, `relay-system/2026-08-31/gh346-phase0-2-qa.md`)
returned **changes requested** and was right. What it found, verified independently before acting:

**Three shims' telemetry was DEAD CODE, and had been for their whole life.**
`claude-turn.py`, `aider-turn.py` and `codex-turn.py` each passed an **undefined name** as
`cli_flags` (`cflags`, `aflags`, `flags` — bound nowhere in their files). Evaluating the argument
raised `NameError` *inside* the `HarnessTurnLogger(...)` call, and the block's own
`except Exception: pass` swallowed it. Those gateways wrote **no telemetry row at all, on any
turn** — not a wrong row, no row.

So the earlier claim in this doc and in commit `86fa1906` — "harnesses.db records the wrong model
for 5 of 8 gateways" — **described code that never executed**. (The denominator was wrong as well:
`utils/py/*-turn.py` is *seven* shims, not eight — caught in QA round 2 on the Phase 3 spec. Both
halves of a nine-word claim were false, which is what a claim written from memory rather than from
the tree looks like.) The honest record:

| Gateway | What actually happened before this work |
|---|---|
| claude, aider, codex | wrote NOTHING — NameError, silently swallowed |
| commandcode, agy | wrote a real row with the WRONG model (the live bug, 2 gateways) |
| dsh (deepseek), pi | wrote a correct row |

Two live wrong-model bugs, not five — and three gateways with **no audit trail at all**, which for
a telemetry system is the worse defect. Phase 0's edits to those three were correct but unreachable
until the names were fixed.

**Checkbox 0.5 was ticked without being performed.** "A fresh harnesses.db row per touched gateway
shows the right model" was never run — no test in the tree exercised a shim with logging enabled,
and the Phase 0 suite was AST-static. That is the process defect, and it is exactly what let dead
code look fixed. It is now discharged by `test/gh346-telemetry-row-written.sh`, which enables
logging against a scratch DB and asserts a row lands per gateway carrying the dispatched model.

**A second silent swallow, found while fixing the first.** `HarnessTurnLogger` ran `harness_app.py`
with `check=False` and never inspected the return code, so a failed INSERT (e.g. `FOREIGN KEY
constraint failed` on an unseeded DB) also produced no row and no message. Both swallows now log to
stderr and stay non-fatal.

**Standing caveat on agy/codex (raised by QA, accepted).** With the model var unset these two pass
no `--model` at all, so the row now records `device_config`'s **declared** default — better
provenance than an invented literal, and the single source Phase 3 will converge with dispatch, but
it is still *declared, not dispatched*. Do not read it as "the model that ran" until Phase 3.

## What shipped, and how it departed from the plan

Phases 0–2 are implemented on branch `gh346-model-resolution`. Three departures, each deliberate:

1. **Phase 0 covered 6 shims, not 3.** `agy-turn.py:621` and `codex-turn.py:143` had the same bug
   in a worse form — neither shim passes `--model` at all when the env var is unset (agy gates the
   flag at `:383`; codex never sets one), yet both logged a hardcoded slug. So they were recording a
   model *nothing* selected. `pi-turn.py:198` had an unreachable `"pi-native"` default contradicting
   its own GH-295 refuse-to-guess contract. **The issue's "3 of 8" is wrong, but so was my "5 of 8"
   — see the CORRECTION section: two wrote a wrong model, three wrote nothing at all.**
   agy/codex now pass `None`, which `harness_turn_logger.py` resolves through `device_config` —
   a real declared default instead of an invented one.
2. **`aider-turn.py`'s `gateway` was fixed too**, not just its `model_id`: it logged `openrouter`
   even on the LM Studio seam. Same bug, same call, one argument over. (`harnesses.db` declares
   `gateway TEXT NOT NULL` with no CHECK, so the new value is safe.)
3. **The allowlist count is TEN, not six.** See below.

### The allowlist count was wrong, and that is the finding

| # | Site | Found by |
|---|---|---|
| 1 | `relay-automation/marathon-drive.sh:777` (frozen twin) | recon |
| 2 | `marathon_drive.py` `route_agent` | recon |
| 3 | `relay-automation/marathon-agent.sh` dispatcher | recon — **the functional blocker** |
| 4 | `marathon_drive.py` `_probe_agent_bin` | recon |
| 5 | `marathon_drive.py` `*_TURN_ROOT` tuple | recon |
| 6 | `bin/marathon-yaml:95` reviewer gate | recon |
| 7 | `src/marathon-yaml.js:114` reviewer gate (2nd copy) | reading, this session |
| 8 | `utils/py/gate_env.py` `HARNESS_ENV` registry | **`test/gh441-gate-env-contract.sh` failing** |
| 9 | `marathon_drive.py` `*_AGENT` reset block | **`test/gh441` failing** |
| 10 | `marathon_drive.py` `GATE_SCRUBBED_ENV` literal | **`test/gh441` failing** |

Three of ten sites were invisible to a careful manual pass and were caught only because an existing
deterministic test refused to go green. That is the strongest argument yet for the issue's
proposal B — **generate the lookup surface from the shims rather than curating it** — stronger than
anything in the issue body, because it is now a measured miss rate rather than an anecdote.

## Phased plan

Checkbox source of truth is the
[plan comment](https://github.com/HiQS-Labs/XYZ-forge/issues/346#issuecomment-5481741819); this
doc mirrors it. Tick both, or tick the comment and re-sync here on promotion to `2-WORKING`.

### Phase 0 — data integrity (do first, smallest diff of all)

Pass the already-resolved local dispatch variable into `HarnessTurnLogger` instead of re-reading
the env var with a second hardcoded default. Three one-line changes, no design needed.

- [x] **0.1** `claude-turn.py:269` — log the dispatch value resolved at `:97`, drop the second hardcoded `anthropic/claude-3-7-sonnet`
- [x] **0.2** `commandcode-turn.py:128` — log the dispatch value resolved at `:58`, drop the hardcoded `Qwen/Qwen3.8-Max`
- [x] **0.3** `aider-turn.py:270` — log the value that actually ran (`:62/64`), drop the third independent default
- [x] **0.4** One regression test asserting telemetry model == dispatch model **for the five shims that
      pass an explicit model** (`claude`, `commandcode`, `aider`, `deepseek`, `pi`; the gateway
      column is asserted on all seven), with the `*_MODEL` var unset
      — **scoped after QA round 2 on the Phase 3 spec.** As first written this said "each shim", and
      that was untrue for two of the seven. `agy-turn.py:626` and `codex-turn.py:146` pass
      `os.environ.get("*_MODEL") or None`, and `harness_turn_logger.py:36` is
      `self.model_id = model_id or self.cfg["model"]` — so with the var unset the row records
      `device_config`'s `default_model` while agy and codex each run their own internal default.
      Two different models. The work under this box was done and the test is real; the sentence
      claimed more than the test proves, which is why it is scoped rather than unticked. Those two
      gateways are covered by the standing caveat above and close in Phase 3c.
- [x] **0.5** `./validate.sh` green; a fresh `harnesses.db` row per touched gateway shows the right model
      (subject to 0.4's scoping — "the right model" means the dispatched one for the five explicit-model
      shims, and the declared one for agy/codex until Phase 3c)
      — **re-done properly after QA**: was ticked without being performed (see the CORRECTION above).
      Now enforced by `test/gh346-telemetry-row-written.sh`, 8/8 with logging enabled.
- [x] **0.6** (added after QA) Fix the three undefined `cli_flags` names that made claude/aider/codex
      telemetry dead code, and make both swallowed-exception paths log instead of passing silently

### Phase 1 — fault-tolerant resolver call, not a swap

`resolve-model-alias.sh` exits 1 with no output on a miss (pinned by `test/model-alias.sh:43-46`)
and has no canonical-slug passthrough. `utils/py/review_xyz.py:82-94` already has the safe pattern.

- [x] **1.1** Lift the `review_xyz.py:82-94` subprocess-with-fallback pattern into one shared helper
- [x] **1.2** Call it from `deepseek-turn.py:136`; keep the existing literal as the fallback value
- [x] **1.3** Test both branches: alias hit resolves, resolver miss (exit 1, no output) falls through unchanged
- [x] **1.4** Confirm `test/model-alias.sh:43-46`'s pinned exit-1-on-miss contract is untouched

### Phase 2 — close the discovery gap (6 sites, not 2)

- [x] **2.1** Allowlist #3 `marathon-agent.sh:35-64` — add DEEPSEEK/COMMANDCODE branches (**the functional blocker; do this one first**)
- [x] **2.2** Allowlist #2 `marathon_drive.py:1783-1806` — add deepseek/commandcode to `route_agent()`
- [x] **2.3** Allowlist #4 `marathon_drive.py:686-698` — add both to `_probe_agent_bin` so preflight stops silently skipping them
- [x] **2.4** Allowlist #5 `marathon_drive.py:2994-2999` — add `DEEPSEEK_TURN_ROOT` propagation (commandcode already present)
- [x] **2.5** Allowlist #6 `bin/marathon-yaml:95-96` — drop the phantom `gemini` entry; decide deepseek/commandcode reviewer eligibility
- [x] **2.6** Allowlist #1 `marathon-drive.sh:777-785` — decide: match #2, or record explicitly that the frozen bash lane stays behind
- [x] **2.7** Add `RELAY_HAS_DEEPSEEK` / `RELAY_HAS_COMMANDCODE` advisory flags
- [x] **2.8** Add a `deepseek-turn` row to the relay-xyz SKILL.md worker table
- [x] **2.9** One regression test per allowlist asserting an *unrecognized* agent id's exact failure mode
- [x] **2.10** Preserve + test the safety-net invariant: unrecognized id exits 2 before any tick/worktree mutation
- [x] **2.11** End-to-end proof: `marathon_drive.py --dry-run` routes + preflights both lanes; a live
      commandcode dispatch is proven by the QA relay in `relay-system/2026-08-31/gh346-phase0-2-qa.md`
- [x] **2.12** (added) Allowlist #7 `src/marathon-yaml.js:114` — second reviewer-gate copy
- [x] **2.13** (added) Allowlist #8 `utils/py/gate_env.py` — HARNESS_ENV scrub registry
- [x] **2.14** (added) Allowlist #9 `marathon_drive.py` — `*_AGENT` reset block
- [x] **2.15** (added) Allowlist #10 `marathon_drive.py` — `GATE_SCRUBBED_ENV` literal

### ⏸ ROI checkpoint — stop here, measure, then decide on Phase 3

Phase 2 is the first point where the original ask is **measurable**: a real run can dispatch every
shipped gateway, so the resolution path can be timed and counted end-to-end instead of estimated.
Phase 0-2 are all evidence-backed fixes to confirmed bugs. Phase 3 is the only piece that changes
a seam every shim already depends on.

- [ ] Re-run the original friction scenario and record: re-resolutions per session, source-reads needed to pick a gateway, time-to-first-turn
- [ ] Confirm `harnesses.db` telemetry matches dispatch for all **7** gateways (the Phase 0 payoff,
      visible only after real runs). **Stays unticked while Phase 3c is deferred** — agy and codex
      record a declared default, not a dispatched one (see the standing caveat and checkbox 0.4).
      *Count corrected from 8 during QA round 2: `utils/py/*-turn.py` is seven shims — agy, aider,
      claude, codex, commandcode, deepseek, pi. The 8 came from `test/gh346-telemetry-row-written.sh`
      reporting "8 pass", which is 8 assertions (7 gateways + one that the scratch DB was written).*
- [ ] Compare against this issue's baseline; decide **go / no-go / re-scope** on Phase 3 with numbers, not intuition

### Phase 3 — gated: unify dispatch on `device_config.py`'s resolver

- [ ] **3.0** Gated on the ROI checkpoint above — do not start without a go decision
- [ ] **3.1** Design pass: how the 3-tier resolver drives dispatch without breaking the 8 existing `*_MODEL` contracts
- [ ] **3.2** Migration + deprecation path for the per-shim env var names
- [ ] **3.3** Implement behind the resolved fallback pattern from Phase 1

### Parked (not in scope until Phase 0-3 ship)

- [ ] **P.1** `--turn-shape review|build` emitting per-gateway turn defaults
- [ ] **P.2** Per-gateway key-seam export + verification (`OPENROUTER_API_KEY` and friends)

Both are real ideas from the comment thread with only one reproduction each, and none of the
confirmed bugs above needed them to be found.

## Provisional ratings

`complexity: 3 / risk: 2 / effort: 3` — provisional. Phase 0 alone would rate 1/1/1; the composite
is carried by Phase 2's six sites and Phase 3's undesigned seam. Re-rate at the ROI checkpoint,
when Phase 3's scope is actually known.
