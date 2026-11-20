# Manual Check — GH-1554 (KS-09: Unambiguous Landing Path & Per-Merge Reconciliation)

- **Issue:** #1554 (KS-09 from #1541)
- **Date:** 2026-11-20
- **Branch:** `feat/XYZ-forge-gh1554-ks09-landing-path-2026-11-20`
- **Route:** `docs` (`outputs/ci-route.txt`)

## Pre-Change Red Control
- `outputs/pre-change-red.txt`: pre-change `skills/1-hourly/kickstart/SKILL.md` and `build_queue.py` lacked explicit single-pinned-primary enforcement, wrapper exit `2` vs child exit `8` reconciliation handling, and reasoned deferred QA verdicts.

## Post-Change Green Controls (`outputs/disposable-controls.txt` & `outputs/controls.txt`)
1. **Control 1 (Real Disposable-Clone Pin Mismatch vs Pinned Primary):** Two valid full clones (`landing_pinned` + `wrong_primary`) with isolated Jog pin — real `merge_cleanup.py` rejected `wrong_primary` (`rc=2`) and accepted `landing_pinned` (`rc=0`).
2. **Control 2 (Real `--record-sweep` CLI on Seeded QA-Pending Batch):** Isolated `HOME` with seeded QA-pending batch — real `merge_cleanup.py --primary <landing_pinned> --record-sweep` rejected reasonless deferred (`rc=2`) and accepted reasoned deferred (`rc=0`).
3. **Control 3 (Executed CLI Wrapper Contract + Controlled Protocol Walkthrough):**
   - **Part A — Executed CLI & Wrapper Checks (`outputs/disposable-controls.txt`):** In a fresh disposable full clone with a local bare `origin.git` on `development` (mocking boundary explicitly documented: disposable clone's `utils/py/wave_reconcile.py` stubbed to exit `8` then `0`, stub `gh` returning `MERGED` for PR `#9901`), ran real `merge_cleanup.py --primary <landing_pinned> --reconcile-pr 9901 --execute`:
     - Active hosted CI run (child exit `8`): real CLI exited `2`; direct `run_local_wave_reconcile(9901, disp)` returned `False`.
     - Hosted run cleared (child exit `0`): real CLI exited `0`; direct `run_local_wave_reconcile(9901, disp)` returned `True`.
     - `OBSERVED_WAVE_RECONCILE_INVOCATIONS` records each real subprocess call.
   - **Part B — Controlled Documentation-Protocol Walkthrough (explicitly distinguished from Part A CLI checks):** Verified `SKILL.md` decision branches (non-MERGED exit `2` does not enter reconcile wait; cleared within 15-min deadline runs `--reconcile-pr 9901 --execute` once; expired 15-min deadline records observed `HOLD PR #9901:` checkpoint diff with `force_local_reconcile=false` and `re_merge=false`).
4. **Refreshed Bucket C Output (`outputs/controls.txt`):** `build_queue.py` output refreshed on the final candidate wording.

## Static Analysis & Governance
- `outputs/mypy.txt`: `mypy` 0 issues.
- `outputs/ci-route.txt`: `route=docs`.
- `outputs/pdda-run.log`: `./utils/pdda/pdda.sh run` 0 errors.
- `outputs/code-and-docs.patch`: `origin/development..HEAD` diff.
- `provenance.jsonl`: exact SHA-256 + byte lengths verified across all 9 artifacts.
