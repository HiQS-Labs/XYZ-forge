---
gh_issue: 225
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/225
title: "10days/marathon guardrail: Agent isolation:\"worktree\" lanes can branch from a stale historical commit, not the marathon branch — silent full-merge risk"
status: "captured 2026-07-17"
created: 2026-07-17
updated: 2026-07-17
owner: noel
doc_type: bug
complexity: 1
risk: 2
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Not attempting to fix or work around the Agent tool's isolation-worktree base-selection behavior
    itself — that's harness-internal, not this repo's code
  - Not mandating cherry-pick in every case — only when the ancestry check fails
related:
  - skills/10days/SKILL.md
goal: >
  Document a guardrail in skills/10days/SKILL.md Step 7 — verify each parallel lane's
  isolation:"worktree" base against the marathon branch's start commit before merging, and prefer
  cherry-pick over a full merge when that check fails.
roadmap_exempt: false
---

# GH-225 · isolation:"worktree" stale-base merge guardrail

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-07-17, promoted to 2-WORKING with a Swarm Preflight Contract. Found live during the GH-174/215/222/189 marathon fire the same day — all 4 lanes' isolation worktrees branched from stale historical commits, not the marathon branch; caught only because `git log` was checked manually before merging. Not yet fixed. | Queue in the next marathon fire; doc-only, low complexity. |

## The gotcha (observed, not hypothetical)

2026-07-17: 4 parallel lanes (GH-174/215/222/189) were each dispatched as a subagent with
`isolation: "worktree"`. Every one of the 4 isolation worktrees was checked out from a stale
historical commit (e.g. `788a5c6`, `e8acdc5`) instead of `marathon/gh174-215-222-189-2026-07-17` —
the branch actually cut for the fire and named as `target.ref` in each lane's own task doc.

Caught by inspecting `git log` on each lane's worktree before merging. Had a plain `git merge
<lane-branch>` been used instead of the cherry-pick that was actually done, it would have pulled in
every commit between the stale base and the marathon branch tip — silently reintroducing
already-superseded file states alongside the lane's real fix.

## Why this is a repo-level concern, not just a one-off

`skills/10days/SKILL.md` Step 7 is the documented procedure for exactly this pattern (parallel
isolated-worktree lanes → merge each back) and currently has **no instruction** to verify a lane's
worktree base before merging, nor any preference for cherry-pick over merge for this reason. Any
future `/10days` or marathon fire dispatching parallel `isolation:"worktree"` lanes is exposed to the
same risk, and a future run might not think to check `git log` first the way this one happened to.

## Fix direction

Doc-only guardrail — the isolation-worktree base-selection behavior itself is an Agent-tool internal,
out of this repo's control:

1. `skills/10days/SKILL.md` Step 7: add an explicit check — before merging any lane's
   isolation-worktree commit(s), verify with `git merge-base --is-ancestor <marathon-branch-start>
   <lane-worktree-HEAD>` (or equivalent ancestry check). If it fails (worktree is based on a
   stale/unrelated point), **cherry-pick the lane's specific new commit(s) onto the marathon branch —
   never `git merge` the isolation branch wholesale.**
2. Check whether any other doc in this repo gives the opposite (merge-first) instruction for this
   pattern and align it.
3. Optional, not required for done: a small deterministic pre-merge check script automating step 1's
   ancestry check, erroring instead of silently merging.

## Definition of done

- [ ] `skills/10days/SKILL.md` Step 7 documents the ancestry check + cherry-pick-over-merge guardrail.
- [ ] Confirmed no other doc gives the opposite (merge-first) instruction for this pattern.
- [ ] `bash validate.sh` no worse than baseline.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "skills/10days/SKILL.md", "pattern": "merge-base --is-ancestor" }
  ],
  "artifacts": [ "skills/10days/SKILL.md" ],
  "remediation": {
    "source": "issue#225",
    "criteria": "skills/10days/SKILL.md Step 7 documents verifying each lane's isolation-worktree base against the marathon branch's start commit (via git merge-base --is-ancestor or equivalent) before merging, and instructs cherry-picking the lane's specific commit(s) rather than a full git merge when that check fails. bash validate.sh green, no worse than pre-existing environmental reds."
  },
  "lanes": { "agy_safe": [ "skills/10days/SKILL.md" ], "orchestrator_only": [] }
}
```
