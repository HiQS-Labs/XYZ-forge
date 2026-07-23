# Marathon Phase gh71-72
STATUS: Open
NEXT: agy

<!-- marathon-drive: task=MARATHON-GH71-72-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Phase brief — GH-71 + GH-72: pgvector hardening wave

Repo: **LTVera-Pandas** (multi-tenant FastAPI + Reflex + Postgres + BigQuery SaaS). Branch: `gh-71-72-hardening` (cut from `development` @ 09374bd, which already contains the merged GH-68 pgvector work from #69).

Two related follow-ups from the GH-68 deploy are batched into this one wave because both touch the same deploy surface and we want a single Postgres cutover, not two.

**Hard constraint: this is a CODE change only. Do NOT deploy, do NOT touch the GCE VM, do NOT run anything against production.** Deployment is operator-gated and happens after review.

---

## Workstream A — GH-71: build our own pgvector image `FROM postgres:16`

### Why
The GH-68 deploy swapped prod Postgres `postgres:16` → `pgvector/pgvector:pg16`. The volume survived (row counts identical), but the images ship different Debian bases and therefore different glibc:

| Image | Base | glibc |
|---|---|---|
| `postgres:16` (data dir was created under this) | trixie | **2.41** |
| `pgvector/pgvector:pg16` (deployed) | bookworm | **2.36** |

Postgres warned `database "ltvera" has a collation version mismatch` on every connection. 26 indexes on collatable (text) columns — including the `customers.customer_key` and `tenants.slug` uniques — had been built under 2.41 and were being read under 2.36, which can make index scans miss rows or miss unique violations. It was remediated in prod at deploy time (`REINDEX INDEX CONCURRENTLY` on all 26, then `ALTER DATABASE ltvera REFRESH COLLATION VERSION`; 0 invalid indexes afterwards), but the underlying footgun remains: a third-party image whose base drifts independently of ours.

### What to build
Add `docker/postgres/Dockerfile`:

```dockerfile
FROM postgres:16
RUN apt-get update \
 && apt-get install -y --no-install-recommends postgresql-16-pgvector \
 && rm -rf /var/lib/apt/lists/*
```

(The official `postgres` image already carries the PGDG apt repo, so `postgresql-16-pgvector` installs cleanly. Verify this actually resolves — if the package name differs on the trixie base, find the correct one and say so in your turn.)

Point `docker-compose.yml`'s `postgres` service at it via `build:` instead of `image: pgvector/pgvector:pg16`. The prod overlay (`docker-compose.prod.yml`) must keep inheriting it — it only overrides `restart` and the data-volume bind, so do not add an `image:` there.

### Acceptance (A)
- [ ] `docker/postgres/Dockerfile` exists and builds.
- [ ] `docker-compose.yml` postgres service builds from it; `docker-compose.prod.yml` unchanged except where strictly required.
- [ ] The built image reports the **same glibc as `postgres:16`** (`ldd --version`) — that is the whole point.
- [ ] `CREATE EXTENSION vector` works in the built image (prove it: build + run + `psql -c "CREATE EXTENSION vector; SELECT extversion FROM pg_extension WHERE extname='vector';"`).
- [ ] `OPERATIONS.md` documents the constraint: **any future Postgres image change must compare the image's glibc against `pg_database.datcollversion`, and reindex collatable indexes if they differ.** Include the reindex + `REFRESH COLLATION VERSION` recipe actually used.

---

## Workstream B — GH-72: near-duplicate guard for semantic cross-sell

### Why
GH-68's semantic cross-sell is deployed but the flag is **OFF**, because on the real Bounce catalog every nearest neighbor is a variant of the anchor (the catalog stores flavors, `V1`, and `OLD` rows as separate `products`):

```
Pre-Workout Gummies - Beast Mode
  → Pre-Workout Gummies - Beast Mode Blend          (similarity 1.00)
  → Pre-Workout Gummies - Beast Mode - Fruit Punch  (0.99)
Pre-Workout Gummies - Mushroom+
  → Pre-Workout Gummies - Mushroom+ - V1 - OLD      (0.97)
```

Live dry-run of `build_recommendations()`, cross-sell family only:

```
FLAG OFF — 3 useful co-order cards (Shred Blend / Creatine Gummies / Mushroom+ → Beast Mode buyers)
FLAG ON  — the SEMANTIC card is "Cross-sell Beast Mode BLEND to Beast Mode buyers"  ← same product
           and it EVICTED the useful Mushroom+ co-order card.
```

So enabling it today makes the page strictly worse. Cosine similarity over `"{title} | type: … | vendor: … | tags: …"` measures *"same product line"*, not *"complementary"*.

### What to build
1. **Upper similarity bound.** Add `cross_sell_semantic_ceiling` (default ~0.95) beside the existing `cross_sell_semantic_floor` (0.75) in `app/recommendations/levers.py` `LeverConfig`. Accept a neighbor only when `floor <= similarity < ceiling`. Follow the existing convention: these are plain `LeverConfig` dataclass fields, deliberately NOT in the numeric `_DESCRIPTORS` registry (so they never reach tenant lever-override validation) — match how `cross_sell_semantic_floor` is done today.
2. **Widen the neighbor fetch.** `neighbors_of_product(..., limit=5)` in `app/embeddings/query.py` is too small once near-duplicates are filtered — the entire top-5 can be siblings. Fetch a larger candidate set and filter down to the qualifying band.
3. **Require a distinct family.** Prefer neighbors whose `product_type` (or `product_clusters.cluster_name`) differs from the anchor's, so semantic surfaces a genuine cross-category bridge rather than an adjacent flavor.
4. **Exclude retired rows.** Products whose title contains `OLD` or `V1`, or whose `status` is not active, must never be recommendable.
5. **Stop evicting stronger evidence.** Revisit the reserved-slot rule in `_cross_sell_recommendations()` (`app/recommendations/builder.py`): currently `co_order_limit = _MAX_PER_FAMILY - min(1, len(semantic_pairs))`. Semantic must not displace a co-order card unless the semantic candidate clears the new quality bar. Surfacing **zero** semantic cards is an acceptable, correct outcome.

### Acceptance (B)
- [ ] With the flag ON, no cross-sell card pairs a product with its own variant/version.
- [ ] Enabling the flag never removes a co-order card that would otherwise have rendered, unless the semantic candidate passes ceiling + distinct-family + not-retired.
- [ ] New test with a seeded near-duplicate pair asserting it is filtered out (`tests/test_semantic_cross_sell.py`).
- [ ] **Flag stays default-OFF.** Do not enable it in config; that is a separate operator decision.
- [ ] **Fail-closed preserved** — a pgvector/embedding error must still never escape `build_recommendations()`.
- [ ] **Tenant isolation preserved** — all queries keep their explicit `tenant_id` filter with RLS as backstop.

---

## Ground rules

- **Do not regress the existing suite.** `tests/test_recommendations.py`, `tests/test_semantic_cross_sell.py`, `tests/test_embedding_service.py`, `tests/test_recommendation_levers.py` must all still pass.
- **Match surrounding conventions.** This repo does not enforce ruff (48 pre-existing E501s in `app/db/models.py`); match the local style of the file you are editing rather than reformatting.
- The DB-backed tests require a **pgvector** Postgres (`vector` extension); a container is already running for the gate on `TEST_POSTGRES_PORT=55440`.
- Keep the two workstreams in separate commits where practical (A = infra, B = recommendation logic).
- Cite `file:line` for every claim in your turn block.


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): docker/postgres/Dockerfile,docker-compose.yml,OPERATIONS.md,app/recommendations/semantic_cross_sell.py,app/recommendations/builder.py,app/recommendations/levers.py,app/embeddings/query.py,tests/test_semantic_cross_sell.py
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH71-72-TURN --agent agy --paths "phases/gh71-72/RELAY.md,docker/postgres/Dockerfile,docker-compose.yml,OPERATIONS.md,app/recommendations/semantic_cross_sell.py,app/recommendations/builder.py,app/recommendations/levers.py,app/embeddings/query.py,tests/test_semantic_cross_sell.py"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH71-72-TURN --agent agy
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH71-72-TURN --agent agy --to codex
4. Edit ONLY these paths: phases/gh71-72/RELAY.md and docker/postgres/Dockerfile,docker-compose.yml,OPERATIONS.md,app/recommendations/semantic_cross_sell.py,app/recommendations/builder.py,app/recommendations/levers.py,app/embeddings/query.py,tests/test_semantic_cross_sell.py. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: docker/postgres/Dockerfile,docker-compose.yml,OPERATIONS.md,app/recommendations/semantic_cross_sell.py,app/recommendations/builder.py,app/recommendations/levers.py,app/embeddings/query.py,tests/test_semantic_cross_sell.py.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH71-72-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH71-72-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh71-72/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
