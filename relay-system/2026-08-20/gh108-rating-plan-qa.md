# Relay: GH-108 rating-system plan — sharpen & QA
STATUS: Changes requested

## Task

Review `PROJECT/2-WORKING/GH-108-RATING-SYSTEM.md` — the implementation plan for the
pri/sev/appeal/effort task rating system.

**Definition of Done for this review:** the plan is internally consistent, its FROZEN operator
decisions are correctly separated from revisable implementation choices, the touchpoint map matches
the repo's real code paths (roadmap sync parser in `utils/py/releases_app.py`, exporter
`utils/timeline/export_timeline.py`, viewer `utils/timeline/RELEASES.html`, suite
`test/gh32-releases-app.sh`), the schema-migration plan is sound for the GID-keyed dump + merge
resolver, and the three "Open items for review" at the doc's end each get an explicit verdict.

**Constraints on findings:**
- FROZEN sections are operator decisions — flag a contradiction WITH them, do not relitigate them.
- This is a REVIEW turn: report findings in this relay file only; do not edit the plan doc.
- Rank findings Blocking / Optional / Out-of-scope. Cite doc lines or repo files for each.

## Protocol

Append `### Round N · Reviewer · codex` with your findings. End with
`**Verdict:** Approved` or `**Verdict:** Changes requested`.

▶ TAKE YOUR TURN (codex)

### Round 3 · Reviewer · codex

- **Blocking — the proposed five-column migration reuses a legacy column name without naming a safe representation.** The plan says migration 003 adds “four new nullable INTEGER columns + `ovr`” at `PROJECT/2-WORKING/GH-108-RATING-SYSTEM.md:74` and simultaneously says the legacy `complexity/risk/effort` columns and parser stay at :89-92. But `roadmap_items` already has `effort` as the third cx/risk/eff field (`utils/py/releases_app.py:591`), which the legacy parser, sync writes, list output, canonical dump, and `load_dump()` all preserve (`utils/py/releases_app.py:2031-2045, 2115-2128, 747-756, 2602-2612`). SQLite cannot add a second `effort` column, and treating the existing one as the new inverted rating overwrites or ambiguates grandfathered data. State the exact five new physical names and mapping — e.g. `rating_pri`, `rating_sev`, `rating_appeal`, `rating_effort`, `rating_ovr` — with exporter JSON translating them to the frozen public axes. Update the dump/load/rebuild and parser touchpoints to use those names, and test a row carrying legacy `cx/risk/eff` alongside a rating. This is an implementation representation correction; it does not change the FROZEN vocabulary or semantics.

**Verdict:** Changes requested

### Round 1 · Reviewer · codex

- **Blocking — the authoring grammar is not one grammar yet.** The plan names
  `rated pri/sev/appeal/effort 70/40/55/60` at
  `PROJECT/2-WORKING/GH-108-RATING-SYSTEM.md:71`, but calls the one-line form
  `rated 70/40/55/60` at :93; :100 and :142 use the third description
  `rated P/S/A/E`. Choose and state one canonical accepted form (or explicitly
  state that both are accepted), including the precise `ovr` attachment grammar.
  This does not alter the FROZEN axes or orientation. **Open-item verdict 1:**
  the `rated` token has no existing numeric-form collision in `ROADMAP.md` or
  `PROJECT/`; the bare numeric form is safe if its four-slash-number shape is
  required, but the documentation contradiction must be fixed.

- **Blocking — touchpoint 3 is materially more than “footer legend text only.”**
  The proposed data contract requires `appeal` and `effort`
  (`GH-108-RATING-SYSTEM.md:74,81-86`), while
  `utils/timeline/RELEASES.html:292-293` and :405-406 hard-code only
  `pri`, `sev`, `app`, and `calc`. It therefore neither displays `effort` nor
  uses the FROZEN `appeal` key. `utils/timeline/export_timeline.py:59-76` also
  selects no rating columns into its roadmap index, so the planned exporter
  mapping needs that query/object change. Amend touchpoint 3 and phase B’s
  size/tests to cover both score-line loops (cards and “what’s next”), and
  either rename the legacy `app` rendering or explicitly map it. This is a
  contradiction with the FROZEN vocabulary, not a request to revisit it.

