---
title: express honors CHANGELOG_WRITES (no CHANGELOG append or bounds exemption unless the mode is branch)
status: Active
created: 2026-11-20
updated: 2026-11-20
owner: Noel Saw
gh_issue: 1530
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1530
doc_type: bugfix
complexity: 1
risk: 2
effort: 1
phases: 1
goal: >
  Under the default CHANGELOG_WRITES=off (and landing), `express docs` leaves CHANGELOG.md untouched and the
  bounds step no longer exempts CHANGELOG.md; under branch it appends and exempts as before.
---

# GH-1530 — express honors CHANGELOG_WRITES

## Status

| What was just completed | What's next |
|---|---|
| `utils/py/express.py` resolves the mode through `wave_reconcile.read_changelog_writes_mode`; the docs-step append, the bounds exemption and the expected driver paths depend on it; `skills/2-daily/express/SKILL.md` updated; existing `test/gh267-express-skill.sh` extended with one off-mode assertion; manual controls under `TESTS-RESULTS/2026-11-20+GH-1530/` | Gate and independent review of the final head, then land |

## Acceptance

- [x] Default `off` (also env `off`/`landing`): `CHANGELOG.md` byte-identical after `express docs --docs-only`.
- [x] `CHANGELOG_WRITES=branch` (env or `.pdda-mode`): the entry is appended as before.
- [x] `is_doc_path("CHANGELOG.md")` is true only under `branch`.
- [x] Express skill Phase 5 and bounds text match the driver.

## Rating

- 2026-11-20: rated 30/25/50/70 (pri/sev/appeal/effort) on the ledger row via `roadmap pickup`, per the start-task rating policy.
- Severity 25: the driver writes a CHANGELOG entry the policy says branches must not write; no data loss, caught in review. Priority 30 follows severity. Appeal 50 neutral. Effort 70: one driver helper plus skill text.

## Notes

- Express is an execution-authority skill and the express driver is a gate/kernel surface per `utils/ci-route.sh`, so this change takes the normal PR lane with a full gate and independent review, not express self-landing.
- Evidence: `TESTS-RESULTS/2026-11-20+GH-1530/` (run_controls.py, control logs, provenance.jsonl). Existing suites run on the candidate: gh267-express-skill 128/0 (off-mode assertion fails against the old driver), gh202, gh425, gh708.
- The manual controls (`run_controls.py`, `control_1..7.log`) ran at candidate revision `f652caba8`; they cover the append and `is_doc_path` behaviour and do not directly exercise `expect_driver_paths`.
- After that: development merged in; the ledger row and this doc added; and, in the commit following `6106fc3d1`, the capture-doc template, the commit-message text and the `docs` CLI help in `express.py` made mode-neutral, and Phase 5 of the express skill corrected (under `off` the changelog synthesis does not run; under `landing` it skips direct commit landings, which is how express lands, so an express landing is not guaranteed an entry).
- Existing suites were re-run on that final tree and their logs are retained as `TESTS-RESULTS/2026-11-20+GH-1530/suite-*.log` with sha256 rows in `provenance.jsonl`: gh267-express-skill 128 pass / 0 fail, gh202-wave-reconcile-issue-state 40/0, gh425-gate-provenance-pr OK, gh708-vendored-suite-skips 17/0. The off-mode assertion in gh267 fails against the old driver: retained red-control log `suite-gh267-express-skill-OLD-driver-red.log` (this branch's suite with `express.py` taken from `origin/development` `127107b36bf4`: 127 pass, 1 fail, `FAIL: CHANGELOG_WRITES=off still wrote CHANGELOG.md`, rc 1). The retained green logs predate the comment-only edit at `express.py:927`.
