---
gh_issue: 931
source: https://github.com/HiQS-Labs/XYZ-forge/issues/931
title: "Sanity-check cross-linkage and index registration"
status: "In progress"
created: 2026-10-02
updated: 2026-10-02
doc_type: feedback
owner: Codex
goal: "Register sanity-check in ARCHITECTURE.md and connect it reciprocally to debug-mantra, unstuck, daily-planner, and 10days."
---

# Sanity-check cross-linkage and index registration

## Status

| What was just completed | What's next |
|---|---|
| Fresh task clone and issue #931 registered. | Draft implementation plan and conduct Codex relay QA. |

Complete the strategic cross-linkages for `sanity-check`:
1. Register `sanity-check` in `ARCHITECTURE.md` (Skills Index, 1-hourly tier, count 14 -> 15).
2. Add diagnostic pre-flight triage pointer in `debug-mantra` (Mantra 1 & 2 exit ramp).
3. Connect `unstuck` Rung 3 ("Test the claimed blocker") directly to `sanity-check`.
4. Connect `daily-planner` blocker evaluation with `sanity-check`, and `sanity-check` Defer handoff with daily trajectory re-anchoring.
5. Cross-link `10days` issue triage with `sanity-check`.

Scope: Markdown files only. No runtime code, scripts, new tests, or installation.
Reversibility: Easy.

## Merge evidence

- PR #939 merged 2026-10-03 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
