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
| ROADMAP.md entry line | `rated pri/sev/appeal/effort 70/40/55/60` (+ optional `ovr 350`) | `roadmap sync` parser |
| PROJECT doc frontmatter | `rating: "pri/sev/appeal/effort 70/40/55/60 · calc 225"` | humans; not machine-parsed in v1 |
| `releases.db` | four new nullable INTEGER columns + `ovr` on `roadmap_items` | exporter, future `releases dashboard` |
| `data.json` / `--json` | `metrics: {pri, sev, appeal, effort, calc}` + `override` per card | timeline viewer, /radar, /10days (#107) |

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
| 1 | `utils/py/releases_app.py` (roadmap sync) | parse `rated P/S/A/E` + `ovr N` from entry text; 5 new nullable columns on `roadmap_items` (schema migration); reject out-of-range values loudly at sync time | M |
| 2 | `utils/timeline/export_timeline.py` | map DB columns → card `metrics` + `override`; derive `calc`; sev hot flag; legend flip | S |
| 3 | `utils/timeline/RELEASES.html` | footer legend text only (metric rendering already exists) | XS |
| 4 | `test/gh32-releases-app.sh` | parser assertions: happy path, `ovr`, out-of-range rejection, absent-rating rows unchanged | S |
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
- Intake docs switch to the rating line on their next edit; no sweep.
- The columns are removed only when the last cx/risk/eff row is gone — tracked as a checklist tail on
  #108, not a phase.

## Sequencing

1. **Phase A (one PR): parser + columns + tests** (touchpoints 1, 4). Ships dark — no consumer reads
   the columns yet, so the blast radius is the sync path, which the gh32 suite pins.
2. **Phase B (one PR): exporter + legend** (touchpoints 2, 3). The legend flips in the same commit
   that first emits metrics. Preview regenerates via the GH-106 hook on the next CLI write.
3. **Phase C (no code): backfill + template** (touchpoints 5, 6). Operator scores ~12 active-window
   items; first leaderboard read comes free via `--json | sort`.

Each phase is independently shippable; a stall after any phase leaves the repo better than before it.

## Exit criterion

`ROADMAP.md` carries `rated` lines on the active-window items; `roadmap sync` lands them in
`releases.db` (generation bump, gh32 suite green); `export_timeline.py --json` emits `calc` for those
cards; the served and baked pages render score lines with the flipped legend; and
`python3 -c "…sort by effective score…"` over `--json` output prints a defensible leaderboard with no
ties in the top five (the resolution argument, demonstrated).

## Open items for review (Codex relay)

- Is `rated P/S/A/E` the right entry-line token, or does it collide with prose in existing entries?
- Schema migration mechanics: `roadmap_items` gains columns — confirm the GID-keyed dump + merge
  resolver need no changes beyond the schema_migrations row.
- Does `ovr` belong on `roadmap_items` (per-task) or is a task ever rated differently per release?
  (Plan says per-task; challenge welcome.)
