# Recon Map — what updates the GitHub Projects board (users/noelsaw1/projects/3)

Commit: `7464fbbb` (primary checkout, branch `fix/gh502-security-dialog-detector`) ·
Mode: grep + full-file reads (codebase-memory graph not consulted; two lanes ran as read-only
sub-agents) · Lanes: **A** (call sites / skills / hooks), **D** (CI, automation, bots, schedulers).
Lanes B and C were folded into A and D — the subject is a single external contract with one
local state file, so a separate state lane had nothing distinct to own.

## Subject and change class

**Subject:** any read or write path from this repo to GitHub Projects V2 board
`https://github.com/users/noelsaw1/projects/3`.
**Change class:** discovery only — no change proposed. This map answers "what is actually there".

## Verdict

A complete board reader/writer **exists and has run against the live board**. Nothing invokes it
automatically. `start-task` has no board integration of any kind.

> Correction to an earlier answer in this session: I first reported that no board integration
> existed anywhere in the repo. That was wrong. It came from a single `rg` whose empty output I
> read as a negative without confirming the command had actually matched anything — exactly the
> failure mode `~/.claude/RTK.md` warns about. `git grep` found the subsystem immediately.

## The seams — where a board write can originate today

| Seam | Location | Crosses | Fires when |
|---|---|---|---|
| `board_sync.py` mutations | `utils/py/board_sync.py:399` (add), `:455` (set Status), `:489` (delete) | repo → live ProjectV2 | a human runs it with `--write` |
| `releases_app.py project sync` | `utils/py/releases_app.py:2945-3020` | repo → any ProjectV2 (draft cards) | a human passes `--owner` + `--number` + `--apply` |
| Local cache of board identity | `~/.xyz/board_sync_state.json` (mode 600, outside the repo) | disk → board node IDs | written on any live run |
| Server-side board workflows | the board object itself, **not in any repo** | GitHub → board | unknown; see Unknowns |

## Call paths in

**There are none that are automatic.** Every path is `human → shell`:

```
operator → python3 utils/py/board_sync.py {scan|reconcile|touch|dedupe} [--write]
operator → python3 utils/py/releases_app.py project sync --owner X --number N --apply
```

Verified empty of board calls: `.github/workflows/ci.yml` and `pages.yml` (both read in full — the
only two files under `.github/`, with `permissions: contents: read`), `githooks/pre-push` and every
other git hook, `bin/`, `relay-automation/`, `src/`, `marathon-system/`, all 52 repo skills, every
globally installed skill under `~/.claude/skills/` including `start-task`, `package.json` scripts,
`crontab` (empty), `~/.claude/scheduled_tasks.json`, and the one real scheduler in the repo — the
launchd hourly scan at `utils/hq/hourly-global-scan.sh`, which writes a local markdown report and
never touches the board.

The only callers of `board_sync.py` are its own two test suites, `test/gh402-board-sync.sh` and
`test/gh405-mock-board-harness.sh`, both of which redirect the `gh` binary to the offline fake
`utils/py/mock_gh_board.py` via `XYZ_BOARD_SYNC_GH_BIN`. `validate.sh:240-241` registers both, so
CI runs them — against the mock, never the network.

## State

- **Authoritative, local:** `releases.db` (`roadmap_items.status_marker`, `jog_queue.status`) is
  what `board_sync.py:180-190` reads to decide what to push. `🚧` is classified **weak** and never
  writes alone; `jog_queue.status='running'` is **strong** and does write.
- **Projection, remote:** the board itself. Per the tool's own design invariants
  (`board_sync.py:1-27`), the board is a cached projection and PDDA + RELEASES DB stay
  authoritative.
- **Cache, outside the repo:** `~/.xyz/board_sync_state.json`, last fetched **2026-09-03T05:10Z**,
  holds resolved project/field/option node IDs and a snapshot of 7 live cards spanning **two**
  repos — `HiQS-Labs/XYZ-forge` #382/#396/#399/#402 and `HiQS-Labs/rebalanceOS` #144/#147/#150.
  The board is shared across projects, which matters for any blast-radius estimate.

