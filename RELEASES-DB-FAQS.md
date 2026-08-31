# RELEASES Ledger

This repository includes the RELEASES add-on.

## Enable the RELEASES ledger
To enable the ledger, simply initialize it:
```bash
releases init
```
*(Optional) You can then author `RELEASES.md` as needed.*

Nothing runs until the ledger is invoked.

## Re-pointing a release's tracking issue (GH-222)

When a tracking umbrella issue is superseded (e.g. closed and replaced by a re-scoped one),
re-point the release with `releases update --gid <rel> --tracking-issue <N|URL>` — a bare
number expands against the org/repo slug or the github origin remote, the URL is stored
canonically like the `add` path, and the old issue ref row keeps its identity.

## Roadmap Rating Vocabulary & Grammar (GH-108)

The canonical roadmap rating system scores candidates across four fixed axes:

- **Grammar**: `rated <pri>/<sev>/<appeal>/<effort>` with an optional ` ovr <score>`.
  - Example: `rated 85/70/90/60` or `rated 85/70/90/60 ovr 320`
- **Axes (each integer 1–100, higher is always better)**:
  - `pri` (**Priority**): urgency and strategic scheduling priority.
  - `sev` (**Severity**): pain / consequence if left unaddressed.
  - `appeal` (**Appeal**): stakeholder / developer desirability.
  - `effort` (**Effort / Cheapness**): scores **cheapness / ease of delivery** (higher = cheaper/easier; 100 = 15-minute quick win, 1 = multi-week architectural rewrite).
- **Override (`ovr`, optional integer 4–400)**:
  - Overrides the computed rank sum (`pri + sev + appeal + effort`) for sorting while preserving the underlying four axis scores.
- **Legacy Vocabulary**:
  - `cx/risk/eff` (`complexity/risk/effort`) is a legacy triple. The two vocabularies measure different things and cannot share a row or entry. Convert any legacy entry to `rated` syntax.

