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
- **Locked-in trigger:** the agent turns the mode on itself, automatically, after its own first
  failed bug-fix attempt — not a flag a human or caller has to set in advance.
- Candidate integration points for the mode's content: a static reference file, injected into the
  next turn's prompt once the trigger fires, or a new `--debug-mantra` mode surfaced by
  `swarm-preflight`/`marathon-drive`.

> **Note for plan writers:** apply the `/ponytail` lens here — favor the laziest integration seam
> that actually works (a static reference file a turn is told to read beats a new relay-drive mode)
> over new harness machinery, and question whether a seam needs to exist at all before adding one.

# GH-162 · Add a "code debugging mantra" harness file/mode

## Status

| What was just completed | What's next |
|---|---|
| Captured as an issue (2026-07-07), directly motivated by the debug-mantra skill's success on GH-160 this session. Operator has locked in the trigger condition (auto-on after 1 failed self-attempted fix); no exploration of the implementation done yet. | Fire the explore-marathon lane: decide how the harness detects "1 failed bug-fix attempt" for a given turn type, decide the content-integration seam (static file, prompt injection, or a new mode), and sketch both for one concrete turn type (e.g. a builder turn whose `--pre-advance-cmd` gate fails). |

## Idea

Add a "code debugging mantra" harness file or mode that builds the debug-mantra discipline into
the harness itself, rather than it living only as an externally-invoked Claude Code skill
(`~/.claude/skills/debug-mantra`) — and have it turn itself on automatically, without a human or
caller flag, once the agent has already failed to fix the bug on its own once.

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

A first attempt failing is exactly the signal a human would use to decide "stop guessing, get
disciplined" — the same escalation point where the debug-mantra Claude Code skill earns its keep.
Requiring an explicit flag in advance would mean nobody sets it until after the second or third
failure, by which point the harness has already burned a round on unstructured guessing. Turning it
on automatically after the first failure removes that judgment call from the loop entirely.

## Phase 0 — Explore & scope

Purpose: this is a review/spike — the trigger condition (auto-on after 1 failed self-attempted fix)
is locked in; decide how to detect that condition and which content-integration seam to use.

### Checklist

- [ ] Define "1 failed bug-fix attempt" concretely per turn type: is it a `--pre-advance-cmd` gate
      failing after a builder turn's edit, a round-cap retry, a failed test the agent's own diff was
      supposed to fix, or something `relay-drive.sh`/`marathon-drive.sh` already tracks (e.g. round
      number, prior-round gate result)? Find the existing signal rather than inventing a new counter.
- [ ] Decide where the trigger check lives: inside the turn-taker shim (`codex-turn.sh`/
      `agy-turn.sh`) before dispatch, or in the driver (`relay-drive.sh`/`marathon-drive.sh`) when it
      detects the retry.
- [ ] Compare the three candidate content seams (static reference file a turn can be told to read;
      prompt injection triggered on the detected failure; a new `--debug-mantra` mode on
      `swarm-preflight`/`marathon-drive`) and note the cost/benefit of each, given the trigger already
      fires automatically.
- [ ] Check whether builder/reviewer turn prompts already carry any debugging guidance today (grep
      `relay-automation/` for existing prompt text) to avoid duplicating or conflicting instructions.
- [ ] Sketch one concrete worked example end to end: a turn whose gate fails once, the harness
      detects it, and what the mantra-equivalent guidance looks like injected into the *next* turn's
      context.
- [ ] Decide whether this needs to reference the ledger/breadcrumb step (step 4) at all for a
      single-turn, stateless builder — or whether that step only makes sense for a human/skill
      session with persistent context across a debug session.
- [ ] Propose the concrete change set as this doc's next phase — do not implement in this phase.
      Apply the `/ponytail` lens: prefer the seam that adds the least new harness surface (a
      reference file over a new mode/flag) unless the worked example proves the simpler seam
      doesn't actually work.

### QA checklist — Phase 0

- [ ] The proposal names the exact existing signal used to detect "1 failed attempt" — not a new,
      separately-tracked counter, unless nothing existing covers it.
- [ ] The proposal names one specific content-integration seam, not "somewhere in the harness."
- [ ] The worked example is concrete (a real turn type, a real gate) and shows the failure→trigger→
      next-turn sequence, not hypothetical in the abstract.
- [ ] The proposal addresses whether/how the breadcrumb-ledger step applies to a stateless turn.
