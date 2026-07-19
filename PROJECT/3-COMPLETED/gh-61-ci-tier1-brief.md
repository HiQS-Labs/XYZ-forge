---
ratings_exempt: true
title: Builder brief — GH-61 Tier 1 CI GitHub Actions (single-phase Marathon)
status: Closed (issue #61 closed)
created: 2026-07-02
updated: 2026-07-02
owner: Noel (operator) · Codex (builder) · agy (reviewer)
parent: PROJECT/1-INBOX/GH-61-CI-GITHUB-ACTIONS.md
substrate_repo: xyz-3-agents-swarm (same-repo build; CWD is the repo root)
gh_issue: 61
goal: >
  Single-phase --phase-brief for the headless Marathon builder: add ONE additive Tier-1 GitHub
  Actions workflow (lint + doc-hygiene, always-green, no secrets) plus a dependency-free deterministic
  test that pins the workflow's shape and is wired into validate.sh. Tier 2 (running the full
  validate.sh suite inside CI) is explicitly OUT OF SCOPE — it carries an unresolved runner decision.
---

# Builder brief: GH-61 Tier 1 CI GitHub Actions

## Status

| What was just completed | What's next |
|---|---|
| Brief authored 2026-07-02 as the single-phase `--phase-brief` for GH-61 Tier 1; ALLOW_PATHS + gate pinned. | Fed to the headless Codex builder (agy reviewer) when the marathon fires. |

You are a headless builder in the **xyz-3-agents-swarm** repo (CWD = repo root). Build ONE additive
GitHub Actions workflow + a deterministic test that pins its shape. **Additive only.** Do NOT change
any runtime script, and touch ONLY the allowlisted paths.

## What to build

1. **`.github/workflows/ci.yml`** (NEW) — a single Tier-1 job, `runs-on: ubuntu-latest`, no secrets,
   triggered `on: [push, pull_request]` (both `main`). It must run these deterministic, network-free
   checks (each a distinct step, each failing the job loudly on error):
   - **`shellcheck`** on all tracked `*.sh` (install via the distro or the `ludeeus/action-shellcheck`
     is NOT available offline — prefer `sudo apt-get install -y shellcheck` then run it, or use the
     runner's preinstalled `shellcheck`). Start permissive: `shellcheck -S error` (or an explicit
     exclude list) so it lands green, with a comment that the severity can be tightened later.
   - **`bash -n`** syntax check on every tracked `*.sh`.
   - **`node --check`** on each tracked `*.js` (JS sources under `src/` and `bin/`).
   - **JSON validate** `.claude/settings*.json` (via `python3 -m json.tool` or `jq`).
   - **`utils/pdda/pdda.sh run`** in full mode — the deterministic doc/roadmap/path-drift gate.
   Use `git ls-files` to enumerate tracked files (portable, no `find` surprises). Keep each step's
   command copy-pasteable so the same checks can be run locally.

2. **`test/ci-workflow.sh`** (NEW) — a standalone, **dependency-free** test (mirror
   `test/swarm-preflight.sh` style: `pass`/`fail` counters, exit 1 on any fail; stock macOS **bash
   3.2** + BSD tools; do NOT require `shellcheck`, `yq`, or a YAML library to be installed). It asserts:
   - `.github/workflows/ci.yml` exists and is non-empty.
   - It declares `runs-on: ubuntu-latest` and triggers on both `push` and `pull_request`.
   - It references each required check by its literal command marker: `shellcheck`, `bash -n`,
     `node --check`, a JSON-validate of `.claude/settings`, and `utils/pdda/pdda.sh run`.
   - **If** `python3` can `import yaml`, the file parses as valid YAML; otherwise that one sub-check
     self-skips (printed as a skip, never a fail) — so the test is green on a machine without PyYAML.
   - `test/ci-workflow.sh` is itself wired into `validate.sh` (grep `validate.sh` for `ci-workflow`).

3. **`validate.sh`** (EDIT, one line) — register `test/ci-workflow.sh` in the suite exactly the way
   the other `test/*.sh` are wired (match the surrounding pattern; don't restructure the file).

## Objective gate (what the marathon's --pre-advance-cmd runs)
```
bash test/ci-workflow.sh
```
It must pass: workflow present + well-formed, all required check markers present, wired into validate.sh.

## How to verify before you hand off
```
bash test/ci-workflow.sh        # the gate — all assertions pass
grep -n ci-workflow validate.sh # confirm the one-line wiring landed
```

## Hard rules
- **Tier 1 ONLY.** Do NOT add a job that runs `./validate.sh` inside CI (that's Tier 2 — it has an
  unresolved `macos-latest` vs `ubuntu-latest` runner decision reserved for the operator). Do NOT make
  any check a *required* status check.
- **Additive.** The only non-new file you may touch is `validate.sh`, and only to add the one wiring
  line. Do NOT edit any runtime script, `bin/tick`, `src/*.js`, relay code, or `ROADMAP.md`.
- **bash 3.2 + BSD-portable** for `test/ci-workflow.sh` (no bash-4 `${,,}`; use `tr`; POSIX classes).
- **Do not `git commit`** — the harness commits. Do not push. Touch ONLY the three allowlisted paths:
  `.github/workflows/ci.yml`, `test/ci-workflow.sh`, `validate.sh`.
- Keep `test/ci-workflow.sh` resilient (match on content markers, not exact line numbers) so a later
  reformat of the workflow doesn't false-fail it.
