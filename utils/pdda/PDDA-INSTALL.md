# PDDA Install / Extraction Manifest

This file is the portable install manifest for PDDA.

Use it when an LLM agent needs to extract the PDDA files from this repo and install them into a
different repo without guessing which files are canonical.

## Fastest path: `install.sh`

For a normal install, the repo-root `install.sh` automates this entire manifest — copy the runtime,
create the lifecycle tree, synthesize the blank seed files, `chmod`, and run a verification pass:

```bash
./install.sh /path/to/target-repo          # observe mode, idempotent
./install.sh --with-startup-docs --mode light /path/to/target-repo
```

The rest of this document is the canonical spec `install.sh` implements — read on when you need to
install by hand, adapt to a non-standard layout, or keep the script honest. Keep the two in lockstep:
a change to the install surface updates both.

## Upgrading an existing install

Re-run `install.sh` (no flags) against the target — `copy_runtime` overwrites the runtime + contract
unconditionally, while seed/state files (`ROADMAP.md`, `CHANGELOG.md`, `.pdda-mode`, `PROJECT/**`,
the activity log) are create-only and stay untouched. Do **not** pass `--force` (it overwrites seeds)
or `--with-startup-docs` (it overwrites any repo-adapted `ROUTER.md`/`AGENTS.md`).

### Migrating a repo that predates the `utils/pdda/` layout

Older installs put the runtime **flat** under `utils/` (`utils/pdda.sh`, `utils/pdda-lib.sh`,
`utils/pdda-doc-ready.sh`, sometimes `utils/pdda-catchup.sh`, plus `utils/PDDA-INSTALL.md` and a
legacy `utils/pdda-phase-out/`). The runtime is relocatable (it sources via `HERE="$(dirname "$0")"`),
so both layouts *run* — but a plain re-install **adds** the new `utils/pdda/` subfolder beside the old
flat files, leaving **two copies** and an ambiguous source of truth.

`install.sh` detects the flat layout and **migrates it automatically** (one canonical `utils/pdda/`):
it removes the now-duplicate PDDA-owned flat files (`utils/pdda.sh`, `utils/pdda-lib.sh`,
`utils/pdda-doc-ready.sh`, `utils/pdda-catchup.sh`, `utils/PDDA-INSTALL.md`, the legacy
`utils/pdda-phase-out/`), repoints old-path references (`utils/pdda.sh` → `utils/pdda/pdda.sh`, etc.)
in tracked docs, and prints a summary of what moved. The target repo's own non-PDDA `utils/` files are
never touched, and historical CHANGELOG paths are left as the dated record they are. Migration runs as
part of the upgrade so the maintainer's whole job is "run the script, review the diff, commit."

## Purpose

PDDA installs two things:

- the canonical document contract in `PROJECT/PDDA.md`
- the runnable shell checks in `utils/pdda-*.sh`

This standalone repo also carries repo-local startup docs (`ROUTER.md`, `AGENTS.md`, `README.md`) and
the `/pdda` re-orient skill (`.claude/skills/pdda/SKILL.md`) so the installer source stays
self-consistent, but those files are not part of the target-repo install surface unless the target
explicitly wants them. `install.sh --with-startup-docs` ships `ROUTER.md`, `AGENTS.md`, and the
`/pdda` skill together as the agent read-order scaffold.

Do not install deprecated PDDA companion docs from `PROJECT/4-MISC/`.

## Prerequisites

- `bash`
- `node`
- standard POSIX tools used by the scripts: `awk`, `grep`, `sed`, `find`, `wc`, `mv`, `date`

## Canonical install set

Extract these files verbatim from this repo into the target repo at the same relative paths:

```text
PROJECT/PDDA.md
utils/pdda/pdda-lib.sh
utils/pdda/pdda.sh
utils/pdda/pdda-doc-ready.sh
utils/pdda/pdda-catchup.sh
utils/pdda/pdda-gh-refresh.sh
utils/pdda/pdda-edit-doc-hook.sh
utils/pdda/pdda-stop-doc-health.sh
```

The shipped runtime lives in its own `utils/pdda/` subfolder so it never mixes with a target repo's
existing `utils/` files. `utils/pdda/pdda.sh` is the unified entry point — it carries every
deterministic check plus the aggregate `run` as subcommands (`pdda.sh run`, `pdda.sh frontmatter`,
`pdda.sh roadmap`, ...). `utils/pdda/pdda-lib.sh` holds the shared helpers it sources;
`utils/pdda/pdda-doc-ready.sh` is the opt-in LLM readiness layer and `utils/pdda/pdda-catchup.sh` is
the opt-in ROUTER.md triage layer. `utils/pdda/pdda-gh-refresh.sh` (`pdda.sh gh-refresh`) refreshes the
cached GitHub issue-state file that `pdda.sh issue-doc-sync` reads when `gh` is offline.
`utils/pdda/pdda-edit-doc-hook.sh` (tier 1, a `PostToolUse` single-file lint) and
`utils/pdda/pdda-stop-doc-health.sh` (tier 2, a `Stop` consolidated full-scan) are the optional
doc-health hooks — installs receive the scripts but **opt in by wiring them in their own
`.claude/settings.json`** (see PROJECT/PDDA.md → "Doc-health hooks"); nothing is written into the
target's hook config automatically.

