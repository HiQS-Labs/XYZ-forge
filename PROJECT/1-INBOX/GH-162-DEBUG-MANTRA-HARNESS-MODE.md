---
gh_issue: 162
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/162
title: "Add a 'code debugging mantra' harness file/mode that builds the mantra into the harness itself"
status: Queued (1-INBOX) — awaiting explore-marathon lane
created: 2026-07-07
updated: 2026-07-07
owner: noel
doc_type: feature
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not replacing the ~/.claude/skills/debug-mantra Claude Code skill — this is about builder/reviewer turns, a different surface
  - Not a general prompt-engineering rewrite of turn prompts beyond the debugging-discipline slice
related:
  - relay-automation/relay-turn-lib.sh
  - relay-automation/marathon-drive.sh
  - utils/swarm-preflight.sh
goal: >
  Decide how to bake the debug-mantra discipline (reproduce reliably -> know the fail path ->
  question the hypothesis -> treat every run as a breadcrumb) into the harness itself, so headless
  builder/reviewer turns hitting a failing gate or flaky test have the same structured discipline
  a Claude Code session gets from the externally-invoked skill.
roadmap_exempt: false
---

## Key concepts

- The debug-mantra skill's four-step discipline (reproduce → know the fail path → question the
  hypothesis → treat every run as a breadcrumb) is what found GH-160's root cause, after an earlier
  investigation stalled on an unverified assumption.
- Today it lives only as an externally-invoked Claude Code skill — headless builder/reviewer turns
  (codex, agy) get no equivalent discipline when they hit a failing gate or flaky test.
- Candidate integration points: a static reference file, prompt injection when a gate fails, or a
  new `--debug-mantra` mode for `swarm-preflight`/`marathon-drive`.
- Open question: which of those three (or a combination) is the right seam — undecided pending
  exploration.

# GH-162 · Add a "code debugging mantra" harness file/mode

## Status

| What was just completed | What's next |
|---|---|
| Captured as an issue (2026-07-07), directly motivated by the debug-mantra skill's success on GH-160 this session. No exploration done yet. | Fire the explore-marathon lane: decide the integration seam (static file, prompt injection, or a new mode) and sketch what it would look like for one concrete turn type (e.g. a builder turn whose `--pre-advance-cmd` gate fails). |

## Idea

Add a "code debugging mantra" harness file or mode that builds the debug-mantra discipline into
the harness itself, rather than it living only as an externally-invoked Claude Code skill
(`~/.claude/skills/debug-mantra`).

## Why

The debug-mantra skill's four-step discipline (reproduce reliably -> know the fail path -> question
the hypothesis -> treat every run as a breadcrumb) is what actually found GH-160's root cause this
session, after an earlier investigation stalled on an unverified assumption. Builder/reviewer turns
driven by this harness (codex, agy, etc.) hit debugging tasks constantly (failing gates, flaky
tests, containment escalations) but have no equivalent structured discipline available to them —
they're just prompted to "read the acceptance criteria and your diff." Baking an equivalent mode or
reference file into the harness (e.g. injected into a turn's prompt when a gate fails, or a
`--debug-mantra` mode for `swarm-preflight`/`marathon-drive`) could make headless debugging turns
more reliable and less prone to the same "confident but wrong" failure mode.

## Phase 0 — Explore & scope

Purpose: this is a review/spike — decide the integration seam before writing anything.

### Checklist

- [ ] Compare the three candidate seams (static reference file a turn can be told to read; prompt
      injection triggered specifically when `--pre-advance-cmd` or a gate fails; a new
      `--debug-mantra` mode on `swarm-preflight`/`marathon-drive`) and note the cost/benefit of each.
- [ ] Check whether builder/reviewer turn prompts already carry any debugging guidance today (grep
      `relay-automation/` for existing prompt text) to avoid duplicating or conflicting instructions.
- [ ] Sketch one concrete worked example: a turn whose gate fails, and what the mantra-equivalent
      guidance would look like injected into that turn's context.
- [ ] Decide whether this needs to reference the ledger/breadcrumb step (step 4) at all for a
      single-turn, stateless builder — or whether that step only makes sense for a human/skill
      session with persistent context across a debug session.
- [ ] Propose the concrete change set as this doc's next phase — do not implement in this phase.

### QA checklist — Phase 0

- [ ] The proposal names one specific integration seam, not "somewhere in the harness."
- [ ] The worked example is concrete (a real turn type, a real gate), not hypothetical in the abstract.
- [ ] The proposal addresses whether/how the breadcrumb-ledger step applies to a stateless turn.
