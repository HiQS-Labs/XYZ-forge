---
title: releases ledger roadmap layer never generalised to a vendored install
status: Active
created: 2026-08-31
updated: 2026-08-31
owner: Noel Saw
gh_issue: 349
source: https://github.com/HiQS-Labs/XYZ-forge/issues/349
doc_type: bugfix
complexity: 3
risk: 2
effort: 2
phases: 1
ratings_provisional: false
reported_from: LTVera-Pandas
harness_commit: 9d44be35
non_goals:
  - Fixing the reporting repo's own ROADMAP.md formatting or its undated releases — those are data
    problems in that repo, tracked in its own issue #322
  - Redesigning the rating system; item 4 asks only that the harness STATE which vocabulary wins
  - Adding a warning to `releases next` (recorded in the issue as out-of-scope, lower confidence)
related:
  - OPERATIONS.md in the reporting repo already records the sibling marathon-plan.sh parser bug as
    "flagged upstream, unresolved" — same root cause, different script
goal: >
  A vendored `.xyz/` install in any org can run `releases roadmap sync` against a link-style
  ROADMAP.md and get correct rows, with issue_url populated. A parse of zero entries from a
  non-empty ledger refuses instead of deleting. Canonical rating vocabulary is stated in
  RELEASES-DB-FAQS.md which ships with the vendored copy.
---

# GH-349 — releases ledger roadmap layer never generalised to a vendored install

## Status

| What was just completed | What's next |
|---|---|
| Phase 2: the reporting repo's review of PR #350 (LTVera-Pandas #322) found four parser defects, one of which broke `roadmap sync` on **this repo's own** `ROADMAP.md`. All four fixed; suite extended to 30/30; nine releases/roadmap suites green (375 assertions, 0 failures) | agy QA review of the full branch via `/relay-xyz`, then merge |

## Symptom

`releases roadmap sync` parses 0 of 51 entries from a vendored install's `ROADMAP.md`, deletes every
row in `roadmap_items`, and exits 0. Three related defects sit behind the same "written against this
repo's own conventions" root cause.

## Environment

- **Observed from:** `LTVera-Pandas` (vendored `.xyz/`)
- **Harness commit:** `9d44be35` (intake repo); vendored copy `c97f6176f53f`, vendored 2026-08-26
- **Worker/CLI:** n/a — `releases_app.py` invoked directly
- **Runtime:** Python (default; `XYZ_PYTHON` unset)
- **Sandbox:** off

## Reproduction

1. Vendor the harness into a repo whose `ROADMAP.md` uses `- [Title](path) — …` bullets rather than
   `- **Title**`.
2. Populate `roadmap_items` (any rows).
3. `python3 .xyz/utils/py/releases_app.py --root . roadmap sync --dry-run`

**Expected:** the parser reads the ledger's entries; or, failing that, the command refuses with a
non-zero exit rather than proposing to delete the table.
**Observed:** `roadmap sync: 0 in ROADMAP.md -> +0 added, ~0 updated, -4 removed, 0 unchanged`.
Without `--dry-run` the rows are deleted and the command exits 0.
**Frequency:** every time — deterministic.

## The four items & resolutions

1. **`parse_roadmap_ledger` now matches both `- **` and `- [Title](path)` bullets.** `cmd_roadmap_sync`
   now checks if `ROADMAP.md` has a non-empty ledger or if `roadmap_items` in the DB has existing rows,
   refusing with `rule=roadmap-empty-parse` rather than wiping the table.
2. **The issue-URL regex is un-hardcoded from this org.** Replaced with module-level `URL_EXTRACT_RE`
   matching any GitHub org/repo issue or PR URL (`https://github.com/[^/\s]+/[^/\s]+/(?:issues|pull|pulls)/[0-9]+`).
3. **Modification timestamps:** Clarified table timestamping model. Append-only tables (`op_receipts`,
   `manifest_state_events`, `schema_migrations`) carry immutable transaction timestamps (`at`, `applied_at`),
   while global and per-table state changes are tracked through generation counters and SHA-256 state digests.
4. **Canonical rating vocabulary documentation in vendored payload:** Added canonical rating grammar
   (`rated pri/sev/appeal/effort [ovr N]`) and axis definitions directly to `RELEASES-DB-FAQS.md`
   (which ships in vendored `.xyz/` for Tier 2) and updated citations in `releases_app.py`.

## Phase 1 — Implementation & QA

### Checklist
- [x] Fix `parse_roadmap_ledger` bullet extraction for `- [Title](path)`
- [x] Un-hardcode GitHub URL regex using org-agnostic `URL_EXTRACT_RE`
- [x] Add fail-safe refusal `rule=roadmap-empty-parse` in `cmd_roadmap_sync`
- [x] Add canonical rating documentation in `RELEASES-DB-FAQS.md`
- [x] Add regression test suite `test/gh349-releases-roadmap-vendored.sh`
- [x] Run Codex QA via `/relay-xyz`

## Phase 2 — Post-review hardening (LTVera-Pandas #322 review of PR #350)

