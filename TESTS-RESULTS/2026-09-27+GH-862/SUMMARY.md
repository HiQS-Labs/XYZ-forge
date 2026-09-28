# GH-862 — `ci-suite-audit` skill

Landed on `staging/stabilize-2026-10` (#854 window, one commit per issue, operator 2026-09-27). The skill text is taken
from Agy's PR #865 head `0c254edd`, with two edits: the mission line no longer says "aggressively", and acceptance
point 5 no longer fixes three suites' verdicts in advance (it now requires D2 + D8 evidence).

**Not landed from #865:** `sample_audit.py`, `ci-suite-audit-sample.tsv` and the validation-plan results in its
SUMMARY. They assigned verdicts by suite name (review B1, `relay-system/2026-09-27/gh862-pr865-r2-review.md`).

## Evidence

| Check | Result |
|---|---|
| License attribution (`NOTICE`) | verified at review: 3 pinned upstream SHAs exist, MIT, copyright lines match |
| Practice GitHub writes (`practice/`, operator-authorized) | dedupe failed twice via GitHub search/listing (#871–#874, closed); fixed with the local record, passed run 4 (#876). Oversized body (411/411 rows), per-turn comments, redaction, labels: pass |
| `test/gh578-ci-optimize-skill.sh` | 36 pass, 0 fail |
| `test/gh589-skill-viewer.sh` | 8 passed, 0 failed |
| `test/gh400-source-url.sh` | 13 pass, 0 fail |
| `test/path-integrity.sh` | 3 pass, 0 fail |
| `utils/pdda/pdda.sh run` | 0 errors |

**Detector validation plan (#862 *Validation plan*):** measured in `validation/VALIDATION.md`. 12 of 14 checks as expected; gh492 and gh620 read `fixed-flake` because their fixes landed in this window.
