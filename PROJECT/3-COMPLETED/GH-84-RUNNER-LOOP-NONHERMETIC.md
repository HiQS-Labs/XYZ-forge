---
gh_issue: 84
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/84
title: test/runner-loop.sh non-hermetic — runner.sh dirty-guard checks the real repo
status: Queued
created: 2026-07-02
updated: 2026-07-02
owner: noel
doc_type: bug
complexity: 1
risk: 1
effort: 1
roadmap_exempt: false
non_goals:
  - Not a change to the live relay dirty-tree guard's behavior — the guard is correct in real runs (the runner commits to the repo it lives in); this only makes the TEST hermetic
  - Not touching the kernel serialization path (relay-turn-lib.sh / bin/tick / relay-drive.sh) — runner.sh is not a kernel-bottleneck file
  - No new guard semantics — the RUNNER_ROOT_DIR override defaults to the current self-location behavior, so an unset env is byte-for-byte today's behavior
related:
  - relay-automation/runner.sh
  - test/runner-loop.sh
---

# GH-84 — test/runner-loop.sh non-hermetic

## Bug

`test/runner-loop.sh` false-fails with `runner: artifact paths have unstaged changes` whenever the
**real** `README.md` has uncommitted edits, despite running in a hermetic temp repo
(`TICK_REPO_ROOT=$A`). Surfaced by GH-83: `validate.sh` went red on `runner-loop` mid-README-edit and
green the instant README was committed.

## Root cause

`relay-automation/runner.sh:4` resolves `ROOT_DIR` from its own script location (the real repo), not
from `TICK_REPO_ROOT`. The dirty guard (`runner.sh:71`, `git -C "$ROOT_DIR" diff --quiet -- <artifacts>`)
therefore checks the **real** repo. `test/runner-loop.sh:27` passes `-- README.md` (a real tracked
file) as the artifact, so a dirty real README trips the guard. Live relay use is correct; this is a
**test-side hermeticity leak** — same class as GH-74 / GH-44.

## Fix direction

Add an optional `RUNNER_ROOT_DIR` env override in `runner.sh` (default = current self-location, so live
containment is unchanged when unset); `test/runner-loop.sh` sets it to `$A` so the guard checks the
hermetic temp repo. Add a regression assertion: the test passes with a deliberately-dirtied real
tracked file.

## Definition of done

- `bash test/runner-loop.sh` passes regardless of the real working tree's cleanliness.
- `runner.sh` default `ROOT_DIR` unchanged when `RUNNER_ROOT_DIR` is unset (no live-relay behavior change).
- `validate.sh` green.

## Swarm Preflight Contract

Consumed by `utils/swarm-preflight.sh`. Same-repo build (`target.ref: main`); both the source
(`relay-automation/runner.sh`) and its test (`test/runner-loop.sh`) already exist — a fix that extends
them, not greenfield. Independent zone — `runner.sh` is not a kernel-serialization path. Codex lane.

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash test/runner-loop.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "relay-automation/runner.sh", "pattern": "GH-84" } ],
  "artifacts":   [ "relay-automation/runner.sh", "test/runner-loop.sh" ],
  "remediation": { "source": "GH-84#fix-direction", "criteria": "runner.sh honors an optional RUNNER_ROOT_DIR override for its dirty/staged artifact guard (default unset = current self-location behavior, byte-for-byte unchanged for live relay); test/runner-loop.sh sets it to $A and adds a regression case proving a dirtied real tracked file no longer false-fails the runner; the change carries a GH-84 marker comment." },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
