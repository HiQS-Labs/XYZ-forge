---
gh_issue: 369
source: https://github.com/HiQS-Labs/XYZ-forge/issues/369
title: "rtl_run_bounded's PID-only kill lets a multi-process CLI outlive its turn cap (observed: 78 min past a 2400 s cap)"
goal: >
  the turn wall-clock cap must kill the whole process group, not just the launched PID
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

# GH-369 — rtl_run_bounded's PID-only kill lets a multi-process CLI outlive its turn cap (observed

## Status

| What was just completed | What's next |
|---|---|
| Capture doc authored with preflight contract. | Marathon phase execution. |

Capture of [XYZ-forge issue #369](https://github.com/HiQS-Labs/XYZ-forge/issues/369).

Observed 2026-09-01: an agy builder turn with `turn_timeout_s: 2400` ran 78 minutes
(13+ min CPU); `rtl_run_bounded`'s watchdog killed only the launched PID while the CLI
had re-exec'd into a different process, and `--print-timeout` did not stop it either.
The operator had to kill it by hand, which surfaced as `relay-drive exited with
unexpected code 247` and burned the lane attempt. The function's own comment flags the
gap: a multi-process CLI whose children outlive the leader is a known gap.

## Remediation

Kill the child's process group: resolve the PGID (`ps -o pgid= -p $apid`) and
`kill -9 -PGID`. Mind `relay_drive.py`'s `start_new_session=True` — target the session
the CLI actually runs in. Apply to the Bash lib and the Python twin (utils/py/rtl.py)
so neither lane drifts.

The fix MUST leave a `GH-369` marker comment at the primary change site — the
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
      "path": "relay-automation/relay-turn-lib.sh",
      "pattern": "GH-369"
    }
  ],
  "artifacts":   ["relay-automation/relay-turn-lib.sh", "utils/py/rtl.py"],
  "remediation": {
    "source": "issue#369",
    "criteria": "rtl_run_bounded's PID-only kill lets a multi-process CLI outlive its turn cap"
  },
  "lanes": {
    "agy_safe": [
      "relay-automation/relay-turn-lib.sh",
      "utils/py/rtl.py"
    ],
    "orchestrator_only": []
  }
}
```
