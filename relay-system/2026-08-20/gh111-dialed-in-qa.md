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

### Round 2 · Producer · claude-a

All seven blockers accepted — every factual claim verified against the schema before acting, and all seven held. Fixes in the plan doc:

1. **Table rebuild, not ALTER.** Schema section rewritten as a 12-step table-rebuild migration for both affected tables, inside one transaction, with `foreign_key_check` before commit.
2. **`UNIQUE (release_id, issue_ref_id)` is now explicitly DROPPED.** You were right that it makes the stated state machine impossible — re-admission needs a new row. The global partial index supersedes it, and multiple `cut` rows per (release, issue) become legitimate history.
3. **`manifest_state_events` now covered.** CHECKs gain `dialed_in` while **`open` stays legal forever**; existing rows copied verbatim rather than remapped — rewriting them would be the silent history edit this repo forbids. `manifest ship` takes `--evidence`, stored as the NOT NULL reason. Round-trip test must prove the digest chain still verifies post-rebuild.
4. **Dump/load/rebuild specified.** Fixed field order, absent trailing fields read NULL, `load_dump()` accepts legacy `state='open'` and maps it (old dumps stay loadable — they are the git-merge surface), `_rebuild()` applies 001→004 before loading.
5. **Migration allocation made mechanical.** Fixed now: GH-108 owns 003, GH-111 owns 004, neither renumbers, gaps are fine. Plus your `validate_merged_dump()` duplicate-version rule and a both-migrations test.
6. **`dialed_in_at` backfill corrected.** `releases.created_at` does not exist — verified. Migrated rows stay NULL; mining `op_receipts` named as explicitly not-v1.
7. **Lifecycle stated.** A `shipped` item MAY be dialed into a later release (intended — #32 spans phases). Marathon links are permanent, never re-linked.

Optionals 2, 3, 4 adopted (exporter state mapping pinned; denominator = `dialed_in + shipped`; active/draft blocks named from the DB — only Meter and Cargo actually carry FROZEN lines). Optional 1 noted: #109's exporter work can split out if Phase B grows.

Open-item verdicts recorded. **One deliberate exception:** your ADOPT on baseline counting is recorded as reviewer concurrence, not as a decision — that one is the operator's, and the plan stays implementable without it.

Touchpoint 1 resized L→XL and touchpoint 4 M→L to reflect the rebuild scope.

Committed at HEAD. Handing off to aider — aider, take your turn: verify the seven fixes and give a final verdict.

▶ TAKE YOUR TURN (aider)

### Round 3 · Harness note · claude-a

**The aider/qwen verification turn FAILED to produce a review** (relay-drive exit 5). The model never emitted a findings block; it entered a meta-loop reasoning about the response format itself — whether to update the `NEXT:` line, and how to nest triple-backtick fences when echoing a file that contains them. `aider-turn.sh`'s GH-251 salvage then did its documented job and appended the turn transcript verbatim, which preserved ~1,200 lines of chain-of-thought as relay content. That salvage block is removed here; this note replaces it so the failure stays on the record rather than being silently deleted.

Two known-hazard notes from the shim itself apply and are worth recording for whoever runs this lane next:
- `aider-turn.sh:145-147` already special-cases qwen with "keep your internal reasoning extremely brief (under 50 words)". It did not hold on a review-only turn.
- GH-251 notes aider drifts to an editor posture on review turns; the full-file-echo instinct seen here is that same drift in a different shape.

**Round 1 stands and is not affected** — it delivered seven substantive blockers, every one verified against the schema and fixed in Round 2. Only the verification of those fixes is outstanding.

Retrying the same lane once. Handing off to aider — aider, take your turn: verify the seven Round 2 fixes and give a final verdict. Append a `### Round 4 · Reviewer · aider` block with your findings and set the `STATUS:` line. Do NOT echo the file back; append your block only, and keep reasoning brief.

▶ TAKE YOUR TURN (aider)

### Round 4 · Producer · claude-a — lane change to Codex

The aider/qwen lane is retired for this thread by operator instruction; the route is now graded **C** for reviewer use in `HARNESS-MODELS-REGISTRY.md` (both halves recorded — r1's review content was excellent, the delivery seam is not). Harness cleanup done the sanctioned way: stray `rtl-wt` worktree removed, stuck `aider` claim cleared with `tick reap` (auditable `task.released`), fresh token `RELAY-gh111-codex-verify` for this round.

**Since Round 1, two things changed and NEITHER has been read by a second reviewer:**

1. **Round 2 applied all seven of r1's blockers** — table-rebuild migration for both `manifest_items` and `manifest_state_events`, the `UNIQUE (release_id, issue_ref_id)` drop, event-table CHECK vocabulary keeping `open` legal forever, `manifest ship --evidence` for the NOT NULL reason, dump/load/rebuild compatibility incl. legacy `state='open'` mapping, fixed migration allocation (108→003, 111→004) plus a duplicate-version validation rule, and the `dialed_in_at` backfill correction (`releases.created_at` does not exist).
2. **Baseline counting was ADOPTED by the operator and specified from scratch** — three write-once columns, auto-capture on `draft → active` only when the manifest is non-empty, no-capture (never zero) when empty, a `releases baseline` verb for that case, progress-plus-growth reporting where negative growth is legitimate, and a flagged `backfilled` migration for currently-active releases.

▶ TAKE YOUR TURN (codex — REVIEWER)

Verify the seven r1 fixes landed correctly AND review the baseline design, which no second reader has seen. Highest-value angles:

- **The baseline kickoff-ordering rule.** The naive "snapshot on activate" would have given Daybreak a baseline of 0 (release rows are created before manifests are dialed in). Does the non-empty-manifest condition actually close that, or does it just move the hazard? What happens on `active → draft → active`, or if a release is created directly as `active`?
- **Write-once enforcement** — is refusal the right behavior when a legitimate re-baseline is wanted, and is there a code path that could set it twice?
- **The table-rebuild migration** for two tables in one transaction, including recreating the append-only triggers on `manifest_state_events` while preserving the digest chain.
- **Migration allocation** 003/004 across two in-flight plans, and whether the `validate_merged_dump()` duplicate-version rule is sufficient.
- Anything r1 got wrong that I accepted too readily.

Constraints: the four decisions under "## The decision" and the adopted baseline are FROZEN operator calls — flag contradictions WITH them, do not relitigate them. REVIEW turn: report in this relay file only, do not edit the plan doc. Rank Blocking / Optional / Out-of-scope, cite doc lines or repo files. End with `**Verdict:** Approved` or `**Verdict:** Changes requested` and set the `STATUS:` line at the top.

### Round 5 · Reviewer · codex

The seven Round 1 corrections are real improvements: the partial active-membership index has the right historical shape; the old event vocabulary is retained; the old-dump `open` mapping, fixed 003/004 allocation, and `manifest ship --evidence` are all correctly called out. The adopted baseline also correctly refuses a misleading zero at the normal activate-before-membership ordering. I cannot approve yet because the plan still leaves five implementation-critical paths unspecified or contradictory.

#### Blocking

1. **The plan has no execution/ledger path to migrate an existing live database.** `apply_migrations()` is currently invoked only by `cmd_init`, while ordinary existing-DB commands merely call `connect()`; `check --rebuild` is explicitly merge resolution, not a normal upgrade. The plan must define the command/entry point that runs 003 then 004 for an existing DB, does so through the normal receipt/dump transaction, and records those versions. It must also say how a rebuilt v2 dump gets 003 and 004 `schema_migrations` rows: today `_rebuild()` prepares schema DDL before `load_dump()`, but the dump is what supplies migration rows. Otherwise the rebuilt DB can have v4 columns while still claim only v2, making a later migration attempt re-run DDL against an already-v4 schema.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md:159-180,280-284`; `utils/py/releases_app.py:618-629,1285-1288,2527-2532,2646-2653`.

2. **Baseline fields are omitted from the specified dump grammar.** The plan fixes the field order and legacy-null handling only for the three new `manifest_items` fields. It adds three `releases` baseline fields, but does not give their release-record order or legacy default rule. The current dump and loader both enumerate `releases` independently, so an implementation following the stated grammar can silently discard observed/backfilled baselines on `check --rebuild`. Specify the three appended release fields and require dump/load round-trip preservation for them as well.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md:144-148,161-169,217-220`; `utils/py/releases_app.py:691-705,2551-2569`.

3. **The baseline lifecycle needs an idempotent rule for every legal activation path.** The planned capture rule needs an explicit guard: capture only when all three baseline fields are unset, otherwise preserve the existing snapshot without refusing a legitimate `active → draft → active` update. It must also define direct `releases add --status active`: that path has no `draft → active` transition and necessarily starts empty, so it must be declared baseline-less and eligible for the later `releases baseline` verb (or be forbidden). Finally, require the count and the baseline update to occur in the same writer-locked transaction as the status transition, and require the three fields to be all-NULL or all-populated; otherwise a partial baseline can leak into rendering.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md:222-241`; `utils/py/releases_app.py:1424-1453,1462-1498`.

4. **Dropping the per-release UNIQUE means `manifest cut` cannot remain unchanged.** After cut-then-redial on the same release there are deliberately multiple rows for one `(release_id, issue_ref_id)`. The current cut lookup selects that pair with no state predicate, so it can select the historical `cut` row and refuse instead of operating on the live `dialed_in` row. The plan calls `manifest cut` “unchanged,” which contradicts this new data shape. Specify that transition commands select the unique `dialed_in` row (and refuse clearly if absent), and add the regression case “cut → redial → cut” on the same release.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md:65-68,111-124,263-266`; `utils/py/releases_app.py:1633-1648`.

5. **The table-rebuild FK sequence is not executable as written.** SQLite does not change `PRAGMA foreign_keys` while a transaction is open. The plan says the two-table swap is inside one transaction with foreign keys off “for the swap,” but must say that FK enforcement is disabled *before* `BEGIN`, then restored after commit; `foreign_key_check` may run before commit while enforcement is off. It must also prescribe the dependency-safe order for rebuilding `manifest_state_events` and `manifest_items`, then recreating both append-only triggers. This is necessary to preserve the event rows and their digest-chain proof rather than relying on an order-sensitive drop.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md:102-107,126-135`; `utils/py/releases_app.py:395-410,493-518`.

#### Optional

1. **The fixed allocation is sufficient for the two named plans once the v2→003→004 upgrade assertion is made exact.** The new duplicate-version check correctly names a union-merged dump defect, but it does not itself detect two different source migrations that were both authored as the same number. State that normal source integration relies on the shared `releases_app.py` conflict plus the ordered-v2-fixture test; do not represent the dump validator as broader collision prevention.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md:171-180,282-284`; `utils/py/releases_app.py:2479-2525`.

2. **Write-once refusal is the right operator behavior.** A legitimate re-baseline should be a separate, explicitly authorized future operation, not an accidental second capture; the required reactivation no-op above preserves that without weakening the adopted rule.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md:222-223`.

#### Out-of-scope

1. The four frozen operator decisions, including adoption of a baseline, remain unchallenged. These findings make their implementation durable rather than reopening the policy calls.

2. Round 1’s five open-item verdicts remain explicit and sound: no v1 candidate tier; keep the marathon pointer direction; require `dial_reason`; retain the adopted baseline; and exclude cut rows from the denominator.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md:318-330`.

**Verdict:** Changes requested

### Round 6 · Producer · claude-a

All five blockers accepted and fixed; both optionals adopted. Two were second-order consequences of my own r1 fixes, which is exactly what a verification round is for.

1. **Live-DB upgrade path added.** Verified your claim: `apply_migrations()` has exactly two references — its definition and one call, inside `cmd_init` (`releases_app.py:1287`). Nothing upgrades an existing ledger. Added a **`releases migrate`** verb running through `perform_write()` (writer lock, journal, generation stamp, receipt, staged dump) so an upgrade is an auditable ledger event. `_rebuild()` must stamp `schema_migrations` rows matching the DDL it materialized, and migrations are written idempotently behind a schema probe so a version/DDL mismatch no-ops instead of erroring. Also flagged that GH-108's per-feature "sync self-migrates" sketch should be dropped in favor of this verb — noted for that plan, not changed here.
2. **Baseline fields added to the `releases` dump grammar** with fixed order, absent-reads-NULL, and a required round-trip assertion. You were right that the earlier text specified only the `manifest_items` fields, so a faithful implementation would have discarded every baseline on `check --rebuild`.
3. **Baseline lifecycle made idempotent across all paths.** Auto-capture skips silently when a baseline exists (so `active → draft → active` is a no-op, never a refusal) while the explicit verb still refuses — deliberately different, per your optional 2. `releases add --status active` is declared baseline-less and eligible for the verb rather than forbidden, since forbidding it would break how releases are actually cut here. Count and write share the status transition's writer-locked transaction. All-three-NULL-or-all-populated enforced by CHECK.
4. **`manifest cut` is no longer described as unchanged** — verified: its lookup is `WHERE release_id=? AND issue_ref_id=?` with no state predicate (`:1633-1637`), correct only while the dropped UNIQUE guaranteed one row. All transition commands now select `… AND state='dialed_in'`; regression `cut → redial → cut` on one release added. This was my error introduced by the r1 fix, and it would have shipped silently.
5. **FK sequence corrected.** `PRAGMA foreign_keys = OFF` **before** `BEGIN`, restored after `COMMIT`; `foreign_key_check` before commit while enforcement is off; parent (`manifest_items`) rebuilt before child (`manifest_state_events`) with `id` values preserved verbatim so the digest chain stays verifiable; triggers recreated immediately after.

Optional 1 adopted — the dump validator's scope is now stated honestly (it catches a union-merged dump, not two branches authoring the same migration number; source collisions are caught by the ordinary merge conflict plus the ordered fixture test).

Committed at HEAD. Handing off to codex — codex, take your turn: verify these five and give a final verdict.

▶ TAKE YOUR TURN (codex)

### Round 7 · Reviewer · codex

Round 6 correctly resolves the five prior findings in principle: the baseline now has a sound non-empty, all-or-nothing, reactivation-safe lifecycle; the release dump fields are specified; and the transition lookup, fixed 003/004 allocation, and parent-before-child rebuild are all necessary corrections. I cannot approve yet: the live migration and rebuild paths still contradict the existing writer/dump protocol, and marathon membership remains unenforced across the two new links.

#### Blocking

1. **`releases migrate` cannot run migration 004 through the current `perform_write()` transaction as specified.** The plan correctly requires `PRAGMA foreign_keys = OFF` *before* `BEGIN` for the table swap, but then requires the new verb to execute migration 004 through `perform_write()`. That function writes the journal and immediately executes `BEGIN IMMEDIATE` before it invokes its mutation callback, on a connection whose `connect()` setup has already enabled foreign keys. SQLite ignores the later PRAGMA, so the required rebuild has no executable live-DB path. Specify a migration-aware writer protocol (for example, a pre-BEGIN callback which disables FKs after the journal but before `BEGIN`, then restores them only after commit), including rollback/error restoration and the unchanged receipt/dump ordering; or give `migrate` an equivalent explicitly journalled protocol. 
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md:105-118,210-212`; `utils/py/releases_app.py:841-904`, `connect()` at :395-410.

2. **The rebuild's migration-ledger ownership is still unspecified and will collide with the existing loader.** The plan says `_rebuild()` materializes/stamps 001–004 before loading, while `load_dump()` inserts every `schema_migrations` record from the dump. With a v2 dump, pre-stamping 1–4 then loading its 1–2 rows fails the primary-key constraint; if the builder instead preserves the current loader behavior, the rebuilt v4 schema retains only the v2 ledger rows — the defect Round 5 found. Require one precise ownership rule: e.g. build DDL without ledger rows, load non-ledger dump data, then write the canonical 1–4 ledger rows; or have `load_dump()` explicitly ignore/validate migration records when called by rebuild. The rule must preserve duplicate-version rejection and be covered by the stated v2-rebuild-v4 test.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md:195-201,335`; `utils/py/releases_app.py:2527-2533,2645-2658`.

3. **The new `manifest_items.marathon_id` can assert false cross-release marathon membership unless its relationship to `releases.marathon_id` is enforced.** The unique index on `releases(marathon_id)` says only one release may name a marathon, but the nullable item FK independently permits an item on release B to carry the marathon belonging to release A. That again lets the exporter group a task under a marathon outside its release and violates the frozen “marathons belong to exactly one release” decision. A cross-table CHECK cannot express this in SQLite, so specify CLI validation/assignment semantics: a dial-in with a marathon must verify that the selected marathon is the target release's marathon (or reject it), with a regression refusal test for a marathon owned by another release.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md:94-96,135-138,165-180,332-335`; `utils/py/releases_app.py:MIGRATION_001` (`releases.marathon_id` and `manifest_items` are independent FKs).

#### Optional

1. **The baseline decision is now sufficiently pinned.** Auto-capture only with all fields unset and a non-empty manifest, no capture at zero, explicit capture for the empty/direct-active route, and a silent reactivation no-op correctly preserve the adopted write-once meaning. The only wording cleanup is that `baseline_count` is the lone count field; `baseline_at` and `baseline_source` are provenance fields.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md:267-310`.

#### Out-of-scope

1. The four locked operator decisions, the adopted baseline itself, and the five Round 1 open-item verdicts remain unchallenged. These findings only require their database implementation to have a valid transaction and invariant boundary.

**Verdict:** Changes requested

### Round 8 · Producer · claude-a

All three blockers accepted and fixed; optional 1 (wording) adopted.

1. **`perform_write()` cannot carry a table-rebuild migration — correct, and the fix is a sibling protocol.** `perform_write()` journals then immediately opens `BEGIN IMMEDIATE` on an FK-enabled connection, and SQLite ignores the pragma inside a transaction, so there was no executable live path. Added **`perform_migration()`**: identical durability contract (writer lock, intent journal, generation stamp, op_receipt, staged dump, atomic renames) with the pragma bracketed in the only place it works — `foreign_keys = OFF` after the journal and before `BEGIN`, `foreign_key_check` inside, `ON` only after `COMMIT`. On error: rollback, restore the pragma, **leave the journal** so existing crash recovery treats an interrupted migration exactly like an interrupted write.
2. **Rebuild ledger ownership pinned to one rule.** You were right that both candidate readings fail — pre-stamping collides with `load_dump()`'s inserts on the primary key, deferring reproduces the v2-ledger-on-v4-schema defect. Now: `_rebuild()` materializes current DDL with no ledger rows → `load_dump()` skips `schema_migrations` records when invoked by rebuild → `_rebuild()` writes the canonical 001–004 rows itself. DDL and ledger agree by construction; duplicate-version rejection is untouched because it validates dump contents before this step.
3. **Cross-release marathon assertion closed as a CLI invariant.** Genuinely subtle — the two FKs are independent, so an item on release B could carry release A's marathon and re-open #109's false-membership defect through a different door. SQLite can't express it as a cross-table CHECK, so it is stated as a CLI rule: `manifest dial-in --marathon` verifies the marathon belongs to the target release and refuses otherwise, and a release's `marathon_id` cannot be changed or cleared while items reference it. Refusal regression added.

Convergence note: blockers per round are **7 → 5 → 3**, declining, with each round reaching genuinely deeper and none re-arguing closed items. If this round returns to zero, the plan is done. If it instead surfaces a fourth wave of new implementation blockers, my recommendation to the operator will be to stop planning and build Phase A behind its test suite — per the GH-77 lesson that a state machine specified in prose eventually needs executable assertions instead of another review round.

Committed at HEAD. Handing off to codex — codex, take your turn: verify these three and give a final verdict.

▶ TAKE YOUR TURN (codex)

### Round 9 · Reviewer · codex

Round 8 resolves the three preceding findings in principle: `perform_migration()` puts the FK
pragma at the only valid transaction boundary, rebuild ledger ownership is unambiguous, and the
cross-release marathon assertion is now a tested CLI invariant. I still cannot approve because the
planned migration mechanics are contradictory across the two independently landing 003/004 changes,
and the specified transaction can be accidentally defeated by the existing migration implementation
idiom.

#### Blocking

1. **The claimed order-independent 003/004 allocation does not define a safe executable migration
   chain.** GH-111 says whichever plan lands first may leave a gap, but its `releases migrate` and
   `_rebuild()` both materialize and stamp the current 001→004 schema. If GH-111 lands first, that
   code has neither GH-108's 003 DDL nor its rating dump/load fields, yet the rebuild rule requires
   it to stamp 003; that yields a ledger claiming v3/v4 while `roadmap_items` lacks the v3 columns.
   Conversely, GH-108 still specifies a first-rating-sync, in-`perform_write()` 003 helper, while
   GH-111 says feature commands do not self-migrate. Require one integration rule: either GH-108's
   003 schema helper/grammar must land before any GH-111 `migrate` or rebuild can expose v4, or a
   shared migration registry must ship first and make both verbs run pending versions strictly in
   numeric order. Add the GH-111-first control fixture (v2 DB/dump, then 004 code before 003) rather
   than testing only the happy v2→003→004 integration order.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md:204-252,263-271`;
   `PROJECT/2-WORKING/GH-108-RATING-SYSTEM.md:109-112`; `utils/py/releases_app.py:618-629,2645-2653`.

2. **`perform_migration()` needs an explicit no-`executescript()` implementation constraint.** The
   required single `BEGIN IMMEDIATE` / swap / `foreign_key_check` / receipt transaction is correct,
   but the current migration helpers materialize DDL with `conn.executescript()`; Python's SQLite
   wrapper commits any pending transaction before executing that script. Reusing that established
   idiom for the 004 rebuild would silently split the transaction, making the stated FK bracket,
   rollback, digest, and receipt guarantees false. State that the 004 DDL is issued with individual
   `execute()` calls (or another helper proven not to commit), and add a failure-in-swap test proving
   neither table nor receipt/generation survives a rollback.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md:105-118,229-250`;
   `utils/py/releases_app.py:608-615,841-904`.

#### Optional

1. The present baseline lifecycle remains approved in principle: non-empty auto-capture, explicit
   empty-path capture, all-or-nothing fields, reactivation no-op, and backfilled provenance honor
   the adopted decision without manufacturing a false zero.
   Cites: `PROJECT/2-WORKING/GH-111-DIALED-IN.md:299-366`.

#### Out-of-scope

1. The frozen operator decisions and the previously closed task/history/marathon semantics are not
   reopened. These blockers concern only an atomic, correctly ordered implementation path.

**Verdict:** Changes requested
