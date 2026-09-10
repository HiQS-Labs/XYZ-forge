---
gh_issue: 556
source: https://github.com/HiQS-Labs/XYZ-forge/issues/556
title: "skills-army-hq: post-GH-536 hardening — source re-anchor, ignore defaults, mode-stable digests"
status: Proposed (1-INBOX — not yet active; implementation not started)
created: 2026-09-10
updated: 2026-09-10
owner: noelsaw1
doc_type: feedback
goal: >
  Carry the three GH-536-learned behavioral fixes as trackable work: a source re-anchor
  path for unchanged-byte updates, a shipped machine-state ignore list for git-backed
  collection roots, and a decision on mode-stable digests.
---

# GH-556 — post-relocation hardening

The issue body owns the full spec (three findings, each with observed evidence and a
red control). This capture exists so the ledger row links somewhere real; the issue
remains the canonical plan. Companion: rebalanceOS #206 (git-pulse writer-side docs).

## Quad Concepts

- Advisory provenance going stale after relocations → a sanctioned re-anchor path (record-on-update or `repoint-source`).
- Exclusions learned by leaking → ship the list; consider `init` emitting a starter `.gitignore` for git-backed roots.
- Mode-sensitive digests vs git's exec-bit-only modes → normalize or add a content-only mode, with a receipts migration note.
