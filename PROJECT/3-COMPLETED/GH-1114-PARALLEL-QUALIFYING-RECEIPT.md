---
gh_issue: 1114
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1114
title: "Hosted wave-reconcile qualifies with validate.sh --parallel 4; receipt records first-attempt failures"
status: Complete
created: 2026-10-17
updated: 2026-10-18
owner: claude
goal: "Flip the hosted qualification gate to parallel (operator override on #1114/#1118) while the receipt reader keeps every existing integrity check and the receipt names any GH-528-rescued suite"
doc_type: fix
effort: 2
complexity: 2
risk: 2
phases: 1
fix_probes:
  - "grep -q 'QUALIFICATION_GATE = \"validate.sh --parallel 4\"' utils/py/wave_reconcile.py"
  - "grep -q 'first_attempt_failures' utils/py/wave_reconcile.py"
---

# GH-1114 — hosted wave-reconcile qualifies with `validate.sh --parallel 4`; receipt records first-attempt failures

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1114 · Decision root: #1131 · Override record: #1114 comment 6246066795, #1118 comment 6246066959
Branch: `fix/XYZ-forge-gh1114-parallel-qualifying-receipt-2026-10-17` off `development@6a05e45f`.

## Status

| What was just completed | What's next |
|---|---|
| Plan QA Approved (Codex r2). Implemented at 7f4a9cb5; gh425/gh740/gh421 green; manual reader controls (a)–(i) all pass (`TESTS-RESULTS/2026-10-17+GH-1114/`) | Final Codex QA → push through pre-push gate → PR → **stop for operator merge approval** |

## Observed problem (base 6a05e45f)

- Hosted reconcile runs `QUALIFICATION_GATE = "validate.sh --sequential"` (`utils/py/wave_reconcile.py:463`, executed at `:677`). On `macos-latest` (`wave-reconcile.yml:27`) validate.sh's auto width is cores/2 capped at 4 and drops to sequential below 4 cores (`validate.sh:996-1012`), so the width must be explicit.
- `qualification_summary` (`wave_reconcile.py:481-525`) requires `mode == "sequential"` (`:496`), counts only `lane == "sequential"` rows (`:503`, `:517`), and fails on any suite row with rc ≠ 0 (`:519`). A parallel run emits lanes `pool` / `driver-lock` / `retry` / `non-suite` (`validate.sh:1288,1311,1314`), and a GH-528 contention rescue leaves the pool row with its non-zero rc plus a `lane:"retry"` row of the same name (`validate.sh:1351-1375`). The telemetry glob at `:682` is `validate-sequential-*-{pgid}.jsonl`; the file is named `validate-<mode>-<ts>-<pid>.jsonl` (`test/lib/runner-telemetry.sh:75`).
- The receipt (`wave_reconcile.py:703-716`) carries nothing about first-attempt failures or retries; `CONTENDED` exists only on stdout (`validate.sh:1391-1405`).

## Operator decisions this implements (not re-litigated here)

