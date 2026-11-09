---
title: "Correct compressor page-size measurement"
status: In progress
created: 2026-11-09
updated: 2026-11-09
gh_issue: 772
source: https://github.com/HiQS-Labs/XYZ-forge/issues/772
doc_type: bugfix
---

# GH-772 — Correct compressor page-size measurement

## Status

| What was just completed | What's next |
|---|---|
| Implemented the scoped correction; manual negative/positive controls and independent QA retained. | Finish current exact-head qualification and land PR1397; reconcile this document after merge. |

## Scope and acceptance

Use the page size reported by vm_stat itself; process SC_PAGE_SIZE can differ under translation. 1024 pages at4K/16K must report4/16MB; missing or zero header leaves measurement unknown. Linux behavior unchanged. Earlier sysconf implementation and its failure evidence are retained.

Evidence: `TESTS-RESULTS/2026-11-09+GH-772/`. Trial/accounting: #1386. No new suite, runner or configuration. Manual agent-assisted progression; automatic continuation unproven.
