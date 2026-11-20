# Relay: GH-1554 (KS-09) Final QA — Unambiguous Landing Path

- **Issue:** #1554 (KS-09 from #1541)
- **Plan:** `PROJECT/2-WORKING/GH-1554-ks09-landing-path.md`
- **Branch:** `feat/XYZ-forge-gh1554-ks09-landing-path-2026-11-20`
- **Candidate HEAD:** `c571696dd32a5f43dff1467ef19a86f0943bf08c`
- **Evidence:** `TESTS-RESULTS/2026-11-20+GH-1554/manual-check.md` and `TESTS-RESULTS/2026-11-20+GH-1554/provenance.jsonl`

## Turn 1 — Producer (Antigravity)

Implemented KS-09 per the Codex-approved Plan QA R2 in `PROJECT/2-WORKING/GH-1554-ks09-landing-path.md`:
- Updated `skills/1-hourly/kickstart/SKILL.md` with an unambiguous landing path: run `merge_cleanup.py --primary "$LANDING_CLONE"` from `LANDING_CLONE` only, never pass the primary checkout as `--primary`, and handle exit codes 4 and 8 explicitly.
- Updated `skills/1-hourly/kickstart/scripts/build_queue.py` so generated run records emit the `LANDING_CLONE` header line cleanly.
- Verified Controls 1A, 1B, 2, and 3 (including disposable clone controls), `mypy --allow-untyped-defs --allow-incomplete-defs` (0 issues), `ci-route.sh pull_request` (`route=docs`), `pdda.sh run` (0 errors), and `provenance.jsonl` under `TESTS-RESULTS/2026-11-20+GH-1554/`.

Please perform Final QA review on `c571696dd32a5f43dff1467ef19a86f0943bf08c`.

**NEXT: Reviewer (Codex)**
