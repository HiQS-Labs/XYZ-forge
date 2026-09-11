---
gh_issue: 533
source: https://github.com/HiQS-Labs/XYZ-forge/issues/533
title: "Relay scaffold verdict vocabulary contradicts validate-relay-block"
status: 2-WORKING
created: 2026-09-10
updated: 2026-09-10
owner: unassigned
doc_type: capture
complexity: 1
risk: 2
effort: 1
ratings_provisional: false
goal: "Give the scaffold, validator, driver, and reviewer one explicit verdict vocabulary."
---

## Status

| What was just completed | What's next |
|---|---|
| Reproduced on GH-508 and GH-562: the scaffold asks for Approved/Changes requested/Blocked while the validator accepts only PASS/FAIL/PARKED plus Basis. | Pick and enforce one canonical vocabulary, retaining deliberate compatibility only where tested. |

## Acceptance

- [ ] The generated reviewer instructions name every required terminal field and the exact values accepted by `bin/validate-relay-block`.
- [ ] A reviewer following those instructions passes structural validation for PASS, FAIL, and PARKED.
- [ ] Invalid or ambiguous verdict values fail with exit 8 and a precise diagnostic.
- [ ] Tests render the real scaffold and pass it through the real validator.

## Swarm Preflight Contract

```json
{
  "target": {"repo": ".", "ref": "development"},
  "gate": "bash test/new-relay.sh && bash test/gh410-relay-block-driven-path.sh",
  "fix_probes": [
    {"type": "grep_present", "path": "relay-automation/new-relay.sh", "pattern": "Approved \\| Changes requested \\| Blocked", "note": "bug evidence: emitted vocabulary is rejected by the structural validator"}
  ],
  "artifacts": ["relay-automation/new-relay.sh", "bin/validate-relay-block", "test/new-relay.sh", "test/gh410-relay-block-driven-path.sh"],
  "remediation": {"source": "issue#533", "criteria": "the real scaffold and validator agree on verdict values and Basis; all accepted values pass and an invalid value fails"},
  "lanes": {"agy_safe": ["relay-automation/new-relay.sh", "bin/validate-relay-block", "test/new-relay.sh", "test/gh410-relay-block-driven-path.sh"], "orchestrator_only": []}
}
```
