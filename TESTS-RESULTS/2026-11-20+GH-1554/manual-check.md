# Manual Check — GH-1554 (KS-09: Unambiguous Landing Path — `LANDING_CLONE`, Exit 4, Exit 8)

Date: 2026-11-20
Scope: `skills/1-hourly/kickstart/SKILL.md` + `skills/1-hourly/kickstart/scripts/build_queue.py` (`route=docs`, zero new runners or test suites per GH-831).

## 1. Executable Disposable-Clone Controls (`outputs/controls.txt`)
- **Control 1A (RED — empty deferred reason):** `batch_record.record_verdict(rec, 'verdict: deferred\n')` returned `ok=False msg=a deferred verdict needs a reason`.
- **Control 1B (GREEN — non-empty deferred reason):** `batch_record.record_verdict(rec, 'verdict: deferred\nwaived by operator turn 4 pending follow-up sweep')` returned `ok=True msg=verdict deferred recorded for #1501`.
- **Control 2 (`build_queue.py` Bucket C):** verified Bucket C text explicitly names the pinned `LANDING_CLONE` (`--primary "$LANDING_CLONE"`) for `merge-cleanup`.
- **Control 3 (`merge_cleanup.py` exit 4 & exit 8 contract lines):** verified `--record-sweep` and exit-4 / exit-8 branches cited by `SKILL.md`.

## 2. Instruction-Level Exit-4 & Exit-8 Walkthrough
- **Exit 4 (prior batch verdict missing):** run `--record-sweep` with either the verified sweep verdict or a non-empty `deferred` reason (`a deferred verdict needs a reason` enforced by `batch_record.py:572-573`); NEVER delete or edit the batch record directly.
- **Exit 8 (post-merge reconcile/gate failed after merge already landed on `origin/development`):**
  - Preserve the local state and PR truth; NEVER retry `merge-cleanup --execute` on an already-merged PR.
  - Check remote state + hosted checks; if reconcile is still pending or failed after merge, run `merge_cleanup.py --primary "$LANDING_CLONE" --reconcile-pr <N> --execute` (backgrounded) once ownership is stopped; if deadline/budget expires before green reconciliation, record explicit `HOLD` with observed SHA/log and hand back.

## 3. Static & Governance Checks
- `mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/build_queue.py`: Success, 0 issues (`outputs/mypy.log`).
- `utils/ci-route.sh pull_request` (piped): `outputs/ci-route.txt`.
- `./utils/pdda/pdda.sh run`: 0 errors (`outputs/pdda-run.log`).
