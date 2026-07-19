---
gh_issue: 232
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/232
title: "validate.sh: ~12 tests fail on ubuntu-latest CI runner (environment incompatibilities, first exposed by GH-230's CI step)"
status: "captured 2026-07-19 (auto-drafted by /10days)"
created: 2026-07-19
updated: 2026-07-19
owner: noel
doc_type: bug
complexity: 3
risk: 2
effort: 3
phases: 1
ratings_provisional: true
goal: >
  Fix the ~12 tests that fail on ubuntu-latest in the full ./validate.sh suite, then re-enable
  the full suite in .github/workflows/ci.yml instead of the current acorn-extract-only scope.
roadmap_exempt: false
---

# GH-232 · validate.sh Ubuntu CI failures

## Status
| What was just completed | What's next |
|---|---|
| Auto-captured 2026-07-19 by the /10days sweep; promoted to 2-WORKING with an auto-drafted Swarm Preflight Contract. Verified still open & reproducible: `.github/workflows/ci.yml:72` still carries the "Scoped to the acorn-extract test" comment and the workflow step still runs only `test/acorn-extract.sh`, not the full suite, on `development` today. **Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified.** | Operator review of the contract, then fire. |

## Problem
The full `./validate.sh` suite has ~12 test failures that are specific to the `ubuntu-latest` CI runner (environment incompatibilities, not real regressions), first exposed when GH-230 added a CI step that actually exercises the npm-dependent path. As a workaround, `.github/workflows/ci.yml` deliberately scopes CI down to only `test/acorn-extract.sh` — the full suite is not run on CI at all, so CI has a large uncovered surface.

## Fix direction
Identify and fix the ~12 Ubuntu-environment-specific failures in `./validate.sh` (likely path/tooling/locale differences vs. the macOS dev environment these tests were authored against), then remove the acorn-extract-only scoping in `.github/workflows/ci.yml` (~lines 72-79) and re-enable running the full `./validate.sh` suite on `ubuntu-latest`.

## Definition of done
- [ ] The ~12 previously-failing tests pass on `ubuntu-latest`.
- [ ] `.github/workflows/ci.yml` runs the full `./validate.sh` suite (not just `test/acorn-extract.sh`) on CI.
- [ ] `bash validate.sh` no worse than baseline.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_present", "path": ".github/workflows/ci.yml", "pattern": "Scoped to the acorn-extract test" }
  ],
  "artifacts": [ ".github/workflows/ci.yml" ],
  "remediation": {
    "source": "issue#232",
    "criteria": "The ~12 tests that previously failed only on ubuntu-latest now pass there, and .github/workflows/ci.yml runs the full ./validate.sh suite instead of being scoped to test/acorn-extract.sh. bash validate.sh green, no worse than pre-existing environmental reds."
  },
  "lanes": { "agy_safe": [ ".github/workflows/ci.yml" ], "orchestrator_only": [] }
}
```
