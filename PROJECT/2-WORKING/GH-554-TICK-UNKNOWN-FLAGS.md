---
gh_issue: 554
source: https://github.com/HiQS-Labs/XYZ-forge/issues/554
title: "tick mutating verbs silently accept unknown flags"
status: 2-WORKING
created: 2026-09-10
updated: 2026-09-10
owner: unassigned
doc_type: capture
complexity: 1
risk: 3
effort: 1
ratings_provisional: false
goal: "Reject unknown tick flags before any state mutation so a mistyped close cannot become a successful release."
---

## Status

| What was just completed | What's next |
|---|---|
| Reproduced during GH-534 QA: `tick release ... --status done` exited 0 and transferred ownership instead of closing the task. | Add verb-aware argument validation before dispatch, plus mutation-preservation tests. |

## Acceptance

- [ ] Every `tick` verb rejects an unknown flag with exit 2 and a usage diagnostic before reading or writing task state.
- [ ] `tick release ... --status done` and `--bogus-flag` leave ownership and event count unchanged.
- [ ] Documented valid flags, `--flag=value`, and environment fallbacks continue to work.
- [ ] Tests cover at least one read-only and every mutating verb, including the original release reproduction.

## Swarm Preflight Contract

```json
{
  "target": {"repo": ".", "ref": "development"},
  "gate": "node --check bin/tick && bash test/gh411-tick-log-foreign-cwd.sh",
  "fix_probes": [
    {"type": "path_absent", "path": "test/gh554-tick-unknown-flags.sh", "note": "new regression suite does not exist"}
  ],
  "artifacts": ["bin/tick", "test/gh554-tick-unknown-flags.sh"],
  "artifacts_new": ["test/gh554-tick-unknown-flags.sh"],
  "remediation": {"source": "issue#554", "criteria": "unknown flags exit 2 before mutation for every verb; valid syntax remains compatible; the original release reproduction is pinned"},
  "lanes": {"agy_safe": ["bin/tick", "test/gh554-tick-unknown-flags.sh"], "orchestrator_only": []}
}
```
