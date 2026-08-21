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

## Schema changes (migration 004, after GH-108's 003)

1. `manifest_items.state` CHECK becomes `('dialed_in','shipped','cut')`; existing `open` rows
   migrate to `dialed_in`.
2. `manifest_items.dialed_in_at TEXT` — when this commitment was made (nullable for migrated rows;
   backfill from the release's creation where no better timestamp exists, and say so rather than
   inventing precision).
3. `manifest_items.dial_reason TEXT` — the case for the commitment.
4. `manifest_items.marathon_id INTEGER REFERENCES marathons(id)` — nullable; closes #109.
5. `CREATE UNIQUE INDEX … ON manifest_items(issue_ref_id) WHERE state = 'dialed_in'` — exclusivity.
6. Marathon exclusivity: `CREATE UNIQUE INDEX … ON releases(marathon_id) WHERE marathon_id IS NOT
   NULL` — a marathon belongs to at most one release. (Open item 2 asks whether the pointer should
   invert instead.)

**Every one of these must be carried by the canonical dump writer, `load_dump()`, and the rebuild
migration chain** — the same three hard-coded lists GH-108's review found (`releases_app.py:747-756`,
`:2602-2612`, `:2649-2650`). A dump→rebuild round trip preserving all new columns is a required test,
not an optional one.

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
- **Active and draft blocks** (Meter, Cargo, and any in-band release) convert to the dialed-in
  vocabulary.
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
| 1 | `utils/py/releases_app.py` | migration 004 (all six schema changes) wired into the chain + both dump directions; `manifest dial-in` (renamed, `--reason`), `manifest ship`, `manifest cut` unchanged; transition legality enforced; state/event coupling preserved in ONE transaction per `:515-518` | L |
| 2 | `utils/timeline/export_timeline.py` | group marathon members by the new `marathon_id`, non-members as siblings (#109); render `shipped` members with the done marker; denominator decision (below) | S+ |
| 3 | `RELEASES.md` | preamble rule rewritten; active/draft blocks converted; **shipped blocks untouched**; GH-308 "frozen twins" prose untouched | M (prose) |
| 4 | `test/gh69-roadmap-shadow.sh` + `test/gh32-releases-app.sh` | transitions incl. illegal ones; exclusivity refusal (dial a task into a second release → refused); cut-then-redial-elsewhere ALLOWED; marathon exclusivity; dump→rebuild round trip; a release with a marathon **plus** a non-member item renders the non-member outside the box | M |
| 5 | `RELEASES-DB-FAQS.md` | document the model (currently zero freeze mentions — it never described the old one) | S |

**Denominator question, unresolved in the current viewer:** Daybreak reads "10 items · 9 open" with
one cut item, while Ballast's prose says a cut *"reduced the manifest from 5 to 4 entries."* The
viewer counts cut rows; the convention does not. Pick one and pin it — recommend the convention
(denominator = dialed_in + shipped, excluding cut), since that is what makes the number mean
"committed work".

## Sequencing

1. **Phase A — schema + verbs** (touchpoint 1, 4). Migration 004 lands after GH-108's 003; if 003
   has not landed, this plan takes 003 and GH-108 takes 004. **The two must not both claim the same
   number** — whichever lands second renumbers, and its round-trip test is the proof.
2. **Phase B — exporter + viewer** (touchpoint 2). Closes #109 and surfaces shipped members.
3. **Phase C — prose** (touchpoint 3, 5). No code; the conversion of active/draft blocks and the
   preamble.

A stall after any phase leaves the repo coherent: A alone gives a correct DB with an unchanged
viewer; B alone adds honest rendering; C alone aligns the human file.

## Exit criterion

`manifest dial-in` refuses a task already dialed into another release, by name, with a reason
pointing at the holding release; `manifest ship` moves a member to shipped and Daybreak reports
#79–#81 done; `manifest cut` then `dial-in` elsewhere succeeds (history does not block re-homing); a
marathon cannot be named by two releases; a `check --rebuild` round trip preserves every new column;
the timeline renders a non-marathon manifest item outside the marathon box; no `Manifest: FROZEN`
line remains on an active or draft release, every shipped block still has its original line, and
`test/gh308-frozen-twin-guard.sh` is untouched and green.

## Open items for review

1. **Is a `candidate` tier wanted?** This plan says no — membership *is* the commitment. The
   alternative (candidate → dialed_in) buys a place to park "maybe" work without distorting the
   denominator. Argue it either way, but name the cost.
2. **Should the marathon pointer invert** (`marathons.release_id`) instead of constraining
   `releases.marathon_id`? Inverting is cleaner for "a marathon is dialed into a release" but touches
   more code.
3. **Is `dial_reason` worth the friction**, or does requiring a reason on every dial-in just
   recreate freeze ceremony under a friendlier name?
4. **Baseline counting** — adopt, defer, or drop?
5. **Denominator** — does it count cut items? (Recommendation above.)
