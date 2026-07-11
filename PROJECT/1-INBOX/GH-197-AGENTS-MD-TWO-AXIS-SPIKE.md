---
gh_issue: 197
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/197
title: "Spike: two-axis (disclosure/steering) diagnostic tag pass on AGENTS.md"
status: Phase 0 complete — verdict recorded, prediction falsified for this repo
created: 2026-07-10
updated: 2026-07-10
owner: noel
doc_type: research
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Not a commitment to rewrite AGENTS.md or build an agents-md-builder skill — this only runs the
    Phase 0 diagnostic proposed in the analysis doc below.
  - Not tagging every bullet in every repo doc — scope is AGENTS.md's numbered Operating Principles
    (the "eleven rules" the source doc's Phase 0 refers to), plus a lighter secondary check on
    ROUTER.md once the primary count suggested where to look.
related:
  - PROJECT/1-INBOX/AGENT-MD-PYDANTIC.md
  - AGENTS.md
  - ROUTER.md
goal: >
  Run PROJECT/1-INBOX/AGENT-MD-PYDANTIC.md's Phase 0 diagnostic: tag each AGENTS.md Operating
  Principle as disclosure, steering, or both (the pydantic.dev "what makes a good harness" frame),
  count the split, and record any steering rule that seems to be missing.
---

## Key concepts

- Source analysis: [AGENT-MD-PYDANTIC.md](AGENT-MD-PYDANTIC.md), reviewing pydantic.dev's "What
  makes a good agent harness" (David Sanchez, June 2026). Core frame: **disclosure** = get the
  model the right instructions/tools at the moment it needs them; **steering** = catch it fast when
  it drifts anyway.
- That doc's Phase 0 (line 28) predicted a **disclosure-heavy skew** in AGENTS.md's rules — "the gap
  the frame predicts" — and proposed tagging each rule to confirm it before any heavier
  agents-md-builder work gets scoped.
- This is a review/spike, not a build: read AGENTS.md as it exists today, classify, count, verdict.

# GH-197 · Two-axis diagnostic tag pass on AGENTS.md

## Status

| What was just completed | What's next |
|---|---|
| Phase 0 complete (2026-07-10): all 8 current AGENTS.md Operating Principles tagged disclosure/steering/both, split counted, verdict recorded. **The predicted disclosure-heavy skew did not hold** — see findings below. | No further work needed on this doc. If anyone later scopes the "agents-md-builder" project from `AGENT-MD-PYDANTIC.md` Phase 1, point it at this doc's verdict first: the two-axis split for *this* repo already exists as a **file-level** split (`ROUTER.md` = disclosure, `AGENTS.md` = steering), not a per-rule gap to fix inside one file. |

## Idea

Tag every AGENTS.md Operating Principle as **disclosure**, **steering**, or **both**, using the
pydantic.dev frame, then count the split and compare against the source doc's prediction.

## Why

`AGENT-MD-PYDANTIC.md` frames this as the one thing worth stealing from the article: naming the
two-axis split exposes gaps a philosophy-lineage organization (SOLID/Ponytail/Ousterhout) doesn't
surface on its own. Doing the diagnostic first (no code, ~1hr) is the gate before committing to the
heavier Phase 1–3 builder work in that doc.

## Phase 0 — Spike: tag and count

Purpose: confirm or refute the predicted disclosure-heavy skew before scoping any builder work.

### Checklist

- [x] Take the current AGENTS.md rule set and tag each entry.

  **Finding — count mismatch first:** the source doc's Phase 0 (line 30) says "take the existing v2
  eleven rules." AGENTS.md today (`AGENTS.md:19-59`) has **8** numbered Operating Principles, not
  11. No `AGENTS.md` history or sibling doc found with an 11-rule version (`git log -p -- AGENTS.md`
  and a repo grep for "eleven" turned up nothing else) — treating "eleven" as stale terminology from
  an earlier draft, not a file this spike failed to find. Tagged the 8 that exist:

  | # | Principle (`AGENTS.md:line`) | Tag | Why |
  |---|---|---|---|
  | 1 | Lead with the line that survives skimming (`:21`) | neither (output-format) | Governs how an answer is *shaped*, not what the agent perceives before acting or how drift is caught after. Closest fit is "speeds a *human* reader's own steering," not harness-native disclosure or steering — the one principle that sits outside the two-axis frame. |
  | 2 | Make the bet explicit before acting (`:25`) | both | Surfaces assumption/tradeoff/failure mode to the reader *before* commit (disclosure-shaped: right info, right moment) but its purpose is making a later "that assumption was wrong" call possible (steering: enables drift detection). |
  | 3 | Use one reversibility scale (`:30`) | steering | A stop/escalation gate — Costly needs a rollback path, One-way door needs explicit confirmation before proceeding. Pure drift-catch checkpoint, not an information-timing rule. |
  | 4 | Size the blast radius before changing shared surfaces (`:36`) | steering | Same shape as #3: a required pre-action self-check ("what ripples, what breaks, who notices") gating a class of risky changes. |
  | 5 | One plan, one ordered list (`:41`) | both | Presentation rule (disclosure: one legible list, not scattered prose) *and* "keep verification inline (`-> expect ...`)" is a per-step drift checkpoint (steering). |
  | 6 | Verified beats plausible (`:46`) | steering | The clearest steering rule in the set — explicitly a drift-detection contract: no success claim without proof, and skipped/failed verification must be stated plainly. |
  | 7 | Record only consequential bets (`:51`) | both | Disclosure in the temporal sense (persist the bet so a *future* agent gets the right context at the right time) and steering (a recorded bet with an expected signal/revisit trigger is exactly how a later drift gets caught). |
  | 8 | Stay quiet on trivial work (`:56`) | disclosure | A suppression rule — governs when *not* to surface ceremony. Still disclosure-shaped: calibrating what reaches the reader, just in the negative direction. |

- [x] Count the split.

  **Finding:** disclosure-leaning (disclosure-only + both) = **4** (#2, #5, #7, #8). Steering-leaning
  (steering-only + both) = **6** (#2, #3, #4, #5, #6, #7). Disclosure-only = 1 (#8). Steering-only =
  3 (#3, #4, #6). Both = 3 (#2, #5, #7). Neither = 1 (#1).

  **The predicted disclosure-heavy skew does not hold.** By either count, AGENTS.md's own Operating
  Principles skew **steering-heavy or balanced**, not disclosure-heavy.

- [x] Explain the mismatch rather than just reporting it.

  **Finding:** the skew is explained by AGENTS.md's own scope declaration, already on the page
  (`AGENTS.md:11-16`): *"This file is the behavioral playbook... decision quality, reversibility,
  blast radius, planning shape, and proof. Do not restate routing... those live in ROUTER.md."* This
  repo already **splits the two axes across two files by design**, not by accident:
  - [`ROUTER.md`](../../ROUTER.md) is near-purely **disclosure**: a numbered startup sequence (what
    to read, in what order, `ROUTER.md:19-25`) plus a 13-entry "Routing hints" table
    (`ROUTER.md:66-80`) that routes a task to the one canonical doc that owns it — functionally the
    same shape as the article's deferred-capability-loading pattern (route to the right doc/tool
    only when the task matches), just implemented as a doc index instead of a runtime tool-search.
  - `AGENTS.md`'s Operating Principles are near-purely **steering**: reversibility gates, blast-radius
    checks, verified-vs-plausible, bet-recording — every one of them fires *while or after* acting,
    not before the agent decides what to read.

  So the "gap the frame predicts" is real but at the **wrong grain**: there is no missing-steering
  gap inside AGENTS.md (it's already steering-dense), and there is no missing-disclosure gap either
  once ROUTER.md is counted — the repo already runs the pydantic two-axis split, just as a two-file
  architecture rather than a per-rule tag. The gap that *would* be worth finding is a steering rule
  missing repo-wide, not an AGENTS.md-specific one — see next.

- [x] Write down any steering rule you wish existed but don't have, per the source doc's seed-backlog
      ask (line 32).

  **Finding:** the closest candidate found is not really missing — `PROJECT/PDDA.md`'s "Discovery &
  spike phases" contract (`PROJECT/PDDA.md:160-189`) already is a steering rule ("a phase tagged as
  discovery/spike must write its findings back into the plan doc before its QA gate can pass," this
  doc's own Phase 0 checklist being a live instance of it). One real gap surfaced by doing this
  exercise: none of AGENTS.md's 8 principles or PDDA's checks assert a **"stop and ask when a
  request is ambiguous"** rule as a standing steering condition — that behavior currently lives only
  in the system-level Auto Mode instructions (outside `AGENTS.md`/`ROUTER.md`), not in either
  repo-owned file. Not actioned here (out of this spike's scope) — flagged for whoever next touches
  AGENTS.md's steering rules.

### QA checklist — Phase 0

- [x] AGENTS.md was read fresh (not from memory) and all 8 current principles were tagged, with a
      `file:line` pointer for each.
- [x] The count is stated as a verdict (skew held / did not hold), not left as a raw table.
- [x] The mismatch between the source doc's prediction and this finding is explained, not just
      reported — findings are written back into this doc per `PROJECT/PDDA.md`'s discovery/spike
      contract.
- [x] The one candidate missing-steering-rule finding is recorded, even though it wasn't actioned.
