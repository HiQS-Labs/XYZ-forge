# GH-1348 verification and regression suite (2026-11-05)

No new tests (GH-831). The existing regression suite `test/gh267-express-skill.sh` was extended with
positive admission and negative refusal controls for non-execution-authority skill docs under `--docs-only`
with relay attestation, including malformed non-object JSON scanning tolerance. Both paperwork exemptions
(capture doc and CHANGELOG) were also falsified via red controls in this task clone.
Output: `smoke-output.txt`, `frozen-twin-output.txt`, `pdda-output.txt`, `red-control-capture-exemption.txt`,
`red-control-changelog-exemption.txt`.

| # | Check | Observed | Verdict |
|---|---|---|---|
| 1 | Unattested skill edit under `--docs-only` | Refuses with `rule=skill-unattested` | pass |
| 2 | Execution-authority skill edit under `--docs-only` | Refuses with `rule=docs-only` | pass |
| 3 | Non-`SKILL.md` under `skills/` under `--docs-only` | Refuses with `rule=docs-only` | pass |
| 4 | Approved attestation record for `HEAD` | Passes `check --docs-only` (`express-check: PASS`, prints attestation) | pass |
| 5 | Malformed non-dict JSON in `relay-attest/` alongside valid receipt | Passes `check --docs-only` without raising, accepts valid receipt | pass |
| 6 | Modified skill in working tree after attested commit | Refuses with `rule=skill-unattested` | pass |
| 7 | Full express suite `test/gh267-express-skill.sh` | 126 pass, 0 fail (`smoke-output.txt`) | pass |
| 8 | Frozen twin guard `test/gh308-frozen-twin-guard.sh --base origin/development` | 38 pass, 0 fail (`frozen-twin-output.txt`) | pass |
| 9 | Documentation gate `utils/pdda/pdda.sh run` | 0 errors, 40 warnings none from this diff (`pdda-output.txt`) | pass |
| 10 | Red control: capture doc exemption disabled | Refuses with `rule=too-many-files` (5 core files > 4) (`red-control-capture-exemption.txt`) | pass (falsified) |
| 11 | Red control: CHANGELOG exemption disabled | Refuses with `rule=too-many-files` (5 core files > 4) (`red-control-changelog-exemption.txt`) | pass (falsified) |
| 12 | End-to-end `run --docs-only` with attested skill | Lands cleanly to development, completes closeout (`smoke-output.txt`) | pass |
| 13 | Paperwork bound: root relay-system doc | Refuses with `rule=too-many-files` (not exempt) (`smoke-output.txt`) | pass |
| 14 | Paperwork bound: dated review transcript | Stays exempt outside bounds (`smoke-output.txt`) | pass |
