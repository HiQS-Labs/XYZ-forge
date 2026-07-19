---
gh_issue: 44
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/44
title: RCA — sandboxed inline run of relay-turn-lib.sh polluted the main repo (.git fall-through)
status: Closed — Queued (rated + contracted — marathon-ready)
created: 2026-06-28
updated: 2026-07-02
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
roadmap_exempt: false
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

## Swarm Preflight Contract

Consumed by `utils/swarm-preflight.sh`. Same-repo build (`target.ref: main`). **Test-harness only** —
no kernel/tick-schema change, so no decision record is required. Verified drift: 3 fixtures build
scratch repos, only 2 harden with `GIT_CEILING_DIRECTORIES`. Independent zone (test files), agy-safe.
Probe polarity is `grep_present` (the fix ADDS a hardened helper + rail rather than removing a marked
bug line).

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_present", "path": "test/_scratch-repo.sh", "pattern": "GIT_CEILING_DIRECTORIES" }, { "type": "grep_present", "path": "AGENTS.md", "pattern": "GH-44" } ],
  "artifacts":   [ "test/_scratch-repo.sh", "test/fixtures/canary-peer-orphan/verify-fixture.sh", "test/fixtures/canary-reviewer-overstep/verify-fixture.sh", "AGENTS.md" ],
  "remediation": { "source": "GH-44#remediation", "criteria": "New test/_scratch-repo.sh exposes a mk_scratch_repo helper that (a) exports GIT_CEILING_DIRECTORIES to the scratch parent and (b) hard-asserts $SC/.git exists before any git op, aborting (never falling through) if init failed. The scratch-repo fixtures (canary-peer-orphan, canary-reviewer-overstep) source it instead of open-coding the guard. Add an AGENTS.md rail (GH-44 marker) forbidding driving repo-mutating helpers inline in a sandboxed shell. validate.sh stays green." },
  "lanes":       { "agy_safe": [ "test/_scratch-repo.sh", "test/fixtures/canary-peer-orphan/verify-fixture.sh", "test/fixtures/canary-reviewer-overstep/verify-fixture.sh", "AGENTS.md" ], "orchestrator_only": [] }
}
```
