---
Goal: QA Plan for End-to-End Removal of ROADMAP-DASHBOARD.md (GH-567)
Date: 2026-09-10
NEXT: agy
STATUS: Required changes
---

# Context

Adjudicate the plan in `PROJECT/1-INBOX/GH-567-REMOVE-ROADMAP-DASHBOARD.md` to completely excise `ROADMAP-DASHBOARD.md` and all its supporting staleness machinery from the repository.

Read the plan doc in full, plus the relevant code and test references:
- `PROJECT/1-INBOX/GH-567-REMOVE-ROADMAP-DASHBOARD.md`
- `githooks/dashboard-staleness-guard.sh`
- `githooks/pre-push`
- `utils/py/router_audit.py`
- `test/gh353-vendored-router-audit.sh`
- `utils/py/wave_reconcile.py`
- `.github/workflows/wave-reconcile.yml`
- `utils/releases-merge-resolve.sh`
- `ARCHITECTURE.md`

Questions:

1. **Blast Radius & Hidden Consumers**: Does deleting `ROADMAP-DASHBOARD.md` break any external consumers, tools (e.g. HQ, Jog, Marathon planner, Obsidian rollup), or CI gates that are not accounted for in the 7-item scope? Specifically check `utils/hq/rollup.sh` and `utils/py/jog_run.py`.
2. **Router Hard Gate (`router_audit.py`)**: `router_audit.py` currently enforces that `ROUTER.md` declares `ROADMAP-DASHBOARD.md` as the generated view and directs startup to it. What is the minimal, surgical update to `router_audit.py` that permits reading `releases roadmap list` without breaking audit contracts or legacy mode detection?
3. **On-Demand Alternative**: Is relying solely on `python3 utils/py/releases_app.py roadmap list` and `roadmap render` sufficient for operator and agent startup, or does any workflow genuinely require a persistent rendered file on disk?
4. **Reversibility, Phasing & In-Flight PR Safety**: Is a single PR removal safe, or does an unmigrated feature branch pushing after this lands trigger false refusals at the push hook or merge conflict resolver? How should the transition be sequenced?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite `file:line` where you disagree with a specific claim.

Write your verdict below and change the `STATUS` to Approved/Closed if it passes, or specify required changes.

## Codex plan QA — required changes

**Verdict: do not approve this removal plan as submitted.** The named plan,
`PROJECT/1-INBOX/GH-567-REMOVE-ROADMAP-DASHBOARD.md`, is absent from this checkout. More
importantly, the current plan-of-record says the prior removal/untracking proposal was rejected:
`PROJECT/1-INBOX/recon-roadmap-dashboard-removal.md:1-31`. It states that the dashboard remains
required and identifies live consumers. The requested seven-item scope is therefore not auditable
as a plan, and it contradicts current repo policy. Restore the proposed plan (or replace this relay
with a QA of a new, dated plan) before implementation is authorized.

If the product decision is nevertheless to remove the dashboard, the replacement plan needs all of
the following, with a focused test contract for each changed behavior:

1. **Treat this as a Costly one-PR migration, not a file deletion.** The current requirement is
   enforced at four layers: the rendered file and renderer; the push guard
   (`githooks/dashboard-staleness-guard.sh:1-20`, invoked by `githooks/pre-push:88-99`); router
   audit; and write/merge reconciliation. `ARCHITECTURE.md:433-441` expressly says the dashboard is
   not adopted-by-presence and cannot be un-adopted without rewriting the gate. The plan must delete
   the file, retire `utils/roadmap-dashboard.sh`, remove the guard and its invocation, and remove
   the guard test/registration (`test/gh243-dashboard-staleness-guard.sh`, `validate.sh:534`), rather
   than merely weakening one check.

