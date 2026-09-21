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
  - Weakening GH-528 solo re-run verdicts
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
  - GH-365
  - GH-648 (#716)
  - GH-693
goal: >
  A verified, de-duplicated checklist of small CI/CD optimisations for the local gate and reconciliation
  loop, each grounded in a source line or a dated observation, that #496's unfinished phases can be
  executed from without re-deriving the diagnosis.
---

## Key concepts

- Measured gate cost vs documented numbers
- Render existing GH-365 per-suite timings
- Present-but-broken toolchain named, not a suite failure
- #496 Phases 3–5 carried over; pre-merge wiring reframed after GH-693

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

- [ ] **Doc fix: refresh or remove the gate timing claims.** `AGENTS.md:180` (~4–6 min parallel), `ROUTER.md:63/:89-90` (~16 min sequential; "3-minute"), and the same stale prose at `githooks/pre-push:10`. Prefer pointing at the hook's own measured lines (`githooks/pre-push:262/:279/:296` print `docs|tier 2|full gate GREEN in Ns`) over another evergreen estimate; if a number is kept, it carries the date, host class and width of a same-week run. The six-run table above is a dated operator observation, not a benchmark.
- [ ] **Render the per-suite durations the gate already records.** Collection exists (GH-365): `validate.sh:1258` calls `rt_suite`, `test/lib/runner-telemetry.sh:146` emits `duration_ms` per suite (plus retry-lane records), the file lands under `.tick/telemetry` (`runner-telemetry.sh:69`) and `validate.sh:1518` prints its path; committed examples: `TESTS-RESULTS/2026-09-01+GH-365/campaign/`. What is missing is only the console view: add a "10 slowest suites" block to the summary, summing each suite once and separating first attempts from retries. No new timing facility.
- [ ] **Toolchain drift: name the failing dependency, don't fail a suite that looks like a regression.** Observed 2026-09-17 (pre-#716/#697 tree, `development@1e21b7cc`): four suites red on clean `development` because the shell's Homebrew `python3` (3.14.7) lacked `pytest`/`PyYAML` and a *present but broken* `php@8.3` (dyld: missing `libaspell`) preceded `/opt/homebrew/bin/php` on PATH; each failed in the pool, was re-run alone, and failed again. Current state: `validate.sh:1409` + `test/gh251-validate-pytest-skip.sh:56` already treat *absent* pytest as a named skip, and `test/gh268-relay-cue-and-target-checks.sh:107` skips *absent* php — but neither covers a binary that is **present and broken** (`php -v` exits non-zero), and `gh425-gate-provenance-pr.sh` no longer imports pytest, so the `ModuleNotFoundError` in its 09-17 log came from a subprocess in its chain, not the suite. Action: (a) extend the existing skip/diagnostic paths so a present-but-broken `php` (or an interpreter missing `yaml`) is reported as a named environment fault, not a suite failure; (b) identify the actual pytest consumer under gh425/`--qualify` and give it the GH-251 treatment. No unconditional top-level dependency gate — docs-only and unrelated tier-2 runs must not acquire these dependencies.
- [ ] **Show the cost of the serial re-run ladder; keep its guarantee.** `vp_rerun_alone` (`validate.sh:1325`) re-runs every pooled failure alone and serially after the pool drains (`:1301`) — correct per GH-528, and a 2-wide re-run pool would reintroduce the contention the solo verdict exists to exclude, so **do not** change that. Action limited to: print time spent in re-runs (from the GH-365 retry-lane records) in the summary, so a refused gate shows how much of its wall-clock was re-run cost. Any early abort must yield incomplete/failed evidence, never a qualifying green.
- [ ] **Tier-2 width: document that the levers already work.** `XYZ_VALIDATE_MAX_JOBS` is applied at `validate.sh:932` and `--burst` at `:980`, both *before* the tier-2 default at `:994-996`, which only fires when `PARALLEL_JOBS` is still empty (`:975`). So `--burst` / `MAX_JOBS` are honoured for tier 2 already; 2 is the default, not a pin. Action: one sentence in the `--help`/ROUTER rails saying so (the earlier framing of this item — "the levers are ignored" — was wrong).
- [ ] **Ledger-row pushes: the router's answer is known; whether to narrow is not.** Routing is path-based: `releases.sql`/`releases.db` map to the `releases` subsystem (`utils/ci-route.sh:38`) → `tier=2` (`:458`), currently 23 registered shell suites (probe: `printf 'docs/x.md\nreleases.sql\nreleases.db' | bash utils/ci-route.sh push` → `tier=2 tier2_subsystems=releases`). An intake-only delta (rows added by `roadmap add`, no schema/CLI change) therefore always runs the whole releases registry (observed 648 s). Default is to keep that; a row-content classifier is new mechanism and needs go/no-go evidence (schema changes, dropped/modified rows, malformed dumps and unreadable diffs must retain fail-closed coverage). Record the evidence before changing selection, or close this item as "keep".
- [x] ~~Fix the nice-nesting false failure in `gh35-test-tiers.sh`~~ — **superseded**: fixed 2026-09-18 by #716 (GH-648 note at `test/gh35-test-tiers.sh:261-273`: caller+10 only asserted for caller nice ≤ 5; a reniced caller asserts "worker never outranks its caller"). The 09-17 observation predates it.
- [ ] **Document the contention recommendation.** Workers run `nice -n 10` (`validate.sh:697`); `ROUTER.md:69/:92` already explain `--burst` for unattended runs, but nothing says "one gate at a time" or that a concurrent relay turn / second gate / pollers on the same host lengthen the run — an operator observation, not derivable from `nice` alone. One sentence in the command rails pointing at the existing controls; no cross-clone serialisation mechanism.
- [ ] **Push independent docs follow-ups separately — but mixed pushes are not automatically tier 3.** Probe: `docs/x.md` + `utils/py/releases_app.py` → `tier=2 tier2_subsystems=releases` (`utils/ci-route.sh:365`: docs never disqualify mapped code); only kernel/unmapped code forces tier 3. So the saving is real only when a docs change is genuinely independent of the code change (observed: a docs-only follow-up gated in 82 s where its code commit took 1378 s). Push cadence is #30's scope — record this as a linked recommendation there rather than a new SOP rule here.
- [ ] **Hosted `wave-reconcile.yml --qualify` cost is per pending *batch*, not per merge.** `.github/workflows/wave-reconcile.yml:65` runs `--pr N --catch-up --gate --qualify` on `pull_request: closed`; `utils/py/wave_reconcile.py:535-582` filters already-qualified landings and runs **one** full sequential qualification for the pending batch. Observed 2026-09-17: three PR-closed runs of ~70 min each, serialised by the concurrency group — plausible when each run finds its own pending landing, not a per-merge law. Those runs failed exit 5 on missing `## Lessons Learned`; that failure class is closed by GH-693 (advisory since 2026-09-18, `wave_reconcile.py:1066/:1836`). Whether `--qualify` belongs on the PR-closed trigger stays a #591 decision (its plan chose hosted qualification per pending batch).
- [ ] **Cross-refs, no action here** (states checked with `gh` on 2026-09-21, all OPEN): #674 (skill's local fallback races the hosted run), #730 (agent-chorus red from `__pycache__` in the clone — 1099 s refused), #223 (ref-lock double-apply after a green gate), #722 (`--root` needed for sibling task clones), #382 (lighter PR gate), #30 (push cadence / ci-route docs), #591 (reconciler). Also relevant and already landed: GH-365 (runner telemetry), GH-648 (#716, gh35 nice fix), GH-693 (Lessons Learned advisory).

## Carried over from #496 (the previous CI/CD optimization issue)

Status of #496 as of 2026-09-21, checked against `development` @ `39bb1392`: **landed** — Phase 1 telemetry out-of-tree (#548), Phase 2 single reconciliation owner / view decoupling / `wave_reconcile.py --pre-merge` (#553), fast-lane `XYZ_SKIP_PREPUSH` + AST selective routing (#580); the original three acceptance items (frozen-twin guard in `vendored-smoke` on PRs — `ci.yml:533-536`, #459 closed; `ci-route.sh:38/:42` maps `releases_app.py` and `utils/pdda/*`; `githooks/pre-push:34-35/:49` names both bypass levers) are done. **Not done**, carried here so #496 can close or be split:

- [ ] **Pre-merge closeout check: optional integration gap, rationale updated.** `wave_reconcile.py --pre-merge` (`run_pre_merge`, `:1700`) exists and nothing runs it before a merge — merge-cleanup's E.6 gate (`merge_cleanup.py:905` → `ledger_merge.py:520`) runs semantic ledger conflict detection + `releases check` + `roadmap reconcile-state --dry-run` only. The failures that motivated this (2026-09-17: #671/#669 reconciliation exit 5 on missing Lessons Learned, ~2.5 h hosted runner time) are **closed by GH-693** (advisory since 09-18), so wiring `--pre-merge` in would not have been needed for that class. What remains: frontmatter/receipt prerequisites the pre-merge check still enforces could be surfaced before landing rather than after; if pursued, pass the PR head/`--pr` metadata (a bare call infers closers from local commit text). Low priority; preserve GH-693 (Lessons Learned warns, never fails).
- [ ] **#496 Phase 3 — conditional `releases.db` transport change, spike-gated.** `releases.db` is still tracked (`git ls-files releases.db` on `development@39bb1392`); the binary conflicted on 3 of the 4 PRs landed 2026-09-17 (#669, #647, #726 — operator observation, each resolved with `utils/releases-merge-resolve.sh` in a disposable clone). The Phase 0 preservation spike from the canonical #496 plan (materialise from `releases.sql`; refuse overwrite on a live journal or unexported local writes; round-trip equality by gid/values/receipts, not bytes) has no retained evidence in `TESTS-RESULTS/` — run it and decide go/no-go. Costly if wrong; keep behind the old behaviour until the spike passes.
- [ ] **#496 Phase 4 — four impact profiles (CI/CD, Skills, Core harness, Accessories) on the existing selector**, additive to the numeric tiers (`utils/ci-route.sh:24` registry + tier resolver); side-by-side old/new selection before narrowing; replay matrix incl. rename/delete, unmapped executable, mixed profiles, empty-diff-from-failure never = docs-only success. Not present in the current selector.
- [ ] **#496 Phase 5 — measure before serialising; remove proven duplicate work.** Serialise only suites whose contention reproduces at matched width with intact clone identity; benchmark baseline vs candidate (≥3 reps, medians + spread, no invented % target). GH-365 already retains per-suite timing campaigns (`TESTS-RESULTS/2026-09-01+GH-365/campaign/`), so the missing piece is a *fresh matched campaign on the current tree*, not new instrumentation; the console-summary item above is a convenience, not a prerequisite.
- [ ] **Bring `PROJECT/2-WORKING/GH-496-SHARPEN-CICD.md` current** (last `updated: 2026-09-10`; status table still says "submit PR 2" though #553 merged; 3 unticked items) — either close #496 with the landed scope and point the undone phases here, or split a reviewed follow-up per `PROJECT/PDDA.md`. Do not mark #496 complete while a required phase is parked (its own rule).

## Acceptance

- [ ] Each landed item carries its own red/green outcome in a disposable full clone with nonempty output and provenance retained — a new log line alone is not proof (e.g. the duration summary must be checked against the JSONL it renders; a routing change against the ci-route matrix: mapped code + docs → tier 2, kernel code + docs → tier 3, docs-only → tier 1).
- [ ] Timing claims in `AGENTS.md`/`ROUTER.md`/`githooks/pre-push` are either removed in favour of the hook's measured line, or carry date/host/width of a same-week run.
- [ ] Red control for the toolchain item: a present-but-broken `php` (a stub that exits 1 on `-v`) on PATH makes `gh268-relay-cue-and-target-checks.sh` report a named environment fault, not "clean PHP did not pass"; the equivalent for the real pytest consumer once identified.

## Non-goals

Changing the GH-35 balanced-width default (cores/2, cap 4, `nice -n 10`); reintroducing `cores-2` as the default; making tiers 1/2 count as promotion evidence (GH-509); redesigning the hosted CI matrix (#382/#30 own that).

## Why

The local push gate costs 18–23 min against docs that promise 4–6; the remaining real gaps are a console view of existing timings, present-but-broken toolchain detection, and #496's unfinished phases.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
