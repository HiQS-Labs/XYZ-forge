---
gh_issue: 111
source: https://github.com/HiQS-Suite/XYZ-forge/issues/111
title: "Retire manifest FREEZE; tasks and marathons are DIALED-IN to exactly one release, as a database state"
status: Active (2-WORKING as of 2026-08-20)
created: 2026-08-20
updated: 2026-08-20
owner: noelsaw1
doc_type: plan
rating: "pri/sev/appeal/effort 80/55/70/45 · calc 250"
goal: >
  Replace a prose-only release-level FREEZE with a per-task, per-marathon DIALED-IN state that
  lives in the database, is exclusive to one release at a time, and can express "done" — so
  membership becomes machine-checkable instead of a sentence someone remembered to write.
---

# GH-111: Retire FREEZE, adopt DIALED-IN (Plan)

> **Operator decision 2026-08-20 — LOCKED.** *"Let's remove the concept of a build's manifest being
> frozen. On the flip side, we can say tasks (and by extension marathons) are dialed-into
> (associated) a particular build... I agree with your idea to make it a database state."*

## Status

| What was just completed | What's next |
|---|---|
| **PHASES A, B and C BUILT 2026-08-20** on `feat/gh111-phase-a-dialed-in` (clone `XYZ-forge-gh108-rating-system`). A: migration registry + migration 004 (table rebuild of `manifest_items` and `manifest_state_events`), `manifest dial-in` / `ship` / `cut` / `marathon`, exclusivity by partial unique index, `perform_migration()` + `releases migrate`, the extended dump grammar both directions, `_rebuild()` ledger ownership, the duplicate-version refusal, and baselines (auto-capture on `draft -> active`, trigger-enforced write-once and all-NULL-or-all-populated). B: exporter groups by `marathon_id` (#109), renders shipped members (#110), counts `dialed_in + shipped` only, and emits baseline + growth. C: the RELEASES.md preamble rule and the three active/draft blocks converted; shipped blocks and the GH-308 frozen-twin prose untouched. The LIVE ledger is migrated (schema {1,2,3,4}); Daybreak carries a backfilled baseline of 9, its nine marathon members are linked, and #79-81 are `shipped` with evidence. gh32 99 -> 138, new gh103 suite 37/0, all 18 releases-subsystem suites green. | Merge into `development`. Then close #109 and #110 with pointers, and decide where #108 lands (its own release, Meter, or unassigned) — the one operator decision this plan still owes. |

## The decision

1. **FREEZE is retired.** A release's manifest is no longer locked at creation, and the
   `Manifest: FROZEN …` prose convention ends for active and future releases.
2. **Membership is DIALED-IN**, a per-task state. A task is dialed into a release, or it is not on
   it at all. There is no separate "candidate" tier (see Open item 1 — this is the simple reading of
   the decision, and simplicity is the default until someone argues otherwise).
3. **Exclusive: one release at a time**, for tasks and for marathons alike.
4. **It lives in the database**, not in prose — so in-band releases can carry it and gates can check
   it.

## Premise correction — exclusivity is NOT true today

The operator asked "tasks and/or marathons can only belong to one release at a time, right?" As of
`a267042` the answer is **no, the schema permits multi-release membership**:

- `manifest_items` has `UNIQUE (release_id, issue_ref_id)` — that stops the same issue appearing
  **twice on one release**. It does nothing to stop the same issue sitting on **two different
  releases**.
- Marathons are worse: the pointer is `releases.marathon_id` (release → marathon), unconstrained, so
  two releases may name the same marathon. The direction is also backwards for this model — under
  "a marathon is dialed into a release", the marathon should name its release, or membership should
  be expressed once and shared.

**Current violations: zero.** No issue is on two releases; marathon 1 is named by exactly one
release. So exclusivity can be enforced cleanly, with no data to reconcile — but it is a **new
constraint being introduced**, not an existing property being documented. That distinction matters
for the migration and for the tests.

## The state model

`manifest_items.state` today is `CHECK (state IN ('open','shipped','cut'))`, of which only `open` and
`cut` are ever written (`shipped` is dead — #110).

Proposed:

| State | Meaning | Written by |
|---|---|---|
| `dialed_in` | committed to this release; counts toward the denominator | `manifest dial-in` (renamed from `add`) |
| `shipped` | the work landed | `manifest ship` — **closes #110** |
| `cut` | removed from this release, with a recorded reason | `manifest cut` (unchanged) |

`open` → `dialed_in` is a vocabulary rename of the existing state, applied to existing rows by the
migration. Legal transitions: `dialed_in → shipped`, `dialed_in → cut`. **Illegal:** `shipped → *`
and `cut → dialed_in` on the same release — re-admitting a cut item is a new dial-in row, so the
history stays append-only and readable.

**Exclusivity is enforced on ACTIVE membership only:** a partial unique index over `issue_ref_id`
where `state = 'dialed_in'`. A task cut from release A is free to be dialed into release B; its
historical `cut` row on A does not block it. This is the property that makes the constraint safe —
without the partial predicate, ordinary release history would trip it.

## What replaces the admission rule

FREEZE carried a standing admission rule (a mid-release discovery joins only with a failing exit
command or a falsified invariant, plus a reproducer, plus an explicit swap or date slip). With no
freeze to violate, that rule stops being a gate. It should not simply evaporate — it is what stopped
scope creep from being invisible.

**Proposal: dialing in requires a reason, exactly as cutting does.** `manifest dial-in` takes
`--reason`, stored on the row. Deliberateness is preserved by making every commitment state its
case; rigidity is dropped by not requiring a ceremony to *change* the commitment. The admission
rule's text survives as guidance in RELEASES.md's preamble rather than as an enforced gate.

## Convergence with #109 and #110 — one change, three defects

These three issues are the same state machine seen from three angles, and doing them together is
cheaper and safer than doing them in sequence:

- **#110 (`shipped` is dead)** is closed by the `manifest ship` verb above — the state model has to
  be redefined here anyway.
- **#109 (viewer asserts false marathon membership)** is closed by the marathon link this plan needs
  regardless. `manifest_items` gains a nullable `marathon_id`; the exporter then groups only true
  members instead of assuming "release has a marathon ⇒ every item is a work unit."
- Doing #109's migration separately would mean **two migrations touching one table** in the same
  week, racing GH-108's migration 003. Sequence them deliberately: see Sequencing.

## Schema changes — migration 004 (GH-108 owns 003; allocation is FIXED, see below)

**This is a TABLE-REBUILD migration, not a set of `ALTER`s** (Aider/Qwen r1 B1). SQLite cannot alter
a CHECK constraint in place, and two of the changes below rewrite CHECK vocabularies.

**Exact procedure (Codex r2 B5 — the earlier wording was not executable).** SQLite **ignores
`PRAGMA foreign_keys` while a transaction is open**, so "off for the swap, inside the transaction"
would silently leave enforcement on. The order is:

1. `PRAGMA foreign_keys = OFF` — **before** `BEGIN`.
2. `BEGIN IMMEDIATE`.
3. Rebuild the **parent first**: `manifest_items` → create `_new` with the final shape, `INSERT …
   SELECT` mapping `open` → `dialed_in` **and preserving `id` values verbatim** (the child's
   `item_id` references them), drop, rename.
4. Rebuild the **child**: `manifest_state_events` → same pattern, rows copied byte-for-byte with no
   state remapping, then recreate `mse_no_update` / `mse_no_delete` and `idx_mse_item`.
5. Recreate every index on `manifest_items`, add the new partial indexes.
6. `PRAGMA foreign_key_check` — legal here, and meaningful, while enforcement is off.
7. `COMMIT`, then `PRAGMA foreign_keys = ON`.

Preserving the child's rows verbatim and its `item_id` linkage is what keeps the event digest chain
verifiable across the rebuild; the round-trip test asserts the chain still verifies afterwards.

### `manifest_items`

1. `state` CHECK becomes `('dialed_in','shipped','cut')`; existing `open` rows map to `dialed_in`
   during the copy.
2. **`UNIQUE (release_id, issue_ref_id)` is DROPPED** (r1 B2). It would refuse the new row that
   re-admission requires, making the stated state machine impossible. It is replaced by — and is
   redundant with — the partial index in 5.
3. `dialed_in_at TEXT` — when the commitment was made. **Migrated rows stay NULL** (r1 B6): the
   plan previously named `releases.created_at` as the backfill source and *that column does not
   exist*. Mining `op_receipts` for a truer timestamp is possible and explicitly not v1. NULL is the
   honest value for "committed before this was tracked."
4. `dial_reason TEXT` — the case for the commitment; NULL on migrated rows, required on new ones.
5. `marathon_id INTEGER REFERENCES marathons(id)` — nullable; closes #109.
6. `CREATE UNIQUE INDEX … ON manifest_items(issue_ref_id) WHERE state = 'dialed_in'` — exclusivity,
   active membership only. Cut rows never block a redial, on this release or another; multiple `cut`
   rows for one (release, issue) pair are legitimate history and are now permitted by dropping 2.

**Consequence the earlier draft missed (Codex r2 B4): `manifest cut` is NOT unchanged.** Its row
lookup is `SELECT * FROM manifest_items WHERE release_id=? AND issue_ref_id=?` with **no state
predicate** (`releases_app.py:1633-1637`) — correct only because the dropped UNIQUE guaranteed one
row. After cut-then-redial on the same release there are several, so `fetchone()` can return the
historical `cut` row and the verb then refuses with "cut is terminal" while a live `dialed_in` row
sits right there. **Every transition command (`cut`, `ship`) must select the unique
`… AND state = 'dialed_in'` row** and refuse clearly when none exists. Regression case:
cut → redial → cut on one release.

### `manifest_state_events` (r1 B3 — the plan previously ignored this table)

7. `from_state` / `to_state` CHECKs become `('open','dialed_in','shipped','cut')`. **`open` stays
   legal forever as a historical value.** Existing event rows are copied **verbatim** — they keep
   saying `open`, because rewriting them would be exactly the silent history edit this repo forbids
   (the same principle that keeps shipped releases' `FROZEN` lines). `open` is documented as the
   pre-2026-08-20 name for `dialed_in`.
   The append-only *guarantee* is about the CLI never mutating rows; a migration rebuilding the table
   while preserving contents byte-for-byte does not violate it, and the triggers are recreated
   immediately. The round-trip test must prove the digest chain still verifies after the rebuild.
8. **`manifest ship` must supply a reason** — `manifest_state_events.reason` is `NOT NULL CHECK
   (length(trim(reason)) > 0)`. The verb takes `--evidence` (commit, PR, or test receipt), stored as
   the reason, mirroring how `releases ship` is evidence-bearing. A ship without evidence is refused.

### `releases`

9. `CREATE UNIQUE INDEX … ON releases(marathon_id) WHERE marathon_id IS NOT NULL` — a marathon
   belongs to at most one release.
10. `baseline_count INTEGER`, `baseline_at TEXT`, `baseline_source TEXT CHECK (baseline_source IN
    ('observed','backfilled'))` — the adopted baseline (see "Measuring commitment growth"). These are
    plain column additions and do **not** require rebuilding `releases`; only the marathon index is
    new alongside them. Write-once: a second capture is refused. Backfilled for currently-`active`
    releases during the migration, flagged as such.

### Lifecycle rules the indexes imply (r1 B7 — state them, don't leave them emergent)

- **A `shipped` item MAY later be dialed into another release.** The partial index permits it and
  that is intended: a long-lived tracking issue can legitimately ship work in one release and more
  in a later one (#32 spans phases exactly this way).
- **Marathon links are historical and permanent.** A marathon is never re-linked to a second release,
  even after the first ships or is cut. A marathon is a release-scoped effort; reusing one across
  releases would make "which release ran this marathon" unanswerable.
- **`manifest_items.marathon_id` must agree with its release's marathon — CLI-enforced (Codex r3
  B3).** The two links are independent foreign keys, so nothing in the schema stops an item on
  release B from carrying release A's marathon; that would let the exporter group a task under a
  marathon from another release, reintroducing #109's false-membership defect through a new door and
  contradicting the frozen one-release rule. SQLite cannot express this as a cross-table CHECK, so it
  is a CLI invariant, stated as such: **`manifest dial-in --marathon <gid>` verifies the marathon is
  the target release's own marathon and refuses otherwise**, and a release's `marathon_id` cannot be
  changed or cleared while any manifest item references it. Regression test: dialing in with a
  marathon owned by another release is refused by name.

### Dump / load / rebuild compatibility (r1 B4)

- Dump grammar, `manifest_items`: the three new columns are appended to that record's field order,
  fixed, in the order listed above. Absent trailing fields read as NULL so a v3 dump still loads.
- **Dump grammar, `releases` (Codex r2 B2 — previously omitted entirely):** `baseline_count`,
  `baseline_at`, `baseline_source` are appended to the *release* record's field order, in that order,
  with the same absent-reads-as-NULL rule. The dump writer and `load_dump()` enumerate `releases`
  independently, so an implementation that followed the earlier text would have silently dropped
  every baseline on `check --rebuild`. Round-trip preservation of these three is a required
  assertion, not an implied one.
- `load_dump()` **accepts `state='open'` from older dumps and maps it to `dialed_in`** on the way in;
  it emits only the new vocabulary. Old dumps therefore stay loadable — required, because dumps are
  the git-merge surface and a colleague's branch may carry a pre-migration dump for weeks.
- **`_rebuild()` migration-ledger ownership — ONE rule, stated exactly (Codex r3 B2).** The earlier
  wording ("stamp rows matching the DDL") collides with `load_dump()`, which inserts every
  `schema_migrations` record the dump contains: pre-stamping 001–004 and then loading a v2 dump's two
  rows fails on the primary key, while deferring to the loader reproduces the v2-ledger-on-v4-schema
  defect. The rule:

  1. `_rebuild()` materializes DDL for **the ordered versions present in the registry** — never a
     hard-coded range — writing **no** ledger rows.
  2. `load_dump()` loads all dump data **except `schema_migrations` records**, which it skips when
     invoked by rebuild.
  3. `_rebuild()` then writes ledger rows for **exactly those same registry versions**, in ascending
     order.

  Both steps read the registry, so a GH-111-first build materializes and stamps {001, 002, 004} and
  never claims 003 (Codex r5 B1 — the earlier "001 → 004" wording contradicted the registry rule
  added in the same round and would have re-introduced the false-v3 claim).

  DDL and ledger therefore always agree by construction. Duplicate-version rejection is unaffected —
  it validates the dump's contents before this step, not after.
- Every migration is additionally written **idempotently** (guarded by a schema probe, not by the
  version number alone), so any residual version/DDL mismatch degrades to a no-op rather than an
  error.

### The live-database upgrade path (Codex r2 B1 — the plan had none)

`apply_migrations()` is called from **exactly one place: `cmd_init` (`releases_app.py:1287`)**.
Ordinary commands on an existing database just `connect()`, and `check --rebuild` is merge
resolution, not an upgrade. So nothing in the current CLI upgrades a live ledger, and the plan
previously assumed a mechanism that does not exist.

- Add an explicit **`releases migrate`** verb with its own writer protocol, **`perform_migration()`**
  — a sibling of `perform_write()`, not a caller of it (Codex r3 B1). `perform_write()` writes the
  journal and then immediately issues `BEGIN IMMEDIATE` on a connection where `connect()` has already
  enabled foreign keys, and SQLite ignores a `PRAGMA foreign_keys` change inside an open transaction.
  So a table-rebuild migration has **no executable path** through it. `perform_migration()` keeps the
  identical durability contract with one added step in the right place:

  ```
  acquire writer lock → write intent journal
  → PRAGMA foreign_keys = OFF          ← the added step, AFTER the journal, BEFORE BEGIN
  → BEGIN IMMEDIATE
  → apply pending migration DDL (parent-before-child order above)
  → PRAGMA foreign_key_check           ← MUST FAIL THE MIGRATION if it returns any row,
                                          before the generation/receipt stamp below
  → stamp generation + op_receipt
  → COMMIT
  → PRAGMA foreign_keys = ON           ← restored only after commit
  → stage dump → atomic renames → clear journal
  ```

  **On any error:** `ROLLBACK`, restore `PRAGMA foreign_keys = ON`, and **leave the journal in place**
  so the existing crash-recovery path sees an interrupted migration exactly as it sees an interrupted
  write. Receipt and dump ordering are unchanged from `perform_write()`; only the pragma bracket is
  new.

  **Implementation constraint — no implicit-commit APIs in ANY registry callback (Codex r4 B2,
  widened by r6 B1).** Every existing migration materializes DDL through `conn.executescript()`
  (`releases_app.py:612, 624, 2649`), and Python's `sqlite3` wrapper **issues a COMMIT before running
  that script**. Reusing the house idiom would silently split the transaction and make every
  guarantee above false — the FK bracket, the rollback, the digest chain, and the receipt coupling —
  while appearing to work.

  The constraint is therefore on **the protocol, not on migration 004**: *every callback
  `perform_migration()` invokes must be transaction-safe*, issuing DDL as individual `execute()`
  calls (or via a helper proven not to commit). This matters immediately because a v2 database with
  **both 003 and 004 pending** runs them inside one `BEGIN IMMEDIATE`, and 003's natural
  implementation is `_ensure_roadmap_schema()`, which calls `executescript()` today. If 003 commits
  mid-flight, a later 004 failure leaves 003's schema and ledger rows **durable** while the journal,
  generation, receipt, and dump all describe an interrupted all-or-nothing migration — the ledger
  would be lying about its own recovery state.

  Two failure-injection tests pin it: (a) an error mid-swap in 004 alone, and (b) **a v2 fixture with
  003 and 004 both pending that fails inside 004**, asserting that neither migration's schema
  changes, neither ledger row, nor the generation bump, receipt, or staged dump survives.
- It is idempotent: with nothing pending it is a clean no-op that still reports the current version.
- Feature commands do **not** self-migrate. (GH-108's plan sketched a per-feature "sync detects
  version 3 missing and runs a 003 helper" path; with a real `migrate` verb that special case should
  be dropped there rather than duplicated here — flagged for that plan, not changed by this one.)
- All three hard-coded column lists must learn the new fields (`releases_app.py:747-756`,
  `:2602-2612`, `:2649-2650`) — the same trap GH-108's review found.

### Migration-number allocation — mechanical, not conventional (r1 B5)

"Whoever lands second renumbers" was process, not a guard. Replaced by:

- **Allocation is fixed now: GH-108 owns 003, GH-111 owns 004.** Neither renumbers; whichever lands
  first simply leaves a gap the other fills. **A gap is only safe under the registry rule below**
  (Codex r4 B1) — the earlier bare claim of order-independence was wrong, because a hardcoded
  "stamp 001→004" would have a GH-111-first build claiming v3 while `roadmap_items` lacked 003's
  columns entirely.

### The migration registry — prerequisite for the fixed allocation (Codex r4 B1)

`apply_migrations()` today is a hardcoded if-chain (`if 1 not in applied: … if 2 not in applied: …`,
`releases_app.py:618-629`), which cannot express a gap. Replace it with an ordered **registry keyed
by version**, and make three rules explicit:

1. **The codebase's registry is the truth.** `migrate` and `_rebuild()` apply and stamp exactly the
   versions the registry defines — never a hardcoded range. A GH-111-first build registers
   {001, 002, 004}, stamps those three, and correctly does not claim 003.
2. **Pending migrations apply in ascending numeric order**, gaps permitted. When 003 later lands on a
   database already at 004, it applies then.
3. **Migrations must be mutually independent**, which is what makes rule 2 safe, and is a standing
   constraint on future ones. It holds here by inspection: 003 touches `roadmap_items`; 004 touches
   `manifest_items`, `manifest_state_events`, and `releases` — disjoint sets.

**Required integration rule:** GH-108's plan currently specifies a per-feature "first rating-capable
sync detects 003 missing and runs a helper inside `perform_write()`", which directly contradicts this
plan's "feature commands do not self-migrate." **That helper must be dropped in favor of `releases
migrate` before either lands** — a fix belonging to GH-108's doc, recorded here because leaving two
plans contradicting each other is how the wrong one gets built.

**Control fixture, not just the happy path:** test **GH-111-first** — a v2 database, 004 applied with
003 absent from the registry, asserting the ledger reads {1, 2, 4} and `roadmap_items` has no rating
columns; then introduce 003 and assert it applies cleanly on top of 004. **The fixture must exercise
BOTH entry points** — `releases migrate` and `check --rebuild` — asserting {1, 2, 4} in each, since
they reach the registry by different paths and only one of them was previously specified.
- `validate_merged_dump()` gains a rule **refusing duplicate `schema_migrations.version` values** in
  a merged dump — the failure a git merge of two independently-numbered branches would otherwise
  produce silently. **Scope it honestly (Codex r2 optional 1):** this catches a union-merged *dump*,
  not two source branches that both authored a migration numbered 003. Source-level collision is
  caught by the ordinary `releases_app.py` merge conflict plus the ordered v2→003→004 fixture test;
  the dump validator must not be described as broader collision prevention than it is.
- A test lands both migrations together and asserts the chain applies in order from a v2 fixture.

## Prose migration — and the homonym trap

**`grep -ri frozen` is the wrong tool here and will break the repo.** "Frozen" names two unrelated
things:

- **Manifest freeze** — this plan's target. Confined to `RELEASES.md` (the `Manifest: FROZEN …`
  lines and the preamble rule at :50).
- **Frozen Bash twins (GH-308)** — Python is authoritative, the Bash twin is frozen. All 10 hits in
  `AGENTS.md`, plus `RELEASES.md:197` ("retire the twelve frozen Bash twins"), plus
  `test/gh308-frozen-twin-guard.sh` and a CI step. **Untouched by this work.** Editing these would
  break the twin guard's own documentation.

Migration rule for RELEASES.md:

- **Shipped release blocks keep their `Manifest: FROZEN …` lines verbatim.** They are the historical
  record of how those releases were actually run. Rewriting shipped history is the silent-edit
  failure this repo forbids everywhere else.
- **Active and draft blocks convert** to the dialed-in vocabulary. Named explicitly (r1 optional 4),
  from `SELECT version, codename, status FROM releases WHERE status IN ('active','draft')`:
  **Daybreak 0.7.2** (active, in-band — no block of its own, so its record is the CHANGELOG),
  **Cargo 0.9.0**, **Meter 0.6.0**, **Sundown 0.8.0**, **Plumbline 0.4.0**, **Lantern 0.5.0**. Of
  these only Meter and Cargo currently carry a `Manifest: FROZEN` line; the rest have none to
  convert, and gain dialed-in wording when they are next touched.
- **The preamble rule at :50** is rewritten to describe dialed-in membership, with one sentence
  recording that pre-2026-08-20 releases used a freeze model and their blocks reflect it.

## Measuring commitment growth — BASELINE COUNT (operator ADOPTED 2026-08-20)

Freeze bought a fixed denominator, which is what made "N of M" honest. Dialed-in gives that up unless
something pins a baseline. The release records what it was committed to at kickoff, and thereafter
reports **two** numbers: progress against that commitment, and how much the commitment itself grew.
Scope creep becomes a measured fact instead of something forbidden-then-worked-around.

### Storage

One count field and two provenance fields:

- `releases.baseline_count INTEGER` — **the count**: dialed-in + shipped members at the kickoff
  moment.
- `releases.baseline_at TEXT` — *provenance*: when the snapshot was taken.
- `releases.baseline_source TEXT CHECK (baseline_source IN ('observed','backfilled'))` —
  *provenance*: how the number was obtained. See Backfill.

Both count columns are **write-once**. Overwriting a baseline would erase the exact thing it exists
to measure, so a second capture is refused, not silently applied.

### When the snapshot is taken — and the ordering hazard it must avoid

The naive rule ("snapshot when the release goes active") is **wrong for this repo, and would have
produced a baseline of 0 for Daybreak.** Releases are created as a row first and have their manifest
dialed in afterwards, so at the instant status flips to `active` the manifest is typically still
empty. A 0 baseline would then report every real commitment as scope growth — the metric would
actively lie in the common case.

The rule instead:

1. **Auto-capture on the `draft → active` transition when the manifest is non-empty**, and only when
   all three baseline fields are currently unset. This is the intended path: dial the work in, then
   activate.
2. **If the manifest is empty at that transition, no baseline is taken** and the release is left
   explicitly baseline-less rather than being given a misleading 0.
3. **`releases baseline --gid <rel>`** captures it later for case 2 — one command, refused if a
   baseline already exists. This is the only new ceremony the model introduces, it is optional, and
   skipping it degrades to "no baseline shown" rather than to a wrong number.

**Idempotency and the other activation paths (Codex r2 B3):**

- **Re-activation is a silent no-op, not a refusal.** `active → draft → active` must preserve the
  original snapshot without erroring — the auto-capture path *skips* when a baseline exists, while
  the explicit `releases baseline` verb *refuses*. Those are deliberately different: an accidental
  second capture should be impossible, but a legitimate status round-trip must not fail.
- **`releases add --status active` starts empty by construction** — there is no `draft → active`
  transition to hook, and no manifest yet. That path is declared **baseline-less**, eligible for
  `releases baseline` afterwards. It is not forbidden; forbidding it would break the way releases are
  actually cut in this repo.
- **The count and the baseline write happen in the SAME writer-locked transaction as the status
  transition** — otherwise a concurrent dial-in between the two lands a baseline that never existed
  as a real manifest state.
- **All three fields are all-NULL or all-populated**, enforced by a table CHECK. A partial baseline
  (count without provenance, say) must not be able to leak into rendering.

### Reporting

- **Progress:** `shipped / (dialed_in + shipped)` — against the live denominator (cut excluded, per
  the decision above).
- **Growth:** `(dialed_in + shipped) − baseline_count`. Positive is scope added since kickoff;
  **negative is legitimate and meaningful** — it means more was cut than added, i.e. scope shrank.
- A release with no baseline shows progress only, with no growth figure and no placeholder zero.

### Backfill for releases already underway

Releases that are `active` at migration time get `baseline_count` = their current dialed-in + shipped
count, with `baseline_source = 'backfilled'` — recorded as **inferred, not observed**, so nobody
later reads it as evidence of what was actually committed at kickoff. Today that means Daybreak gets
a baseline of 9, which happens to be exactly right (#79–#87), but the flag stays `backfilled` because
the mechanism did not witness it. Draft releases get no baseline; they have not kicked off.

## Touchpoints

| # | Component | Change | Size |
|---|---|---|---|
| 1 | `utils/py/releases_app.py` | migration 004 as a **table rebuild** of BOTH `manifest_items` and `manifest_state_events` (CHECK vocabularies cannot be altered in place), plus the `releases` marathon index; wired into the chain + both dump directions + `load_dump()`'s `open`→`dialed_in` acceptance; `validate_merged_dump()` duplicate-version rule; `manifest dial-in` (renamed from `add`, `--reason` required), `manifest ship` (`--evidence`, stored as the NOT NULL event reason), **`manifest cut` amended to select the `dialed_in` row** (it currently has no state predicate and breaks once the UNIQUE is dropped); **`releases migrate` — the live-DB upgrade path, which does not exist today (`apply_migrations()` is `cmd_init`-only)** — run through a new `perform_migration()` protocol (same durability contract as `perform_write()`, with the FK pragma bracketed outside `BEGIN`), idempotent, with `_rebuild()` owning the migration ledger rows and `load_dump()` skipping them; transition legality enforced; state/event coupling preserved in ONE transaction per `:515-518`; **baseline capture** — three `releases` columns, auto-capture on `draft → active` when the manifest is non-empty, write-once refusal, `releases baseline` verb for the activate-first case, and the flagged backfill for currently-active releases | **XL** |
| 2 | `utils/timeline/export_timeline.py` | group marathon members by the new `marathon_id`, non-members as siblings (#109); render `shipped` members with the done marker; denominator decision (below); emit `baseline: {count, at, source}` and the derived growth figure per release, and render both numbers on the card — a baseline-less release shows progress only, with no placeholder | **M** |
| 3 | `RELEASES.md` | preamble rule rewritten; active/draft blocks converted; **shipped blocks untouched**; GH-308 "frozen twins" prose untouched | M (prose) |
| 4 | `test/gh32-releases-app.sh` (+ `test/gh69-roadmap-shadow.sh` where sync is involved) | transitions incl. illegal ones; exclusivity refusal (dial a task into a second release → refused **by name**, citing the holding release); cut-then-redial on the SAME release allowed (proves the dropped UNIQUE); cut-then-redial elsewhere allowed; shipped-then-dial-elsewhere allowed; marathon exclusivity; ship-without-evidence refused; **v2 fixture → 003+004 chain applied in order**; **merged dump with duplicate `schema_migrations.version` refused**; old dump carrying `state='open'` loads and maps; dump→rebuild round trip preserving every new column **and the event digest chain**; a release with a marathon plus a non-member item renders the non-member outside the box; **baseline: auto-capture on activate with a non-empty manifest, NO capture (not zero) when the manifest is empty, `active→draft→active` preserves the original silently, explicit second capture refused, `releases add --status active` lands baseline-less, all-NULL-or-all-populated enforced, `releases baseline` fills the empty case, growth goes negative when cuts exceed additions, baseline fields survive a dump round trip, and the migration backfill flags `backfilled` not `observed`**; **cut → redial → cut on ONE release** (proves transition commands select the live row); **`releases migrate` upgrades a v2 fixture and is a no-op on a current DB; a rebuilt v2 dump reports v4, not v2; an interrupted migration leaves its journal and restores FK enforcement; dialing in with another release's marathon is refused** | **L** |
| 5 | `RELEASES-DB-FAQS.md` | document the model (currently zero freeze mentions — it never described the old one) | S |

**Denominator — DECIDED (r1 optional 3, adopted):** `itemsTotal = dialed_in + shipped`, **cut rows
excluded**. Today's viewer counts cut rows (Daybreak reads "10 items · 9 open" with one cut), which
contradicts Ballast's own prose that a cut *"reduced the manifest from 5 to 4 entries."* The
convention wins: the denominator must mean *committed work*, or "N of M" is not a commitment figure.
Cut items still render (as `deferred`), they just stop inflating the total.

**Exporter state mapping — pinned (r1 optional 2):** `manifest_cards()` currently branches on
`shipped` and `cut` only. `dialed_in` takes the branch `open` has today — queued/wip depending on
roadmap enrichment — and `shipped` renders the `done` marker, which the function already handles and
has simply never received.

## Sequencing

1. **Phase A — schema + verbs** (touchpoint 1, 4). Migration **004**, fixed allocation — GH-108 owns
   003 and neither renumbers, so this phase does NOT depend on 003 having landed first; a gap in the
   chain is fine. The duplicate-version validation rule ships in this phase.
2. **Phase B — exporter + viewer** (touchpoint 2). Closes #109 and surfaces shipped members.
3. **Phase C — prose** (touchpoint 3, 5). No code; the conversion of active/draft blocks and the
   preamble.

A stall after any phase leaves the repo coherent: A alone gives a correct DB with an unchanged
viewer; B alone adds honest rendering; C alone aligns the human file.

## Exit criterion

`manifest dial-in` refuses a task already dialed into another release, by name, citing the holding
release; `manifest ship --evidence` moves a member to shipped and Daybreak reports #79–#81 done
(closing #110); `manifest cut` then `dial-in` succeeds both on the same release and on another
(history never blocks re-homing); a marathon cannot be named by two releases; a v2 fixture upgrades
through the 003+004 chain in order; a merged dump carrying duplicate `schema_migrations.version`
values is refused; a pre-migration dump with `state='open'` still loads and maps to `dialed_in`; a
`check --rebuild` round trip preserves every new column **and leaves the manifest event digest chain
verifying**; the timeline renders a non-marathon manifest item outside the marathon box (closing
#109) and counts `dialed_in + shipped` only; **a release activated with a non-empty manifest captures
its baseline automatically and one activated empty captures none rather than zero, Daybreak carries a
backfilled baseline of 9 flagged `backfilled`, and the timeline shows progress plus growth for
baselined releases and progress alone for the rest**; no `Manifest: FROZEN` line remains on an active
or draft release, every shipped block still carries its original line verbatim, and
`test/gh308-frozen-twin-guard.sh` is untouched and green.

## Review status

**Round 1 (Aider · Qwen 3.8 Max) delivered seven blockers; all were verified against the live schema
and applied.** The verification round FAILED — the lane produced no findings and its salvage appended
~1,200 lines of raw reasoning to the relay file; the operator stopped the lane and the route is now
graded **C** for reviewer use in `HARNESS-MODELS-REGISTRY.md`. **The r1 fixes, and the baseline design
added after them, are therefore UNVERIFIED by any second reader.** Routing a verification round to
Codex is the outstanding recommendation.

## Review verdicts (Aider · Qwen 3.8 Max, r1 2026-08-20 — all five open items resolved)

1. **Candidate tier: NO for v1.** `dialed_in` is the commitment state; a pre-commitment tier can be
   added later without breaking this change. (Reviewer concurred with the plan.)
2. **Marathon pointer: do NOT invert.** Keep `releases.marathon_id` plus the partial unique index;
   `marathons.release_id` is conceptually cleaner but touches more code for no v1 gain. The lifecycle
   ambiguity the reviewer flagged is now stated explicitly above (links are permanent).
3. **`dial_reason`: keep it required** on new dial-ins — it carries the deliberateness the admission
   rule used to supply. Migrated rows stay NULL.
4. **Baseline counting: ADOPTED by the operator 2026-08-20**, with the reviewer concurring. Now a
   locked part of this plan — see "Measuring commitment growth" for the full design, including the
   kickoff-ordering hazard that the naive "snapshot on activate" rule would have walked into.
5. **Denominator: exclude cut items** — decided and folded into touchpoint 2 above.

## Still open for the operator

- **Where #108 lands** — unrelated to this plan's mechanics, but waiting on the same framing work.