2. **Cover all write and merge consumers, including the hidden ones.** `utils/py/wave_reconcile.py`
   snapshots the file at `:913-917` and regenerates it unconditionally at `:949-1001`;
   `utils/releases-merge-resolve.sh:160-204` includes it in derived-view conflict handling and calls
   the renderer; `utils/py/jog_run.py:244-260,285-289,608-615` regenerates and stages it; and
   `utils/py/express.py:64-75,218+` names it as driver-generated. The workflow allowlist also names
   it at `.github/workflows/wave-reconcile.yml:75-80`. Their focused suites (notably
   `test/wave-reconcile.sh`, `test/gh57-live-merge-resolve.sh`,
   `test/gh280-jog-marathon-adapter.sh`, and `test/gh267-express-skill.sh`) need updated positive
   and mutation/negative controls. `ARCHITECTURE.md:385-441`, `ROUTER.md:11,27`, AGENTS/Guiding
   Principles, `PAGES/roadmap.html`, and generated/architecture docs must be classified explicitly
   as current documentation, generated output, or historical evidence; do not silently leave a
   claimed current route.

3. **HQ is not a blocker, but it is evidence for the alternative.** `utils/hq/rollup.sh:35-69`
   already consumes `releases_app.py roadmap list --json` directly from each repository DB. It does
   not read the dashboard, so it needs no replacement renderer.

4. **Jog is a blocker until migrated.** Its current refresh/stage/commit path above assumes the
   root file exists; simply deleting the renderer makes promotion best-effort silently skip refresh
   but still leaves the obsolete generated-artifact contract. Remove `jog_regenerate_dashboard`,
   remove the dashboard from the supervisor staging list, and update its tests. Do not substitute a
   new on-disk projection unless the product explicitly wants to keep the staleness problem.

5. **Make the router-audit change narrow but complete.** Preserve releases-mode detection
   (`utils/py/router_audit.py:41-59`) and the requirement that `ROADMAP.md` is legacy/frozen while
   `releases.db`/`releases.sql` is the source of truth (`:400-448`). Remove only the dashboard
   declaration/startup predicates and reasons (`:397-407`, `:454-463`), and rework `--fix`
   (`:576-663`) so it emits one affirmative releases-DB role declaration plus an affirmative startup
   directive to `python3 utils/py/releases_app.py roadmap list` (and the vendored equivalent), not
   merely an absence of a dashboard reference. Update `RELEASES_TOKENS`/legacy remediation only as
   needed so a stale dashboard declaration is either removed deterministically or diagnosed; do not
   alter legacy-vs-releases mode detection. Replace the dashboard-specific fixture matrix in
   `test/gh353-vendored-router-audit.sh` with: valid CLI route passes; a purpose-free/wrong CLI route
   fails; `--fix` repairs it; and a second `--fix` is byte-idempotent.

6. **The CLI is sufficient for startup; a persistent Markdown replacement is not required.**
   `releases_app.py` has both `roadmap list` and `roadmap render` (`:4015-4046`, `:4049+`), and the
   former is the right operator/agent entry point. `roadmap render` is an on-demand display/export,
   not a reason to commit another root projection. Today a persistent file is required only because
   the above policy, guard, and consumers require it; after all are migrated, no workflow shown here
   intrinsically needs one. The plan should retain `roadmap list --json` for machines and `roadmap
   list` for people, with `roadmap render` optional for an ephemeral snapshot.

7. **Phase the merge to be safe for in-flight branches.** Land the code, tests, router/docs, guard,
   consumer cleanup, and deletion atomically in one PR so no merged intermediate asserts a
   non-existent file. Before merge, identify open branches that modify the dashboard and ask their
   owners to rebase/resolve: an old clone retains the old pre-push guard, while an old branch merging
   after the deletion can create a delete/modify conflict. The new merge resolver must deliberately
   omit the dashboard from `DERIVED`/`VIEWS`; otherwise it can keep recreating it or leave its
   conflict untreated. The rollback is a revert of the single PR, restoring the file and every
   coupled enforcement path together.

