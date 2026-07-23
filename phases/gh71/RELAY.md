# Marathon Phase gh71
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH71-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Phase brief — GH-71: build our own pgvector Postgres image (glibc/collation parity)

Repo: **LTVera-Pandas**. Branch: `gh-71-72-hardening` (cut from `development` @ 09374bd, which already contains the merged GH-68 pgvector work).

**Hard constraint: CODE ONLY. Do NOT deploy, do NOT touch the GCE VM, do NOT run anything against production.** Deployment is operator-gated and happens after review.

## Why

The GH-68 deploy swapped prod Postgres `postgres:16` → `pgvector/pgvector:pg16`. The data volume survived intact (row counts byte-identical: 162,242 products / 5,546,802 orders / 6,186,678 order_lines), **but the two images ship different Debian bases and therefore different glibc**:

| Image | Base | glibc |
|---|---|---|
| `postgres:16` (the 14 GB data dir was created under this) | trixie | **2.41** |
| `pgvector/pgvector:pg16` (what we deployed) | bookworm | **2.36** |

Postgres warned on every connection:

```
WARNING:  database "ltvera" has a collation version mismatch
DETAIL:  The database was created using collation version 2.41, but the operating system provides version 2.36.
```

26 indexes on collatable (text) columns — including the `customers.customer_key` and `tenants.slug` uniques — had been built under 2.41 and were being read under 2.36. Text collation differences across glibc versions can make index scans miss rows or fail to detect unique violations.

This was remediated in prod at deploy time (`REINDEX INDEX CONCURRENTLY` on all 26 → 87s, 0 invalid indexes; then `ALTER DATABASE ltvera REFRESH COLLATION VERSION`). **Prod is currently consistent and warning-free — this phase is about removing the recurring footgun, not fixing a live fault.**

## What to build

1. **`docker/postgres/Dockerfile`** — our own pgvector image built `FROM postgres:16`, so glibc always matches the data directory by construction:

```dockerfile
FROM postgres:16
RUN apt-get update \
 && apt-get install -y --no-install-recommends postgresql-16-pgvector \
 && rm -rf /var/lib/apt/lists/*
```

The official `postgres` image already carries the PGDG apt repo, so `postgresql-16-pgvector` should install cleanly. **Verify this actually resolves on the trixie base** — if the package name differs, find the correct one and say so explicitly in your turn block with evidence.

2. **`docker-compose.yml`** — point the `postgres` service at the Dockerfile via `build:` instead of `image: pgvector/pgvector:pg16`.

3. **`docker-compose.prod.yml`** — must keep *inheriting* the image. It currently overrides only `restart` and the data-volume bind onto `/mnt/pgdata/postgres`. Do **not** add an `image:` key there. Change it only if strictly required, and justify it.

4. **`OPERATIONS.md`** — document the constraint under a clear heading: **any future Postgres image change must compare the image's glibc (`ldd --version`) against `pg_database.datcollversion`, and reindex collatable indexes if they differ.** Include the exact recipe that was used in prod:
   - generate `REINDEX INDEX CONCURRENTLY <ix>;` for every index on a collatable column,
   - run them,
   - `ALTER DATABASE ltvera REFRESH COLLATION VERSION;`,
   - verify `SELECT count(*) FROM pg_index WHERE NOT indisvalid` is 0.

## Definition of Done

- [ ] `docker/postgres/Dockerfile` exists and **builds successfully**.
- [ ] The built image reports the **same glibc as `postgres:16`** — this is the entire point of the phase. Prove it with `ldd --version` output from both.
- [ ] `CREATE EXTENSION vector` works in the built image. Prove it: run the image and `psql -c "CREATE EXTENSION vector; SELECT extversion FROM pg_extension WHERE extname='vector';"`.
- [ ] `docker-compose.yml` postgres service builds from the Dockerfile; prod overlay still inherits it.
- [ ] `OPERATIONS.md` documents the glibc/collation-parity constraint + the reindex recipe.
- [ ] No application code changed — this phase touches infra + docs only.

## Ground rules

- Match surrounding conventions. This repo does **not** enforce ruff (48 pre-existing E501s in `app/db/models.py`); match the local style of the file you edit rather than reformatting.
- Cite `file:line` for every claim in your turn block.
- Do not modify application code, tests, or the GH-72 recommendation logic — that is a separate phase.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): docker/postgres/Dockerfile,docker-compose.yml,docker-compose.prod.yml,OPERATIONS.md
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH71-TURN --agent codex --paths "phases/gh71/RELAY.md,docker/postgres/Dockerfile,docker-compose.yml,docker-compose.prod.yml,OPERATIONS.md"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH71-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH71-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh71/RELAY.md and docker/postgres/Dockerfile,docker-compose.yml,docker-compose.prod.yml,OPERATIONS.md. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: docker/postgres/Dockerfile,docker-compose.yml,docker-compose.prod.yml,OPERATIONS.md.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH71-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH71-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh71/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Reviewer · agy
Codex, it looks like you haven't taken your turn as the BUILDER yet. The `docker/postgres/Dockerfile` and `docker-compose.yml` files are missing, and you didn't append your builder block to this document. Please complete the tasks outlined in the Phase Brief, leave your builder block, and release the turn back to me.

**Verdict:** Changes requested
