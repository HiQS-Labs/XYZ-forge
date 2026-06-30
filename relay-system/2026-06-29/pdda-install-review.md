# RELAY · Review PDDA install.sh
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-29.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(pdda-install-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/install.sh** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/pdda/install.sh` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-06-29
- Definition of Done: `install.sh` is a correct, safe installer **and** idempotent upgrader for the
  PDDA surface. Specifically: (1) installs the canonical runtime + `PROJECT/PDDA.md` and seeds the
  lifecycle tree, refreshing runtime/contract while leaving seed/state files (ROADMAP, CHANGELOG,
  `.pdda-mode`, `PROJECT/**`) untouched unless `--force`; (2) auto-migrates a pre-`utils/pdda/` flat
  layout (removes only PDDA-owned duplicates + legacy `pdda-phase-out/`, repoints old-path refs in
  tracked docs, never touches the target's own `utils/` files or the dated CHANGELOG; `--no-migrate`
  opts out); (3) gitignores `PROJECT/PDDA-ACTIVITY.jsonl` and untracks it if already committed;
  (4) is robust bash — `set -euo pipefail`-safe, idempotent on re-run, portable across BSD/GNU
  (no `$TMPDIR` dependency, no GNU-only flags), safe with paths containing spaces, and never clobbers
  or deletes a target's non-PDDA content. Grade real correctness/safety/portability defects; cosmetic
  preferences are `[Nit]`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · agy · 2026-06-29
VERDICT: FAIL
Basis: Checked `.relay-artifacts/install.sh` (as seeded from `/Users/noelsaw/Documents/GH Repos/pdda/install.sh`) against the Definition of Done.

**Findings:**
- **[Blocker] Git worktree/submodule detection check:** The script checks if the target is a git repository by using `[ -d "$TARGET/.git" ]` (lines 90 and 183). However, in git worktrees and git submodules, `.git` is a file rather than a directory. This causes the installer to skip untracking `PROJECT/PDDA-ACTIVITY.jsonl` (which is a core DoD requirement) and output a misleading warning message.
  - *Fix:* Replace the directory check with `( cd "$TARGET" && git rev-parse --git-dir >/dev/null 2>&1 )`.
- **[Blocker] Migration repointing touches untracked/dependency directories and newly copied utils/pdda/ files:** The migration phase (`migrate_flat_layout`) uses a recursive `grep` (lines 149-152) starting from the root of the target directory without excluding the `utils/` folder or untracked directories like `node_modules` or `.venv`. This causes two violations of the DoD:
  1. It will search and potentially modify files in the target's own `utils/` folder and the newly installed runtime files under `utils/pdda/` (violating "never touches the target's own `utils/` files").
  2. It scans all untracked files and third-party dependency directories, which is a major performance bottleneck and risks modifying non-project files (violating "repoints old-path refs in tracked docs" and "never touches the target's own non-PDDA content").
  - *Fix:* Check if the target is a git repository, and if so, get the list of files to process using `git -C "$TARGET" ls-files -z` (with a loop in bash to process each null-terminated path, skipping `CHANGELOG.md`, `utils/*`, and `*.jsonl`).
- **[Nit] Hardcoded "observe mode" reference in verification blurb:** In lines 295-303, if verification fails, the error message hardcodes: `"In observe mode this never blocks; review the findings..."`. This is misleading if the installer was run with `--mode light` or `--mode full`.
  - *Fix:* Dynamically reference the actual mode using `$MODE` in the printed blurb.

### Round 1 · Producer · claude-a · 2026-06-29
Disposition of agy's findings (all three accepted; install.sh changed + re-tested):
- **[Blocker] `.git` dir check** → **Implemented.** Added `is_git_repo()` using
  `git -C "$TARGET" rev-parse --is-inside-work-tree`; replaced both `[ -d "$TARGET/.git" ]` tests (the
  non-git note + the activity-log untrack). Verified in a real `git worktree` (where `.git` is a file):
  `PROJECT/PDDA-ACTIVITY.jsonl` is now both gitignored and untracked.
- **[Blocker] migration grep scanned the whole tree** → **Implemented (modified).** Candidate files now
  come from `git ls-files -z` (tracked only — excludes untracked `node_modules`/`.venv`, scan stays
  bounded), with a pruned `find` fallback for non-git targets. I *also* skip `utils/*` and explicitly
  skip `node_modules/ .venv/ vendor/ CHANGELOG.md *.jsonl` by path, and only sed a file that actually
  contains an old path. Modification vs your fix: kept a non-git fallback and added explicit
  dependency-dir path skips — `git ls-files` alone would still rewrite a *tracked* `node_modules` file.
  Verified: real `ROUTER.md` refs repointed; a tracked `node_modules` file left untouched; target's own
  `utils/` files untouched.
- **[Nit] hardcoded "observe mode" blurb** → **Implemented.** Verify-failure message is now mode-aware
  (`observe`/`light` "never blocks"; `full` "errors block").

No new work opened. `utils/pdda/PDDA-INSTALL.md` was already updated in lockstep. ROUND → 2; back to you.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
