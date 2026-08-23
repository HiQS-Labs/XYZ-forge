# utils/timeline — RELEASES ledger → timeline viewer (GH-103 spike)

Read-only projection of `releases.db` onto the timeline-ui rail (release nodes on a
horizontal trunk, manifest cards in lanes). See
`PROJECT/1-INBOX/GH-103-TIMELINE-LEDGER-SPIKE.md`; overlaps queued #75
(`releases dashboard` verb).

## Usage

From the repo root:

```bash
python3 utils/timeline/export_timeline.py --preview     # bake ./RELEASES-PREVIEW.html (one file, opens from disk)
python3 utils/timeline/export_timeline.py --serve 8103  # live: http://127.0.0.1:8103/RELEASES.html
python3 utils/timeline/export_timeline.py               # full export → temp/timeline/
python3 utils/timeline/export_timeline.py --check-drift # exit 1 if RELEASES.md and the DB disagree
```

- `--preview [PATH]` — the on-demand snapshot: current DB state baked into one
  self-contained `RELEASES-PREVIEW.html` (default: repo root). Generated artifact —
  regenerate rather than edit.
- `--serve PORT` — live mode: `/data.json` re-queries the DB (read-only) on every
  request; no stale file in the path. The browser cannot read SQLite directly; this
  is the one-source equivalent.
- Full export writes `temp/timeline/`: `data.json` (the viewer's data contract),
  `index.html` (baked, opens from `file://`), and `RELEASES.html` (the fetch-mode
  template copy).
- `--db`, `--md`, `--template`, `--out` override the defaults.

## Navigation sidebar (GH-153 spike)

The template ships a left sidebar in both baked views: default ON, hamburger
(`#sidenav-toggle`) slides it out, the chevron (`#sn-min`) collapses it to an icon rail,
state persists via `localStorage('ledger-sidenav')`. The project switcher and the
"releases cycle" panel are filled from the payload's additive `projects`/`cycle` keys —
the cycle numbers come from `utils/py/releases_cycle.py`, the same module
`utils/hq/rollup.sh` embeds, so the dashboard and the Obsidian daily rollup cannot
disagree. Items with no destination yet are deliberate non-link placeholders (`.sn-ph`).

## Guarantees & limits

- Opens the DB with SQLite's read-only URI (`mode=ro`): no writer lock, no generation
  bump, no receipt — safe to run mid-merge.
- Cards lead with the release's own sentence (first sentence of
  `releases.description`); the exit criterion renders below as the machine contract.
- Card titles/doc links are enriched from the GH-69 `roadmap_items` shadow by issue
  number; unshadowed issues degrade to bare links.
- Drift banner: the exporter parses RELEASES.md `Release:` blocks (canonical during
  the GH-32 shadow phase) and shows a red banner when the two ledgers disagree —
  releases existing on one side only, or shipped-status flips (draft-vs-active is
  not drift; the md vocabulary has no `active`). Band-aware per the RELEASES.md
  contract: a DB release inside a block's `Iterations:` band is accounted for, not
  drift.
- Not rendered yet (no DB concept / out of spike scope): detour lane, ROADMAP row
  parity, per-card pri/sev metrics.

`RELEASES.html` is adapted from the `timeline-ui` repo's `ledger.html`
(© Neochrome, AGPL-3.0).
