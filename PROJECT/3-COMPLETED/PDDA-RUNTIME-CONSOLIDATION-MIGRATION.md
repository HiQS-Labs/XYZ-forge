---
title: PDDA Runtime Consolidation — migrate this repo from the split flat layout to the canonical utils/pdda/ dispatcher
status: Cutover complete 2026-06-30 (moved to 3-COMPLETED 2026-07-04 — doc's own body already recorded this as done, just never relocated)
created: 2026-06-30
updated: 2026-07-04
owner: noel
branch: fix/upgrade-pdda
doc_type: migration
goal: >
  Cut this repo over from its old split PDDA implementation (utils/pdda-run.sh + 11 flat
  utils/pdda-check-*.sh scripts) to the canonical consolidated runtime the upstream pdda repo now
  ships (a single utils/pdda/pdda.sh dispatcher + helpers), which install.sh has already landed.
  Reconcile the layout AND the semantic divergence (ratings words-vs-integers, dropped/added checks,
  repo-specific tooling that must survive) before repointing hooks, gates, and docs — so the repo
  runs exactly one PDDA, not two.
complexity: 4
risk: 4
effort: 3
ratings_provisional: false
related:
  - utils/pdda/PDDA-INSTALL.md
  - PROJECT/PDDA.md
  - ROUTER.md
  - AGENTS.md
---

# PDDA Runtime Consolidation — flat `utils/pdda-*.sh` → `utils/pdda/pdda.sh`

**Verdict:** ✅ **Cutover complete (2026-06-30).** The repo now runs exactly one PDDA — the upstream
consolidated dispatcher at [utils/pdda/pdda.sh](../../utils/pdda/pdda.sh). The old split implementation
(12 flat files) is removed; the triage-ratings contract moved to integers `1`–`5`; every hook, gate,
and operator doc is repointed; repo-specific tooling (`marathon-plan.sh`, `swarm-preflight.sh`,
telemetry) was preserved. Decisions D1–D3 are recorded in
[decisions/2026-06-30-pdda-runtime-consolidation.md](../../decisions/2026-06-30-pdda-runtime-consolidation.md).
The sections below are retained as the migration record (original plan + divergence analysis).

## Status

| What was just completed | What's next |
|---|---|
| **Cutover complete 2026-06-30.** Decisions: D1=integers `1`–`5` (rewrote 25 docs `low→2/med→3/high→4` + `marathon-plan.sh` + test), D2=dropped `pdda-check-ratings.sh`, D3=kept refreshed `PROJECT/PDDA.md`. Removed 12 flat files; repointed hooks/gate-test/operator-docs to `utils/pdda/pdda.sh`; kept repo-specific tooling. Gates green: `pdda.sh run` full-mode 0 errors · `test/marathon-plan.sh` 31/31 · `test/pdda-roadmap-coverage.sh` 3/3 · `validate.sh` 0. | **Commit on `fix/upgrade-pdda`** (not yet committed). Optional follow-ups: move this doc to `3-COMPLETED`; re-add a `ratings_provisional` confirm-nudge to `marathon-plan.sh` if missed; fine-tune individual doc ratings toward `1`/`5` where warranted. |

## Current state (what's on disk now)

Two PDDA implementations live side-by-side:

| Concern | OLD (wired in, running) | NEW (landed, dormant) |
|---|---|---|
| Entry point | `utils/pdda-run.sh` | `utils/pdda/pdda.sh run` |
| Checks | 11 flat `utils/pdda-check-*.sh` + `pdda-stale-working-docs.sh` | 8 checks bundled inside `pdda.sh` |
| Shared lib | `utils/pdda-lib.sh` | `utils/pdda/pdda-lib.sh` |
| LLM readiness | `utils/pdda-doc-ready.sh` | `utils/pdda/pdda-doc-ready.sh` |
| Install doc | `utils/PDDA-INSTALL.md` | `utils/pdda/PDDA-INSTALL.md` |
| Invoked by | `.claude/settings.json` hooks, `ROUTER.md`, `AGENTS.md`, `validate.sh`/`test/`, ~25 docs | nothing but the install verify |

**Duplicated basenames right now:** `pdda-lib.sh`, `pdda-doc-ready.sh`, `PDDA-INSTALL.md` exist in
**both** `utils/` (flat) and `utils/pdda/`. The installer's auto-migration did **not** fire because it
gates on a flat `utils/pdda.sh`, and this repo's old entry point is `utils/pdda-run.sh`.

## Divergence inventory (must reconcile before cutover)

### 1. Check-set delta
- **NEW adds** `issue-doc-sync` (warn-only; flags `2-WORKING/GH-*.md` docs drifted from their GitHub
  issue state). This repo has **no** equivalent flat script — pure gain.
- **NEW drops** the repo-specific `utils/pdda-check-ratings.sh`. The new `pdda.sh` folds ratings
  validation **into** `check_frontmatter` instead of running it as a separate warn-only check.
- NEW dispatcher subcommands also cover: `gh-refresh`, `catchup`, `doc-ready` (helper), beyond the
  8 run-checks.

### 2. Triage-ratings semantic conflict — the blocker
- **OLD** (`pdda-check-ratings.sh`): `complexity`/`risk`/`effort` ∈ `low|medium|high` (words),
  **warn-only**, never blocks.
- **NEW** (`pdda.sh` → `check_frontmatter`): `effort`/`complexity`/`risk` must be **integer 1–5**,
  emitted at **error** level.
- **Every** active doc in this repo uses words; the install verify already flagged **12 errors**
  across `ADVERSARIAL-HARDENING.md`, `AUTONOMOUS-SELF-IMPROVEMENT-LOOP.md`,
  `GH-40-DOUBLE-BLIND-REVIEWER.md`, `RELAY-TO-ISSUE-SKILL.md`.
- **`utils/marathon-plan.sh` ranks survivors by these word ratings** — so the format is not just a
  doc-hygiene field, it is an input to live tooling. Changing it touches the planner + its tests.

### 3. Repo-specific tooling that the canonical runtime does NOT carry (must survive untouched)
`utils/marathon-plan.sh`, `utils/swarm-preflight.sh`, `utils/roadmap-dashboard.sh`,
`utils/validate-agy.sh`, `utils/telemetry/`, and `utils/pdda-check-ratings.sh` are **this repo's own**
surface, not upstream PDDA. The cutover must not delete or repoint these. Only the canonical-lineage
flat files (`pdda-run.sh`, the upstream-equivalent `pdda-check-*.sh`, `pdda-lib.sh`,
`pdda-doc-ready.sh`, `utils/PDDA-INSTALL.md`) are migration targets.

## Open decisions (operator) — resolve before Phase 1

- **D1 — Ratings format.** Pick one:
  - **(a) Adopt integers 1–5** → rewrite `complexity/risk/effort` in every active doc AND update
    `marathon-plan.sh` ranking + `test/marathon-plan.sh`. Most work; aligns with upstream.
  - **(b) Keep words** → patch the vendored `utils/pdda/pdda.sh` `check_frontmatter` to accept
    `low|medium|high` (or skip its rating validation). Least churn; **forks the vendored runtime**,
    which re-creates the drift PDDA exists to fight — note it explicitly.
  - **(c) Decouple** → keep the new frontmatter check's rating validation **off** and retain the
    repo's separate warn-only `pdda-check-ratings.sh` running alongside.
  - *Recommendation:* **(a)** if the repo intends to track upstream long-term; **(c)** if it wants the
    consolidation now with the least semantic churn. Avoid **(b)** unless words are load-bearing
    elsewhere.
- **D2 — Keep `pdda-check-ratings.sh`?** If D1=(a), it becomes redundant (delete). If D1=(c), it
  stays as the canonical home for the ratings rule. Decide jointly with D1.
- **D3 — Interim `PDDA.md` mismatch.** `install.sh` already overwrote `PROJECT/PDDA.md` (+224/−59) to
  the new contract that points at `utils/pdda/pdda.sh`, while the repo still runs the old paths. Until
  cutover, the contract describes a runtime the repo isn't using. Choose: **keep** (accept a short-
  lived mismatch this doc documents) or **`git restore PROJECT/PDDA.md`** and re-refresh it as the
  final cutover step. *Recommendation:* restore now, refresh at the end of Phase 3 — keeps the
  contract honest about what actually runs at every commit.

