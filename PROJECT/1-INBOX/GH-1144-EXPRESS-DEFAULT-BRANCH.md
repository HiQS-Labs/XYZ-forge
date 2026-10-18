---
gh_issue: 1144
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1144
title: "express: target the repo's default branch (or --base) instead of hardcoded development"
status: "Captured — plan drafted, awaiting plan QA"
created: 2026-10-18
updated: 2026-10-18
owner: claude
goal: "Let /express land on a repo whose integration branch is not `development` (e.g. `main`), resolving the branch once per run, with XYZ Forge's own behaviour unchanged"
doc_type: feature
effort: 2
complexity: 2
risk: 2
phases: 1
fix_probes:
  - "grep -q 'base-unresolved' utils/py/express.py"
  - "grep -q -- '--base' utils/py/wave_reconcile.py"
---

# GH-1144 — express targets the repo's integration branch, not a hardcoded `development`

Issue #1144 is the brief. Origin: on 2026-10-18 an operator asked for `/express --docs-only` in
HiQS-Labs/XYZ-layout-engine (default branch `main`, no `development`); the lane could not start and the
archive landed by hand (XYZ-layout-engine `0d6706c`).
Branch `feat/XYZ-forge-gh1144-express-default-branch-2026-10-18` off `development@9a61625f`.

## Status

| What was just completed | What's next |
|---|---|
| Issue filed, clone provisioned off `origin/development` (`9a61625f`, hooks installed), recon, plan drafted | Codex plan QA, then promote to 2-WORKING |

## Observed today (9a61625f)

- `utils/py/express.py` names `development` 53 times. Load-bearing sites:
  - Base/bounds: `is_documentation_update` `:102` (`ls-tree origin/development`), `change_paths` `:360-362`,
    `insertions` `:429` (diff/`--numstat` against `origin/development`).
  - Task-clone pre-flight `cmd_check` `:457-474`: refuses running on `development`/`main`/detached; checks
    `origin/development` exists, ancestry, and ≤ 2 commits ahead.
  - Landing `cmd_land` `:853`: `git push origin HEAD:development` (`XYZ_SKIP_PREPUSH=1`).
  - Closeout `:858-867`: checkout/pull `development`, clean-tree refusal, reachability from `origin/development`.
  - `persist_closeout` `:994`: `git push origin development`.
  - `resolve_landing_commit` `:1036-1086`: reachability and `git log origin/development`.
  - `cmd_resume` `:1177-1183`: switch to and pull `development`.
  - Messages/receipts/help: `:5-14`, `:313`, `:335`, `:840`, `:905`, `:912`, `:931`, `:949`, `:1200`, `:1209`,
    `:1280`, `:1287`.
- `reconcile_gated` `:938-949` runs `wave_reconcile.py --commit <sha> --root <root> --gate` and passes no branch.
- `utils/py/wave_reconcile.py` on that direct-commit path assumes `development` in four places:
  `check_current_branch(expected_branch="development")` `:286` (called `:2220`), `pull_upstream(branch="development")`
  `:300` (called `:2229`), `fetch_commit_metadata` `:408-452` (reachability from local `development` `:433`,
  synthesized `baseRefName: "development"` `:418`, `:449`), and the base guard `:2319-2321`
  (`base_ref != "development"` dies). Its PR, catch-up and hosted-qualification modes (`:396`, `:680-738`,
  `:1334-1501`, `:2297`) are Forge-only flows tied to Forge's `development` PRs and stay untouched.
- XYZ Forge's default branch is `development` (`git symbolic-ref --short refs/remotes/origin/HEAD` →
  `origin/development`; `gh repo view … defaultBranchRef` → `development`), so resolving the default branch
  keeps Forge's behaviour.
- Covering suites (registered in `validate.sh`): `test/gh267-express-skill.sh` (express end to end on a fixture
  repo) and the wave-reconcile suites (`wave-reconcile.sh`, `gh168-…`, `gh202-…`, `gh232-…`, `gh358-…`,
  `gh421-…`, `gh425-…`, `gh429-…`, `gh454-…`). The express fixture builds its remote with `git init --bare` +
  `remote add` (`test/gh267-express-skill.sh:111-113`), so it has **no** `refs/remotes/origin/HEAD`, and its
  `gh` is a stub. A resolver that requires `origin/HEAD` or a live `gh` call would refuse there.
