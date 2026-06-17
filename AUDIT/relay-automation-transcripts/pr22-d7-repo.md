# RELAY · PR #22 — D7 tenant-scoped repository helper (code review, gate the merge)
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Done
STATUS: Approved
ROUND: 2 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup. **IMPORTANT (this relay):** review against **origin** (`origin/spike/d7-repository`), NOT necessarily your on-disk tree. Use the `git show` commands in the Round 1 block. Cite `file:line`.
   - **Reviewer (Codex):** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; you only append findings here.
   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Basis:**` + `**Findings & proposals:**` + `**Answers:**` + `**Commit:**`.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes the relay — Reviewer only; else `Open`).
6. **Do NOT commit or push (this relay).** This log is **local scratch**; keep it out of the PR. Save the file on disk and write `Commit: none (comments only)`.
7. **Stop.** Tell the operator your one-line result.

## Setup
- Artifact under review: **PR #22** — `spike/d7-repository` → `build/v1.2-p22-scorer`. The actual code: **`app/db/repository.py`** (the thin `tenant_scoped(session, Model)` helper) and **`tests/test_repository.py`** (behavioral RLS test), plus a §8.3 doc update in `V1.2-BUILD-SWE-INTERNAL.md`. New files only — no existing app code changed.
- Definition of Done: PR #22 is **safe + sound to merge into the build line** — (a) the helper is correct and its contract (operate on an already-bound session; fail closed if unbound) is right; (b) `tests/test_repository.py` genuinely proves RLS composition **under live RLS** (not under the superuser URL where RLS is dormant — a false positive); (c) the two known tensions are dispositioned: the **private `_TENANT_KEY` import** and **merging a helper not yet used by app code**; (d) no isolation/security regression vs the AGENTS.md model (app-layer filter = primary, RLS = backstop).
- Producer: **Claude (window A)**   ·   Reviewer: **Codex (window B)**   <!-- IDENTITY: Claude = Producer (wrote the helper + test); Codex = Reviewer. Stamp your label in every header. -->
- Handoff: manual nudge   ·   **log is local scratch (uncommitted); review against origin/spike/d7-repository**
- Started: 2026-06-15
- Why Codex: independent, non-Claude eyes on actual app code touching the tenant-isolation surface.

## Ground rules
1. This file is the single source of truth; the two agents (Claude, Codex) never share memory.
2. Take a turn only if `NEXT` names your role — else reply "not my turn" and stop.
3. One block appended at the bottom, above the marker. Never edit earlier turns. Update `NEXT`/`STATUS`.
4. Findings are graded bullets with `file:line` evidence, not essays.
5. **The Reviewer never edits the artifact** — it proposes; the Producer (with the operator) implements + logs a disposition for each.
6. Grade: `[Blocker]` must fix before merge · `[Should]` strong rec · `[Nit]` optional · `[Pass]` checked + sound.
7. Reviewer posts Verdict + **Basis** every turn. Relay ends on **Approved**; max ROUND without it → `STATUS: Escalated`.
8. **No commits this relay** — log is local scratch; `Commit: none (comments only)`.
9. One window at a time; `NEXT` is honor-system.
10. **Evidence contract.** This is runnable code, so behavioral basis is achievable: if your window has the env, run `TEST_POSTGRES_PORT=5433 .venv/bin/pytest tests/test_repository.py tests/test_rls_isolation.py -q` and report it as `behaviorally proven`. If you can't run it, `textual only` (read the code + reason about RLS) is acceptable — say which.

## Roles
- **Producer (Claude)** — wrote the helper + test; requests review, decides + implements proposals.
- **Reviewer (Codex)** — reviews vs the DoD, proposes graded findings with fixes, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · Claude · 2026-06-15 10:12 PDT
**Did:** Built the D7 thin helper (the §8.3-sanctioned "adopt in P22" foundation) on `spike/d7-repository` and opened PR #22 into the build line. New files only:
- `app/db/repository.py` — `tenant_scoped(session, model)`: reads the tenant id from `session.info[_TENANT_KEY]`, returns `select(model).where(model.tenant_id == tid)`, raises `RuntimeError` if no tenant is bound.
- `tests/test_repository.py` — reuses the live-RLS two-tenant `rls_db` fixture from `test_rls_isolation` and routes reads through the helper.
I ran `TEST_POSTGRES_PORT=5433 .venv/bin/pytest tests/test_repository.py tests/test_rls_isolation.py -q` → **10 passed**.

**Review this (gate the merge) — read the real code first:**
- `git show origin/spike/d7-repository:app/db/repository.py`
- `git show origin/spike/d7-repository:tests/test_repository.py`
- Context: `git show origin/build/v1.2-p22-scorer:app/db/session.py` (the `_TENANT_KEY`, `bind_tenant_context`, `after_begin` GUC re-assert) and `AGENTS.md` Multi-tenancy (app-layer filter = primary, RLS = backstop).
1. **Helper correctness + contract.** Is reading `session.info[_TENANT_KEY]` and filtering `model.tenant_id == tid` correct? Is fail-closed-on-unbound the right behavior (vs returning empty)? Any edge case — e.g. a model without `tenant_id` (AttributeError at build), or a session bound to a *different* tenant than the caller assumes?
2. **Private import.** It imports the private `_TENANT_KEY` from `app.db.session`. Acceptable, or should `session.py` expose a public accessor (e.g. `current_tenant(session)`) and the helper use that? (Changing session.py touches shared code — call it.)
3. **Test validity.** Does `tests/test_repository.py` actually exercise **live RLS**? It depends on the `rls_db` fixture connecting as `ltvera_app` (non-superuser). Confirm the test isn't silently running under the superuser URL where RLS is dormant (which would make "composes with RLS" a false positive).
4. **Security/merge safety.** Does the helper preserve the primary-guarantee semantics (explicit `tenant_id` filter, not relying on RLS alone)? Anything that weakens isolation? Is merging this additive helper into the build line safe given nothing uses it yet?

**Verification:** ran `TEST_POSTGRES_PORT=5433 .venv/bin/pytest tests/test_repository.py tests/test_rls_isolation.py -q` → 10 passed (note: a host Postgres squats :5432 with no `postgres` role; the compose DB is on :5433).
**Open questions:** (a) private `_TENANT_KEY` import — live with it, or require a public accessor in session.py before merge? (b) Is merging a not-yet-used helper acceptable, given the regression test guards the invariant and §8 sanctions adopting it in P22? (c) Any blocker to merging into the build line?
**Commit:** none (comments only) — code is on origin at `spike/d7-repository` (9c118fe); this log is local scratch.

### Round 2 · Reviewer · Codex · 2026-06-15 10:55 PDT
**Verdict:** Approved.
**Basis:** Behaviorally proven. I reviewed the origin branch code and ran `TEST_POSTGRES_PORT=5433 .venv/bin/pytest tests/test_repository.py tests/test_rls_isolation.py -q` locally: **10 passed**.

**Findings & proposals:**
- `[Pass]` `app/db/repository.py:37-43` keeps the AGENTS.md primary guarantee intact: it reads the tenant bound onto the session and emits an explicit `model.tenant_id == tenant_id` predicate instead of leaning on RLS alone. Pairing that with the existing bound-session contract in `app/db/session.py:80-98` and `app/db/session.py:114-131` is the correct composition model.
- `[Pass]` `app/db/repository.py:38-42` fails closed on the only unsafe path. Raising on an unbound session is the right contract here; returning an empty query would hide a programmer error and make it easier to accidentally ship code that never bound tenant context.
- `[Pass]` `tests/test_repository.py:21-69` genuinely exercises live RLS, not the superuser path. The borrowed fixture rewires `DATABASE_URL` to `ltvera_app` and rebinds `SessionLocal` to that non-superuser connection in `tests/test_rls_isolation.py:36-79`, so the helper tests are running with the same live-RLS backstop that proves the no-`WHERE` behavior in `tests/test_rls_isolation.py:92-149`.
- `[Nit]` `app/db/repository.py:25` imports the private `_TENANT_KEY` constant from `app.db.session`. I would not block the merge on this because the coupling stays inside the `app.db` boundary and the contract is already documented, but the cleaner long-term shape is a small public accessor like `current_tenant_id(session)` in `app/db/session.py`, then have the helper call that.

**Answers:**
- `(a)` Private `_TENANT_KEY` import: acceptable for this PR; not ideal API shape, but not worth forcing shared-session churn before merge. If you touch this surface again, expose a public accessor and migrate the helper to it.
- `(b)` Merging an unused helper now is acceptable. This PR is additive, keeps the isolation model unchanged, and lands the regression test with the helper so P22 can adopt it without inventing a fresh surface under deadline.
- `(c)` No blocker found. The helper is correct for tenant-owned models on an already-bound session; misuse on a model without `tenant_id` would fail loudly at query-build time, which is acceptable for this thin first step.

**Commit:** none (comments only)

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
