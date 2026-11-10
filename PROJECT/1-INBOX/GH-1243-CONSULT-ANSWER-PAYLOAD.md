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

- [ ] Re-running a small Codex + agy consult gives neutral payloads of comparable shape and size: answer text only, with no exec logs, prompt echo or token footer.
- [ ] A Codex answer that cites file:line next to its `[Pass]` lines is not stamped. An answer with an uncited `[Pass]` still is.
- [ ] Verified per GH-831 with existing suites (`test/consult.sh`) plus a manual TESTS-RESULTS receipt. No new suites.
- [ ] Preserve baseline failure and final passing evidence in the declared manual/provenance artifacts; use existing checks only.
- [ ] Do not install or publish anything, change versions or release tags, add dependencies, create new test suites, or modify unrelated paths.

## Acceptance — deviations from the issue

- [added] Preserve baseline failure and final passing evidence in the declared manual/provenance artifacts; use existing checks only. — reason: operator-authorized bounded trial constraints.
- [added] Do not install or publish anything, change versions or release tags, add dependencies, create new test suites, or modify unrelated paths. — reason: operator-authorized bounded trial constraints.

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
      "type": "command",
      "cmd": "python3 -c 'import sys;sys.path.insert(0,'\"'\"'utils/py'\"'\"');from consult import _neutralize_answer_text;raw='\"'\"'Prompt echo\\nTRANSCRIPT_SENTINEL\\nexec log\\ntokens used\\n123\\n[Pass] utils/py/consult.py:89 final answer.'\"'\"';out=_neutralize_answer_text(raw,'\"'\"'advisor.md'\"'\"','\"'\"'A'\"'\"','\"'\"'codex'\"'\"');assert '\"'\"'TRANSCRIPT_SENTINEL'\"'\"' not in out and '\"'\"'exec log'\"'\"' not in out and '\"'\"'[Pass] utils/py/consult.py:89 final answer.'\"'\"' in out'",
      "expect_nonzero": true
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
  },
  "round_cap": 2
}
```
