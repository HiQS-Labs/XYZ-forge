---
gh_issue: 1468
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1468
title: "New weekly skill: baseline — turn a circular process or policy thread into graded evidence, one ask per item and a one-question-per-slide deck"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-11-14
doc_type: enhancement
effort: 2
complexity: 2
risk: 1
phases: 1
---

# Baseline skill

## Quad Concepts
- Circular threads about a process or policy → Read the thread, sort what was said from what happened, and write down the ask or the ruling it is waiting on.
- Evidence before asks → Check each cited claim with `recon` and grade it confirmed, partly, not-found or unverified; the room agrees on the facts before it discusses a change.
- One slide, one question → Build a local, self-contained HTML deck with two slides per item and a closing slide that compiles the answers as Markdown.
- Stays local and read-only → The deck quotes people, so it lives in the repo's ignored `temp/` or `tmp/` folder; the skill never writes to a tracker or chat.

## Scope and Plan
1. Add `skills/3-weekly/baseline/`: `SKILL.md`, `scripts/build_deck.py` (spec validator and builder), `assets/deck-template.html` and `assets/example-spec.json` (fictional).
2. Change the `honest` skill's bare "baseline" trigger to "repo baseline" so the two skills do not both fire.
3. Add the Skills Index row in `ARCHITECTURE.md`.
4. Verify with the PDDA docs gate and a recorded manual check of the builder, including its refusal cases.
5. Open the PR; after merge, deploy through Skills Army HQ.

## Mode before skill (GH-1299)
Checked `honest` (repo maturity), `sanity-check` (one blocker in the operator's own task), `whack-a-mole` and `radar` (defect clusters) and `idea` (the operator's own idea). None takes another person's thread as input or produces an artifact two parties work through together.

## Acceptance Criteria
- [x] `skills/3-weekly/baseline/` holds the skill text, the builder, the template and a fictional example spec.
- [x] The builder builds the example and exits 2 on two questions per slide, an unsupported change ask, an over-long field and a missing evidence reference.
- [x] Source text cannot inject markup or script into the deck.
- [x] The deck renders in light and dark; a non-ignored output path produces a warning.
- [x] `ARCHITECTURE.md` row added; `honest` no longer claims the bare trigger word.
- [x] PDDA docs gate passes.
- [ ] PR merged and the skill deployed through Skills Army HQ.

## Not verified
- The deck's answer buttons, saved notes and Markdown copy were not exercised in a live browser; rendering was checked from headless screenshots and a DOM dump.
- No independent review has run on this change.
