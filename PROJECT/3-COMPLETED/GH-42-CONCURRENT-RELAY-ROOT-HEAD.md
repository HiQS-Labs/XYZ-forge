---
complexity: 2
risk: 3
effort: 2
title: Concurrent relay/marathon on one clone resets ROOT HEAD (single-writer guard)
status: Completed
created: 2026-06-28
updated: 2026-06-28
owner: agent
branch: main
gh_issue: 42
source: GH-42
doc_type: project
---

# GH-42: Concurrent relay/marathon on one clone resets ROOT HEAD

## Status
**Completed (2026-06-28)**: Fixed by adding a repo-level directory lock (`.git/relay-driver.lock`) to both marathon-drive.sh and relay-drive.sh.

## Goal
Prevent a concurrent relay or marathon session from destroying the other's in-progress work. Currently, `rtl_enforce` resets `ROOT HEAD` if it detects changes, which orphans any peer's commits if multiple sessions run on the same clone.

## Bet / Blast Radius / Reversibility
**Bet:** A simple `mkdir`-based directory lock in the two driver entrypoints (`marathon-drive.sh` and `relay-drive.sh`) is sufficient to prevent concurrent execution on the same clone without changing the underlying `rtl_enforce` behavior.
**Tradeoff:** We block valid concurrent non-mutating reads if they use these entrypoints, but safety is paramount.
**Failure mode:** If a process crashes without triggering `trap EXIT`, the `.git/relay-driver.lock` might be left behind, requiring manual removal.
**Reversibility:** Easy. Can be reverted without touching coordination logs.
**Blast radius:** Small. Touches only the outer driver loops; turn-takers (`relay-turn-lib.sh`) remain untouched.

## Execution Plan
1. In `relay-automation/marathon-drive.sh`, inject an atomic `mkdir "$ROOT/.git/relay-driver.lock"` immediately after path resolution. Exit 1 if it fails.
2. Register a `trap` to `rmdir` the lock on exit.
3. Export `RELAY_DRIVER_LOCKED=1` to signal to downstream drivers.
4. In `relay-automation/relay-drive.sh`, add the identical logic but wrap it in `if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then` to allow `marathon-drive.sh` to safely delegate to it.

## Fix
Implement a single-writer guard using a repo-level lock (`.git/relay-driver.lock`) inside the drivers (`marathon-drive.sh` and `relay-drive.sh`). If the lock is held, the driver will immediately exit with a clear error, preventing concurrent runs on the same clone.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash validate.sh",
  "artifacts": [ "relay-automation/marathon-drive.sh", "relay-automation/relay-drive.sh" ],
  "lanes": { "orchestrator_only": [] }
}
```
