---
gh_issue: 45
source: https://github.com/HiQS-Labs/XYZ-forge/issues/45
title: "validate.sh must refuse to run from a linked worktree — an observed run corrupted the parent clone"
status: Active (2-WORKING — built 2026-08-18)
created: 2026-08-18
updated: 2026-08-18
owner: noelsaw1
doc_type: bugfix
effort: 1
complexity: 2
risk: 2
goal: >
  Make the whole class of "suite escapes a fixture into the shared .git" unreachable from the
  entry points: validate.sh and ci-local.sh refuse to run from a linked git worktree (fail
  closed, every tier), with a message that names the observed damage and an explicit
  XYZ_ALLOW_WORKTREE_GATE=1 override for deliberate disposable runs.
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/35
---

# GH-45: The gate refuses to run from a linked worktree

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-08-18 (clone `XYZ-forge-gh35`, `development`)**: `validate.sh` and `ci-local.sh` refuse to run from a linked git worktree — exit 2, before anything executes, in every tier. Detection is the issue's verified one-liner (`--absolute-git-dir` vs a resolved `--git-common-dir`, the GH-448 resolver's idiom), anchored on BOTH `HERE` and the invocation CWD so an absolute-path invocation from outside the worktree cannot slip past. The message names the observed 2026-08-19 damage (core.bare=true, origin repointed at a deleted temp path, every `refs/remotes/origin/*` deleted, `development` overwritten with fixture commits); `XYZ_ALLOW_WORKTREE_GATE=1` overrides and announces itself. Pinned in `test/gh35-test-tiers.sh` §9 (suite now 67/0), including the issue's required control: the normal checkout of the SAME fixture repo still runs, silently. | GH-564 owns the per-suite fixture-escape audit — this guard is deliberately outer and stays valuable after every suite is fixed (it fails closed for suites nobody has audited yet). The incident's doc record lives on the `docs/worktree-gate-safety` lane (separate branch). Revisit whether `githooks/pre-push`'s fallback (which execs validate.sh) needs its own wording once a real worktree push is observed. |

## What happened (the incident, abridged)

Running `bash validate.sh` from a **linked git worktree** corrupted the parent clone at
`~/Documents/GH Repos/XYZ-forge` on 2026-08-19: `core.bare=true` on a working-tree clone,
`remote.origin.url` repointed to a since-deleted fixture bare repo, all `refs/remotes/origin/*`
deleted, `development` and `main` overwritten with fixture commits, fixture branches and ~72
fixture files left behind. No commits were lost; recovery required knowing exactly what to look
for. Full damage list: [#45](https://github.com/HiQS-Labs/XYZ-forge/issues/45).

Root cause: a linked worktree **shares the parent's `.git` common directory** — config, refs,
objects. A suite that reaches "the repo" through `git -C "$(git rev-parse --git-common-dir)"`,
or whose fixture path resolves empty and falls through to the caller, hits the **real** clone.
That is GH-564's class firing for real; this guard is the cheap structural outer fence while
(and after) the per-suite audit proceeds.

## The guard

- **Where:** top of `validate.sh` (after `HERE` resolution, before the TESTS array — nothing
  runs first) and top of `ci-local.sh` (after its `cd "$HERE"`), because ci-local runs the same
  suite and writes the gate record (issue requirement 4). Kept inline in both rather than a new
  shared `.sh` — GH-551 outlaws new Bash under `utils/`; both copies are pinned by the same
  suite section.
- **Detection (verified):** `git rev-parse --absolute-git-dir` vs `--git-common-dir` resolved to
  a physical path. Main checkout: equal. Linked worktree: `<common>/worktrees/<name>` differs.
  Checked for BOTH `HERE` and `$PWD` — a suite's `git -C ""` escape lands in the CWD's repo,
  the identity bracket asserts HERE's, and both must be clean.
- **Refusal:** exit 2 with the consequence-naming message (issue requirement 1 — an operator
  who does not know what breaks will override).
- **Override:** `XYZ_ALLOW_WORKTREE_GATE=1`, announced when used (a silent bypass is
  indistinguishable from no guard).
- **Scope:** every tier. Tier 1 runs no fixtures but refusing uniformly is simpler to reason
  about and the docs gate is cheap to run from a normal clone.

## Validation

| What | Result |
|---|---|
| `test/gh35-test-tiers.sh` §9 (GH-45) | 12/12 within the suite's 67/0 — worktree refused exit 2 before anything runs; message names core.bare / origin / remote-refs / development consequences and the override; override runs AND announces; **control: the same fixture's main checkout still runs silently**; `ci-local.sh` refuses from the worktree; absolute-path invocation with HERE in the worktree still refused |
| Neighbor pins after the guard | `gh544-parallel-default` 29/0 · `gh4-ungated-clone-warning` 6/0 · `ci-workflow` green · `path-integrity` 2/0 · security-scan clean · mktemp-trap-guard clean |
| Full `./validate.sh` on this change | **GREEN 216/216** (2026-08-18, clone `XYZ-forge-gh35`, 4-wide balanced) — run from the normal checkout, where the guard passes silently, exactly as the control asserts |

## Lessons Learned (For Future Agents)

- The blast radius of a suite run is "every clone sharing this `.git`", not "this directory":
  a linked worktree isolates the working tree ONLY. Anything reached through `.git` — config,
  remotes, refs, hooks — is the parent's (the GH-564 rail, now enforced at the entry point).
- `test/gh4-ungated-clone-warning.sh` already could not pass from a worktree (`rm
  .git/hooks/pre-push` — in a worktree `.git` is a file): the gate was never meaningfully
  runnable there; it just failed confusingly instead of refusing clearly.
