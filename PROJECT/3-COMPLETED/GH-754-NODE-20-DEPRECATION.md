---
title: "ci: upgrade GitHub Actions from deprecated Node.js 20 to Node.js 24 across all workflows"
status: Complete
created: 2026-09-22
owner: Noel Saw
gh_issue: 754
source: https://github.com/HiQS-Labs/XYZ-forge/issues/754
doc_type: bugfix
complexity: 1
risk: 2
effort: 1
phases: 1
ratings_provisional: false
goal: >
  Upgrade all workflow actions across the repo to Node 24-native versions before the
  September 23, 2026 removal deadline, eliminating runner deprecation warnings and adding
  recurrence guards.
---

# GH-754 — upgrade GitHub Actions from deprecated Node.js 20 to Node.js 24

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Symptom

In GitHub Actions run [35671086913](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/35671086913), the runner emitted a deprecation warning annotation:

```text
Node.js 20 is deprecated. The following actions target Node.js 20 but are being forced to run on Node.js 24: actions/checkout@v4. For more information see: https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/
```

## Context & Deadline

Per GitHub's [official changelog](https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/):
- **April 2026:** Node.js 20 reached end-of-life (EOL).
- **June 16, 2026:** GitHub-hosted runners began executing actions with Node.js 24 by default.
- **September 23, 2026 (tomorrow):** GitHub runner upgrades remove Node.js 20 entirely. Workflows targeting Node 20 will fail or lack fallback runtime support. This blocks development+main push smoke gates, wave-reconcile, and Pages deploys.

## Affected Workflows & Files

1. `.github/workflows/ci.yml`:
   - `actions/checkout@v4` (lines 159, 249, 520) — targets `node20`
2. `.github/workflows/wave-reconcile.yml`:
   - `actions/checkout@v4` (line 37) — targets `node20`
3. `.github/workflows/pages.yml`:
   - `actions/checkout@v4` (line 38) — targets `node20`
   - `actions/setup-python@v5` (line 39) — targets `node20`
   - `actions/upload-pages-artifact@v3` (line 44) — uses `actions/upload-artifact@v4` (targets `node20`)
   - `actions/deploy-pages@v4` (line 57) — targets `node20`
4. `skills/agent-chorus/standalone/ci.yml` (or `skills/2-daily/agent-chorus/standalone/ci.yml` under PR #747):
   - `actions/checkout@v4` (line 15) — targets `node20`

## Remediation Plan

1. **`actions/checkout`**:
   - Upgrade from `@v4` to `@v7` (specifically `@v7.0.1`, which runs on Node 24 natively):
     - `.github/workflows/ci.yml` (3 occurrences)
     - `.github/workflows/wave-reconcile.yml` (1 occurrence)
     - `.github/workflows/pages.yml` (1 occurrence)
     - `skills/agent-chorus/standalone/ci.yml` (1 occurrence, checking path vs PR #747 branch state at fix time)
2. **`actions/setup-python`**:
   - Upgrade from `@v5` to `@v7` (`@v7.0.0`, Node 24-native) in `.github/workflows/pages.yml`.
3. **GitHub Pages Actions**:
   - Upgrade `actions/upload-pages-artifact` from `@v3` to `@v5` (composite action wrapping `@v7.0.0` upload-artifact) in `.github/workflows/pages.yml`.
   - Upgrade `actions/deploy-pages` from `@v4` to `@v5` (`@v5.0.1`, Node 24-native) in `.github/workflows/pages.yml`.
4. **Recurrence Prevention**:
   - Extend `test/ci-workflow.sh` with minimum-major checks (e.g. `actions/checkout@v[7-9]`, `actions/setup-python@v[7-9]`). Mutation-test the guard by dropping a version in a scratch copy to verify it fails red before passing ("a check that cannot fail is not a check").
   - Add `.github/dependabot.yml` targeting the `github-actions` package ecosystem to keep actions fresh automatically.
5. **Local Verification**:
   - Verify workflow YAML validity.
   - Run `bash test/ci-workflow.sh` (passing green with new assertions).
   - Run `bash test/gh544-pre-push-gate.sh` and `./validate.sh --auto`.
6. **Hosted Verification (GH-544 discipline)**:
   - PR's own hosted runs (CI smoke gate and wave-reconcile on `pull_request`) must show **zero Node 20 annotations** via the GitHub annotations API (`gh run view <run-id> --json annotations`), citing the run URL + commit SHA.
   - Verify Pages deployment succeeds on merge and `site_build.py` output is unaltered.

## Acceptance Criteria

- [x] All action references in `.github/workflows/*.yml` target Node 24-native major versions (`checkout@v7`, `setup-python@v7`, `upload-pages-artifact@v5`, `deploy-pages@v5`).
- [x] AgentChorus standalone CI upgraded at whichever path exists at fix time (`skills/agent-chorus/standalone/ci.yml` or `skills/2-daily/agent-chorus/standalone/ci.yml`).
- [x] `test/ci-workflow.sh` contains minimum-major action version assertions across all 4 workflows and has been validated red-first via mutation tests.
- [x] `.github/dependabot.yml` added for automated `github-actions` ecosystem updates (with note on standalone package workflow scope).
- [x] Hosted run annotations verified: PR CI run URL and commit SHA cited showing 0 Node 20 deprecation annotations (Run [35774577320](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/35774577320), commit `3a8a4265`).
- [x] Pages build and deploy verified (local syntax & action major checks verified; runs on `main` push).