- Parallel is the standard form; the 2-of-2 clean re-run threshold is waived; a rescued first-attempt failure does not block qualification but **must be recorded** (#1118 decisions table row 1, #1114 override).
- Sequential stays accepted (old receipts replay through `qualification_receipt_matches`, `:564`) and stays the fallback.
- No new test files, no new test cases; existing assertions adapted only where the gate string changes. Any new case needs separate per-case approval.

## Smallest change (ordered, verification inline)

1. `utils/py/wave_reconcile.py`
   - `:463` `QUALIFICATION_GATE = "validate.sh --parallel 4"`. Keep `SMALL_GATE` sequential (tier-1 list is 72 suites per `utils/ci-route.sh:38`; operator decision, not revisited here). Add `ACCEPTED_GATES = {QUALIFICATION_GATE, "validate.sh --sequential", SMALL_GATE}` and use it at `:539` so historical receipts still match.
   - `qualification_summary`: accept `mode in ("sequential", "parallel")` (read from `run.start`, never from the requested gate). Executed rows = lanes `sequential|pool|driver-lock`. **Every existing check is retained**: summary/envelope/run-set/registered/`suite_events_match` (`:519-523`), the required-probe names (`:524-526`), executed-row count == `registered` **and** unique executed names == `registered` (`:517`; duplicates across pool/driver-lock cannot stand in for distinct suites), and the integer-rc check on every suite row (`:519`) **with one carve-out only**: a row in an executed lane may carry a non-zero rc iff a `lane:"retry"` suite row with the same name has rc == 0. Non-suite rows (python layer, gamma probe, pdda) are never retry-eligible and must still be rc 0. `first_attempt_failures = sorted(names that used the carve-out)`. A retry row without an executed row is not completeness (the runner already sets `suite_events_match=no` for it, `validate.sh:1538-1543`; that check stays). Return `(summary, meta)` where `meta = {mode, width, first_attempt_failures}` taken from `run.start` (`runner-telemetry.sh:76-77`); callers at `:564` (ignores meta) and `:685` updated. Small path unchanged except the mode check.
   - `:682` glob `validate-*-{validation.pgid}.jsonl` (pgid binding and `run == tested[:9]-pgid` check at `:687` unchanged, so the decoy test at gh425:324 still holds).
   - Receipt (`:703-716`): add `mode`, `width` (both from `run.start`, so a sequential fallback on a small runner records `mode=sequential,width=1`), `first_attempt_failures` (list), `retries` (len). Additive under `wave-qualification@1`; no reader whitelists keys (`qualification_receipt_matches` `:534-569`, `hosted_lane_report.py:123-127`, `batch_record.py:263-279`), so no schema bump.
   - Verify: existing `test/gh425-gate-provenance-pr.sh`, `test/gh740-hosted-lane-publish.sh`, `test/gh421-auto-wave-reconcile.sh` green (measured post-change in a disposable clone, with gh425's mutation table `:400-406` and gh740's byte mutation `:183-185` still red). Manual check `TESTS-RESULTS/2026-10-17+GH-1114/reader-controls.log.txt` (python harness calling the real functions; no new suite/case): (a) gh425-shaped sequential telemetry → PASS, meta `mode=sequential,width=1`; (b) synthetic parallel JSONL (field set copied from `validate.sh:1103,1288,1365-1366,1541-1543`, `run.start` `mode=parallel,width=4`) with one pool rc=1 + retry rc=0 → PASS, `first_attempt_failures=[name]`, `retries=1`; (c) same with retry rc=1 → raises; (d) parallel with a dropped suite → raises; (e) (b) with `python:test_python_layer.py` rc=1 → raises (non-suite never retry-eligible); (f) (b) with the pool row removed and `suite_events_match=no` → raises; (g) two executed rows sharing a name standing in for two registry entries → raises. Tier selection: (h) `select_qualification_gate` with a stub `utils/ci-route.sh` printing `tier=1` → `SMALL_GATE` + list, and printing `tier=3` → `--parallel 4` (gh425's fixture has no ci-route file and only exercises the fallback, `:608-613`). Receipt: (i) an emitted `provenance.jsonl` from (b) carries `mode=parallel,width=4,first_attempt_failures,retries`, and from (a) `mode=sequential,width=1`; the comparison flags a deliberately wrong `mode`.
2. `test/gh425-gate-provenance-pr.sh:299` stub: accept `"$*" = "--parallel 4"` or `"$1" = --sequential` (adaptation of an existing assertion; no new case). Fixture rows stay sequential; they must keep passing (sequential remains a valid receipt).
3. `skills/2-daily/merge-cleanup/scripts/batch_record.py:31` `FULL_GATE = "validate.sh --parallel 4"` (text fallback only, `:276-279`). `utils/ci-route.sh:35` is accurate as written (describes the unchanged Small gate); not edited.
4. Docs: one paragraph in `PROJECT/2-WORKING/GH-1114-...` acceptance table; `wave-reconcile.yml` untouched (args unchanged, `:66-68`).

## Explicit non-goals

- `.github/workflows/ci.yml:203` (push-to-main macOS boundary) stays `--sequential`; its pin test `test/gh544-parallel-default.sh:115-116` untouched. Flipping it is a one-line follow-up the operator can order separately (#1131 child).
- No change to validate.sh, its retry lane, telemetry schema, or `gate_receipt.py`.
- No bookkeeping-retrigger work (the other half of #1114); superseded by local reconcile (#1131).

## Risks / rollback

- A hosted runner with `xargs -P` missing falls back (`validate.sh:776-783,979-984`) and the receipt would say `mode=sequential`; accepted by design. Rollback = revert the one commit; old and new receipts both replay.
- First hosted parallel sample is the next development merge after landing (auto-fired reconcile); #1131 says let it run.

## Acceptance

| # | Check | Red control |
|---|---|---|
| A1 | gh425 / gh740 / gh421 green at the final commit | gh425 mutation table (`:396-406`) still fails on each mutation |
| A2 | reader-controls (b) passes and names the rescued suite; (i) receipt metadata correct | (c) retry rc=1, (d) dropped suite, (e) non-suite rc=1, (f) retry-only, (g) duplicate names all raise; wrong `mode` flagged |
| A3 | `select_qualification_gate` returns `--parallel 4` for tier 3 and `--sequential --subsystem small` for tier 1 | reader-controls (h), stubbed classifier both branches; gh425 covers the fallback only |
| A4 | Final gate for changed paths per `utils/ci-route.sh` in a disposable clone; `pdda.sh` doc hygiene clean | — |
