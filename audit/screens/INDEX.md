# Screenshot index

Every image below was rendered from the log beside it, and every log is the captured
stdout/stderr of a command that actually ran during `bash audit/repro-containment.sh`.
Nothing here is a mockup or a re-typed transcript. Diff any PNG against its `.log` to check.

Probes run in **four-frame sequences** so the violation and its undo are both visible:
before → the hostile agent → the harness verdict → the post-state that proves the revert.

| # | Screenshot | Frame | What it shows | Log | Ref |
|---|---|---|---|---|---|
| 1 | `c0-bash-1-before.png` | 1 · before — baseline state | Control: well-behaved agent | `audit/logs/c0-bash-1-before.log` | C0 |
| 2 | `c0-bash-2-agent.png` | 2 · the fake agent / the mechanism | Control: well-behaved agent | `audit/logs/c0-bash-2-agent.log` | C0 |
| 3 | `c0-bash-3-verdict.png` | 3 · verdict — harness response + exit code | Control: well-behaved agent | `audit/logs/c0-bash-3-verdict.log` | C0 |
| 4 | `c0-bash-4-after.png` | 4 · after — proof the undo landed | Control: well-behaved agent | `audit/logs/c0-bash-4-after.log` | C0 |
| 5 | `c0-python-1-before.png` | 1 · before — baseline state | Control: well-behaved agent | `audit/logs/c0-python-1-before.log` | C0 |
| 6 | `c0-python-2-agent.png` | 2 · the fake agent / the mechanism | Control: well-behaved agent | `audit/logs/c0-python-2-agent.log` | C0 |
| 7 | `c0-python-3-verdict.png` | 3 · verdict — harness response + exit code | Control: well-behaved agent | `audit/logs/c0-python-3-verdict.log` | C0 |
| 8 | `c0-python-4-after.png` | 4 · after — proof the undo landed | Control: well-behaved agent | `audit/logs/c0-python-4-after.log` | C0 |
| 9 | `c1-bash-1-before.png` | 1 · before — baseline state | Attack: git commit mid-turn | `audit/logs/c1-bash-1-before.log` | C1 |
| 10 | `c1-bash-2-agent.png` | 2 · the fake agent / the mechanism | Attack: git commit mid-turn | `audit/logs/c1-bash-2-agent.log` | C1 |
| 11 | `c1-bash-3-verdict.png` | 3 · verdict — harness response + exit code | Attack: git commit mid-turn | `audit/logs/c1-bash-3-verdict.log` | C1 |
| 12 | `c1-bash-4-after.png` | 4 · after — proof the undo landed | Attack: git commit mid-turn | `audit/logs/c1-bash-4-after.log` | C1 |
| 13 | `c2-bash-1-before.png` | 1 · before — baseline state | Attack: edit outside the allowlist | `audit/logs/c2-bash-1-before.log` | C2 |
| 14 | `c2-bash-2-agent.png` | 2 · the fake agent / the mechanism | Attack: edit outside the allowlist | `audit/logs/c2-bash-2-agent.log` | C2 |
| 15 | `c2-bash-3-verdict.png` | 3 · verdict — harness response + exit code | Attack: edit outside the allowlist | `audit/logs/c2-bash-3-verdict.log` | C2 |
| 16 | `c2-bash-4-after.png` | 4 · after — proof the undo landed | Attack: edit outside the allowlist | `audit/logs/c2-bash-4-after.log` | C2 |
| 17 | `c3-bash-1-before.png` | 1 · before — baseline state | Attack: hang past the watchdog ceiling | `audit/logs/c3-bash-1-before.log` | C3 |
| 18 | `c3-bash-2-agent.png` | 2 · the fake agent / the mechanism | Attack: hang past the watchdog ceiling | `audit/logs/c3-bash-2-agent.log` | C3 |
| 19 | `c3-bash-3-verdict.png` | 3 · verdict — harness response + exit code | Attack: hang past the watchdog ceiling | `audit/logs/c3-bash-3-verdict.log` | C3 |
| 20 | `c3-bash-4-after.png` | 4 · after — proof the undo landed | Attack: hang past the watchdog ceiling | `audit/logs/c3-bash-4-after.log` | C3 |
| 21 | `c4-bash-1-before.png` | 1 · before — baseline state | Attack: exit 0 having done nothing | `audit/logs/c4-bash-1-before.log` | C4 |
| 22 | `c4-bash-2-agent.png` | 2 · the fake agent / the mechanism | Attack: exit 0 having done nothing | `audit/logs/c4-bash-2-agent.log` | C4 |
| 23 | `c4-bash-3-verdict.png` | 3 · verdict — harness response + exit code | Attack: exit 0 having done nothing | `audit/logs/c4-bash-3-verdict.log` | C4 |
| 24 | `c4-bash-4-after.png` | 4 · after — proof the undo landed | Attack: exit 0 having done nothing | `audit/logs/c4-bash-4-after.log` | C4 |
| 25 | `c5-bash-1-before.png` | 1 · before — baseline state | Attack: off-lane under worktree isolation | `audit/logs/c5-bash-1-before.log` | C5 |
| 26 | `c5-bash-2-agent.png` | 2 · the fake agent / the mechanism | Attack: off-lane under worktree isolation | `audit/logs/c5-bash-2-agent.log` | C5 |
| 27 | `c5-bash-3-verdict.png` | 3 · verdict — harness response + exit code | Attack: off-lane under worktree isolation | `audit/logs/c5-bash-3-verdict.log` | C5 |
| 28 | `c5-bash-4-after.png` | 4 · after — proof the undo landed | Attack: off-lane under worktree isolation | `audit/logs/c5-bash-4-after.log` | C5 |
| 29 | `c6-bash-1-before.png` | 1 · before — baseline state | Attack: commit under worktree isolation | `audit/logs/c6-bash-1-before.log` | C6 |
| 30 | `c6-bash-2-agent.png` | 2 · the fake agent / the mechanism | Attack: commit under worktree isolation | `audit/logs/c6-bash-2-agent.log` | C6 |
| 31 | `c6-bash-3-verdict.png` | 3 · verdict — harness response + exit code | Attack: commit under worktree isolation | `audit/logs/c6-bash-3-verdict.log` | C6 |
| 32 | `c6-bash-4-after.png` | 4 · after — proof the undo landed | Attack: commit under worktree isolation | `audit/logs/c6-bash-4-after.log` | C6 |
| 33 | `c7-bash-1-before.png` | 1 · before — baseline state | Attack: off-lane AND timeout together | `audit/logs/c7-bash-1-before.log` | C7 |
| 34 | `c7-bash-2-agent.png` | 2 · the fake agent / the mechanism | Attack: off-lane AND timeout together | `audit/logs/c7-bash-2-agent.log` | C7 |
| 35 | `c7-bash-3-verdict.png` | 3 · verdict — harness response + exit code | Attack: off-lane AND timeout together | `audit/logs/c7-bash-3-verdict.log` | C7 |
| 36 | `c7-bash-4-after.png` | 4 · after — proof the undo landed | Attack: off-lane AND timeout together | `audit/logs/c7-bash-4-after.log` | C7 |
| 37 | `c8-bash-1-before.png` | 1 · before — baseline state | Attack: fork a child that outlives the kill | `audit/logs/c8-bash-1-before.log` | F9 |
| 38 | `c8-bash-2-agent.png` | 2 · the fake agent / the mechanism | Attack: fork a child that outlives the kill | `audit/logs/c8-bash-2-agent.log` | F9 |
| 39 | `c8-bash-3-verdict.png` | 3 · verdict — harness response + exit code | Attack: fork a child that outlives the kill | `audit/logs/c8-bash-3-verdict.log` | F9 |
| 40 | `c8-bash-4-after.png` | 4 · after — proof the undo landed | Attack: fork a child that outlives the kill | `audit/logs/c8-bash-4-after.log` | F9 |
| 41 | `containment-flow.png` | standalone | Rendered CONTAINMENT-FLOW.mmd | `(rendered from audit/CONTAINMENT-FLOW.mmd)` | - |
| 42 | `d1-1-what-the-default-is.png` | 1 · before — baseline state | Default lane (XYZ_PYTHON unset) on Windows | `audit/logs/d1-1-what-the-default-is.log` | F7 |
| 43 | `d1-2-real-tick-under-python.png` | 2 · the fake agent / the mechanism | Default lane (XYZ_PYTHON unset) on Windows | `audit/logs/d1-2-real-tick-under-python.log` | F7 |
| 44 | `d1-3-default-turn.png` | 3 · verdict — harness response + exit code | Default lane (XYZ_PYTHON unset) on Windows | `audit/logs/d1-3-default-turn.log` | F7 |
| 45 | `d1-4-after.png` | 4 · after — proof the undo landed | Default lane (XYZ_PYTHON unset) on Windows | `audit/logs/d1-4-after.log` | F7 |
| 46 | `env-pyshim.png` | standalone | Python lane forced onto PATH | `audit/logs/env-pyshim.log` | F7 |
| 47 | `env-stamp.png` | standalone | Environment stamp for this run | `audit/logs/env-stamp.log` | - |
| 48 | `gate-recursion.png` | standalone |  | `audit/logs/gate-recursion.log` | - |
| 49 | `turn-sequence.png` | standalone | Rendered TURN-SEQUENCE.mmd | `(rendered from audit/TURN-SEQUENCE.mmd)` | - |
| 50 | `validate-summary.png` | standalone |  | `audit/logs/validate-summary.log` | - |

**Total frames:** 50

## Orphan check

No orphans: every PNG has its log and every log has its PNG.
