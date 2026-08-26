---
issue: 243
source: https://github.com/HiQS-Labs/XYZ-forge/issues/243
title: "GH-169 items 3-4: repoint ROUTER.md/AGENTS.md off ROADMAP.md text + dashboard-staleness push guard"
created: 2026-08-25
type: feedback
status: 1-INBOX
complexity: 2
risk: 2
effort: 2
phases: 1
---

# GH-243 · Repoint agent docs + dashboard-staleness push guard

## Why

The repo flipped to `ROADMAP_SOURCE=releases` (c97f6176), but ROUTER.md/AGENTS.md still direct
agents to read and park in `ROADMAP.md` text — instructions that now describe a frozen legacy
file. And nothing yet enforces that a ledger write regenerates `ROADMAP-DASHBOARD.md`, so the
human-readable view can silently go stale — the exact drift #169's item 3 predicted.

## Key Concepts

- Read surface: `ROADMAP-DASHBOARD.md` / `releases roadmap list`; write surface: `releases roadmap add` (hq park routes there automatically).
- `roadmap sync` is legacy-mode-only (GH-238 no-op here).
- Guard lives at the push gate (GH-549 single wired stub), as a standalone, hermetically testable script.

## Non-goals

- The other ~26 ROADMAP.md readers named in #169's blast-radius list.
- RELEASES-DB-FAQS.md rewrite.

## Related

- #169 (plan) · #238/#239/PR #240 (machinery) · c97f6176 (the flip)
