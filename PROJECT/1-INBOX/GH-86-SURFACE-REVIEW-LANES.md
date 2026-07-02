---
gh_issue: 86
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/86
title: marathon-plan — surface PR-review lanes so they don't silently drop
status: Queued
created: 2026-07-02
updated: 2026-07-02
owner: noel
doc_type: enhancement
complexity: 2
risk: 1
effort: 2
roadmap_exempt: false
non_goals:
  - Level 1 (surface) is the core; auto-generating review lanes from open PRs (Level 3) is a stretch, not required
  - Not auto-firing reviews headless — surfacing/tracking is enough to stop the silent drop
related:
  - utils/marathon-plan.sh
  - PROJECT/2-WORKING/PR-REVIEW-QUEUE-2026-07-02.md
  - relay-automation/relay-drive.sh
---

# GH-86 — surface PR-review lanes in the marathon plan

## Problem

`marathon-plan.sh` generates only **build** lanes from the ROADMAP ledger. PR-**review** lanes live
only in a manual `PR-REVIEW-QUEUE-<date>.md` overlay that nothing surfaces — so two defined review
lanes (PR #79, #81) were silently never run (operator caught it 2026-07-02; recovered via relay-xyz).

## Fix direction (levels)

1. **Surface (core):** the plan detects `PROJECT/2-WORKING/PR-REVIEW-QUEUE-<today>.md` with open review
   lanes and prints a "Review lanes (manual overlay — run via relay-xyz)" section in its output.
2. **Track:** report per-lane status (run / not-run / verdict) by reading the overlay's Status table.
3. **Generate (stretch):** turn `gh pr list` output into review lanes with a contract.

Level 1 alone would have caught the loss.

## Definition of done

- An unrun PR-review lane is visible in the generated marathon plan, not only in a manual doc.
