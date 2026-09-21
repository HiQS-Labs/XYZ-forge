---
gh_issue: 732
source: https://github.com/HiQS-Labs/XYZ-forge/issues/732
title: "Mid September CI/CD optimizations — measured gate cost vs documented; fail-fast toolchain preflight; re-run ladder bound; tier-2 width; per-suite timings"
status: Proposed (1-INBOX — not yet active)
created: 2026-09-21
owner: noel
doc_type: feedback
complexity: 2
risk: 2
effort: 3
phases: 1
ratings_provisional: true
non_goals:
  - Changing the GH-35 balanced default
  - Tiers 1/2 as promotion evidence
  - Redesigning the hosted matrix (#382/#30)
related:
  - #496 (predecessor)
  - #382
  - #30
  - #730
  - #223
  - #591
  - #674
  - #722
goal: >
  TODO: one-paragraph statement of what "done" looks like for this idea.
---

## Key concepts

- Measured gate cost vs documented numbers
- Fail-fast toolchain preflight
- Bounded re-run ladder and per-suite timings
- Wire the landed --pre-merge check into the landing gate
- #496 Phases 3–5 carried over

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# Mid September CI/CD optimizations — measured gate cost vs documented; fail-fast toolchain preflight; re-run ladder bound; tier-2 width; per-suite timings

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `HiQS-Labs/XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Why

Between 2026-09-17 and 2026-09-21 the local pre-push gate cost far more wall-clock than the docs promise, and several minutes of each run were spent on things that are not the diff under test. Observed on one 12-core macOS host, PARALLEL 4-wide (the GH-35 default), from six gated pushes in the merge/start-task lanes:

| push | tier / width | wall-clock | what stretched it |
|---|---|---|---|
| #669 refresh, 1st attempt | full (3), 4-wide | 972 s → **refused** | 5 pooled failures, each re-run alone serially; all 5 were toolchain artifacts (below) |
| #669 refresh, 2nd | full (3), 4-wide | **1378 s** | 1 flake re-run alone |
| #647 refresh | full (3), 4-wide | **1082 s** | 1 flake re-run alone |
| reconcile commit | tier 2, 2-wide | 408 s | releases subsystem only |
| #726 (GH-724, doc + ledger row) | tier 2, 2-wide | **648 s** | ledger row forces tier 2 at 2 workers |
| docs-only pushes | tier 1 | 74–82 s | — |

Another agent reported ~35 min for a full gate the same week. The docs say otherwise: `AGENTS.md:180` "parallel by default (~4–6 min …)", `ROUTER.md:63` "`--sequential` (~16 min)", `ROUTER.md:89-90` "a 16-minute gate … 3-minute one". Nobody is measuring against those numbers, so the gap grew unnoticed.

This is an **optimization checklist**, not a redesign; each item is small and independently landable. Adjacent open issues are linked rather than re-stated: #382 (lighter PR gate vs full post-merge), #30 (ci-route docs gap / push cadence), #730 (agent-chorus red from clone state), #223 (ref-lock double-apply), #591 (hosted reconciler never lands), #674 (merge-cleanup races the hosted reconciler), #722 (`SAFE_ROOTS` misses `GitHub Repos`).

## Checklist

- [ ] **Doc fix (one line each): refresh the gate timing claims.** `AGENTS.md:180` (~4–6 min parallel) and `ROUTER.md:63/:89-90` (~16 min sequential; "3-minute") → state the measured range with date and host class ("full gate ≈ 18–23 min at 4-wide on a 12-core host, 2026-09; tier 2 ≈ 7–11 min at 2-wide; docs gate ≈ 80 s"), or drop the numbers and point at the gate's own `GREEN in Ns` line. Stale numbers are how a 20-minute gate gets called broken.
- [ ] **Print per-suite durations in the gate summary.** The `[parallel] <suite> rc=0` lines and the final `passed: N / M` list carry no timings; only the total (`… GREEN in 1378s`) is printed. Add wall-clock per suite and a "10 slowest" block so the long tail is visible and the next optimisation is data-driven, not guessed. (`validate.sh` result loop around `:1309-1330`.)
- [ ] **Fail fast on toolchain drift instead of 16 minutes later.** Four suites (`gh142-ate-exit-contract`, `gh268-relay-cue-and-target-checks`, `gh425-gate-provenance-pr`, `gh-gen4-phase2-adaptive-ate`) went red on **clean `development`** purely because the shell's `python3` (Homebrew 3.14.7) lacked `pytest`/`PyYAML` and a broken `php@8.3` keg (missing `libaspell`) preceded `/opt/homebrew/bin/php` on PATH; each failed in the pool, was re-run alone, and failed again (~10 min of pure re-run). `gh251-validate-pytest-skip.sh` shows pytest-absence *is* meant to be a named skip, but `gh425`'s own `python3 -m pytest` call still hard-fails (`ModuleNotFoundError: No module named 'pytest'` in its log). Add a 2-second preflight at the top of `validate.sh` that checks `python3 -c 'import pytest, yaml'` and `php -v`, and either names the missing toolchain and exits 2, or routes the dependent suites to a named SKIP — never a red that looks like a regression.
- [ ] **Bound the cost of the serial re-run ladder.** `vp_rerun_alone` (`validate.sh:1325`) re-runs every pooled failure alone, serially, after the pool. Correct (GH-528: a pooled verdict is not trusted), but unbounded: 5 failures ≈ +10 min on top of a run that is then refused anyway. Print the time spent in re-runs; consider re-running failures in a 2-wide pool (still isolated from the main pool's contention) or short-circuiting when the first solo re-run reproduces a toolchain error.
- [ ] **Let tier 2 honour the width levers.** `validate.sh:994-996` pins tier 2 to `PARALLEL_JOBS=2` ("2 throttled workers is the whole point of the fast lane") regardless of `--burst` / `XYZ_VALIDATE_MAX_JOBS` (precedence comment at `:684`). A 26-suite tier-2 run took 648 s. Verify whether the levers are ignored for tier 2 (the `elif` runs before the balanced-default branch) and, if so, let an explicit lever win; keep 2 as the default.
- [ ] **Ledger-row pushes route to tier 2 at ~11 min.** A doc-only PR that also parks a roadmap row (`releases.sql`/`releases.db` via `roadmap add`) is classified `releases` subsystem → tier 2 (`utils/ci-route.sh:458`). Evaluate whether an intake-only ledger delta (rows added, no schema/CLI change) can run `releases check` + the docs gate instead of the whole releases subsystem. If not, say so in `ci-route.sh` and leave it.
- [ ] **Fix the nice-nesting false failure in `gh35-test-tiers.sh`.** Under the pre-push gate (workers already at `nice 10`, caller measured at 15) the assertion "worker ran 10 below its caller" wanted nice 25; the OS clamps at 20, so the suite fails only when nested — it passes when invoked directly. Assert `min(caller+10, 20)`, or skip the nice assertion when the caller is already ≥ 10.
- [ ] **Document the contention rule.** Gate workers are `nice -n 10` by design (`validate.sh:669-670`), so a concurrent Codex/agy relay turn, a second gate in another clone, or hosted-run pollers on the same box lengthen the gate materially. One sentence in `ROUTER.md`'s command rails: run one gate at a time, and use `--burst` when the machine is otherwise idle.
- [ ] **Push docs and code separately where the work allows.** The router already gives docs-only pushes an ~80 s gate (tier 1) and subsystem pushes tier 2; a mixed push pays tier 3. Note it in `SOP.md` §4 as a maintainer default (evidence: the same PR's docs-only follow-up commit gated in 82 s where its code commit took 1378 s).
- [ ] **Hosted `wave-reconcile.yml --qualify` is ~70 min per merge and serialised** (concurrency group), so three merges in an afternoon queue ~3.5 h of runner time before any reconciliation can land — and today every run fails on doc debt (#591). Not a gate-speed item, but it is the largest CI/CD wall-clock in the loop; decide in #591 whether `--qualify` belongs on the PR-closed trigger or only on the scheduled catch-up.
- [ ] **Cross-refs, no action here:** #674 (skill's local fallback races the hosted run), #730 (agent-chorus red from `__pycache__` in the clone — 1099 s refused), #223 (ref-lock double-apply after a green gate), #722 (`--root` needed for sibling task clones).

## Carried over from #496 (the previous CI/CD optimization issue)

Status of #496 as of 2026-09-21, checked against `development` @ `39bb1392`: **landed** — Phase 1 telemetry out-of-tree (#548), Phase 2 single reconciliation owner / view decoupling / `wave_reconcile.py --pre-merge` (#553), fast-lane `XYZ_SKIP_PREPUSH` + AST selective routing (#580); the original three acceptance items (frozen-twin guard in `vendored-smoke` on PRs — `ci.yml:533-536`, #459 closed; `ci-route.sh:38/:42` maps `releases_app.py` and `utils/pdda/*`; `githooks/pre-push:34-35/:49` names both bypass levers) are done. **Not done**, carried here so #496 can close or be split:

- [ ] **Wire the existing pre-merge closeout check into the landing gate.** `wave_reconcile.py --pre-merge` (`run_pre_merge`, `utils/py/wave_reconcile.py:1700`) validates closing docs incl. `## Lessons Learned` — but nothing runs it before a merge: merge-cleanup's E.6 gate runs `releases check` + `roadmap reconcile-state --dry-run` only (`skills/merge-cleanup/scripts/merge_cleanup.py`, no `--pre-merge` call). Consequence this week: #671 and #669 merged clean, then every reconciliation run (hosted and local) failed exit 5 on a missing Lessons Learned section, costing two post-merge doc commits and ~2.5 h of hosted runner time. Add `--pre-merge` to E.6 (and/or the pre-push hook when the diff closes an issue) so the doc debt is caught in seconds before landing. (#496 Phase 2, fourth bullet.)
- [ ] **#496 Phase 3 — conditional `releases.db` transport change, spike-gated.** Still tracked (`git ls-files releases.db`); the binary conflicted on 3 of the 4 PRs landed 2026-09-17 (#669, #647, #726) and each needed a resolver pass in a disposable clone. The plan's Phase 0 preservation spike (materialize-from-`releases.sql`, refuse on live journal / unexported local writes, round-trip equality by gid) has not been run; run it and decide go/no-go. Costly if wrong — keep behind the old behaviour until the spike passes.
- [ ] **#496 Phase 4 — four impact profiles (CI/CD, Skills, Core harness, Accessories) on the existing selector**, additive to the numeric tiers; side-by-side old/new selection before narrowing; replay matrix incl. rename/delete, unmapped executable, mixed profiles, empty-diff-from-failure never = docs-only success. Not started.
- [ ] **#496 Phase 5 — measure before serializing; remove proven duplicate work.** Serialize only suites whose contention reproduces at matched width with intact clone identity; benchmark baseline vs candidate (≥3 reps, medians + spread, no invented % target). Not started — and the per-suite timings item above is its prerequisite.
- [ ] **Bring `PROJECT/2-WORKING/GH-496-SHARPEN-CICD.md` current** (last `updated: 2026-09-10`; status table still says "submit PR 2" though #553 merged; 3 unticked items) — either close #496 with the landed scope and point the undone phases here, or split a reviewed follow-up per `PROJECT/PDDA.md`. Do not mark #496 complete while a required phase is parked (its own rule).

## Acceptance

- [ ] Each landed item cites the before/after gate wall-clock on the same host and width, or the suite log line it changes; no item is closed on reasoning alone.
- [ ] The doc numbers in `AGENTS.md`/`ROUTER.md` match a run recorded in the same week they are written.
- [ ] Red control for the toolchain preflight: remove `pytest` from a scratch venv and confirm the gate names it within seconds rather than failing `gh425` after the pool.

## Non-goals

Changing the GH-35 balanced-width default (cores/2, cap 4, `nice -n 10`); reintroducing `cores-2` as the default; making tiers 1/2 count as promotion evidence (GH-509); redesigning the hosted CI matrix (#382/#30 own that).

## Why

The local push gate costs 18–23 min against docs that promise 4–6; several minutes per run are toolchain artifacts and serial re-runs, and #496's later phases never ran.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
