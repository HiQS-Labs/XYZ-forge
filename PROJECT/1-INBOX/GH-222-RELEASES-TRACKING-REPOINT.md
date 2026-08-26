---
title: releases update cannot re-point a release's tracking issue
status: Proposed (1-INBOX — not yet active)
created: 2026-08-24
owner: noel
gh_issue: 222
source: https://github.com/HiQS-Labs/XYZ-forge/issues/222
doc_type: enhancement
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
reported_from: LTVera-Pandas
release: 0.7.3 Bulkhead (dialed in 2026-08-24, mfi-01M0V21JW1SCY4CQFE3WW4Z20C)
non_goals:
  - General manifest-item re-pointing (this is the release-level tracking_ref only)
  - Any hand-edit path around the writer contract
---

## Why

A release's tracking umbrella issue can be closed and superseded by a re-scoped one (observed
live in LTVera-Pandas: #225 → #236). `releases update` exposes no `--tracking-issue` flag and
`reconcile` only fills TMP-XXXXXX refs, so the ledger permanently points at a closed issue —
followable only via a redirect comment, and unfixable without a hand edit the writer contract
forbids. Either the CLI gains a sanctioned re-point, or immutability is documented as
intentional with a named workaround.

## Key Concepts

- Decision first: is tracking-issue immutability intentional? If yes → docs + workaround; if
  no → `releases update --tracking-issue <url>` as a validated write (new issue_ref row or
  reuse, receipt-chained like every other CLI write).
- Supersession should leave an audit trail: the old ref is history, not garbage — a receipt
  naming old → new, not an overwrite that loses provenance.
- Same field shape exists in the vendored fleet: whatever ships must ride `.xyz` vendoring
  (GH-105/GH-197 tiering) unchanged.

## Acceptance (provisional)

- [ ] Decision recorded (immutability intentional vs. mutable) in RELEASES-DB-FAQS.md.
- [ ] If mutable: `releases update --gid <g> --tracking-issue <url>` re-points with a receipt;
      `releases check` stays clean; generated views show the new tracker.
- [ ] If intentional: FAQ names the sanctioned workaround for a superseded tracker.
- [ ] Regression coverage in the releases suite either way.
