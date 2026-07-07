---
gh_issue: 164
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/164
title: "Idea -> queue -> plan docs & GH issue -> queue -> marathon: quick automated intake pipeline"
status: Queued (1-INBOX) — awaiting explore-marathon lane
created: 2026-07-07
updated: 2026-07-07
owner: noel
doc_type: feature
complexity: 3
risk: 2
effort: 3
phases: 1
ratings_provisional: true
non_goals:
  - Not replacing HQ's existing park/queue/fire commands (GH-128/132) — this composes with them, not around them
  - Not auto-firing a marathon lane without a human review point somewhere in the loop
related:
  - ROADMAP.md
  - utils/hq/
  - utils/marathon-plan.sh
  - PROJECT/1-INBOX/GH-161-HARNESS-OBSERVABILITY.md
  - PROJECT/1-INBOX/GH-162-DEBUG-MANTRA-HARNESS-MODE.md
  - PROJECT/1-INBOX/GH-163-WP-SIBLING-AST-REVIEW.md
goal: >
  Design a faster, more automated on-ramp from a short idea prompt to a marathon-ready lane: draft
  the plan doc, file the GH issue, and add the ROADMAP queue entry, composing with HQ's existing
  park/queue/fire commands rather than duplicating them.
roadmap_exempt: false
---

## Key concepts

- Today's flow is mostly hand-authored: a `PROJECT/1-INBOX` doc → a matching GH issue → promotion
  to `2-WORKING` → only then eligible for `marathon-plan.sh`/preflight/`marathon-drive`.
- HQ (GH-128/132) already automates `park`/`queue`/`fire`; the idea → plan-doc → issue step itself
  is still fully manual.
- Goal: take a short idea prompt and auto-draft the plan doc + file the GH issue + add the ROADMAP
  queue entry, then queue it for a marathon.
- Open question: how much of the plan doc gets auto-drafted vs. human-reviewed before it's queued,
  and how this composes with HQ's existing commands rather than becoming a second, parallel path.

# GH-164 · Idea → queue → plan docs & GH issue → queue → marathon

## Status

| What was just completed | What's next |
|---|---|
| Captured as an issue (2026-07-07). This very lane (GH-161–164 explore-marathon) is itself a live example of the manual version of this flow — a useful reference case to design against. | Fire the explore-marathon lane: map the exact manual steps this session just took by hand (idea → issue → doc → ROADMAP queue line) and design the automated version against that concrete trace. |

## Idea

A "quick" and automated system for: initial idea -> queue -> build out plan docs & GH issue ->
queue -> marathon.

## Why

Today, going from a raw idea to a marathon-ready lane is mostly hand-authored: someone writes a
`PROJECT/1-INBOX` doc, files a matching GH issue, promotes the doc to `2-WORKING`, and only then
does it become eligible for `marathon-plan.sh`/preflight/`marathon-drive`. HQ already automates
parts of this (GH-128's `hq park`/`hq queue`/`hq fire`, GH-158's marathon-scan), but the idea ->
plan-doc -> issue step itself is still manual. A faster, more automated on-ramp — take a short idea
prompt, draft the plan doc + file the GH issue + add the ROADMAP queue entry, then queue it for a
marathon — could shorten the loop from "I have an idea" to "it's fireable" considerably.

## Phase 0 — Explore & scope

Purpose: this is a review/spike — use this session's own manual GH-161–164 intake as the concrete
trace to design against, rather than designing in the abstract.

### Checklist

- [ ] Write down the exact manual steps this session took for GH-161–164: raw idea → `gh issue
      create` → `PROJECT/1-INBOX/GH-<n>-*.md` doc → ROADMAP queue line → ROADMAP-DASHBOARD
      regeneration. Note which of those are mechanical (could be scripted) vs. judgment calls
      (need a human).
- [ ] Review HQ's existing `park`/`queue`/`fire` commands (`utils/hq/`) to find the seam where an
      automated draft step would plug in without duplicating what HQ already does.
- [ ] Decide how much of the plan doc gets auto-drafted (skeleton with Key Concepts + Phase 0 only,
      like this doc) vs. left for human review before promotion/queueing.
- [ ] Decide the human checkpoint: does the auto-drafted issue/doc get created directly, or staged
      for a one-line human approval before it's real?
- [ ] Propose the concrete tool/command shape (a new `hq` subcommand, a standalone script, or a
      Claude Code skill) as this doc's next phase — do not implement in this phase.

### QA checklist — Phase 0

- [ ] The design is grounded in this session's actual manual trace, not a hypothetical workflow.
- [ ] The proposal states explicitly where a human checkpoint remains, not full auto-fire.
- [ ] The proposal composes with HQ's park/queue/fire rather than introducing a second, competing path.
