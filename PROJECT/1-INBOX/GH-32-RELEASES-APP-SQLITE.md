---
gh_issue: 32
source: https://github.com/HiQS-Suite/XYZ-forge/issues/32
title: "RELEASES app: SQLite-backed release ledger with CLI-only writes, generated RELEASES.md, and cross-repo UI"
status: Proposed (1-INBOX — not yet active)
created: 2026-08-18
doc_type: feedback
effort: 4
complexity: 3
risk: 2
phases: 5
---

# GH-32: RELEASES App — SQLite-Backed Release Ledger (PRD)

> Revised 2026-08-18 after a Codex (sol, high-reasoning) relay review
> (`relay-system/2026-08-18/gh32-releases-app-prd-review.md`) — 5 Blockers, 1 Should, all
> dispositioned in the relay thread. The largest corrections: enforcement claims are now honest about
> what SQLite can and cannot enforce, global IDs are 128-bit, the round-trip claim is qualified with
> a lossless legacy-line mechanism, and the committed-DB git story gained a writer lock and a tested
> conflict procedure.

## Problem

RELEASES.md discipline depends on prose rules and advisory checks (GH-28). Nothing structurally
prevents drift, and a device-wide survey (2026-08-18, 14 RELEASES.md files found) shows the drift is
already universal:

