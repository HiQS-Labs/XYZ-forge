<!--
CONTRACT.example.md — a complete, realistic capture doc with a machine-readable preflight contract.
Copy this file into PROJECT/2-WORKING/GH-<issue>-<slug>.md in the target repository, then replace
the fictional GH-900 details below with the real issue's facts.

Per-field annotations:
  target       The repo and ref the marathon should branch from.
               repo: "." (this repo) or a relative path to a foreign target.
               ref: The committish to branch from (for example, "main" or a specific branch).
  gate         A runnable bash command that verifies the fix (for example, "bash validate.sh").
               Preflight ensures this command exists, but it DOES NOT execute it during preflight.
  artifacts    A JSON array of files the builder may create or edit.
               The builder is strictly limited to these paths (plus inferred covering tests).
  remediation  Optional work scope: source identifies its origin; criteria states a concrete,
               checkable outcome the finished work must satisfy.
  lanes        Optional artifact assignments for agent capabilities. Keep sensitive/shared paths
               under orchestrator_only; leave agy_safe empty when no special routing is needed.

  fix_probes   (CRITICAL FIELD) A list of probes that determine whether the fix is still required.
               POLARITY: Probes detect the **bug**, NOT the fix.
               - path_absent: The required file is missing (it should exist after the fix).
               - path_present: The unwanted file is present (it should be removed by the fix).
               - grep_present: The bug evidence (string/regex) is still in the file.
               - grep_absent: The fix marker has not yet landed in the file.
               - command: A command whose exit code indicates the bug is still present.

               WARNING: Inverting the polarity (for example, probing for the fix rather than the
               bug) causes preflight to return **STALE (exit 4)**, which reads as "already done" —
               a false completion signal that prevents the build from running.
-->
---
gh_issue: 900
source: https://github.com/example-org/example-repo/issues/900
title: "widget: add an accessible empty-state component"
status: "captured 2026-07-18"
created: 2026-07-18
updated: 2026-07-18
owner: example-owner
doc_type: bug
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Redesigning populated widget states
goal: >
  Add the missing accessible empty-state component so a widget with no results gives the user a
  clear, screen-reader-visible explanation.
roadmap_exempt: false
---

# GH-900 · add an accessible widget empty state

## Status

| What was just completed | What's next |
|---|---|
| Captured a missing empty-state component with a preflight contract. | Implement the component and its regression test. |

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "path_absent", "path": "src/widget-empty-state.js" },
    { "type": "grep_absent", "path": "src/widget.js", "pattern": "widget-empty-state" }
  ],
  "artifacts": [
    "src/widget-empty-state.js",
    "src/widget.js",
    "test/widget-empty-state.sh"
  ],
  "remediation": {
    "source": "issue#900",
    "criteria": "src/widget-empty-state.js renders an empty-state message with an accessible name; src/widget.js uses it when there are no results; test/widget-empty-state.sh covers that path."
  },
  "lanes": {
    "agy_safe": [
      "src/widget-empty-state.js",
      "src/widget.js",
      "test/widget-empty-state.sh"
    ],
    "orchestrator_only": []
  }
}
```

## Phase 1

- [ ] Add `src/widget-empty-state.js` with an accessible empty-state message.
- [ ] Render that component from `src/widget.js` when there are no results.
- [ ] Add `test/widget-empty-state.sh` coverage for the empty-result path.
