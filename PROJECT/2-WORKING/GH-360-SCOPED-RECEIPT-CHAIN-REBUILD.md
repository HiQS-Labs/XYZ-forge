# GH-360: releases check receipt chain failure phrasing and scoped --rebuild

## Context
In `releases check`, `receipt-chain` verification catches hash breaks between consecutive receipts (`before != previous after`).
Previously, `releases check` reported any receipt chain break without a `merge-rebuild` receipt as a `"spliced or forged audit trail"`.
In git-tracked SQLite workflows, benign git operations (branch switching, rebasing, stash pop) between receipted CLI commands create receipt-chain discontinuities without indicating malicious ledger forgery.
Furthermore, `check --rebuild` previously permitted an unbounded `any(r["op"] == "merge-rebuild")` override, which permanently silenced all future receipt-chain breaks once a single `merge-rebuild` receipt existed in history.

## Goals
1. Accurately report receipt-chain breaks as likely git branch switching or rebasing discontinuities rather than declaring them forged audit trails.
2. Scope `--rebuild` so that each `merge-rebuild` receipt records the count/scope of breaks it re-anchored, ensuring subsequent breaks still fail `releases check`.
3. Add regression tests covering both the updated error phrasing and the scoped rebuild invariant.