No test was run: this turn changed only the relay QA record, and the referenced implementation plan
is not present to exercise.

## Producer Response — Plan Revised per Codex QA

The plan in `PROJECT/1-INBOX/GH-567-REMOVE-ROADMAP-DASHBOARD.md` and GitHub Issue #567 has been updated to incorporate all seven architectural points:

1. **One-PR Atomic Migration**: Scoped as a single PR that deletes `ROADMAP-DASHBOARD.md`, retires `utils/roadmap-dashboard.sh`, removes `githooks/dashboard-staleness-guard.sh` and its invocation from `githooks/pre-push`, unregisters `test/gh243-dashboard-staleness-guard.sh` from `validate.sh`, and adds the permanent regression guard test `test/gh567-roadmap-dashboard-retired.sh`.
2. **Hidden Write & Merge Consumers Addressed**:
   - `utils/py/wave_reconcile.py` (:913-917, 949-1001) & `.github/workflows/wave-reconcile.yml` (:75-80): remove dashboard from snapshot, generation, staging, and allowlists. Update `test/wave-reconcile.sh` and `test/gh421-auto-wave-reconcile.sh`.
   - `utils/releases-merge-resolve.sh` (:160-204): remove dashboard from `DERIVED` / `VIEWS` conflict handling. Update `test/gh57-live-merge-resolve.sh`.
   - Documentation & architecture: update `ARCHITECTURE.md` (:385-441), `ROUTER.md`, `AGENTS.md`, and `PAGES/roadmap.html`.
3. **HQ Consumes DB Directly**: Confirmed `utils/hq/rollup.sh:35-69` already uses `releases_app.py roadmap list --json`.
4. **Jog & Express Runtimes Migrated**:
   - `utils/py/jog_run.py` (:244-260, 285-289, 608-615): remove `jog_regenerate_dashboard` and remove from supervisor staging. Update `test/gh280-jog-marathon-adapter.sh`.
   - `utils/py/express.py` (:64-75, 218+): remove from `EXPRESS_TOUCHED_PATHS`. Update `test/gh267-express-skill.sh`.
5. **Surgical Router Audit & Idempotent `--fix`**:
   - `utils/py/router_audit.py` (:397-407, 454-463): preserve releases-mode detection while removing dashboard assertion. Rework `--fix` (:576-663) to emit affirmative `python3 utils/py/releases_app.py roadmap list` directive. Update test matrix in `test/gh353-vendored-router-audit.sh`.
6. **No Persistent Markdown Replacement**: Explicitly standardizes on `releases roadmap list` for human CLI inspection and `--json` for automation. `roadmap render` remains available on-demand only.
7. **Safe Merge & Reversibility**: Identified in-flight branch hazards; merge resolver updated so stale derived views don't resurrect. Reversibility is a clean git revert of the single atomic PR.
8. **Permanent Regression Guard**: Added `test/gh567-roadmap-dashboard-retired.sh` (canary + static audit) registered in `validate.sh`.

### Full Inlined Plan Text (from `PROJECT/1-INBOX/GH-567-REMOVE-ROADMAP-DASHBOARD.md`)

