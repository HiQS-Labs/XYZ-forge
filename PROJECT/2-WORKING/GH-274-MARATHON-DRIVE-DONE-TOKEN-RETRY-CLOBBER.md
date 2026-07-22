---
gh_issue: 274
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/274
title: "marathon-drive: re-invoking a phase whose tick token is already done clobbers RELAY.md's Approved record instead of detecting a satisfied lane"
status: "captured 2026-07-21, found live during GH-273 Phase 0's fire — not yet fired"
created: 2026-07-21
updated: 2026-07-21
owner: noel
doc_type: bug
complexity: 3
risk: 2
effort: 2
phases: 1
ratings_provisional: true
related:
  - "PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md — where this was found, live, during Phase 0's real fire"
  - "phases/p1/ESCALATION.md — the incident record + manual recovery (git revert of the bad re-render)"
  - "GH-207 — the existing 'satisfied-lane recovery' fix this extends (currently only covers a --review-once reroute, not a post-terminal gate retry)"
non_goals:
  - Auto-retrying a failed gate on its own — the operator/--post-approve-cmd caller still decides
    when to retry. This is only about not corrupting state when they do.
  - Changing done-token immutability in tick — that's correct behavior; the fix is marathon-drive
    recognizing the already-terminal state up front, not working around tick.
goal: >
  Make marathon-drive.sh detect a phase whose relay already reached a terminal Approved state (tick
  task done) before re-rendering RELAY.md, so retrying just the pre-advance gate after a flaky
  failure doesn't clobber the accurate execution record.
---

# GH-274 · marathon-drive done-token retry clobbers the Approved record

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-07-21 from a live incident during GH-273 Phase 0's real fire: the relay succeeded (Codex + agy, Approved), the `bash validate.sh` pre-advance gate flaked on an unrelated pre-existing test, and re-invoking `marathon-drive.sh` to retry the gate instead re-rendered `RELAY.md` back to `STATUS: Open` and failed on the already-`done` tick token. Recovered manually via `git revert`; full narrative in `phases/p1/ESCALATION.md`. | Fire when convenient — not blocking, workaround is manual `git revert` + close out by hand (as done for GH-273 Phase 0). |

## Problem

`marathon-drive.sh` has no path that detects "this phase's relay already reached a terminal
Approved state, the tick task is `done`, only re-run `--pre-advance-cmd`" — it unconditionally
re-renders the phase's `RELAY.md` from the phase brief on every invocation, then tries to re-seed
the tick token. A `done` tick token cannot be reopened (existing, correct behavior), so the retry
fails at Step 3 (exit 1) — but only *after* Step 2 has already committed a fresh `STATUS: Open`
render over the accurate Approved one.

Full repro trace: GH-273's `phases/p1/ESCALATION.md` § Resolution, and
`PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md`'s Status table (2026-07-21 entry).

**Impact:** an operator can't safely retry just the gate after a flaky pre-advance failure without
first manually inspecting `RELAY.md`/tick state and reverting the bad re-render. For a fully
unattended caller (relevant once GH-273 Phase 4's `--post-approve-cmd` ships) this would silently
corrupt the phase's own execution record on every gate-flake retry.

## Fix direction

Before Step 2's render in `marathon-drive.sh` (and the Python twin), if `$RELAY_FILE` already
exists with a terminal `STATUS:` *and* the corresponding tick task is `status: done`, treat the
phase as a **satisfied lane**: skip the re-render + re-seed, and go straight to re-running (only)
`--pre-advance-cmd`. Same shape as the GH-207 satisfied-lane fix already shipped for a different
trigger (`--review-once` reroute) — extend that detection to also cover "gate failed after an
already-terminal relay," not just the mid-relay reroute case it currently handles.

## Definition of done

- [ ] Re-invoking `marathon-drive.sh` for a phase whose `RELAY.md` is already terminal (Approved)
      and whose tick task is `done` skips the render/reseed and re-runs only `--pre-advance-cmd`.
- [ ] A regression test in `test/marathon-drive.sh` covers this exact sequence: happy-path approval
      → pre-advance gate fails → re-invoke → gate re-run only, `RELAY.md` untouched.
- [ ] `bash validate.sh` no worse than baseline.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/marathon-drive.sh", "pattern": "satisfied.*done.*pre-advance|pre-advance.*retry.*satisfied" }
  ],
  "artifacts": [ "relay-automation/marathon-drive.sh", "utils/py/marathon_drive.py", "test/marathon-drive.sh" ],
  "artifacts_new": [],
  "remediation": {
    "source": "issue#274",
    "criteria": "marathon-drive.sh (both Bash and Python) detects a phase whose RELAY.md is already terminal and whose tick task is done, skips re-render/re-seed on re-invocation, and re-runs only --pre-advance-cmd; a new test/marathon-drive.sh case covers the exact sequence; validate.sh no worse than baseline."
  },
  "lanes": { "agy_safe": [ "test/marathon-drive.sh" ], "orchestrator_only": [ "relay-automation/marathon-drive.sh", "utils/py/marathon_drive.py" ] }
}
```
