---
gh_issue: 549
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/549
title: "Pre-push gate is silently skipped on any branch without githooks/ — move the entrypoint out of the working tree"
status: 2-WORKING
created: 2026-08-14
updated: 2026-08-14
owner: unassigned
doc_type: capture
complexity: 2
risk: 4
effort: 1
ratings_provisional: true
related:
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/544 — the gate this corrects; same PR"
goal: >
  Make a missing or overridden hook wiring LOUD instead of silent, so that a push from any branch in
  an installed clone is either gated or refused — never quietly ungated.
---

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-08-14.** Entrypoint moved from `core.hooksPath=githooks` to a dispatch stub in the clone's `.git/hooks/`. `gh544-pre-push-gate` 63/0 (was 38/0), including a real-`git push` harness against a local bare remote and the negative control that reproduces the bug. Cross-model consult (codex + agy) run and adjudicated. | Merge with #544 — this ships inside PR #545, not separately. |

## The defect, and why it is worse than it looks

`core.hooksPath` is **repo-config scoped, not branch scoped**. Once set, it persists across every
checkout in the clone. On a branch with no `githooks/` directory — one cut before the hook landed, an
old feature branch, a bisect checkout — git resolves no hook file and **runs no hook at all**. Git
emits no warning for a `core.hooksPath` that does not resolve.

Observed live, not predicted: pushing `chore/ship-litmus-nightwatch` produced **no gate output**. That
push was in fact verified, because the gate was run by hand — but the mechanism failed silently, which
is exactly the property #544 exists to eliminate. A gate that is sometimes absent and always quiet is
worse than no gate, because it also produces the belief that something was checked.

The structural trap: **the hook is the thing that does not run**, so no code inside `githooks/pre-push`
can detect its own absence. Any fix that lives in the failing component is not a fix.

## Decision

Cross-model consult (codex + agy, transcripts in `relay-system/2026-08-14/hookspath-loud2-185938/`).
Both converged independently on moving the entrypoint out of the working tree, and both rejected the
alternatives for the same reason.

**Adopted:** `install.sh` writes a dispatch stub to the clone's `.git/hooks/pre-push` and leaves
`core.hooksPath` **unset** (migrating the legacy value). The stub lives in git metadata, so it is
branch-independent. It keeps no logic beyond dispatch:

1. exec the in-tree `githooks/pre-push` when present — all real logic stays reviewable in-tree, and
   the two cannot drift, because the stub is not a copy of it
2. else run `validate.sh` directly, announced — branches predating the hook still gate
3. else **refuse** the push

**Rejected — a check in `validate.sh` / `ci-local.sh`:** it only runs when the operator already chose
to run it, so it cannot observe the push where git found no hook. It is a detector inside the thing
that fails to run, one layer removed.

**Rejected — a documentation note:** no mechanical guarantee. The rails already correctly call this
the only gate, which raises the cost of a silent bypass rather than lowering it.

### Where the two advisors diverged, and the adjudication

They split on the stub's **location**. agy said `.git/hooks/` with `core.hooksPath` unset; codex
objected that `.git/hooks` is "awkward for linked worktrees, whose `$GIT_DIR` is private per worktree"
and proposed a custom directory under the git common dir instead.

**Measured rather than adjudicated on argument:** from a linked worktree,
`git rev-parse --git-path hooks` returns the **parent clone's** `.git/hooks`. Git looks for hooks
under the common dir, which worktrees share. codex's objection does not hold, and the custom
directory it motivated buys nothing — so the default location stands, per the smallest-mechanism bias.
codex's other correction *was* load-bearing and is adopted: `core.hooksPath` must be explicitly
**unset**, or the stale value keeps overriding the stub.

They also split on the stub's **body**: codex embedded the full gate logic in the installed copy;
agy kept it a delegator. The delegator wins — an embedded copy drifts from the in-tree hook the first
time the hook is edited, and drift in a gate is invisible by construction.

### The bug this suite caught in its own fix

The first implementation resolved the stub's destination with `git rev-parse --git-path hooks`. That
call **obeys `core.hooksPath`** — so on a clone still carrying the legacy value it resolved to the
in-tree `githooks/`, and the installer targeted the very hook it delegates to. Caught by the migration
test's exit code, not by review. Resolution moved to `--git-common-dir`, which ignores the override,
and an assertion now pins that the in-tree hook survives migration.

## Acceptance

Copied verbatim from [#549](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/549):

- [x] `githooks/install.sh` writes the stub to `$(git rev-parse --git-path hooks)/pre-push` and unsets a legacy `core.hooksPath=githooks`; still refuses (exit 4) to clobber a foreign `core.hooksPath`.
- [x] `--check` reports the stub's presence/executability; exit 1 when absent.
- [x] `--uninstall` removes the stub, and only when it carries this installer's marker.
- [x] A real `git push` to a local bare remote, from a branch with **no** `githooks/` directory, runs the gate and refuses on red — asserted in `test/gh544-pre-push-gate.sh` (the current test invokes the hook directly and so cannot exercise git's dispatch).
- [x] Delete-only pushes and `XYZ_SKIP_PREPUSH=1` still short-circuit on the fallback path, not just the delegated one.
- [x] Negative control recorded in `test/baselines/`.
- [x] Command rails updated.

### Acceptance — deviations from the issue

- [changed] `githooks/install.sh` writes the stub to `$(git rev-parse --git-path hooks)/pre-push` -> writes it to `$(git rev-parse --git-common-dir)/hooks/pre-push` — reason: `--git-path hooks` obeys `core.hooksPath`, so during migration from the legacy value it resolves to the in-tree `githooks/` and the installer would target the hook it delegates to. The resolved location is identical once the override is cleared; `--git-common-dir` is simply the form that is correct *before* it is.

## Residual gap (stated, not solved)

A fresh clone that has never run `install.sh` is ungated — unchanged, and intended: `--check` makes
that detectable. `git push --no-verify` remains an explicit, announced escape. Neither is fixable
client-side, because the hook is the component that does not run; closing them requires a server-side
receive policy, which is out of scope while the repo is private.