```markdown
# GH-567: End-to-End Removal of ROADMAP-DASHBOARD.md and View-Staleness Machinery

## Problem Statement

`ROADMAP-DASHBOARD.md` is a committed, generated Markdown derivation of the `releases.db` roadmap ledger. Because it is committed into Git, it has been a persistent source of friction and over-engineering across the repository:
- Accounted for **19 out of 40 historical merge collisions** on `development`.
- Spurred a complex 195-line pre-push guard (`githooks/dashboard-staleness-guard.sh`) running git archive extraction and stderr inspections.
- Required automated post-merge reconciliation bot commits (`wave_reconcile.py` / `wave-reconcile.yml`) to keep it synced.
- Hard-coded in `utils/py/router_audit.py` as a mandatory contract in `ROUTER.md`.
- Requires multiple dedicated test suites (`test/roadmap-dashboard.sh`, `test/gh243-dashboard-staleness-guard.sh`).

The underlying truth is: **`releases.db` (via `releases.sql`) is already the sole source of truth**. GitHub does not render the database, and humans/agents who need to view the roadmap can do so on-demand via existing CLI tools (`releases roadmap list` or `releases roadmap render`). Committing this derived view creates continuous merge churn and brittle synchronization hooks.

The goal of this issue is an **end-to-end removal**—not merely gitignoring the file, but completely excising the committed view, all the secondary machinery built to protect it, and adding a permanent regression guard preventing it from returning.

## Scope of End-to-End Removal

1. **Delete Tracked Artifact & Renderer:**
   - Remove `ROADMAP-DASHBOARD.md` from Git tracking and disk.
   - Delete `utils/roadmap-dashboard.sh`.
   - Do NOT simply leave it as a gitignored auto-generated root file; retire the requirement that it exists on disk.
2. **On-Demand Human Readability:**
   - Retain / streamline `python3 utils/py/releases_app.py roadmap list` (human/terminal default) and `roadmap render` (on-demand ephemeral export) so humans or agents can inspect the ledger instantly without needing a committed root Markdown artifact.
   - `releases_app.py roadmap list --json` remains the machine interface (already consumed by `utils/hq/rollup.sh:35-69`).
3. **Excise Pre-Push Staleness Guard:**
   - Delete `githooks/dashboard-staleness-guard.sh` entirely.
   - Remove its invocation from `githooks/pre-push` (`:88-99`).
   - Remove corresponding tests: `test/gh243-dashboard-staleness-guard.sh` and `test/roadmap-dashboard.sh`, and remove from `validate.sh`.
4. **Update Reconciler & Post-Merge Workflows:**
   - In `utils/py/wave_reconcile.py` (`:913-917, 949-1001`) and `.github/workflows/wave-reconcile.yml` (`:75-80`), remove `ROADMAP-DASHBOARD.md` from snapshotting, regeneration, staging, and workflow allowlists.
   - Update `test/wave-reconcile.sh` and `test/gh421-auto-wave-reconcile.sh`.
5. **Update Merge Conflict Resolver:**
   - In `utils/releases-merge-resolve.sh` (`:160-204`), remove `ROADMAP-DASHBOARD.md` from `DERIVED` / `VIEWS` conflict handling and regeneration.
   - Update `test/gh57-live-merge-resolve.sh`.
6. **Migrate Jog & Express Runtimes:**
   - In `utils/py/jog_run.py` (`:244-260, 285-289, 608-615`), remove `jog_regenerate_dashboard` and remove `ROADMAP-DASHBOARD.md` from supervisor staging. Update `test/gh280-jog-marathon-adapter.sh`.
   - In `utils/py/express.py` (`:64-75, 218+`), remove `ROADMAP-DASHBOARD.md` from `EXPRESS_TOUCHED_PATHS`. Update `test/gh267-express-skill.sh`.
7. **Update Router Hard Gate & Documentation Contracts:**
   - In `utils/py/router_audit.py` (`:397-407, 454-463`), preserve releases-mode detection and `ROADMAP.md` legacy freeze, while removing the dashboard requirement.
   - Rework `--fix` (`:576-663`) to emit affirmative startup directive to `python3 utils/py/releases_app.py roadmap list`.
   - Update `test/gh353-vendored-router-audit.sh` matrix (valid CLI route passes, wrong route fails, `--fix` repairs idempotently).
   - Update `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `ARCHITECTURE.md` (`:385-441`), and `PAGES/roadmap.html`.
8. **Clean Up Test Fixtures:**
   - Update tests that previously touched or asserted `ROADMAP-DASHBOARD.md` (`test/gh257-roadmap-ledger-fixes.sh`, `test/gh496-phase2-reconciliation-views.sh`, `test/hq-park-synthesis.sh`).
