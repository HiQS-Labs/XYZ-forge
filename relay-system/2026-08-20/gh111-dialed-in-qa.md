# Relay: GH-111 dialed-in plan — sharpen & QA
STATUS: Changes requested
NEXT: aider (Reviewer)

## Task

Review `PROJECT/2-WORKING/GH-111-DIALED-IN.md` — the plan to retire release-manifest FREEZE and
replace it with a per-task/per-marathon DIALED-IN database state.

**Definition of Done for this review:** the plan's schema changes are sound against the real code
paths (`utils/py/releases_app.py` — schema at :490-520, dump writer :747-756, `load_dump()`
:2602-2612, rebuild migration chain :2649-2650), the state machine and its exclusivity constraint
are correct and safe for existing data, the prose-migration scope is right, and each of the five
"Open items for review" at the end of the doc gets an explicit verdict.

**Highest-value things to attack:**
1. The **partial unique index** on `manifest_items(issue_ref_id) WHERE state='dialed_in'` — does it
   actually give one-release-at-a-time without breaking legitimate history (cut on A, dial into B)?
2. **Migration-number collision** with GH-108's migration 003 (`PROJECT/2-WORKING/GH-108-RATING-SYSTEM.md`),
   which touches `roadmap_items` in the same week. Is the stated "whoever lands second renumbers"
   rule sufficient, or does it need a real mechanism?
3. The **`open` → `dialed_in` rename** of an existing CHECK-constrained state on populated rows —
   SQLite cannot ALTER a CHECK constraint in place. Is the migration actually implementable?
4. Whether folding #109 + #110 into this change is right, or whether it makes one change too big.

**Constraints on findings:**
- The four numbered decisions under "## The decision" are FROZEN operator calls — flag a
  contradiction WITH them, do not relitigate them.
- This is a REVIEW turn: report findings in this relay file only; do not edit the plan doc.
- Rank findings Blocking / Optional / Out-of-scope. Cite doc lines or repo files for each.

## Protocol

Append a `### Round N · Reviewer · aider` block with your findings, then set the `STATUS:` line at
the top of this file to `Approved` or `Changes requested`, and end your block with
`**Verdict:** Approved` or `**Verdict:** Changes requested`.

▶ TAKE YOUR TURN (aider)

### Round 1 · Reviewer · aider

The plan is directionally sound and does not contradict the frozen operator decisions. However, the implementation details currently under-specify several SQLite and dump/rebuild constraints that are load-bearing in this repo. I am requesting changes before this can be approved.

#### Blocking

1. **The `open` → `dialed_in` rename is not implementable as a simple ALTER.**
   `manifest_items.state` is currently constrained by a CHECK in the v1 schema, and SQLite cannot ALTER a CHECK constraint in place. The plan must explicitly specify a table-rebuild migration for `manifest_items` (create new table, copy rows with `open` mapped to `dialed_in`, drop/rename, recreate indexes/triggers/FKs). As written, schema change 1 reads like an in-place CHECK replacement, which is not safe or portable.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md` (“Schema changes”, item 1); `utils/py/releases_app.py` (`MIGRATION_001`, `manifest_items` CHECK).

2. **The existing `UNIQUE (release_id, issue_ref_id)` conflicts with “re-admitting a cut item is a new dial-in row”.**
   The plan says a cut item can be re-admitted by inserting a new row. But the current schema has `UNIQUE (release_id, issue_ref_id)`, which would refuse a second row for the same release and issue even if the old row is `cut`. The plan must say whether that UNIQUE constraint is dropped, replaced, or made partial. If it remains as-is, the stated state machine is impossible for same-release redial. If it is changed, that also requires the table-rebuild migration above.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md` (“The state model”, “Schema changes”); `utils/py/releases_app.py` (`manifest_items` UNIQUE constraint).

3. **`manifest_state_events` is not covered by the migration plan.**
   The current append-only event table has CHECK constraints on `from_state` and `to_state` using the old state vocabulary. If `open` is renamed to `dialed_in`, historical events may still contain `open`, and the append-only triggers forbid updating them. The plan must specify one of:
   - keep `open` legal in `manifest_state_events` forever as a historical value, or
   - rebuild the event table with an explicit migration mapping, while preserving append-only semantics.
   It must also specify what event is written for `manifest ship`, because `manifest_state_events.reason` is NOT NULL and current code only appends events on cut.
   Cites: `utils/py/releases_app.py` (`manifest_state_events`, `mse_no_update`, `mse_no_delete`, `cmd_manifest_cut`); `PROJECT/2-WORKING/GH-111-DIALED-IN.md` (“Schema changes”).

4. **Dump/load/rebuild compatibility is under-specified.**
   The plan correctly says the new columns must be carried by the canonical dump writer, `load_dump()`, and the rebuild migration chain. But it does not specify:
   - the dump grammar for `dialed_in_at`, `dial_reason`, and `manifest_items.marathon_id`;
   - whether old dumps containing `state='open'` are accepted and mapped to `dialed_in`;
   - how `_rebuild()` applies migrations 003/004 before loading the dump.
   This matters because `dump_text()` currently emits only the old manifest columns, and `load_dump()` currently inserts only those columns. Without explicit compatibility rules, merge/rebuild can fail or silently lose new fields.
   Cites: `utils/py/releases_app.py` (`dump_text`, `load_dump`, `_rebuild`); `PROJECT/2-WORKING/GH-111-DIALED-IN.md` (“Schema changes”).

