---
title: "GH-446: marathon_plan.py writes unprompted plan file to disk on default invocation without --dry-run"
status: Queued
created: 2026-09-05
updated: 2026-09-05
owner: orchestrator (Claude Code)
gh_issue: 446
source: https://github.com/HiQS-Labs/XYZ-forge/issues/446
doc_type: plan
effort: 1
complexity: 2
risk: 1
rating: "pri/sev/appeal/effort 65/60/75/80 · calc 280"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/299
goal: >
  Make --dry-run / read-only inspection the safe default for marathon_plan.py, requiring explicit
  write intent to mutate PROJECT/2-WORKING/MARATHON-PLAN-*.md on disk.
---

# GH-446: marathon_plan.py write guard

## Why

During the GH-299 Gen 4 ATE campaign and downstream `wave_reconcile`, invoking `marathon_plan.py` /
`marathon-plan.sh` without explicit arguments (or with stripped flags) defaults to generating and
writing a new plan markdown file (`PROJECT/2-WORKING/MARATHON-PLAN-YYYY-MM-DD.md`) directly into the
working directory.

This caused 57 sandbox-contamination events during the Gen 4 soak (which were caught and reset by the
Zero-State Oracle), and causes `wave_reconcile` runs to leave an untracked plan file in clean clones.

## Plan

1. Require an explicit `--write` / `--apply` or non-default flag to mutate `PROJECT/2-WORKING/`.
2. Make `--dry-run` or read-only/planning inspection the safe default when inspecting plans or validating state.
3. Guard CLI argument handling so invalid or empty invocations display `--help` or exit 2 rather than
   generating an untracked file on disk.
4. Add regression test pinning read-only default behavior.
