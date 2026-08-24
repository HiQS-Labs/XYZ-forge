---
title: "GH-114: headless agy -p stalls on TTY allocation / network waits until the idle watchdog kills it (exit 7)"
status: active
created: 2026-08-22
updated: 2026-08-22
owner: orchestrator (Claude Code)
goal: stop headless builder turns from dying idle on TTY allocation — no /dev/tty dependency headless, and idle-kill attribution that names the real blocker
gh_issue: 114
source: https://github.com/HiQS-Labs/XYZ-forge/issues/114
branch: gh-114/headless-tty-idle-hang
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
related:
  - "#113 — same headless agy-turn seam (scratch containment); shared artifact relay-automation/agy-turn.sh"
---

# GH-114 — headless agy TTY/idle hang

## Status

| What was just completed | What's next |
|---|---|
| capture doc + preflight contract written (ready, exit 0); queued as Bulkhead wave 6 (2026-08-22, release 0.7.3 "Bulkhead", #179) | Operator fires the marathon lane per MARATHON-PLAN-2026-08-23.md; builder executes ## Plan, reviewer verifies ## Acceptance |


Release 0.7.3 "Bulkhead" manifest member. Radar 2026-08-22: headless-reliability class.

## Bug

`agy -p` under `agy-turn.sh` periodically stalls with no worktree progress and ~0 CPU until
the 300s idle watchdog kills it (observed at ~431s and ~685s of a 900s cap, exit 7
`timeout-idle-no-progress`). Logged CLI error: `bubbletea: could not open TTY: open /dev/tty:
device not configured` — the TUI layer wants a TTY that headless turns do not have, and the
process blocks instead of failing fast.

## Plan

1. `utils/py/agy-turn.py` (authoritative Python lane; the Bash twin is FROZEN per GH-308):
   force a fully headless invocation (no TTY probe path —
   env/flags per agy's CLI; stdin from /dev/null) so bubbletea never attempts /dev/tty; if the
   CLI still requires one, wrap with `script -q /dev/null` as the documented pty shim.
2. Idle-kill attribution: when the watchdog fires, capture the child's last stderr lines and
   open fds into the turn log so "blocked on TTY" vs "blocked on network" is stated, not guessed.
3. `test/gh114-headless-tty.sh`: run the turn wrapper with no controlling TTY and assert the
   agy invocation path does not touch /dev/tty (stubbed agy asserting its stdio) and that a
   simulated stall produces the attribution block. Register in validate.sh TESTS.

## Acceptance

- [ ] A headless turn with no controlling TTY never logs the `bubbletea: could not open TTY` error.
- [ ] A watchdog idle-kill's log carries an attribution block naming the real blocker (TTY vs. network vs. lock).
- [ ] `test/gh114-headless-tty.sh` green and registered in validate.sh.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/gh114-headless-tty.sh" } ],
  "artifacts":     [ "utils/py/agy-turn.py", "test/gh114-headless-tty.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh114-headless-tty.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "headless turns never attempt /dev/tty; idle-kills name the real blocker in the turn log; gh114 suite green" },
  "lanes":         { "agy_safe": [ "test/gh114-headless-tty.sh" ], "orchestrator_only": [ "relay-automation/" ] }
}
```

## Lessons Learned (For Future Agents)

- A TUI layer that wants /dev/tty does not fail fast headless — it BLOCKS at ~0 CPU until the
  idle watchdog kills it, which misreads as a network stall. Provision the pty (or force the
  no-TTY path) at invocation time rather than diagnosing the hang after the fact.
- Attribution beats retries: an idle-kill log that names the blocker (TTY vs network vs lock)
  turns a 900s mystery into a one-line diagnosis; capture the child's last stderr and open fds
  at watchdog fire.
- The Bash lib and the Python lane must land the same behavior together — a fix in one lane
  with a frozen twin is a fix that vanishes on the fallback path.
