---
gh_issue: 1243
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1243
title: "Consult answer payload and citation accuracy"
status: proposed
created: 2026-11-10
updated: 2026-11-10
owner: B trial
goal: "Extract final answer for neutral payload and citation screening; preserve full transcript separately and missing-final-answer safety. Verify cited and uncited answers plus transcript exclusion using existing consult suite/manual evidence; no new suite."
---

# GH-1243 — Consult answer payload

## Acceptance

Extract final answer for neutral payload and citation screening; preserve full transcript separately and missing-final-answer safety. Verify cited and uncited answers plus transcript exclusion using existing consult suite/manual evidence; no new suite.

Baseline: controlled transcript marker survives current neutralizer. Original issue describes prompt echo causing false uncited warnings.

## Trial execution scope

Extract final answer for neutral payload and citation screening; preserve full transcript separately and missing-final-answer safety. Verify cited and uncited answers plus transcript exclusion using existing consult suite/manual evidence; no new suite. Preserve unrelated files. Two builder attempts maximum. Capture baseline/final controls, no new test suite.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh --auto development",
  "fix_probes": [
    {
      "type": "grep_present",
      "path": "utils/py/consult.py",
      "pattern": "body = raw_text"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-11-10+GH-1243/manual.md"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl"
    }
  ],
  "artifacts": [
    "utils/py/consult.py",
    "TESTS-RESULTS/2026-11-10+GH-1243/manual.md",
    "TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-11-10+GH-1243/manual.md",
    "TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl"
  ],
  "remediation": {
    "source": "issue#1243",
    "criteria": "Extract final answer for neutral payload and citation screening; preserve full transcript separately and missing-final-answer safety. Verify cited and uncited answers plus transcript exclusion using existing consult suite/manual evidence; no new suite."
  },
  "lanes": {
    "agy_safe": [
      "utils/py/consult.py",
      "TESTS-RESULTS/2026-11-10+GH-1243/manual.md",
      "TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl"
    ],
    "orchestrator_only": []
  }
}
```
