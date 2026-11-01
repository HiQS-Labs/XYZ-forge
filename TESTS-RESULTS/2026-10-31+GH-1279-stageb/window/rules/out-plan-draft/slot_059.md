# Plan draft: #1242 Merge sequence plan 2026-10-27 — 7 open PRs (#1172 #1173 direct; #1170 #1190 #1209 #1211 #1198 folded)

> draft; preflight and independent plan QA outstanding

- Request: `gh-1242-27cd1eaeb30f` (tick `slot_059`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: 27cd1eaeb30fff08bfe4f912d4b4d4197c3a2c1d84587d199aa911466d7264e7 (updated 2026-10-28T17:36:09Z)
- Dependencies: none

## Scope

_Source: issue#1242:L74 (Not in scope of this run)_

- Teardown found 0 clones safe to remove. Eight sibling clones are `PRESERVE_UNSAFE_ROOT` because `~/Documents/GitHub Repos` is not in `SAFE_ROOTS`. Nine are `PRESERVE_UNPUSHED`. #1198 changes the retire path for sibling roots; a teardown pass after it lands may free some of them.

## Acceptance criteria

_missing_

## Open questions

_missing_

## Write set

- `.github/workflows/wave-reconcile.yml` (issue#1242:L9)
- `AGENTS.md` (issue#1242:L16)
- `ROUTER.md` (issue#1242:L16)
- `SOP.md` (issue#1242:L16)
- `utils/py/express.py` (issue#1242:L18)
- `src/events.js` (issue#1242:L19)
- `bin/tick` (issue#1242:L19)
- `CHANGELOG.md` (issue#1242:L20)
- `utils/py/marathon_plan.py` (issue#1242:L21)
- `LEADERBOARD.md` (issue#1242:L21)
- `WORKTREE-SAFETY.md` (issue#1242:L22)
- `releases.sql` (issue#1242:L27)
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (issue#1242:L44)
- `utils/releases-merge-resolve.sh` (issue#1242:L61)
- `utils/py/releases_app.py` (issue#1242:L61)
- `utils/py/wave_reconcile.py` (issue#1242:L65)
- `utils/pdda/pdda.sh` (issue#1242:L65)

## Unresolved file names

- `SKILL.md` (issue#1242:L17; 77 tracked files share this name)

## Contract probes

- none