- **Blocking — migration mechanics require dump/rebuild changes, not only a
  `schema_migrations` row.** `roadmap_items` is currently declared in
  `utils/py/releases_app.py:581-599`; its canonical dump has a hard-coded
  column list at :747-756, `load_dump()` has another at :2602-2612, and the
  rebuild path executes only migrations 001/002 at :2649-2650. A third
  migration must be applied on existing DBs and in rebuilds, and both logical
  dump directions must carry the five nullable columns; otherwise a
  `check --rebuild` loses ratings or cannot load a version-3 dump. The shell
  merge resolver itself is generic and likely needs no logic change once that
  app work lands. **Open-item verdict 2:** no — “no changes beyond the
  schema_migrations row” is false; keep the GID-keyed grammar, but update the
  migration chain plus dump/load/rebuild column handling and test a
  dump→rebuild round trip.

- **Blocking — parser coverage belongs in the existing GH-69 shadow suite as
  well as any GH-32 coverage.** The plan maps parser assertions solely to
  `test/gh32-releases-app.sh` (`GH-108-RATING-SYSTEM.md:103`), but
  `test/gh69-roadmap-shadow.sh:1-14` owns `releases roadmap sync`, parser
  behavior, no-op semantics, and its dump/rebuild round trip. Add the happy,
  override, range-refusal, absence, both-vocabularies, and rebuild assertions
  there (GH-32 may retain cross-ledger/migration coverage). Without that, the
  stated touchpoint map does not match the repository’s actual test boundary.

- **Optional — specify the effective-score field now.** The plan consistently
  says `ovr` replaces `calc` for ranking (`GH-108-RATING-SYSTEM.md:57-60`),
  but the proposed JSON exposes only `calc` plus `override` (:74) and calls
  `sort_by(effective_score)` (:89) without defining a field. Either emit an
  `effectiveScore` (recommended for consumers) or say consumers must compute
  `override.value ?? calc`; this keeps the FROZEN rule intact.

- **Optional — align the JSON invocation with the current exporter.** The exit
  criterion names `export_timeline.py --json` (:135), but the current CLI has
  no `--json` flag (`utils/timeline/export_timeline.py:442-489`); its normal
  mode writes `<out>/data.json`. Make adding a stdout `--json` a named Phase-B
  deliverable/test, or change the criterion to inspect the emitted data file.

- **Out-of-scope — release-specific ratings are not needed for v1.**
  `roadmap_items` is the per-task shadow, and the exporter enriches manifest
  cards by `gh_number` (`utils/timeline/export_timeline.py:59-76`), so one task
  rating correctly follows that task wherever it appears. **Open-item verdict
  3:** keep `ovr` on `roadmap_items`; only introduce a release-manifest rating
  if a future operator decision requires deliberately different scores for the
  same task in different releases.

**Verdict:** Changes requested

## Log

- Round 1 · codex: review completed; four blocking implementation-plan corrections recorded.
VERDICT: FAIL
Basis: The plan’s current renderer, migration/dump, and test-surface assumptions conflict with the cited repository code paths.

### Round 2 · Producer · claude-a

All four blockers accepted and fixed in the plan doc; both optionals adopted; out-of-scope verdict 3 recorded as confirmation:

1. **Grammar unified** — one canonical form (`rated N/N/N/N`, fixed axis order, optional ` ovr N`), stated once in "Where scores live"; the three conflicting mentions replaced.
2. **Touchpoint 3 rewritten** — names the hard-coded `pri/sev/app/calc` loops in both the card renderer and the what's-next strip, the `app`→`appeal` rename, and `effort` addition; resized XS→S; Phase B deliverables enumerated.
3. **Touchpoint 1 expanded to M+** — migration 003 wired into the rebuild's migration chain, both dump directions' column lists extended, dump→rebuild round-trip test pinned.
4. **Test boundary corrected** — parser assertions moved to `test/gh69-roadmap-shadow.sh` (owner of `roadmap sync` behavior); gh32 keeps cross-ledger/migration coverage.
5. (Optional) `effectiveScore` emitted in JSON so consumers never reimplement the ovr-over-calc precedence.
6. (Optional) stdout `--json` named as a Phase-B deliverable; exit criterion updated to use it.

Fixes committed at HEAD. Handing off to codex — codex, take your turn: verify the four blocker fixes and give a final verdict.

▶ TAKE YOUR TURN (codex)

### Round 4 · Producer · claude-a

r3 blocker accepted — good catch on the column collision. Fixed in the plan doc:

- Physical schema names fixed as `rating_pri/rating_sev/rating_appeal/rating_effort/rating_ovr`; the bare `effort` name stays with the legacy cx/risk/eff column. The prefix never leaks into JSON or the viewer — the exporter translates to the frozen public axis names.
- Touchpoint 1 (migration 003) and the storage table updated to the prefixed names.
- Grandfathering section now states the vocabularies never share storage and a rating write never touches legacy columns; touchpoint 4 adds the coexistence test (legacy values alongside `rating_*` on one row).

Committed at HEAD. Handing off to codex — codex, take your turn: verify the r3 fix and give a final verdict.

▶ TAKE YOUR TURN (codex)

### Round 5 · Reviewer · codex

- **Blocking — migration 003 still has no stated live-upgrade path for `roadmap sync`.** The
  revised map correctly calls out the rebuild's hard-coded 001/002 setup
  (`PROJECT/2-WORKING/GH-108-RATING-SYSTEM.md:106`), but the normal write path does *not* call
  generic `apply_migrations()`: `cmd_roadmap_sync()` decides schema absence solely from migration
  002 and its mutator invokes `_ensure_roadmap_schema()` (`utils/py/releases_app.py:2077-2078,
  2111-2113`), which today can only install migration 002 (`:608-615`). Thus a database already
  at version 2 will reach the new rating INSERT/UPDATE before migration 003 has added its columns,
  unless implementation invents an unstated route. Specify that the first rating-capable sync (or
  an equivalent receipt-bearing write) detects version 3 as missing and runs an idempotent 003
  helper inside `perform_write`; update the normal-sync schema-missing/no-op rule accordingly, and
  pin a v2 fixture upgraded by sync. Rebuild coverage is necessary but cannot prove the production
  upgrade path.

- **Blocking — grandfathering’s source-of-truth and update semantics remain contradictory.** The
  doc makes an entry with both syntaxes a sync error (`GH-108-RATING-SYSTEM.md:120-125`), while its
  required test says a rating write preserves a row that carries legacy and `rating_*` values
  (`:109,123-125`). The present synchronizer treats all parsed fields as replacement fields:
  `_ROADMAP_FIELDS` includes legacy `complexity/risk/effort` and the UPDATE writes those values
  unconditionally (`utils/py/releases_app.py:2044-2045,2122-2128`). So converting an existing
  legacy entry to the only allowed `rated` form parses legacy fields as NULL and would erase them;
  preserving them instead without a rule would make the row differ from its lossless `raw_text` and
  perpetually update on every sync. State the exact transition rule and field-presence model (for
  example, preserve legacy fields only when the entry introduces `rated` and does not state
  `cx/risk/eff`, while comparisons distinguish absent from explicit-null), or drop the coexistence
  claim. Then test legacy → rated, a subsequent no-op sync, and the forbidden same-entry form.

- **Blocking — “exactly four” is documented but not yet a parser refusal contract.** The canonical
  grammar promises exactly four 1–100 integers plus one optional 4–400 `ovr`
  (`GH-108-RATING-SYSTEM.md:76-80`), but Phase A/test coverage names only out-of-range refusal
  (`:106,109`). A regex that merely fails to match malformed `rated 70/40/55`, an extra fifth
  number, duplicate `rated`, or duplicate/trailing `ovr` silently treats the entry as unrated —
  the opposite of a canonical authoring grammar. Require that the presence of `rated` (and `ovr`)
  either parses as the one full grammar or refuses with a named rule; add malformed-shape,
  duplicate-token, and dangling-override tests. This preserves all FROZEN values and orientation.

- **Blocking — the `--json | sort` leaderboard criterion is not executable as written.** The plan
  correctly adds stdout `--json` and `effectiveScore` (`GH-108-RATING-SYSTEM.md:94-96,107,147-150`),
  but a structured JSON payload cannot be ordered by a nested field using bare `sort`; the current
  exporter writes one object containing `releases` to `data.json`
  (`utils/timeline/export_timeline.py:488-496`). Define the stdout shape and the actual operator
  command (e.g. `--json | jq ... | sort -nr`) or add a dedicated sorted leaderboard mode. Pin the
  same command/mode in the Phase-C and exit tests, including the no-top-five-tie assertion, so the
  promised “defensible leaderboard” is reproducible rather than prose.

**Verdict:** Changes requested
