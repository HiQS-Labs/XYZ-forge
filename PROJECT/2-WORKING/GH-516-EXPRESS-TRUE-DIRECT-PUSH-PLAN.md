---
title: "GH-516: /express v2 — true direct-push mode, commit-driven reconciliation, recovery subcommand, and central telemetry"
status: Active (2-WORKING — execution started 2026-09-08)
updated: 2026-09-08
created: 2026-09-08
owner: noelsaw1
gh_issue: 516
source: https://github.com/HiQS-Labs/XYZ-forge/issues/516
doc_type: feature
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: false
rating_pri: 75
rating_sev: 40
rating_appeal: 70
rating_effort: 70
rating_ovr: 255
non_goals:
  - Bypassing the pre-push gate or lowering regression suite requirements.
  - Allowing Costly or one-way-door changes on express (the frozen twin, kernel surfaces, and size bounds remain strict).
  - Merging multi-repo coordination into express.
related:
  - GH-267 (original /express fast lane implementation)
  - GH-270 / GH-278 (express post-merge reviews)
  - GH-202 / GH-205 (wave_reconcile contract)
  - GH-430 (provenance receipts)
goal: >
  Upgrade the /express hotfix fast lane from interim Ghost-PR mode to True Direct-Push Mode,
  teaching wave_reconcile.py to reconcile directly from a commit SHA, enabling cumulative diff
  evaluation on pre-committed branches, adding an explicit recovery/resume subcommand, supporting
  --dry-run, and mirroring telemetry centrally.
---

# GH-516: /express v2 — True Direct-Push Fast Lane & Commit Reconciler

## Status

| What was just completed | What's next |
|---|---|
| **Intake, rating, and relay plan QA completed** — rated 75/40/70/70 [calc 255/400]; Relay Plan QA approved by Agy (`relay-system/2026-09-08/gh516-express-plan-qa-agy.md`); promoted to 2-WORKING in fresh task clone `feat/gh516-express-v2`. | Implement cumulative diff + branch flexibility (<= 2 commits), `--allow-multi-subsystem`, `--dry-run`, `express resume`, and central telemetry in `utils/py/express.py`; update `skills/express/SKILL.md` and `test/gh267-express-skill.sh`. |


## 1. Problem & Operational Background

