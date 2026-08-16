---
gh_issue: 10
source: https://github.com/HiQS-Suite/XYZ-forge/issues/10
title: "GH-10: prevent-half of containment — adopt require_fixture across the ~31 unaudited suites + adoption guard + ci-local identity bracket"
status: active
created: 2026-08-16
updated: 2026-08-16
owner: orchestrator (Claude Code)
doc_type: bugfix
complexity: 3
risk: 3
effort: 5
ratings_provisional: true
goal: >
  Every test suite that creates git fixtures under a mktemp sandbox guards every derived fixture
  path at the use boundary (require_fixture / require_fixture_file), an adoption guard makes
  regression loud, and the qualifying ci-local.sh run carries the same clone-identity bracket
  validate.sh has.
---

# GH-10 — require_fixture adoption (the prevent-half)

## Status

| What was just completed | What's next |
|---|---|
| Capture promoted to 2-WORKING; contract authored; Ballast 0.7.0 manifest frozen (this lane is the manifest's designated cut if scope slips) | Preflight, then fire as a marathon lane on operator go |

## Bug

The containment work has two halves. The detect-half landed with PR #6 (#1): a shared hardened
`require_fixture` (`test/lib/fixture-guard.sh`) and a clone-identity bracket in `validate.sh`.
The prevent-half is still open: ~31 `test/*.sh` suites create git fixtures via `mktemp -d` under
a `$WORK` sandbox and hand those paths to `git -C "$r"` / `cd "$r"` with no guard at all, so the
GH-564 failure mode (empty mktemp return → `git -C ""` silently targets the caller's clone)
remains live in each of them.

## Source of truth

- GitHub issue: [HiQS-Suite/XYZ-forge#10](https://github.com/HiQS-Suite/XYZ-forge/issues/10)

## Acceptance

- [ ] Adoption ledger lists 0 unaudited suites.
- [ ] `gh1-adoption-guard.sh` fails on both a removed guard and an unguarded new suite (negative control recorded under `test/baselines/`).
- [ ] `ci-local.sh` carries the clone-identity bracket.
- [ ] Full `./validate.sh` green in a disposable full clone, with the clone-identity invariant line passing.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "type": "path_absent", "path": "test/gh1-adoption-guard.sh" },
    { "type": "grep_absent", "path": "ci-local.sh", "pattern": "clone-identity" }
  ],
  "artifacts":   [ "ci-local.sh", "validate.sh", "test/gh1-adoption-guard.sh", "test/baselines/GH-1-adoption-ledger.md" ],
  "remediation": { "source": "issue#10", "criteria": "adoption ledger at zero; guard fails on removed guard and unguarded new suite; ci-local bracketed" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```

Probe polarity: both probes carry FIX markers — the `gh1-adoption-guard.sh` suite the issue's
step 4 mandates, and the `clone-identity` bracket in `ci-local.sh` the issue's step 5 mandates.
The lane is ready while both are absent and reports stale (exit 4) once either lands. NOTE for
the wave planner: `validate.sh` (guard registration) overlaps lane #15 — serialize #10 and #15
into different waves. Mechanical adoption across ~31 suites proceeds in review-sized batches
(~5-8 per PR) per the issue's own plan; the marathon lane drives the batches, and partial
progress must never be reported as the acceptance being met.

## Verification

- Removing a `require_fixture` from an adopted suite turns `gh1-adoption-guard.sh` red; adding a
  new mktemp-using suite without the guard turns it red (both recorded in the negative control).
- `bash test/gh308-frozen-twin-guard.sh --check --staged` clean.
- Full `./validate.sh` green in a disposable full clone at a durable location.
