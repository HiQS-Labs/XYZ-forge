---
complexity: 2
risk: 3
effort: 2
title: Marathon headless-build robustness (task-scoped tick claim reaping)
status: Completed
created: 2026-06-28
updated: 2026-06-28
owner: agent
branch: main
gh_issue: 43
source: GH-43
doc_type: project
---

# GH-43: Marathon headless-build robustness

## Status
**Completed (2026-06-28)**: Fixed by making `tick reap` task-scoped and auto-reaping leaked claims in `marathon-drive.sh` before token seeding.

## Goal
Implement the remaining fix for marathon robustness: auto-reaping leaked tick claims (GH-43-2). When turns fail (timeout, collision) without properly releasing their tokens, the per-agent claim-cap blocks subsequent runs.

## Bet / Blast Radius / Reversibility
**Bet:** Extending `tick reap` to accept a `--task <id>` argument and invoking it in `marathon-drive.sh` *before* seeding is the safest way to clear leaked claims for a specific run without wiping an agent's claims globally.
**Tradeoff:** Ripping claims from a stalled marathon is safe here because we rely entirely on the GH-42 lock (`.git/relay-driver.lock`) to guarantee no concurrent live peer holds the claim. A blanket task-scoped reap works because we are the only driver running.
**Failure mode:** If `tick reap` fails, the marathon continues and might hit the claim limit again.
**Reversibility:** Easy. Can be reverted in the bash script and `src/scope.js`.
**Blast radius:** Moderate. Touches `tick` core (`scope.js`), but only the `reap` command which is a manual/recovery tool.

## Execution Plan
1. In `src/scope.js` `reap()`, add support for filtering by `task`.
2. In `bin/tick`, parse the `--task <task>` flag for the `reap` command and pass it to `scope.reap`.
3. In `relay-automation/marathon-drive.sh` (Step 3), call `"$TICK_BIN" reap "$BUILDER" --by marathon-drive --task "$RELAY_TASK"` (and the same for `$REVIEWER`) before creating/claiming the task.

## Fix
Enhance `tick reap` to optionally target a specific task (`--task <task>`), rather than indiscriminately reaping all claims for an agent. Then, update `marathon-drive.sh` to auto-reap the `BUILDER` and `REVIEWER` claims for the specific task BEFORE seeding a new token, ensuring a clean slate for the current marathon run.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash validate.sh",
  "artifacts": [ "bin/tick", "src/scope.js", "relay-automation/marathon-drive.sh" ],
  "lanes": { "orchestrator_only": [] }
}
```
