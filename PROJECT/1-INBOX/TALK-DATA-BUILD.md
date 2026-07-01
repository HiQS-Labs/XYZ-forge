---
title: "Talk With Your Data — Project Plan - in-house XYZ dog food spin off"
project: greaney-campaign-data-platform
version: 0.1.1
status: draft — not started
last_updated: 2026-07-01
owners:
  - it-devops-lead
swarm_compatible: true
repo: github.com/<org>/campaign-data-platform  # TODO: set
effort: 4
complexity: 4
risk: 3
phases: 5
stack:
  language: Python 3.12
  web_framework: Reflex 0.7.x
  auth: Clerk via reflex-clerk-api
  oltp_db: PostgreSQL (GCE VM)
  olap_store: BigQuery
  object_storage: Google Cloud Storage
  analysis_engine: PandasAI v3 + LiteLLM (Claude)
  packaging: Docker
  ci: GitHub Actions
  cloud: Google Cloud Platform
related_docs:
  - PITCH.md
  - CONTRACTS.md  # produced in Phase 0, source of truth for swarm lanes
---

## Status

| What was just completed | What's next |
|---|---|
| — (project not started) | **Phase 0 — Foundation & Contracts** |

> Update this table at the end of every phase. It is the fastest way for any agent (or human) to orient on resume.

---

## Table of Contents

