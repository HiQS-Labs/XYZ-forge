# GH-1605 smoke & red-control verification (manual check, GH-831)

- **Candidate commit:** `41baf1524b6857c3654f1be33043afc5283f21d2`
- **Base commit (red control):** `e22fd2374` (`origin/development`)
- **Execution environment:** Separate disposable full clone (`-verify` sibling, canonical `origin` verified; pre/post `HEAD`, `core.bare=false`, `remotes`, and local `user.email` matched identically).
- **Policy:** No new `test/` file or `validate.sh` entry added (GH-831).

## Existing suites

| Suite | Command | Result |
|---|---|---|
| Deploy skills unit suite | `python3 -B -m unittest -v test/test_deploy_skills.py` | **34 passed, 0 failed** (24.4s) |
| Skills Army mini sync | `bash test/gh620-skills-army-mini-sync.sh` | **28 passed, 0 failed** |
| Drift comparator | `bash test/gh660-skill-drift.sh` | **7 pass, 0 fail** |
| Skills Army bash wrapper | `bash test/skills-army-hq.sh` | `SKIPPED` (`pytest` not installed in host Python; covered directly by `unittest` above) |

## Manual smoke + red-control matrix (`sync.py`)

Fixture: bare `origin` on `development`, fresh canonical checkout at v3, stale canonical checkout at v1 fetched (`0 ahead / 2 behind`), `Deployed Skills` collection holding current v3 `sample` skill with an enabled target. Red control uses `git show e22fd2374:skills/3-weekly/skills-army-hq/scripts/sync.py`.

| # | Case | Expected | Observed |
|---|---|---|---|
| 0 | **Red control (`e22fd2374`)** `--status` vs stale canonical (`0 ahead / 2 behind`) | False `WARN DRIFTED` + downgrade `intake.py --apply update` command, no `STALE_CANONICAL_FORGE` | **PASS** — emitted `WARN DRIFTED sample:` + `intake.py --apply update sample --source <stale>` |
| 1 | **Main path** `--status` vs stale canonical (`0 ahead / 2 behind`) | Exit 0, `WARN STALE_CANONICAL_FORGE` with `git -C ... pull --ff-only`, 0 `WARN DRIFTED` / 0 `intake.py --apply update`, JSON `stale_canonical: true`, `behind: 2`, `ahead: 0`, `branch: "development"`, `skipped: "STALE_CANONICAL_FORGE"`, no `drifted`/`ok` keys | **PASS** |
| 2 | **Main path** `--apply` (enabled target) vs stale canonical | Exit 2, `REFUSED: canonical XYZ-forge checkout ... is 2 commit(s) behind`, 0 links created, 0 downgrade commands | **PASS** |
| 3 | **Main path** `--apply --allow-drift` (pending links) vs stale canonical | Exit 0, loud warning on stderr & JSON, links created, `STALE_CANONICAL_FORGE` + `--allow-drift` recorded in `changelog.md` | **PASS** |
| 4 | **Adjacent path** repeated no-op `--apply --allow-drift` (already reconciled) | Exit 0, loud warning on stderr & JSON, `changelog.md` bytes strictly unchanged (`sync.py:427-428` invariant) | **PASS** |
| 5 | **Adjacent path** diverged canonical (`1 ahead / 2 behind`) `--status` | Exit 0, `WARN STALE_CANONICAL_FORGE` notes `pull --ff-only will refuse while 1 commit(s) ahead`, 0 `WARN DRIFTED` / 0 downgrade commands | **PASS** |
| 6 | **Adjacent path** detached `HEAD` behind `origin/development` with `origin/HEAD` deleted | Exit 0, `origin/development` fallback detects `behind: 2`, `branch: "HEAD"`, `WARN STALE_CANONICAL_FORGE` | **PASS** |
| 7 | **Adjacent path** fast-forward recovery (`git pull --ff-only` on stale canonical) | Exit 0, `STALE_CANONICAL_FORGE` clears, `stale_canonical: false`, `behind: 0`, `ok: ["sample"]`, `drifted: []` | **PASS** |
| 8 | **Adjacent path** fresh canonical (`0 ahead / 0 behind`) + genuine drift in collection | Normal `WARN DRIFTED sample:` on `--status` and `REFUSED` (exit 2) on `--apply`; `stale_canonical: false` | **PASS** |
| 9 | **Adjacent path** non-git canonical directory | `branch: null`, `ahead: null`, `behind: null`, `stale_canonical: false`; normal drift check runs | **PASS** |

Verdict: **PASS** (10/10 smoke + red-control checks; 69/69 existing automated assertions).
