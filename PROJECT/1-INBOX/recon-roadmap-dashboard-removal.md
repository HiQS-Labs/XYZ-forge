# Recon Map — ROADMAP-DASHBOARD.md Removal
Commit: current-head · Mode: grep-only · Lanes: A, B, C, D (serial)

## Subject and change class
Subject: `ROADMAP-DASHBOARD.md` and its rendering/enforcement machinery (`utils/roadmap-dashboard.sh`, `githooks/dashboard-staleness-guard.sh`).
Change class: Subsystem removal

## The seams — where a change here escapes this file
| Seam | Location | Crosses | Breaks if |
| --- | --- | --- | --- |
| Staleness guard hook | `githooks/pre-push` | Local dev workflow | The guard script is deleted but the hook still calls it |
| Documentation | `AGENTS.md`, `ROUTER.md`, `skills/express/SKILL.md`, `skills/vendor-stack/SKILL.md` | Agent context | They instruct agents to read/update the deleted dashboard |
| Hq Skill integration | `utils/hq/hq-lib.sh`, `utils/hq/hq.sh` | Cross-repo ops | Hq checks for the dashboard to verify releases mode |
| Merge resolve | `utils/releases-merge-resolve.sh` | Git conflict resolution | The resolver attempts to call the deleted render script |
| Test Suites | `test/roadmap-dashboard.sh`, `test/gh243-dashboard-staleness-guard.sh` and 5 other tests | CI/CD | Tests execute deleted scripts or assert on deleted files |

## Call paths in
- `githooks/pre-push:87-93` -> `githooks/dashboard-staleness-guard.sh`
- `utils/releases-merge-resolve.sh` -> `utils/roadmap-dashboard.sh` (regenerates dashboard post-merge)
- `utils/hq/hq-lib.sh:42` -> checks `-f "$ROOT/ROADMAP-DASHBOARD.md"` to classify repo state
- Developer tests -> `test/roadmap-dashboard.sh`, `test/gh243-dashboard-staleness-guard.sh`

## State
- Read sites: Agents and humans read `ROADMAP-DASHBOARD.md` to see the roadmap.
- Write sites: `utils/roadmap-dashboard.sh` writes the file.
- Single write path: Yes, `utils/roadmap-dashboard.sh` is the only writer.
- Other rendered MD files: `LEADERBOARD.md` (rendered by `utils/leaderboard.sh` from `releases.db`), `docs/ROADMAP-UPSTREAM-ARCHIVE.md` (static archive).

## Contracts
- `ROADMAP-DASHBOARD.md` — Human/Agent consumer — breaks if they expect a pre-rendered markdown view instead of using `roadmap list` or `releases.db` — declared in `ROUTER.md` and `AGENTS.md`.

## Build, failure and rollback today
- Build: generated manually or during `pre-push` / merge resolution.
- Failure: `dashboard-staleness-guard.sh` blocks `git push` if `releases.sql` is changed but the dashboard isn't regenerated. Removing it removes this failure mode entirely (fixing GH-474).
- Rollback: Revert the commit.

## Unknowns
| Unknown | Why it matters | What would settle it |
| --- | --- | --- |
| Are there external downstream consumers (e.g. static site generators, other repos) relying on `ROADMAP-DASHBOARD.md`? | The file is named as the ONLY human-readable view. If we delete it, external links will 404. | Searching the broader org/wiki for links to this file |

## Current-state radius, one line
The developers pushing commits, the `pre-push` hook, `hq` cross-repo commands, and agent instructions in `ROUTER.md`/`AGENTS.md`.
