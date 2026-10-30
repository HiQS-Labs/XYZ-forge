---
gh_issue: 1261
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1261
title: "GH-1248 Phase 2B: plan-draft resolves bare filenames and seeds issues with no ledger row"
status: Active
created: 2026-10-30
updated: 2026-10-30
owner: noelsaw1
goal: "Make the plan-draft pilot see the unregistered majority of open issues and stop under-counting write sets when an issue names files without a directory, while staying read-only."
doc_type: plan
effort: 2
complexity: 2
risk: 2
phases: 1
branch: feat/XYZ-forge-gh1261-plan-draft-phase-2b-2026-10-30
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1248
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1257
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1175
non_goals:
  - Stale-contract or swarm-preflight readiness checks (need worktrees; separate design).
  - Dispatch, adapters, scheduling, merge, or any GitHub/ledger/repository write at run time.
  - Changing the marathon planner (`utils/py/_marathon_plan.py`) or its waves.
  - New test suites or gate registrations (GH-831).
---

# GH-1261 — plan-draft Phase 2B

## Status

| What was just completed | What's next |
|---|---|
| Recon and plan written | Codex plan QA |

## Problem

The Phase 2A pilot (#1257, PR #1260, merged into `feat/gh1248-outer-loop-primitive` at `b1dd41a8`) has two gaps, both seen on real data (`TESTS-RESULTS/2026-10-29+GH-1257/SUMMARY.md`):

1. **Write-set under-count from bare names.** #216 names `marathon-plan.sh`, `wave_reconcile.py` and `.xyz/utils/py/_marathon_plan.py`. `_cited_paths` (`utils/py/harness.py:318`) only keeps slash-containing paths that exist on disk, so the only sourced path was `PROJECT/PDDA.md` and the provisional proposal put #216 in wave 1 beside planner lanes. That is false parallelism, the unsafe direction.
2. **Most of the backlog is invisible.** `init_from_prs` (`harness.py:546`) seeds only from ledger rows in `Queue / parked intake`. 283 issues are open today; the GH-1175 spike measured ~73% of open issues with no ledger row.

## Recon findings

- Base: `b1dd41a8` (`feat/gh1248-outer-loop-primitive`).
- `_cited_paths(text, source, root)` uses `PATH_RE` (requires at least one `/`) and `os.path.isfile` under `REPO_ROOT`; it is called only from `plan_draft` (`harness.py:477`), and only when the planner record has no preflight contract.
- The frozen tracked-file listing already exists: `init_from_prs` writes `backlog/base-files.txt` from `git ls-tree -r --name-only HEAD`; `plan_draft` can read it inside the sandbox.
- Basename uniqueness on this tree: 8362 tracked files. `_marathon_plan.py` and `wave_reconcile.py` are unique; `marathon-plan.sh` matches `utils/marathon-plan.sh` and `test/marathon-plan.sh`; `README.md`/`SKILL.md`/fixture `ROADMAP.md` match many. Root `ROADMAP.md` is not tracked (generated).
- `.xyz/` is the vendored-harness prefix used by downstream repos (#216 was filed from LTVera-Pandas). The forge path is the same path without `.xyz/`.
- `plan_draft` requires a planner record (`computed["deduped"]`) for the issue and raises `issue missing from the frozen ledger` otherwise (`harness.py:461`). `_build_proposal` copies `by_gh[issue]` for draft lanes (`harness.py:399`). An unregistered issue therefore needs a synthesized record in both places.
- `_pack_waves` reads `gh`, `deps`, `writeset`, `zone`, `zoneRule`, `zoneInferred`, `state` (through dependency lookup in the `deduped` view). `_zone_of({"artifacts": paths}, item)` returns the zone from paths alone. `Engine._deps_of({"raw": text})` parses "depends on / after / blocked by #N" and is static.

## Bet

- **Outcome:** a pilot run's proposal covers registered and unregistered open issues, and an issue that names its files without a directory gets a write set that reflects them.
- **Smallest bet:** two bounded edits in `harness.py` plus one CLI flag. No planner change; no new module.
- **Alternatives rejected:** filing ledger rows for all unregistered issues first (a ledger write and a governance task of its own, and #1258 covers admissible filing upstream); fuzzy path matching (unsafe when wrong in the other direction).
- **Rollback:** revert the PR; `--unregistered` defaults to 0, so an unflagged `init --from-prs` behaves as before.

## Plan

1. **Bare-name and `.xyz/` resolution** in `_cited_paths`, with an optional `files` list (the frozen listing).
   - Slash path that fails the existing check and starts with `.xyz/`: retry without the prefix.
   - Bare name (no `/`, ends in a code/doc extension: `py sh md js ts json yml yaml sql toml txt`): match tracked basenames. One match → that path. Several → if exactly one is outside `test/` and any `fixtures/` segment, take it; else unresolved.
   - Unresolved bare names are returned separately (name, source line, match count) and shown in the brief under a new `## Unresolved file names` section and a new `unresolved_names` key.
   - Verify: #216 resolves to `utils/marathon-plan.sh`, `utils/py/wave_reconcile.py`, `utils/py/_marathon_plan.py`; `README.md` stays unresolved with its count.
2. **Seed unregistered issues** with `init --from-prs --unregistered N` (default 0, range 0..50).
   - One read-only `gh issue list --state open --limit 500 --json number,title,body,updatedAt` at init; drop every number that has any ledger row (all sections); newest `updatedAt` first; take N. Freeze into `issues.json`/`gh-state.json` like ledger candidates; requests carry `"source": "unregistered"` (ledger requests get `"source": "ledger"`).
   - A failed list call fails init with a clear error (nothing is admitted).
3. **Draft unregistered issues** in `plan_draft` and `_build_proposal`.
   - Synthesized record: `state` `unregistered`, `deps` from `Engine._deps_of` over title + body, no contract, no doc, no rating.
   - Admission treats `unregistered` like `needs-contract`: sourced write set + sourced scope → `draft`; else `needs-recon` / `missing-scope` (held).
   - `_build_proposal` builds the lane from the brief when the issue is not in the planner records, and adds those lanes to the dependency view so a dependency between two seeded issues is honoured.
   - Verify: planner waves unchanged; unregistered drafts appear only in the provisional view, marked provisional.
4. **Run and record.** Pilot in a disposable full clone: `init --from-prs --limit 10 --unregistered 10`, 22 ticks. Manual controls: ambiguous bare name, `.xyz/` prefix, unregistered dependency pair, failed issue list, `--unregistered 0` parity with Phase 2A output shape. Ledger byte-identical before and after. Evidence under `TESTS-RESULTS/2026-10-30+GH-1261/`.
5. **Gate.** Changed path is `utils/py/harness.py` → full route per `utils/ci-route.sh`; run once on the final approved commit in the disposable clone.

## Acceptance

- #216's brief cites `utils/marathon-plan.sh`, `utils/py/wave_reconcile.py` and `utils/py/_marathon_plan.py`, and #216 no longer shares a provisional wave with a lane writing any of them.
- A bare name with several non-test matches is not resolved and is listed with its match count.
- A pilot run with `--unregistered 10` produces a brief for each seeded unregistered issue; the ledger is byte-identical before and after.
- `--unregistered 0` seeds exactly the Phase 2A candidate set.
- Red control: with resolution disabled (reverting step 1), #216's write set falls back to `PROJECT/PDDA.md` only.

## Risks

- **More collisions:** widely named files such as `CHANGELOG.md` will serialize lanes that mention them. That is the conservative direction and is visible in the proposal.
- **Wrong pick among duplicates:** the test/fixture tie-break can still choose wrong when a real write target lives under `test/`. The brief shows the chosen path and its source line.
- **Unregistered noise:** umbrella, radar and plan issues will mostly land as `needs-recon`. They are held, never packed.

## Rating

`rated 55/40/50/60` (pri/sev/appeal/effort), 2026-10-30. Severity: wrong parallel advice is the unsafe direction, but nothing dispatches from this proposal yet. Priority: it unblocks the Flywheel seeing its actual backlog. Appeal neutral. Effort: two bounded edits in one file. Recurrence: not a recurring defect class; unknown trend.
