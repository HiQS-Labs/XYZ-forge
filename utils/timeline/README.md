# utils/timeline — RELEASES ledger → timeline viewer (GH-103 spike)

Read-only projection of `releases.db` onto the timeline-ui rail (release nodes on a
horizontal trunk, manifest cards in lanes). See
`PROJECT/1-INBOX/GH-103-TIMELINE-LEDGER-SPIKE.md`; overlaps queued #75
(`releases dashboard` verb).

## Usage

From the repo root:

```bash
python3 utils/timeline/export_timeline.py            # reads ./releases.db → temp/timeline/
open temp/timeline/index.html                        # self-contained, works from file://
```

- `index.html` — static page with the data baked inline (the shareable artifact).
- `data.json` — the viewer's data contract, for the served mode:
  `python3 -m http.server -d temp/timeline 8080` → `http://localhost:8080/ledger.html`.
- `--db`, `--template`, `--out` override the defaults.

## Guarantees & limits

- Opens the DB with SQLite's read-only URI (`mode=ro`): no writer lock, no generation
  bump, no receipt — safe to run mid-merge.
- Card titles/doc links are enriched from the GH-69 `roadmap_items` shadow by issue
  number; unshadowed issues degrade to bare links.
- Drift banner: the exporter parses RELEASES.md `Release:` blocks (canonical during
  the GH-32 shadow phase) and shows a red banner when the two ledgers disagree —
  releases existing on one side only, or shipped-status flips (draft-vs-active is
  not drift; the md vocabulary has no `active`). `--md` overrides the file location.
- Not rendered yet (no DB concept / out of spike scope): detour lane, ROADMAP row
  parity, per-card pri/sev metrics.

`ledger.html` is adapted from the `timeline-ui` repo (© Neochrome, AGPL-3.0).
