---
gh_issue: 1144
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1144
title: "express: target the repo's default branch (or --base) instead of hardcoded development"
status: "In progress — plan QA Approved (Codex, round 3), implementing"
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
| Plan QA Approved by Codex in round 3 (`relay-system/2026-10-18/gh1144-plan-qa.md`) | Implement changes 1–6, then the verification in 7 |

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
- Smallest viable bet: resolve one base branch per run in `express.py`: `--base` flag, else `origin/HEAD`, else
  GitHub's recorded default (`gh repo view <repo> --json defaultBranchRef`), else refuse `base-unresolved`
  (plan QA S5: the issue's "never guess"; ref existence is not evidence). Every candidate must also exist as
  `origin/<base>`. Keep it in one module value used at every site above; pass it to `wave_reconcile.py`
  through a new `--base` (default `development`) used only on the direct-commit path's four sites.
- Not built: no fallback that infers the branch from which refs exist; no change to wave_reconcile's PR,
  catch-up or hosted modes; no new suite; no change to the vendored-host blockers (`validate.sh`,
  `test/pdda-repo-contract.sh`, `githooks/install.sh`), which the issue scopes out.
- Alternatives rejected: (a) a repo config file naming the branch — a new state surface for what git already
  records in `origin/HEAD`; (b) threading `base` through every function signature — touches ~15 signatures for
  one value that is constant per run (express dispatches one command per process, `express.py:1246-1312`);
  the one library entry point used outside `main()`, `write_receipt` (imported by the recovery recipe), gets
  an explicit optional `base` argument instead; (c) an `origin/development` existence fallback — picks a
  direct-push target with no evidence the operator authorized it (plan QA S5).
- Rollback: revert the commit; default behaviour is today's.
- Reversibility: **Easy** to revert the code, but reverting cannot undo a misdirected remote landing. Stop
  signal: any disagreement between the resolved base and a push, pull, reachability or reconcile destination.
  Last safe checkpoint: before the first push. Fast-forward-only authority is unchanged.

## Changes (ordered, verification inline)

1. `express.py`: `BASE = "development"` module default; `resolve_base(root, repo, explicit)` returns
   `explicit`, else the branch named by `git symbolic-ref --short refs/remotes/origin/HEAD` (minus `origin/`),
   else `gh repo view <repo> --json defaultBranchRef --jq .defaultBranchRef.name`; the candidate is accepted only
   when it is a plain branch name and `origin/<candidate>` verifies; otherwise `None`. `main()` resolves once
   after parsing; `None` → `refuse(root, "base-unresolved", …)` before any phase writes docs, ledger or git
   state. Like every other express refusal it records `express-refused` telemetry (the skill: "all refusals …
   write `.tick/express/*`"); plan QA B1 asked to suppress it — kept consistent with the other refusals instead,
   and the acceptance wording now says no doc/ledger/git writes. `--base` is added to the shared subcommand
   arguments and to `resume`. `write_receipt(root, sha, issue, suite, rc, base=None)` uses `base or BASE` in its
   `environment` text.
2. Replace every load-bearing literal above with `BASE` / `"origin/" + BASE`. The task-branch refusal keeps
   `development`, `main` and detached, and adds `BASE` (never run express from the integration branch itself).
   Messages, receipt `environment`, help text name the resolved branch (in Forge they read exactly as today).
3. `reconcile_gated` passes `--base BASE` to `wave_reconcile.py`.
4. `wave_reconcile.py`: `--base` argument (default `development`, so PR/catch-up/qualification runs that
   never pass it are unchanged even though the branch and pull preflight at `:2220`/`:2229` are shared with
   those modes); used by the `check_current_branch` and `pull_upstream` calls at `:2220`/`:2229`, `fetch_commit_metadata` reachability and synthesized
   `baseRefName`, and the base guard at `:2319-2321`. Default keeps every existing caller byte-identical.
5. `skills/2-daily/express/SKILL.md`: a short paragraph on base resolution (`--base`, else `origin/HEAD`, else
   GitHub's default branch, else refuse), "development" in the procedure and phase text reworded to "the
   resolved base (development in XYZ Forge)", and the recovery recipe made executable on any base: one
   `BASE=<branch>` variable, `git checkout "$BASE"`, `git push origin "$BASE"`, `write_receipt(..., base='$BASE')`
   and `resume --base "$BASE"` (plan QA S4). Forge's default wording and receipts are unchanged.
6. Existing suite kept truthful (GH-831 permits editing a suite whose pinned behaviour changes; no new suite or
   registry entry): `test/gh267-express-skill.sh` — (a) the source audit at `:753` asserts the landing pushes
   `"HEAD:" + BASE` (direct fast-forward push to the resolved base) instead of the literal `HEAD:development`;
   (b) the fixture declares its integration branch with `git remote set-head origin development` once its
   remote has `development` (its `gh` stub returns no `defaultBranchRef`, so without this the new resolver
   correctly refuses). No other assertion changes.
7. Verification:
   - `bash test/gh267-express-skill.sh` and the wave-reconcile suites green (in a disposable full clone).
   - Red control for (6a): mutate `cmd_land` to push a hardcoded `HEAD:development` while bounds use `BASE`;
     the adjusted assertion fails; restore → passes.
   - Main-only end-to-end manual check (plan QA S3), recorded under `TESTS-RESULTS/2026-10-18+GH-1144/` with
     `provenance.jsonl`, in a disposable full clone: a scratch copy of `gh267-express-skill.sh` with its
     fixture's integration branch renamed `development` → `main` (`origin/HEAD → origin/main`) runs the full
     non-preview `run` and `resume`; inspect the bare remote's refs (`main` advanced, no `development` created),
     the fixture's final branch and cleanliness, the committed receipt naming `main`, and a passing
     `wave_reconcile --commit … --base main --gate`. Red control: the same scratch run against a build whose
     push destination alone is hardcoded to `development` must fail (remote `main` unchanged or refusal);
     restore → passes.
   - Production reconciler on a main-only repo (plan QA round 2): gh267's fixture installs its own
     `wave_reconcile.py` stub (`test/gh267-express-skill.sh:173-213`), so the scratch run above cannot exercise
     the changed module. Separately, in the disposable clone, run the canonical `utils/py/wave_reconcile.py
     --commit <sha> --base main --gate` against a scratch repo whose only branch is `main` (commit with
     `Closes #N`, a committed express receipt for that sha, harness tools resolved from the clone as the
     existing wave-reconcile suites do). Expect: the commit is accepted as reachable from `main`, the base
     guard passes, the gate attributes the receipt. Red control: with `fetch_commit_metadata` still checking
     local `development`, the same invocation exits 4 `not reachable from local development`; fixed → passes.
     Also record that the same command without `--base` on a Forge-shaped (`development`) scratch repo
     behaves as before.
   - Resolution checks (same clone, recorded): `--base main` with no `origin/HEAD` resolves `main`; no
     `origin/HEAD`, no `--base`, `gh` without a default branch → exit 3 `base-unresolved` with no doc, ledger or
     git changes (refusal telemetry only, as for every refusal); a clone with both `main` and `development`,
     `gh` reporting `main` and no `origin/HEAD` resolves `main`, never `development`.
   - Recovery recipe: run the edited SKILL.md recipe once on the main-only fixture; the receipt names `main`
     and `resume --base main` reconciles.
   - Smoke (GH-1088): main path — `run --dry-run` from this Forge clone resolves `development` and prints the
     same preview as `origin/development`'s express on the same input; adjacent — `resume --dry-run` in the
     main-only fixture resolves `main`.
   - Final gate per `utils/ci-route.sh` on the changed paths (code → full route), once, on the final commit.

## Non-goals

No change to wave_reconcile's PR/catch-up/hosted modes; no vendored-host enablement (`validate.sh`, docs suite,
`githooks/install.sh` under `.xyz/`); no new suite or gate; no change to bounds, refusals, receipts, ship or
reconcile ordering.

## Risks

- A clone with a stale `origin/HEAD` (set at clone time) could resolve an outdated branch. Mitigation: explicit
  `--base` wins; the refusal and dry-run name the resolved branch so the operator sees it before landing.
- Missing a literal leaves a split-brain run (bounds on `main`, push to `development`). Mitigation: after the
  edit, `grep -n development utils/py/express.py` shows only the module default and the task-branch refusal;
  the main-only non-preview run inspects real remote refs, closeout branch, receipt and reconcile, with a red
  control that hardcodes one wrong destination.

## Acceptance

- Main-only fixture with `origin/HEAD`: a full non-preview `run` advances remote `main` (no `development`
  created), leaves the fixture clean on `main`, commits a receipt naming `main`, and reconciles with
  `--base main --gate`; `resume` on the same fixture completes against `main`.
- Same fixture, no `origin/HEAD`, `--base main`: same resolution.
- Both `main` and `development` present, no `origin/HEAD`, GitHub default `main`: resolves `main`.
- No `origin/HEAD`, no `--base`, no GitHub default: exit 3 `base-unresolved`; no doc, ledger or git writes;
  refusal telemetry as for every refusal.
- XYZ Forge clone: dry-run output and receipt wording unchanged; `test/gh267-express-skill.sh` (with the two
  truthful edits) and the wave-reconcile suites pass.
- `wave_reconcile.py --commit <sha> --base main` accepts a commit reachable from local `main` and reports base
  `main`; without `--base` behaviour is unchanged.

## Per-issue map

| Issue | Requirement | Clone / branch | State |
|---|---|---|---|
| [#1144](https://github.com/HiQS-Labs/XYZ-forge/issues/1144) | Changes 1–7 | `XYZ-forge-gh1144-express-default-branch-2026-10-18` / `feat/…` | Implementing |

## Rating rationale (2026-10-18)

`rated 40/30/50/55`. Severity 30: express is unusable in every non-`development` repo; the workaround is a
manual landing, so no data or work is lost. Priority 40: one observed blocked use (XYZ-layout-engine, 2026-10-18);
operator asked for it now. Appeal 50: neutral default. Effort 55: one file's literals plus a narrow reconcile
argument, on well-covered code with existing suites. Recurrence: one incident in the last 14 days; none in
the preceding 14; trend unknown.

## Evidence

| Check | Result |
|---|---|
| Plan QA | Codex, 3 rounds, Approved (`relay-system/2026-10-18/gh1144-plan-qa.md`). R1: B1 refusal-telemetry wording (modified: kept consistent with every refusal), B2 gh267 `:753` literal, S3 non-preview main-only run, S4 recovery recipe, S5 no ref-existence guess, nit reversibility. R2: production reconciler check added |