- Prior art: `prior_art_recon.py --query "express development branch"` listed 26 "possible existing fix"
  matches; all are keyword matches (Pages publishing #1053, hosted catch-up #877, marathon batches, task
  starts #723), none changes express's branch. Current `origin/development` still pushes `HEAD:development`
  (`:853`).

## Preflight bet

- Outcome sought: `/express` works in a repo whose integration branch is `main` (or any named branch), with
  every existing express invariant intact and XYZ Forge's behaviour and receipts unchanged.
- Smallest viable bet: resolve one base branch per run in `express.py` (`--base` flag, else `origin/HEAD`,
  else `development` when `origin/development` exists, else refuse `base-unresolved`); keep it in one module
  value used at every site above; pass it to `wave_reconcile.py` through a new `--base` (default
  `development`) used only on the direct-commit path's four sites.
- Not built: no `gh repo view` fallback (a network call the offline fixture cannot answer, and `origin/HEAD`
  plus `git remote set-head origin --auto` already cover it); no change to wave_reconcile's PR, catch-up or
  hosted modes; no new suite; no change to the vendored-host blockers (`validate.sh`, `test/pdda-repo-contract.sh`,
  `githooks/install.sh`), which the issue scopes out.
- Alternatives rejected: (a) a repo config file naming the branch — a new state surface for what git already
  records in `origin/HEAD`; (b) threading `base` through every function signature — touches ~15 signatures for
  one value that is constant per run; a module value set once in `main()` keeps library callers (the recovery
  recipe imports `express.write_receipt`) on today's default; (c) refusing whenever `origin/HEAD` is missing —
  breaks the existing fixture and every clone made with `git init` + `remote add`.
- Rollback: revert the commit; default behaviour is today's.
- Reversibility: **Easy** to revert; the change sits on express's direct-push authority, so it is reviewed as
  at least Costly-adjacent (AGENTS: landing behaviour) even though Forge's resolved branch is unchanged.

## Changes (ordered, verification inline)

1. `express.py`: `BASE = "development"` module default; `resolve_base(root, explicit)` returns `explicit`, else
   the branch named by `git symbolic-ref --short refs/remotes/origin/HEAD` (minus `origin/`), else
   `development` when `git rev-parse --verify origin/development` succeeds, else `None`. `main()` resolves once
   after parsing; `None` → `refuse(root, "base-unresolved", …)` before any phase writes. `--base` is added to the
   shared subcommand arguments and to `resume`.
2. Replace every load-bearing literal above with `BASE` / `"origin/" + BASE`. The task-branch refusal keeps
   `development`, `main` and detached, and adds `BASE` (never run express from the integration branch itself).
   Messages, receipt `environment`, help text name the resolved branch (in Forge they read exactly as today).
3. `reconcile_gated` passes `--base BASE` to `wave_reconcile.py`.
4. `wave_reconcile.py`: `--base` argument (default `development`); used by `check_current_branch` and
   `pull_upstream` calls at `:2220`/`:2229`, `fetch_commit_metadata` reachability and synthesized
   `baseRefName`, and the base guard at `:2319-2321`. Default keeps every existing caller byte-identical.
5. `skills/2-daily/express/SKILL.md`: one short paragraph — express lands on the resolved base
   (`--base`, else `origin/HEAD`, else `development`); no other wording change.
6. Verification (no new suite, GH-831):
   - `bash test/gh267-express-skill.sh` and the wave-reconcile suites green, unchanged (their fixtures resolve
     `development` through the fallback).
   - Manual checks under `TESTS-RESULTS/2026-10-18+GH-1144/` with `provenance.jsonl`, in a disposable clone,
     on a scratch fixture built like gh267's but with `main` as the only branch and `origin/HEAD → origin/main`:
     `express.py run --docs-only --dry-run` previews `push to origin/main`; the same with `--base main` and no
     `origin/HEAD`; a fixture with neither `origin/HEAD` nor `origin/development` refuses `base-unresolved`
     and writes nothing (red control: the old code on the `main` fixture refuses `task-clone`
     "origin/development not found").
   - Smoke (GH-1088): one real `--dry-run` from this Forge clone (main path: resolves `development`, output
     unchanged versus `origin/development`'s express on the same input) and one adjacent path (`resume
     --dry-run` on the `main` fixture resolves `main`).
   - Final gate per `utils/ci-route.sh` on the changed paths (code → full route), once, on the final commit.

## Non-goals

No change to wave_reconcile's PR/catch-up/hosted modes; no vendored-host enablement (`validate.sh`, docs suite,
`githooks/install.sh` under `.xyz/`); no new suite or gate; no change to bounds, refusals, receipts, ship or
reconcile ordering.

## Risks

- A clone with a stale `origin/HEAD` (set at clone time) could resolve an outdated branch. Mitigation: explicit
  `--base` wins; the refusal and dry-run name the resolved branch so the operator sees it before landing.
- Missing a literal leaves a split-brain run (bounds on `main`, push to `development`). Mitigation: after the
  edit, `grep -n development utils/py/express.py` must show only the default, the task-branch refusal, and the
  `origin/development` fallback; the `main` fixture dry-run exercises push, closeout and reconcile previews.

## Acceptance

- `main`-only fixture with `origin/HEAD`: `run --docs-only --dry-run` resolves `main` and previews pushing to
  `origin/main`; bounds and ancestry use `origin/main`.
- Same fixture, no `origin/HEAD`, `--base main`: same result.
- No `origin/HEAD`, no `origin/development`, no `--base`: exits with `base-unresolved`, no tick/doc/ledger writes.
- XYZ Forge clone: dry-run output and receipt wording unchanged; `test/gh267-express-skill.sh` and the
  wave-reconcile suites pass unmodified.
- `wave_reconcile.py --commit <sha> --base main` accepts a commit reachable from local `main` and reports base
  `main`; without `--base` behaviour is unchanged.

## Per-issue map

| Issue | Requirement | Clone / branch | State |
|---|---|---|---|
| [#1144](https://github.com/HiQS-Labs/XYZ-forge/issues/1144) | Changes 1–6 | `XYZ-forge-gh1144-express-default-branch-2026-10-18` / `feat/…` | Plan drafted |

## Rating rationale (2026-10-18)

`rated 40/30/50/55`. Severity 30: express is unusable in every non-`development` repo; the workaround is a
manual landing, so no data or work is lost. Priority 40: one observed blocked use (XYZ-layout-engine, 2026-10-18);
operator asked for it now. Appeal 50: neutral default. Effort 55: one file's literals plus a narrow reconcile
argument, on well-covered code with existing suites. Recurrence: one incident in the last 14 days; none in
the preceding 14; trend unknown.

## Evidence

| Check | Result |
|---|---|
| Plan QA | pending |
