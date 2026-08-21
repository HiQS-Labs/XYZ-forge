---
gh_issue: 111
source: https://github.com/HiQS-Suite/XYZ-forge/issues/111
title: "Execution checklist — GH-111 (dialed-in) and GH-108 (rating system) to done"
status: Active (2-WORKING as of 2026-08-20)
created: 2026-08-20
updated: 2026-08-20
owner: noelsaw1
doc_type: checklist
rating: "pri/sev/appeal/effort 85/50/60/40 · calc 235"
goal: >
  One running list covering every remaining deliverable in the two plans, in dependency order,
  so a stall at any point leaves the next move unambiguous.
---

# Execution checklist — GH-111 + GH-108

Plans: [GH-111-DIALED-IN.md](GH-111-DIALED-IN.md) · [GH-108-RATING-SYSTEM.md](GH-108-RATING-SYSTEM.md)

Branch: `feat/gh111-phase-a-dialed-in` (clone `XYZ-forge-gh108-rating-system`).

Legend: `[x]` landed and green · `[~]` in progress · `[ ]` not started.

## GH-111 Phase A — schema + verbs

- [x] A0 Migration registry (`MIGRATIONS`, `registry_versions`, `pending_versions`,
      `apply_migrations(stamp_ledger=)`) replacing the hardcoded if-chain
- [x] A1 Migration 004 — table rebuild of `manifest_items` + `manifest_state_events`, the
      `releases` baseline columns, both partial unique indexes, backfill of active releases
- [x] A2 `manifest dial-in` / `add` alias, exclusivity refusal (`dialed-in-elsewhere`),
      `--marathon` validation (`marathon-not-this-release`), `--reason`
- [x] A3 `manifest ship --evidence` (closes #110); `_live_manifest_item()` state predicate
- [x] A4 `perform_migration()` + `releases migrate` verb (FK pragma bracketed outside `BEGIN`,
      `PRAGMA foreign_key_check` gate, journal left on error, idempotent no-op)
- [x] A5 Dump grammar: three new `manifest_items` columns + three new `releases` columns in the
      dump writer and `load_dump()`; `state='open'` accepted and mapped on load
- [x] A6 `_rebuild()` registry ledger ownership — DDL from the registry, `load_dump()` skips
      `schema_migrations`, `_rebuild()` stamps exactly the registry versions
- [x] A7 `validate_merged_dump()` duplicate-`schema_migrations.version` refusal
- [x] A8 Baseline: auto-capture on `draft → active` when the manifest is non-empty, silent skip
      on re-activation, `releases baseline` verb (write-once refusal), all-NULL-or-all-populated
- [x] A9 `releases.marathon_id` immutable while manifest items reference it
- [x] A10 gh32 tests for A4–A9 incl. the GH-111-first {1,2,4} fixture through BOTH entry points,
      failure injection, cut→redial→cut, digest chain across the rebuild

## GH-108 Phase A — parser + columns

- [x] B1 Migration 003 — five nullable `rating_*` columns on `roadmap_items`, transaction-safe,
      registered in the shared registry
- [x] B2 `rated N/N/N/N` + optional ` ovr N` parser in `roadmap sync`; named refusals for every
      malformed shape; both-vocabularies-on-one-entry refusal; legacy→rated transition NULLs the
      legacy columns
- [x] B3 Dump grammar for the five rating columns (writer + `load_dump()`)
- [x] B4 gh69 tests for the parser contract and the dump round trip

## GH-111 Phase B — exporter + viewer

- [x] C1 Group marathon members by `manifest_items.marathon_id`; non-members render as siblings
      (closes #109)
- [x] C2 Render `shipped` members with the done marker; `dialed_in` takes today's `open` branch
- [x] C3 Denominator `dialed_in + shipped`, cut excluded
- [x] C4 Emit `baseline: {count, at, source}` + derived growth; baseline-less releases show
      progress only
- [x] C5 Viewer renders the baseline/growth pair

## GH-108 Phase B — exporter + viewer

- [x] D1 Select the rating columns into the roadmap index; map to card `metrics` + `override`;
      derive `calc` and `effectiveScore`
- [x] D2 Join detour cards to the GH-keyed roadmap index (Codex r4)
- [x] D3 `--json` stdout flag
- [x] D4 `sev >= 80` hot flag
- [x] D5 `RELEASES.html`: `app` → `appeal` rename + `effort` in BOTH metric loops; legend flip in
      the same commit as first metric emission

## Phase C — prose

- [ ] E1 `RELEASES.md` preamble rule rewritten; active/draft blocks converted; shipped blocks and
      GH-308 frozen-twin prose untouched
- [ ] E2 `RELEASES-DB-FAQS.md` documents the dialed-in model
- [ ] E3 Intake template / PDDA scaffold: cx/risk/eff → the rating line
- [ ] E4 ROADMAP.md active-window backfill (~12 items)

## GH-108 Phase D — leaderboard

- [x] F1 `utils/leaderboard.sh` consuming `--json`, sorting on `effectiveScore` (one scorer)
- [x] F2 Generated `LEADERBOARD.md`, idempotent
- [x] F3 `view` field + leaderboard rendering in the shared template; `--leaderboard` bakes
      `LEADERBOARD.html`
- [x] F4 Two-way cross-link in `.top` (never `#fbar` — it collapses)
- [x] F5 GH-106 hook refreshes both artifacts
- [x] F6 Tests: ranking matches the pinned `--json` command exactly; a rated detour ranks

## Closeout

- [ ] G1 Full releases + timeline + pdda suites green
- [ ] G2 CHANGELOG entries
- [ ] G3 Plans moved to `PROJECT/3-COMPLETED`, ROADMAP pointers updated
- [ ] G4 #109, #110 closed with pointers; #108, #111 closed