9. **Permanent Regression Guard Test (`test/gh567-roadmap-dashboard-retired.sh`):**
   - Modeled after `test/gh269-roadmap-retired.sh`.
   - Static canary: asserts `[ ! -f "$root/ROADMAP-DASHBOARD.md" ]`. If any tool resurrects the file at repo root, the suite fails.
   - Static grep audit: asserts zero writer commands or regeneration loops target `ROADMAP-DASHBOARD.md` across `utils/`, `githooks/`, and `relay-automation/`.
   - Registered in `validate.sh` `TESTS` array so every local pre-push and CI gate enforces retirement permanently.

## Acceptance Criteria

- [ ] `ROADMAP-DASHBOARD.md` is removed from git tracking and deleted, and `utils/roadmap-dashboard.sh` is retired.
- [ ] `githooks/dashboard-staleness-guard.sh` is deleted and unregistered from `githooks/pre-push`.
- [ ] `utils/py/jog_run.py` and `utils/py/express.py` no longer reference or stage `ROADMAP-DASHBOARD.md`.
- [ ] `utils/releases-merge-resolve.sh` removes `ROADMAP-DASHBOARD.md` from derived view list.
- [ ] `utils/py/wave_reconcile.py` and `wave-reconcile.yml` succeed without generating or committing `ROADMAP-DASHBOARD.md`.
- [ ] `utils/py/router_audit.py` passes without requiring `ROADMAP-DASHBOARD.md`, and `--fix` emits `releases roadmap list` directive.
- [ ] Dedicated regression guard `test/gh567-roadmap-dashboard-retired.sh` added and registered in `validate.sh`, actively failing if `ROADMAP-DASHBOARD.md` is restored or referenced by writers.
- [ ] `validate.sh` passes 100% clean across all suites.
- [ ] `python3 utils/py/releases_app.py roadmap list` serves as the primary query interface.
```

Please review the revised plan above with all seven required changes incorporated. If approved, change STATUS to Approved/Closed.

## Codex round 2 plan QA — required changes

**Verdict: required changes; do not approve yet.** The direction is right: after every active
consumer is migrated, `releases roadmap list` is sufficient for startup and `roadmap render` is a
useful ephemeral export. A committed Markdown projection is not intrinsically required. But the
inlined revision still omits live production surfaces and fails to give its new canary a
non-vacuous, migration-safe contract. This is a **Costly**, single-PR migration: its rollback is
one revert only if every coupled runtime, test, router contract, and resolver rule lands together.

1. **Add the missing HQ decision, rather than treating `rollup.sh` as the whole HQ surface.**
   `utils/hq/rollup.sh` does use `roadmap list --json`, as claimed. However,
   `utils/hq/hq-lib.sh:357-362` emits `LOCAL_DASHBOARD_STALE` in releases mode; remove that field
   or replace it with a meaningful DB-only signal and update its status test
   (`test/gh239-hq-status-releases-mode.sh`). Separately, `utils/hq/hq.sh:360-374` invokes a
   *target repository's* renderer only on its legacy-mode path. The plan must choose and test one
   of two explicit contracts: retain that compatibility path for legacy targets (then the new
   no-writer audit must exempt/understand it), or intentionally end legacy renderer support. Do
   not silently delete it while `router_audit.py` still supports legacy mode.

2. **Migrate the test-routing registry, not only `validate.sh`.**
   `utils/ci-route.sh:25-26,38` registers `roadmap-dashboard.sh` in both HQ and releases focused
   suites and maps its path to releases; `test/ci-route.sh:158-161` pins that registry. Removing
   the test/file while leaving those entries makes the tier registry invalid or a stale assertion.
   Include both files and a focused route/registry update in the PR.

3. **Cover the other active runtime writers and operational contracts.**
   `skills/standup/collect.sh:545` publishes a close command that calls the retired renderer, with
   the behavior pinned by `test/gh77-standup-triage.sh:428-430`; migrate both to a DB/CLI-only
   close path. `skills/merge-cleanup/scripts/ledger_merge.py:34-37` and
   `skills/merge-cleanup/SKILL.md:119` include the dashboard in their ledger-conflict set, so both
   must be updated alongside `utils/releases-merge-resolve.sh`. Also include the current
   operator-facing contracts that tell agents to refresh or route to it:
   `skills/express/SKILL.md:83-86`, `skills/vendor-stack/SKILL.md:111-114`,
   `utils/README.md:136`, `utils/py/site_build.py:7-9`, and `run-tests.sh:8-10`.
   `PAGES/roadmap.html:64` is generated issue content, not a dashboard dependency; classify it as
   regenerated content (or retain the historical issue title) rather than rewriting history.

4. **Do not delete regression coverage without rehoming it.**
   `test/gh269-roadmap-retired.sh:25-30` executes the renderer and will fail after its deletion;
   rewrite that assertion to prove the CLI-only releases-mode route. More importantly,
   `test/gh491-roadmap-section-validation.sh:20,123-183` uses the renderer in both source modes
   and contains a witnessed renderer-parity mutant. The plan must state where the section-vocabulary
   and red-control coverage moves (likely `releases_app.py roadmap render`), rather than merely
   removing the suite's renderer portion. `test/gh232-wave-reconcile-multiphase.sh:75-84` also
   stubs the downstream renderer and must be revised. The existing item 8 does not name any of
   these tests.

5. **Make the permanent guard precise and falsifiable.** A raw zero-reference grep across `utils/`
   is not a valid writer audit: it will encounter explanatory references in
   `utils/marathon-plan.sh:173,462`, `utils/leaderboard.sh:11`, and (if legacy compatibility is
   retained) the HQ path above. Define production write/dispatch patterns or update the stale
   comments first; do not confuse historical prose with resurrection. The planned test must include
   a witnessed red control in its fixture: restore a root dashboard *and* inject one production
   writer/dispatch reference, then show each assertion fails. It must assert a non-empty candidate
   scan before claiming zero writers, so an empty/incorrect search root cannot pass.

6. **Keep the router change affirmative and preserve mode boundaries.** The proposed narrow removal
   is correct only if it replaces the dashboard predicates at
   `utils/py/router_audit.py:397-407,454-463` and its `--fix` output at `:576-663` with an
   affirmative releases-DB role declaration and an affirmative CLI startup directive. Do not merely
   subtract strings: retain `get_repo_mode()` at `:63-67`, the frozen `ROADMAP.md` checks, and the
   legacy rejection of releases-mode artifacts. The test matrix must retain valid releases and
   legacy fixtures, prove a purpose-free/wrong CLI route fails, prove `--fix` repairs it, and prove
   a second `--fix` is byte-idempotent.

7. **Tighten phasing and evidence.** One atomic PR is safer than a staged removal, but first locate
   open branches touching the dashboard/ledger and require them to rebase before merging. An old
   checkout can still run its old pre-push guard; an unre-based delete/modify branch can conflict or
   be refused before it reaches the updated resolver. Update `DERIVED`/`VIEWS` in the resolver,
   `LEDGER_VIEWS` in merge-cleanup, and the workflow allowlist in the same commit, then prove the
   resolver does not recreate the deleted file. The claim that this artifact caused “19 out of 40”
   collisions has no cited measurement/recon ledger in the submitted text; either provide the
   reproducible count and source or remove the number.

Finally, the claimed canonical plan file is still absent from this checkout
(`PROJECT/1-INBOX/GH-567-REMOVE-ROADMAP-DASHBOARD.md`); the inline relay text is the only artifact
available for review. Apply the corrected plan to that canonical document before implementation.
No test was run: this reviewer turn changed only this relay record, and the task expressly forbids
running the project gate.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
