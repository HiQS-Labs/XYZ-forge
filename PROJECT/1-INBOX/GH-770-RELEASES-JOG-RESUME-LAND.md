---
gh_issue: 770
source: https://github.com/HiQS-Labs/XYZ-forge/issues/770
title: "releases jog resume/land/reconcile/retry-gate/retry-build ignore --root"
status: Proposed (1-INBOX — not yet active)
created: 2026-09-23
owner: unassigned
doc_type: bugfix
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - TODO: what this explicitly is NOT (scope boundary).
related:
  - TODO: related files/docs, if any.
goal: >
  TODO: one-paragraph statement of what "done" looks like for this idea.
---

## Key concepts

- TODO: 2-4 bullets on what this idea concretely is and why it matters.

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# releases jog resume/land/reconcile/retry-gate/retry-build ignore --root

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `HiQS-Labs/XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Bug
`releases --root X jog resume|land|reconcile|retry-gate|retry-build N` ignores `--root` and acts on the repo in the current working directory. That can read or write the wrong ledger.

## Repro
Run any of those five subcommands with `--root` pointing at a repo other than cwd. The action lands on the cwd repo. The audit confirmed this on Python 3.9, 3.11 and 3.13.

## Source
Found in the #768 audit: `PROJECT/1-INBOX/GH-768-RELEASES-APP-AUDIT.md`.

## Acceptance
- All five subcommands honor `--root`.
- A regression test runs each one from an unrelated cwd.


🤖 Generated with [Claude Code](https://claude.com/claude-code)

## Why

TODO: why this matters now -- what prompted it, what breaks or slows without it.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
