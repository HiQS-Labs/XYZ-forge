---
title: "GH-1: suite-wide fixture containment + clone-identity invariant gate"
status: active
created: 2026-08-15
updated: 2026-08-16
owner: orchestrator (Claude Code)
goal: make every test suite unable to touch the caller's clone — harden require_fixture to resolved-path containment and bracket suite runs with a clone-identity invariant check
gh_issue: 1
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1
branch: gh-1/suite-containment-gate
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
related: "[GH-564 family, GH-559]"
---

# GH-1 — suite-wide fixture containment + clone-identity invariant gate

Captured and promoted in the same PR (issue-first SOP): the issue was filed 2026-08-15 against the
public repo and execution starts immediately, so no 1-INBOX parking period elapsed.

## Status

| What was just completed | What's next |
|---|---|
| PR #6 open; orchestrator review fixes applied 2026-08-16 (TESTS-array comments restored to their own lines, `_fixture_check` init check moved above both case blocks + pinned by a new `/etc`-without-init case, mutation control recorded under `test/baselines/GH-1-init-order-negative-control.md`; gh1 17/0, gh544 78/0) | Merge PR #6 — the detect-half of #1. The prevent-half (adoption across the ~31 unaudited suites) is #10; #1 stays open until that lands |

## Bug

`test/*.sh` suites drive git fixtures under a `mktemp -d` sandbox. When `mktemp` fails under
parallel load, the derived variable is empty, and `git -C ""` / `cd ""` are silent no-ops — every
"fixture" operation lands on the real clone the suite was invoked from. Suites run without `set -e`,
so nothing fails loudly. One suite (`gh544-pre-push-gate.sh`) has a `require_fixture` guard, but its
containment test is **lexical** (`case "$p" in "$WORK"/*)`), which still accepts
`$WORK/../../<real-repo>`; ~31 other suites have no guard at all.

## Source of truth

- GitHub issue: [HiQS-Labs/XYZ-forge#1](https://github.com/HiQS-Labs/XYZ-forge/issues/1)
- This doc is the execution surface of record.

## Plan

1. Extract a hardened `require_fixture` into a shared sourceable helper `test/lib/fixture-guard.sh`:
   non-empty, lexically under `$WORK`, **physically resolved** under `$WORK` (rejects
   `$WORK/../../<real>`), not `$WORK` itself, and of the expected type.
2. Point `test/gh544-pre-push-gate.sh` at the shared helper (its private copy is replaced).
3. Add `test/lib/clone-identity.sh`: capture `core.bare`, remotes, local user identity and `HEAD`
   before a run; assert unchanged after. Wire the bracket into `validate.sh` (and `ci-local.sh`)
   so every suite execution is covered in one place, including the unaudited suites.
4. New suite `test/gh1-fixture-guard.sh` proving: empty path refused, outside path refused,
   `..`-traversal refused (the lexical-check hole), resolved-descendant accepted.

## Verification

- `bash test/gh1-fixture-guard.sh` → expect all PASS in a disposable full clone.
- `bash test/gh544-pre-push-gate.sh` → expect unchanged verdicts.
- `bash test/gh308-frozen-twin-guard.sh --check --staged` → expect clean (no twins touched).
- Manual A/B: `$WORK/../../<real path>` accepted by the old lexical check and refused by the new
  resolved check.

## Non-goals

- Auditing/rewriting all 31 suites to call `require_fixture` per mktemp — the identity bracket in
   `validate.sh` covers them detectably; per-suite adoption lands incrementally.
- Any change to suite runtime behavior or `set -e` posture.
