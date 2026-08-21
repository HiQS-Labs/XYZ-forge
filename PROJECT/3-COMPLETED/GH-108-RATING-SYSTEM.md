---
gh_issue: 108
source: https://github.com/HiQS-Suite/XYZ-forge/issues/108
title: "pri/sev/appeal/effort — the canonical task rating system (calc sum + operator override)"
status: Complete (3-COMPLETED as of 2026-08-21)
created: 2026-08-20
updated: 2026-08-21
owner: noelsaw1
doc_type: plan
roadmap_exempt: true
rating: "pri/sev/appeal/effort 70/40/55/60 · calc 225"  # dogfood: this doc scored under its own system
goal: >
  One scoring vocabulary for every task in the ledger, oriented so a single glance answers "what
  should go to the front of the line": four 1-100 axes, a combined 4-400 computed score with
  leaderboard resolution, and an operator override that can pin anything visible.
---

# GH-108: pri/sev/appeal/effort — Canonical Task Rating System (Plan)

## Status

| What was just completed | What's next |
|---|---|
| **Plan Authored (2026-08-20):** Operator locked 4-axis 1-100 rating model. | Complete review and implementation steps. |

> **Operator decisions in this doc are LOCKED (2026-08-20, two rounds).** Sections marked FROZEN
> restate them; everything else is implementation planning and may be revised by review.

## Status

| What was just completed | What's next |
|---|---|
| **SHIPPED 2026-08-21 — merged to `development` via PR #116** (`c271be3`), issue #108 closed. All four phases built on `feat/gh111-phase-a-dialed-in`. A: migration 003 (five nullable `rating_*` columns, transaction-safe, registry-driven), the one canonical `rated N/N/N/N` + ` ovr N` grammar in `roadmap sync` with a named refusal for every malformed shape, and the dump grammar both directions. B: exporter emits `metrics` + `effectiveScore` under the public axis names, joins detour cards to the roadmap index, flags `sev >= 80` hot, and gained `--json`; the viewer renames `app` -> `appeal`, adds `effort` to both metric loops, and flips the footer legend in the same commit. C: the intake scaffold takes the rating line and the 15 active-window ROADMAP entries are rated. D: `utils/leaderboard.sh` -> `LEADERBOARD.md`, `--leaderboard` -> `LEADERBOARD.html` from the SAME template via a `view` field, cross-linked from `.top`, all three refreshed by the GH-106 hook. Final suite counts after the aider/qwen3.8-max QA round: gh32 140/0, gh69 53/0, gh103 38/0. | Nothing — this plan is closed. The backfilled scores remain a defensible FIRST PASS read off what the ledger already says (operator front-of-line calls, built-vs-unstarted, blast radius); revising one is a `rated` edit plus a sync, not a reopen. Deferred as named, and still deferred: GH label mirroring, re-weighting, and machine-parsed doc frontmatter. |

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
3. **A leaderboard exists, in three forms.** The command (pinned in the exit criterion) answers
   "what's highest-scored right now" from a terminal; `LEADERBOARD.md` is the committed, diffable
   ranking an agent or a GitHub reader can consume without a browser; `LEADERBOARD.html` is the
   rendered report, reachable from a "leaderboard →" link in the timeline page's title row and
   linking back. All three read the same `effectiveScore` from the same exporter — see "The
   leaderboard pipeline". The #75 `releases dashboard` verb inherits this rather than rebuilding it.
