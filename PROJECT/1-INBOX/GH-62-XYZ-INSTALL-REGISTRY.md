---
gh_issue: 62
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/62
title: XYZ install registry — call-home to remember install locations (borrow PDDA pattern)
status: Proposed (1-INBOX — not yet active)
created: 2026-06-30
doc_type: feedback
---

> **Inbox capture.** Per PDDA, a `1-INBOX/GH-*.md` doc carries no `## Status` table while it sits
> here; it is the capture, not the active-work doc. Promote to `2-WORKING/` (keeping the `GH-62`
> prefix + adding the exact status table) when execution starts.

## Problem

The XYZ `tick` runtime is installed by materializing `bin/tick` + `src/*.js` into a directory — today
only via the `/xyz` SKILL self-extractor. There is **no record of where copies were installed**, so
when a new `tick` version is cut in this repo there is no way to know which locations are behind and
need a re-push. There is also real provenance drift with nothing surfacing it: the repo master is
`SCHEMA_VERSION = 0.2.0` (`src/events.js`) while the SKILL self-extract still ships `0.1.0`.

## Borrowed pattern

Adopt PDDA's **"install → call home to register location"** pattern
([`pdda/install.sh`](../../../pdda/install.sh) → `~/.config/pdda/registry.tsv`), adapted to XYZ's
self-extract model. The valuable core is a **per-user, machine-local registry** recording WHERE each
copy was installed and on which source version/commit, plus an optional path-normalized multi-device
projection carried by git-pulse.

## Proposed build (this issue)

- **`install.sh`** at repo root: materialize the runtime (`bin/tick` + `src/*.js`) into a target dir,
  then register the install.
- **Registry** `~/.config/xyz/registry.tsv` — machine-local, lives in `$HOME`, **never committed**
  (can't leak into the eventually-public repo). One row per install dir, latest wins, atomic tmp+mv,
  best-effort / fail-open (a registry failure never fails the install).
- **Columns:** `install_dir` (primary key) · `last_install_utc` · `tick_version` (grepped
  `SCHEMA_VERSION`) · `source_commit` · `coordinated_repo` (`TICK_REPO_ROOT`, or `-`).
- **Multi-device rollup:** best-effort git-pulse projection (path-normalized; never absolute paths),
  mirroring PDDA. Absent git-pulse → silently skipped.
- **`/xyz` SKILL parity:** add the same compact register step to the SKILL self-extract block, with a
  "keep in lockstep" comment (mirrors PDDA's `install.sh` ↔ `PDDA-INSTALL.md` pairing).
- **Opt-out:** `--no-register`; `-h` usage.

## Out of scope (follow-ons)

- An `xyz-sync` push tool that reads the registry and re-materializes stale copies (PDDA's
  `pdda-sync.sh` analog).
- Resolving the `bin/tick`(0.2.0) ↔ SKILL-embed(0.1.0) drift / defining the embed-sync direction.

## Effort & risk

- **Effort: Small.** The registry core is ~40 lines lifted almost verbatim from PDDA; `install.sh`'s
  copy step is a `bin/tick` + `src/*.js` materialize.
- **Risk / blast radius: low.** Additive new file + one additive edit to the global SKILL block;
  writes only to `$HOME`. Touches nothing in `.tick/events/`, `src/*.js`, or event/verb shape — stays
  clear of AGENTS.md's "at least Costly" surfaces.
- **Reversibility: Easy** — delete `install.sh` + the registry file; nothing tracked changes.

## Acceptance (when worked)

- `./install.sh <scratch-dir>` materializes a working `tick` and appends exactly one row to
  `~/.config/xyz/registry.tsv` stamped `0.2.0`.
- Re-running updates in place (still one row for that dir).
- `./validate.sh` green; `utils/pdda/pdda.sh run` clean.

## Provenance

Filed 2026-06-30 while preflighting a cross-repo Marathon Queue (rebalance-OS): installing `tick` into
an external repo surfaced that we keep no record of install locations. Relates to GH-49 (vendored local
copy / locator chain), the `relay-pkg`/`skill-extract` packaging, and the PDDA registry + git-pulse
rollup this borrows from. Parked in the ROADMAP queue (not in progress).
