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
a CHECK constraint in place, and two of the changes below rewrite CHECK vocabularies. Both affected
tables use the standard 12-step procedure inside one transaction: create `*_new` with the final
shape, `INSERT … SELECT` with the state mapping applied, drop the old table, rename, then recreate
every index, trigger, and FK. `PRAGMA foreign_keys` off for the swap, `PRAGMA foreign_key_check`
before commit.

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

### Lifecycle rules the indexes imply (r1 B7 — state them, don't leave them emergent)

- **A `shipped` item MAY later be dialed into another release.** The partial index permits it and
  that is intended: a long-lived tracking issue can legitimately ship work in one release and more
  in a later one (#32 spans phases exactly this way).
- **Marathon links are historical and permanent.** A marathon is never re-linked to a second release,
  even after the first ships or is cut. A marathon is a release-scoped effort; reusing one across
  releases would make "which release ran this marathon" unanswerable.

### Dump / load / rebuild compatibility (r1 B4)

- Dump grammar: the three new `manifest_items` columns are appended to that record's field order,
  fixed, in the order listed above. Absent trailing fields read as NULL so a v3 dump still loads.
- `load_dump()` **accepts `state='open'` from older dumps and maps it to `dialed_in`** on the way in;
  it emits only the new vocabulary. Old dumps therefore stay loadable — required, because dumps are
  the git-merge surface and a colleague's branch may carry a pre-migration dump for weeks.
- `_rebuild()` applies the full migration chain (001 → 004) **before** loading, so the target schema
  exists no matter which dump version arrives.
- All three hard-coded column lists must learn the new fields (`releases_app.py:747-756`,
  `:2602-2612`, `:2649-2650`) — the same trap GH-108's review found.

### Migration-number allocation — mechanical, not conventional (r1 B5)

"Whoever lands second renumbers" was process, not a guard. Replaced by:

- **Allocation is fixed now: GH-108 owns 003, GH-111 owns 004.** Neither renumbers; whichever lands
  first simply leaves a gap the other fills.
- `validate_merged_dump()` gains a rule **refusing duplicate `schema_migrations.version` values** in
  a merged dump — the failure a git merge of two independently-numbered branches would otherwise
  produce silently.
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

## Measuring commitment growth (RECOMMENDED — operator has not ruled)

Freeze bought a fixed denominator, which is what made "N of M" honest. Dialed-in gives that up unless
something pins a baseline. Proposal: record `baseline_dialed_in_count` on the release when it goes
active, then report two numbers — **progress against commitment** and **commitment growth since
baseline**. That is strictly more information than freeze provided: scope creep becomes a measured
fact instead of something forbidden-then-worked-around.

This is my recommendation, not a locked decision. It is separable — the plan works without it, and it
can be added later without touching the state machine. Flagged for the operator, and for the review.

## Touchpoints

| # | Component | Change | Size |
|---|---|---|---|
| 1 | `utils/py/releases_app.py` | migration 004 as a **table rebuild** of BOTH `manifest_items` and `manifest_state_events` (CHECK vocabularies cannot be altered in place), plus the `releases` marathon index; wired into the chain + both dump directions + `load_dump()`'s `open`→`dialed_in` acceptance; `validate_merged_dump()` duplicate-version rule; `manifest dial-in` (renamed from `add`, `--reason` required), `manifest ship` (`--evidence`, stored as the NOT NULL event reason), `manifest cut` unchanged; transition legality enforced; state/event coupling preserved in ONE transaction per `:515-518` | **XL** |
| 2 | `utils/timeline/export_timeline.py` | group marathon members by the new `marathon_id`, non-members as siblings (#109); render `shipped` members with the done marker; denominator decision (below) | S+ |
| 3 | `RELEASES.md` | preamble rule rewritten; active/draft blocks converted; **shipped blocks untouched**; GH-308 "frozen twins" prose untouched | M (prose) |
| 4 | `test/gh32-releases-app.sh` (+ `test/gh69-roadmap-shadow.sh` where sync is involved) | transitions incl. illegal ones; exclusivity refusal (dial a task into a second release → refused **by name**, citing the holding release); cut-then-redial on the SAME release allowed (proves the dropped UNIQUE); cut-then-redial elsewhere allowed; shipped-then-dial-elsewhere allowed; marathon exclusivity; ship-without-evidence refused; **v2 fixture → 003+004 chain applied in order**; **merged dump with duplicate `schema_migrations.version` refused**; old dump carrying `state='open'` loads and maps; dump→rebuild round trip preserving every new column **and the event digest chain**; a release with a marathon plus a non-member item renders the non-member outside the box | **L** |
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
#109) and counts `dialed_in + shipped` only; no `Manifest: FROZEN` line remains on an active or draft
release, every shipped block still carries its original line verbatim, and
`test/gh308-frozen-twin-guard.sh` is untouched and green.

## Review verdicts (Aider · Qwen 3.8 Max, r1 2026-08-20 — all five open items resolved)

1. **Candidate tier: NO for v1.** `dialed_in` is the commitment state; a pre-commitment tier can be
   added later without breaking this change. (Reviewer concurred with the plan.)
2. **Marathon pointer: do NOT invert.** Keep `releases.marathon_id` plus the partial unique index;
   `marathons.release_id` is conceptually cleaner but touches more code for no v1 gain. The lifecycle
   ambiguity the reviewer flagged is now stated explicitly above (links are permanent).
3. **`dial_reason`: keep it required** on new dial-ins — it carries the deliberateness the admission
   rule used to supply. Migrated rows stay NULL.
4. **Baseline counting: reviewer says ADOPT** — losing freeze's fixed denominator is a real
   regression risk and a baseline makes scope growth measurable instead of forbidden. **Still
   pending the operator**, who has not ruled on this; a reviewer's concurrence is not an operator
   decision, and this plan does not treat it as one. Until then it stays a recommendation, and the
   plan is implementable without it.
5. **Denominator: exclude cut items** — decided and folded into touchpoint 2 above.

## Still open for the operator

- **Baseline counting** (item 4 above) — adopt, defer, or drop.
- **Where #108 lands**, unrelated to this plan but blocked behind the same framing question.
