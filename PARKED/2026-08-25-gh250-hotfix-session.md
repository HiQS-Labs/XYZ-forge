# Parked — 2026-08-25 GH-250 hotfix session

Context: GH-250 hotfix (export_timeline.py NULL-version crashes) shipped to development as
`033a48ee`; QA relay `relay-system/2026-08-25/gh250-qa-timeline-null-version.md` closed
STATUS: Approved (commandcode reviewer on deepseek/deepseek-v4-pro, --review-once exit 0).
Items below were found during the sweep or by the reviewer and deliberately NOT fixed —
all cosmetic/latent, none a crash.

- **Timeline column id can collide (reviewer Q1).**
  `"c-" + (version or codename or "untitled")...` collapses `version="1.0 0"` and
  codename `"1.0-0"` to the same `c-1-0-0`; two releases with neither field both get
  `c-untitled`. Reachable via the CLI (`--version` has no shape validation,
  releases_app.py:1662-1678; SQLite UNIQUE exempts NULL). Cosmetic — the id is a DOM
  anchor, never a join key.
  Remediation: append the GID when the slug is ambiguous, or validate shapes.
  issue: none · revisit_when: someone reports two columns scrolling to the same anchor

- **`md_drift()` keys `db` by version — N codename-only releases collapse to one None key**
  (export_timeline.py:413), undercounting `db_only`/`flipped` in the drift banner only.
  Remediation: key by GID/id instead of version.
  issue: none · revisit_when: drift-banner counts matter for anything beyond a warning

- **`strip_entries()` renders `"vNone"`** for a codename-only release in the
  justFinished/whatsNext strips (export_timeline.py:311/321). Cosmetic; the template's
  own `esc(null)`→`''` already keeps the column cards safe.
  Remediation: `f"v{version}" if version else name`.
  issue: none · revisit_when: a codename-only release ships (strip becomes visible)

- **`.gitignore` ignores `relay-system/` + `phases/` → marathon preflight will refuse
  (GH-514)**, per xyz-sync during the vendor fan-out on this date. Sync deliberately does
  not edit ignore rules (would publish withheld transcripts).
  Remediation: narrow the rules or permit transcripts — operator call.
  issue: none · revisit_when: next marathon run in this repo refuses at preflight
