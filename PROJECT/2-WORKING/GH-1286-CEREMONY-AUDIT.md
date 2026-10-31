---
title: Ceremony audit skill
status: in-progress
owner: Claude
goal: Cut plan steps that re-prove known results; keep the steps that change goal state
created: 2026-10-31
updated: 2026-10-31
issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1286
---

# GH-1286 Ceremony audit skill

## Status

| What was just completed | What's next |
|---|---|
| Parked, rated, promoted to In progress; plan written | Codex plan QA |

## Why

Plans keep growing machinery that re-tests what is already proven, while the open question
stays untested. Prompting case: #1279, the 8-hour planning soak for the GH-1248 Flywheel.
`/ponytail` and `/sanity-check` were both applied and still missed it until the operator asked.

## Key concepts

- **Progress:** a step that changes goal state.
- **Proof:** a step that answers the one open question.
- **Safety:** a control that protects data, security or reversibility; never cut.
- **Ceremony:** a step that re-proves a known result, or machinery no decision depends on.

## Step 1 — gap check (done before any skill text)

Base: `origin/development` at `b78df4b9`. Read at that revision: `skills/1-hourly/ponytail/SKILL.md`,
`skills/1-hourly/sanity-check/SKILL.md`, `skills/1-hourly/triangulate/SKILL.md`,
`skills/3-weekly/worth-it/SKILL.md`; and the installed `take-a-step-back`, `finish-line`,
`stay-focused` (giant-brains-claude-skills).

| Skill | Unit it judges | Why it does not cover the gap |
|---|---|---|
| ponytail | one mechanism being built | Shrinks *how* a step is built; never asks whether the step answers anything. Rung 1 ("does this need to exist") is about speculative code, not about re-proving a known result. |
| sanity-check | one blocker or failure | Fires at a failure; step 5 challenges a single guard's necessity. It does not walk a plan that has no failure in it. |
| triangulate | effort depth for one change | Balances over- vs under-building one change; no notion of "already proven" vs "open question". |
| worth-it | whole feature, or the next increment | Continuation step 4 ("buy information only when it could change the call") is the closest idea, but it decides Continue/Pivot/Park/Stop for the effort as a whole and allows at most one proof step; it does not label each planned step. |
| take-a-step-back | the decision frame | Re-checks framing and assumptions; no per-step evidence test. |
| finish-line | remaining work to a checkpoint | Cuts scope to ship the current chapter; does not test whether the remaining verification re-proves known results. |
| stay-focused | session anchor | Keeps replies on one task; no plan audit. |

**Gap (one sentence):** none of them walks a plan step by step and asks, for each step, whether it
changes goal state or answers the one still-open question, as opposed to re-proving what the
evidence already shows.

**Section instead of a skill?** Rejected. The question needs its own trigger (a plan review with no
failure in it) and its own unit (every step of a plan). Bolted onto `sanity-check` it would only fire
at a blocker, which is exactly how #1279 slipped past; bolted onto `ponytail` it would judge mechanism,
not evidence. `worth-it` continuation is the nearest neighbour, and the new skill links to it rather
than restating it.

## Bet check

- **Outcome sought:** agents cut verification machinery that re-proves known results, and spend the
  time on the one run that answers the open question.
- **Smallest viable bet:** one `skills/1-hourly/ceremony-audit/SKILL.md`, 120 lines or fewer, plus one
  `ARCHITECTURE.md` index row (tier count 15 → 16) and a `CHANGELOG.md` entry. Not built: scripts,
  scoring, tests (GH-831), hooks, install.sh, changes to the sibling skills.
- **Alternative rejected:** a section in `sanity-check` or `ponytail` (see above).
- **Rollback:** delete the folder and the index row; nothing else depends on it.

## Plan

1. Write `skills/1-hourly/ceremony-audit/SKILL.md` (frontmatter `name: ceremony-audit`, triggers:
   "no ceremony", "is this meaningful progress", "are we just building machinery", "audit this plan
   for ceremony", plus self-trigger when a plan's verification sections outgrow its delivery
   sections). Body: goal + open question with the evidence that the rest is proven; label each step
   progress / proof / safety / ceremony with the deletion test; prefer a real run over a proxy (name
   both); short output (cut list, kept list with reasons, smallest next goal-changing step with its
   gate, parked count); scheduling/stop calls are questions to the operator. Link `ponytail`,
   `sanity-check`, `worth-it`; do not restate them. Include a short counter-example (a lean plan cuts
   nothing).
2. Add the `ARCHITECTURE.md` row and fix the `1-hourly` count; add the `CHANGELOG.md` entry.
3. **Acceptance — worked example:** a fresh subagent that has only the draft `SKILL.md` and the live
   text of #1279 (`gh issue view 1279`, comments included) runs the audit. Pass = it cuts the timed
   window / planned crashes / slot arithmetic / staged handoff as re-proving the proven uptime (or not
   load-bearing), keeps plan-quality review and one real marathon lane as the proof/progress steps, and
   names the operator approval as the gate. It is not told the expected answer. Receipt:
   `TESTS-RESULTS/2026-10-31+GH-1286/worked-example-1279.md` with the prompt, issue revision and
   output.
4. **Red control:** same procedure on a genuinely lean merged plan (a recent one-file fix, chosen
   before the run and cited by PR number). Pass = cut list empty. Receipt in the same folder.
5. **Gates:** `utils/ci-route.sh` decides; expected docs route → `utils/pdda/pdda.sh run`. Because a
   file is added under a published skill folder, also run `test/gh620-skills-army-mini-sync.sh` and
   `test/gh589-*.sh` in a disposable full clone (`<folder>-gate`).
6. Final Codex relay QA, ready PR against `development`, no merge. Deployment through Skills Army HQ
   `intake.py` is a separate step after merge, not part of this PR.

## Ratings

`rated 60/35/50/80` (2026-10-31). Severity 35: no data loss or crash; the cost is hours of agent and
operator time spent on proxies (#1279 alone planned an 8-hour soak where about an hour answers the
question). Priority 60: it is shaping live Flywheel work now (#1248/#1279). Appeal 50: neutral, no
operator score given. Effort 80: one doc of about 120 lines, no code. Recurrence: one documented case
(#1279); the issue reports agents missed it under two existing skills. Trend unknown beyond that.
