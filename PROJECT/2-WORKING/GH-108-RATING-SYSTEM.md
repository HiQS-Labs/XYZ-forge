---
gh_issue: 108
source: https://github.com/HiQS-Suite/XYZ-forge/issues/108
title: "pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)"
status: Active (2-WORKING as of 2026-08-20)
created: 2026-08-20
updated: 2026-08-20
owner: noelsaw1
doc_type: plan
rating: "pri/sev/appeal/effort 70/40/55/60 · calc 225"  # dogfood: this doc scored under its own system
goal: >
  One scoring vocabulary for every task in the ledger, oriented so a single glance answers "what
  should go to the front of the line": four 1-100 axes, a combined 4-400 computed score with
  leaderboard resolution, and an operator override that can pin anything visible.
---

# GH-108: pri/sev/appeal/effort — Canonical Task Rating System (Plan)

> **Operator decisions in this doc are LOCKED (2026-08-20, two rounds).** Sections marked FROZEN
> restate them; everything else is implementation planning and may be revised by review.

## Problem

The repo has three half-systems for "how important is this":

1. **cx/risk/eff** (1–5-ish) — the authored triage in intake docs and a few ROADMAP lines. Parsed by
   `roadmap sync` into `roadmap_items.complexity/risk/effort`, populated on **1 of 27** rows.
2. **pri/sev/app** — the timeline viewer's inherited rendering (numbers, hot flags, weighted `calc`,
   `▸ ovr` override), fed by **nothing**: no DB columns, no authoring convention, no exporter mapping.
3. **Prose** — "operator call", "NEXT immediate item", bold markers. The only system actually used.

Result: the timeline can render a prioritization instrument, the DB can store one, and the operator
runs the queue from memory. The three parts have never been connected, and the two scoring
vocabularies measure different things (cost vs. value) without either being canonical.

## The decision — FROZEN (operator, 2026-08-20)

**Four axes, 1–100 each. Higher score = more likely to be prioritized and put to the front of the
line.** Every number in the system — each axis, the computed score, the override — reads the same
direction. There is no axis where a low number means "do it first."

| Axis | What it measures | 100 means | 1 means |
|---|---|---|---|
| **pri** (priority) | operator-judged queue position | top of the queue | ignorable |
| **sev** (severity) | pain if left undone | worst pain | cosmetic |
| **appeal** | attraction/energy to do it | most energizing | a slog |
| **effort** | cheapness (INVERTED from work-amount) | easiest | hardest |

- **risk is dropped.** Effort and severity absorb what it measured. No fifth axis.
- **Effort's inversion is deliberate**: scoring cheapness rather than cost keeps all four axes in one
  orientation, so they combine without sign-flipping and a 90/90/90/90 item reads as what it is — a
  screaming quick win.
- **`calc` (computed) = the equal-weighted SUM of the four axes. Range 4–400.** Sum, not average, by
  operator preference: the wider range gives tiebreaker resolution and makes a leaderboard readable.
  Equal weights are frozen "at this point"; re-weighting is a future amendment to THIS doc, not a
  config knob, an env var, or a per-repo setting.
- **`ovr` (operator override) — a manual score on the same 4–400 scale that replaces `calc` for
  ranking wherever both exist.** Its purpose is visibility: the operator can pin a task to the front
  of the line regardless of arithmetic. `ovr` never modifies the four axes; they keep their honest
  values underneath.
- **No GH label mirroring.** Scores live in the ledger only. Mirroring to labels is explicitly ON THE
  TABLE for the future and explicitly NOT built now.
- **Supersedes cx/risk/eff** as the authoring convention. Grandfathering below.

## Where scores live (authoring surfaces and storage)

One rule: **scores are authored where the task is authored, and stored where the task is stored.**

