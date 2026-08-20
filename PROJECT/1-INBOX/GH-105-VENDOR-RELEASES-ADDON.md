---
issue: 105
title: "Vendor the RELEASES DB system + HTML timeline generator into the .xyz payload as an optional add-on"
state: INBOX
created: 2026-08-20
---

# GH-105: Vendor the RELEASES DB + timeline generator into `.xyz/` (optional add-on)

## Context & Cross-References
- **Tracking Issue:** [#105](https://github.com/HiQS-Suite/XYZ-forge/issues/105)
- **Release:** 0.9.0 "Cargo" (target 2026-09-19, sequenced before Meter by operator decision 2026-08-20) — sole frozen manifest entry.
- **Builds on:** GH-32 (RELEASES app) · GH-69 (roadmap shadow) · GH-103 / PR #104 (timeline viewer) · GH-312 (vendor preserve list) · interacts with the #75 dashboard-verb fold-in decision.

## Why
A repo that adopts the vendored XYZ harness gets coordination but no release ledger. Shipping the RELEASES subsystem inside every `.xyz/` payload (operator decision: always present, not flag-gated) makes the ledger a zero-download, opt-in capability — "when you're ready," never wired by default, matching RELEASES.md's own OPTIONAL philosophy (GH-381).

## Scope
- `xyz-vendor.sh materialize_vendor()` ships: `utils/py/releases_app.py` (+ machinery), `utils/releases-merge-resolve.sh`, `RELEASES-DB-FAQS.md`, `utils/timeline/` (exporter + `RELEASES.html`).
- Target-repo state (`releases.db`/`releases.sql`/`RELEASES.md`) lives at the target root; any `.xyz/`-resident runtime state joins the GH-312 preserve list.
- A short documented "enable the ledger" recipe; `find-harness.sh`/skill docs gain a one-line pointer.

## Key Concepts
1. **Payload, not plumbing** — files always present, zero behavior until `releases init` is run by the user.
2. **State outlives updates** — `xyz-sync.sh update` must preserve the target's ledger (GH-312 rule).
3. **The exit criterion is the gate** — authored before any member work, per the Litmus/Nightwatch ordering (see the Cargo block in RELEASES.md).

## Provisional triage
cx/risk/eff 2/1/2 — additive to the vendor script; blast radius is the `.xyz/` payload size and the preserve list.