1. [Swarm Preflight & Relay Architecture](#swarm-preflight--relay-architecture)
2. [Architecture at a Glance](#architecture-at-a-glance)
3. [Phase 0 — Foundation & Contracts](#phase-0--foundation--contracts)
4. [Phase 1 — Core Platform](#phase-1--core-platform)
5. [Phase 2 — Intelligence & UI](#phase-2--intelligence--ui)
6. [Phase 3 — Integration & Hardening](#phase-3--integration--hardening)
7. [Phase 4 — Deploy & Ops](#phase-4--deploy--ops)
8. [Open Risks & Decisions](#open-risks--decisions)

---

## Swarm Preflight & Relay Architecture

This plan is built to run on the **XYZ harness** (`tick` kernel + `relay-automation/` stack), which lives in the `xyz-3-agents-swarm` repo. Two distinct rails do two different jobs — do **not** conflate them:

- **`tick` / `xyz` swarm = concurrent, path-scoped lanes.** Multiple agents edit **non-overlapping path globs** of ONE shared checkout, in ONE session, claiming lanes with `tick take` / `tick scope --paths <globs>`, heartbeating with `tick ping`, releasing with `tick done`. This is the only rail that gives us *concurrency* (Phase-1 A/B/C and Phase-2 D/E in parallel).
- **`marathon` = serial, phase-gated relay.** `relay-automation/marathon.sh --plan MARATHON.yaml` runs each phase through one producer↔reviewer relay loop in `depends_on` order, advancing on approval and **halting on the first phase failure**. Marathon does **not** run lanes in parallel — it is the gate that chains phases and enforces review.

**Preflight is a planner, not a launcher.** `utils/swarm-preflight.sh` reads a capture doc's machine-readable preflight contract (see below), proves the fix is still required, assigns lanes, and *emits a run packet*. The **operator** then launches `relay-automation/marathon-drive.sh` with that packet — preflight never executes the run (GUIDING-PRINCIPLES §8).

**The one rule that makes concurrency work:** No lane starts until Phase 0 freezes `CONTRACTS.md`. Every lane builds against the frozen DB schema, module interfaces, and env-var contract — never against another lane's live code. Cross-lane calls go through interfaces that can be mocked, so a lane is never blocked waiting on a sibling. (`CONTRACTS.md` is the **human** source of truth; the machine surface the harness actually reads is the JSON preflight contract + each lane's `tick --paths` globs.)

**Cross-repo note.** This plan targets a *separate* greenfield repo (`campaign-data-platform`); the XYZ harness (`swarm-preflight`, `marathon`, `tick`, `validate.sh`, `utils/pdda/pdda.sh`) lives in `xyz-3-agents-swarm`. Phase 0 must therefore **install the harness into the target repo** (via its `install.sh`) so `validate.sh` and `utils/pdda/pdda.sh run` exist locally — or every run must be driven cross-repo with `swarm-preflight --target-root <target>`. Pick one; Phase 0 below assumes the install path.

**Lane Legend (`tick --paths` scopes):**

| Lane | Path scope (`tick scope --paths`) | Depends on |
| --- | --- | --- |
| **A — Platform** | `infra/**`, `.github/workflows/**` | Phase 0 |
| **B — Auth** | `auth/**`, `middleware/**` | Phase 0 (user contract) |
| **C — Data** | `models/**`, `ingest/**`, `db/**` | Phase 0 (schema contract) |
| **D — Intelligence** | `analysis/**`, `reports/**` | Phase 0 (query contract) |
| **E — UI** | `ui/**`, `pages/**`, `components/**` | Phase 0 (API contract) |

**Wave Map (which rail runs each phase):**

- **Phase 0** — Single lane, single agent. Blocking gate. Nobody else starts.
- **Phase 1** — `xyz` swarm: Lanes **A, B, C** claim disjoint `--paths` and run concurrently in one shared tree.
- **Phase 2** — `xyz` swarm: Lanes **D, E** run concurrently (A/B/C feed them via merged contracts + mocks).
- **Phase 3** — Serial integration via `marathon` (`depends_on` chain); independent hardening/test sub-tasks may still parallelize as tick lanes.
- **Phase 4** — Serial ops via `marathon`.

**Merge discipline:** Trunk-based. Each lane declares its editable `artifacts` in the preflight contract; a **path-allowlist containment** boundary rejects edits outside a lane's scope. After a lane's turn, marathon-drive runs the contract's `gate` (`bash validate.sh`); `fix_probes` are what proved the work was still required going in. Changes to `CONTRACTS.md` require a dedicated synchronous PR and ping to affected lanes — contracts change by agreement, never silently.

**Intra-lane order matters, inter-lane order does not.** Tasks in the same lane run in listed order; disjoint lanes have no ordering between them within a phase (that is exactly what lets the swarm run them at once).

### Swarm Preflight Contract

Machine-readable contract consumed by `utils/swarm-preflight.sh --project-doc` (required, or preflight exits 3). Freeze the concrete values in Phase 0 alongside `CONTRACTS.md`; the `artifacts` / `lanes` here are the top-level Phase-0 scaffold — each parallel lane gets its own capture doc + contract scoped to its `tick --paths` globs when it is promoted to `2-WORKING`.

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "path_absent", "path": "CONTRACTS.md" } ],
  "artifacts":   [ "CONTRACTS.md", "docker-compose.yml", ".env.example" ],
  "remediation": { "source": "self#phases", "criteria": "Phase 0 checklist below" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [ ".github/workflows/" ] }
}
```

---

## Architecture at a Glance

```
Browser
  │
  ▼
Reflex app (pure Python → Next/React front + FastAPI back)   ← Lane E
  ├─ Clerk auth (reflex-clerk-api)                            ← Lane B
  ├─ Upload  → GCS (raw file) → schema infer → BigQuery load  ← Lane C
  ├─ Postgres: users, projects, memberships, dataset &        ← Lane C
  │            report metadata, audit log
  └─ Ask     → Analysis engine (PandasAI v3 + LiteLLM→Claude) ← Lane D
                 runs in Docker sandbox, reads BigQuery
```

Two data stores by design: **Postgres = app/metadata (OLTP)**, **BigQuery = the uploaded tabular data for analysis (OLAP)**. GCS holds the raw upload as source of truth before load.

---

## Phase 0 — Foundation & Contracts

*Single lane. Blocking gate. Keep it short — the goal is to unblock parallel work, not to build features.*

- [ ] GitHub repo created, trunk-based branch strategy documented in `CONTRIBUTING.md`
- [ ] XYZ harness installed into the target repo (via `install.sh`) so `validate.sh`, `utils/pdda/pdda.sh`, and `tick` resolve locally — OR the operator commits to driving every run cross-repo with `swarm-preflight --target-root <target>` (decide and record here)
- [ ] Swarm Preflight Contract (JSON block above) frozen with concrete `gate` / `artifacts` / `lanes` values; `utils/swarm-preflight.sh --project-doc <this doc> --dry-run` reports `ready`
- [ ] `CONTRACTS.md` committed and frozen, containing:
  - [ ] Postgres schema (tables: `users`, `projects`, `memberships`, `datasets`, `reports`, `audit_log`) with columns + types
  - [ ] Module interface signatures for `data-ingest`, `analysis-engine`, `reports` (function names, inputs, outputs)
  - [ ] REST/event contract for UI ↔ backend (endpoint names, request/response shapes)
  - [ ] Canonical env-var list (`CLERK_PUBLISHABLE_KEY`, `CLERK_SECRET_KEY`, `DATABASE_URL`, `BIGQUERY_DATASET`, `GCS_BUCKET`, `ANTHROPIC_API_KEY`, etc.)
- [ ] Local dev scaffold: `docker-compose.yml` runs Reflex + local Postgres + stub services with one command
- [ ] Mock/stub layer committed so any lane can run in isolation (fake auth user, in-memory dataset, canned analysis response)
- [ ] `.env.example` matches the env-var contract exactly

### QA Checklist — Phase 0

- [ ] Fresh clone + `docker compose up` yields a running Reflex "hello" page with zero manual steps
- [ ] Every lane's stub is importable and returns contract-shaped data
- [ ] `CONTRACTS.md` reviewed and explicitly signed off (no lane may edit it unilaterally after this)
- [ ] `utils/swarm-preflight.sh --project-doc <this doc> --dry-run` returns `ready` (contract parses, gate resolves, artifacts exist at ref)
- [ ] `validate.sh` and `utils/pdda/pdda.sh run` pass cleanly (in the target repo, per the harness-install decision above)
- [ ] Status table updated → completed: Phase 0 / next: Phase 1

---

## Phase 1 — Core Platform

*Lanes A, B, C run concurrently.*

### Lane A — Platform (Infra + CI)

- [ ] GCP project + billing + IAM roles provisioned (least-privilege service accounts per component)
- [ ] GCE VM running, hardened (firewall, SSH keys only), Docker installed
- [ ] Managed/self-hosted Postgres reachable from VM; `DATABASE_URL` in secret manager
- [ ] BigQuery dataset created; service account can create tables + query
- [ ] GCS bucket created for raw uploads (uniform bucket-level access, lifecycle rule for stale temp files)
- [ ] Secrets in Google Secret Manager (no secrets in repo or images)
- [ ] **CI shipped first**: GitHub Actions runs lint + tests + Docker build on every PR (all later lanes inherit this)
- [ ] Dockerfile builds the Reflex app image reproducibly

### Lane B — Auth

- [ ] `reflex-clerk-api` installed; Clerk dev instance created
- [ ] `clerk_provider` wraps the app; sign-in / sign-out works end-to-end against Clerk dev
- [ ] `ClerkState` synced to backend; authenticated user resolvable server-side
- [ ] User record upserted into Postgres `users` on first auth (maps Clerk `user_id` → internal id)
- [ ] RBAC roles defined (`admin`, `editor`, `viewer`); role stored on `memberships`
- [ ] Protected-route helper: unauthenticated users redirect to sign-in; role checks gate pages

### Lane C — Data (Model + Ingestion)

- [ ] Migrations create all Phase 0 schema tables; ORM models match `CONTRACTS.md`
- [ ] Upload endpoint accepts a CSV, writes raw file to GCS, returns `dataset_id` (verify: row in `datasets`, object in bucket)
- [ ] File validation: size cap, MIME/extension check, row/column sniff, rejects malformed files with a clear error
- [ ] Schema inference maps CSV columns → BigQuery types; data loaded into a per-dataset BigQuery table
- [ ] Dataset metadata (owner, project, row count, column schema, source filename) persisted in Postgres
- [ ] Audit-log entry written on every upload

### QA Checklist — Phase 1

- [ ] Lane A: `terraform`/scripts re-run cleanly (idempotent); a teardown + rebuild produces identical infra
- [ ] Lane A: CI red-blocks a PR with a failing test (proven, not assumed)
- [ ] Lane B: a signed-in `viewer` is denied an `editor`-only route; an `admin` is allowed
- [ ] Lane C: upload → GCS → BigQuery round-trips a 3-column sample CSV; row counts match source
- [ ] Lane C: a deliberately broken CSV is rejected with a non-500 error
- [ ] Contracts unchanged, or changes merged and re-reviewed
- [ ] `validate.sh` passes across all merged lanes
- [ ] Status table updated → completed: Phase 1 / next: Phase 2

---

## Phase 2 — Intelligence & UI

*Lanes D and E run concurrently. Each mocks the other via Phase 0 stubs until integration.*

### Lane D — Intelligence (Analysis + Reports)

- [ ] PandasAI v3 wired to Claude via LiteLLM; `pai.config` set from env
- [ ] **Sandbox is mandatory**: all LLM-generated code executes in PandasAI's Docker sandbox — never in the app process
- [ ] Privacy guard: only column names/schema (not raw rows) sent to the LLM unless the dataset owner opts in
- [ ] Query API: `ask(dataset_id, question) → {answer, generated_code, chart?}` matching the contract
- [ ] Reads dataset from BigQuery by `dataset_id`; handles empty/huge results gracefully
- [ ] Report templates defined (e.g., summary stats, trend over time, breakdown by category)
- [ ] Pre-generated report job: runs a template against a dataset, stores result + metadata in `reports`
- [ ] Errors from bad questions or failed code-gen return a friendly message, not a stack trace

### Lane E — UI

- [ ] App shell first: Reflex layout, nav, theming, auth-aware header (mocks Lane B until merge)
- [ ] Upload page: drag-drop CSV, progress, success/failure states, lists user's datasets
- [ ] Chat-with-data page: pick a dataset, ask a question, render answer + any chart + (collapsible) generated code
- [ ] Shared project viewer: members of a project see the same pre-generated reports and templates (read model respects RBAC)
- [ ] Loading/empty/error states on every async view
- [ ] Responsive enough for laptop + tablet (field volunteers)

### QA Checklist — Phase 2

- [ ] Lane D: a prompt-injection attempt ("delete all files", "read env vars") is contained by the sandbox — proven with a test
- [ ] Lane D: same question on same dataset returns stable, contract-shaped output
- [ ] Lane D: a report template produces a stored `reports` row viewable later
- [ ] Lane E: every page renders against mocks with no console/server errors
- [ ] Lane E: a `viewer` cannot see another project's reports
- [ ] `validate.sh` passes across all merged lanes
- [ ] Status table updated → completed: Phase 2 / next: Phase 3

---

## Phase 3 — Integration & Hardening

*Serial wiring; hardening sub-tasks may parallelize.*

- [ ] Replace all mocks: UI → real auth, real upload, real analysis, real reports
- [ ] End-to-end flow passes: sign in → create project → upload CSV → ask question → save report → teammate opens the same report
- [ ] Rate limiting on upload + ask endpoints (protect LLM spend and the sandbox)
- [ ] LLM cost guardrails: per-user/day token or request cap, logged
- [ ] Structured logging + basic error tracking (e.g., Sentry) across front and back
- [ ] Secrets confirmed absent from images, logs, and client bundle
- [ ] Backup: Postgres automated backup + documented restore; GCS versioning on the upload bucket
- [ ] Load sanity check: concurrent uploads + queries from ~5 users don't wedge the VM

### QA Checklist — Phase 3

- [ ] Full e2e flow green in CI (or a scripted smoke test)
- [ ] Rate limits trip correctly under a burst test
- [ ] A Postgres restore from backup is actually performed once and verified
- [ ] Security pass: no secrets leaked; RBAC holds across all real (non-mock) paths
- [ ] `validate.sh` green
- [ ] Status table updated → completed: Phase 3 / next: Phase 4

---

## Phase 4 — Deploy & Ops

*Serial.*

- [ ] Production Clerk instance created; **`CLERK_PUBLISHABLE_KEY` present at Docker build time** (known Reflex/GCP export gotcha — the frontend export step fails without it)
- [ ] Production env vars in Secret Manager; prod `.env` matches contract
- [ ] App deployed to the GCE VM via Docker Compose (or container runtime of choice)
- [ ] HTTPS via reverse proxy (Caddy/Nginx) + valid cert; only 443 exposed
- [ ] Health check endpoint + uptime monitor
- [ ] `RUNBOOK.md`: deploy, rollback, restore-from-backup, rotate-secrets, on-call basics
- [ ] Access review: who has GCP/Clerk/DB admin; principle of least privilege confirmed

### QA Checklist — Phase 4

- [ ] Cold deploy from scratch succeeds using only `RUNBOOK.md` (no tribal knowledge)
- [ ] A rollback to the previous image is performed and verified
- [ ] Real user (non-admin) completes the full flow on production
- [ ] Monitoring fires a test alert successfully
- [ ] `validate.sh` and `utils/pdda/pdda.sh run` green
- [ ] Status table updated → completed: Phase 4 / next: — (live; move to iteration backlog)

---

## Open Risks & Decisions

| Risk / Decision | Note | Mitigation |
| --- | --- | --- |
| `reflex-clerk-api` is beta | Small maintainer, Reflex 0.7.x pinned | Pin exact version; fallback is `reflex-local-auth` if it blocks. Keep auth behind our own interface (Phase 0 contract) so swapping is cheap |
| PandasAI executes generated code | Real RCE surface on a public campaign tool | Docker sandbox is non-negotiable; privacy guard; rate limits; cost caps |
| Single GCE VM | Fine for MVP; not HA | Acceptable for current scale; revisit if usage grows (managed DB, autoscaled runtime) |
| Reflex version pinning | Framework moves fast | Pin `reflex`, `reflex-clerk-api`, `pandasai` versions in lockfile; upgrade deliberately |
| Sensitive campaign data in the cloud | Volunteer/survey PII | Least-privilege IAM, encryption at rest (default on GCP), audit log, opt-in before raw rows reach any LLM |

> **Reminder:** none of this is needed the day it's built — the value is being ready before the data volume arrives. Until then, one-off analysis runs fine through Claude Desktop.