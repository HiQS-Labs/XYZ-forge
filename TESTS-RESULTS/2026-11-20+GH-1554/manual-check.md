# Manual Check — GH-1554 (KS-09: Unambiguous Landing Path)

- **Issue:** #1554 (KS-09 from #1541)
- **Date:** 2026-11-20
- **Branch:** `feat/XYZ-forge-gh1554-ks09-landing-path-2026-11-20`
- **Route:** `docs` (see `outputs/ci-route.txt`)

## Summary of Changes (`outputs/code-and-docs.patch`)
- `skills/1-hourly/kickstart/SKILL.md`: specifies one pinned `LANDING_CLONE` as `--primary`, rejects the primary checkout, handles exit `4` deferred sweep receipts with non-empty reason, and distinguishes `wave_reconcile.py` child exit `8` from `merge_cleanup.py` wrapper exit `2` (never assuming every exit `2` means `MERGED`; inspecting logs + live remote PR state before preserve/wait/`--reconcile-pr`/deadline-HOLD).
- `skills/1-hourly/kickstart/scripts/build_queue.py`: updates Bucket C guidance to cite the pinned `LANDING_CLONE` path cleanly.

## Paired Disposable-Clone CLI Controls (`outputs/disposable-controls.txt`)
1. **Control 1A (RED) & 1B (GREEN) — Jog Pin Mismatch vs Pinned Primary:** Created two valid local clones (`landing_pinned` and `wrong_primary`) with matching origin URLs in an isolated `HOME` with a read-only `gh` shim, pinned `xyz.primary.repo-*` to `landing_pinned`. Invoking real `merge_cleanup.py --primary <wrong_primary> --prs-only` failed closed (`rc=2`, `differs from the pinned`); invoking with `--primary <landing_pinned>` succeeded (`rc=0`).
2. **Control 2A (RED) & 2B (GREEN) — Real `--record-sweep` CLI on Seeded QA-Pending Batch:** Seeded a real QA-pending batch JSON under the isolated `HOME`. Reasonless `verdict: deferred` was rejected (`rc=2`); reasoned `verdict: deferred` succeeded via real `merge_cleanup.py --primary <landing_pinned> --record-sweep <file>` (`rc=0`) and recorded the deferred verdict covering PRs 9901 and 9902.
3. **Control 3 — Active Hosted `wave-reconcile.yml` Transitions:** Verified `merge_cleanup.run_local_wave_reconcile(9901, landing_pinned)` converts child exit `8` to `False` (wrapper exit `2`) and child exit `0` to `True`, and verified the preserve/wait/`--reconcile-pr`/deadline-HOLD/non-MERGED-exit-2 transition matrix with `force_local_reconcile=False` and `re_merge=False` throughout.
4. **Bucket C Refresh (`CONTROL_BUCKET_C_BUILD_QUEUE_REFRESH`, exit 0):** Re-executed `build_queue.py` on the final candidate against a behind-PR fixture.

## Static Analysis & Governance
- `outputs/mypy.txt`: `mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/build_queue.py` — 0 issues.
- `outputs/ci-route.txt`: `route=docs`.
- `outputs/pdda-run.log`: `./utils/pdda/pdda.sh run` — 0 errors.
- `provenance.jsonl`: exact SHA-256 and byte-size ledger verified for every artifact.
