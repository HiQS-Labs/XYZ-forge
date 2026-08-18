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
phases: 4
---

# GH-32: RELEASES App — SQLite-Backed Release Ledger (PRD)

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

1. **DB is source of truth; RELEASES.md is generated.** A generator renders each repo's RELEASES.md
   as a read-only view (the ROADMAP-DASHBOARD.md pattern). Existing consumers — `pdda.sh releases`,
   `test/ballast-release.sh`'s ledger cross-check, the `/releases` skill — keep reading the generated
   file unchanged. Hand-edits are overwritten on next generation; that overwrite IS the enforcement.
2. **Per-repo DB, committed to git.** Operator call, accepting the binary-diff tradeoff.
   **Mitigation (spec'd, required):** a deterministic text dump (`releases.sql`, stable ordering) is
   committed alongside as the git-diffable/mergeable form. A registered check fails when DB and dump
   diverge. Merge conflicts are resolved in the dump; the DB is rebuilt from it (`releases check
   --rebuild`).
3. **CLI is the only writer.** Validation happens at write time — a malformed manifest URL, a missing
   tracking issue, an over-length description are refused at the source, not flagged after landing.
4. **V1 includes the cross-repo read-only UI.** Slack integration deferred (see Non-goals).

## Two new SOPs (enforced by schema, not prose)

1. **Every Release requires a tracking GH issue** (`tracking_issue_url NOT NULL`). This is GH-28's
   `Tracking Issue:` field, promoted from optional doc convention to schema constraint. Release-level
   status notes and run logs live on that issue — the DB holds pointers and enums, never narrative.
2. **Every Marathon requires a tracking GH issue** (`marathons.tracking_issue_url NOT NULL`).
3. **GitHub-down fallback:** temp alphanumeric IDs (`TMP-` + 6 uppercase alphanumerics) satisfy the
   constraint when GitHub is unreachable. Recorded in `temp_ids` with a created-at stamp;
   `releases reconcile` lists unreconciled temp IDs and swaps in real URLs interactively or via
   `--map TMP-XXXXXX=<url>`. A registered check warns on temp IDs older than 7 days.

## Schema (v1)

```sql
CREATE TABLE repos (
  id INTEGER PRIMARY KEY,
  slug TEXT NOT NULL UNIQUE,          -- e.g. "HiQS-Suite/XYZ-forge"
  local_path TEXT                      -- device-local; informational for the UI
);

CREATE TABLE marathons (
  id INTEGER PRIMARY KEY,
  repo_id INTEGER NOT NULL REFERENCES repos(id),
  tracking_issue_url TEXT NOT NULL,    -- real URL or TMP-XXXXXX
  status TEXT NOT NULL CHECK (status IN ('planned','running','done','escalated','abandoned')),
  created_at TEXT NOT NULL
);

CREATE TABLE releases (
  id INTEGER PRIMARY KEY,
  repo_id INTEGER NOT NULL REFERENCES repos(id),
  version TEXT,                        -- nullable: "recorded, never reserved" repos use NULL until ship
  codename TEXT,
  status TEXT NOT NULL CHECK (status IN ('draft','active','shipped','cut')),
  target_date TEXT,                    -- ISO date or NULL
  shipped_date TEXT,
  description TEXT NOT NULL,           -- CLI enforces <=4 sentences at write time
  exit_criterion TEXT,                 -- one runnable command/observable; CLI enforces length
  tracking_issue_url TEXT NOT NULL,    -- SOP 1; real URL or TMP-XXXXXX
  marathon_id INTEGER REFERENCES marathons(id),
  gh_release_url TEXT,                 -- the GH Release object, once published
  milestone TEXT,
  UNIQUE (repo_id, version)
);

CREATE TABLE manifest_items (
  id INTEGER PRIMARY KEY,
  release_id INTEGER NOT NULL REFERENCES releases(id),
  issue_url TEXT NOT NULL,             -- FULL URL; foreign sibling-repo issues are first-class
  state TEXT NOT NULL CHECK (state IN ('open','shipped','cut')),
  state_changed TEXT,                  -- dated re-scope trail, replacing narrative in Manifest: prose
  UNIQUE (release_id, issue_url)
);

CREATE TABLE temp_ids (
  temp_id TEXT PRIMARY KEY,            -- TMP-XXXXXX
  kind TEXT NOT NULL CHECK (kind IN ('release','marathon','manifest_item')),
  created_at TEXT NOT NULL,
  reconciled_url TEXT                  -- NULL until reconciled
);
```

Deliberately absent (survey-informed): `Iterations:` bands (aegis proved them harmful; repos that
want them keep them in the generated file's header prose, not the schema), free-text status values,
narrative fields. QA gates (`Front-door reviewed` etc.) deferred to a v2 `release_checks` table if
demand shows up — YAGNI for v1.

## CLI (v1) — `utils/py/releases_app.py`, Python-only per GH-551 rails

```
releases init                          # create DB + dump in this repo
releases add|update <version|--id N> --field value ...   # validated writes; refusal names the rule
releases ship <version> --evidence "<exit-criterion run cite>"
releases manifest add|cut <version> <issue-url>          # cut records state_changed, never deletes
releases list [--all-repos] [--status draft|active]
releases gen                           # regenerate RELEASES.md + releases.sql (byte-stable)
releases check [--rebuild]             # DB<->dump<->generated-file consistency; --rebuild from dump
releases reconcile [--map TMP-X=url]   # swap temp IDs for real URLs
```

Write-time validation (the GH-28 rubric, now refusals instead of warnings): description ≤4 sentences,
exit criterion ≤~1000 chars, manifest items are well-formed `https://github.com/<org>/<repo>/issues/N`
URLs or registered temp IDs, status transitions legal (draft→active→shipped; anything→cut only via
`manifest cut` with a reason).

## Generator contract

- Byte-stable: same DB → identical file, so `releases check` can diff cheaply and the pre-push docs
  gate sees no churn.
- Emits the existing block format XYZ-forge's parsers already read (`Release:`, `Status:`,
  `Manifest-Members:`, etc.) so `pdda.sh releases`, `ballast-release.sh` Half A, and `/releases`
  keep working with zero changes in v1.
- A generated-file header line marks it machine-generated and names the CLI, so agents stop
  hand-editing (and the overwrite makes hand-edits futile anyway).

## Cross-repo UI (v1, read-only)

Extend the GH-480 VSCode cockpit's Releases card: aggregate every registered repo's committed DB
(discovery via the `utils/hq/` repo registry, which already knows the device's repos). Shows
upcoming releases across repos sorted by target date, with status, manifest completion counts, and
tracking-issue links. Read-only — the card never writes.

## Non-goals (v1, recorded so they are not silently absorbed)

- **Slack read-only queries** ("what's shipping next") via aegis-sleuth-slack-bot — v2.
- **Slack-launched headless marathon sessions** — the long-term goal, explicitly deferred: it is a
  remote-execution trigger and needs its own issue, threat model, and design review before any build.
- **Migration of sibling repos' existing ledgers** — v1 ships in XYZ-forge only; the survey table
  above is the migration worklist, not v1 scope.
- **Editing UI** — the CLI is the writer; the UI reads.

## Relationship to GH-28

GH-28's advisory checks are the interim fix on the markdown ledger and land first — its
`Tracking Issue:` field is this schema's `tracking_issue_url`, and its validated thresholds
(4-sentence description, ~1000-char exit criterion) become this CLI's write-time refusals. Once the
generator owns RELEASES.md, GH-28's parser-side detection becomes redundant by construction.

## Phases

1. **Schema + CLI + dump discipline** — `releases init/add/update/ship/manifest/list/check/reconcile`,
   registered consistency test, temp-ID SOP working end-to-end.
2. **Generator + XYZ-forge migration** — import this repo's current RELEASES.md into the DB,
   byte-compare generated output, flip the file to generated with the machine-generated header.
   Existing consumers verified green (pdda releases, ballast-release Half A, /releases skill).
3. **Cross-repo UI** — GH-480 cockpit Releases card reads all registered repo DBs.
4. **Sibling-repo rollout** — migrate the survey's worklist repo-by-repo (each gets its own issue).

## Acceptance Criteria (v1 = phases 1-3)

- [ ] Schema created via CLI `init`; DB + `releases.sql` dump committed; consistency check registered
      in `validate.sh` and observed failing on a deliberate divergence (negative control).
- [ ] All writes refused outside the CLI's validation rules, with each refusal naming the violated
      rule; the GH-28 thresholds enforced at write time.
- [ ] Temp-ID lifecycle demonstrated: create while offline-simulated, `reconcile` swaps to real URL,
      staleness warning observed at the 7-day boundary (mocked clock).
- [ ] Generator is byte-stable and XYZ-forge's RELEASES.md round-trips: import → generate →
      existing consumers (pdda releases, ballast-release Half A) still green.
- [ ] Cockpit card renders releases from ≥2 registered repo DBs sorted by target date, read-only.
