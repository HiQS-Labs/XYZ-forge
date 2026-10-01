---
gh_issue: 906
source: https://github.com/HiQS-Labs/XYZ-forge/issues/906
title: "Optional PDDA skill install"
status: active
created: 2026-10-01
updated: 2026-10-01
owner: XYZ Forge maintainers
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
related:
  - "#908 — serial PDDA adopter Jog"
goal: >
  Treat the skill copy as optional, warn, and finish core installation with truthful verification.
---

# Optional PDDA skill install

## Status

| What was just completed | What's next |
|---|---|
| Issue #908 ordered this serial Jog; preflight passed on base 57bd97af and implementation is drafted on fix/gh908-pdda-adopter-jog. | Independent Agy QA approved at 6ce4b327; finish the qualifying gate, open a PR, then await operator merge approval. |

## Observed problem

An unwritable .claude/skills path aborts before core installation finishes. Source: [issue #906](https://github.com/HiQS-Labs/XYZ-forge/issues/906).

## Plan

1. Reproduce the reported behavior at the named source path and establish a red control.
2. Make the smallest fix in the existing subsystem. #905 may touch its declared installer, router, releases, and documentation surfaces; keep the same canonical writer.
3. Run the existing covering suite and a manual acceptance matrix in a disposable full clone. Commit provenance for cited evidence. Run final review and qualifying gate before the PR.

## Acceptance

- [ ] Treat the skill copy as optional, warn, and finish core installation with truthful verification.
- [ ] Existing legacy and releases-mode behavior outside this issue still works.
- [ ] No new suite, gate, runner, or telemetry stage (GH-831).

## Rating (2026-10-01)

PRS pri/sev/appeal/effort = 80/75/50/75; appeal neutral. Effort is cheapness. This issue is one observed adopter report; recurrence trend is unknown. The installer failure (#906) blocks core setup, while #905 crosses mode and view contracts. Reassess on new evidence.

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
      "path": "utils/pdda/pdda-install.sh",
      "pattern": "\\n  mkdir -p \"\\$TARGET/\\.claude/skills/pdda\"",
      "note": "pre-fix symptom; verify against source before dispatch"
    }
  ],
  "artifacts": [
    "utils/pdda/pdda-install.sh"
  ],
  "remediation": {
    "source": "issue#906",
    "criteria": "Treat the skill copy as optional, warn, and finish core installation with truthful verification."
  },
  "lanes": {
    "agy_safe": [
      "utils/pdda/pdda-install.sh"
    ],
    "orchestrator_only": []
  }
}
```