## Contracts

| Name | Consumer | Breaking if | Declared |
|---|---|---|---|
| `project_owner: "noelsaw1"`, `project_number: 3` | the live board | the board is renumbered or moved to an org | `board_sync.py:63-64` — **hardcoded defaults, no config required** |
| `gh` ambient OAuth token | every mutation | the token lacks `project` scope | `board_sync.py:239-264` |
| `XYZ_BOARD_SYNC=0` | all entry points | — | `board_sync.py:522` — global kill switch |
| `--write` required | all mutations | — | dry-run is the default everywhere |

## Build, failure and rollback today

Failure degrades rather than blocks: network failure warns, and the design contract says adapters
must background + timeout and ignore the return code so a board write can never block a host
operation. `dedupe` is the only destructive verb. Rollback for an unwanted card is manual, or
`dedupe --write`.

## Unknowns

| Unknown | Why it matters | What would settle it |
|---|---|---|
| **Server-side board workflows** ("Auto-add to project", "Item added", "Item reopened") | These live on the board object, leave **zero trace in any repository**, and would update the board with the repo 100% clean. No amount of code reading can settle it. | Board UI → `⋯` → **Workflows**. The API route is blocked below. |
| Current `gh` token cannot read the board | Attempted `gh api graphql … projectV2` returned `INSUFFICIENT_SCOPES`: token has `gist, read:org, repo, workflow`, needs `read:project`. **So the GH-402 Phase 0 spike finding — "the gh token CAN mutate the user project" — no longer holds for this token.** Any Phase 2 adapter wired today would fail on scope. | `gh auth refresh -s read:project,project` |
| Whether the board's live contents match the 2026-09-03 cache | The cache is 6 days stale; a plan sized from it would be sized from fiction. | `gh project item-list 3 --owner noelsaw1 --format json` (needs the scope above) |
| 3 other clones carry `board_sync.py` with the same hardcoded defaults | Any of them can write the live board if run. | `rg -n 'project_number' ~/task-clones/*/utils/py/board_sync.py` |
| `reconcile()` not read end-to-end | Whether it fetches a network snapshot *before* the weak/strong filter short-circuits. | Read `board_sync.py:404-461` plus the reconcile body |

## Current-state radius, one line

The live board `users/noelsaw1/projects/3` and its 7 cards across **two** repos (XYZ-forge and
rebalanceOS), the local `~/.xyz/board_sync_state.json` cache, `releases.db`'s `status_marker` and
`jog_queue` columns that drive candidate selection, the two registered test suites in `validate.sh`,
and whoever's `gh` login is on the machine — since auth is the ambient token, a board write leaves
no repo-side secret and no audit trail in `.github/`.

## Related issues

| Issue | State | Bearing |
|---|---|---|
| **#402** Board-sync: auto-add issues when any agent starts work | **OPEN** | The plan of record. Phase 0 + 1 done (`board_sync.py` + tests); **Phase 2 — adapters (pdda wiring, git hook stubs, harness fires, sweeper) is unchecked** at `PROJECT/2-WORKING/GH-402-BOARD-SYNC.md:54`. This is exactly the "make it automatic" work. |
| **#405** Mock harness for Projects V2 API | CLOSED | Shipped `utils/py/mock_gh_board.py`; why most ProjectV2 grep hits are a fake, not live traffic. |
| **#39** Project RELEASES.DB into a GitHub release board | CLOSED | The second, separate writer (`releases_app.py project sync`), draft cards, no hardcoded board. |
| **#424** Roadmap status-marker writer | OPEN | **Landmine.** Its own recon (`PROJECT/1-INBOX/recon-gh424-status-marker.md:61`) records that the `🚧` query is inert only because nothing can write `🚧` today; if #424 ships, flipping a row starts creating cards on the live board. |
