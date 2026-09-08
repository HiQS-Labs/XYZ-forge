# Clone inventory — 2026-09-07

13 XYZ-forge clones on disk (~1.2 GB) plus the primary checkout. Snapshot taken
after `/merge-cleanup` left leftovers behind.

## Keep — known active

| Clone | Branch | State | Why keep |
|---|---|---|---|
| `~/marathon-clones/marathon-gh-490-roadmap-db-flip` | `marathon/gh-490-prep` | clean, commit 12 min ago, PR #495 open | **Active marathon** |
| `~/Documents/GH Repos/XYZ-forge-marathon-ledger-trust` | `marathon/gh-497-ledger-trust-prep` | 2 dirty, 5 ahead, PR #498 open | **Marathon ready to fire** |
| `~/Documents/GH Repos/XYZ-forge-merge-cleanup-pr` | `fix/merge-cleanup-conflict-recovery` | clean, 1 ahead, PR #493 open | Open PR |
| `~/Documents/GH Repos/XYZ-forge.wiki` | `master` | clean, 136K | Separate wiki repo, not a clone |

GH-496 has **no clone folder**. `PROJECT/1-INBOX/GH-496-SHARPEN-CICD.md` is
untracked in the primary checkout at `~/Documents/GH Repos/XYZ-forge`.

## Deleted 2026-09-07 22:59 — moved to `~/.Trash`, recoverable

| Clone | Branch | Proof |
|---|---|---|
| `~/Documents/GH Repos/XYZ-forge-unstuck` | `feat/gh473-unstuck-skill` | clean, 0 stashes, no procs; HEAD is ancestor of `origin/development` |
| `~/marathon-clones/marathon-gh-417-gh406-remediation` | `feat/gh410-relay-block-validator-driven-path` | clean, 0 stashes, no procs, idle 4 d; remote branch merged into development, 0 ahead |
| `~/marathon-clones/transcript-archive-2026-09-05` | `main` | 1.9 MB transcript archive, clean, idle 2 d |

Each carried a stale `.git/releases-app.lock` (advisory lock from
`releases_app.py`, not a core git lock) — not a blocker.

## HELD — was listed safe, is not

`~/Documents/GH Repos/XYZ-forge-gate-203849` (detached HEAD, 2 ahead) has a live
`git push origin development` — PID 97203, started 2026-09-07 22:51, still
running after 8 min, parented to a detached process. 137 files touched in the
last 24 h. **Do not delete while that push is in flight.** Re-check the PID,
confirm whether the push landed or hung, then retire the clone.

This is the background-push race the session memory warns about.

## Needs a decision — carries unlanded diff, no open PR

Diffs are three-dot vs each clone's own `origin/development` ref, which may be
stale. Per the clone-retirement proof method, "N commits ahead" is not proof of
unlanded work — classify line provenance before deleting any of these.

| Clone | Branch | Diff vs development | Dirty | Idle |
|---|---|---|---|---|
| `~/marathon-clones/marathon-gh-462-planner-core` | `marathon/10days-gh462-planner-core` | 87 files, +4638/-585 | 0 | 31 h |
| `~/marathon-clones/marathon-gh-299-gen4-ate` | `feat/gh299-gen4-ate` | 22 files, +3341/-465 | 10 | 4 d |
| `~/marathon-clones/gh271-waveA` | `plan/gh-271-subtraction-marathon` | 36 files, +2240/-11 | 0 | 3 wk |
| `~/task-clones/xyzforge-gh478-runaway-guard` | `fix/gh478-ate-runaway-guard` | 21 files, +1553/-126 | 1 | 1 d |
| `~/Documents/GH Repos/XYZ-forge-flight-dashboard` | `feat/flight-dashboard-mockup` | 18 files, +1090/-35 | 2 | today |
| `~/marathon-clones/marathon-gh-424-status-marker-writer` | `fix/gh424-roadmap-status-marker` | 11 files, +763/-114 | 2 | 4 d |
| `~/Documents/GH Repos/XYZ-forge-merge-cleanup-docs` | `fix/merge-cleanup-docs` | 1 file, +3/-2 | 0 | today |

Only `feat/gh299-gen4-ate` still has a remote branch; the rest are local-only,
so deleting the folder destroys the work.

## Notes

- `gh` fails inside the Bash sandbox with a TLS `x509: OSStatus -26276` error.
  Run GitHub CLI calls unsandboxed.
- 11 vendored `.xyz/` harness copies also flagged at session start; separate
  cleanup via `relay-automation/xyz-sync.sh list`.
