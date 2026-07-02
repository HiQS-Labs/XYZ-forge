---
title: Centralized Transcript Archive (optional setting)
status: Proposed (1-INBOX — not yet active)
created: 2026-06-27
updated: 2026-06-27
owner: noel
goal: >
  Add ONE optional setting that redirects all multi-agent operational transcripts
  (relay threads, consult runs, marathon logs, swarm preflight packets) to a single
  centralized archive location instead of writing them into each foreign repo's
  relay-system/ folder. Default behavior is unchanged when the setting is unset.
doc_type: project
complexity: 3
risk: 4
effort: 3
ratings_provisional: true
non_goals:
  - Not changing the on-tree default (xyz's own relay-system/ stays put when unset)
  - Not building a transcript viewer/dashboard (telemetry extractor already exists)
  - Not moving .tick/ coordination state (token stays with the target repo)
related:
  - relay-automation/CONSUMING.md
  - relay-automation/relay-turn-lib.sh
  - PROJECT/PDDA.md
gh_issue: 30
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/30
roadmap_exempt: false
---

## Status

| What was just completed | What's next |
|---|---|
| Phase 0 intake done: issue [#30](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/30) opened, doc renamed `GH-30-…`, parked in ROADMAP. Plan drafted with per-phase QA gates. | Decide the archive model (separate-repo vs. plain-dir) — the last open Phase 0 item — then promote to `2-WORKING` before any code. |

## Effort & Risk (the question asked)

- **Effort: Moderate (~1–2 focused days).** The path itself is a one-line default in ~5 scripts behind a single resolver. The cost is concentrated in Phase 3 (off-tree containment + commit target), not in the redirect.
- **Risk: Costly (not a one-way door).** It touches relay containment (`relay-turn-lib.sh`) and commit semantics — `AGENTS.md` flags containment changes as "broader than they look." Fully reversible: unsetting the env var restores today's behavior exactly, and the resolver defaults to current paths.
- **Blast radius:** the relay turn-takers (agy/codex/claude shims), `consult.sh`, `marathon-drive.sh`, `relay-drive.sh` consult-verify output, `swarm-preflight.sh`, and the telemetry extractor that reads `relay-system/`. Each is a *writer* or *reader* of the same root; the setting changes that root in one place.
- **Reversibility read:** Easy to roll back the redirect; Costly to roll back if archived transcripts were committed to a separate repo and then depended upon. Mitigation: Phase 3 makes the archive write a leave-uncommitted (or archive-repo-local commit) operation, never an orphaned cross-repo commit.

## Table of Contents

- [Status](#status)
- [Effort & Risk (the question asked)](#effort--risk-the-question-asked)
- [Problem](#problem)
- [Proposed setting](#proposed-setting)
- [Phase 0 — Intake & decision gate](#phase-0--intake--decision-gate)
- [Phase 1 — Single transcript-root resolver](#phase-1--single-transcript-root-resolver)
- [Phase 2 — Wire the resolver into all writers](#phase-2--wire-the-resolver-into-all-writers)
- [Phase 3 — Off-tree containment & commit semantics](#phase-3--off-tree-containment--commit-semantics)
- [Phase 4 — Telemetry & discovery of archived transcripts](#phase-4--telemetry--discovery-of-archived-transcripts)
- [Phase 5 — Docs, defaults, and validation](#phase-5--docs-defaults-and-validation)

## Problem

When the relay/consult/marathon tooling runs against a **foreign repo B** (the supported
cross-repo mode in `relay-automation/CONSUMING.md`), the operational transcript is written
*inside repo B*:

- `RELAY_FILE=/abs/path/to/repoB/relay-system/<date>/<slug>.md` — "REL lives INSIDE repo B" (`CONSUMING.md:45`)
- `consult.sh:77` → `OUT="${OUT:-$ROOT/relay-system/$(date +%F)}"`
- `marathon-drive.sh:288` → `date_dir="$ROOT/relay-system/$(date +%Y-%m-%d)"`
- `relay-drive.sh:173` → `_cv_out_dir="$ROOT_DIR/relay-system/$(date +%F)"`
- `swarm-preflight.sh:477` → `OUT_DIR="…/relay-system/preflight/$TODAY/$SLUG"`

This pollutes every product repo with a `relay-system/` tree and lands generic relay commits in
its history. The operator wants those transcripts collected in **one place** instead.

## Proposed setting

One optional env var (mirroring the existing `*_ROOT` convention): **`XYZ_ARCHIVE_ROOT`**.

- **Unset (default):** behavior is byte-for-byte what it is today — transcripts go to `$ROOT/relay-system/…`.
- **Set to an absolute dir/repo:** all transcript writers emit to `$XYZ_ARCHIVE_ROOT/relay-system/<repo-slug>/<date>/…`, namespaced by source repo so a central archive can hold many repos without collision.
- Resolved **once** in a shared helper; every writer calls the helper instead of hardcoding `$ROOT/relay-system`.

> Decision deferred to Phase 0: whether `XYZ_ARCHIVE_ROOT` is a *separate git repo* (committed archive) or a *plain directory* (leave-uncommitted). This choice drives all of Phase 3.

## Phase 0 — Intake & decision gate

- [x] Open a GitHub issue describing the optional centralized-archive setting (issue-first SOP). → [#30](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/30)
- [x] Rename this doc to `PROJECT/1-INBOX/GH-30-CENTRALIZED-TRANSCRIPT-ARCHIVE.md` and set `gh_issue` in frontmatter.
- [x] Park a one-line queue pointer in `ROADMAP.md` linking the inbox doc.
- [x] Decide the archive model: **(A)** separate git repo (committed) vs **(B)** plain directory (uncommitted). → **DECIDED 2026-07-02: Model A (separate committed git repo)** — see the "Phase 0 — DECIDED" section below; recorded in `CHANGELOG.md`.
- [ ] Confirm the namespacing scheme (`<repo-slug>` from the target git remote/basename) avoids cross-repo collisions.

### QA checklist — Phase 0

- [ ] GH issue exists and is linked from both the doc frontmatter and `ROADMAP.md`.
- [ ] `utils/pdda/pdda.sh roadmap-coverage` passes (inbox doc is parked).
- [ ] Archive-model decision (A or B) is written down, not implicit.
- [ ] No code changed in this phase.

## Phase 1 — Single transcript-root resolver

- [ ] Add a `rtl_archive_root` (or `xyz_transcript_root`) helper to `relay-automation/relay-turn-lib.sh` that returns `$XYZ_ARCHIVE_ROOT/relay-system/<slug>` when set, else `$ROOT/relay-system`.
- [ ] Helper validates: if `XYZ_ARCHIVE_ROOT` is set it MUST be absolute and exist (fail loud, never silently fall back to the foreign tree).
- [ ] Helper derives `<slug>` deterministically from the target repo (remote basename, fallback to dir basename).
- [ ] Unit-cover the helper for: unset → today's path; set → namespaced path; set-but-missing → hard error.

### QA checklist — Phase 1

- [ ] With `XYZ_ARCHIVE_ROOT` unset, helper output equals the current hardcoded path (regression-safe).
- [ ] Resolver lives in exactly one place; no writer recomputes the root independently.
- [ ] New tests pass under `./validate.sh`.
- [ ] `utils/pdda/pdda.sh hardcoded-paths` clean.

## Phase 2 — Wire the resolver into all writers

- [ ] `consult.sh` — replace `OUT="${OUT:-$ROOT/relay-system/$(date +%F)}"` with the resolver.
- [ ] `marathon-drive.sh` — replace the `date_dir="$ROOT/relay-system/…"` derivation.
- [ ] `relay-drive.sh` — replace `_cv_out_dir` (consult-verify output).
- [ ] `swarm-preflight.sh` — replace the preflight `OUT_DIR` default.
- [ ] `RELAY_FILE` convention in `CONSUMING.md` — document deriving it from the resolver instead of hardcoding `repoB/relay-system/…`.
- [ ] Each writer still honors an explicit per-call override (`OUT=`, `--relay-file`) above the resolver default.

### QA checklist — Phase 2

- [ ] Each writer, run with the var unset, produces the same path as before the change.
- [ ] Each writer, run with the var set, writes under `$XYZ_ARCHIVE_ROOT/relay-system/<slug>/…`.
- [ ] Explicit overrides still win over the resolver default.
- [ ] `./validate.sh` green.

## Phase 3 — Off-tree containment & commit semantics

> The actual risk lives here. The relay turn guards restrict writes to the turn root and commit the transcript into the target repo's history. An off-tree archive collides with both.

- [ ] Extend the containment allowlist so the resolved archive root is a permitted write target (without widening the foreign-repo allowlist).
- [ ] Decide commit behavior per Phase-0 model:
  - [ ] Model A (separate repo): commit the transcript to the **archive** repo, never to repo B — verify no orphaned cross-repo commit (see the known `rtl_enforce` reset hazard).
  - [ ] Model B (plain dir): write transcript **uncommitted**; only `.tick/` token/commits (if any) stay with repo B.
- [ ] Ensure the relay turn-token (`.tick/`) stays anchored to the **target** repo even when the transcript is redirected (token and transcript may now live in different trees).
- [ ] Re-scope reviewer `ALLOW_PATHS` (recently tightened to the relay file) to the relay file at its new archive location.

### QA checklist — Phase 3

- [ ] A cross-repo relay turn with the var set writes its transcript to the archive and leaves repo B's tree free of `relay-system/`.
- [ ] No relay commit lands in repo B's history under the chosen model (verify with `git log` in repo B).
- [ ] Concurrent-commit guard does not reset/orphan a peer commit (the documented `rtl_enforce` hazard) when token and transcript trees differ.
- [ ] Reviewer allowlist still scopes to exactly one relay file.

## Phase 4 — Telemetry & discovery of archived transcripts

- [ ] `utils/telemetry/extract-relay-telemetry.sh` reads `$RELAY_SYSTEM` from the resolver, so it finds archived transcripts (currently `$ROOT_DIR/relay-system`).
- [ ] Telemetry handles the `<repo-slug>` namespacing layer when aggregating across repos.
- [ ] `relay-to-issue` / discovery paths that auto-detect `relay-system/<date>/<slug>.md` honor the archive root.

### QA checklist — Phase 4

- [ ] Telemetry extractor produces a feed from an archived (off-tree) transcript set.
- [ ] Aggregation across two source repos does not collide on date/slug.
- [ ] Auto-detect of "newest relay thread" resolves correctly when archived.

## Phase 5 — Docs, defaults, and validation

- [ ] Document `XYZ_ARCHIVE_ROOT` in `relay-automation/CONSUMING.md` (cross-repo recipe) and `relay-automation/README.md`.
- [ ] Note the default-unchanged guarantee and the namespacing scheme.
- [ ] Add a `CHANGELOG.md` entry recording the bet (Costly: containment touch) with the reversibility read and revisit trigger.
- [ ] Promote this doc to `PROJECT/2-WORKING/` with the full active-doc contract intact.

### QA checklist — Phase 5

- [ ] `./validate.sh` green.
- [ ] `utils/pdda/pdda.sh run` clean (frontmatter, status table, hardcoded paths, roadmap coverage).
- [ ] Docs describe both default and archive modes; no hardcoded absolute paths in the docs.
- [ ] `CHANGELOG.md` entry present with the bet recorded.

## Phase 0 — DECIDED 2026-07-02: archive model **A (separate committed git repo)**

The operator chose **Model A**: `XYZ_ARCHIVE_ROOT` points at a **separate git repo** transcripts are
committed into (durable, shareable history across devices), NOT a plain uncommitted directory. This
contract must honor the cross-repo commit consequences: (a) keep `TICK_REPO_ROOT` + the allowlist
anchored on the **target** repo (never the archive); (b) commit to the archive repo only via an
isolated archive-commit step that can never orphan a peer commit in the target tree (the documented
`rtl_enforce` reset/orphan hazard when token-tree ≠ transcript-tree); (c) hard-error on a
set-but-missing / non-git `XYZ_ARCHIVE_ROOT` (never silent fallback). Namespacing: `<repo-slug>` from
the git remote basename (fallback dir basename), collision-checked.

## Swarm Preflight Contract

Consumed by `utils/swarm-preflight.sh`. Same-repo build (`target.ref: main`). **Orchestrator-only
kernel lane** (`relay-turn-lib.sh` is the containment kernel) — serialized, never parallel. Model A's
cross-repo commit semantics are why risk is 4. Gate is a new test. Because this is phased + Costly,
build it phase-gated (Phase 1 resolver first is a safe standalone slice; Phase 3 containment is the
risky one).

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash test/archive-root.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "relay-automation/relay-turn-lib.sh", "pattern": "XYZ_ARCHIVE_ROOT" } ],
  "artifacts":   [ "relay-automation/relay-turn-lib.sh", "relay-automation/consult.sh", "relay-automation/marathon-drive.sh", "relay-automation/relay-drive.sh", "utils/swarm-preflight.sh", "utils/telemetry/extract-relay-telemetry.sh", "relay-automation/CONSUMING.md", "relay-automation/README.md", "test/archive-root.sh" ],
  "remediation": { "source": "GH-30#phase-0-model-A", "criteria": "A single resolver in relay-turn-lib.sh returns $XYZ_ARCHIVE_ROOT/relay-system/<repo-slug> when set (absolute + existing git repo, else HARD ERROR — never silent fallback) and $ROOT/relay-system when unset (byte-for-byte current path); all transcript writers (consult/marathon-drive/relay-drive/swarm-preflight/extract-relay-telemetry) call it; explicit per-call overrides (OUT=/--relay-file) still win. MODEL A: commit the transcript into the SEPARATE archive git repo via an isolated step that keeps TICK_REPO_ROOT + allowlist anchored on the TARGET repo and never orphans a peer commit in the target tree. NEW test/archive-root.sh covers unset / set / set-but-missing / non-git-archive (hard error) + a cross-repo turn leaving the target tree free of relay-system/. Costly containment-kernel change; GH-30 marker comment." },
  "lanes":       { "agy_safe": [], "orchestrator_only": [ "relay-automation/relay-turn-lib.sh" ] }
}
```