5. **Migration-number collision with GH-108 needs a real mechanism, not only a renumbering convention.**
   GH-108 already plans migration 003. GH-111 plans migration 004 but also says it may take 003 if GH-108 has not landed. “Whoever lands second renumbers” is a process statement, not a mechanical guard. A merged dump can contain duplicate `schema_migrations` versions, and current dump validation does not specifically name that case. The plan should require:
   - explicit migration allocation at merge time;
   - a test covering both migrations landing together;
   - preferably a validation rule that refuses duplicate `schema_migrations.version` values in a merged dump.
   Cites: `PROJECT/2-WORKING/GH-108-RATING-SYSTEM.md` (touchpoint 1, migration 003); `PROJECT/2-WORKING/GH-111-DIALED-IN.md` (“Sequencing”); `utils/py/releases_app.py` (`validate_merged_dump`, `_rebuild`).

6. **`dialed_in_at` backfill source does not exist in the current schema.**
   The plan says to backfill `dialed_in_at` from the release’s creation time where no better timestamp exists. But the current `releases` table has no `created_at` column. Unless the migration adds such a column or derives the value from receipts/other data, the plan should state that migrated rows remain NULL. As written, it promises a backfill source that is not present.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md` (“Schema changes”, item 2); `utils/py/releases_app.py` (`releases` schema in `MIGRATION_001`).

7. **Exclusivity lifecycle needs clarification for shipped items and historical marathon links.**
   The partial unique index on `manifest_items(issue_ref_id) WHERE state='dialed_in'` is the right shape for preventing multiple active dial-ins, and it does not block cut history. But the plan does not fully state whether a `shipped` item on release A may later be dialed into release B. The index as written would allow that. That may be intended, but it should be explicit.
   Similarly, the proposed unique index on `releases(marathon_id) WHERE marathon_id IS NOT NULL` blocks a marathon from being linked to two releases, but it also blocks reuse after a release is cut or shipped unless the old release’s `marathon_id` is cleared. The plan should state whether marathon links are historical forever or active-only.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md` (“Schema changes”, items 5–6); `utils/py/releases_app.py` (`releases.marathon_id`).

#### Optional

1. **Folding #109 and #110 is acceptable, but #109 could be split if size grows.**
   #110 is tightly coupled because the state machine is being redefined anyway. #109 is also coupled through `manifest_items.marathon_id`, but its exporter work could be separated if Phase B becomes large. I would not block the plan on this, but it is worth watching.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md` (“Convergence with #109 and #110”); `utils/timeline/export_timeline.py`.

2. **Exporter changes need explicit state mapping.**
   `utils/timeline/export_timeline.py` currently knows `shipped` and `cut`, but not `dialed_in`. The plan should specify that `dialed_in` renders as open/queued/wip depending on roadmap enrichment, and that `shipped` renders done. This is likely already intended, but it should be pinned.
   Cites: `utils/timeline/export_timeline.py` (`manifest_cards`).

3. **Denominator convention should be pinned in the plan, not left implicit.**
   The current exporter counts all manifest cards in `itemsTotal`, including cut rows, while the Ballast prose treats cut as reducing the manifest. The plan’s recommendation to count `dialed_in + shipped` and exclude `cut` is the better convention. It should be adopted explicitly.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md` (“Denominator question”); `utils/timeline/export_timeline.py` (`release_columns`).

4. **Prose migration scope is mostly right, but the plan should name the active/draft blocks it will convert.**
   In the provided `RELEASES.md`, shipped blocks such as Litmus, Nightwatch, and Ballast keep their historical `Manifest: FROZEN` lines. Draft blocks such as Lantern, Meter, and Cargo contain freeze/re-freeze language that would need conversion. The plan’s homonym warning around GH-308 is correct and important.
   Cites: `RELEASES.md`; `PROJECT/2-WORKING/GH-111-DIALED-IN.md` (“Prose migration”); `AGENTS.md` (GH-308 frozen twins).

#### Out-of-scope

1. **Relitigating the frozen operator decisions.**
   The review does not challenge the decisions to retire FREEZE, make membership DIALED-IN, enforce exclusivity, or store the state in the database. The findings above are implementation safety issues, not policy reversals.

2. **Changing GH-308 frozen-twin rules.**
   The plan correctly avoids touching frozen Bash twin prose. That remains out of scope.

#### Verdicts on the five open items

1. **Candidate tier:** No for v1. Keep the model simple: `dialed_in` is the commitment state. If a candidate tier is needed later, it can be added as a separate pre-commitment state without breaking this change.

2. **Invert marathon pointer:** Not now. Keep `releases.marathon_id` for v1 and add a partial unique index, but clarify lifecycle. Inverting to `marathons.release_id` is cleaner conceptually but touches more code and can be deferred.

3. **`dial_reason` friction:** Yes, keep it required for new dial-ins. It replaces the deliberateness previously supplied by the freeze/admission rule. Migrated rows may remain NULL.

4. **Baseline counting:** Adopt. Losing FREEZE’s fixed denominator is a real regression risk. Recording a baseline count when a release becomes active is the right way to make scope growth measurable instead of forbidden.

5. **Denominator:** Exclude cut items. The denominator should be `dialed_in + shipped`. This matches the manifest-as-commitment model and avoids counting descoped work as still-committed.

**Verdict:** Changes requested
