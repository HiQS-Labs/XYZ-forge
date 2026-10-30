---
gh_issue: 1257
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1257
title: "GH-1248 Phase 2A: read-only backlog-to-wave pilot"
status: Planned
created: 2026-10-29
updated: 2026-10-29
owner: noelsaw1
goal: "Point the GH-1248 outer loop at the real roadmap backlog, one issue per tick, and produce sourced draft briefs plus a parallel-wave proposal, without writing to the repository, the ledger or GitHub."
doc_type: plan
effort: 3
complexity: 3
risk: 2
phases: 1
branch: feat/XYZ-forge-gh1257-backlog-wave-pilot-2026-10-29
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1248
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1175
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1254
non_goals:
  - Dispatch, marathon launch, scheduling, merge, deployment or any GitHub/ledger/repository write.
  - Agent adapters (Claude, Codex); the decider stays the deterministic rules arm.
  - Finishing the 24-hour synthetic soak, a watchdog daemon, or soak-v2.
  - New test suites, gate registrations or a second planner.
---

# GH-1257 — Read-only backlog-to-wave pilot

## Status

| What was just completed | What's next |
|---|---|
| Recon: the real backlog has 79 open roadmap rows; the existing planner finds 6 ready across 2 waves and holds 63 for `needs-contract` | Codex plan QA, then implement on the GH-1248 branch |

## Table of contents

