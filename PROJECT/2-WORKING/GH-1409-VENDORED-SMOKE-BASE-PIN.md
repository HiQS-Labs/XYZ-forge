---
title: "ci(vendored-smoke): base-pin ratchet, frozen-twin guard, and vendored smoke suites against self-modification"
status: Active
created: 2026-11-10
updated: 2026-11-10
owner: noel
gh_issue: 1409
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1409
doc_type: feature
complexity: 2
risk: 2
effort: 1
phases: 1
ratings_provisional: false
non_goals:
  - CODEOWNERS or required code-owner review (single-author PRs cannot satisfy it)
  - Branch protection on development (blocked on a reviewed bot-bypass policy; wave-reconcile.yml:41-47)
  - Closing the ci.yml self-edit loophole (accepted by the operator, 2026-11-10)
  - New test suites, registry entries, scripts or gate runners (AGENTS.md "No new tests", GH-831)
  - Pinning on push events, or pinning helpers the suites source (test/lib/*)
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1409#issuecomment-6780390475
  - GH-777 / #1182 (inventory ratchet in vendored-smoke)
  - GH-308 / GH-459 (frozen twin guard in vendored-smoke)
  - GH-1226 (merge-cleanup honours required checks)
fix_probes:
  - bash test/ci-workflow.sh
  - bash test/gh308-frozen-twin-guard.sh
goal: >
  On pull requests, run vendored-smoke's existing judge files from the PR base commit instead of
  the PR's own copies, refuse a grown inventory baseline or newly added SQLite suppression markers,
  and keep a maintainer label as the escape hatch for intended judge changes.
---

# GH-1409 — vendored-smoke: base-pin the judge files

## Status

| What was just completed | What's next |
|---|---|
| Final QA PASS (attested fc48de9a5); full gate rc=1 on harness-environment and pre-existing causes, base-identical (TESTS-RESULTS gate.txt). | Push through the pre-push gate from the disposable clone, open the PR, confirm the hosted vendored-smoke run. |

## Problem (recon, 2026-11-10)

- On a PR, `vendored-smoke` (`.github/workflows/ci.yml`) runs the PR's own copies of its judge
  files. A PR can weaken them in the same change and still report green:
  `utils/pdda/check_inventory_ratchet.py`, `utils/pdda/inventory_ratchet_baseline.json`,
  `test/gh421-auto-wave-reconcile.sh`, `test/gh308-frozen-twin-guard.sh`, and the four vendored
  suites `test/gh396-find-harness-roots.sh`, `test/gh393-deepseek-readiness.sh`,
  `test/gh358-wave-reconcile-vendored-paths.sh`, `test/gh292-worktree-vendored-discovery.sh`.
- Until 2026-11-10 the check gated nothing: `development` has no protection and `main` had no
  required checks, so `merge_cleanup.py:542-564` saw "no required checks reported" and merged.
  The operator authorized making it required. `main` now requires
  `vendored smoke gate (blocking on development + main)` (app 15368, `strict=false`).
  `development` stays unprotected: `wave-reconcile.yml:41-47` fails closed on a protected branch
  until a reviewed bot-bypass policy exists.
- No incident of judge weakening is on record (issue search, 2026-11-10). This is latent risk.

## Requirements

- **R1** On `pull_request`, resolve the trusted base as the merge ref's first parent and log base,
  PR head and merge SHAs. Fail closed when HEAD is not a merge commit.
- **R2** Refuse a PR whose `inventory_ratchet_baseline.json` grows relative to base: a script added
  to `scripts`, a file added to the `sqlite_bypasses` file set, more distinct `sqlite_bypasses`
  entries (the cardinality the ratchet actually compares, `check_inventory_ratchet.py:116,155-159`),
  or a larger declared `sqlite_bypasses_count`. A shrink or exact match passes. That keeps
  `--update-baseline` shrinks legitimate. (Plan QA round 1: the declared count alone missed an extra
  location in an existing bypass file.)
- **R3** Refuse a PR that adds a `SQLITE-BYPASS-OK:` or `SQLITE-GATEWAY-OK:` line in a `.py`/`.sh`
  file outside `test/`. Counting markers is not enough, because a removed marker could hide an added one.
- **R4** Run all seven judge scripts from the base commit. Keep the PR's baseline JSON, which R2 has
  already checked.
- **R5** A `judge-change` label on the PR, read live at run time so a re-run sees it, skips R2–R4
  with a visible warning. It is a speed bump for intended judge edits, not a security control.

## Design (extends the existing vendored-smoke job; no new file)

One new step, `Pin judge files to PR base (GH-1409)`, placed directly after `Prepare git environment`.
It runs only when `github.event_name == 'pull_request'`.

1. `git rev-parse --verify HEAD^2` must succeed, then `BASE_SHA=$(git rev-parse HEAD^1)`, appended
   to `$GITHUB_ENV`, with the three SHAs echoed.
2. A live `gh pr view "$PR_NUMBER" --json labels` lookup (`GH_TOKEN: github.token`; the repo is
   public, so `contents: read` suffices). If `judge-change` is present, warn and exit 0.
3. An inline `python3 -` compares `git show "$BASE_SHA:utils/pdda/inventory_ratchet_baseline.json"`
   with the working copy (R2).
4. `git diff -U0 "$BASE_SHA" HEAD -- '*.py' '*.sh' ':!test/**'`, grepped for added marker lines (R3).
5. `git checkout "$BASE_SHA" -- <the seven judge scripts>`. The checkout fails closed if a path is
   absent at base.
   - Every judge resolves its paths from its own location (`check_inventory_ratchet.py:22-23`,
     `gh308:11-12`, `gh421:4`, `gh396:23`, `gh393:27`, `gh358:18`, `gh292:6`). Restoring each file in
     place therefore keeps it scanning the candidate tree.
   - `xyz-vendor.sh` copies `test/` into `.xyz/test` (`VENDOR_DIRS`, line 432), so the scratch
     repo gets the base copies of the four suites without a second overwrite.

The existing gh308 step drops its step-level `BASE_SHA` env so it uses the exported value. That aligns
its range with the tested merge, including on a re-run where the event's base SHA may be stale. Push events are unchanged and run the merged tree's own judges.

## Risks, residuals, rollback

- **Residual, accepted:** a PR can still edit `ci.yml` itself.
- **Residual, accepted:** anyone with triage rights can apply the label, including the agents'
  account.
- **Residual:** helpers the suites source (`test/lib/*`, `test/_setup.sh`) stay at the PR's version.
- **Accepted friction (R3):** the diff scope is broader than the scanner's `PRUNED_DIRS`, and a moved
  marker line shows as an added one. Both can need the label; neither lets a marker through.
- **Risk:** a PR that legitimately changes behaviour one of the seven suites pins now fails until
  the label is applied. That is the intended friction.
- **Rollback:** revert the single ci.yml commit. The settings change reverts with one
  `gh api -X PUT .../branches/main/protection` without `required_status_checks`.

## Verification (no new tests; GH-831)

- Focused: `bash test/ci-workflow.sh`, `bash test/gh308-frozen-twin-guard.sh`.
- Manual controls, recorded under `TESTS-RESULTS/2026-11-10+GH-1409/` with `provenance.jsonl`.
  Each runs in a disposable full clone: the step's `run:` block is extracted from ci.yml and run
  against a constructed `--no-ff` merge of a throwaway PR commit onto base.
  - **Red 1:** a dummy script added to the baseline → R2 exits non-zero.
  - **Red 1b:** an extra distinct location in an existing bypass file, declared count unchanged →
    R2 exits non-zero.
  - **Red 2:** one existing marker moved to a new `sqlite3.connect(` line → R3 exits non-zero.
  - **Red 3:** `test/gh396-find-harness-roots.sh` replaced with `exit 0` while `find-harness-roots`
    is broken → after the pin, the vendored gh396 run exits non-zero.
  - **Green:** a script under `utils/` deleted, plus `--update-baseline` → R2, the pinned ratchet and
    the vendored suites all exit 0.
  - **Adjacent:** the same Red 1 with a stubbed label lookup returning `judge-change` → warning, exit 0.
    This proves only the branch; live label permissions are shown by the hosted run.
- Hosted: this PR's own `vendored-smoke` run is green, and its log shows the three SHAs.
- Final gate: one `ci-local.sh` run in a disposable full clone (ci-route: tier 3, kernel/gate surface).

## Implementation order

1. Add the step to ci.yml and drop the gh308 step's env. Verify with the focused suites.
2. Run the six manual controls; write the receipts.
3. Create the `judge-change` label (repo write, reversible) and note it in the PR.
4. Run the final gate once, then final relay QA, then the PR.

## Rating (2026-11-10)

`rated 25/30/50/70`, set by the operator. There is no incident on record and the trend is unknown
(last 28 days of issues searched). This is a latent eval-integrity risk. Appeal is neutral. The
change is a single inline workflow step, so it is cheap.
