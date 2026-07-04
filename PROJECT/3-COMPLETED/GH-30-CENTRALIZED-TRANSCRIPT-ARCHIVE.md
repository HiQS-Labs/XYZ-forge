---
title: Centralized Transcript Archive (optional setting)
status: Complete (3-COMPLETED — all phases shipped 2026-07-03)
created: 2026-06-27
updated: 2026-07-03
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
| **✅ ALL PHASES SHIPPED 2026-07-03.** Phases 1–2 (resolver + writer wiring) plus **Phase 3** (Model A off-tree commit): `rtl_init` flags `RTL_ARCHIVE_MODE` when the relay file lives in a git repo distinct from `RTL_ROOT`, and `rtl_enforce` commits the **transcript into the archive** via an isolated `git -C` pathspec commit while the **code artifact + `.tick` token stay on the target** — the target tree stays free of `relay-system/`, no transcript commit lands in target history, and the isolated archive commit can never orphan a concurrent peer commit (GH-13 guard is target-only, holds when token-tree ≠ transcript-tree). Worktree seed/copyback skip the absolute archive entry in lockstep. **Phase 4** — `extract-relay-telemetry.sh` reads the resolver and aggregates across all `<repo-slug>/` dirs when set. **Phase 5** — `new-relay.sh` wired to the resolver; `CONSUMING.md` + `README.md` document the full contract; CHANGELOG bet recorded. New `test/archive-commit.sh` (16) + `test/archive-telemetry.sh` (3) wired into `validate.sh`. | **Done** — promote to `3-COMPLETED`, close [#30](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/30). Follow-on (not this issue): live end-to-end archive dogfood against a real foreign repo. |

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

## Phase 1 — Single transcript-root resolver ✅ SHIPPED 2026-07-03

- [x] Add a `rtl_transcript_root` helper to `relay-automation/relay-turn-lib.sh` that returns `$XYZ_ARCHIVE_ROOT/relay-system/<slug>` when set, else `$root/relay-system`. (Companion `rtl_repo_slug` derives the slug.)
- [x] Helper validates: if `XYZ_ARCHIVE_ROOT` is set it MUST be absolute, exist, **and be a git repo** (Model A) — fail loud (stderr + `return 1`), never silently fall back to the foreign tree.
- [x] Helper derives `<slug>` deterministically from the target repo (origin remote basename, fallback to dir basename, sanitized to a single `[A-Za-z0-9._-]` segment).
- [x] Unit-cover the helper for: unset → today's path; trailing-slash target; set → namespaced path; set-relative/missing/non-git → hard error (+ stderr); slug-fallback; scp-style remote; trailing-slash remote; `..`/`.` traversal → `repo`; leading-dash → stripped; space → `_`. (`test/archive-root.sh`, **13 checks** after the cross-model review below.)

### Cross-model review (Codex + agy, PR #105) — 1 Blocker + 2 Shoulds fixed before merge

Both models independently flagged the same **[Blocker]**: `rtl_repo_slug`'s `tr -c 'A-Za-z0-9._-'` sanitizer *preserved* `.` and `-`, so a target basename of `..` produced slug `..` → `$XYZ_ARCHIVE_ROOT/relay-system/..` **escaped the namespace** (path traversal), and a leading-`-` slug was option-shaped for a later `cd`/`git -C`. Plus two **[Should]**s: a trailing-slash origin URL (`…/foo.git/`) yielded an empty remote basename → wrong dir-basename fallback; a trailing-slash `target_root` → `//relay-system`. **Fixed:** strip trailing slashes off the remote URL (before + after `.git`); strip leading dashes; collapse `.`/`..`/empty → `repo`; normalize one trailing slash off `target_root` (byte-identical on the normalized roots callers pass). Both graded fail-loud, `set -u/-e` safety, and determinism **[Pass]**. Tests grew 7 → 13 to pin every case.

### QA checklist — Phase 1

- [x] With `XYZ_ARCHIVE_ROOT` unset, helper output equals the current hardcoded path (regression-safe — asserted; trailing-slash target normalized so no `//`).
- [x] Resolver lives in exactly one place; no writer recomputes the root independently. (Writers wired in Phase 2.)
- [x] Slug is always a safe single path segment — no `/`, no `.`/`..` traversal, no leading `-`, never empty (cross-model-reviewed + asserted).
- [x] New tests pass under `./validate.sh` (89/89 green; also fixed a pre-existing `test/xyz-vendor.sh` typo that was reddening the suite).
- [x] `utils/pdda/pdda.sh hardcoded-paths` clean (0 errors).

## Phase 2 — Wire the resolver into all writers ✅ SHIPPED 2026-07-03

Each writer now sources `relay-turn-lib.sh` (by the script's own dir, so a foreign `CONSULT_ROOT`/`--target-root` doesn't break discovery) and derives its transcript base from `rtl_transcript_root "$ROOT"`. The resolver is invoked **only when no explicit override is set**, so an explicit `--out`/`OUT=` fully wins — even against an invalid `XYZ_ARCHIVE_ROOT` — and each call fails loud (`|| exit/return 1`) under both `set -e` and `set -uo`.

- [x] `consult.sh` — `OUT` default now `rtl_transcript_root "$ROOT"/<date>` (guarded on empty `$OUT`).
- [x] `marathon-drive.sh` — `save_transcript` derives `date_dir` from the resolver (declare-then-assign so `local` doesn't mask the rc).
- [x] `relay-drive.sh` — `_cv_out_dir` (consult-verify output) derives from the resolver.
- [x] `swarm-preflight.sh` — `OUT_DIR` default resolved **once** before the dry-run gate, so the `Would emit to:` preview and the real emit agree.
- [x] `CONSUMING.md` — new "keep transcripts OUT of repo B (`XYZ_ARCHIVE_ROOT`)" section; derive `RELAY_FILE` from the base instead of hardcoding `repoB/relay-system/…`.
- [x] Each writer still honors an explicit per-call override (`--out`/`OUT_DIR`) above the resolver default (asserted).

### QA checklist — Phase 2

- [x] Each writer, run with the var unset, produces the same path as before (consult e2e `T1`, swarm dry-run `T8b`).
- [x] Each writer, run with the var set, writes under `$XYZ_ARCHIVE_ROOT/relay-system/<slug>/…` (consult e2e `T2`, swarm dry-run `T8c`).
- [x] Explicit overrides still win over the resolver default (consult `T3`, swarm `T8d`).
- [x] Set-but-invalid archive fails loud with no silent fallback into the target repo (consult `T4`).
- [x] `./validate.sh` green (**90/90**; new `test/archive-writers.sh` = consult end-to-end + a structural regression lock over all four writers; marathon-drive/relay-drive covered structurally + by the resolver unit test, since a full relay loop needs codex/agy + network). `hardcoded-paths` clean.

> **Scope note:** Phase 2 redirects the transcript *writers*. A cross-repo relay *turn* is not fully redirected until **Phase 3** (containment allowlist + commit-into-archive), because the turn's own relay-file writes are still governed by the target-repo write-allowlist in `relay-turn-lib.sh`. `consult.sh` and `swarm-preflight.sh` (no containment) are fully redirected today.

## Phase 3 — Off-tree containment & commit semantics ✅ SHIPPED 2026-07-03

> The actual risk lived here. The relay turn guards restrict writes to the turn root and commit the transcript into the target repo's history. An off-tree archive collides with both. Resolved by a **split commit**: transcript → archive repo (isolated `git -C`), code artifact + `.tick` → target repo.

- [x] Extend the containment allowlist so the resolved archive root is a permitted write target (without widening the foreign-repo allowlist). — `rtl_init` flags `RTL_ARCHIVE_MODE` when the relay file's git toplevel ≠ `RTL_ROOT`; the out-of-root relay file is an absolute allowlist entry, inert to the `RTL_ROOT` status/commit loop, and the worktree seed/copyback skip absolute entries in lockstep (seedsig index preserved).
- [x] Commit behavior per Phase-0 model:
  - [x] Model A (separate repo): `rtl_enforce` commits the transcript to the **archive** repo via an isolated `git -C "$RTL_RELAY_REPO"` pathspec commit, never to the target — the archive commit can't move the target's HEAD, so it can never orphan a concurrent peer commit (`test/archive-commit.sh` peer-case).
  - [x] ~~Model B (plain dir)~~ — not chosen (Model A decided 2026-07-02).
- [x] Ensure the relay turn-token (`.tick/`) stays anchored to the **target** repo even when the transcript is redirected — the GH-67 handoff already uses `TICK_REPO_ROOT`; archive mode never touches it, so token-tree and transcript-tree differ safely.
- [x] Reviewer `ALLOW_PATHS` scoping is preserved — reviewer-turn detection (relay file only) is upstream of archive detection and unchanged; the single relay file is the only writable target whether in-tree or in the archive.

### QA checklist — Phase 3

- [x] A cross-repo relay turn with the var set writes its transcript to the archive and leaves the target tree free of `relay-system/`. (`archive-commit.sh` T1)
- [x] No relay commit lands in the target's history under Model A. (`archive-commit.sh` T1: no `transcript` commit in target log)
- [x] Concurrent-commit guard does not reset/orphan a peer commit when token and transcript trees differ. (`archive-commit.sh` T3: peer commit preserved, artifact on top, archive transcript still committed)
- [x] Reviewer allowlist still scopes to exactly one relay file. (unchanged; `worktree-isolation.sh` + `relay-artifact-file.sh` still green)

## Phase 4 — Telemetry & discovery of archived transcripts ✅ SHIPPED 2026-07-03

- [x] `utils/telemetry/extract-relay-telemetry.sh` reads the resolver, so it finds archived transcripts (was `$ROOT_DIR/relay-system`).
- [x] Telemetry handles the `<repo-slug>` namespacing layer when aggregating across repos — archive mode scans `$XYZ_ARCHIVE_ROOT/relay-system/*/*/` (slug/date).
- [~] `relay-to-issue` / discovery auto-detect honoring the archive root — `relay-to-issue` is an external Claude skill (not a repo script); the repo-side extractor honors the archive, and the skill should resolve `XYZ_ARCHIVE_ROOT` the same way when archived. Tracked as a follow-on note, not a repo deliverable.

### QA checklist — Phase 4

- [x] Telemetry extractor produces a feed from an archived (off-tree) transcript set. (`archive-telemetry.sh`)
- [x] Aggregation across two source repos does not collide on date/slug. (`archive-telemetry.sh`: same-named threads in two slugs → distinct records)
- [x] Unset path still yields a valid feed. (`archive-telemetry.sh`: empty range → `[]`)

## Phase 5 — Docs, defaults, and validation ✅ SHIPPED 2026-07-03

- [x] Document `XYZ_ARCHIVE_ROOT` in `relay-automation/CONSUMING.md` (cross-repo recipe) and `relay-automation/README.md`.
- [x] Note the default-unchanged guarantee and the namespacing scheme.
- [x] Add a `CHANGELOG.md` entry recording the bet (Costly: containment touch) with the reversibility read and revisit trigger.
- [x] Promote this doc to `PROJECT/3-COMPLETED/` with the full active-doc contract intact.

### QA checklist — Phase 5

- [x] `./validate.sh` green.
- [x] `utils/pdda/pdda.sh run` clean (frontmatter, status table, hardcoded paths, roadmap coverage).
- [x] Docs describe both default and archive modes; no hardcoded absolute paths in the docs.
- [x] `CHANGELOG.md` entry present with the bet recorded.

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
