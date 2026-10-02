---
gh_issue: 904
source: https://github.com/HiQS-Labs/XYZ-forge/issues/904
title: "PDDA empty releases ledger"
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
  Recognize a queryable empty roadmap_items table; still report unreadable DBs and uncovered working docs.
---

# PDDA empty releases ledger

## Status

| What was just completed | What's next |
|---|---|
| Issue #908 ordered this serial Jog; preflight passed on base 57bd97af and implementation is drafted on fix/gh908-pdda-adopter-jog. | Agy and final Codex relay QA approved; full macOS ci-local passed at final post-reconciliation tip 3882935e with clone identity intact. PR #913 is open and its blocking hosted smoke gate passed at 9a32b247. Await operator merge approval. |

## Observed problem

pdda.sh mistakes zero roadmap rows for an absent ledger. Source: [issue #904](https://github.com/HiQS-Labs/XYZ-forge/issues/904).

## Plan

1. Reproduce the reported behavior at the named source path and establish a red control.
2. Make the smallest fix in the existing subsystem. #905 may touch its declared installer, router, releases, and documentation surfaces; keep the same canonical writer.
3. Run the existing covering suite and a manual acceptance matrix in a disposable full clone. Commit provenance for cited evidence. Run final review and qualifying gate before the PR.

## Acceptance

- [ ] Recognize a queryable empty roadmap_items table; still report unreadable DBs and uncovered working docs.
- [ ] Existing legacy and releases-mode behavior outside this issue still works.
- [ ] No new suite, gate, runner, or telemetry stage (GH-831).

## Rating (2026-10-01)

PRS pri/sev/appeal/effort = 75/55/50/80; appeal neutral. Effort is cheapness. This issue is one observed adopter report; recurrence trend is unknown. The installer failure (#906) blocks core setup, while #905 crosses mode and view contracts. Reassess on new evidence.

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
      "path": "utils/pdda/pdda.sh",
      "pattern": "no releases.db ledger present",
      "note": "pre-fix symptom; verify against source before dispatch"
    }
  ],
  "artifacts": [
    "utils/pdda/pdda.sh"
  ],
  "remediation": {
    "source": "issue#904",
    "criteria": "Recognize a queryable empty roadmap_items table; still report unreadable DBs and uncovered working docs."
  },
  "lanes": {
    "agy_safe": [
      "utils/pdda/pdda.sh"
    ],
    "orchestrator_only": []
  }
}
```
