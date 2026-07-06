---
gh_issue: 59
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/59
title: relay-turn-lib — allowlisted artifact in an untracked dir trips spurious off-lane (exit 6)
status: Proposed (1-INBOX — not yet active)
created: 2026-07-02
doc_type: bug
complexity: 3
risk: 3
effort: 3
ratings_provisional: false
related:
  - relay-automation/relay-turn-lib.sh
  - test/worktree-isolation.sh
  - decisions/
---

# GH-59 · relay-turn-lib: allowlisted artifact in an untracked dir → spurious off-lane (exit 6)

**Why (reproduced live twice):** under worktree isolation, a turn whose **allowlisted artifact lives
in an otherwise-untracked directory** is wrongly flagged as a containment violation (exit 6, "off-lane
edit reverted") and its whole turn is discarded — though nothing off-lane was touched. First surfaced
in the Part C live-loop dogfood (2026-06-30, `improve-loop-machinetest/target.txt`), and again
**this session** building GH-61 Tier 1 CI (`.github/workflows/ci.yml` — codex built all 3 allowlisted
files correctly and its gate passed, yet the turn was discarded). Worked around GH-61 with an empty
tracked stub; the bug remains.

**Root cause:**
1. `rtl_worktree_begin` seeds the allowlist into the worktree; if the artifact's parent dir is not at
   `HEAD`, the seeded file is **untracked in the worktree**.
2. `rtl_worktree_end` runs `git status --porcelain -z`. Git **collapses an all-untracked directory** to
   a single `<dir>/` entry — the loop sees `.github/`, not `.github/workflows/ci.yml`.
3. `rtl_in_allow` is an **exact string match** — the collapsed dir prefix never equals the file-level
   allowlist entry → `RTL_WT_OFFLANE=1` → exit 6.

`.relay-artifacts/` is **already** special-cased for exactly this collapse
([relay-turn-lib.sh](../../relay-automation/relay-turn-lib.sh)); the general allowlist case was never
generalized.

**Fix direction:** make `rtl_in_allow` (or the `rtl_worktree_end` off-lane loop) treat a
git-collapsed untracked-directory prefix as allowed **when it is an ancestor of** an allowlisted path
(so `.github/` matches allowlist entry `.github/workflows/ci.yml`), mirroring the `.relay-artifacts`
special-case but generalized. Preserve strictness: a change to any path NOT under an allowlisted
ancestor still trips off-lane.

**Blast radius — Costly (containment kernel).** `relay-turn-lib.sh` is the shared containment core;
per AGENTS.md a change here is at least Costly and needs a `decisions/` record + a regression fixture
before it lands. The guard against over-broadening: match only true *ancestors* of a concrete
allowlist file entry, never a bare prefix.

## Acceptance
- [ ] `rtl_in_allow` (or the `rtl_worktree_end` off-lane loop) treats a git-collapsed untracked-directory prefix as allowed WHEN it is an ancestor of an allowlisted **file** entry — mirroring the existing `.relay-artifacts` special-case, but generalized.
- [ ] A greenfield-artifact-in-a-new-dir turn (allowlisted file in an otherwise-untracked dir) commits file-scoped with **no** spurious exit 6.
- [ ] A genuinely off-lane change (a new file NOT under any allowlisted ancestor) STILL trips exit 6 (strictness preserved — match only true ancestors of a concrete allowlist file, never a bare prefix).
- [ ] The change carries a `GH-59` marker comment at the generalization site in `relay-automation/relay-turn-lib.sh`.
- [ ] A regression case is added to `test/worktree-isolation.sh` covering both the fixed greenfield case AND the still-rejected genuine off-lane case; it fails without the fix and passes with it.
- [ ] `bash test/worktree-isolation.sh` passes; no edit outside `relay-automation/relay-turn-lib.sh` + `test/worktree-isolation.sh`.

> **Build precondition:** `decisions/2026-07-02-offlane-untracked-dir.md` (the behavior contract) is authored by the orchestrator BEFORE this lane fires — it is not part of the builder's allowlist.

## Swarm Preflight Contract

Consumed by `utils/swarm-preflight.sh`. Same-repo build (`target.ref: main`); source + test both exist
(a fix that extends them, not greenfield). **Kernel zone** (`relay-turn-lib.sh`) — serializes; at most
one kernel lane per wave. Opus-grade (kernel correctness). The `decisions/` record is a build
precondition, not a preflight gate.

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash test/worktree-isolation.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "relay-automation/relay-turn-lib.sh", "pattern": "GH-59" } ],
  "artifacts":   [ "relay-automation/relay-turn-lib.sh", "test/worktree-isolation.sh" ],
  "remediation": { "source": "GH-59#fix-direction", "criteria": "rtl_in_allow (or the rtl_worktree_end off-lane loop) treats a git-collapsed untracked-directory prefix as allowed when it is an ancestor of an allowlisted file entry, mirroring the existing .relay-artifacts special-case; a greenfield-artifact-in-a-new-dir turn commits file-scoped with no spurious off-lane exit 6, while a change outside any allowlisted ancestor still trips off-lane; regression case added to test/worktree-isolation.sh; carries a GH-59 marker comment. Costly containment-kernel change — write decisions/2026-07-02-offlane-untracked-dir.md first." },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
