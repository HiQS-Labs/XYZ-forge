---
title: "GH-251: validate.sh reports python:test_python_layer.py as FAILED when pytest is merely absent"
status: Active
created: 2026-08-25
updated: 2026-08-26
owner: orchestrator (Claude Code)
goal: an absent pytest reads as a named SKIP, never as a failure, so a green run claim can be read honestly
gh_issue: 251
source: https://github.com/HiQS-Labs/XYZ-forge/issues/251
branch: gh-251/validate-pytest-skip
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
release: 0.7.4 Linux-RC (dialed in 2026-08-26)
non_goals:
  - Changing test/test_python_layer.py itself
  - Vendoring pytest into the repo
---

# GH-251 · validate.sh miscounts an absent pytest as a failure

## Status

| What was just completed | What's next |
|---|---|
| capture doc authored with a preflight contract; dialed into 0.7.4 | Operator fires the lane; builder adds the import probe, reviewer verifies a real pytest failure still lands in FAILED |


## Why

`validate.sh:1048-1053` treats the exit code of `python3 -m pytest …` as a pass/fail verdict, so
"pytest is not installed" and "an assertion failed" are indistinguishable. On a host without
pytest the suite lands in `FAILED`, while the same file is **20 passed** in a venv.

That suite covers `utils/py/` — where `releases_app.py` lives. An agent that edits it, runs
`validate.sh`, sees the familiar red and shrugs has skipped the coverage for the file it just
changed. It is the same defect `.github/workflows/ci.yml:215-217` already warns about in the
canary: unread red trains everyone to ignore the channel.

Blocks 0.7.4's exit criterion, which is a *qualifying 100% green* hosted run.

## Key Concepts

- Probe `python3 -c "import pytest"` first; classify absence as a NAMED SKIP, not a failure.
- Precedent: `test/gh342-sentinel-debug-log-python.sh:249` — "say so rather than reporting a pass
  this run did not earn." The inverse holds: do not report a failure this run did not earn.
- A real pytest failure must still land in `FAILED`.

## Non-goals

- Changing `test/test_python_layer.py` itself.
- Vendoring pytest.

## Related

- `validate.sh:574,1048-1053` · `test/test_python_layer.py` · GH-249 · 0.7.4 Linux-RC

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "grep_absent", "path": "validate.sh", "pattern": "import pytest" } ],
  "artifacts":     [ "validate.sh" ],
  "artifacts_new": [],
  "remediation":   { "source": "self#plan", "criteria": "absent pytest yields a named SKIPPED line, not a FAILED entry; a genuine pytest failure still lands in FAILED" },
  "lanes":         { "agy_safe": [ "validate.sh" ], "orchestrator_only": [ "relay-automation/", ".tick/" ] }
}
```