## Files to create in the target repo

Create these paths if they do not already exist:

```text
PROJECT/
PROJECT/1-INBOX/
PROJECT/2-WORKING/
PROJECT/3-COMPLETED/
PROJECT/4-MISC/
utils/pdda/
ROADMAP.md
CHANGELOG.md
PROJECT/PDDA-ACTIVITY.jsonl
```

If the target repo already has its own `PROJECT/**` tree, reuse it rather than replacing it.

## Do not copy

These are not part of the live install surface:

```text
PROJECT/4-MISC/PDDA-AGENT.md
PROJECT/4-MISC/AGENTS-DOCS.md
```

Also do not copy this repo's existing `PROJECT/PDDA-ACTIVITY.jsonl` contents into another repo.
Create a fresh empty file instead.

## Install sequence

1. Create the target directories listed above. -> expect `PROJECT/` and `utils/` to exist.
2. Copy the canonical install-set files verbatim to the same relative paths in the target repo. -> expect `PROJECT/PDDA.md` and all shipped `utils/pdda-*.sh` files to exist.
3. Create baseline `ROADMAP.md` and `CHANGELOG.md` files if the target repo does not already have them. -> expect the roadmap contract to have a file to guard and the changelog check to warn less.
4. Create an empty `PROJECT/PDDA-ACTIVITY.jsonl` if it does not exist. -> expect a zero- or low-byte log file, not this repo's historical log.
4a. Add `PROJECT/PDDA-ACTIVITY.jsonl` to the target's `.gitignore` (and `git rm --cached` it if already tracked). -> expect the churning runtime log to stop dirtying `git status` on every run.
4b. Record the install in the per-user, machine-local registry `${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv` (one tab-delimited row per target: `target · last_install_utc · mode · source_commit · startup_docs`; latest install wins). -> expect a future sync layer to read this to find copies that are behind. Machine-local, never committed; `--no-register` or `PDDA_REGISTRY` adjust it.
5. Make the shell scripts executable. -> expect `chmod +x utils/pdda/pdda.sh utils/pdda/pdda-doc-ready.sh utils/pdda/pdda-lib.sh utils/pdda/pdda-catchup.sh utils/pdda/pdda-gh-refresh.sh utils/pdda/pdda-edit-doc-hook.sh utils/pdda/pdda-stop-doc-health.sh` to succeed.
6. Optionally create a repo-root `.pdda-mode` file with `observe` for first install. -> expect a non-destructive first run.
7. If the target repo uses a different doc layout, set environment overrides instead of editing the scripts first. -> expect the checks to honor the env vars below.
8. Run `utils/pdda/pdda.sh run` in the target repo. -> expect report-only behavior in `observe` mode and an append to `PROJECT/PDDA-ACTIVITY.jsonl`.

## Environment overrides

PDDA is portable because the scripts can be redirected by env vars.

Use these when the target repo does not exactly match this repo's layout:

```text
PDDA_MODE
PDDA_WORKING_DIR
PDDA_COMPLETED_DIR
PDDA_MISC_DIR
PDDA_ACTIVITY_LOG
PDDA_GH_STATE_CACHE
PDDA_ROADMAP
PDDA_STALE_DAYS
PDDA_ISSUE_SYNC_SOURCE
PDDA_DRY_RUN
PDDA_FORMAT
PDDA_ACTIVITY_MAX_LINES
PDDA_ROADMAP_MAX_LINES
PDDA_ROADMAP_MAX_HEADINGS
PDDA_LLM_BIN
PDDA_LLM_ARGS
PDDA_LLM_MODEL
```

`issue-doc-sync` adds three of these: `PDDA_COMPLETED_DIR` (the `3-COMPLETED` move target named in the
flag), `PDDA_GH_STATE_CACHE` (the cached GitHub issue-state file used when `gh` is offline; written by
`pdda-gh-refresh.sh`), and `PDDA_ISSUE_SYNC_SOURCE` = `auto` (default: live `gh`, else cache) | `gh` |
`cache` (the Stop doc-health hook forces `cache` to stay fast and offline-tolerant).

