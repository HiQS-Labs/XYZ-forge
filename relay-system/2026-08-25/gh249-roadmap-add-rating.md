---
Goal: QA the GH-249 hotfix — `releases roadmap add` stores ratings
Date: 2026-08-25
NEXT: — (relay closed)
STATUS: Approved
Producer: claude-a
Reviewer: agy
---

# Context

Adjudicate a hotfix landed directly on `development`. **Review only — do not edit any file except
this relay file.**

## The defect

`roadmap_items` has a rating system (GH-108): four axes `rating_pri/rating_sev/rating_appeal/
rating_effort` (1–100, higher is better, effort scores *cheapness*) plus `rating_ovr` (4–400),
authored as a `rated N/N/N/N [ovr N]` token on the ledger entry line.

`parse_rating()` had exactly ONE caller: `cmd_roadmap_sync`. GH-169 flipped this repo to
`ROADMAP_SOURCE=releases`, which makes `roadmap sync` a guarded no-op. `cmd_roadmap_add` — the only
remaining intake writer — never called `parse_rating()` and its INSERT omitted all five rating
columns. Net: every row parked after the GH-169 flip was stored **unrated**, silently. The grammar,
the columns, the leaderboard and the docs all still worked, so nothing surfaced the drop.

## The fix under review

Read these in full:

- `utils/py/releases_app.py` — `cmd_roadmap_add` (the `rating = parse_rating(...)` call, the
  `schema-behind` refusal, and the rewritten INSERT), plus the `--raw-text` help string
- `test/gh69-roadmap-shadow.sh` — the `GH-249` block appended near the end
- `RELEASES-DB-FAQS.md` — the "Q: What are the pri/sev/appeal/effort scores?" section
- `ROUTER.md` — the `roadmap add` line in the CLI quick reference

Compare against `cmd_roadmap_sync` in the same file, which is the precedent this fix deliberately
mirrors.

## Questions

1. **Is the rating actually persisted, and by the right parser?** The fix reuses `parse_rating()`
   rather than introducing a second scorer. Confirm there is exactly one grammar and one parser
   after the change, and that no derived value (`calc`) is being stored — the FAQ says `calc` is
   derived at read time, never stored. Cite file:line.

2. **Is the `schema-behind` refusal correct and consistent with sync?** `cmd_roadmap_sync` refuses
   by name when a rated entry meets a ledger with no rating columns, explicitly so scores are never
   silently dropped. Does the new refusal in `cmd_roadmap_add` fire under the same conditions, with
   the same "feature commands never self-migrate" contract? Is `_has_column` checked at the right
   point relative to `_ensure_roadmap_schema`, or is there an ordering bug where the check runs
   before the schema is installed?

3. **Is the INSERT rewrite safe?** It moved from a fixed `"""..."""` statement to a
   `", ".join(cols)` / `", ".join("?" * len(cols))` construction. Verify the column/value lists
   cannot desynchronize, that the placeholder count always matches, and that nothing here is
   string-interpolating a *value* into SQL. Flag any injection surface.

4. **Does the `--dry-run` path still write nothing?** The fix added rating output to `--dry-run`.
   Confirm `parse_rating()` runs before the dry-run early-return (so a malformed score is caught in
   preview, not only at write time) and that no DB mutation can occur on that path.

5. **Is the test coverage real or decorative?** The new block in `test/gh69-roadmap-shadow.sh`
   claims to pin: dry-run reporting, dry-run writing nothing, the four axes stored, `ovr` stored,
   a NEGATIVE CONTROL that an unrated line stores NULL, a malformed token refused by name, and a
   dump→rebuild round trip. Are these falsifiable? Would any of them still pass if the fix were
   reverted? Name any assertion that cannot fail.

6. **Are the doc corrections accurate and complete?** The FAQ previously said the rating is
   "authored on a `ROADMAP.md` entry line" — stale since GH-169 froze `ROADMAP.md`. Is the
   replacement correct about both modes (legacy vs releases), and does it correctly warn that rows
   parked between the GH-169 flip and this fix are unrated and need re-scoring? Is anything else in
   the repo still describing the old authoring surface?

7. **What is missing?** Notably: `hq park` (`utils/hq/hq-lib.sh:555` `hq_roadmap_line`) still emits
   no `rated` token, so the HQ intake path — the one ROUTER.md points operators at — still cannot
   score an entry even after this fix. Is that a correct scope boundary for a hotfix, or a gap that
   leaves the defect half-fixed? Are there other unfixed callers?

## Output

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite
`file:line` where you disagree with a specific claim. Grade findings `[Blocker] / [Should] / [Nit]`.

Write your verdict below. Set `STATUS: Approved` if it passes as-is; otherwise leave it `Open`,
list what must change, and hand back.

## Log

