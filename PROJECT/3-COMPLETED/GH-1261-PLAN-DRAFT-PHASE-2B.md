---
gh_issue: 1261
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1261
title: "GH-1248 Phase 2B: plan-draft resolves bare filenames and seeds issues with no ledger row"
status: Complete
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
| Plan QA approved (r2); built on `f0bb7db9`; 20-issue pilot and all controls pass, ledger untouched; full gate 409/409 on `7bc1742d`; final Codex QA approved (r2) (`TESTS-RESULTS/2026-10-30+GH-1261/SUMMARY.md`) | Stacked PR against `feat/gh1248-outer-loop-primitive`; awaiting review |

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
   - Slash path that fails the existing check and starts with `.xyz/`: retry without the prefix, through the same realpath/containment/file checks, and only when the stripped path is in the frozen listing.
   - Bare name (no `/`, ends in a code/doc extension: `py sh md js ts json yml yaml sql toml txt`): match tracked basenames in the frozen listing. Exactly one match → that path. Two or more → unresolved; no tie-break (plan QA R1).
   - Unresolved bare names are returned separately (name, source line, match count) and shown in the brief under a new `## Unresolved file names` section and a new `unresolved_names` key, added to `BRIEF_KEYS` so the existing drop-key and Markdown/JSON verifier controls cover it.
   - Remove the silent 25-path cap on the cited write set (`harness.py:477-480`): every sourced path is kept, so new resolutions can never evict an earlier issue or capture-doc path (plan QA R3). A larger write set only serializes the lane, the conservative direction.
   - Verify: #216 resolves `utils/py/wave_reconcile.py` and `utils/py/_marathon_plan.py` (the latter via `.xyz/` strip); `marathon-plan.sh` stays unresolved with match count 2; `README.md` stays unresolved with its count.
2. **Seed unregistered issues** with `init --from-prs --unregistered N` (default 0, range 0..50).
   - Only when N > 0: one read-only `gh issue list --state open --limit 500 --json number,title,body,updatedAt` at init (N = 0 makes no new call and adds no failure mode); drop every number that has any ledger row (all sections); newest `updatedAt` first; take N. Freeze into `issues.json`/`gh-state.json` like ledger candidates; requests carry `"source": "unregistered"` (ledger requests get `"source": "ledger"`).
   - A failed list call fails init with a clear error (nothing is admitted).
3. **Draft unregistered issues** in `plan_draft` and `_build_proposal`.
   - Synthesized record: `state` `unregistered`, `deps` from `Engine._deps_of` over title + body, no contract, no doc, no rating.
   - Admission treats `unregistered` like `needs-contract`: sourced write set + sourced scope → `draft`; else `needs-recon` / `missing-scope` (held).
   - `_build_proposal` builds the lane from the brief when the issue is not in the planner records. The dependency view gets a lookup-only synthesized record for **every** frozen unregistered request (state `unregistered`, which is not in `DEP_RESOLVED`), overlaid by admitted lanes, so a dependency on a held or not-yet-drafted seeded issue stays unmet and the dependent is held, never packed early (plan QA R2). Synthesized records carry the keys the brief reader uses (`flags`, `signals`, `contract`, `deps`).
   - Verify: planner waves unchanged; unregistered drafts appear only in the provisional view, marked provisional.
4. **Run and record.** Pilot in a disposable full clone: `init --from-prs --limit 10 --unregistered 10`, 22 ticks. Manual controls: bare name with one match vs two matches (resolved vs unresolved); `.xyz/` prefix with and without the stripped target in the listing; unregistered dependency pair with the prerequisite held/pending (dependent unplaced) and then admitted (prerequisite in an earlier wave); a 25+ citation draft keeps its capture-doc path and collides with a competing lane on it; failed issue list with N > 0; `--unregistered 0` candidate-set parity with Phase 2A (same request issues and order; new `source` field aside). Ledger byte-identical before and after. Evidence under `TESTS-RESULTS/2026-10-30+GH-1261/`.
5. **Gate.** Changed path is `utils/py/harness.py` → full route per `utils/ci-route.sh`; run once on the final approved commit in the disposable clone.

## Acceptance

- #216's brief cites `utils/py/wave_reconcile.py` and `utils/py/_marathon_plan.py`, lists `marathon-plan.sh` as unresolved (2 matches), and #216 no longer shares a provisional wave with a lane writing either cited path.
- A bare name with two or more tracked matches is never resolved and is listed with its match count; with a single match it is resolved.
- A seeded issue that depends on a held or pending seeded issue is held as unplaceable; once the prerequisite is an admitted draft, it packs in an earlier wave.
- Newly resolved citations never remove a path Phase 2A would have sourced for the same input.
- A pilot run with `--unregistered 10` produces a brief for each seeded unregistered issue; the ledger is byte-identical before and after.
- `--unregistered 0` seeds exactly the Phase 2A candidate set.
- Red controls: with resolution disabled, #216's write set falls back to `PROJECT/PDDA.md` only; with lookup records limited to admitted lanes, the held-prerequisite case wrongly packs the dependent (shows the R2 check detects the bug).

## Risks

- **More collisions:** widely named files such as `CHANGELOG.md` will serialize lanes that mention them. That is the conservative direction and is visible in the proposal.
- **Ambiguous names stay unresolved:** a duplicate basename (e.g. `marathon-plan.sh`) still under-counts. It is listed in the brief, so a reviewer sees the gap instead of a guessed path.
- **Unregistered noise:** umbrella, radar and plan issues will mostly land as `needs-recon`. They are held, never packed.

## Rating

`rated 55/40/50/60` (pri/sev/appeal/effort), 2026-10-30. Severity: wrong parallel advice is the unsafe direction, but nothing dispatches from this proposal yet. Priority: it unblocks the Flywheel seeing its actual backlog. Appeal neutral. Effort: two bounded edits in one file. Recurrence: not a recurring defect class; unknown trend.

## Lessons Learned

- Wave packing reads a missing dependency record as satisfied; every seeded item needs a lookup record (entry in `LESSONS-LEARNED.md`, 2026-10-30).
- Retain before/after digests in the evidence directory when they are measured; final QA r1 failed on a ledger claim whose digests lived only in a temp file.

## Follow-ups

- Stale-contract / delivered-but-open check at init (needs a read-only preflight design).
- Ambiguous bare names (e.g. `marathon-plan.sh`) still under-count; a capture-doc path or contract is the fix today.
