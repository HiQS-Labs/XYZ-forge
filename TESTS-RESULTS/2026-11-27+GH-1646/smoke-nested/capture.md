---
gh_issue: 99001
title: smoke
---

# smoke

## Acceptance

- [ ] The first criterion.
      - a nested plain detail of the first.
- [ ] A plain sibling criterion.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh --auto development",
  "fix_probes": [ { "type": "path_absent", "path": "gh99001-smoke-never-exists.txt" } ],
  "artifacts": [ "gh99001-smoke-never-exists.txt" ]
}
```