## Minimal target-repo expectations

PDDA assumes these repo concepts exist, either literally or through overrides:

- an active-doc folder
- an archive/misc folder
- a repo roadmap file
- an end-of-iteration changelog file
- Markdown project docs under source control

The default install expects:

```text
PROJECT/2-WORKING
PROJECT/4-MISC
ROADMAP.md
```

## Extraction instructions for an LLM agent

If you are an install agent extracting PDDA into another repo, follow this exact rule:

1. Copy only the files in `Canonical install set`.
2. Create only the paths in `Files to create in the target repo`.
3. Do not copy anything listed under `Do not copy`.
4. Do not infer extra files from historical companions in `PROJECT/4-MISC/`.
5. Do not copy old activity logs from this repo into the target repo.
6. Prefer `.pdda-mode = observe` on first install unless the user explicitly asks for blocking enforcement.

## Post-install verification

Run these commands in the target repo:

```bash
chmod +x utils/pdda/pdda.sh utils/pdda/pdda-doc-ready.sh utils/pdda/pdda-lib.sh utils/pdda/pdda-catchup.sh
printf 'observe\n' > .pdda-mode
utils/pdda/pdda.sh run
```

Expected result:

- the run prints PDDA summaries
- `observe` mode prevents stale-doc moves
- `PROJECT/PDDA-ACTIVITY.jsonl` receives new entries
- the suite exits `0` even if it reports findings

## Syncing the runtime to other repos (HQ → targets)

Once PDDA lives in several repos, keep them current from one canonical source ("HQ" = this clone) with
`utils/pdda/pdda-sync.sh`. HQ is the only writer; targets opt in via `register`. The synced file set is
the auto-regenerated manifest (`utils/pdda/pdda-sync-manifest.conf`, shared with `install.sh`), so a new
runtime file under `utils/pdda/` propagates with no list edit. Per-repo adapted startup docs
(`ROUTER.md`, `AGENTS.md`) are never touched. Full design + rationale:
[`PROJECT/2-WORKING/PDDA-SYNC-TO-OTHER-REPOS.md`](../../PROJECT/2-WORKING/PDDA-SYNC-TO-OTHER-REPOS.md).

```bash
# Enroll a target (initial install via install.sh, then seeds sync state). Confirms first;
# --yes for unattended onboarding.
utils/pdda/pdda-sync.sh register [--mode observe|light|full] [--with-startup-docs] [--yes] /path/to/repo

# Distribute the current runtime on demand — one target, or all registered if omitted.
utils/pdda/pdda-sync.sh push [/path/to/repo]
utils/pdda/pdda-sync.sh push --dry-run        # preview copies AND deletions, write nothing
utils/pdda/pdda-sync.sh push --no-delete      # copy/update only, skip HQ-side deletions

utils/pdda/pdda-sync.sh list                  # registered targets + mode/source-commit/sync state
utils/pdda/pdda-sync.sh status [/path/to/repo]# read-only: current/behind/diverged/missing/to-delete
utils/pdda/pdda-sync.sh remove /path/to/repo  # de-register, keep the target's files
utils/pdda/pdda-sync.sh prune                 # drop registry entries whose dir is gone

# OPTIONAL hands-off schedule (a launchd job that runs `push` every 30 min over the whole registry):
utils/pdda/pdda-sync.sh install-agent         # opt-in; --no-load writes the plist without loading it
utils/pdda/pdda-sync.sh uninstall-agent
```

**Safety:** `push` only overwrites a file when HQ's copy has genuinely advanced (content hash, not
mtime), so deliberate local edits between releases are preserved; any overwrite of a *diverged* target
and any HQ-side deletion is backed up first under `temp/pdda-sync-backups/` (kept to the last
`PDDA_SYNC_BACKUPS`, default 5). A dirty HQ is refused (`--allow-dirty` to override). HQ-side deletions
mirror to targets, but a **manifest-poisoning guard** aborts the delete phase before touching any target
if a declared source root resolves to zero files, the manifest is empty, or it shrank past
`PDDA_SYNC_MAX_SHRINK`% (default 25) — override only with `--force-delete`.

State lives under HQ's gitignored `temp/` (state stamps, manifest snapshots, backups, log, lock); the
target **registry** is machine-local at `${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv` (written by
`install.sh`, the single registry writer), never committed.

## Notes for adaptation

- `PROJECT/PDDA.md` is the canonical policy doc; if the target repo needs wording changes, edit that file there after install.
- `pdda-doc-ready.sh` is opt-in for model use; if no model CLI is configured, it self-skips and the deterministic suite still works.
- `pdda-lib.sh` uses `node` for JSON escaping/parsing helpers, so Node is required even though the checks are shell scripts.
