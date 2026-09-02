---
gh_issue: 370
source: https://github.com/HiQS-Labs/XYZ-forge/issues/370
title: "Mid-turn blindness: add worktree-progress telemetry to the supervisor poll loop (0-byte turn logs are the norm)"
goal: >
  the supervisor must emit worktree progress telemetry during a turn
status: 2-WORKING
# Staged 2026-09-01 by the LTVera marathon orchestrator alongside the marathon plan at
# PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/ — commit to XYZ-forge when the
# marathon fires. Exempt from ROADMAP parking while it travels inside the plan bundle.
roadmap_exempt: true
created: 2026-09-01
updated: 2026-09-01
owner: unassigned
doc_type: capture
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
related:
  - "all seven findings originate from one live run: the 2026-09-01 LTVera health-and-isolation marathon"
---

# GH-370 — Mid-turn blindness

Capture of [XYZ-forge issue #370](https://github.com/HiQS-Labs/XYZ-forge/issues/370).

Observed 2026-09-01: the agy CLI buffers all output until exit, so a turn's log was
0 bytes for 78 minutes while the process showed live CPU. The supervisor's only live
signal was RSS. A spinning turn and a productive turn are indistinguishable until the
cap (which, per #369, did not fire either).

## Remediation

In the relay_drive poll loop (`while proc.poll() is None`), sample the turn
worktree's changed-file count (`git -C <worktree> status --porcelain | wc -l`) on a
throttled interval (~60 s) into the run log. Bash twin parity per repo convention.

The fix MUST leave a `GH-370` marker comment at the primary change site — the
preflight probe below keys on it.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "utils/py/relay_drive.py",
      "pattern": "GH-370"
    }
  ],
  "artifacts":   ["utils/py/relay_drive.py"],
  "remediation": {
    "source": "issue#370",
    "criteria": "Mid-turn blindness: add worktree-progress telemetry to the supervisor poll loop"
  },
  "lanes": {
    "agy_safe": [
      "utils/py/relay_drive.py",
      "relay-automation/relay-drive.sh"
    ],
    "orchestrator_only": []
  }
}
```
