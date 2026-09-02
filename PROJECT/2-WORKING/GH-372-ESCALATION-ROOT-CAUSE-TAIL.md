---
gh_issue: 372
source: https://github.com/HiQS-Labs/XYZ-forge/issues/372
title: "Turn-taker failure reason never reaches ESCALATION.md (codex 'workspace out of credits' surfaced as generic no-progress)"
goal: >
  a failed turn must surface its log tail in ESCALATION.md
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

# GH-372 — Turn-taker failure reason never reaches ESCALATION.md (codex 'workspace out of credits' surfaced as generic no-progress)

## Status

| What was just completed | What's next |
|---|---|
| Capture doc authored with preflight contract. | Marathon phase execution. |

Capture of [XYZ-forge issue #372](https://github.com/HiQS-Labs/XYZ-forge/issues/372).

Observed 2026-09-01: `codex exec` died immediately with `ERROR: Your workspace is
out of credits.` — ESCALATION.md recorded only `relay-failed-before-gate`, the turn log
was not locatable from the record, and an operator could not tell "model lane dead,
switch builder" from "builder misbehaved". The lane attempt counter burned on a
configuration-level failure.

## Remediation

On turn failure/escalation, embed the last ~40 lines of the turn's log in a
collapsed block in ESCALATION.md; if the log was never created, say that explicitly —
a missing log is itself diagnostic.

The fix MUST leave a `GH-372` marker comment at the primary change site — the
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
      "pattern": "GH-372"
    }
  ],
  "artifacts":   ["utils/py/relay_drive.py"],
  "remediation": {
    "source": "issue#372",
    "criteria": "Turn-taker failure reason never reaches ESCALATION.md"
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

## Lessons Learned (For Future Agents)

- Generic failure reasons like `relay-failed-before-gate` obscure critical diagnostic details such as provider credit exhaustion or authentication errors. Embedding the trailing lines of the failing turn's log into `ESCALATION.md` provides immediate actionable context without requiring full transcript excavation.
