# Project Document Operating Contract

This file defines how agents should create, update, move, and review documents under `PROJECT/`.
The goal is simple: project plans, bug-fix notes, and research docs should be structured enough
that a human can skim them quickly and automation can lint them reliably.

## Folder lifecycle

- `PROJECT/1-INBOX`: intake, rough proposals, notes not yet being actively worked
- `PROJECT/2-WORKING`: active project docs only
- `PROJECT/3-COMPLETED`: finished docs with a completion outcome
- `PROJECT/4-MISC`: archived, stale, abandoned, or reference-only docs

Use the real folder names above. Do not refer to a non-existent `2-IN PROGRESS` folder.

## Core rules

1. New project docs start in `PROJECT/1-INBOX` unless the user explicitly says the work is active now.
2. A doc moves to `PROJECT/2-WORKING` when it becomes the active source of truth.
3. A doc moves to `PROJECT/3-COMPLETED` when its stated goal is done or intentionally closed.
4. A doc moves to `PROJECT/4-MISC` when it is stale, superseded, abandoned, or only useful as reference.
5. Do not duplicate the same plan across multiple files. Link to the canonical doc instead.
6. Do not put detailed plan execution inside `ROADMAP.md`. `ROADMAP.md` is an index and pointer doc.
7. After any meaningful work session, update the active doc's status table, checklists, and frontmatter if they changed.

## Required frontmatter

Every active project doc should begin with YAML frontmatter. Minimum required fields:

```yaml
---
title: Short descriptive title
status: Draft | Active | Blocked | Completed | Deferred
created: YYYY-MM-DD
updated: YYYY-MM-DD
owner: Name or agent
goal: >
  One short paragraph describing the outcome this doc is driving.
---
```

Recommended when relevant:

- `related:` for linked docs
- `reviewed:` for reviewer thread / approval state
- `branch:` when work is branch-specific
- `non_goals:` when scope control matters
- `gh_issue:` when a GitHub issue is the intake source for a bug fix or task

Use repo-relative paths in metadata and body content. Do not hardcode absolute machine paths.

## Required status block for working docs

Every doc in `PROJECT/2-WORKING` must contain this exact two-column table near the top:

```md
## Status

| What was just completed | What's next |
|---|---|
| ... | ... |
```

Rules:

- Use the exact column names above.
- Compatibility window: older status-table aliases are tolerated only through `2026-07-31`, and should be normalized when touched before then.
- The left column states the latest concrete completed step, with date or phase when helpful.
- The right column states the single next action or next phase.
- If the doc is done, the right column should say so explicitly rather than leaving the cell vague.

## Required structure for plan docs

If a doc is a phased project plan, it should usually contain:

1. `## Status`
2. `## Context` or `## Background`
3. `## Goal`
4. `## Scope` and, when needed, `## Non-goals`
5. Phase sections in execution order
6. A QA checklist for each phase
7. `## Deferred`, `## Risks`, or `## Open questions` when relevant

The rule is not "add boilerplate everywhere." The rule is "make progress, next step, and gate criteria obvious."

## Bug-fix doc contract

Bug-fix docs can use a lighter structure than full project plans, but they still need the same frontmatter
and the same `## Status` table while they live in `PROJECT/2-WORKING`.

Recommended lightweight structure:

1. `## Status`
2. `## Bug`
3. `## Source` (`gh_issue:` link/number is valid when the issue started the work)
4. `## Fix plan`
5. `## Verification`

GitHub issues are valid intake sources for bug reports, but once a bug fix becomes active work in this repo,
the local doc is the execution record. The issue should link in; it should not be the only place the next step lives.

## QA gate contract

If a plan has multiple phases, each phase should have a visible QA gate or acceptance checklist.
That gate should be observable, not aspirational. Good examples:

- command exits `0`
- test count stays green
- file exists
- reviewer approved thread linked
- metric was captured in a named artifact

Bad examples:

- "looks solid"
- "should be fine"
- "ready to move on"

## Naming and scope

- Prefer specific names tied to the project or decision, not generic names like `notes.md`.
- Keep one primary purpose per file.
- If a doc becomes a hub, link outward to deeper docs instead of absorbing all detail.
- If a doc is superseded, say by what and move it rather than silently leaving two competing versions.

## Automation-facing expectations

Agents should assume future automation will lint for these conditions:

- missing frontmatter
- missing `## Status` table in `2-WORKING`
- missing QA gates in phased plans
- absolute filesystem paths
- stale docs in `2-WORKING`
- `ROADMAP.md` containing plan detail instead of pointers

Write docs so those checks can be deterministic whenever possible.

`blank.md` placeholders are scaffolding only and are excluded from PDDA linting.

These checks run in one of three enforcement modes (`observe` → `light` → `full`, via `PDDA_MODE` or a
repo-root `.pdda-mode` file); see `PROJECT/PDDA.md` "Enforcement modes". A fresh install starts in
`observe` (reports only, never moves or blocks); a project graduates to `full` once on the rails.

## Roadmap rule

`ROADMAP.md` is the repo-level index of work in progress, completed, attempted, and deferred work.
It should point to project docs. It should not become the place where phase-by-phase execution detail lives,
except for a short exception note when a pointer would hide something operationally important.

This rule is enforced deterministically by `utils/pdda-check-roadmap.sh` (errors on task checklists and
`### Checklist` / `### QA checklist` headings, warns on sprawl) plus the `utils/pdda-doc-ready.sh` LLM
rubric for the fuzzier cases — and the roadmap carries a top banner restating the contract.
