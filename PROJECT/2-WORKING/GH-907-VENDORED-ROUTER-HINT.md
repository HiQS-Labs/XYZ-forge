---
gh_issue: 907
source: https://github.com/HiQS-Labs/XYZ-forge/issues/907
title: "Vendored router audit hint"
status: active
created: 2026-10-01
updated: 2026-10-01
owner: XYZ Forge maintainers
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
related:
  - "#908 — serial PDDA adopter Jog"
goal: >
  Derive a runnable remediation script path from the executing file in bare and vendored layouts.
---

# Vendored router audit hint

## Status

| What was just completed | What's next |
|---|---|
| Issue #908 ordered this serial Jog; preflight passed on base 57bd97af and implementation is drafted on fix/gh908-pdda-adopter-jog. | Agy and final Codex relay QA approved; full macOS ci-local passed at 5af2ed25 with clone identity intact. Publish the PR, check hosted CI, then await operator merge approval. |

## Observed problem

router_audit.py prints an unqualified script path under .xyz/ installs. Source: [issue #907](https://github.com/HiQS-Labs/XYZ-forge/issues/907).

## Plan

1. Reproduce the reported behavior at the named source path and establish a red control.
2. Make the smallest fix in the existing subsystem. #905 may touch its declared installer, router, releases, and documentation surfaces; keep the same canonical writer.
3. Run the existing covering suite and a manual acceptance matrix in a disposable full clone. Commit provenance for cited evidence. Run final review and qualifying gate before the PR.

## Acceptance

- [ ] Derive a runnable remediation script path from the executing file in bare and vendored layouts.
- [ ] Existing legacy and releases-mode behavior outside this issue still works.
- [ ] No new suite, gate, runner, or telemetry stage (GH-831).

## Rating (2026-10-01)

PRS pri/sev/appeal/effort = 45/25/50/90; appeal neutral. Effort is cheapness. This issue is one observed adopter report; recurrence trend is unknown. The installer failure (#906) blocks core setup, while #905 crosses mode and view contracts. Reassess on new evidence.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash ci-local.sh",
  "fix_probes": [
    {
      "type": "grep_present",
      "path": "utils/py/router_audit.py",
      "pattern": "python3 utils/py/router_audit.py --fix",
      "note": "pre-fix symptom; verify against source before dispatch"
    }
  ],
  "artifacts": [
    "utils/py/router_audit.py"
  ],
  "remediation": {
    "source": "issue#907",
    "criteria": "Derive a runnable remediation script path from the executing file in bare and vendored layouts."
  },
  "lanes": {
    "agy_safe": [
      "utils/py/router_audit.py"
    ],
    "orchestrator_only": []
  }
}
```
