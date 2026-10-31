---
title: Fold ceremony-audit into sanity-check
status: in-progress
owner: Claude
goal: One "is this needed?" skill instead of two; a rule that stops new-skill sprawl
created: 2026-10-31
updated: 2026-10-31
issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1299
---

# GH-1299 Fold ceremony-audit into sanity-check

## Status

| What was just completed | What's next |
|---|---|
| Folded into sanity-check Plan mode (tested wording); README rule; fold runs f1–f2 recorded; docs gate green | Final Codex QA, then ready PR |

## Why

`ceremony-audit` (#1286, PR #1289) asks `sanity-check`'s question of every step in a plan. Operator
decision 2026-10-31: fold it into `sanity-check` as a Plan mode and add a new-skill admission rule.
