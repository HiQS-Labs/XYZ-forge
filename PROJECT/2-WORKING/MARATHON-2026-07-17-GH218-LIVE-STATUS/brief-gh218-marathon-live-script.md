---
title: "Phase brief: GH-218 marathon-live.sh (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-17
updated: 2026-07-17
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the
  gh218-marathon-live-script phase — not itself an active-doc capture; the canonical capture doc
  is GH-218-CROSS-REPO-LIVE-MARATHON-STATUS.md one level up.
roadmap_exempt: true
---

## Status

| What was just completed | What's next |
|---|---|
| Brief authored 2026-07-17. | Fire this phase via the marathon. |

## Phase: gh218-marathon-live-script — new utils/hq/marathon-live.sh

Full context: [GH-218-CROSS-REPO-LIVE-MARATHON-STATUS.md](../GH-218-CROSS-REPO-LIVE-MARATHON-STATUS.md).
GitHub issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/218

### Do NOT build a server of any kind

This phase is explicitly scoped to a read-only, on-demand shell script. No MCP server, no daemon,
no long-running process, no network listener, in this phase or the next. Everything needed is a
local file/process read already available today. If you find yourself reaching for a server
framework, stop — you're off-scope.

### What already exists — reuse, don't reinvent

- `utils/hq/hq-lib.sh`'s `hq_known_repos` — every distinct repo name any registry knows (reads the
  XYZ install registry, rebalance's project registry, git-pulse's PDDA registry). Already used by
  `utils/hq/marathon-scan.sh` — read that script's existing repo-enumeration loop as your template.
- `hq_repo_resolve <repo>` — given a repo name, emits `REPO_PATH=` (absolute path) and (when the
  repo has a vendored install) `XYZ_PATH=` (the `.xyz` install dir — so the tick binary for a
  vendored repo is `$XYZ_PATH/bin/tick`; for a non-vendored repo with the harness natively, it's
  `$REPO_PATH/bin/tick`).
- `tick project` — run inside a repo (or with `TICK_REPO_ROOT` pointed at it), this regenerates
  `.tick/STATE.md` from that repo's own `.tick/events/` log. Its `## Claimed` section lists
  `- <task-id> by <claimant> paths: [...]` lines — this IS the live in-progress signal. Task IDs
  already encode the marathon/lane name (e.g. `MARATHON-GH208-WORKTREE-ISOLATION-RACE-TURN` ->
  repo's own marathon "GH208...", or generically whatever the task id says).
- The driver lock: `.git/relay-driver.lock` for a native install, or the vendored equivalent
  (check `relay-automation/marathon-drive.sh`'s own lock-path resolution, added recently for
  GH-149, for exactly how a vendored `.xyz/` install's lock differs) — its presence means a
  marathon-drive.sh/relay-drive.sh process currently holds it (actively driving right now), its
  absence means nothing is driving this instant even if tasks are still `Claimed`.
- `git worktree list` (run with `-C <REPO_PATH>`) — a worktree whose branch matches `marathon/*`
  with a commit or dirty status in roughly the last 30 minutes is a secondary corroborating signal
  of recent activity (not required to be exact — this is a diagnostic aid, not the ground truth).

### What to build

`utils/hq/marathon-live.sh`:
1. Enumerate repos via `hq_known_repos` + `hq_repo_resolve`, mirroring `marathon-scan.sh`'s
   existing loop shape and CLI flag conventions (`--out FILE`, `--help`).
2. For each resolved repo, locate its tick binary (native or vendored, per above), run
   `tick project` scoped to that repo (set `TICK_REPO_ROOT`/cwd as needed — check how
   `find-harness.sh` or `marathon-scan.sh` already do this for a vendored repo), and parse
   `.tick/STATE.md`'s `## Claimed` section.
3. For each claimed task, cross-check the driver lock file and `git worktree list` for that repo,
   and classify: `live` (lock held, or a `marathon/*` worktree active in the last ~30 min) vs.
   `claimed (idle)` (task claimed but no corroborating live signal).
4. Emit ONE compact Markdown table: `Repo | Marathon/lane | Task | Claimant | Live? | Last activity`.
   Repos with nothing claimed can be omitted from the table or listed as "idle" — your call, note
   which you chose in the findings.
5. Read-only over every target repo (never write into them) — same safety posture as
   `marathon-scan.sh`. The only write is the `--out` report file, in this hub repo.

### Test

New `test/hq-marathon-live.sh`. At minimum, prove with fixtures (reuse `marathon-scan.sh`'s own
fixture-repo pattern if one exists, or build the smallest equivalent):
- a repo with a live claim + held driver lock → reported `live`
- a repo with a claim but no lock and no recent worktree activity → reported `claimed (idle)`
- a repo with nothing claimed → reported idle/omitted per your choice above
- a repo that fails to resolve (unknown/offline) is skipped gracefully, not a hard failure for the
  whole scan (same degrade-gracefully posture as `marathon-scan.sh`)

### Acceptance / done means

- `utils/hq/marathon-live.sh` exists, is read-only over target repos, reuses `hq_known_repos`/
  `hq_repo_resolve`/`tick project` rather than reimplementing any of them.
- `test/hq-marathon-live.sh` passes and is registered in `validate.sh`'s test array.
- `bash validate.sh` green (or unchanged from before your change).
- No server, daemon, or long-running process was introduced anywhere.
