---
title: "GH-443: marathon-triage — verify PRS ratings, then compute, preflight, and dry-run the marathon before it fires"
status: Queued
created: 2026-09-05
updated: 2026-09-05
owner: orchestrator (Claude Code)
gh_issue: 443
source: https://github.com/HiQS-Labs/XYZ-forge/issues/443
doc_type: plan
effort: 2
complexity: 2
risk: 1
rating: "pri/sev/appeal/effort 60/40/50/55 · calc 205"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/299
goal: >
  Before any marathon is fired, four deterministic passes run in order — PRS rating verification
  against the RELEASES DB, planner compute on the verified rank, per-candidate swarm preflight,
  and a no-dispatch marathon-drive dry run — each with an exit code and a written artifact.
---

# GH-443: marathon-triage rating → compute → preflight → dry-run ladder

## Why

`/marathon-triage` preflights candidates and the planner has `--dry-run|--check|--deep`, but nothing
verifies the PRS four-axis rating (`pri/sev/appeal/effort`, `rated N/N/N/N [ovr N]`) the plan ranks on:
`_marathon_plan.py` reads only the PDDA frontmatter trio (1–5) and reports `rated` on that. `/start-task`
now rates every issue on the four axes, so ledger and plan can silently disagree. Nothing dry-runs the
driver either, although `marathon-drive.sh --dry-run` already exists (GH-238).

## Key Concepts

- Rating pass verdicts: `UNRATED` · `STALE` (rating older than last issue update) · `DISAGREES` (PDDA trio vs PRS band) — proposals written only via `roadmap rate` after confirmation; operator `ovr` never re-scored.
- Compute on the verified PRS rank (four-axis sum or `ovr`); PDDA `risk <= 2` stays the gate.
- Preflight unchanged (`swarm-preflight.sh --gh-issue <n> --dry-run`).
- Dry run = existing `marathon-drive.sh --dry-run` wired as pass 4; must not write a plan file (the GH-299 soak found `marathon_plan.py` writes when flags are stripped).
- `READY` requires all four passes green; `test/gh443-marathon-rating-pass.sh` pins them with +/- controls.

## Plan

1. Rating pass module (read `roadmap list --json`, compute verdicts, propose ratings per the `/start-task` policy).
2. Planner reads PRS rank; keep PDDA gate.
3. Skill text: four ordered passes + report lines; jog first-run shares the rating pass.
4. Suite + registry.
