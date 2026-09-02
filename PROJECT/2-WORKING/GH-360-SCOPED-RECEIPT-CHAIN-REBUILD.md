---
title: releases check receipt chain failure phrasing and scoped --rebuild
status: Active
created: 2026-08-31
updated: 2026-08-31
owner: Noel Saw
gh_issue: 360
source: https://github.com/HiQS-Labs/XYZ-forge/issues/360
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: false
reported_from: ltvera
non_goals:
  - Removing receipt chain hash integrity verification
  - Changing SQLite append-only trigger rules
related:
  - utils/py/releases_app.py
  - test/gh360-scoped-receipt-chain-rebuild.sh
goal: >
  Accurately diagnose receipt chain breaks as normal git branch switching / rebasing discontinuities
  and scope check --rebuild break tolerance so future breaks are not masked.
---

# GH-360: releases check receipt chain failure phrasing and scoped --rebuild

## Status

| What was just completed | What's next |
|---|---|
| Implemented de-dramatized diagnostics, canonical `reanchor:N` scoping in `_rebuild`, strict parsing in `_parse_reanchor_breaks`, legacy NULL compatibility in `cmd_check`, 27-assertion test suite `test/gh360-scoped-receipt-chain-rebuild.sh`, and 5-round QA relay approved by Codex. | Pre-push gate validation, push, PR creation. |

## Context
In `releases check`, `receipt-chain` verification catches hash breaks between consecutive receipts (`before != previous after`).
Previously, `releases check` reported any receipt chain break without a `merge-rebuild` receipt as a `"spliced or forged audit trail"`.
In git-tracked SQLite workflows, benign git operations (branch switching, rebasing, stash pop) between receipted CLI commands create receipt-chain discontinuities without indicating malicious ledger forgery.
Furthermore, `check --rebuild` previously permitted an unbounded `any(r["op"] == "merge-rebuild")` override, which permanently silenced all future receipt-chain breaks once a single `merge-rebuild` receipt existed in history.

## Goals
1. Accurately report receipt-chain breaks as likely git branch switching or rebasing discontinuities rather than declaring them forged audit trails.
2. Scope `--rebuild` so that each `merge-rebuild` receipt records the count/scope of breaks it re-anchored, ensuring subsequent breaks still fail `releases check`.
3. Add regression tests covering both the updated error phrasing, scoped rebuild invariant, and legacy compatibility.
