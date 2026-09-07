# Recon Map — LEADERBOARD.md Removal
Commit: current-head · Mode: grep-only · Lanes: A, B, C, D (serial)

## Subject and change class
Subject: `LEADERBOARD.md`, `LEADERBOARD.html`, and their rendering machinery (`utils/leaderboard.sh`, `utils/timeline/export_timeline.py --leaderboard`).
Change class: Subsystem removal

## The seams — where a change here escapes this file
| Seam | Location | Crosses | Breaks if |
| --- | --- | --- | --- |
| Merge resolve | `utils/releases-merge-resolve.sh:196-214` | Git conflict resolution | Resolving a merge still tries to invoke the deleted `leaderboard.sh` or `export_timeline.py --leaderboard` |
| Python App Auto-refresh | `utils/py/releases_app.py:1170-1201` | Releases CLI | `releases_app.py` tries to refresh the deleted LEADERBOARD files |
| Automation Pipelines | `utils/py/wave_reconcile.py`, `utils/py/express.py`, `utils/py/jog_run.py` | Automated lane commits | Automation tries to stage a deleted LEADERBOARD file during git commits |
| Tests | `test/gh57-live-merge-resolve.sh` and others | CI/CD | Tests expect `LEADERBOARD.md` to be present and updated |

## Call paths in
- CLI / Agent writes -> `utils/py/releases_app.py` -> `refresh_preview()` -> calls `utils/leaderboard.sh` to regenerate `LEADERBOARD.md` and `export_timeline.py --leaderboard` to regenerate `LEADERBOARD.html`.
- Git merge conflicts -> `utils/releases-merge-resolve.sh` -> calls `utils/leaderboard.sh` and `export_timeline.py --leaderboard`.
- Automated loops (`wave_reconcile.py`, `express.py`, `jog_run.py`) -> automatically add `LEADERBOARD.md` to commits if it exists.

## State
- Read sites: Humans and agents reviewing task rankings (e.g., via `LEADERBOARD.md`).
- Write sites: Generated automatically by `utils/leaderboard.sh` and `utils/timeline/export_timeline.py`.
- Source of truth: The score data (pri/sev/appeal/effort) is sourced directly from `releases.db` (`roadmap_items` table). `LEADERBOARD.md` is strictly a derived view.

## Contracts
- As with `ROADMAP-DASHBOARD.md`, `LEADERBOARD.md` is an "adopted view." `releases_app.py` only refreshes it if the file exists (opt-in by presence). Removing the file means it stops refreshing automatically.

## Build, failure and rollback today
- Build: Automatically generated via `releases_app.py` after a DB write or during merge resolution.
- Failure: If `utils/leaderboard.sh` is missing, `releases-merge-resolve.sh` will fail and block merge resolution if the file was tracked.
- Rollback: `git revert`

## Unknowns
| Unknown | Why it matters | What would settle it |
| --- | --- | --- |
| Do any downstream external tools rely on `LEADERBOARD.html`? | If it's served statically to a team dashboard, removing it will cause a 404. | Search for org/repo deployments of `LEADERBOARD.html` |

## Current-state radius, one line
Releases CLI auto-refresh (`releases_app.py`), merge resolution (`releases-merge-resolve.sh`), Python automation staging loops (`wave_reconcile.py`, `express.py`, `jog_run.py`), and downstream docs.
