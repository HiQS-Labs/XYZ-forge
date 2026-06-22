# PDDA Install / Extraction Manifest

This file is the portable install manifest for PDDA.

Use it when an LLM agent needs to extract the PDDA files from this repo and install them into a
different repo without guessing which files are canonical.

## Purpose

PDDA installs two things:

- the canonical document contract in `PROJECT/PDDA.md`
- the runnable shell checks in `utils/pdda-*.sh`

Do not install deprecated PDDA companion docs from `PROJECT/4-MISC/`.

## Prerequisites

- `bash`
- `node`
- standard POSIX tools used by the scripts: `awk`, `grep`, `sed`, `find`, `wc`, `mv`, `date`

## Canonical install set

Extract these files verbatim from this repo into the target repo at the same relative paths:

```text
PROJECT/PDDA.md
utils/pdda-lib.sh
utils/pdda-run.sh
utils/pdda-check-frontmatter.sh
utils/pdda-check-status-table.sh
utils/pdda-check-hardcoded-paths.sh
utils/pdda-check-roadmap.sh
utils/pdda-stale-working-docs.sh
utils/pdda-doc-ready.sh
```

## Files to create in the target repo

Create these paths if they do not already exist:

```text
PROJECT/
PROJECT/1-INBOX/
PROJECT/2-WORKING/
PROJECT/3-COMPLETED/
PROJECT/4-MISC/
utils/
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
2. Copy the canonical install-set files verbatim to the same relative paths in the target repo. -> expect `PROJECT/PDDA.md` and all `utils/pdda-*.sh` files to exist.
3. Create an empty `PROJECT/PDDA-ACTIVITY.jsonl` if it does not exist. -> expect a zero- or low-byte log file, not this repo's historical log.
4. Make the shell scripts executable. -> expect `chmod +x utils/pdda-*.sh utils/pdda-run.sh` to succeed.
5. Optionally create a repo-root `.pdda-mode` file with `observe` for first install. -> expect a non-destructive first run.
6. If the target repo uses a different doc layout, set environment overrides instead of editing the scripts first. -> expect the checks to honor the env vars below.
7. Run `utils/pdda-run.sh` in the target repo. -> expect report-only behavior in `observe` mode and an append to `PROJECT/PDDA-ACTIVITY.jsonl`.

## Environment overrides

PDDA is portable because the scripts can be redirected by env vars.

Use these when the target repo does not exactly match this repo's layout:

```text
PDDA_MODE
PDDA_WORKING_DIR
PDDA_MISC_DIR
PDDA_ACTIVITY_LOG
PDDA_ROADMAP
PDDA_STALE_DAYS
PDDA_DRY_RUN
PDDA_FORMAT
PDDA_ACTIVITY_MAX_LINES
PDDA_ROADMAP_MAX_LINES
PDDA_ROADMAP_MAX_HEADINGS
PDDA_LLM_BIN
PDDA_LLM_ARGS
PDDA_LLM_MODEL
```

## Minimal target-repo expectations

PDDA assumes these repo concepts exist, either literally or through overrides:

- an active-doc folder
- an archive/misc folder
- a repo roadmap file
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
chmod +x utils/pdda-*.sh utils/pdda-run.sh
printf 'observe\n' > .pdda-mode
utils/pdda-run.sh
```

Expected result:

- the run prints PDDA summaries
- `observe` mode prevents stale-doc moves
- `PROJECT/PDDA-ACTIVITY.jsonl` receives new entries
- the suite exits `0` even if it reports findings

## Notes for adaptation

- `PROJECT/PDDA.md` is the canonical policy doc; if the target repo needs wording changes, edit that file there after install.
- `pdda-doc-ready.sh` is opt-in for model use; if no model CLI is configured, it self-skips and the deterministic suite still works.
- `pdda-lib.sh` uses `node` for JSON escaping/parsing helpers, so Node is required even though the checks are shell scripts.
