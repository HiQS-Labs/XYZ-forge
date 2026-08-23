---
title: "GH-2: test-suite run relocated an untracked file into .tick/orphan-backups/"
status: active
created: 2026-08-22
updated: 2026-08-22
owner: orchestrator (Claude Code)
goal: reproduce the untracked-file relocation, then guard every mv/rm/find-delete on a derived path with a resolved-containment check at the use boundary
gh_issue: 2
source: https://github.com/HiQS-Suite/XYZ-forge/issues/2
branch: gh-2/orphan-backup-relocation
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
related:
  - "#1 — same containment family (unguarded empty/derived path redirecting file ops onto real content); #1 owns require_fixture, this owns the mv/rm audit"
---

# GH-2 — untracked file relocated into .tick/orphan-backups/

Release 0.7.3 "Bulkhead" manifest member. Radar 2026-08-22: suite-containment class
(RADAR-class-suite-containment), data-loss polarity.

## Bug

A test-suite run moved an untracked file from a project docs directory into
`.tick/orphan-backups/`. Observed once, not yet reproduced. Same family as #1's sandbox
escape: an unguarded empty/derived path variable redirecting file operations onto real
content — silent data loss for anything not under version control. Known trigger condition:
`mktemp` failure under parallel load.

## Plan

1. Reproducer `test/gh2-orphan-backup-repro.sh`: force the mktemp-failure path under parallel
   load and assert no file outside the fixture moves (negative control: with the guard stubbed
   out, the relocation must be detected).
2. Audit every suite + harness script for `mv` / `find -delete` / `rm -rf` on derived paths;
   each call site gains a resolved-containment check at the use boundary (reusing #1's
   `require_fixture` helper where present — consuming it, not editing it).
3. Register the suite in validate.sh TESTS.

## Acceptance

Repro suite green in both polarities (guarded: nothing moves; guard stubbed: detection fires);
audit table of call sites recorded in this doc; suite registered.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/gh2-orphan-backup-repro.sh" } ],
  "artifacts":     [ "test/gh2-orphan-backup-repro.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh2-orphan-backup-repro.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "reproducer green in both polarities; every audited mv/rm/find-delete call site on a derived path carries a resolved-containment check" },
  "lanes":         { "agy_safe": [ "test/gh2-orphan-backup-repro.sh" ], "orchestrator_only": [ ".tick/" ] }
}
```
