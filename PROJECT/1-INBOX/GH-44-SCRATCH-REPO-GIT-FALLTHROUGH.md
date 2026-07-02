---
gh_issue: 44
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/44
title: RCA — sandboxed inline run of relay-turn-lib.sh polluted the main repo (.git fall-through)
status: Proposed (1-INBOX — not yet active)
created: 2026-06-28
doc_type: bugfix
related:
  - PROJECT/3-COMPLETED/GH-40-DOUBLE-BLIND-REVIEWER.md
---

# GH-44 · scratch-repo `.git` fall-through can pollute the parent repo

**Process/safety RCA.** While building the GH-40 peer-orphan canary, the real containment kernel
`relay-turn-lib.sh` was driven **inline in a sandboxed shell** against a scratch dir inside the repo.
The sandbox blocked the scratch `.git` from being created, so `git -C "$SC"` fell through to the
**main** repo: a garbage commit landed on the branch and `rtl_enforce` ran `reset --hard` against the
live repo. Contained, fully recovered, nothing pushed (origin stayed at `a9eb587`).

## Root cause

git's upward `.git` discovery + a partially-failed `git init` (no nested repo) ⇒ silent fall-through to
the parent. The caller had no `GIT_CEILING_DIRECTORIES`, no nested-`.git` precondition, and drove a
history-mutating helper (`reset --hard`) inline instead of via a bash script run un-sandboxed.

## Safeguards (what worked / what was missing)

- **Worked:** not pushed; `rtl_enforce`'s own `refs/relay-orphan/` backstop preserved the commit before
  reset; reflog made recovery total; the real test suite already builds scratch repos safely.
- **Missing:** nothing stopped the fall-through when an in-tree scratch `.git` failed to init.

## Remediation

- **Applied:** `test/fixtures/canary-peer-orphan/verify-fixture.sh` exports `GIT_CEILING_DIRECTORIES`
  and asserts `[ -d "$SC/.git" ]` before any git op.
- **Proposed:** a shared hardened scratch-repo helper (`test/_setup.sh` / `test/_scratch-repo.sh`); an
  `AGENTS.md` rail (never drive repo-mutating helpers inline); optional `rtl_init` `.git` precondition.