4. **Hot-flag threshold.** One constant in the exporter: `sev >= 80` renders the severity red (the
   viewer's existing `hot` flag). One constant, not a threshold system.
5. **Authoring stays one line.** Rating a task = appending `rated 70/40/55/60` to its ROADMAP entry.
   Nothing else to update; sync carries it to the DB, the hook refreshes the preview.

## Touchpoints (implementation map)

| # | Component | Change | Size |
|---|---|---|---|
| 1 | `utils/py/releases_app.py` (roadmap sync) | parse `rated N/N/N/N` + `ovr N` from entry text; **migration 003** adding the 5 nullable `rating_*` columns to `roadmap_items` (prefixed — the bare `effort` name is taken by the legacy vocabulary) — wired into the migration chain the rebuild path executes (currently 001/002 only), with the hard-coded column lists in the canonical dump writer AND `load_dump()` extended to carry them. **Live-upgrade path — SUPERSEDED 2026-08-20 by GH-111.** This plan previously specified a per-feature helper: the first rating-capable sync detects version 3 missing and runs an idempotent 003 helper inside `perform_write()`. **That is now withdrawn.** GH-111 adds a general `releases migrate` verb with its own `perform_migration()` protocol and an ordered migration registry, and establishes the rule that **feature commands do not self-migrate**. Two plans specifying different upgrade mechanisms is how the wrong one gets built (Codex flagged the contradiction on the GH-111 relay). This plan therefore: registers 003 in the shared registry, relies on `releases migrate` to apply it, and keeps `cmd_roadmap_sync` free of schema-installation logic — it may *refuse* clearly when the rating columns are absent, but it never installs them. **Migration 003 must be transaction-safe: no `executescript()` or any implicit-commit API**, because a v2 database runs 003 and GH-111's 004 inside ONE `BEGIN IMMEDIATE` — and `_ensure_roadmap_schema()`, 003's natural implementation, calls `executescript()` today. A mid-flight commit there would leave 003 durable after a 004 failure while the journal and receipt describe an interrupted all-or-nothing migration. The v2-fixture test moves to exercising `releases migrate`, and GH-111's registry work is a prerequisite for this touchpoint. **Grammar refusal contract:** the presence of a `rated` (or `ovr`) token either parses as the one full grammar or refuses with a named rule — malformed shapes never silently read as unrated. Reject out-of-range values loudly at sync time | M+ |
| 2 | `utils/timeline/export_timeline.py` | select the rating columns into the roadmap index (today's query selects none); map → card `metrics` + `override`; derive `calc` and emit `effectiveScore` (= `ovr` if set, else `calc`) so consumers never reimplement the precedence rule; **join detour cards to the GH-keyed roadmap index too (Codex r4)** — `roadmap_detours()` reparses ROADMAP.md text without consulting the index, so an in-progress rated task not on any manifest would otherwise render scoreless; add stdout `--json`; sev hot flag. Phase-B test pins a rated MANIFEST card and a rated DETOUR card | S+ |
| 3 | `utils/timeline/RELEASES.html` | more than legend text (Codex r1): the metric loops hard-code `pri/sev/app/calc` in BOTH the card renderer and the what's-next strip — rename legacy `app` → `appeal`, add `effort`, then flip the footer legend | S |
| 4 | `test/gh69-roadmap-shadow.sh` (owns `roadmap sync` parser behavior) | happy path, `ovr`, out-of-range rejection, absent-rating rows unchanged, both-vocabularies-on-one-entry refusal, the legacy→`rated` transition (legacy columns NULLed, ratings populated, next sync a no-op), **malformed-shape refusals** (three or five numbers, duplicate `rated`, duplicate or dangling `ovr` — each refuses with a named rule rather than silently parsing as unrated), a v2-schema fixture upgraded in place by the first rating-capable sync, and a dump→rebuild round trip preserving ratings; `test/gh32-releases-app.sh` keeps cross-ledger/migration-chain coverage only | S |
| 5 | Intake template / PDDA scaffold | replace cx/risk/eff with the rating line | XS |
| 6 | `PROJECT/1-INBOX`+ROADMAP authoring | backfill ACTIVE WINDOW ONLY (Daybreak + Cargo manifest and detour items, ~12 tasks) | S (operator judgment) |
| 7 | `utils/leaderboard.sh` + `LEADERBOARD.md` + `LEADERBOARD.html` | the ranked-report pipeline — see "The leaderboard pipeline" below | M |

Out of v1 scope, named so they stop resurfacing: GH label mirroring (future), re-weighting (future
amendment), historical backfill (never — closed items don't need scores), machine-parsing doc
frontmatter ratings, and any write path from viewer to DB (the page stays a pure consumer, per
GH-103's founding rule). *(The "leaderboard rides #75" deferral was reversed by operator instruction
2026-08-20 — it is now touchpoint 7 and Phase D below.)*

## The leaderboard pipeline (touchpoint 7 — operator-specified 2026-08-20)

```
releases.db ──▶ export_timeline.py --json ──▶ utils/leaderboard.sh ──▶ LEADERBOARD.md
                        (the ONLY scorer)               │
                                                        ▼
                        export_timeline.py --leaderboard ──▶ LEADERBOARD.html
```

Three rules make this cheap instead of a second system to maintain:

**1. One scorer, never two.** `leaderboard.sh` does NOT compute `calc` or apply the ovr-over-calc
rule — it consumes `export_timeline.py --json` (Phase B) and sorts on the `effectiveScore` the
exporter already derives. A shell script re-deriving scores is the exact drift class the "`calc` is
never stored" rule exists to prevent, one layer up. The script's whole job is sort, rank, format.

**2. `LEADERBOARD.md` is the git-native artifact, and it is generated — never hand-edited.** It
follows the established `ROADMAP.md → utils/roadmap-dashboard.sh → ROADMAP-DASHBOARD.md` pattern
already in this repo: committed so ranking changes show up in diffs and code review, greppable by
agents that never open a browser, and readable on GitHub. Regenerating it is idempotent; a stale
checked-in copy is a review signal, not a hazard.

**3. One template, two baked artifacts.** `LEADERBOARD.html` is produced by the SAME
`bake_static(template, payload)` path that produces `RELEASES-PREVIEW.html`, from the SAME
`utils/timeline/RELEASES.html` template — the payload gains a `view` field (`"timeline"` |
`"leaderboard"`) and the page's boot function renders one or the other. This is the maximum
available reuse: no second copy of the ~200 lines of design-system CSS, no second baker, one data
contract, and still two standalone self-contained files that open from a git checkout with no
server. The GH-106 post-write hook regenerates both.

**Navbar link placement:** the cross-link belongs in the `.top` header row (title line), NOT in
`#fbar` — `#fbar` is inside the collapsible header shipped in GH-103, so a link there disappears
when the operator collapses the chrome. Each page links to the other: `RELEASES-PREVIEW.html` gets
"leaderboard →", `LEADERBOARD.html` gets "← timeline".

### Rejected alternative: a React SPA (operator raised it, 2026-08-20)

**Rejected.** The one reason that decides it: today's artifacts are zero-dependency single files
that open from a plain `git checkout` with no build step, and the deterministic GH-106 regeneration
hook depends on that property. A React SPA introduces a build toolchain (`node_modules`, bundler,
lockfile) into a repo whose gate philosophy is fast and deterministic — the pre-push gate would
either have to run a bundler or accept committed build output that silently drifts from source.

The premise behind the SPA question — "multiple HTML files to maintain" — dissolves under rule 3
above: there is one template and one generator, producing two rendered views. If a *third* view is
ever wanted, the first move is extracting the shared chrome into a template partial, not adopting a
framework. Revisit only if the viewer ever needs genuine client-side state (routing, filtering
across pages, live editing) — and note that live editing would violate GH-103's founding rule that
the page is a pure consumer.

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
   the columns yet, so the blast radius is the sync path, which the **gh69** suite pins (per
   touchpoint 4's corrected test boundary; gh32 keeps only cross-ledger/migration coverage).
2. **Phase B (one PR): exporter + viewer** (touchpoints 2, 3). Named deliverables: rating-column
   selection, `effectiveScore`, the stdout `--json` flag, the viewer's `app`→`appeal` rename +
   `effort` in both metric loops, and the legend flip — legend and first metric emission in the SAME
   commit. Preview regenerates via the GH-106 hook on the next CLI write.
3. **Phase C (no code): backfill + template** (touchpoints 5, 6). Operator scores ~12 active-window
   items; the first ranked read comes free via the pinned `--json` command below — no leaderboard
   artifact needed yet, which is what keeps C independent of D.
4. **Phase D (one PR): the leaderboard pipeline** (touchpoint 7). `utils/leaderboard.sh` consuming
   `--json`; generated `LEADERBOARD.md`; the `view` field + leaderboard rendering in the shared
   template; `--leaderboard` baking `LEADERBOARD.html`; the two-way navbar cross-link in `.top`;
   both artifacts added to the GH-106 refresh hook. Tests: the script's ranking matches the pinned
   `--json` ordering exactly (one scorer, proven), and a rated detour appears in the ranking, not
   just manifest cards.

Each phase is independently shippable; a stall after any phase leaves the repo better than before
it. D depends on B (it consumes `--json`) but not on C — an empty leaderboard from unrated data is a
valid, correct artifact.

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

**Phase D adds to the exit criterion:** `utils/leaderboard.sh` regenerates `LEADERBOARD.md`
idempotently (a second run produces a byte-identical file), its top five matches the pinned command's
top five exactly — the one-scorer property, proven rather than asserted — `LEADERBOARD.html` bakes
from the shared template with the `view` field set, the two pages cross-link from their title rows,
and the GH-106 hook refreshes both artifacts after a CLI write.

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
