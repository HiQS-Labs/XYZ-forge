---
title: "GH-168: wave_reconcile.py hard-fails and rolls back on pre-existing marathon-plan drift unrelated to the PR being reconciled"
status: Complete
created: 2026-08-22
updated: 2026-08-24
owner: orchestrator (Claude Code)
goal: scope wave_reconcile's drift check to the PR being reconciled so unrelated backlog drift downgrades to a warning instead of rolling back correct mutations
gh_issue: 168
source: https://github.com/HiQS-Suite/XYZ-forge/issues/168
branch: gh-168/wave-reconcile-scope
doc_type: bugfix
effort: 1
complexity: 2
risk: 1
related:
  - "#163 — the ROADMAP double-listing this reconciler family produces (fix #164 was detection; this issue is the writer/scope half)"
---

# GH-168 — wave_reconcile drift-check scope

## Status

| What was just completed | What's next |
|---|---|
| capture doc + preflight contract written (ready, exit 0); queued as Bulkhead wave 2 (2026-08-22, release 0.7.3 "Bulkhead", #179) | Operator fires the marathon lane per MARATHON-PLAN-2026-08-23.md; builder executes ## Plan, reviewer verifies ## Acceptance |


Release 0.7.3 "Bulkhead" manifest member. Radar 2026-08-22:
RADAR-class-roadmap-ledger-drift — the class recurred same-day (f8ea40a1 "(recurrence)")
because fixes so far are detection plus hand-deletion; this is the writer-side fix.

## Bug

`utils/py/wave_reconcile.py` (GH-165, PR #166) chains a trailing `marathon-plan.sh --dry-run`
after its PR-specific reconciliation. ANY backlog drift found there (closed issues still
listed active, missing preflight contracts elsewhere) exits 4, which wave_reconcile treats as
a hard reconciler failure and rolls back ALL mutations via RollbackJournal — even when the
PR-specific work was correct. Reproduced 2/2 on real merges (`--pr 162`, `--pr 160`).

## Plan

1. `utils/py/wave_reconcile.py`: split the trailing check — drift attributable to the
   reconciled PR's items stays fatal; pre-existing unrelated drift downgrades to a warning
   block naming each held item, with no rollback.
2. Idempotence: the promotion writer moves a ROADMAP bullet between lifecycle sections, never
   adds — running reconcile twice on the same PR is a no-op (retires the #163 duplicate shape
   at the writer).
3. `test/gh168-wave-reconcile-scope.sh`: fixture ledger with pre-existing unrelated drift —
   reconcile of an unrelated PR succeeds with a warning; drift on the reconciled PR's own item
   still fails and rolls back; double-run is a no-op. Register in validate.sh TESTS.

## Acceptance

- [ ] Both real repro shapes (`--pr 162`, `--pr 160`) succeed with a warning on pre-existing unrelated drift instead of rolling back.
- [ ] Drift attributable to the reconciled PR's own items still fails and rolls back, unchanged.
- [ ] Running reconcile twice on the same PR is a no-op (idempotence).
- [ ] `test/gh168-wave-reconcile-scope.sh` green and registered in validate.sh.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/gh168-wave-reconcile-scope.sh" } ],
  "artifacts":     [ "utils/py/wave_reconcile.py", "test/gh168-wave-reconcile-scope.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh168-wave-reconcile-scope.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "unrelated pre-existing drift warns without rollback; PR-attributable drift still fatal; reconcile is idempotent; gh168 suite green" },
  "lanes":         { "agy_safe": [ "test/gh168-wave-reconcile-scope.sh", "utils/py/wave_reconcile.py" ], "orchestrator_only": [ ".tick/" ] }
}
```

## Lessons Learned (For Future Agents)

- Scope a reconciler's failure to the thing it reconciles: PR-attributable drift stays fatal
  (rollback), pre-existing unrelated drift downgrades to a named warning. Blanket tolerance and
  blanket fatality are both wrong — the first hides real breakage, the second blocks every merge.
- The attribution split fired correctly on its own closeout: reconciling PR #220 before issues
  #2/#50/#168 were closed was refused as PR-attributable drift — the new fatal path, doing its job.
- Idempotence lives in the promotion WRITER (move-not-add between lifecycle sections), which is
  what makes double-running reconcile a no-op instead of a duplicate-entry generator (#163 shape).
