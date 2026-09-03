---
title: Four documentation trues-ups — package.json vs §7, dead PROJECT/4-MISC refs, CODEX_FLAGS default and dead escalation rung, uncommitted ROUTER pointer
status: Proposed (1-INBOX — not yet active)
created: 2026-09-03
owner: noelsaw1
gh_issue: 416
source: https://github.com/HiQS-Labs/XYZ-forge/issues/416
doc_type: chore
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Removing acorn; it is real tooling. The fix is classifying it as devDependencies.
  - Renumbering any GH reference. Upstream numbers are mirrored, not rewritten.
related:
  - GH-406 (umbrella — external review by Russ K.)
  - GH-414 (the dead-reference class this batch's items 2 and 4 belong to)
goal: >
  Make four documents literally true of the tree: §7's no-dependencies claim, the README's
  PROJECT/4-MISC references, SKILL.md's CODEX_FLAGS default and its no-op escalation rung, and
  the ROUTER pointer that exists only in an uncommitted working tree.
---

# GH-416: documentation trues-ups

> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.

## Why batched

None has a sequencing constraint and each is a few lines. Every one is the umbrella's own class at
nit severity: a document stating something not literally true of the tree.

| # | Claim | Reality |
|---|---|---|
| 1 | §7: "Node standard library only — no deps, no lockfile" | `package.json:18-21` carries `acorn` + `acorn-walk` under `dependencies`, with a lockfile |
| 2 | README `:71`, `:572`, `:573` reference `PROJECT/4-MISC/…` and `RECAP.md` | none exist; already in the PDDA warning stream |
| 3 | `SKILL.md:515` default `-s workspace-write`; `:519-520` offers `-c approval_policy=never` as the escalation rung | the real default is `-s workspace-write -c approval_policy=never`, so the escalation advice is a **no-op**; the real next rung is `--dangerously-bypass-approvals-and-sandbox` |
| 4 | ROUTER pointer to `docs/ROADMAP-UPSTREAM-ARCHIVE.md` reported done | exists only as an uncommitted working-tree change; `git show HEAD:ROUTER.md` carries no pointer |

Item 3 has two halves and the second was missed on first read — the doc does not merely omit the
default, its remediation advice is dead. Item 4 is a correction to this umbrella's own earlier
claim of completion.

## Phase

Single phase, one PR. Move the parser deps to `devDependencies`; fix or remove the README
references; correct both `CODEX_FLAGS` lines; commit the ROUTER and archive edits.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "ROUTER.md", "pattern": "ROADMAP-UPSTREAM-ARCHIVE" } ],
  "artifacts":   [
    "package.json",
    "README.md",
    "ROUTER.md",
    "skills/relay-xyz/SKILL.md",
    "docs/ROADMAP-UPSTREAM-ARCHIVE.md"
  ],
  "remediation": { "source": "issue#416", "criteria": "no document claims a property the tree does not have: deps classified, dead README refs gone, CODEX_FLAGS default and escalation rung both correct, ROUTER pointer at HEAD" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
