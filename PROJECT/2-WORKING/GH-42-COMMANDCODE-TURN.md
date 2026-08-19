---
title: "GH-42: Supported Commandcode relay turn-taker"
gh_issue: 42
source: "https://github.com/HiQS-Suite/XYZ-forge/issues/42"
status: active
created: 2026-08-18
updated: 2026-08-18
owner: Codex
goal: "Ship and validate a containment-preserving Commandcode relay turn-taker."
doc_type: bugfix
---

# GH-42 — Commandcode relay turn-taker

## Status

| What was just completed | What's next |
|---|---|
| Muse Spark Contributor built the initial adapter; a live third relay review found and Codex corrected token-cleanup and child token-root propagation gaps. | Run the full clean-clone gate, publish the findings to issue #41, and open the PR. |

## Bet and boundary

The relay can safely support Commandcode only if its turn-taker reuses the existing `rtl` containment,
token, worktree, transcript, and no-push boundary. This is a **Costly** shared-safety change: an
incorrect adapter could write off lane or leave a token stranded. Rollback is removal of the new
adapter, registration, and documentation; existing worker paths remain unchanged.

## Phase 0 — compatibility spike

- Prove the installed `cmd` CLI accepts `meta/muse-spark-1.2-contributor` headlessly.
- Establish that the adapter needs a Python implementation plus a thin Bash entry point; the latter
  requires a `New-bash-exception` commit trailer.
- Result: Muse answered a bounded read-only prompt; the repository currently has no Commandcode shim.

## Delivery contract

- Add `utils/py/commandcode-turn.py` and `relay-automation/commandcode-turn.sh`.
- Reuse `RelayTurnLib`, `claim_task_or_exit`, durable logs, timeout diagnostics, worktree isolation,
  and `rtl.enforce` rather than duplicating the containment protocol.
- Offer `COMMANDCODE_AGENT`, `COMMANDCODE_BIN`, `COMMANDCODE_MODEL`, `COMMANDCODE_FLAGS`,
  `COMMANDCODE_TURN_ROOT`, and `COMMANDCODE_LOG` configuration.
- Add a registered mock test proving defer, success, CLI failure/empty output, timeout, and
  off-allowlist containment.
- Document a Commandcode worker recipe in `relay-xyz` without changing existing worker behavior.

## QA plan

- Run the focused Commandcode test and existing Codex shim test in this build clone.
- Run the full `validate.sh` suite in a separate fresh clone only.
- Have Muse Spark Contributor make the initial implementation, then independently inspect its diff,
  rerun focused tests, and capture the build plus live third-relay outcome on issue #41.
