---
gh_issue: 539
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/539
title: "A gitignored 2-minute skill-sync job resurrects deleted SKILL.md files, so a skill deletion is never durable"
status: 2-WORKING
created: 2026-08-14
updated: 2026-08-14
owner: unassigned
doc_type: capture
complexity: 1
risk: 3
effort: 1
ratings_provisional: true
goal: >
  Make a skill deletion in this repo stick, by fixing the bidirectional sync that silently writes
  the file back — or at minimum by making the rewrite legible instead of appearing as mystery
  untracked noise.
---

## Status

| What was just completed | What's next |
|---|---|
| **Diagnosed and filed 2026-08-14** while landing the GH-395 deletion, which is what exposed it. Root cause identified with a preserved-mtime proof; issue #539 filed, then **rewritten** after the first diagnosis proved wrong. **Re-filed against the owning repo as [`Hypercart-Dev-Tools/rebalance-OS#269`](https://github.com/Hypercart-Dev-Tools/rebalance-OS/issues/269)** — checked first for a duplicate; the closest by name (rebalance-OS#237) is an auto-filed health alert about the job's exit status, unrelated to deletion propagation. **No fix is built, and none of the candidate fixes lives in this repo.** | Tracked on rebalance-OS#269. #539 stays open here as the **consumer-side record**, because the symptom is observed here and the consequence is local. Close it when #269 lands, or when the `giant-brains-claude-skills/04-build/ponytail-refined/` counterpart is deleted — whichever makes the deletion stick. |

## Why

`~/Library/LaunchAgents/com.rebalance-os.3eyes.skill-sync.plist` runs every **120 seconds** and
executes a 3-Eyes job whose own config describes it as:

> Bidirectional last-writer-wins sync of shared SKILL.md files between `giant-brains-claude-skills`
> and `xyz-3-agents-swarm`.

**Last-writer-wins bidirectional sync has no representation for a deletion.** Removing
`skills/<name>/SKILL.md` here is not a change it can propagate — it sees the file present on the
other side and copies it back. So a skill deletion is reverted within two minutes, silently.

**This is the mechanism behind GH-395.** That issue reports an unreviewed CI push reverting
GH-180's removal of `skills/ponytail-refined/`. No unreviewed intent is needed to explain it:
delete and commit → the sync writes it back untracked within 2 minutes → the next `git add -A`
re-adds it → the deletion is undone inside someone else's commit, looking like unrelated noise.

The job is **machine-local and gitignored** (the GH-195 overlay), which is why this is invisible to
anyone reading the repo: the thing undoing the commit is not in the repo.

## Key concepts

- **Preserved mtime is the discriminating evidence.** The resurrected file carried
  `Aug 11 15:29:08`, byte-identical to `giant-brains-claude-skills/04-build/ponytail-refined/SKILL.md`.
  Any git-based restore (`checkout`, `reset --hard`, `stash pop`) stamps mtime to the time of the
  run. That single fact is what ruled out the entire first diagnosis.
- **A skill deletion in this repo is currently not durable**, and nothing reports it. Any lane
  whose deliverable is removing a skill can pass its gate and be silently reverted.

## Acceptance

Authored by this lane — the issue is one I filed and it carries a "Suggested fix" list rather than
an `## Acceptance` block.

1. Deleting a skill directory in this repo survives for at least one sync interval. **[not met]**
2. Whatever the sync rewrites is recorded somewhere a reader can find, rather than appearing as
   unexplained untracked files. **[not met]**
3. GH-395's deletion of `skills/ponytail-refined/` is durable end-to-end. **[not met]**

## Acceptance — deviations from the issue

- [dropped] All three candidate fixes — reason: every one of them is outside this repository. The
  counterpart file lives in `giant-brains-claude-skills`; the sync implementation and its job
  registry live in `rebalance-OS/utils/3-eyes`. Changing either from a lane scoped to
  `xyz-3-agents-swarm` would edit a repo this work was never authorized to touch. Recorded as an
  operator decision rather than silently narrowed.

## The correction, recorded rather than quietly replaced

This issue was **first filed with the wrong root cause** — "a full `validate.sh` run resurrects
deleted tracked files" — on the strength of two green gate runs that both ended with the file
back. The correlation was real and the conclusion was wrong: a 16-minute gate simply spans several
120-second ticks, while a 5-second spot-check does not.

Two further hypotheses were tested and disproved before the right one: the canary fixtures (deleted,
ran all three individually, file stayed gone) and `test/agy-turn.sh` (named by an instrumented run
as the suite in flight at detection — coincidence; its only destructive git calls are `git -C "$A"`,
scoped to its own temp clone). The disproved leads are listed on the issue so nobody re-runs them.

Recorded here because the failure mode is instructive: three consecutive plausible causes, each
consistent with the observation, none of them correct, and the thing that finally discriminated was
a file timestamp rather than any amount of further reasoning about the gate.
