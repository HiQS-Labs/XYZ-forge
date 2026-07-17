---
title: Marathon Plan G (2026-07-17) — marathon/relay driver hardening (GH-149, GH-198)
status: Both lanes SHIPPED 2026-07-17 via the GH208-154-149-198 marathon (codex builder, agy
  reviewer, both Approved)
created: 2026-07-17
updated: 2026-07-17
owner: noel
branch: main
doc_type: project
source: found during a recent-issues (last 10 days) sweep — two small, independent driver-script
  bugs that don't fit any existing marathon plan's theme
generated_by: hand-authored (2 lanes, same-day triage)
lanes: [149, 198]
execution: parallel Sonnet subagents or a codex/agy relay via marathon-drive.sh, one per lane —
  independent write-sets, no builder/reviewer relay needed for any single lane
roadmap_exempt: true
goal: >
  Two independent driver-hardening bugs surfaced during a 2026-07-17 recent-issues sweep: GH-149
  (marathon-drive.sh's --require-clean self-trips on its own lock inside a linked worktree) and
  GH-198 (relay-drive.sh has no fail-fast preflight check for a missing Setup-referenced artifact —
  Bug 1 of this issue, a real commit-scoping bug, is already fixed separately). Neither fits Plan
  F's validate.sh/parity theme, so they get their own small plan.
---

# Marathon Plan G — 2026-07-17 · marathon/relay driver hardening

> Two small, independent driver-script bugs found during a recent-issues sweep. Neither touches a
> file the other touches, and neither collides with any currently in-flight or planned lane in
> Plan F (validate.sh gate failures / parity gaps) or Plan E (closed).

## Status

| What was just completed | What's next |
|---|---|
| **Both lanes SHIPPED 2026-07-17** via a combined 4-phase marathon (`MARATHON-2026-07-17-GH208-154-149-198/`, codex builder, agy reviewer). Lane 1 (#149): `marathon-drive.sh` resolves the driver lock via `git rev-parse --git-common-dir` in a linked worktree; new regression case in `test/marathon-drive.sh`, 105/105 green. Lane 2 (#198 Bug 2): `relay-drive.sh` gained a Setup-artifact preflight check; `test/relay-artifact-file.sh` 13/13 green. Full `bash validate.sh`: 113/114 (only the separately-fixed `relay-pkg-freshness.sh` staleness). | Both lanes done — merge the marathon branch. |

## Collision map

| Zone (shared file) | Parallel-safe? | Lane |
|---|---|---|
| `relay-automation/marathon-drive.sh` (+ `test/marathon-drive.sh`) | ✅ fireable, only one lane touches this | Lane 1 (#149) |
| `relay-automation/relay-drive.sh` (+ `test/relay-artifact-file.sh`) | ✅ fireable, only one lane touches this | Lane 2 (#198) |
| independent | ✅ fully parallel | — |

Note: Lane 1 shares `test/marathon-drive.sh` with Plan F's Lane 10 (#174) — Lane 10 is test-only
(adding an agy-leg case) while Lane 1 adds a require-clean regression case; if both plans are fired
in the same run, sequence these two rather than firing them concurrently to avoid a same-file
concurrent-edit collision. If only one plan is fired at a time, there is no conflict.

## Per-lane summary

| # | Issue | File(s) | Symptom | Class | cx/risk/eff | Fireable? |
|---|-------|---------|---------|-------|-------------|---|
| 1 | [#149](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/149) | `relay-automation/marathon-drive.sh` | `--require-clean` self-trips on its own `.relay-driver.lock` inside a linked worktree | deterministic | 2/2/2 | ✅ ready |
| 2 | [#198](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/198) | `relay-automation/relay-drive.sh` | No preflight check for a missing Setup-referenced artifact — opaque mid-turn failure | deterministic (UX gap) | 1/1/2 | ✅ ready |

Full diagnostic detail lives in [GH-149's doc](GH-149-REQUIRE-CLEAN-SELFTRIP.md) and
[GH-198's doc](GH-198-RELAY-DRIVE-ARTIFACT-PREFLIGHT.md) — each lane should read its own doc before
starting.

## Recommended waves

**Wave 1 — parallel (2 fireable lanes ‖):** Lane 1 (#149) ‖ Lane 2 (#198)

## Execution contract

- **Path:** each lane runs as a worktree-isolated Sonnet subagent (or a codex/agy relay via
  `marathon-drive.sh`), scoped via `ALLOW_PATHS`/artifact allowlist to its own source + test file.
- **Per lane:** land the fix with its regression test passing, leave a one-line status update in
  the lane's own capture doc Status table.
- **Lane 1** — fix only the lock-path resolution (`git rev-parse --git-common-dir` when
  `$ROOT/.git` is a file); do not touch unrelated `marathon-drive.sh` logic.
- **Lane 2** — add the new preflight check only; do not touch the existing `--artifact-file` check
  (already correct) or Bug 1's already-fixed commit-scoping logic (commit `bee1abf`).

## How to fire

Both lanes confirmed ready via `--dry-run` on 2026-07-17:

```
utils/swarm-preflight.sh --gh-issue 149 --dry-run   # ready (exit 0)
utils/swarm-preflight.sh --gh-issue 198 --dry-run   # ready (exit 0)
relay-automation/marathon-drive.sh ...   # build→gate→review, contained, one invocation per lane
```

After both land: re-run `bash test/marathon-drive.sh` and `bash test/relay-artifact-file.sh`, then
full `validate.sh`.