The `/express` fast lane ([GH-267](https://github.com/HiQS-Labs/XYZ-forge/issues/267), `skills/express/SKILL.md`, `utils/py/express.py`) was introduced to mechanize SOP §4's express-to-development carve-out: landing critical, risk-bounded hotfixes without a human PR review loop.

The v1 implementation relied on an interim "Ghost PR" landing shape:
1. The driver pushed a task branch.
2. The driver opened a PR via GitHub CLI (`gh pr create`).
3. The driver immediately merged the PR (`gh pr merge --merge`).
4. The driver switched local checkout to `development` and pulled.
5. The driver ran `manifest ship`, committed, and pushed.
6. The driver ran `wave_reconcile.py --pr <M>`, committed, and pushed again.

While this automated the paperwork, live usage revealed 5 core friction points:
1. **Push Thrashing & Latency**: A single hotfix requires 4 remote pushes and 2 GitHub API calls, taking ~25–30s and causing CI trigger churn.
2. **The "HEAD == origin/development" Trap**: `express check` strictly requires uncommitted working-tree diffs. If an agent/operator creates 1–2 exploratory commits on the task branch before expressing, it triggers a hard `task-clone` refusal, forcing manual soft-resets.
3. **No Recovery on Post-Merge Faults**: If `wave_reconcile` or remote push fails after the ghost PR merges, the driver dies on `development` with an orphaned intermediate state and no resume mechanism.
4. **Brittle Subsystem Root Checking**: A micro-diff touching `src/` and a 1-line constant in `config/` trips `multi-subsystem` refusal even when the total diff is < 10 lines.
5. **Disposable Clone Telemetry Loss**: `.tick/events/` receipts are destroyed when disposable task clones are pruned per SOP §4.

---

## 2. Proposed Architecture & Design (Post-QA Revision)

### 2.1 True Direct-Push Mode & Landing Sequence (Phase 2 Delivery)
Landing straight onto `origin/development` with clear two-transaction persistence and GH-202 compliance:

1. **Pre-flight & Qualification (`express check`)**:
   - Computes cumulative diff across pre-committed branch (`origin/development..HEAD`) and working tree.
   - Enforces bounds (<= 4 files, <= 150 insertions, single-subsystem unless `--allow-multi-subsystem`).
   - Verifies canonical pre-push gate stub (`githooks/install.sh --check`).
   - Verifies registered regression suite in `validate.sh`.
2. **Focused Suite & Anti-TOCTOU Requalification**:
   - Runs `test/ghN-*.sh` green.
   - Fingerprints before/after tree to verify zero unexpected mutation.
3. **Paperwork Generation (`express docs` & `express ledger`)**:
   - Scaffolds born-complete capture doc (`PROJECT/2-WORKING/GH-N-*.md`).
   - Appends entry under `CHANGELOG.md` `[Unreleased]`.
   - Executes `roadmap add` (if absent) + `manifest dial-in` + `manifest ship --gid <rel> --evidence "<sha>; <suite> green"`.
4. **Transaction 1: Commit & Push Hotfix**:
   - Stages fix + test suite + born-complete doc + changelog + releases.db/manifest outputs.
   - Commits: `fix(GH-N): <title> [express]

Closes #N`.
   - Pushes to `origin/development` (invoking `githooks/pre-push` full regression gate).
5. **Issue Closure (GH-202 Compliance)**:
   - Explicitly calls `gh issue close N --comment "Express hotfix landed in <sha> (suite green)"`.
   - Ensures issue is positively `CLOSED` before reconciler runs so GH-202 promotion succeeds.
6. **Reconciliation & Transaction 2: Commit & Push Reconciled State**:
   - Runs `wave_reconcile.py --commit <sha>` (or `--offline` manifest fallback).
   - Promotes capture doc `PROJECT/2-WORKING/` -> `PROJECT/3-COMPLETED/`, updates roadmap item status marker to `shipped`, and refreshes dashboards.
   - Stages reconciliation outputs, commits `chore(pdda): express reconcile GH-N (commit <sha[:7]>)`, and pushes to `origin/development`.
7. **Receipts & Central Telemetry**:
   - Records `express-fired` event to local `.tick/events/` and mirrors to `~/.config/xyz/events/`.

### 2.2 Commit-Driven Reconciliation in `wave_reconcile.py`
Add `--commit <sha>` support to `utils/py/wave_reconcile.py`:
- `fetch_commit_metadata(repo_root, sha, offline_manifest=None, dry_run=False)`:
  - Extracts subject, body, author, and timestamp via `git log -1 --format="%s%n%b" <sha>`.
  - Sets `"number": None`, `"sha": sha`, `"title": subject`, `"body": body`, `"mergedAt": timestamp`.
- **Badge & Link Formatting**:
  - In `update_roadmap_entry`, if `pr_num` is `None` (commit-driven), format the link badge as `(commit <sha[:7]>)` instead of `(PR #None)`.
- Reconciles doc promotion, roadmap updates, and dashboard generation identically to PR-driven flow.

### 2.3 Cumulative Diff & Pre-Committed Branch Handling
In `utils/py/express.py`:
- `change_paths(root)` is updated to return `set(git diff --name-only origin/development..HEAD) | set(status_porcelain_paths)`.
- If `git rev-list --count origin/development..HEAD` is <= 2: permits pre-committed work, evaluating the net change against `max_files` and `max_insertions`.
- If count > 2: refuses (`too-many-commits`) and routes to normal marathon/PR workflow.

### 2.4 Recovery Subcommand (`express resume`)
Add `express.py resume --issue <N> [--sha <SHA>] [--pr <PR>]`:
- Idempotently recovers interrupted reconciliations.
- If `--sha` is omitted, resolves the latest commit mentioning `GH-N` or `Closes #N` on `origin/development`.
- Ensures issue `#N` is closed.
- Runs `wave_reconcile.py --commit <SHA>`.
- Commits and pushes any uncommitted reconciliation artifacts.

### 2.5 Micro-Diff Subsystem Tolerance & `--dry-run`
- Add `--allow-multi-subsystem` flag.
- Auto-permit multi-root diffs if total insertions <= 30 lines across <= 2 files.
- Add `--dry-run` across `check`, `docs`, `ledger`, `land`, and `run` to preview operations without modifying disk or git state.

### 2.6 Persistent Central Telemetry
- In `write_tick()`: mirror `.jsonl` receipts to `~/.config/xyz/events/` safely inside a `try...except OSError:` block so telemetry never blocks execution.

---

## 3. Detailed File Changes

### 1. `utils/py/wave_reconcile.py`
- Add `--commit` CLI argument.
- Implement `fetch_commit_metadata(repo_root, sha)`.
- Update `update_roadmap_entry` to format `(commit <sha[:7]>)` when `pr_num` is absent.
- Support `--commit` in main dispatch alongside `--pr` and `--marathon-doc`.

### 2. `utils/py/express.py`
- Update `change_paths` to include `origin/development..HEAD` commits.
- Refactor `cmd_check` to support branches ahead by <= 2 commits.
- Refactor `cmd_land` to implement True Direct-Push landing sequence (Tx1 fix push -> close issue -> reconcile -> Tx2 reconcile push).
- Implement `cmd_resume` for `express.py resume`.
- Add `--allow-multi-subsystem` and `--dry-run`.
- Add central telemetry mirroring in `write_tick`.

### 3. `skills/express/SKILL.md`
- Document True Direct-Push sequence, flags, and `resume` command.

### 4. `test/gh267-express-skill.sh`
- Add test cases for:
  - `wave_reconcile.py --commit <sha>` and `(commit <sha[:7]>)` roadmap badge formatting.
  - Expressing task branch with 1–2 pre-existing commits.
  - Multi-root diff auto-allow and `--allow-multi-subsystem`.
  - `--dry-run` output verification.
  - `express resume` recovery from interrupted state.

---

## 4. Verification & Acceptance Plan

1. **Automated Suite**: Run `test/gh267-express-skill.sh` (all assertions green).
2. **Full Repository Gate**: Run `validate.sh` and `githooks/install.sh --check`.
3. **Simulation**: Execute `express.py run --dry-run` and wet runs in sandbox clones.
