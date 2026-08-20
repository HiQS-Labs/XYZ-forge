---
issue: 103
title: "Technical spike: render RELEASES SQLite ledger through the timeline-ui viewer"
state: INBOX
created: 2026-08-20
---

# GH-103: Technical spike — RELEASES SQLite → timeline-ui viewer

## Context & Cross-References
- **Tracking Issue:** [#103](https://github.com/HiQS-Suite/XYZ-forge/issues/103)
- **Overlaps / informs:** [#75](https://github.com/HiQS-Suite/XYZ-forge/issues/75) — the queued `releases dashboard` verb wants exactly this (one read-only self-contained HTML from `releases.db`). This spike is #75's rendering prototype; if adopted, the exporter becomes that verb's body.
- **Template source:** `timeline-ui` repo (`ledger.html` + `data.json` contract; `ledger-static-preview.html` is the target look). © Neochrome, AGPL-3.0 — same family as this repo's license.

## Why
`RELEASES.md` / `releases.db` answer "what ships when" only through CLI reads. The timeline-ui rail (release nodes on a trunk, manifest cards in lanes) is a one-glance answer. The spike proves the DB can drive that viewer with zero schema changes and zero writes.

## What was built (spike deliverable)
- `utils/timeline/export_timeline.py` — read-only exporter (stdlib only, SQLite `mode=ro` URI). Queries releases + manifest_items + issue_refs + marathons + roadmap_items + settings + op_receipts; emits `data.json` (the viewer's documented contract) and bakes `index.html`, a self-contained static page that opens from `file://` like the preview.
- `utils/timeline/ledger.html` — adapted template: inline-JSON boot path (`<!--LEDGER_DATA-->` placeholder) with `fetch('./data.json')` fallback, null-guards for sections the DB can't populate yet (sync banner, row parity, strip halves), de-hardcoded footer.
- Output lands in `temp/timeline/` (gitignored).

## Key Concepts
1. **Projection, not sync** — the exporter is a pure read-model over the GH-32/GH-69 tables; no writer lock, no generation bump, no receipt. Safe mid-merge.
2. **The `data.json` contract is the seam** — viewer and exporter evolve independently; a future `releases dashboard` verb (#75) only has to emit the same JSON.
3. **Manifest cards enriched via the ROADMAP shadow** — issue titles/doc links come from `roadmap_items` by GH number; items without a shadow row degrade to bare issue links.

## Provisional triage
cx/risk/eff 1/1/1 — additive, read-only, no gate surface touched.

## Open questions for promotion (not spike scope)
- Fold into `releases_app.py` as `dashboard` verb (#75) vs. keep standalone script.
- Staleness banner + ROADMAP.md row-parity need the real sync comparison, not a crude re-parse.
- Detour lane (ad-hoc items) has no DB concept yet; marathon membership of manifest items is inferred (release-level `marathon_id` wraps all cards).
