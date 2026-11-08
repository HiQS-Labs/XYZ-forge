---
gh_issue: 1160
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1160
title: "Correct startup reconciliation instructions"
status: Active
created: 2026-11-08
updated: 2026-11-08
owner: noelsaw1
doc_type: capture
complexity: 1
risk: 1
effort: 1
phases: 1
goal: Startup instructions match the existing local reconciliation and dispatch-only promotion workflow.
---
## Status

| What was just completed | What's next |
|---|---|
| Promoted to active working contract via jog | Execute implementation and verify probes |

# GH1160 — correct startup reconciliation instructions

## Scope

The live issue is OPEN with no comments/defer decisions. AGENTS.md still says the
hosted wave-reconcile automatically reconciles development merges and local
reconciliation is an emergency fallback. .github/workflows/wave-reconcile.yml is
workflow_dispatch only; existing later AGENTS and ROUTER paragraphs name local
reconciliation as default. Fix only that contradictory startup paragraph, retaining
receipt/approval controls and the statement that task branches do not commit views.
Do not change runtime or add tests. This is needed documentation work discovered
from the live open issue backlog, not a fabricated workload.

## Acceptance

Copied from the live issue.

- [ ] No startup or router text describes automatic hosted reconciliation after a development merge.
- [ ] `pdda.sh run` is clean.

## Preflight Contract

```json
{
  "target": {"repo": ".", "ref": "development"},
  "gate": "bash utils/pdda/pdda.sh run",
  "fix_probes": [
    {"type": "grep_present", "path": "AGENTS.md", "pattern": "automatically reconciles docs, ledger, and views"},
    {"type": "grep_present", "path": "AGENTS.md", "pattern": "serves as an emergency fallback"}
  ],
  "artifacts": ["AGENTS.md"],
  "remediation": {"source": "issue#1160", "criteria": "Local wave_reconcile.py --pr is default after development merge; hosted wave-reconcile is dispatched before promotion. Preserve existing controls; docs only."}
}
```

## Rehearsal limits

One queued execution in this window; no automatic retry or merge. Codex builder,
Agy reviewer. Worker wall/idle900 seconds. Existing relay base5 may extend to10 only
on qualifying progress; Marathon lane cap2 unchanged. This task is independent of
GH1295; commits must start from the runner's prepared development, not its lane.