## Cutover plan (do NOT start until D1–D3 are settled)

### Phase 0 — Reconcile semantics (depends on D1/D2)
- [ ] Apply the D1 decision (rewrite doc ratings to integers, **or** patch/keep the rating check).
- [ ] If D1=(a): update `utils/marathon-plan.sh` + `test/marathon-plan.sh` to the integer scale; re-run.
- [ ] `utils/pdda/pdda.sh run` reports **0 rating errors** on the real tree.

### Phase 1 — Repoint the machine-driven rails (highest blast radius)
- [ ] `.claude/settings.json` — replace the 3 `utils/pdda-*` allow entries (`pdda-check-status-table.sh`,
      `pdda-check-frontmatter.sh`, `pdda-run.sh`) with the `utils/pdda/pdda.sh` equivalents.
- [ ] `validate.sh` + `test/pdda-roadmap-coverage.sh` — repoint to `utils/pdda/pdda.sh roadmap-coverage`
      (or the relevant subcommand); confirm the test still asserts the same behavior.
- [ ] Run `./validate.sh` → must stay green (currently 69/69) **before** deleting anything.

### Phase 2 — Repoint operator-facing docs
- [ ] `ROUTER.md` (startup seq line 7 + command-rails block lines 47–59) → `utils/pdda/pdda.sh` + its
      subcommands.
