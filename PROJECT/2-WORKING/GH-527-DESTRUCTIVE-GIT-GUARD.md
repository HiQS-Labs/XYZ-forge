---
gh_issue: 527
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/527
title: "Three destructive incidents in one session: a git history command used to undo a working-tree experiment has no guard"
status: 2-WORKING
created: 2026-08-14
updated: 2026-08-14
owner: unassigned
doc_type: capture
complexity: 2
risk: 3
effort: 2
ratings_provisional: true
goal: >
  Make a git command that overwrites the working tree from a committed state
  recoverable rather than destructive, by snapshotting the tracked files it is
  about to overwrite into the directory the repo already uses for exactly this.
---

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-08-14** on `fix/critical-2026-08-14` — all five acceptance criteria met. Part A: the `AGENTS.md` rail names all three spellings and points at the guard. Part B: `relay-automation/hooks/gh527-destructive-git-guard.sh` snapshots the doomed **tracked** files into `.tick/orphan-backups/` and always exits 0 (it is a net, not a gate), registered as a third `Bash` PreToolUse matcher. `test/gh527-destructive-git-guard.sh` is **26/0** and registered in `validate.sh`; recovery is demonstrated end-to-end (destroy → `v1` → restore → `PEER-UNCOMMITTED-WORK`), and untracked files are asserted to survive, matching the issue's own reproduced blast radius. | Operator review of the shape decision. **Read the control record first** (`test/baselines/GH-527-negative-control.md`): clean-tree silence is defended by **two** independent conditions, so two separate single-line mutations both stayed green and it took a combined mutation to produce the red. That is recorded rather than smoothed over, because a control that cannot be falsified by the obvious edit is the exact failure mode this repo keeps paying for. |

## Why

Three times in one session (2026-08-12) uncommitted work in the shared clone was destroyed by
using a **git history command to undo a working-tree experiment**: a tree-wide `git stash` that
timed out before its `pop`, a `git checkout -- <path>` that restored HEAD rather than the
pre-mutation state, and a `git reset --hard origin/development` that took four other sessions'
tracked modifications plus `.claude/settings.json` — which never came back.

The harness already prevents the *headless* version of this (relay allowlist, worktree isolation,
`.tick/orphan-backups/`). The interactive version has no guard, and the interactive agent is the
one that did it three times.

**The blast radius was reproduced, not inferred:** tracked modifications are destroyed; untracked
files survive. That is what makes the guard's design tractable — the dangerous case is exactly
the one a peer agent produces most often, editing a file that already exists.

## Key concepts

- **A doc rail alone will not fix this, and the issue proves it.** Running `/debug-mantra` against
  the original AGENTS.md-only proposal falsified it using the session's own ledger: every
  *mechanical* guard (frozen-twin, `path-integrity.sh`, the GH-472 SIGPIPE detector) caught the
  author; neither *written* warning did. The rail is the explanation, not the fix.
- **Shape chosen: 2, snapshot-then-allow.** The issue offers three shapes and calls the choice an
  operator decision; this lane takes shape 2 because it is the shape the repo already chose for
  the same problem — `rtl_check` copies an off-allowlist edit into `.tick/orphan-backups/`
  before reverting it (GH-141) precisely so a wrongly-caught edit stays recoverable. Shape 1
  (refuse-when-dirty) fires on every legitimate solo-session cleanup and trains an override
  reflex, and it cannot satisfy acceptance criterion 4, which requires demonstrated recovery.

## Acceptance

Copied verbatim from the tracking issue's `## Acceptance` block.

- [ ] `AGENTS.md` carries the rail, naming all three command shapes and pointing at the guard.
- [ ] A `PreToolUse` hook intercepts the three shapes in a dirty tree.
- [ ] **A witnessed red control** (GUIDING-PRINCIPLES #13): a fixture where the command would destroy a peer's tracked edit, showing the guard firing — and a control showing it does *not* fire on a clean tree, so it is not a blanket that trains people to override it.
- [ ] Recovery is demonstrated end-to-end, not asserted: destroy → recover from the snapshot.
- [ ] The hook is registered in `.claude/settings.json` alongside the existing `Bash` matchers.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "type": "grep_absent", "path": ".claude/settings.json", "pattern": "gh527-destructive-git-guard" }
  ],
  "artifacts":   [
    "relay-automation/hooks/",
    "AGENTS.md",
    ".claude/settings.json",
    "test/",
    "validate.sh"
  ],
  "remediation": { "source": "issue#527", "criteria": "Snapshot tracked files into .tick/orphan-backups before a tree-overwriting git command, plus the AGENTS.md rail" },
  "lanes":       { "agy_safe": [ "relay-automation/hooks/", "test/" ], "orchestrator_only": [ ".claude/settings.json", "AGENTS.md", "validate.sh" ] }
}
```

Contract auto-drafted by the 2026-08-14 fix-now pass — artifacts/lanes not yet operator-verified.
