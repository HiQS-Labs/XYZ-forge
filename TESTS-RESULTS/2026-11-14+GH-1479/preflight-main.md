---
gh_issue: 1479
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1479
risk: 1
---

# GH-1479 smoke fixture

## Acceptance

- Existing swarm-preflight and parity suites pass, including unknown-argument and vendored paths.
- Main and adjacent smoke paths produce equivalent packets/results and exit codes; a recorded pre-change comparison is the red control.
- Scoped mypy passes and fails on a deliberate temporary type error in a manual red control.
- Later executor refactors stay in their linked issues; active PRs #1467 and #1471 and the #1475 lane are not touched.

## Swarm Preflight Contract

```json
{
  "target": {"repo": ".", "ref": "development"},
  "gate": "python3 -c \"print('gate-ok')\"",
  "fix_probes": [{"type": "command", "cmd": "test -e utils/py/swarm_preflight.py"}],
  "artifacts": ["utils/py/swarm_preflight.py"],
  "remediation": {"source": "GH-1479", "criteria": "Behavior-preserving decomposition and typed static analysis"},
  "round_cap": 1
}
```
