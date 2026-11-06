# GH-1348 verification and regression suite (2026-11-05)

No new tests (GH-831). The existing regression suite `test/gh267-express-skill.sh` was extended with
positive admission and negative refusal controls for non-execution-authority skill docs under `--docs-only`
with relay attestation. Output: `smoke-output.txt`.

| # | Check | Observed | Verdict |
|---|---|---|---|
| 1 | Unattested skill edit under `--docs-only` | Refuses with `rule=skill-unattested` | pass |
| 2 | Execution-authority skill edit under `--docs-only` | Refuses with `rule=docs-only` | pass |
| 3 | Non-`SKILL.md` under `skills/` under `--docs-only` | Refuses with `rule=docs-only` | pass |
| 4 | Approved attestation record for `HEAD` | Passes `check --docs-only` (`express-check: PASS`, prints attestation) | pass |
| 5 | Modified skill in working tree after attested commit | Refuses with `rule=skill-unattested` | pass |
| 6 | Full express suite `test/gh267-express-skill.sh` | 120 pass, 0 fail | pass |
| 7 | Frozen twin guard `test/gh308-frozen-twin-guard.sh --base origin/development` | 38 pass, 0 fail | pass |
| 8 | Documentation gate `utils/pdda/pdda.sh run` | 0 errors, 40 warnings (none from this diff) | pass |