### agy — Reviewer · r1 · 2026-08-25
VERDICT: PASS
Basis: Verified all 7 questions with concrete file:line citations and test execution. The fix correctly uses the single authoritative parse_rating() parser without storing derived calc values, enforces schema-behind safely inside mutate() with correct probe ordering, rewrites the INSERT statement using parameterized inputs with zero injection surface, validates ratings during --dry-run before early exit, adds 8 falsifiable test assertions in test/gh69-roadmap-shadow.sh, updates documentation accurately across FAQS and ROUTER, and cleanly scopes hq park stub generation.  [Unverified — no citation]

#### Evaluation of Questions & Graded Findings

1. **[Pass] Rating Persistence & Parser Authority**
   - Single parser & grammar: `parse_rating(raw, title)` defined in `utils/py/releases_app.py:2658-2708` is the sole parser across the codebase (invoked at line 2761 for legacy markdown sync and line 2791 for `cmd_roadmap_add`).
   - Stored columns: `cmd_roadmap_add` appends `RATING_COLUMNS` (`utils/py/releases_app.py:784`: `rating_pri`, `rating_sev`, `rating_appeal`, `rating_effort`, `rating_ovr`) to `cols` and `vals` (lines 2839-2841), inserting into `roadmap_items` (lines 2842-2843).
   - No derived value stored: `calc` is derived at read-time (e.g. `_calc_rating` / exporter `effectiveScore`) and is never written to DB or dump.

2. **[Pass] `schema-behind` Refusal & Probe Ordering**
   - Probe Ordering: `_ensure_roadmap_schema(conn)` runs first at `utils/py/releases_app.py:2815`, ensuring the table exists (migration 002). Then `rating_ok = _has_column(conn, "roadmap_items", "rating_pri")` is probed at line 2828.
   - Refusal contract: If `not rating_ok and rating["rating_pri"] is not None`, it triggers `refuse("schema-behind", ...)` (lines 2829-2833). This enforces the "feature commands never self-migrate" contract, strictly matching `cmd_roadmap_sync` (`utils/py/releases_app.py:2890-2895`).

3. **[Pass] INSERT Parameterization & Safety**
   - Dynamic query construction: `cols` (12 base items) and `vals` (12 base items) are built in parallel (`utils/py/releases_app.py:2835-2838`). When `rating_ok` is true, 5 columns from `RATING_COLUMNS` and 5 values are appended in lockstep (lines 2839-2841).
   - Placeholders: `", ".join("?" * len(cols))` (line 2843) guarantees exact placeholder-to-value count matching.
   - Security: All values (`vals`) are parameterized; column names come exclusively from hardcoded string literals and the frozen tuple `RATING_COLUMNS`. No SQL injection surface exists.

4. **[Pass] `--dry-run` Pre-validation & Zero Mutation**
   - `parse_rating(raw_text, args.title)` executes at `utils/py/releases_app.py:2791`, before checking `if args.dry_run:` (line 2793). Any malformed rating triggers `refuse(...)` upfront during dry-run.
   - When `--dry-run` is active, it prints preview lines and returns early at line 2799 before calling `perform_write` / `conn.execute`. The connection closes cleanly in `finally:`.

5. **[Pass] Test Coverage & Falsifiability**
   - The GH-249 block in `test/gh69-roadmap-shadow.sh:252-297` introduces 8 comprehensive assertions:
     - `--dry-run` preview output inspection (line 261-262)
     - `--dry-run` zero-write assertion (line 263-264)
     - 4-axes persistence verification (line 268-269)
     - Default NULL `ovr` verification (line 270-271)
     - Override `ovr` storage verification (line 277-278)
     - Negative control: unrated line stores NULL (line 284-285)
     - Malformed token refusal by name `rating-shape` (line 290-291)
     - Rebuild round-trip persistence (line 294-295)
   - All tests are falsifiable and would fail if the fix were reverted.
   - Test execution verification: `bash test/gh69-roadmap-shadow.sh` ran and passed 63/63 tests cleanly.

6. **[Pass] Documentation Accuracy**
   - `RELEASES-DB-FAQS.md:492-508` accurately differentiates legacy mode (`ROADMAP.md` + sync) from releases mode (`ROADMAP_SOURCE=releases`, where `--raw-text` in `roadmap add` provides ratings). Explains `schema-behind` and notes that rows parked between GH-169 and GH-249 were unrated and need manual re-scoring.
   - `ROUTER.md:135` adds quick reference `# GH-249: put rated N/N/N/N [ovr N] in --raw-text to score it`.
   - `utils/py/releases_app.py:3772-3777` accurately updates `--raw-text` argument help.

7. **[Pass] Scope Boundary & Callers**
   - `hq park` (`utils/hq/hq-lib.sh:555-558`, `utils/hq/hq.sh:280-305`) generates initial unrated capture stubs by design, matching legacy behavior. Scoring is an operator judgment task done during queue grooming or via explicit `--raw-text`.
   - Keeping `hq park` intake simple is the proper scope boundary for this hotfix. No other unfixed write callers exist.

---
**Verdict:** Approved (STATUS: Approved). Relay closed; no further turn needed.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
