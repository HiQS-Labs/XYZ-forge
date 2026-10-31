---
title: Ceremony audit skill
status: Complete
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
| Final Codex QA Approved (round 2, relay-system/2026-10-31/gh1286-final-qa-r2.md); worked example partial (4 of 6), counter-example passes | PR ready; awaiting merge. Lessons: NO_ENTRY (single-case evidence, confounded) |

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
| sanity-check | one blocker, or one piece of machinery | Fires at a failure *or* when asked whether a feature, CI test or other machinery is necessary (description; step 5 tests duplicate coverage). It judges one named mechanism at a time; it has no whole-plan, per-step pass and no progress/proof/safety/ceremony output. |
| triangulate | effort depth for one change | Balances over- vs under-building one change; no notion of "already proven" vs "open question". |
| worth-it | whole feature, or the next increment | Continuation step 4 ("buy information only when it could change the call") is the closest idea, but it decides Continue/Pivot/Park/Stop for the effort as a whole and allows at most one proof step; it does not label each planned step. |
| take-a-step-back | the decision frame | Re-checks framing and assumptions; no per-step evidence test. |
| finish-line | remaining work to a checkpoint | Cuts scope to ship the current chapter; does not test whether the remaining verification re-proves known results. |
| stay-focused | session anchor | Keeps replies on one task; no plan audit. |

**Gap (one sentence):** none of them walks a plan step by step and asks, for each step, whether it
changes goal state or answers the one still-open question, as opposed to re-proving what the
evidence already shows.

**Section instead of a skill?** Considered; a separate skill is kept, on a narrower rationale (plan QA
round 1). `sanity-check` already answers "is this one mechanism necessary?" when asked. What it lacks is
the whole-plan pass: walk every step, label each, and return one cut list, kept list and next step.
Adding that to `sanity-check` would extend both its activation (any plan review) and its unit (every
step), which is a second workflow inside a 236-line skill, not a short section. `ponytail` judges
mechanism, not evidence. `worth-it` continuation decides the effort as a whole. The new skill links to
all three for the single-mechanism, shrink and whole-effort calls instead of restating them. If Noel
prefers the `sanity-check` section, the same text moves there.

## Bet check

- **Outcome sought:** agents cut verification machinery that re-proves known results, and spend the
  time on the one run that answers the open question.
- **Smallest viable bet:** one `skills/1-hourly/ceremony-audit/SKILL.md`, 120 lines or fewer, plus one
  `ARCHITECTURE.md` index row (set the `1-hourly` count to the actual row total: 16 rows are listed
  today under a heading that says 15, so 17 after this) and a `CHANGELOG.md` entry. Not built: scripts,
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
2. Add the `ARCHITECTURE.md` row (portable relative link, per `skills/README.md`) and set the `1-hourly` count to the counted rows; add the `CHANGELOG.md` entry.
3. **Acceptance — worked example:** a fresh subagent that has only the draft `SKILL.md` and the live
   text of #1279 (`gh issue view 1279`, comments included) runs the audit. Pass = it cuts the timed
   window / planned crashes / slot arithmetic / staged handoff as re-proving the proven uptime (or not
   load-bearing), keeps plan-quality review and one real marathon lane as the proof/progress steps, and
   names the operator approval as the gate. It is not told the expected answer. Leakage check done
   before the run: #1279's body states the 12-hour run already completed (line 33 of the snapshot) and
   its one comment (a cross-link to #1280) does not state the diagnosis, so this is a blind run on the
   issue's own evidence. Receipt: `TESTS-RESULTS/2026-10-31+GH-1286/worked-example-1279.md` with the
   prompt, the issue snapshot (`updatedAt`), the draft skill's commit, the model and the raw output.
   **Rejection witness:** apply the same acceptance rule by hand to a deliberately wrong output (one that
   keeps every #1279 proxy) and record that it fails.
4. **Counter-example control (false positives):** same procedure on a genuinely lean merged plan,
   chosen before the run: PR #1186 (GH-1182), one CI step in `.github/workflows/ci.yml`, verified only by
   its own hosted run, with its extra red control left "on request". Pass = cut list empty. This only
   tests that the skill does not over-cut; the rejection witness in step 3 tests sensitivity. Receipt in
   the same folder. Both runs get entries in `TESTS-RESULTS/2026-10-31+GH-1286/provenance.jsonl`
   (`commit`, `pr`, `status` pass/fail), per `AGENTS.md` manual-evidence rules.
5. **Gates:** `utils/ci-route.sh` decides; expected docs route → `utils/pdda/pdda.sh run`. Also run
   `test/gh589-skill-viewer.sh`, which inventories every Forge skill and so does see the new folder.
   Dropped (plan QA round 1): `test/gh620-skills-army-mini-sync.sh`, `test/gh589-consult-no-tick.sh`,
   `test/gh589-xyz-mini-sync.sh`. They test publisher manifests and exported consult; `ceremony-audit`
   is in no publisher manifest, so they cannot read the new file (gh589-xyz-mini-sync asserts unlisted
   skills never ship). This departs from the issue's delivery note and is disclosed in the PR.
6. Final Codex relay QA, ready PR against `development`, no merge. Deployment through Skills Army HQ
   `intake.py` is a separate step after merge, not part of this PR.

## Ratings

`rated 60/35/50/80` (2026-10-31). Severity 35: no data loss or crash; the cost is hours of agent and
operator time spent on proxies (#1279 alone planned an 8-hour soak where about an hour answers the
question). Priority 60: it is shaping live Flywheel work now (#1248/#1279). Appeal 50: neutral, no
operator score given. Effort 80: one doc of about 120 lines, no code. Recurrence: one documented case
(#1279); the issue reports agents missed it under two existing skills. Trend unknown beyond that.