| Failure observed | Where | What it proves |
|---|---|---|
| Typo'd field names committed (`Shakdedown reviwed:`) | sleuth-app AND aegis-sleuth-slack-bot | Nothing validates field names; typos propagate by copy-paste |
| Ad-hoc field invention (`Deadline:` vs `Target Date:`, `Exit:` vs `Exit criterion:`, `Issues:` vs `Manifest:`, `Issues frozen:`, `Deploys:`, `Not in scope:`) | aegis, rebalanceOS | The "minimal fields" contract forks per repo with no mechanism to converge |
| `<!--test-->` blocks with fake data committed | sleuth-app, aegis | No write-time gate at all |
| Empty keys (`Release:` with no value, empty `GH_URL:`) | sleuth-app, aegis, cactus | Warn-only checks don't stop broken blocks landing |
| Contradictory conventions: aegis formally RETIRED `Iterations:` bands ("wrong 18 consecutive times") while XYZ-forge mandates them | aegis vs XYZ-forge | The per-repo prose contract has already diverged irreconcilably |
| Bare `#nnn` refs resolving to nothing (rebalanceOS's own header admits its issue numbers point at a retired tracker) | rebalanceOS | Manifests need full URLs, not repo-relative issue numbers |
| Version format drift (`v0.9.0` vs `0.7.0` vs `TBD`) | cactus vs others | No canonical version format |
| Prose bloat in Description/Exit-criterion fields | XYZ-forge (6 of 8 blocks, GH-28 scan) | Advisory length rules don't hold under pressure |
| Duplicate "Silverlining" block copy-pasted across two repos | sleuth-app + aegis | No cross-repo identity for a release |

Cross-repo visibility also doesn't exist: each ledger is an island, and "what's shipping next across
my repos" has no answer short of opening every file.

## Decisions (operator, 2026-08-18)

1. **DB is source of truth at runtime; RELEASES.md is generated.** A generator renders each repo's
   RELEASES.md as a read-only view (the ROADMAP-DASHBOARD.md pattern). Hand-edits are overwritten on
   next generation; that overwrite IS the enforcement. **Authority split, stated precisely** (review
   finding): the DB is authoritative for reads and writes at runtime; the committed logical dump
   (`releases.sql`, global-ID-keyed) is authoritative **at git merge boundaries only**, because git
   can merge text and cannot merge SQLite pages. On any DB↔dump divergence the consistency check
   fails and `releases check --rebuild` (dump → DB, atomic, with a `.bak` of the displaced DB) is the
   one documented recovery.
2. **Per-repo DB, committed to git.** Operator call. The dump is the diffable/mergeable git form; the
   conflict procedure is defined and tested (see Git story below).
3. **CLI is the only writer.** Enforcement claims are split honestly (review finding):
   **schema-enforced** = what SQLite genuinely refuses (uniqueness, FK integrity with
   `PRAGMA foreign_keys=ON` self-checked per connection, XOR and non-empty CHECKs, enum membership);
   **CLI-enforced** = everything else (status *transitions*, GH-28 length thresholds, URL
   reachability). The consistency check detects direct writes that bypassed the CLI (see audit
   receipts) — a bypass is caught, not prevented.
4. **V1 includes the cross-repo read-only UI.** Slack integration deferred (see Non-goals).

## Two new SOPs

1. **Every Release requires a tracking GH issue.** GH-28's `Tracking Issue:` field, promoted to a
   required reference: `releases.tracking_ref_id NOT NULL REFERENCES issue_refs(id)`.
2. **Every Marathon requires a tracking GH issue** (`marathons.tracking_ref_id NOT NULL`, same shape).
3. **GitHub-down fallback:** an `issue_refs` row may carry a temp ID (`TMP-` + 6 uppercase
   alphanumerics) instead of a URL — exactly one of the two, enforced by CHECK. `releases reconcile`
   fills in the real URL later (the row keeps its identity; nothing downstream changes). A registered
   check warns on temp refs older than 7 days.
4. **Migration placeholder (import-only, distinct from the GitHub-down fallback — r2 review
   finding):** legacy blocks predate the tracking-issue SOP and cannot satisfy `NOT NULL` at import.
   `releases import` — and only import; ordinary writes refuse the shape — may create `MIG-XXXXXX`
   placeholder refs, each recorded in the grandfather ledger. **The strict flip (Phase 2) requires
   zero surviving `MIG-` refs**: each is dispositioned to a real issue URL or the block is
   consciously retired. Same shape rules as TMP but a different prefix, so the two lifecycles
   (offline-wait vs migration-debt) can never be confused. Import also supplies recorded defaults for
   newly-required fields a legacy block omits (`status` from the block's `Status:` line, else
   `draft`; `description` from `Description:`, else a placeholder) — every such default is a
   grandfather-ledger entry, not a silent fill.

## Schema (v1)

**Global IDs: 128-bit, prefixed, immutable** (review finding — 8 hex chars was birthday-collision
territory across independent per-repo DBs that no local `UNIQUE` can police). Format:
`rel-`/`mar-`/`mfi-`/`ref-`/`repo-` + a 26-character ULID. Assigned at creation, never changed —
**identity, not a content hash** (a content hash would mutate on edit and break cross-repo
references; the Sundown 0.7.0 → 0.8.0 renumber is the recorded proof case). External addressing —
CLI (`--gid`), UI, and future links — uses the global ID, never the integer PK, which stays an
internal join key. The cross-repo aggregator **fails loudly** on any duplicate global ID rather than
merging silently.

```sql
PRAGMA foreign_keys = ON;   -- the CLI asserts this per connection and refuses to run without it

CREATE TABLE schema_migrations (
  version INTEGER PRIMARY KEY,
  applied_at TEXT NOT NULL
);

CREATE TABLE settings (            -- per-repo DB, so per-repo enforcement mode lives here
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);  -- rows: ('enforcement','lenient'|'strict'), ('repo_slug', ...)

CREATE TABLE repos (
  id INTEGER PRIMARY KEY,
  global_id TEXT NOT NULL UNIQUE CHECK (global_id GLOB 'repo-*'),
  slug TEXT NOT NULL UNIQUE CHECK (length(trim(slug)) > 0)
);  -- device-local paths deliberately NOT committed (review finding): the UI resolves local
    -- checkout paths from the utils/hq/ registry, which is already per-device.

CREATE TABLE issue_refs (          -- normalized issue reference: real URL XOR placeholder
  id INTEGER PRIMARY KEY,
  global_id TEXT NOT NULL UNIQUE,  -- exact-shape checked, see GID note below
  url TEXT UNIQUE CHECK (url IS NULL OR url GLOB 'https://github.com/*/issues/*'),
  temp_id TEXT UNIQUE CHECK (temp_id IS NULL OR
    temp_id GLOB 'TMP-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]' OR
    temp_id GLOB 'MIG-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]'),  -- MIG-: import-only (CLI-enforced)
  created_at TEXT NOT NULL,
  CHECK ((url IS NULL) != (temp_id IS NULL))   -- exactly one
);

CREATE TABLE marathons (
  id INTEGER PRIMARY KEY,
  global_id TEXT NOT NULL UNIQUE CHECK (global_id GLOB 'mar-*'),
  repo_id INTEGER NOT NULL REFERENCES repos(id),
  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
  status TEXT NOT NULL CHECK (status IN ('planned','running','done','escalated','abandoned')),
  created_at TEXT NOT NULL
);

CREATE TABLE releases (
  id INTEGER PRIMARY KEY,
  global_id TEXT NOT NULL UNIQUE CHECK (global_id GLOB 'rel-*'),
  repo_id INTEGER NOT NULL REFERENCES repos(id),
  version TEXT CHECK (version IS NULL OR length(trim(version)) > 0),
  codename TEXT,
  status TEXT NOT NULL CHECK (status IN ('draft','active','shipped','cut')),
  target_date TEXT CHECK (target_date IS NULL OR target_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
  shipped_date TEXT CHECK (shipped_date IS NULL OR shipped_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
  description TEXT NOT NULL CHECK (length(trim(description)) > 0),
  exit_criterion TEXT,
  tracking_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
  marathon_id INTEGER REFERENCES marathons(id),
  gh_release_url TEXT,
  milestone TEXT,
  front_door_reviewed TEXT CHECK (front_door_reviewed IN ('Yes','No') OR front_door_reviewed IS NULL),
  shakedown_reviewed  TEXT CHECK (shakedown_reviewed  IN ('Yes','No') OR shakedown_reviewed  IS NULL),
  license_file        TEXT CHECK (license_file        IN ('Yes','No') OR license_file        IS NULL),
  UNIQUE (repo_id, version)
);

CREATE TABLE manifest_items (
  id INTEGER PRIMARY KEY,
  global_id TEXT NOT NULL UNIQUE CHECK (global_id GLOB 'mfi-*'),
  release_id INTEGER NOT NULL REFERENCES releases(id),
  issue_ref_id INTEGER NOT NULL REFERENCES issue_refs(id),
  state TEXT NOT NULL CHECK (state IN ('open','shipped','cut')),
  UNIQUE (release_id, issue_ref_id)
);

CREATE TABLE manifest_state_events (   -- append-only re-scope trail (review finding: the old
  id INTEGER PRIMARY KEY,              -- single overwriteable state_changed cell lost history)
  item_id INTEGER NOT NULL REFERENCES manifest_items(id),
  from_state TEXT NOT NULL CHECK (from_state IN ('open','shipped','cut')),
  to_state   TEXT NOT NULL CHECK (to_state   IN ('open','shipped','cut')),
  at TEXT NOT NULL,
  reason TEXT NOT NULL CHECK (length(trim(reason)) > 0)   -- a cut without a reason is refused
);
-- Append-only is enforced by triggers, not convention (r2 review finding):
CREATE TRIGGER mse_no_update BEFORE UPDATE ON manifest_state_events
  BEGIN SELECT RAISE(ABORT, 'manifest_state_events is append-only'); END;
CREATE TRIGGER mse_no_delete BEFORE DELETE ON manifest_state_events
  BEGIN SELECT RAISE(ABORT, 'manifest_state_events is append-only'); END;
-- (same trigger pair on op_receipts). Transition LEGALITY and the item-state/event coupling are
-- CLI-enforced, stated as such: the CLI updates manifest_items.state and appends the event in ONE
-- transaction; a direct writer that skips the event is caught by the digest chain below, not
-- prevented.

CREATE TABLE doc_lines (               -- document-level verbatim preservation (r2: the 86-line
  id INTEGER PRIMARY KEY,              -- preamble is release-less; legacy_lines can't hold it)
  repo_id INTEGER NOT NULL REFERENCES repos(id),
  position INTEGER NOT NULL,           -- ordering among document-level segments
  content TEXT NOT NULL,
  UNIQUE (repo_id, position)
);

CREATE TABLE legacy_lines (            -- lossless import: unmapped/continuation lines, verbatim
  id INTEGER PRIMARY KEY,
  release_id INTEGER NOT NULL REFERENCES releases(id),
  position INTEGER NOT NULL,
  content TEXT NOT NULL,
  disposition TEXT,                    -- NULL = pending; else 'kept'|'migrated'|'dropped:<why>'
  UNIQUE (release_id, position)
);

CREATE TABLE op_receipts (             -- append-only CLI operation log (append-only via the same
  id INTEGER PRIMARY KEY,              -- trigger pair as manifest_state_events)
  op TEXT NOT NULL,
  target_gid TEXT,
  at TEXT NOT NULL,
  txn_id TEXT NOT NULL,                -- one per CLI transaction
  dump_digest_before TEXT NOT NULL,    -- sha256 of the canonical dump before/after this txn:
  dump_digest_after TEXT NOT NULL      --   `check` recomputes the current dump digest; a digest
);                                     --   matching no receipt's `after` = receipt-less mutation
```

**GID shape note (r2 review finding — prefix-only GLOBs were theater):** every `global_id` CHECK is
an exact-shape test: the type prefix plus exactly 26 characters of the Crockford base32 alphabet
(`[0-9A-HJKMNP-TV-Z]`), written out in full in the migration (elided above for readability). Length
and alphabet are schema-refused, not convention.

Deliberately absent (survey-informed): `Iterations:` bands as schema (aegis proved them harmful;
imported bands are preserved via `legacy_lines` and re-rendered verbatim, so XYZ-forge keeps its
bands without the schema blessing them), free-text status values, narrative columns.

## Duplication guard (light touch — operator, 2026-08-18)

- **Structural (refused at write time, both modes):** `UNIQUE(repo_id, version)` and
  `UNIQUE(release_id, issue_ref_id)` — exact dupes within a repo/release cannot land.
- **Same manifest issue in >1 non-cut release** → **warn, never refuse.** Legitimate during handoffs
  (Meter's five entries moving to Sundown is the recorded precedent); flags for a human instead of
  blocking the transfer.
- **Same codename across repos** (aggregator + `releases check`) → **warn** — the "Silverlining
  copy-pasted into two repos" case from the survey.
- Identical behavior in lenient and strict mode: cross-release/cross-repo duplication is a smell,
  not always a defect, so it never gets refusal teeth.

## Git story — committed DB without a race (review finding)

A SQLite transaction serializes the DB file only; it says nothing about the dump and the generated
Markdown. With 2-3 live sessions routinely on this clone, the multi-artifact write needs its own
serialization:

1. **One repo-scoped writer lock**, resolved through the **git common-dir** — never a literal
   `.git/releases-app.lock` path, because in a linked worktree `.git` is a file (r2 review finding).
   Reuse the repo's existing GH-448 shared lock-path resolver idiom (`driver_lock_path`), which
   already handles all three repo shapes. Held across the whole write: BEGIN → mutate → COMMIT →
   stage dump + Markdown to temp names → journal → atomic renames → bump generation → release lock.
2. **Reader consistency via a generation marker** (r2: readers previously had a torn window between
   DB COMMIT and the renames): every committed write ends by bumping a `generation` value stored in
   `settings` AND stamped into the dump and the generated file. A reader (UI, `check`) that sees
   mismatched generations across the trio retries briefly, then reports "write in progress or
   crashed" — it never treats a torn trio as truth.
3. **Crash recovery journal:** staged outputs are written under temp names first, then a one-line
   journal records the intended renames, then the renames execute, then the journal clears.
   `releases check` finding a journal completes the renames (all staged files exist) or discards the
   stage (they don't) — recovery is defined at every boundary, and the DB-committed operation is
   never discarded by recovery (r2: rebuild-from-dump as sole recovery could lose the committed txn).
4. **Stale-artifact refusal:** a leftover `-wal`/`-journal`, a live recovery journal, or a
   generation-mismatched trio fails `releases check` loudly; no new write proceeds over a dirty state.
5. **Canonical dump grammar** (r2: "global-ID-keyed" was underspecified for rows without GIDs):
   GID-bearing rows are keyed by `global_id`. Non-GID rows are keyed by parent GID + a stable ordinal
   (`manifest_state_events`/`legacy_lines`/`doc_lines`: parent GID or repo slug + `position`/event
   order; `op_receipts`: `txn_id`; `settings`/`schema_migrations`: their natural keys). Integer PKs
   and FK ids never appear in the dump; rebuild renumbers them deterministically.
6. **Merge conflict procedure (tested, not aspirational):** conflicts are resolved in the logical
   dump per the grammar above; then `releases check --rebuild` reconstructs the DB atomically,
   backing up the displaced DB to `releases.db.bak`.
7. **Negative controls (acceptance):** crash injected at each rename boundary recovers per (3);
   a concurrent-branch merge of two divergent dumps rebuilds cleanly with both sides' rows present.

## Flexibility contract — this may become PDDA's home (operator, 2026-08-18)

1. **Global IDs on every referenceable row.** Anything can reference anything later — a future PDDA
   capture-doc row pointing at a release, a marathon pointing at a working doc — via a future
   `links(from_gid, to_gid, kind)` table, without redesigning any existing table.
2. **Additive-only migrations**, tracked in `schema_migrations`. New tables and nullable columns are
   always safe; renames/repurposes are forbidden (a new column supersedes an old one, retired by a
   later migration once nothing reads it).
3. **What flexibility does NOT mean:** no EAV/attribute tables, no JSON-blob columns, no speculative
   PDDA tables in v1. Generic-everything schemas are themselves the corner — they trade write-time
   validation (this project's entire point) for imagined future ease.

## CLI (v1) — `utils/py/releases_app.py`, Python-only per GH-551 rails

```
releases init                          # create DB + dump in this repo; settings default lenient
releases import <RELEASES.md>          # ONE-SHOT legacy import (Phase 0): every violation that
                                       #   lenient mode tolerates is recorded as a grandfathered
                                       #   entry (what, which rule, block) requiring later
                                       #   disposition; unmapped lines land in legacy_lines
releases add|update --gid <id> ...     # validated writes; refusal/warning names the rule
releases ship --gid <id> --evidence "<exit-criterion run cite>"
releases manifest add|cut --gid <id> <issue-url|TMP-XXXXXX> [--reason ...]  # cut REQUIRES a reason
releases marathon add|list ...         # v1 CRUD (review finding: no writeless tables in v1)
releases list [--all-repos] [--status ...]
releases gen [--side-by-side]          # Phase 0: writes RELEASES.generated.md + drift report only
releases check [--rebuild]             # DB<->dump<->generated consistency; FK pragma; stale WAL;
                                       #   receipt-vs-change bypass detection; temp-ref staleness;
                                       #   duplication warnings
releases reconcile [--map TMP-X=url]   # fill real URLs into temp refs
```

Write-time rules, split by mode (review finding — the old "lenient" was self-contradictory):

| Rule class | strict | lenient |
|---|---|---|
| Structural (URL/temp-ID shape, enums, uniqueness, FK integrity, non-empty, cut-needs-reason) | refuse | **refuse** — lenient tolerates *imported legacy debt*, never *new corruption* |
| GH-28 thresholds (description ≤4 sentences, exit criterion ≤~1000 chars) on **new/edited** rows | refuse | warn and write |
| Grandfathered legacy violations (recorded by `import`) | n/a — must be dispositioned before strict flip | tolerated, tracked |

## Generator contract (round-trip claim, qualified — review finding)

The original "zero-change, byte-stable" claim was false against the real file: the schema had nowhere
to keep `Iterations:`, the QA fields, `Shipped:` prose, or Sundown's continuation paragraphs, and
`pdda-lib.sh`'s parser consumes several of those positionally while `test/ballast-release.sh` Half A
requires `Manifest-Members:`. Corrected contract:

- **Explicit lossless mapping** for every label in the current contract: schema-backed fields render
  from columns **preserving each block's original field order and lexical spelling** (import records
  per-block field order; the generator replays it); `Manifest-Members:` is **generated** from
  `manifest_items`; the document-level preamble and inter-block separators import into `doc_lines`
  (r2 — `legacy_lines` is release-scoped and could not hold the 86-line preamble); everything else
  unmapped (continuation paragraphs, `Iterations:` bands, ad-hoc fields) imports into `legacy_lines`.
  Both re-render **verbatim, in original order**, until dispositioned.
- **Byte-for-byte fixture** on THIS repo's current RELEASES.md: import → generate must reproduce the
  file **exactly, with NO generated header during Phase 0** (r2 — a header plus byte-equality was
  self-contradictory). The header is added only at the Phase 2 flip, at which point the fixture is
  re-pinned to the header-bearing form. Registered alongside focused assertions for
  `pdda.sh releases`, `pdda.sh releases-current`, and `ballast-release.sh` Half A.
- **The compatibility claim is READ-consumer compatibility only** (r2 — `/releases` is not just a
  reader: its clean/plan/anchor/publish routes patch RELEASES.md directly, which collides with
  CLI-only writes). **Phase 2 entry gate:** every `/releases` mutating route is migrated to call
  this CLI (the skill keeps its preview-and-confirm UX; the write goes through `releases ...`), and
  the skill doc is updated, BEFORE the file flips to generated. Until then `/releases` mutations are
  part of the legacy write path Phase 0 tolerates.
- Bare-number manifests in sibling repos (`#nnn`) import as `legacy_lines` when unresolvable — the
  rebalanceOS case, where the numbers point at a retired tracker, is precisely why they cannot be
  auto-converted to URLs.

## Cross-repo UI (v1, read-only)

Extend the GH-480 VSCode cockpit's Releases card: aggregate registered repo DBs (repo discovery and
local paths via the `utils/hq/` registry — paths are per-device and not in the committed DB). Shows
upcoming releases across repos by target date, status, manifest completion, tracking-issue links.
Read-only. Duplicate global IDs across DBs fail the aggregation loudly.

## Non-goals (v1, recorded so they are not silently absorbed)

- **Slack read-only queries** via aegis-sleuth-slack-bot — v2.
- **Slack-launched headless marathon sessions** — remote-execution trigger; own issue, threat model,
  and design review before any build.
- **Marathons running off this system** (operator-flagged direction) — v3, own issue. The v1
  `marathons` table + CRUD is the data home; the evolution is drivers reading/writing the DB,
  `MARATHON.yaml` becoming generated output, Slack-launch reducing to "insert a row, driver picks it
  up." Deferred because it touches `relay-automation/` driver surfaces (`full_required` in CI
  routing) — the biggest-blast-radius phase of the arc.
- **Migration of sibling repos' ledgers** — the survey table is the worklist, not v1 scope.
- **Editing UI** — the CLI is the writer; the UI reads.

## Phases

0. **Transition dogfood in THIS repo (lenient mode)** — schema + CLI land; `releases import` brings
   the current ledger in with every tolerated violation recorded as a grandfathered entry;
   post-import writes follow the mode table above (structural rules strict even in lenient);
   generator runs **side-by-side only** (`RELEASES.generated.md` + drift report; the real file
   untouched — current consumers see zero change). **Exit gate (r1+r2 review findings — quiet weeks
   are not evidence, and rare operations must not be manufactured):** a **minimum 2-week window**
   during which `op_receipts` shows ≥10 accepted real write transactions originating from **≥2
   distinct sessions**, including **one witnessed lock-contention case** (second writer correctly
   refused/retried); the everyday operation classes (`add`, `update`, `manifest add`, `gen`,
   `check`) each exercised on real work; **rare/destructive operations** (`ship` when no release
   actually ships, `reconcile` when GitHub never went down, `check --rebuild`) exercised in
   **disposable fixture DBs**, not manufactured in the real ledger; the side-by-side byte-fixture
   green; the grandfather ledger (including every `MIG-` placeholder) fully dispositioned.
   Zero-change days count for nothing.
1. **Schema + CLI + dump discipline** — mechanical acceptance for what Phase 0 builds: registered
   consistency test with negative control, temp-ref lifecycle, writer-lock/preimage behavior under a
   simulated concurrent writer.
2. **Flip** — RELEASES.md becomes generated output with the machine-generated header; this repo
   switches to `strict`. Consumers re-verified green.
3. **Cross-repo UI** — cockpit card reads ≥2 registered DBs. Since sibling rollout is Phase 4, the
   two-repo proof uses **two disposable fixture repos** registered in a test copy of the hq registry
   (review finding — no hidden Phase-4 dependency).
4. **Sibling-repo rollout** — the survey worklist, repo-by-repo, each with its own issue and its own
   lenient transition window.

## Acceptance Criteria (v1 = phases 0-3)

- [ ] **Phase 0:** import grandfathers legacy violations with recorded dispositions; a structurally
      corrupt write is refused even in lenient; side-by-side generation reproduces the current
      ledger byte-for-byte via `legacy_lines`; exit gate met per the receipts + exercised-operation
      matrix above.
- [ ] `PRAGMA foreign_keys=ON` asserted per connection; consistency check registered in `validate.sh`
      and observed failing on: a deliberate DB↔dump divergence, a stale `-wal`, a receipt-less direct
      write, and a duplicate global ID across two fixture DBs (four negative controls).
- [ ] Strict-mode refusals name the violated rule; GH-28 thresholds refuse in strict / warn in
      lenient; manifest cut without a reason refused in both modes.
- [ ] Temp-ref lifecycle: offline create → `reconcile` → 7-day staleness warning (mocked clock).
- [ ] Writer lock + preimage check demonstrated against a simulated concurrent writer; merge
      procedure tested: conflicting dumps merged by global ID, DB rebuilt atomically with `.bak`.
- [ ] Duplication guard: exact dupes refused; shared-manifest-issue and cross-repo-codename cases
      observed warning (not refusing).
- [ ] Cockpit card renders releases from 2 fixture repo DBs sorted by target date, read-only, and
      fails loudly on an injected duplicate global ID.
