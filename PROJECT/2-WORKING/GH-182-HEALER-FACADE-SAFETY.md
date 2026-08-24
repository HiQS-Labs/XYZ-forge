---
title: "GH-182: self_healer --mode heal is a facade — containment refuses any real target, the CLI can never heal"
status: active
created: 2026-08-23
updated: 2026-08-23
owner: orchestrator (Claude Code)
goal: heal mode either refuses with named requirements or runs safely in a disposable clone — no reachable in-place patch path, ever
gh_issue: 182
source: https://github.com/HiQS-Labs/XYZ-forge/issues/182
branch: gh-182/healer-facade-safety
doc_type: bugfix
effort: 3
complexity: 3
risk: 4
related:
  - "#174 — Gen 3.5 umbrella (Part C C2-C7, Part G probe C3); #177 — soak results §3.3"
  - "#113 — same disposable-scratch/containment family within Bulkhead"
---

# GH-182 — self_healer CLI safety (fail-fast + gates)

## Status

| What was just completed | What's next |
|---|---|
| capture doc + preflight contract written; auto-filed per SOP §1 (2026-08-23); queued as Bulkhead wave candidate (release 0.7.3, #179) | Operator fires the marathon lane per MARATHON-PLAN; builder executes ## Plan, reviewer verifies ## Acceptance |

Release 0.7.3 "Bulkhead" manifest member. Gen 3.5 soak (#177 §3.3, probe C3): heal mode never
passes a sandbox root, so the cycle's empty mkdtemp refuses every real `--target-file`
(`apply_failed` ×N → `escalated`); the success path is unreachable by construction and the
default generator is a placeholder returning the file's current content.

## Bug

See #182 for the deterministic reproduction (3× `apply_failed: Refusing write … outside sandbox
root /var/folders/…/self_heal_XXXX`). Compounding: 30s hardcoded gate timeout cannot hold a real
regression gate; revert-on-gate-failure only (crash mid-attempt leaves the target patched);
`regression_cmd` optional; `winning_diff` has no consumer.

## Plan

1. `utils/py/self_healer.py`: heal mode requires `--sandbox-root` that (a) exists, (b) contains
   `--target-file` after realpath resolution, and (c) is NOT the invoking checkout — refuse at
   arg-parse with named requirements otherwise; delete the placeholder generator.
2. Gates: make `--regression-cmd` mandatory for heal mode; `--gate-timeout` flag (default 900s);
   restore target on ANY exit (try/finally), not only gate-failure branches.
3. Escalation emits an issue-rollup artifact (markdown body for `compile_issue.py`) instead of
   only a printed dict; `winning_diff` written to a file when healed.
4. `test/gh182-healer-facade-safety.sh`: (a) missing --sandbox-root refuses with the named
   requirement; (b) sandbox == invoking checkout refuses; (c) fixture sandbox heals the fixture
   defect with mandatory gate; (d) crash-mid-attempt restores the target (kill -9 simulation).
   Register in `validate.sh` TESTS.

## Acceptance

No reachable code path applies patches in place to the invoking checkout; heal mode refuses
loudly with named requirements or heals inside the provided disposable root; gh182 suite green.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/gh182-healer-facade-safety.sh" } ],
  "artifacts":     [ "utils/py/self_healer.py", "test/gh182-healer-facade-safety.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh182-healer-facade-safety.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "heal mode fails fast outside a disposable sandbox; mandatory regression gate; restore-on-any-exit; gh182 suite green" },
  "lanes":         { "agy_safe": [ "utils/py/self_healer.py", "test/gh182-healer-facade-safety.sh" ], "orchestrator_only": [ "validate.sh" ] }
}
```
