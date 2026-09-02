---
gh_issue: 374
source: https://github.com/HiQS-Labs/XYZ-forge/issues/374
title: "Drift-brief prepends stale cross-repo registry entries (src/project.js warnings inside an LTVera run)"
goal: >
  drift-brief must not prepend registry entries whose paths do not exist in the driven repo
status: Complete
# Staged 2026-09-01 by the LTVera marathon orchestrator alongside the marathon plan at
# PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/ — commit to XYZ-forge when the
# marathon fires. Exempt from ROADMAP parking while it travels inside the plan bundle.
roadmap_exempt: true
created: 2026-09-01
updated: 2026-09-02
owner: unassigned
doc_type: capture
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
related:
  - "all seven findings originate from one live run: the 2026-09-01 LTVera health-and-isolation marathon"
---

# GH-374 — Drift-brief prepends stale cross-repo registry entries (src/project.js warnings inside an LTVera run)

## Status

| What was just completed | What's next |
|---|---|
| Capture doc authored with preflight contract. | Marathon phase execution. |

Capture of [XYZ-forge issue #374](https://github.com/HiQS-Labs/XYZ-forge/issues/374).

Observed 2026-09-01: every few turns, `dependency.drift — agy changed
src/project.js (0 lines); signalled for the next turn` — the file does not exist in the
driven repo; the entries are leftovers from another repo's drift registry. Warn-only
today, but `rtl_drift_brief` prepends the unread heads-up INTO the builder's prompt, so
stale cross-repo noise can misdirect a turn.

## Remediation

Filter drift-registry entries by path existence in the driven repo (or namespace
the registry per repo) at read time. Bash lib + Python twin (utils/py/rtl.py).

The fix MUST leave a `GH-374` marker comment at the primary change site — the
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
      "pattern": "GH-374"
    }
  ],
  "artifacts":   ["relay-automation/relay-turn-lib.sh", "utils/py/rtl.py"],
  "remediation": {
    "source": "issue#374",
    "criteria": "Drift-brief prepends stale cross-repo registry entries"
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

## Lessons Learned (For Future Agents)

- Shared or multi-repo event logs must filter entries against the target repository's tree before injecting heads-ups into agent prompts. Checking path existence prevents cross-repo drift noise from misleading builder turns.
