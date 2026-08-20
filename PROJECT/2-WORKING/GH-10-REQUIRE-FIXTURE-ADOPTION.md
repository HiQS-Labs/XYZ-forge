---
gh_issue: 10
source: https://github.com/HiQS-Suite/XYZ-forge/issues/10
title: "GH-10: prevent-half of containment — adopt require_fixture across the ~31 unaudited suites + adoption guard + ci-local identity bracket"
status: cut-from-ballast
created: 2026-08-16
updated: 2026-08-17
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
| **BUILT 2026-08-19 (standalone clone `XYZ-forge-gh10`, branch off `development`)** — the prevent-half landed for real, resolving the marathon's enforcement-without-adoption failure: `test/_setup.sh` adopts centrally for every sourcer (shared `$WORK` pinned, `$A`/`$B`/`$REMOTE` guarded); 35 suites mechanically (source + `fixture_guard_init` after the sandbox root, `require_fixture` after every per-suite `mktemp -d`); 7 by hand where fixtures lived outside their suite's root (nested under it — find-harness `FHWORK` restructure, gh308 `exc`, gh536 suite-level `WORK`, meter mutate `TMP`, swarm-preflight late `TMP`, relay-dep-drift + relay-turn-handoff new roots, aider-turn `require_fixture_file`); `test/gh1-adoption-guard.sh` (registered in TESTS) derives the offender list FROM SOURCE on every run and fails naming stragglers, with in-suite controls proving it fires on an unguarded new suite, a stripped adoption, and a removed exemption marker; `ci-local.sh` carries the GH-1 clone-identity bracket around its suite step; ledger `test/baselines/GH-1-adoption-ledger.md` records **Unaudited suites: 0** and the one declared exemption (`mktemp-trap-guard.sh`, static audit, marker in-file). Drive-by fix: `fixture-guard.sh`'s dynamic test-operator idiom was an `-S error` shellcheck failure on `ci-local` (pre-existing, found by this lane's `--fast` verification) — rewritten as explicit branches. | Full `./validate.sh` in this disposable clone, then PR into `development`. Not done here (out of scope): per-suite re-init shape in gh527/meter-release (function-scoped `fixture_guard_init`, functionally verified green, recorded in the ledger); `.github/workflows` alignment if CI ever wires the shellcheck step differently. |

## Marathon attempt evidence (2026-08-17, not merged)

Local branch `marathon/p1-2026-08-16` (unpushed, kept for reference). 5 rounds, escalated
(round-cap exceeded, `STATUS: Review Pending`). Both review rounds from codex converged on the
same defect the orchestrator found independently: the ledger/guard the builder produced
(`test/gh1-adoption-guard.sh`, `test/baselines/GH-1-adoption-ledger.md`) freezes 73 suites as a
permanent, guard-accepted exception list rather than adopting `require_fixture` in any of them —
enforcement without adoption. Round 3's self-issued waiver ("editing the ~73 suites... would
trigger containment failures") is the builder declining scope on its own authority rather than
escalating; that call belongs to the orchestrator/operator, not the builder.

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

- [x] Adoption ledger lists 0 unaudited suites.
- [x] `gh1-adoption-guard.sh` fails on both a removed guard and an unguarded new suite (negative controls in-suite; recorded under `test/baselines/GH-1-adoption-ledger.md`).
- [x] `ci-local.sh` carries the clone-identity bracket (capture before the suite step, assert as a summary step after; `--fast` verified green).
- [x] Full `./validate.sh` green in a disposable full clone, with the clone-identity invariant line passing — **228/228** (2026-08-19, clone `XYZ-forge-gh10`, 4-wide balanced).

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "type": "path_absent", "path": "test/gh1-adoption-guard.sh" },
    { "type": "grep_absent", "path": "ci-local.sh", "pattern": "clone-identity" },
    { "type": "path_absent", "path": "test/baselines/GH-1-adoption-ledger.md" }
  ],
  "artifacts":   [ "ci-local.sh", "validate.sh", "test/gh1-adoption-guard.sh", "test/baselines/GH-1-adoption-ledger.md" ],
  "artifacts_new": ["test/gh1-adoption-guard.sh", "test/baselines/GH-1-adoption-ledger.md"],
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
