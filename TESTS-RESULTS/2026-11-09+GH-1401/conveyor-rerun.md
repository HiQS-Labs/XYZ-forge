---
gh_issue: 1401
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1401
title: Conveyor smoke input
status: captured
created: 2026-11-09
updated: 2026-11-09
owner: codex
goal: Verify real consumer contract behavior without publication.
---

## Acceptance

- [ ] Add the missing conveyor skill.

## Swarm Preflight Contract

```json
{"target": {"repo": ".", "ref": "31424e4ff421037c413c0ef3fef2ad55ba4afaa8"}, "gate": "bash utils/pdda/pdda.sh run", "fix_probes": [{"type": "path_absent", "path": "skills/1-hourly/conveyor/SKILL.md"}], "artifacts": ["skills/1-hourly/conveyor/SKILL.md"], "artifacts_new": ["skills/1-hourly/conveyor/SKILL.md"]}
```
