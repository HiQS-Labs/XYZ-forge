---
title: Refuse unsafe GH-642 fixture construction before writes
status: Complete
created: 2026-09-17
updated: 2026-09-17
gh_issue: 665
source: https://github.com/HiQS-Labs/XYZ-forge/issues/665
doc_type: bugfix
owner: noel
goal: Prevent failed GH-642 fixture construction from committing into caller checkouts.
---

# GH-665 — Fixture refusal

## Status

| What was just completed | What's next |
|---|---|
| Caller-preserving fault checks and red controls verified; full gate 393/393; independent source QA Approved; PR #671 ready | Await merge approval; then refresh and qualify #669's own branch |

Canonical execution, recon, rating rationale and acceptance:
[GH-653-FIXTURE-SAFETY.md](GH-653-FIXTURE-SAFETY.md). One test file/clone/branch/PR
for both issues. This issue adapter preserves a distinct ledger and issue identity.
No caller damage is claimed outside prior controlled reproductions.

## Quad Concepts

- Failed setup can retarget a seed commit → validate at write boundaries and refuse.

## Lessons Learned (For Future Agents)

- Guard fixture paths at the write boundary, not at derivation: `mkrepo` refuses empty, `.`, `..`
  and slashed names and checks `mkdir`/`git init` before any seed commit, because an empty
  `git -C` target silently resolves to the caller's checkout.
- A refusal is only proven by the caller-preservation assertion that follows it. Each fault case
  runs in a subshell so its `exit 2` is captured in `rc` and the outer HEAD/git-dir/clean-tree
  check always executes; the committed `caller-damaged` control fails at exactly that assertion,
  which is what makes the control falsifiable (an automated review that read the `exit 2` as
  top-level concluded the opposite — verify subshell scope before trusting that reading).
- An adapter doc that points execution at a canonical sibling (GH-653) still needs its own
  Lessons Learned: the reconciler validates every doc it moves to `3-COMPLETED`, and a missing
  section stops the whole post-merge reconciliation, not just this doc.
