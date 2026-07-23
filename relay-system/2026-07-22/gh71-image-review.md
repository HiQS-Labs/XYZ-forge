# RELAY · GH-71 pgvector image FROM postgres:16 review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-22.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh71-image-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **review_gh71.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-22

### Artifact — review_gh71.md
```
# Review brief — GH-71: pgvector image built FROM postgres:16 (glibc/collation parity)

You are reviewing a **committed change** on branch `gh-71-72-hardening` in the LTVera-Pandas repo. **Read the actual files in the working tree** — this turn runs in a worktree of the branch @ HEAD. This is a **review-only** turn: report findings, do not edit.

## Context

The GH-68 deploy swapped prod Postgres `postgres:16` → `pgvector/pgvector:pg16`. The volume survived, but the images have different Debian bases and therefore different glibc (**2.41** trixie vs **2.36** bookworm). Postgres warned `collation version mismatch`; 26 indexes on collatable columns (incl. the `customers.customer_key` and `tenants.slug` uniques) had been built under 2.41 and were being read under 2.36. It was remediated in prod (REINDEX CONCURRENTLY ×26, then `REFRESH COLLATION VERSION`, 0 invalid indexes).

This change removes the footgun permanently by building our own image `FROM postgres:16`.

## The change (commit `2b196c6`, 3 files)

- **`docker/postgres/Dockerfile`** (new) — `FROM postgres:16` + `postgresql-16-pgvector`.
- **`docker-compose.yml`** — postgres service switched from `image: pgvector/pgvector:pg16` to `build: {context: ., dockerfile: docker/postgres/Dockerfile}`.
- **`OPERATIONS.md`** (+55) — new "Postgres image and collation parity" section with a check + reindex/refresh/verify recipe.
- **`docker-compose.prod.yml`** — intentionally unchanged (must keep inheriting the image).

An objective gate already verified empirically: built image glibc **2.41 == postgres:16 2.41**, `CREATE EXTENSION vector` → **0.8.5**, compose no longer pins the third-party image, prod overlay untouched.

## What to scrutinize (most severe first)

1. **Does this actually achieve collation parity going forward?** Any way the built image's glibc could still drift from the data directory's `datcollversion`? Is pinning `FROM postgres:16` (a moving tag) sufficient, or should it be digest-pinned?
2. **`postgresql-16-pgvector` package** — correct package for the trixie base? Any risk it lags the pgvector version we depend on, or disappears? Should the version be pinned?
3. **Compose correctness.** Does `build:` in the base file interact correctly with `docker-compose.prod.yml` (which overrides only `restart` and the data-volume bind onto `/mnt/pgdata/postgres`)? Any deploy-path breakage — e.g. does the prod deploy command need `--build` now that it's a build rather than a pull? Flag anything OPERATIONS.md should say about that.
4. **The OPERATIONS.md recipe.** Is the generated `REINDEX` SQL correct? It selects indexes where `attribute.attcollation <> 0`. Does that correctly capture every collatable index? Is `REINDEX ... CONCURRENTLY` outside a transaction handled right? Is the ordering (reindex → refresh → verify, never refresh first) correct and clearly stated?
5. **Operational risk.** Anything about this change that could break the running prod stack on the next deploy or the nightly VM restart? Note that prod currently runs `pgvector/pgvector:pg16` with collation already refreshed to 2.36 — **switching to a 2.41-based image will re-introduce a mismatch in the opposite direction on that existing data dir.** Does OPERATIONS.md (or the change) adequately warn the operator that deploying this REQUIRES the reindex recipe to be run again? This is the highest-value thing to get right.
6. Anything else that would block deploying this.

Report `[Blocker]` / `[Should]` / `[Nit]` / `[Pass]` with `file:line` citations, then a **Verdict** (Approved | Changes requested | Blocked).
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer (agy) — Round 1

- `[Blocker]` The `OPERATIONS.md` reindex query misses all expression indexes (e.g., `CREATE INDEX ON table (lower(col))`). For expression indexes, `indkey` contains `0`, so joining `pg_attribute` against the *table's* `attrelid` returns no rows. Fix: query the `pg_attribute` of the *index itself* (`WHERE attribute.attrelid = index_rel.oid`) rather than parsing `indkey`. Citation: `OPERATIONS.md:148-155`
- `[Blocker]` `FROM postgres:16` is a moving tag. When the official image bumps its Debian base (e.g. bookworm to trixie), a rebuild will silently upgrade glibc and break collations again. Fix: Pin to a specific OS release like `FROM postgres:16-bookworm` or a sha256 digest. Citation: `docker/postgres/Dockerfile:1`
- `[Blocker]` The "Which restart command to use" table instructs the operator to run `up -d --build worker app` for Dockerfile changes, omitting `postgres`. If the postgres Dockerfile changes, the operator won't rebuild the database image. Fix: Update the command to include `postgres` (or all services) for build changes. Citation: `OPERATIONS.md:85`
- `[Blocker]` The runbook explains how to handle *future* Postgres image changes, but doesn't explicitly warn that deploying *this specific change* will immediately cause a mismatch on production (reverting 2.36 back to 2.41). Fix: Add a prominent warning in `OPERATIONS.md` (or deployment notes) that deploying this change requires rebuilding `postgres` and running the reindex recipe immediately. Citation: `OPERATIONS.md:115`
- `[Should]` The `postgresql-16-pgvector` apt package is not version-pinned. A future rebuild might pull a newer extension version, forcing an unexpected `ALTER EXTENSION vector UPDATE;`. Fix: Pin the version in the `apt-get install` command. Citation: `docker/postgres/Dockerfile:4`
- `[Pass]` Compose configuration correctly migrates from the hardcoded image to the local `build:` definition, and `docker-compose.prod.yml` correctly inherits it. Citation: `docker-compose.yml:53`

**Verdict:** Changes requested

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
