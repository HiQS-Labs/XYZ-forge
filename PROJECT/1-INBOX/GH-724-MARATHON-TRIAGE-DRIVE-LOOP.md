---
gh_issue: 724
source: https://github.com/HiQS-Labs/XYZ-forge/issues/724
title: "marathon-triage skill does not drive end to end — drive-loop shape, guard-aware Step 0, capture recipe, refresh deployed copy"
status: Proposed (1-INBOX — not yet active)
created: 2026-09-20
owner: noel
doc_type: bugfix
complexity: 2
risk: 1
effort: 4
phases: 1
ratings_provisional: true
non_goals:
  - PRS-rating pass, PRS-based planner ranking, marathon-drive --dry-run, new test (#443)
  - hq park --gh-issue capture verb (follow-up)
  - Any runtime code change
related:
  - #443 (adjacent code work)
  - #418 (planner reads releases.db already — verify and close)
  - #672 (deployed-skills SOP)
  - skills/merge-cleanup/SKILL.md (loop shape to mirror)
goal: >
  An agent invoking /marathon-triage runs inventory, reconciliation, missing capture docs, the planner
  dry run and per-candidate preflight unattended, and reports classifications, verdicts and
  RECOMMEND/BECAUSE/UNLESS decisions without the operator walking it through each step.
---

## Key concepts

- Skill is a description, not a driven loop (no recite/drive-loop/done rule)
- Guardrails say confirm before running read-only tools (planner --dry-run, preflight --dry-run)
- relay-xyz guard blocks marathon-plan/swarm-preflight unless Step 0's locator ran first
- No capture-doc recipe; hq_render_capture + roadmap add are the existing writers
- Deployed Pulse copy stale (ROADMAP.md)

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# marathon-triage skill does not drive end to end — drive-loop shape, guard-aware Step 0, capture recipe, refresh deployed copy

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `HiQS-Labs/XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Problem

Invoking `/marathon-triage` does not produce an end-to-end triage. In practice the agent inventories issues, then stops and asks the operator before each of: writing missing `1-INBOX` capture docs, running `swarm-preflight.sh --dry-run`, and running the planner dry run. The operator has to walk it through every step, which defeats the skill.

Root causes, verified against `skills/marathon-triage/SKILL.md` @ `5e60cb01`:

1. **It is a description, not a driven procedure.** Unlike the newer skills (`merge-cleanup`, `start-task`, `express`, `workhorse`, `unstuck`) it has no "Recite this" block, no drive loop, no exit-code ladder, and no Done rule. Nothing tells the agent that a report without preflight verdicts is not done.
2. **Its guardrails tell the agent to stop.** "Default to read-only. Do not … author contracts … generate a plan file … without explicit operator confirmation" and "Running the planner writes a file, so request confirmation before generating" are read as "ask before Step 3/4". But `utils/py/marathon_plan.py --dry-run` writes nothing (`marathon_plan.py:49`), `--deep` already delegates to `swarm-preflight.sh --dry-run` per ready item (`:52`), and `swarm-preflight.sh --dry-run` is read-only. The read-only default should *include* those, and only reserve confirmation for promotion, closing, firing, branch cutting and writing the plan file.
3. **The relay-xyz guard hook blocks the tools the skill relies on.** `relay-automation/hooks/relay-xyz-guard.sh` derives Tier-A entrypoints from AGENTS.md; `marathon-plan` (12th frozen twin) and `swarm-preflight` are on it, Python twins included. A session that runs `$HARNESS/utils/marathon-plan.sh` or `swarm-preflight.sh` before either `Skill(relay-xyz)` or a Bash call containing `find-harness.sh` gets exit 2 — reproduced this session. Step 0's locator loop *does* count as proof-of-load, but the skill never says so, and agents that skip or reorder Step 0 hit the block and turn to the operator.
4. **Capture docs are out of scope today.** The skill classifies `NEEDS-CONTRACT`/no-doc issues but has no recipe to write the `PROJECT/1-INBOX/GH-<n>-*.md` capture + `releases roadmap add` row (the issue-first SOP). `hq park` only files *new* issues; `hq_render_capture` (`utils/hq/hq-lib.sh:416`) and `roadmap add` are the existing writers to reuse.
5. **The deployed copy is stale.** `~/git-pulse-sync/Deployed Skills/marathon-triage/SKILL.md` still cites `ROADMAP.md` (retired, GH-269) where canonical says the RELEASES DB — three hunks of drift; every app symlink serves the stale copy.

## Ask (doc-only; no runtime code)

Rewrite `skills/marathon-triage/SKILL.md` in the drive-loop shape:
- **Recite block** (verbatim, first response) naming the phases and the Done rule.
- **Step 0 is the guard's proof-of-load**: say so, make it the first Bash call, and name the exit-2 symptom when it is skipped.
- **Drive loop**: inventory → reconcile → **write missing capture docs + park rows** (existing writers) → `marathon_plan.py --dry-run --deep` (default, writes nothing) → per-candidate `swarm-preflight.sh --dry-run` verdicts → report with `RECOMMEND/BECAUSE/UNLESS`. Exit-code ladder for the planner (0/2/3/4/5/6) and preflight (0/2/3/4/5/6/7) with the action per code; do not stop at the first non-zero.
- **Done rule**: no report without (a) a classification for every open issue/doc, (b) a preflight verdict per candidate, (c) the planner dry-run output; still never promote, close, fire, cut a branch, or write the plan file without confirmation.
- Refresh the Pulse deployed copy via `skills-army-hq` so the app links serve the new text (GH-672 SOP).

## Acceptance

- [ ] `SKILL.md` has a `## Recite this` block, a `## Drive loop`, an exit ladder, and a `**Done rule**` (grep-checkable; same headings as `skills/merge-cleanup/SKILL.md`).
- [ ] Step 0 states that the locator call is the relay-xyz guard's proof-of-load and must precede any `marathon-plan`/`swarm-preflight` call.
- [ ] The read-only default explicitly *includes* `marathon_plan.py --dry-run --deep` and `swarm-preflight.sh --dry-run`; the confirmation list is limited to promote / close / fire / branch / write plan file.
- [ ] A capture-doc recipe exists that reuses `hq_render_capture` + `releases roadmap add` (no new writer, no hand-authored frontmatter).
- [ ] No `ROADMAP.md` reference remains in either the canonical or the deployed copy; `diff -q` of the two is clean after deployment.
- [ ] `test/xyz-harness-hooks.sh` (the skill's nudge hook) still passes.

## Non-goals

The PRS-rating pass, PRS-based planner ranking, `marathon-drive --dry-run` and the new test suite are **#443** and stay there. A `hq park --gh-issue N` capture verb for existing issues would be a small DRY follow-up, not part of this doc change. #418 (planner reads frozen ROADMAP.md) appears already addressed in code — `_marathon_plan.py` reads `releases.db` in releases-mode, and `MARATHON-PLAN-2026-09-18.md` says `source: releases.db (roadmap_items)` — worth closing separately after a check.

## Why

Invoking /marathon-triage stalls at every write-looking step; the operator hand-drives intake, preflight and the planner dry run.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