The reporting repo re-ran its own probe against this branch and confirmed the headline fix: 51 of 51
entries parse from `LTVera-Pandas/ROADMAP.md` where `development` parsed 0. It also found four
defects in `parse_roadmap_ledger`, one blocking. All four are fixed here.

### 1. Blocking — the widened GH-key search broke `roadmap sync` on this repo's own ledger

Phase 1 replaced an anchored `^GH-(\d+)` match with a whole-title `re.search`. A GH number is a
**key**, not a mention, and the search harvested one out of titles that merely cite other issues.
Diffing this branch's parser against `origin/development` over this repo's own 72 bold-style
entries — where nothing should have changed — showed two:

| Title | base | Phase 1 |
|---|---|---|
| `#129/#130/#131 · Wave 1 of the Harness Driver` | `None` | `129` |
| `Execution checklist for GH-111 + GH-108` | `None` | `111` |

The second collides with the real `GH-111 · retire manifest FREEZE` entry, so `cmd_roadmap_sync`'s
`roadmap-duplicate-gh` guard refused outright — this branch could not sync the repo it ships from.

**Fix.** `_roadmap_gh_number()` reads the key only from the head of the title (`_ROADMAP_KEY_RE`),
and `_ROADMAP_MULTI_KEY_RE` returns `None` for umbrella titles naming several issues
(`#129/#130/#131`, `GH-42 + GH-43`). The `#N` prefix form is **kept** — the reporting repo has six
legitimate `#N — …` ledger titles, so dropping it would have lost six real keys.

### 2. `doc_path` was filled with a GitHub URL

The Phase 1 fallback accepted any link target, so five of the reporting repo's 51 rows stored an
issue URL in a column consumers resolve against the filesystem — a miss indistinguishable from a
dead pointer. `_is_doc_pointer()` now gates the fallback on a relative `.md` path. The
`PROJECT/…` match also regained tolerance for `#anchor` suffixes, which Phase 1 silently narrowed away.

### 3. `issue_url` took the first URL anywhere in the entry block

Unanchored `URL_EXTRACT_RE.search(raw)` keyed `GH-94` to a **different repository's** issue #2 and
`GH-68` to a PR, because both hooks cite other work in passing. Confirmed in this repo too:
`GH-61 · RELEASES ledger durability hardening` was keyed to issue **#62**, a child issue named in
its own hook. `_roadmap_issue_url()` now takes the bullet's own link target, or a URL corroborating
the entry's GH number, and otherwise stores nothing — no URL beats a wrong URL.

`(?:issues|pull|pulls)` in `URL_EXTRACT_RE` is deliberately **kept**: the pre-Phase-1 ledger regex
already accepted `pull`, and `test/gh349` pins external-org PR extraction. Anchoring, not narrowing,
is what fixes the mis-keying.

### 4. `- [` swallowed markdown task-list items

`- [ ]` / `- [x]` share the link-bullet prefix and parsed as rows with an empty or `x` title.
`_is_ledger_bullet()` excludes them, and the block-boundary scan now shares that one predicate
instead of restating it.

### Checklist
- [x] Anchor the GH key; refuse umbrella titles; keep the `#N` prefix form
- [x] Gate the `doc_path` fallback on a relative `.md` path
- [x] Anchor `issue_url` to the bullet's own link or a corroborating number
- [x] Exclude task-list checkboxes from ledger bullets
- [x] Extend `test/gh349-releases-roadmap-vendored.sh` (sections 6-7, now 30/30)
- [x] Pin this repo's own ROADMAP.md against duplicate keys inside the suite itself
- [x] Re-run the releases/roadmap suites: 9 suites, 375 assertions, 0 failures
- [ ] agy QA review of the full branch via `/relay-xyz`

### Verification

| Suite | Result |
|---|---|
| `test/gh349-releases-roadmap-vendored.sh` | 30 passed, 0 failed |
| `test/gh69-roadmap-shadow.sh` | 84 passed, 0 failed |
| `test/gh257-roadmap-ledger-fixes.sh` | all passed |
| `test/gh32-releases-app.sh` | 144 passed, 0 failed |
| `test/gh57-releases-fuzz.sh` | 42 passed, 0 failed |
| `test/gh153-releases-sidebar-rollup.sh` | 40 passed, 0 failed |
| `test/gh53-releases-merge-resolve.sh` | 15 passed, 0 failed |
| `test/pdda-roadmap-coverage.sh` | 11 passed, 0 failed |
| `test/roadmap-dashboard.sh` | 9 passed, 0 failed |
| `test/gh39-releases-project-sync.sh` | 4 passed, 0 failed |

### Known, out of scope

The reporting repo's `ROADMAP.md` carries **two** entries keyed `GH-199`, so `roadmap sync` there
still refuses with `roadmap-duplicate-gh`. That is a data condition in that repo, correctly named by
the existing guard, not a parser defect — it belongs to LTVera-Pandas #322's own remediation.

### Lessons Learned

A parser generalisation is only safe if it is diffed against the corpus it already served. Phase 1's
suite was green because it exercised only the new link format; the regression it introduced was
visible in one pass over this repo's own 72 existing entries. Section 7 of the suite now performs
exactly that pass on every run, so the ledger this harness ships with is itself a fixture.

