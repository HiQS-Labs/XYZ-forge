---
title: "GH-50: sandboxed git --track / branch -D half-applies — working tree rewritten, .git/config write fails, HEAD left behind"
status: active
created: 2026-08-22
updated: 2026-08-22
owner: orchestrator (Claude Code)
goal: make branch operations refuse-or-succeed atomically under a sandbox that blocks .git/config writes, so a half-applied switch can never overwrite uncommitted work
gh_issue: 50
source: https://github.com/HiQS-Suite/XYZ-forge/issues/50
branch: gh-50/sandboxed-git-half-apply
doc_type: bugfix
effort: 1
complexity: 1
risk: 1
---

# GH-50 — sandboxed git switch half-applies and loses uncommitted work

## Status

| What was just completed | What's next |
|---|---|
| capture doc + preflight contract written (ready, exit 0); queued as Bulkhead wave 3 (2026-08-22, release 0.7.3 "Bulkhead", #179) | Operator fires the marathon lane per MARATHON-PLAN-2026-08-23.md; builder executes ## Plan, reviewer verifies ## Acceptance |


Release 0.7.3 "Bulkhead" manifest member. Radar 2026-08-22: data-loss class.

## Bug

Inside a sandbox that blocks `.git/config` writes, `git switch --track` updates the index and
working tree, then fails the config write and leaves HEAD behind — the tree holds another
branch's content while HEAD points at the old branch. An uncommitted modification to
`test/ballast-release.sh` was overwritten and lost this way. The fatal line
(`error: could not lock config file .git/config: Operation not permitted`) is easy to truncate
away; the visible symptom is only a misleading upstream hint.

## Plan

1. `utils/git-sandbox-guard.sh` (new): a preflight primitive that probes `.git/config`
   writability and refuses tracking/branch-mutation operations up front with a named error,
   for harness scripts that switch branches (relay/marathon drivers).
2. Adopt the guard at the harness call sites that perform `switch --track` / `branch -D`.
3. `test/gh50-sandboxed-git-guard.sh`: simulate a read-only `.git/config` and assert the guard
   refuses before any tree mutation; register in validate.sh TESTS.
4. AGENTS.md: one-paragraph note naming the failure shape (do not truncate git stderr on
   branch operations).

## Acceptance

With `.git/config` unwritable, a guarded `switch --track` refuses with a named error and the
working tree is byte-identical; gh50 suite green and registered.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "utils/git-sandbox-guard.sh" },
                     { "type": "path_absent", "path": "test/gh50-sandboxed-git-guard.sh" } ],
  "artifacts":     [ "utils/git-sandbox-guard.sh", "test/gh50-sandboxed-git-guard.sh", "AGENTS.md", "validate.sh" ],
  "artifacts_new": [ "utils/git-sandbox-guard.sh", "test/gh50-sandboxed-git-guard.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "guarded branch ops refuse-or-succeed atomically when .git/config is unwritable; no tree mutation on refusal; gh50 suite green" },
  "lanes":         { "agy_safe": [ "utils/git-sandbox-guard.sh", "test/gh50-sandboxed-git-guard.sh" ], "orchestrator_only": [ "AGENTS.md" ] }
}
```
