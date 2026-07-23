# RELAY · GH-71 fix round — address agy blockers
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-22.
-->

NEXT: Reviewer
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
6. **Commit only the relay file** (`relay(gh71-fix-round): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **fix_gh71.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: codex
- Started: 2026-07-22

### Artifact — fix_gh71.md
```
# Fix round — GH-71: address agy review blockers

Branch `gh-71-72-hardening` in LTVera-Pandas, on top of commit `2b196c6`. **CODE ONLY — do not deploy, do not touch the GCE VM.** Address every finding below, then state a disposition (Implemented / Modified / Declined + why) for each.

Reviewer (agy) verdict: **Changes requested** — 4 blockers, 1 should.

---

## `[Blocker 1]` Reindex query misses expression indexes — `OPERATIONS.md:148-155`

The generated `REINDEX` SQL joins `pg_attribute` against the **table's** `attrelid` using `unnest(idx.indkey)`. For an **expression index** (e.g. `CREATE INDEX ON t (lower(col))`) the corresponding `indkey` entry is `0`, so the join returns no rows and the index is silently skipped — exactly the indexes most likely to depend on collation.

**Fix:** query the `pg_attribute` rows of the **index itself** (`WHERE a.attrelid = <index>.oid AND a.attcollation <> 0`) instead of parsing `indkey` against the table. This catches both plain and expression indexes.

Verified against prod: there are currently **0** expression indexes and both queries return the same 26, so this is a latent correctness bug in the runbook, not a live gap — but it must be fixed.

## `[Blocker 2]` `FROM postgres:16` is a moving tag — `docker/postgres/Dockerfile:1`

This is the exact failure mode GH-71 exists to prevent. `postgres:16` already moved bookworm → trixie (glibc 2.36 → 2.41), which is how we got the original mismatch. A future rebuild would silently upgrade glibc again and re-break collations.

**Fix:** pin the OS release explicitly — `FROM postgres:16-bookworm` (or a `sha256` digest). **Choose deliberately and explain the choice in your turn**, because it interacts with Blocker 4: prod's `datcollversion` is currently **2.36** (bookworm). Pinning `postgres:16-bookworm` would therefore match prod's *existing* collation and avoid forcing a reindex at deploy; pinning a trixie/2.41 base would require one. State which you chose and why.

## `[Blocker 3]` Restart table omits `postgres` — `OPERATIONS.md:85`

The "Which restart command to use" table tells the operator to run `up -d --build worker app` for Dockerfile changes. The postgres image is now built from a Dockerfile too, so a change to `docker/postgres/Dockerfile` would not rebuild the DB image.

**Fix:** update that row so a build change includes `postgres` (e.g. `up -d --build postgres app worker`), and note that the postgres service is now a build, not a pull.

## `[Blocker 4]` No warning that deploying THIS change causes an immediate mismatch — `OPERATIONS.md:115`

The runbook documents how to handle *future* image changes but never warns that deploying *this* change is itself such an event. Prod currently runs `pgvector/pgvector:pg16` and its `datcollversion` was refreshed to **2.36** during the GH-68 deploy. Cutting over to a differently-based image flips it back and **re-introduces the mismatch in the opposite direction**.

**Fix:** add a prominent, unmissable warning in `OPERATIONS.md` stating that deploying this change requires rebuilding `postgres` and running the reindex → refresh → verify recipe immediately, *unless* the pinned base matches prod's current `datcollversion` (see Blocker 2 — if you pin bookworm/2.36, say so explicitly and explain that no reindex is needed).

## `[Should 5]` `postgresql-16-pgvector` not version-pinned — `docker/postgres/Dockerfile:4`

An unpinned apt package can pull a newer pgvector on rebuild, forcing an unexpected `ALTER EXTENSION vector UPDATE;`.

**Fix:** pin the package version, or document why it is intentionally floating.

---

## Ground rules
- Keep `docker-compose.prod.yml` inheriting the image (do not add an `image:` key) — agy passed this, don't regress it.
- The build gate must still pass: image builds, `CREATE EXTENSION vector` works, compose builds from the Dockerfile, OPERATIONS.md documents the constraint.
- Match surrounding file conventions; this repo does not enforce ruff.
- Cite `file:line` for each change.
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