| Surface | Form | Consumed by |
|---|---|---|
| ROADMAP.md entry line | `rated 70/40/55/60` (+ optional ` ovr 350`) — see grammar below | `roadmap sync` parser |
| PROJECT doc frontmatter | `rating: "pri/sev/appeal/effort 70/40/55/60 · calc 225"` | humans; not machine-parsed in v1 |
| `releases.db` | five new nullable INTEGER columns on `roadmap_items`, physically named **`rating_pri` / `rating_sev` / `rating_appeal` / `rating_effort` / `rating_ovr`** — prefixed because the table already has a legacy `effort` column (cx/risk/eff's third field), which SQLite cannot duplicate and grandfathered data must not share. The exporter translates physical names to the frozen public axis names; the `rating_` prefix never leaks into JSON or the viewer | exporter, future `releases dashboard` |
| `data.json` / `--json` | `metrics: {pri, sev, appeal, effort, calc}` + `override` + `effectiveScore` per card | timeline viewer, /radar, /10days (#107) |

**The one canonical grammar (Codex r1 — the doc previously stated three forms):**
`rated N/N/N/N` — exactly four slash-separated integers 1–100, axis order fixed as
**pri/sev/appeal/effort**, optionally followed by ` ovr N` (integer 4–400). No labeled long form is
accepted; the axis names live in this doc, not in the entry line. Codex verified `rated` followed by
the four-number shape collides with nothing in today's ROADMAP.md or PROJECT/**.

`calc` is **never stored** — it is derived at read time (exporter/CLI) from the four axes. Storing a
derived value invites the drift class this repo already fights everywhere else.

## User-facing impact — what changes for the operator

1. **Timeline cards grow a score line.** Cards render `pri 70 · sev 40 · appeal 55 · effort 60 ·
   calc 225`, with `▸ ovr 350` when set. Unrated cards render exactly as today — no placeholder
   noise, no "0/400".
2. **The footer legend flips.** Today it reads the inherited "pri / sev / app ranked 1–100 (1 =
   strongest)". It becomes: `pri / sev / appeal / effort 1–100 (100 = strongest) · calc = sum /400 ·
   ovr = operator override, wins over calc`. The flip ships in the SAME commit as the first real
   metric emission — the legend and the data must never disagree in a committed artifact.
3. **A leaderboard exists.** First home: `export_timeline.py --json` (already queued in #107) emits
   cards with `calc`/`ovr`, so `sort_by(effective_score)` is a one-liner for any consumer; the #75
   `releases dashboard` verb inherits it as a sorted view later. No new page is built for v1.
4. **Hot-flag threshold.** One constant in the exporter: `sev >= 80` renders the severity red (the
   viewer's existing `hot` flag). One constant, not a threshold system.
5. **Authoring stays one line.** Rating a task = appending `rated 70/40/55/60` to its ROADMAP entry.
   Nothing else to update; sync carries it to the DB, the hook refreshes the preview.

## Touchpoints (implementation map)

| # | Component | Change | Size |
|---|---|---|---|
| 1 | `utils/py/releases_app.py` (roadmap sync) | parse `rated N/N/N/N` + `ovr N` from entry text; **migration 003** adding the 5 nullable `rating_*` columns to `roadmap_items` (prefixed — the bare `effort` name is taken by the legacy vocabulary) — wired into the migration chain the rebuild path executes (currently 001/002 only), with the hard-coded column lists in the canonical dump writer AND `load_dump()` extended to carry them. **Live-upgrade path (Codex r3):** the normal sync path never runs generic migrations — `cmd_roadmap_sync` checks only migration 002 and `_ensure_roadmap_schema()` can only install 002 — so the first rating-capable sync must detect version 3 as missing and run an idempotent 003 helper INSIDE `perform_write` (receipt-bearing), with the schema-missing/no-op rule updated to key on 003; pinned by the v2-fixture-upgraded-by-sync test. **Grammar refusal contract:** the presence of a `rated` (or `ovr`) token either parses as the one full grammar or refuses with a named rule — malformed shapes never silently read as unrated. Reject out-of-range values loudly at sync time | M+ |
| 2 | `utils/timeline/export_timeline.py` | select the rating columns into the roadmap index (today's query selects none); map → card `metrics` + `override`; derive `calc` and emit `effectiveScore` (= `ovr` if set, else `calc`) so consumers never reimplement the precedence rule; add stdout `--json`; sev hot flag | S |
| 3 | `utils/timeline/RELEASES.html` | more than legend text (Codex r1): the metric loops hard-code `pri/sev/app/calc` in BOTH the card renderer and the what's-next strip — rename legacy `app` → `appeal`, add `effort`, then flip the footer legend | S |
| 4 | `test/gh69-roadmap-shadow.sh` (owns `roadmap sync` parser behavior) | happy path, `ovr`, out-of-range rejection, absent-rating rows unchanged, both-vocabularies-on-one-entry refusal, the legacy→`rated` transition (legacy columns NULLed, ratings populated, next sync a no-op), **malformed-shape refusals** (three or five numbers, duplicate `rated`, duplicate or dangling `ovr` — each refuses with a named rule rather than silently parsing as unrated), a v2-schema fixture upgraded in place by the first rating-capable sync, and a dump→rebuild round trip preserving ratings; `test/gh32-releases-app.sh` keeps cross-ledger/migration-chain coverage only | S |
| 5 | Intake template / PDDA scaffold | replace cx/risk/eff with the rating line | XS |
| 6 | `PROJECT/1-INBOX`+ROADMAP authoring | backfill ACTIVE WINDOW ONLY (Daybreak + Cargo manifest and detour items, ~12 tasks) | S (operator judgment) |

Out of v1 scope, named so they stop resurfacing: GH label mirroring (future), re-weighting (future
amendment), historical backfill (never — closed items don't need scores), machine-parsing doc
frontmatter ratings, a dedicated leaderboard page (rides #75), and any write path from viewer to DB
(the page stays a pure consumer, per GH-103's founding rule).

## Grandfathering cx/risk/eff

- The `complexity/risk/effort` columns and their parser **stay** — 26 unpopulated rows and 1
  populated row (GH-5) cost nothing.
- An entry carrying BOTH vocabularies is a sync error (loud, not silent preference).
- The vocabularies never share storage: legacy values live in `complexity/risk/effort`, new ratings
  in the `rating_*` columns (Codex r2 — the bare `effort` name is already taken).
- **The row always mirrors the entry text — no row-level coexistence** (Codex r3; supersedes the
  earlier coexistence claim). The sync's replacement-field model stands: converting an entry from
  `cx/risk/eff` to `rated` populates the `rating_*` columns and clears the legacy columns to NULL in
  the same sync — the entry's lossless `raw_text` is the historical record, the row is a mirror, and
  a mirror that disagrees with its source would re-update on every sync forever. "Grandfathered"
  means: entries still WRITTEN in cx/risk/eff keep their values; it never means one row carries both.
  Pinned by three tests: legacy → `rated` transition (legacy columns NULLed, ratings populated),
  a subsequent sync is a no-op, and the forbidden both-on-one-entry form refuses.
- Intake docs switch to the rating line on their next edit; no sweep.
- The columns are removed only when the last cx/risk/eff row is gone — tracked as a checklist tail on
  #108, not a phase.

## Sequencing

1. **Phase A (one PR): parser + columns + tests** (touchpoints 1, 4). Ships dark — no consumer reads
   the columns yet, so the blast radius is the sync path, which the gh32 suite pins.
2. **Phase B (one PR): exporter + viewer** (touchpoints 2, 3). Named deliverables: rating-column
   selection, `effectiveScore`, the stdout `--json` flag, the viewer's `app`→`appeal` rename +
   `effort` in both metric loops, and the legend flip — legend and first metric emission in the SAME
   commit. Preview regenerates via the GH-106 hook on the next CLI write.
3. **Phase C (no code): backfill + template** (touchpoints 5, 6). Operator scores ~12 active-window
   items; first leaderboard read comes free via `--json | sort`.

Each phase is independently shippable; a stall after any phase leaves the repo better than before it.

## Exit criterion

`ROADMAP.md` carries `rated` lines on the active-window items; `roadmap sync` lands them in
`releases.db` (generation bump; gh69 + gh32 suites green, including the dump→rebuild round trip
preserving ratings); `export_timeline.py --json` (the Phase-B flag) emits `effectiveScore` for those
cards; the served and baked pages render score lines — `appeal` and `effort` included — with the
flipped legend; and the pinned leaderboard command prints a defensible top five with no ties (the
resolution argument, demonstrated). The command is part of the contract, not prose (Codex r3 — bare
`sort` cannot order nested JSON):

```
python3 utils/timeline/export_timeline.py --json \
  | jq -r '.releases[] | .detours[]?, .roadmap[]? | select(.metrics.effectiveScore?) 
           | [.metrics.effectiveScore, .id, .title] | @tsv' \
  | sort -rn | head -5
```

(`--json` emits the same single-object shape as `data.json`; `effectiveScore` rides inside each
card's `metrics`. The exact jq path is Phase B's to finalize against the emitted shape — but Phase B
must land THIS command working, and the Phase-C exit test runs it verbatim.)

## Review verdicts (Codex relay r1, 2026-08-20 — all three open items resolved)

- **Entry-line token:** `rated` + the four-number shape collides with nothing in today's ROADMAP.md
  or PROJECT/**; canonical grammar fixed to the single bare-number form above.
- **Migration mechanics:** "no changes beyond the schema_migrations row" was FALSE — the rebuild
  path executes a hard-coded migration list and both dump directions carry hard-coded column lists;
  all three must learn migration 003 (folded into touchpoint 1, pinned by the round-trip test). The
  shell merge resolver itself needs no logic change.
- **`ovr` placement:** per-task on `roadmap_items` confirmed — the exporter enriches manifest cards
  by GH number, so one rating correctly follows a task everywhere; a per-release rating would be a
  new operator decision, not a v1 shape.
