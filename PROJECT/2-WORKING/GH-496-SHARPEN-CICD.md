---
title: "GH-496: ci: sharpen CI/CD per Ponytail & Guiding Principles — fix unreachable PR twin guard (#459) and widen Tier-2 routing"
status: In progress
created: 2026-09-07
updated: 2026-09-07
owner: Antigravity
goal: sharpen CI/CD by extending existing patterns (fix CI PR twin guard, widen Tier-2 routing, clarify offline levers) with zero new subsystems
gh_issue: 496
source: https://github.com/HiQS-Labs/XYZ-forge/issues/496
branch: feat/gh496-sharpen-cicd
doc_type: enhancement
effort: 4
complexity: 2
risk: 1
---

# GH-496 — Sharpen CI/CD per Ponytail & Guiding Principles

## Status

| What was just completed | What's next |
|---|---|
| Implemented Phases 1–3: moved twin guard to `vendored-smoke` (closes #459), widened Tier-2 routing for releases & PDDA, clarified offline bypass in pre-push; verified all suites (ci-workflow: 45 pass, ci-route: 63 pass, gh544-pre-push: 103 pass, gh35: 71 pass, pdda: 0 errors) | Commit, push task branch, and open PR against `development` |

## Problem statement

Applying `/ponytail` and `GUIDING-PRINCIPLES.md` (lines 18–22: *"Do not build a new layer, module, or sub-system when an existing piece of code can be extended easily, logically, and safely"*), we rejected speculative machinery (such as custom hermetic runner sandboxes or complex suite-caching systems).

Instead, we take the shortest, most durable path to fastest and safest CI/CD by extending existing patterns with zero new subsystems:

1. **Fix Unreachable PR Guard (#459):**
   - In `.github/workflows/ci.yml`, move the `Frozen Bash twin guard (GH-308)` step into the existing `vendored-smoke` job (which already runs on `pull_request` and `development`). Zero new jobs, zero new runner minutes.
2. **Widen Tier-2 Subsystem Routing in `utils/ci-route.sh`:**
   - Extend `subsystem_of()` to map high-frequency utilities (e.g. `utils/py/releases_app.py`, `utils/pdda/`) to their existing test suites so routine edits stay in Tier 2 (~30s) instead of triggering the 10-minute Tier-3 gate.
3. **Clarify Offline Push Diagnostics in `githooks/pre-push`:**
   - When `git ls-remote` cannot verify remote base freshness (offline / captive portal), update the stderr diagnostic to explicitly remind the operator of the existing canonical levers (`XYZ_SKIP_PREPUSH=1` or `git push --no-verify`) rather than introducing new environment flags.
4. **Preserve GH-564 & Worktree Discipline:**
   - Maintain the established maintainer SOP (fresh-clone-per-task) for full-gate runs without adding complex sandbox wrapper code.

## Plan & Phases

### Phase 1: Fix Unreachable PR Guard in `.github/workflows/ci.yml`
- Move `Frozen Bash twin guard (GH-308)` step out of `canary-ubuntu` and into `vendored-smoke`.
- Configure it to check `--base origin/development --allow-exceptions` on pull requests.
- Update `test/ci-workflow.sh` to lock this requirement.

### Phase 2: Widen Tier-2 Subsystem Routing in `utils/ci-route.sh`
- Map `utils/py/releases_app.py` and related CLI code to `test/gh32-releases-app.sh`.
- Map `utils/pdda/*` to `test/pdda-repo-contract.sh`.
- Add test coverage in `test/ci-route.sh` proving these paths classify as `tier=2` and route `fast`.

### Phase 3: Clarify Offline Lever in `githooks/pre-push`
- Update the `_base_note` in `githooks/pre-push` when `git ls-remote` fails/times out to explicitly recommend:
  `To bypass while offline: XYZ_SKIP_PREPUSH=1 git push`
- Verify with `test/gh544-pre-push-gate.sh`.

## Acceptance criteria (debug-mantra plan pivot)

- [x] `.github/workflows/ci.yml` runs the frozen-twin guard on pull requests within `vendored-smoke` (closing #459).
- [x] `utils/ci-route.sh` routes mapped utility edits to Tier-2 dedicated tests, verified with contract tests in `test/ci-route.sh`.
- [x] `githooks/pre-push` stderr message clearly documents `XYZ_SKIP_PREPUSH=1` upon offline probe failure.
- [x] Zero new subsystems, daemons, or workflow files added.
