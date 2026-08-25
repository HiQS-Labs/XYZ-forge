---
title: "GH-205: validate.sh mutates four tracked files on every run — clean checkouts cannot stay clean"
status: Active
created: 2026-08-24
updated: 2026-08-24
owner: orchestrator (Claude Code)
goal: a full gate run on a pristine checkout leaves `git status --porcelain` completely clean — verification never dirties the tree it verifies
gh_issue: 205
source: https://github.com/HiQS-Labs/XYZ-forge/issues/205
branch: gh-205/gate-idempotency
doc_type: bugfix
effort: 2
complexity: 2
risk: 1
release: 0.7.4 Linux-RC (dialed in 2026-08-24, mfi-01M0V6HCHW8ZE0Y2VG6ARM35XR)
related:
  - "#224 — Linux MVP RC umbrella (Phase 2 exit item)"
  - "#174 — the harness-registry suite that writes into the live root ledger"
non_goals:
  - Changing what the registry records on REAL (non-test) gate runs — the eval telemetry itself stays
  - Gate policy, suite count, or duration
---

# GH-205 — gate idempotency: suite writes land in tracked root files

## Status

| What was just completed | What's next |
|---|---|
| capture doc + preflight contract written; dialed into 0.7.4 Linux-RC | Operator fires the marathon lane; builder executes ## Plan, reviewer verifies ## Acceptance |

Root cause pinpointed in Agy's empirical review on #224 (2026-08-24):
`test/gh174-harness-registry.sh` writes directly into `$ROOT/harnesses.db` and
`$ROOT/docs/blog-frontier-benchmarks.md` (see its `BLOG_FILE="$ROOT/docs/..."` at line 126)
rather than an isolated fixture under `$WORK`. Every full gate accumulates benchmark rows in
tracked files — the "eval treadmill" this repo sweeps with chore commits.

## Plan

1. `test/gh174-harness-registry.sh`: point every write (`harnesses.db`, `harnesses.sql`,
   `docs/blog-frontier-benchmarks.md`, generated registry views) at a fixture copy under the
   suite's `$WORK` dir; the suite must never name `$ROOT` as a write destination.
2. If `utils/py/harness_app.py` lacks a root/db override needed for fixture isolation, add the
   minimal flag (e.g. honor `--root`) — no behavior change on real runs.
3. New `test/gh205-gate-idempotency.sh`: run the gh174 suite (and any other identified
   root-writer) inside a scratch clone and assert `git status --porcelain` is empty afterward.
   Register in validate.sh TESTS.

## Acceptance

- [ ] `bash validate.sh` leaves `git status --porcelain` completely clean.
- [ ] `test/gh174-harness-registry.sh` writes only under its `$WORK` fixture, never `$ROOT`.
- [ ] `test/gh205-gate-idempotency.sh` green and registered in validate.sh.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/gh205-gate-idempotency.sh" } ],
  "artifacts":     [ "test/gh174-harness-registry.sh", "utils/py/harness_app.py", "test/gh205-gate-idempotency.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh205-gate-idempotency.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "gh174 suite fully fixture-isolated; porcelain-clean gate pinned by a registered regression suite" },
  "lanes":         { "agy_safe": [ "test/gh174-harness-registry.sh", "test/gh205-gate-idempotency.sh" ], "orchestrator_only": [ "relay-automation/", ".tick/" ] }
}
```
