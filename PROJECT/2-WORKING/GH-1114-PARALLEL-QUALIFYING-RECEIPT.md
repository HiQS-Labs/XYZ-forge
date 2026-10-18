# GH-1114 — hosted wave-reconcile qualifies with `validate.sh --parallel 4`; receipt records first-attempt failures

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1114 · Decision root: #1131 · Override record: #1114 comment 6246066795, #1118 comment 6246066959
Branch: `fix/XYZ-forge-gh1114-parallel-qualifying-receipt-2026-10-17` off `development@6a05e45f`.

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
   - `:463` `QUALIFICATION_GATE = "validate.sh --parallel 4"`. Keep `SMALL_GATE` sequential (tier-1 list is ~6 suites; no gain). Add `ACCEPTED_GATES = {QUALIFICATION_GATE, "validate.sh --sequential", SMALL_GATE}` and use it at `:539` so historical receipts still match.
   - `qualification_summary`: accept `mode in ("sequential", "parallel")`; executed rows = lanes `sequential|pool|driver-lock`; final rc per name = the `lane:"retry"` suite row's rc when one exists, else the executed row's rc; require unique names == `registered` and every final rc == 0; collect `first_attempt_failures = sorted(names with a retry row)`. Return `summary` plus that list (tuple or attribute; callers at `:685` and `:564` updated). Small path unchanged except the mode check.
   - `:682` glob `validate-*-{validation.pgid}.jsonl` (pgid binding and `run == tested[:9]-pgid` check at `:687` unchanged, so the decoy test at gh425:324 still holds).
   - Receipt (`:703-716`): add `mode`, `width`, `first_attempt_failures` (list), `retries` (len). Schema version bump only if a reader rejects unknown keys (check `qualification_receipt_matches` and `test/gh740-hosted-lane-publish.sh:182`); otherwise additive.
   - Verify: existing `test/gh425-gate-provenance-pr.sh`, `test/gh740-hosted-lane-publish.sh`, `test/gh421-auto-wave-reconcile.sh` green; manual check `TESTS-RESULTS/2026-10-17+GH-1114/reader-controls.log.txt`: feed the reader (a) a real sequential fixture → PASS, (b) a synthetic parallel JSONL with one contended rescue → PASS with `first_attempt_failures=[name]`, (c) same with the retry row rc=1 → raises, (d) parallel with a dropped suite → raises. Synthetic rows copy the exact field set from `validate.sh:1103,1288,1365-1366,1541-1543`.
2. `test/gh425-gate-provenance-pr.sh:299` stub: accept `"$*" = "--parallel 4"` or `"$1" = --sequential` (adaptation of an existing assertion; no new case). Fixture rows stay sequential; they must keep passing (sequential remains a valid receipt).
3. `skills/2-daily/merge-cleanup/scripts/batch_record.py:31` `FULL_GATE = "validate.sh --parallel 4"` (text fallback only, `:276-279`). `utils/ci-route.sh:35` comment wording.
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
| A2 | reader-controls (b) passes and names the rescued suite | (c) retry rc=1 raises; (d) dropped suite raises |
| A3 | `select_qualification_gate` returns `--parallel 4` for tier 3 and `--sequential --subsystem small` for tier 1 | — (existing gh425 paths) |
| A4 | Final gate for changed paths per `utils/ci-route.sh` in a disposable clone | — |
