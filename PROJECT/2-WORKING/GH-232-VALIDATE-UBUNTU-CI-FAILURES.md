---
gh_issue: 232
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/232
title: "validate.sh: ~12 tests fail on ubuntu-latest CI runner (environment incompatibilities, first exposed by GH-230's CI step)"
status: "fixed 2026-07-21 — re-diagnosed directly against a real ubuntu container, not guessed at"
created: 2026-07-19
updated: 2026-07-21
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
| Fixed 2026-07-21 by re-diagnosing directly against a real `ubuntu:latest` Docker container (not guessed at from macOS behavior). Two real, previously-mischaracterized bugs found: (1) a BSD-only `sed -i ''` in marathon.sh/marathon-drive.sh mis-parsing under GNU sed; (2) driver-lock.sh/xyz-harness-hooks.sh stubbed CLAUDE_BIN/AGY_BIN but not CODEX_BIN (the actual default builder), passing locally only because a real `codex` binary happened to be on the developer's PATH. Once fixed, path-integrity.sh/archive-writers.sh/relay-file-seeding-visibility.sh/xyz-vendor.sh/hq.sh/relay-pkg-freshness.sh all turned out to have no ubuntu-specific bug at all — they were skipped based on an assumption that was never re-verified after the git-identity fix (767035e) landed. Only `registry-lock-concurrency.sh` (a documented real flake, GH-72) stays skipped. `.github/workflows/ci.yml` now runs the full suite minus that one flake. Real CI verification in progress on PR #271. `bash validate.sh` green locally (117/117). | Confirm PR #271's real ubuntu-latest CI run is green, then merge. |

## Problem
The full `./validate.sh` suite has ~12 test failures that are specific to the `ubuntu-latest` CI runner (environment incompatibilities, not real regressions), first exposed when GH-230 added a CI step that actually exercises the npm-dependent path. As a workaround, `.github/workflows/ci.yml` deliberately scopes CI down to only `test/acorn-extract.sh` — the full suite is not run on CI at all, so CI has a large uncovered surface.

## Fix direction
Identify and fix the ~12 Ubuntu-environment-specific failures in `./validate.sh` (likely path/tooling/locale differences vs. the macOS dev environment these tests were authored against), then remove the acorn-extract-only scoping in `.github/workflows/ci.yml` (~lines 72-79) and re-enable running the full `./validate.sh` suite on `ubuntu-latest`.

## Definition of done
- [x] The ~12 previously-failing tests pass on `ubuntu-latest` — confirmed directly against a real `ubuntu:latest` container; pending final confirmation on PR #271's real CI run.
- [x] `.github/workflows/ci.yml` runs the full `./validate.sh` suite (not just `test/acorn-extract.sh`) on CI — only `registry-lock-concurrency.sh` (documented flake) and `acorn-extract.sh` (run separately, earlier) stay skipped.
- [x] `bash validate.sh` no worse than baseline — 117/117 local.

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
