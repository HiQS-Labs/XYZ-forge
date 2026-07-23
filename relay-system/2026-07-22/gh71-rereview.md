# RELAY · GH-71 re-review — blocker fixes
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-22.
-->

NEXT: claude-a
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh71-rereview): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **rereview_gh71.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-22

### Artifact — rereview_gh71.md
```
# Re-review — GH-71 blocker fixes (commit f2c7c21)

You previously reviewed commit `2b196c6` on branch `gh-71-72-hardening` (LTVera-Pandas) and returned **Changes requested** with 4 blockers + 1 should. Those have now been addressed in commit `f2c7c21`. **Read the actual files in this worktree.** Review-only: report findings, do not edit.

Your original findings and the claimed dispositions:

1. `[Blocker]` *Reindex query misses expression indexes* (`OPERATIONS.md`) — **claimed fixed**: the EXISTS clause now reads `pg_attribute` off the **index's own** relation (`attribute.attrelid = index_rel.oid AND attnum > 0 AND attcollation <> 0`) instead of joining `unnest(indkey)` against the table. Verified against prod: still returns the same 26 indexes (no regression).
2. `[Blocker]` *`FROM postgres:16` is a moving tag* (`docker/postgres/Dockerfile:1`) — **claimed fixed**: pinned to `FROM postgres:16-bookworm`.
3. `[Blocker]` *Restart table omits `postgres`* (`OPERATIONS.md`) — **claimed fixed**: new table row for `docker/postgres/Dockerfile` changes using `up -d --build postgres`, routing the operator to the collation-parity section first.
4. `[Blocker]` *No warning that deploying this change causes an immediate mismatch* — **claimed dissolved rather than documented**: bookworm provides glibc **2.36**, and prod's `ltvera.datcollversion` is **2.36** (refreshed during the GH-68 remediation), so they now match and **no reindex is required to deploy this**. A warning block + historical note were added explaining the pin and that editing `FROM` is a collation event.
5. `[Should]` *pgvector package unpinned* — **claimed fixed**: `postgresql-16-pgvector=0.8.5-1.pgdg12+1` via a build `ARG`.

## Verify specifically

- Is disposition 4's reasoning actually **sound**? It is the load-bearing claim: that pinning bookworm makes the deploy reindex-free because 2.36 == 2.36. Check for a flaw — e.g. does `datcollversion` track glibc in the way assumed? Are there per-collation (`pg_collation.collversion`) mismatches that a database-level match would hide? Is `default_collation`/ICU relevant here?
- Is the corrected reindex SQL genuinely correct for **both** plain and expression indexes? Any remaining index class it misses (partial indexes, indexes on collatable columns of composite/domain types, non-default collations)?
- Does pinning **bookworm** create a foreseeable problem — EOL/security-update horizon, pgvector package availability, or a future forced migration that is now harder? Is that trade adequately documented?
- Anything about the compose `build:` + prod overlay interaction, or the new restart-table row, that is still wrong or would break a deploy?

Report `[Blocker]` / `[Should]` / `[Nit]` / `[Pass]` with `file:line`, then a **Verdict** (Approved | Changes requested | Blocked).
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

## agy (Reviewer)

- `[Pass]` *Reindex query misses expression indexes:* The query correctly joins against `pg_attribute` using the index relation's OID (`attribute.attrelid = index_rel.oid`) and checks `attcollation <> 0`. This effectively catches expression indexes since the expression's return type collation is stored directly on the index's attribute (`OPERATIONS.md:172-177`).
- `[Pass]` *`FROM postgres:16` is a moving tag:* Base image is strictly pinned to the OS release (`docker/postgres/Dockerfile:19`).
- `[Pass]` *Restart table omits `postgres`:* The restart table correctly identifies that `postgres` is a build and instructs the operator to read the collation parity section before running the rebuild (`OPERATIONS.md:86-88`).
- `[Pass]` *No warning that deploying this change causes an immediate mismatch:* The reasoning for dissolving this is sound. `postgres:16-bookworm` provides glibc 2.36, which exactly matches production's `datcollversion` of 2.36. This guarantees libc collation rules are identical, meaning the deployment is indeed reindex-free. The documentation adequately warns that any future OS change is a collation event (`OPERATIONS.md:126-134`).
- `[Pass]` *pgvector package unpinned:* The package is correctly pinned using `apt-get install -y ... "postgresql-16-pgvector=${PGVECTOR_VERSION}"` (`docker/postgres/Dockerfile:21-27`).

**Verdict:** Approved

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
