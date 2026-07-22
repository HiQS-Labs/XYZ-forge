---
gh_issue: 232
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/232
title: "validate.sh: ~12 tests fail on ubuntu-latest CI runner (environment incompatibilities, first exposed by GH-230's CI step)"
status: "✅ SHIPPED — closed 2026-07-22 (PR #271, merge 2a2da17)"
created: 2026-07-19
updated: 2026-07-21
owner: noel
doc_type: bug
complexity: 3
risk: 2
effort: 3
phases: 1
ratings_provisional: false
goal: >
  Fix the ~12 tests that fail on ubuntu-latest in the full ./validate.sh suite, then re-enable
  the full suite in .github/workflows/ci.yml instead of the current acorn-extract-only scope.
roadmap_exempt: false
---

# GH-232 · validate.sh Ubuntu CI failures

## Status
| What was just completed | What's next |
|---|---|
| **Fixed and confirmed green on real CI 2026-07-21** (PR #271, run 29865944751). Re-diagnosed entirely against a real `ubuntu:latest` Docker container instead of guessing from macOS. Real bugs found and fixed: (1) BSD-only `sed -i ''` in marathon.sh/marathon-drive.sh mis-parsing under GNU sed; (2) 7 direct `bash "$DRIVER"`/`bash "$MD"` invocations across driver-lock.sh/xyz-harness-hooks.sh/marathon-drive.sh/debug-mantra.sh stubbed CLAUDE_BIN/AGY_BIN but never CODEX_BIN (the actual default builder), passing locally only because a real `codex` binary happened to be on the developer's PATH; (3) `hq_sanitize`'s `tr -cd '[:alnum:]/_.- '` silently corrupted to an empty-string filter under GNU tr (invalid range warning), breaking every rebalance-registry lookup; (4) `xyz-vendor.sh`'s staleness fixture used `git rev-list --max-parents=0 HEAD` to synthesize an "older" commit, which resolves to HEAD itself under GitHub's default shallow clone — fixed via `fetch-depth: 0`. path-integrity.sh/archive-writers.sh/relay-file-seeding-visibility.sh/xyz-vendor.sh all had no bug at all — skipped on a stale assumption never re-verified after 767035e landed. Only `registry-lock-concurrency.sh` (documented GH-72 flake) stays skipped. `bash validate.sh` 117/117 local. | Merge (part of the /10days marathon branch). |

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