- [ ] `AGENTS.md` line 66, `GUIDING-PRINCIPLES.md` line 61, `FRONTDOOR.md`, `ROADMAP.md` contract banner
      (line 23) → new paths.
- [ ] Active `PROJECT/**` docs that reference old paths (`GH-30`, `MARATHON-PLANNER`, `AGENTS-DOCS.md`,
      etc.). **Leave `CHANGELOG.md` and `relay-system/**` history untouched** — they are dated records of
      what was true then, not live wiring.

### Phase 3 — Remove the old implementation + finalize contract
- [ ] `git rm` the canonical-lineage flat files: `utils/pdda-run.sh`, the upstream-equivalent
      `utils/pdda-check-*.sh`, flat `utils/pdda-lib.sh`, `utils/pdda-doc-ready.sh`,
      `utils/PDDA-INSTALL.md`. **Keep** `marathon-plan.sh`, `swarm-preflight.sh`, `roadmap-dashboard.sh`,
      `validate-agy.sh`, `telemetry/`, and (per D2) `pdda-check-ratings.sh`.
- [ ] Resolve D3: re-refresh / confirm `PROJECT/PDDA.md` now matches the live wiring.
- [ ] Grep clean: `git grep -e 'utils/pdda-run' -e 'utils/pdda-check' -e 'utils/pdda-lib' -e 'utils/pdda-doc-ready'`
      returns only `CHANGELOG.md` + `relay-system/**` historical hits.

## Verification gates
- `./validate.sh` green (≥ current 69/69) at the end of **each** phase.
- `utils/pdda/pdda.sh run` green in `full` mode (the repo's `.pdda-mode`) — **0 errors**, not just
  observe-mode pass.
- No duplicated `pdda-*` basename across `utils/` and `utils/pdda/`.
- `.claude/settings.json` hooks fire against the new dispatcher (smoke-test one doc edit).

## Rollback
The landed install is fully reversible at any point before Phase 3:
`rm -rf utils/pdda/`, `git restore PROJECT/PDDA.md .gitignore`, `rm PROJECT/{1-INBOX,2-WORKING,3-COMPLETED}/blank.md`
(only the newly-seeded ones) returns the repo to its exact pre-install state. After Phase 3, rollback
is `git revert`/branch-drop since `fix/upgrade-pdda` is a dedicated branch.

## Anti-goals
- Not deleting or rewiring repo-specific tooling (`marathon-plan.sh`, `swarm-preflight.sh`, telemetry).
- Not rewriting historical records (`CHANGELOG.md`, `relay-system/**`) to the new paths.
- Not forking the vendored `utils/pdda/` runtime unless D1=(b) is explicitly chosen and recorded.
- Not enabling cutover behavior incrementally in a half-wired state — each phase ends green or reverts.