- [Problem](#problem)
- [Recon findings](#recon-findings)
- [Bet](#bet)
- [Plan](#plan)
- [Acceptance criteria](#acceptance-criteria)
- [Risks and rollback](#risks-and-rollback)
- [Rating rationale](#rating-rationale)

## Problem

GH-1248's outer loop passed 12 hours on synthetic inputs (`TESTS-RESULTS/2026-10-29+GH-1248/`), but it has never touched a real issue. The operator's goal is a Flywheel that walks open issues and produces marathon plans that can run in parallel. A Codex and Agy consult (`relay-system/2026-10-29/gh1248-flywheel-194730/` on the GH-1248 clone) independently judged that more synthetic soak would not move toward that goal, and recommended this read-only pilot.

## Recon findings

Base: `feat/gh1248-outer-loop-primitive` at `89e1af53`.

- **The planner already exists and is the right engine.** `utils/py/_marathon_plan.py` `Engine.run` (line 812) loads the ledger read-only from `releases.db` (line 766), classifies every row (`ready`, `needs-contract`, `needs-doc`, `unrated`, `already-closed`, `blocked-dep`, …), packs disjoint write-set waves with dependency and zone caps (lines 1121–1172), and flags shared-spine contract seams (lines 1174–1189). It is monolithic, though: `run()` computes and renders in one method and returns only an exit code.
- **It already has offline seams.** `gh_force="off"` or a frozen `gh_state_file` (stub mode, line 435) avoids network, and `deep=False` avoids `swarm-preflight`'s fetch and worktree. The only other subprocesses are read-only `git cat-file` and `git branch` (lines 283, 386). `db_path` is hard-coded to `ROOT/releases.db` (line 816).
- **The real backlog today:** `marathon_plan.py --dry-run` with gh off reports 416 rows (62 queue, 17 in progress), **6 active lanes across 2 waves, 68 held, 63 of them `needs-contract`**, and 3 `coupled-lanes` seams. The Flywheel's bottleneck is therefore not wave packing but missing preflight contracts: without a declared write set, an issue cannot be placed in a parallel wave.
- **The loop's sandbox is already offline.** `_run_tool` (harness.py:455) runs the tool under `sandbox-exec` with `(deny default)`, file reads allowed, writes only to `out/<tool>` and `tmp/<tool>`, and no network rule, so a tool that tries the network fails closed.
- **Phase 1 gap this depends on.** A `_verify_output` failure after a successful tool run (harness.py:591) falls into the generic `except` (line 608) and records `failed`, leaving its inputs eligible for retry. For a tool whose outputs are real drafts, that is an ambiguous attempt and must become `uncertain` with its inputs quarantined.
- **`status`** (harness.py:621) lacks the §7 fields: heartbeat age and stage, lock state, last receipt or error, quarantined IDs.

## Bet

- **Outcome sought:** turning the loop on over the real backlog yields, per issue, a sourced answer to "can this join a parallel marathon wave, and if not, what is missing", plus one cumulative wave proposal a human can review.
- **Smallest viable bet:** one new tool, `plan-draft`, that reuses `Engine` for classification and packing, plus a read-only backlog seed. Rules decider only.
- **Not built:** agent adapters, contract authoring by a model, dispatch, ledger writes, a watchdog, soak-v2.
- **Alternatives rejected:** (a) running `marathon_plan.py` on a timer gives the same waves but no per-issue drafts, no frozen inputs and none of the loop's receipts or recovery; (b) a new planner would duplicate `Engine`; (c) the synthetic soak alone does not exercise real inputs.
- **Rollback:** the change is confined to the unmerged GH-1248 branch family; abandon the branch. The `Engine` refactor is a behaviour-preserving split guarded by the existing marathon-plan suites.

## Plan

Extends the GH-1248 executive in `utils/py/harness.py` and the existing planner in `utils/py/_marathon_plan.py`. No new module, writer or suite.

1. **Split `Engine.run` without changing behaviour.** Move everything up to the exit-code computation into `Engine.compute()` returning `deduped`, `active`, `waves`, `held`, `contract_seams`, `has_drift`, `exit_code`, `counts` and `weight_str`; `run()` calls it and renders exactly as before. Extract the wave-packing loop into `Engine._pack_waves(active, deduped)` so step 3 can reuse it. Add an optional `cfg["releases_db"]` (default `ROOT/releases.db`). *Verify:* `test/marathon-plan.sh`, `test/gh698-planner-db-ratings.sh`, `test/gh362-marathon-plan-link-bullets.sh` pass unchanged.
2. **Backlog seed: `factory-primitive init --from-prs [--limit N]`.** Default N = 10. Outside the sandbox, at init only:
   - copy `releases.db` into `<instance>/backlog/releases.db` with SQLite's backup API from a read-only connection, and record its SHA-256;
   - run `Engine.compute()` once on that copy (gh off) and pick the top N open rows by planner order among `ready` and `needs-contract` rows that have a GitHub number;
   - snapshot each candidate once with `gh issue view N --json number,state,title,body,updatedAt` (read-only) into `backlog/issues.json`, and write `backlog/gh-state.json` for the engine's stub mode;
   - write one `plan-request` inbox item per candidate at slots 1..N and a per-instance manifest, so slot synchronisation still holds.
   *Verify:* the repository's `releases.db` and `releases.sql` are byte-identical before and after, and `releases_app.py check` exits 0.
3. **Tool `plan-draft`.** Add it to `TOOLS`, `_validate` (one eligible `plan-request` id), `rules_decide` (oldest pending `plan-request`) and `execute_tool`. Inside the sandbox, offline, it:
   - builds an `Engine` over the frozen DB and `gh-state.json` with `deep=False`, and calls `compute()`;
   - writes `out/plan-draft/<tick>.json` and `.md`: the issue's planner state and flags, rating, doc path and doc SHA-256, existing contract if any, dependencies, and the issue snapshot's `updatedAt`. For a `needs-contract` issue it adds a **draft write set**: repository paths cited in the issue body or capture doc that exist in the tree, each with the line it was cited from. No cited existing path yields `needs-recon` with no write set;
   - rewrites `out/plan-draft/wave-proposal.json` and `.md`: the planner's actual waves and seams, plus a provisional packing via `_pack_waves` that adds every drafted issue with a sourced write set, clearly marked provisional; held items with reasons; and counts with their denominators.
   Every output carries "draft; preflight and independent plan QA outstanding".
4. **Ambiguity fix.** A `_verify_output` failure after a successful tool run records the tool run, finishes the tick `uncertain` and quarantines its inputs, with no retry. *Verify:* manual control with a corrupted output.
5. **`status` §7 fields.** Add heartbeat age and stage, lock held or free, last receipt status and error, and quarantined IDs.
6. **Evidence.** A compressed run (slots 1..N+2) on a disposable full clone, the controls below, three drafts inspected by hand against their issues, and the focused suites; recorded under `TESTS-RESULTS/2026-10-29+GH-1257/` with `provenance.jsonl`. Update the GH-1248 plan doc and the changelog.

## Acceptance criteria

Existing suites plus recorded manual controls; no new suite (GH-831).

1. `init --from-prs` seeds a nonempty frozen backlog; repository `releases.db`/`releases.sql` byte-identical before and after; `releases_app.py check` exits 0.
2. A compressed run gives every candidate a draft or `needs-recon`, each with doc and issue fingerprints.
3. The wave proposal shows disjoint lanes, any collision or seam the real data contains, a dependency if present, and that an issue with no sourced write set is held out of every wave. If the real data lacks a case, the evidence says so rather than inventing one.
4. Replaying a completed tick creates no duplicate output. A crash after the output is written leaves the tick `uncertain`, its input quarantined, with no retry. A corrupted output fails verification and quarantines.
5. An unknown issue id is rejected by `_validate`; PAUSE prevents execution; no repository, ledger or GitHub write occurs during ticks (a network attempt inside the tool fails closed); outputs stay under `temp/factory-primitive/`.
6. The marathon-plan suites, `gh777` inventory ratchet, `gh174` registry, `gh496` telemetry, `gh788` path-space and `agy-turn` pass; frozen-twin staged check, PDDA and `releases check` pass.

## Risks and rollback

- **False confidence in parallelism.** A draft write set from cited paths can be incomplete, and exact-path disjointness does not prove two changes are independent. Bound: only sourced paths count, missing evidence holds the issue, provisional waves are labelled, existing seam detection runs, and every output is a draft for human review.
- **Hidden side effects in planner helpers.** Bound: gh stub from the frozen snapshot, `deep=False`, the frozen DB copy, and the sandbox denying writes and network.
- **Planner regression from the split.** Bound: a pure move of existing code, verified by the three existing marathon-plan suites.
- **Rollback:** abandon the branch; nothing outside `temp/` is written at run time.

## Rating rationale

2026-10-29: `rated 60/35/50/45`. Priority 60: it is the first real step toward the operator's stated Flywheel goal and unblocks Phase 3 adapters deciding over real inputs. Severity 35: no defect or data at risk; the cost of not doing it is continued synthetic-only evidence. Appeal 50 (neutral; no operator score given). Effort 45: medium, touching the shared planner (behaviour-preserving) and the harness. Recurrence: not a defect class; no incident history applies.
