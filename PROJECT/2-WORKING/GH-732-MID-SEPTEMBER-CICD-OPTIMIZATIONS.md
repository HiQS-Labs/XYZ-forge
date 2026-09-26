---
gh_issue: 732
source: https://github.com/HiQS-Labs/XYZ-forge/issues/732
title: "Mid September CI/CD optimizations — measured gate cost vs documented; render existing per-suite timings; present-but-broken toolchain diagnostics; #496 Phases 3–5 carried over"
status: Active — marathon GH-749 lanes L2–L4 (A.1–A.5, B.1/B.2, C.1, D.2); #496 P3–5 held
created: 2026-09-21
updated: 2026-09-22
owner: noel
doc_type: feedback
complexity: 2
risk: 2
effort: 3
phases: 3
ratings_provisional: false   # rated 2026-09-22 at marathon-triage; three sequential lanes (measure, docs+render, env faults); #496 P3–5 excluded from this rating
non_goals:
  - Changing the GH-35 balanced default
  - Weakening GH-528 solo re-run verdicts or --qualify's refusal
  - Tiers 1/2 as promotion evidence
  - Redesigning the hosted matrix (#382/#30)
related:
  - GH-749 (marathon umbrella — lanes L2, L3, L4)
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
- Render existing GH-365 per-suite timings (event=suite only)
- Present-but-broken toolchain named in the validator; --qualify refusal preserved
- #496 Phases 3–5 carried over; pre-merge wiring reframed after GH-693
- Radar run 4 (2026-09-21): hosted lane 7/40 green, gate-red-on-clean-trunk class, three conflict magnets — lanes B.2 / C.1 / D.2

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# Mid September CI/CD optimizations — measured gate cost vs documented; render existing per-suite timings; present-but-broken toolchain diagnostics; #496 Phases 3–5 carried over

## Status

| What was just completed | What's next |
|---|---|
| 2026-09-22: promoted to 2-WORKING as lanes L2–L4 of marathon GH-749; ratings confirmed (e3/c2/r2/p3); preflight contract added; #496 Phases 3–5 explicitly held for a follow-on arc. D.2 re-baselined at triage: 14 green / 24 failed / 2 cancelled of the last 40 hosted runs (was 7/40 at v6). | Chain p2 (C.1 + D.2 measurements) → p3 (A.1–A.5 docs + `validate.sh` summary render) → p4 (B.1 named environment faults, B.2 fresh-clone acceptance) from `~/marathon-clones/marathon-gh-749-relay-gate-cost`; tick each item in the canonical issue body with its landing commit. |

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_present", "path": "AGENTS.md", "pattern": "4.6 min at the GH-35 balanced width" },
    { "type": "grep_absent", "path": "validate.sh", "pattern": "GH-732" },
    { "type": "path_absent", "path": "TESTS-RESULTS/2026-09-22+GH-732/c1/conflict-magnets.md" },
    { "type": "path_absent", "path": "TESTS-RESULTS/2026-09-22+GH-732/c1/provenance.jsonl" },
    { "type": "path_absent", "path": "TESTS-RESULTS/2026-09-22+GH-732/d2/hosted-lane-rate.md" },
    { "type": "path_absent", "path": "TESTS-RESULTS/2026-09-22+GH-732/d2/provenance.jsonl" },
    { "type": "path_absent", "path": "test/gh732-l3-gate-summary.sh" }
  ],
  "artifacts": [
    "TESTS-RESULTS/2026-09-22+GH-732/c1/conflict-magnets.md",
    "TESTS-RESULTS/2026-09-22+GH-732/c1/provenance.jsonl",
    "TESTS-RESULTS/2026-09-22+GH-732/d2/hosted-lane-rate.md",
    "TESTS-RESULTS/2026-09-22+GH-732/d2/provenance.jsonl",
    "AGENTS.md",
    "ROUTER.md",
    "githooks/pre-push",
    "validate.sh",
    "test/gh732-l3-gate-summary.sh",
    "test/gh251-validate-pytest-skip.sh",
    "test/gh268-relay-cue-and-target-checks.sh"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-09-22+GH-732/c1/conflict-magnets.md",
    "TESTS-RESULTS/2026-09-22+GH-732/c1/provenance.jsonl",
    "TESTS-RESULTS/2026-09-22+GH-732/d2/hosted-lane-rate.md",
    "TESTS-RESULTS/2026-09-22+GH-732/d2/provenance.jsonl",
    "test/gh732-l3-gate-summary.sh"
  ],
  "remediation": {
    "source": "issue#732",
    "criteria": "Lane L2: C.1 per-file conflict counts and D.2 hosted-lane green rate recorded as reproducible counted lists under TESTS-RESULTS/2026-09-22+GH-732/. Lane L3: AGENTS.md:180, ROUTER.md:63/:89-90 and githooks/pre-push:10 no longer carry undated gate-timing estimates; validate.sh's summary prints a 10-slowest-suites block from the GH-365 event=suite telemetry (each suite once, retries separate) and the time spent in vp_rerun_alone; A.4/A.5 one-sentence rails. Lane L4: a present-but-broken php or an interpreter missing yaml (consumer: test/ci-workflow.sh:137) is reported by the ordinary validator as a named environment fault while --qualify's exit-6/no-receipt refusal is unchanged; B.2 fresh full clone on the documented PATH passes the full gate with zero re-runs."
  },
  "lanes": {
    "agy_safe": [
      "TESTS-RESULTS/2026-09-22+GH-732/c1/conflict-magnets.md",
      "TESTS-RESULTS/2026-09-22+GH-732/c1/provenance.jsonl",
      "TESTS-RESULTS/2026-09-22+GH-732/d2/hosted-lane-rate.md",
      "TESTS-RESULTS/2026-09-22+GH-732/d2/provenance.jsonl",
      "AGENTS.md",
      "ROUTER.md",
      "githooks/pre-push",
      "validate.sh",
      "test/gh732-l3-gate-summary.sh",
      "test/gh251-validate-pytest-skip.sh",
      "test/gh268-relay-cue-and-target-checks.sh"
    ],
    "orchestrator_only": []
  }
}
```

## Idea

> Mirrored from the canonical issue body (v6, 2026-09-21). Refresh this block *from* #732; never edit it here first.

> **This body is canonical.** It is the single list for the Mid-September CI/CD optimizations. Comments below are discussion and QA history, never a second list; the capture doc `PROJECT/1-INBOX/GH-732-MID-SEPTEMBER-CICD-OPTIMIZATIONS.md` (PR #734) is refreshed *from* this body, not the reverse. When an item lands, tick it here with the PR/commit; when one is dropped, strike it here with the reason. Body history: v1–v4 2026-09-21 (Codex relay QA R1–R3, Approved at `1d43d504`); **v5 2026-09-21** (radar run 4 folded in — sections *Radar evidence*, *C*, *D.2* and the status ledger are new; every v4 item is kept verbatim under its lane); **v6 2026-09-21** (correction: #735's `merged_at` error was a unit test's output, not a failure class — D.2 and *Radar evidence* reworded; sub-issues #740/#741 linked).

## Status ledger

| Lane | Item | State (2026-09-21) |
|---|---|---|
| A | A.1 timing docs · A.2 render durations · A.3 re-run cost · A.4 tier-2 levers doc · A.5 contention · A.6 split pushes · A.7 ledger-row routing | open |
| B | B.1 toolchain named faults · B.2 widened clean-trunk class | open (#730, #667, #715 open; #708, #716, #680 landed) |
| C | C.1 conflict magnets measured | open |
| D | D.1 hosted `--qualify` per batch · D.2 lane success rate | open — lane at **7/40 green**; fixes tracked as #740 / #741 under #591 |
| E | cross-refs | — |
| #496 | pre-merge wiring · Phase 3 · Phase 4 · Phase 5 · doc refresh | open |
| — | gh35 nice nesting | ~~superseded~~ by #716 |
| intake | capture doc + Codex QA relay | PR #734 open, **CONFLICTING** since #733 — refresh before merge |

## Why

Between 2026-09-17 and 2026-09-21 the local pre-push gate was **observed** to cost far more wall-clock than the docs promise (18–23 min full, one host — table below), and several minutes of each run were spent on things that are not the diff under test. Observed on one 12-core macOS host, PARALLEL 4-wide (the GH-35 default), from six gated pushes in the merge/start-task lanes:

| push | tier / width | wall-clock | what stretched it |
|---|---|---|---|
| #669 refresh, 1st attempt | full (3), 4-wide | 972 s → **refused** | 5 pooled failures, each re-run alone serially; all 5 were toolchain artifacts (B.1) |
| #669 refresh, 2nd | full (3), 4-wide | **1378 s** | 1 flake re-run alone |
| #647 refresh | full (3), 4-wide | **1082 s** | 1 flake re-run alone |
| reconcile commit | tier 2, 2-wide | 408 s | releases subsystem only |
| #726 (GH-724, doc + ledger row) | tier 2, 2-wide | **648 s** | ledger row forces tier 2 at 2 workers |
| docs-only pushes | tier 1 | 74–82 s | — |

Another agent reported ~35 min for a full gate the same week. The docs say otherwise: `AGENTS.md:180` "parallel by default (~4–6 min …)", `ROUTER.md:63` "`--sequential` (~16 min)", `ROUTER.md:89-90` "a 16-minute gate … 3-minute one". Nobody is measuring against those numbers, so the gap grew unnoticed.

This is an **optimization checklist**, not a redesign; each item is small and independently landable.

## Radar evidence (run 4, 2026-09-21, window 2026-08-31 → 09-21, `development@bd8c6950`)

Radar's Lens 2 found the two CI/CD seams as **recurring, regression-shaped classes** — not one-off observations. Full report: `PROJECT/1-INBOX/RADAR-REPORT-2026-09-21.md` (run 4); live board #293.

- **Hosted reconcile lane** — `RADAR-class-hosted-reconcile-lane`: **30 failures / 7 successes / 2 cancelled** in the last 40 `wave-reconcile.yml` runs; 5 fixes from 5 different PRs in 9 days on `utils/py/wave_reconcile.py` + `.github/workflows/wave-reconcile.yml` (#599, #600, `43cf4452` GH-684/686, `989f5549` GH-693, #725 GH-721, #733 GH-656/657), each exposing the next failure class: hosted test setup → exit-5 doc debt → 1-INBOX publish guard → runner-only `agent-chorus-bridge` red → plain fast-forward push rejected when a merge landed mid-run (#733 during #731's run 35623940059) → the same push rejection again on 2026-09-21 (#733 during #731's run 35623940059), which the lane report (#735) *misattributed* to `invalid merged_at timestamp` — a gh421 unit test's expected output in the qualification log. Umbrella #591 re-scored **≈13, class alive**. Fixes: #740 (push race) and #741 (report attribution) under #591. This issue tracks the *measurement* (D.2).
- **Gate red on a clean trunk** — `RADAR-class-gate-red-on-clean-trunk`: 7 members in 5 days — #667 (roadmap-coverage), #730 (`__pycache__`), #715 (vendored `.xyz` suites), the B.1 toolchain case, and landed #708, #710/#716, #678/#680. The 09-18 wave alone edited seven gate suites from 7 PRs in 2 days. Root pattern: environment differences surface as red *suites*, never as a named *environment fault*, so each is fixed suite-by-suite. **Claimed by this issue (B).**
- **Conflict magnets** (observation): `validate.sh` edited by **47 of 143** window fix commits (one shared `TESTS` array), `skills/relay-automation/relay-pkg.tar.gz` regenerated **13** times, binary `releases.db` conflicted on 3 of 4 PRs landed 09-17. Same shape — generated or registry state in one committed file. → C.1.
- Flow context: Run **82.4%** / Grow **11.5%** / Transform 0% (undeclared) over 557 non-harness commits — Run up ~5 points on run 3. The two classes above are where that went.

Adjacent open issues are linked rather than re-stated: #382 (lighter PR gate vs full post-merge), #30 (ci-route docs gap / push cadence), #223 (ref-lock double-apply), #591 (reconciler umbrella), #674 (merge-cleanup races the hosted reconciler), #722 (`SAFE_ROOTS` misses `GitHub Repos`), #735 (hosted lane alert, auto-managed).

## Checklist

### A — Measure and document what already exists

- [ ] **A.1 Doc fix: refresh or remove the gate timing claims.** `AGENTS.md:180` (~4–6 min parallel), `ROUTER.md:63/:89-90` (~16 min sequential; "3-minute"), and the same stale prose at `githooks/pre-push:10`. Prefer pointing at the hook's own measured lines (`githooks/pre-push:262/:279/:296` print `docs|tier 2|full gate GREEN in Ns`) over another evergreen estimate; if a number is kept, it carries the date, host class and width of a same-week run. The six-run table above is a dated operator observation, not a benchmark.
- [ ] **A.2 Render the per-suite durations the gate already records.** Collection exists (GH-365): `validate.sh:1258` calls `rt_suite`, `test/lib/runner-telemetry.sh:146` emits `duration_ms` per suite (plus retry-lane records), the file lands under `.tick/telemetry` (`runner-telemetry.sh:69`) and `validate.sh:1518` prints its path; committed examples: `TESTS-RESULTS/2026-09-01+GH-365/campaign/`. What is missing is only the console view: add a "10 slowest suites" block to the summary, summing each suite once and separating first attempts from retries. No new timing facility.
- [ ] **A.3 Show the cost of the serial re-run ladder; keep its guarantee.** `vp_rerun_alone` (`validate.sh:1325`) re-runs every pooled failure alone and serially after the pool drains (`:1301`) — correct per GH-528, and a 2-wide re-run pool would reintroduce the contention the solo verdict exists to exclude, so **do not** change that. Action limited to: print time spent in re-runs (from the GH-365 retry-lane records) in the summary, so a refused gate shows how much of its wall-clock was re-run cost. Any early abort must yield incomplete/failed evidence, never a qualifying green.
- [ ] **A.4 Tier-2 width: document that the levers already work.** `XYZ_VALIDATE_MAX_JOBS` is applied at `validate.sh:932` and `--burst` at `:980`, both *before* the tier-2 default at `:994-996`, which only fires when `PARALLEL_JOBS` is still empty (`:975`). So `--burst` / `MAX_JOBS` are honoured for tier 2 already; 2 is the default, not a pin. Action: one sentence in the `--help`/ROUTER rails saying so (the earlier framing of this item — "the levers are ignored" — was wrong).
- [ ] **A.5 Document the contention recommendation.** Workers run `nice -n 10` (`validate.sh:697`); `ROUTER.md:69/:92` already explain `--burst` for unattended runs, but nothing says "one gate at a time" or that a concurrent relay turn / second gate / pollers on the same host lengthen the run — an operator observation, not derivable from `nice` alone. One sentence in the command rails pointing at the existing controls; no cross-clone serialisation mechanism.
- [ ] **A.6 Push independent docs follow-ups separately — but mixed pushes are not automatically tier 3.** Probe: `docs/x.md` + `utils/py/releases_app.py` → `tier=2 tier2_subsystems=releases` (`utils/ci-route.sh:365`: docs never disqualify mapped code); only kernel/unmapped code forces tier 3. So the saving is real only when a docs change is genuinely independent of the code change (observed: a docs-only follow-up gated in 82 s where its code commit took 1378 s). Push cadence is #30's scope — record this as a linked recommendation there rather than a new SOP rule here.
- [ ] **A.7 Ledger-row pushes: the router's answer is known; whether to narrow is not.** Routing is path-based: `releases.sql`/`releases.db` map to the `releases` subsystem (`utils/ci-route.sh:38`) → `tier=2` (`:458`), currently 23 registered shell suites (probe: `printf 'docs/x.md\nreleases.sql\nreleases.db' | bash utils/ci-route.sh push` → `tier=2 tier2_subsystems=releases`). An intake-only delta (rows added by `roadmap add`, no schema/CLI change) therefore always runs the whole releases registry (observed 648 s). Default is to keep that; a row-content classifier is new mechanism and needs go/no-go evidence (schema changes, dropped/modified rows, malformed dumps and unreadable diffs must retain fail-closed coverage). Record the evidence before changing selection, or close this item as "keep".
- [x] ~~Fix the nice-nesting false failure in `gh35-test-tiers.sh`~~ — **superseded**: fixed 2026-09-18 by #716 (GH-648 note at `test/gh35-test-tiers.sh:261-273`: caller+10 only asserted for caller nice ≤ 5; a reniced caller asserts "worker never outranks its caller"). The 09-17 observation predates it.

### B — Environment faults get a name (the `gate-red-on-clean-trunk` class)

- [ ] **B.1 Toolchain drift: name the failing dependency — without weakening qualification.** Observed 2026-09-17 (`development@1e21b7cc`, pre-#716/#697): four suites red on clean `development` because the shell's Homebrew `python3` (3.14.7) lacked `pytest`/`PyYAML` and a *present but broken* `php@8.3` (dyld: missing `libaspell`) preceded `/opt/homebrew/bin/php` on PATH; each failed in the pool, was re-run alone, and failed again. Current state: `validate.sh:1409` + `test/gh251-validate-pytest-skip.sh:56` treat *absent* pytest as a named skip in the ordinary validator; `test/gh268-relay-cue-and-target-checks.sh:107` skips *absent* php. Neither covers a binary that is **present and broken**. The pytest consumer under `--qualify` is `qualify_landings` (`utils/py/wave_reconcile.py:580` runs `python3 -c "import pytest"`) and it **deliberately refuses with exit 6 and no receipt** (`:596`) — that is correct and must stay: qualification requires the coverage the ordinary validator may skip. Where the 09-17 `ModuleNotFoundError` in gh425's log originated is **unverified** (its traceback was not retained; `gh425` itself has 0 pytest references — it exercises qualification through a unittest fixture at `:360`). Action: (a) extend the existing skip/diagnostic paths so a present-but-broken `php` or an interpreter missing `yaml` (consumer **unverified** — identify it and its red control on promotion, or defer that subcase) is reported as a named environment fault in the ordinary validator; (b) keep `--qualify`'s nonzero refusal, optionally with a clearer environment diagnostic. No unconditional top-level dependency gate.
- [ ] **B.2 Close the class, not the suite.** The same "environment difference → red suite" pattern has three more open members: #730 (leftover `skills/agent2agent/__pycache__` makes `test/agent-chorus.sh` red — 1099 s refused), #667 (`origin/development` red on its own: roadmap-coverage for GH-658's doc with no ledger row + path-integrity reading fixture names as paths), #715 (11 vendored-`.xyz` suites red for non-path reasons). Each keeps its own issue; this item is the shared acceptance: **a fresh full clone of `development` on the documented PATH (`~/.cache/xyz-forge-test-venv/bin` + `/opt/homebrew/bin` first) passes the full gate with zero `vp_rerun_alone` re-runs**, and any of the four faults above, planted, is reported as a named environment fault (not a suite failure) by the existing diagnostic path. No new precheck facility — B.1's mechanism, widened.

### C — Conflict magnets

- [ ] **C.1 Measure, then decide per file.** Three committed files absorb a disproportionate share of merge work (radar run 4, window 08-31→09-21): `validate.sh` — 47 of 143 fix commits touch its `TESTS` array; `skills/relay-automation/relay-pkg.tar.gz` — regenerated 13 times; `releases.db` — binary conflicts on 3 of the 4 PRs landed 09-17. Action: count PRs in the window that needed a manual resolution on each (from `git log --merges`/resolver commits and the merge-lane attempt records under `.tick/merge-cleanup/`), then record one decision per file: *registry* — derive the suite list from `test/*.sh` + an explicit exclusions list (the derive-from-source pattern `RADAR-class-guard-blind-matcher` has asked for since 08-28; the frozen-twin and registration guards must still fire); *tarball* — generate on demand or in CI instead of committing (check who consumes the committed bytes first); *ledger* — the #496 Phase 3 spike below. Measurement only here; each change is its own PR with a red control.

### D — Hosted lane

- [ ] **D.1 Hosted `wave-reconcile.yml --qualify` cost is per pending *batch*, not per merge.** `.github/workflows/wave-reconcile.yml:65` runs `--pr N --catch-up --gate --qualify` on `pull_request: closed`; `utils/py/wave_reconcile.py:535-582` filters already-qualified landings and runs **one** full sequential qualification for the pending batch. Observed 2026-09-17: three PR-closed runs of ~70 min each, serialised by the concurrency group — plausible when each run finds its own pending landing, not a per-merge law. Those runs failed exit 5 on missing `## Lessons Learned`; that failure class is closed by GH-693 (advisory since 2026-09-18, `wave_reconcile.py:1066/:1836`). Whether `--qualify` belongs on the PR-closed trigger stays a #591 decision (its plan chose hosted qualification per pending batch).
- [ ] **D.2 Track the lane's success rate as the CI/CD number that matters most.** Baseline 2026-09-21: **7 green of the last 40** runs (`gh run list --workflow wave-reconcile.yml --limit 40`), six failure classes in nine days (listed under *Radar evidence*). The two open items belong to #591 and are filed: **#740** — the final plain `git push HEAD:development` is rejected whenever a merge lands during the ~70-min run (#733 during #731's run; #674 is the local-fallback half of the same race); **#741** — `hosted_lane_report.py` names the *last* `wave-reconcile: ERROR —` line, which on a `--qualify` run is a unit test's expected output (#735's `invalid merged_at timestamp` was exactly that; the run failed on the push). There is no `merged_at` recovery bug. This issue owns only the measurement: re-count at each landed item here and record it in the same `TESTS-RESULTS/<date>+GH-732/` evidence; **exit condition for this checklist: 10 consecutive green scheduled/PR-closed runs** with #741 landed so a red run names its real cause. Until then, merge one PR at a time and wait for `gh run watch` to return before the next (merge-lane practice since 2026-09-21; the race is documented on #674).

### E — Cross-refs, no action here

States checked with `gh` on 2026-09-21, all OPEN: #674 (skill's local fallback races the hosted run), #730 (agent-chorus red from `__pycache__`), #667 (trunk red on its own), #715 (vendored suites), #223 (ref-lock double-apply after a green gate), #722 (`--root` needed for sibling task clones), #382 (lighter PR gate), #30 (push cadence / ci-route docs), #591 (reconciler umbrella), #740 / #741 (its two filed sub-issues), #735 (hosted lane alert). Already landed and relevant: GH-365 (runner telemetry), GH-648/#716 (gh35 nice fix), GH-693 (Lessons Learned advisory), GH-678/#680 (gate stops writing real HOME), GH-710/#716, #708.

## Carried over from #496 (the previous CI/CD optimization issue)

Status of #496 as of 2026-09-21, checked against `development` @ `39bb1392`: **landed** — Phase 1 telemetry out-of-tree (#548), Phase 2 single reconciliation owner / view decoupling / `wave_reconcile.py --pre-merge` (#553), fast-lane `XYZ_SKIP_PREPUSH` + AST selective routing (#580); the original three acceptance items (frozen-twin guard in `vendored-smoke` on PRs — `ci.yml:533-536`, #459 closed; `ci-route.sh:38/:42` maps `releases_app.py` and `utils/pdda/*`; `githooks/pre-push:34-35/:49` names both bypass levers) are done. **Not done**, carried here so #496 can close or be split:

- [ ] **Pre-merge closeout check: optional integration gap; the two contracts are not interchangeable.** `wave_reconcile.py --pre-merge` (`run_pre_merge`, `:1700`) exists and the inspected merge-cleanup E.6 path (`merge_cleanup.py:905` → `ledger_merge.py:520`: semantic ledger conflict detection + `releases check` + `roadmap reconcile-state --dry-run`) does not call it. The failures that motivated this (2026-09-17: #671/#669 reconciliation exit 5 on missing Lessons Learned) are **closed by GH-693** (advisory since 09-18, `:1066/:1836`). What the pre-merge path uniquely enforces: strict frontmatter (`validate_frontmatter_schema`, `:1001`, sole call `:1831`) and committed passing-evidence receipts (`validate_pre_merge_receipts`, `:720`, called `:1840`). Post-merge `--gate` checks receipt *attribution* (`check_provenance_receipts`, `:628`, called `:2047`) — missing attributable receipts remain fatal there — and `--qualify` generates fresh evidence; strict frontmatter is a pre-merge-only contract. So the optional integration would surface frontmatter/receipt problems before landing, not duplicate the post-merge checks. If pursued, pass the PR head / `--pr` metadata. Low priority; GH-693 preserved (Lessons Learned warns, never fails).
- [ ] **#496 Phase 3 — conditional `releases.db` transport change, spike-gated.** `releases.db` is still tracked (`git ls-files releases.db` on `development@39bb1392`); the binary conflicted on 3 of the 4 PRs landed 2026-09-17 (#669, #647, #726 — operator observation, each resolved with `utils/releases-merge-resolve.sh` in a disposable clone). The preservation constraints come from the canonical #496 plan comment (2026-09-10, Phase 3), quoted: "Reuse the existing parser, locks and atomic recovery primitives for **safe bootstrap/materialization**", "Refuse overwrite when a journal/live writer or unexported local data exists", "Witness round-trip equality by stable global IDs, values, relationships, generations and receipt semantics; do not require SQLite byte equality". Retained evidence search: `TESTS-RESULTS/` has `2026-09-09+GH-496-PR1` and `2026-09-10+GH-496-PR2` only — no Phase 3 / materialization spike receipts. Run the spike and decide go/no-go; Costly if wrong; keep behind the old behaviour until it passes.
- [ ] **#496 Phase 4 — four impact profiles (CI/CD, Skills, Core harness, Accessories) on the existing selector**, additive to the numeric tiers (`utils/ci-route.sh:24` registry + tier resolver); side-by-side old/new selection before narrowing; replay matrix incl. rename/delete, unmapped executable, mixed profiles, empty-diff-from-failure never = docs-only success. Not present in the current selector.
- [ ] **#496 Phase 5 — measure before serialising; remove proven duplicate work.** Serialise only suites whose contention reproduces at matched width with intact clone identity; benchmark baseline vs candidate (≥3 reps, medians + spread, no invented % target). GH-365 already retains per-suite timing campaigns (`TESTS-RESULTS/2026-09-01+GH-365/campaign/`), so the missing piece is a *fresh matched campaign on the current tree*, not new instrumentation; A.2 is a convenience, not a prerequisite.
- [ ] **Bring `PROJECT/2-WORKING/GH-496-SHARPEN-CICD.md` current** (last `updated: 2026-09-10`; status table still says "submit PR 2" though #553 merged; 3 unticked items) — either close #496 with the landed scope and point the undone phases here, or split a reviewed follow-up per `PROJECT/PDDA.md`. Do not mark #496 complete while a required phase is parked (its own rule).

## Acceptance

- [ ] Each landed item carries its own red/green outcome in a disposable full clone with nonempty output and `provenance.jsonl` retained under `TESTS-RESULTS/<UTC-date>+GH-732/<item>/` — a new log line alone is not proof (e.g. the duration summary must be checked against the JSONL it renders; a routing change against the ci-route matrix: mapped code + docs → tier 2, kernel code + docs → tier 3, docs-only → tier 1).
- [ ] Timing claims in `AGENTS.md`/`ROUTER.md`/`githooks/pre-push` are either removed in favour of the hook's measured line, or carry date/host/width of a same-week run.
- [ ] Controls for B.1: (red) a present-but-broken `php` stub on PATH — one that fails both `-v` and `-l`, modelling unusable linting — makes `gh268-relay-cue-and-target-checks.sh` report a named environment fault, not "clean PHP did not pass"; (green) healthy `php` still passes clean PHP and still fails the planted syntax error; (boundary) a missing-pytest `--qualify` run in a disposable clone still exits nonzero with **no** qualification receipt — a candidate that emits qualifying green after omitting the coverage fails.
- [ ] Controls for B.2: a fresh clone of `development` on the documented PATH → full gate GREEN with zero re-runs (record the hook's `GREEN in Ns` line); a planted `__pycache__` under `skills/agent2agent/` and a planted 1-INBOX doc with no ledger row each produce a *named* fault line, and the suite that used to go red no longer does — or the fault is refused before the pool starts.
- [ ] A.2 selects `event=suite` records only — retry legs also emit `event=retry` (`validate.sh:1339-1340`) and must not be double-counted.
- [ ] C.1 and D.2 are measurements: their evidence is the counted list (PR numbers / run ids), reproducible from the commands named in the item, retained under the same `TESTS-RESULTS/` path.

## Non-goals

Changing the GH-35 balanced-width default (cores/2, cap 4, `nice -n 10`); reintroducing `cores-2` as the default; making tiers 1/2 count as promotion evidence (GH-509); redesigning the hosted CI matrix (#382/#30 own that); fixing the reconciler itself (#591 owns it — this issue only measures it).

## Why

The local push gate was observed at 18–23 min against docs that promise 4–6; the remaining real gaps are a console view of existing timings, present-but-broken toolchain detection, and #496's unfinished phases.

## Marathon lanes (GH-749) — what this doc's checklist splits into

### Lane L2 — measure (phase p2)
- [ ] C.1: per-file count of PRs in the 08-31→09-21 window that needed a manual resolution on `validate.sh`, `skills/relay-automation/relay-pkg.tar.gz`, `releases.db` (from `git log --merges`, resolver commits, `.tick/merge-cleanup/` attempt records) → `TESTS-RESULTS/2026-09-22+GH-732/c1/conflict-magnets.md` + one decision line per file (registry / tarball / ledger).
- [ ] D.2: `gh run list --workflow wave-reconcile.yml --limit 40` re-count with run ids → `…/d2/hosted-lane-rate.md`; baseline at triage 2026-09-22 was 14/40 green.

### Lane L3 — docs + render (phase p3)
- [ ] A.1 timing claims at `AGENTS.md:180`, `ROUTER.md:63/:89-90`, `githooks/pre-push:10` → point at the hook's measured `GREEN in Ns` lines or carry date/host/width.
- [ ] A.2 "10 slowest suites" block in the `validate.sh` summary from `event=suite` records only; A.3 re-run cost line from the retry-lane records; `test/gh732-l3-gate-summary.sh` checks the block against the JSONL it renders.
- [ ] A.4 / A.5 one sentence each in the `--help` / ROUTER rails (levers already work; one gate at a time).

### Lane L4 — environment faults get a name (phase p4)
- [ ] B.1: present-but-broken `php` (fails `-v` and `-l`) → `gh268-relay-cue-and-target-checks.sh` reports a named environment fault; interpreter missing `yaml` (consumer `test/ci-workflow.sh:137`) → named fault; `--qualify`'s exit-6 / no-receipt refusal untouched (boundary control).
- [ ] B.2 acceptance: fresh full clone of `development` on the documented PATH → full gate GREEN with zero `vp_rerun_alone` re-runs (record the `GREEN in Ns` line).

### QA gate — every lane
- [ ] Red/green controls with `provenance.jsonl` under `TESTS-RESULTS/2026-09-22+GH-732/<lane>/`; `bash validate.sh` green in the marathon clone; the canonical issue body ticked with the landing commit.

### Held (not in GH-749)
- #496 Phases 3–5 and the GH-496 doc refresh — follow-on arc (Phase 3 is Costly, spike-gated).
- A.6 / A.7 — recorded as recommendations (#30 / "keep"), no code.

## Merge evidence

- PR #734 merged 2026-09-21 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #743 merged 2026-09-22 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #750 merged 2026-09-22 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #821 merged 2026-09-26 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
