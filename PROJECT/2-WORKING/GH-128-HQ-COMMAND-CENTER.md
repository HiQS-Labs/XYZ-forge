---
gh_issue: 128
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/128
title: "HQ — multi-repo command-center skill: one utterance → registry-resolved repo → PDDA-compliant intake → marathon queue/dispatch"
status: Active — Phases 0–2 built & verified; Phase 3 (dispatch) next
created: 2026-07-04
updated: 2026-07-04
owner: noel
goal: >
  Turn one utterance ("For project Acme, do X") into governance-aware action across every repo on
  this device: resolve the project name to a real repo via the registry ladder, report its PDDA
  governance state, and (later phases) land the request on that repo's own PDDA rails with
  explicit-verb-only dispatch. Phase 0/1 (this iteration) is the read-only resolver + project card.
doc_type: project
effort: 3
complexity: 3
risk: 2
phases: 4
related:
  - PROJECT/PDDA.md
  - PROJECT/3-COMPLETED/GH-96-XYZ-REBALANCE-SYNC-CHECK.md
  - PROJECT/3-COMPLETED/GH-62-XYZ-INSTALL-REGISTRY.md
  - skills/hq/SKILL.md
  - utils/hq/hq.sh
  - utils/hq/hq-lib.sh
  - test/hq.sh
  - GH-128-HQ-system-diagram.html
non_goals:
  - "Phase 2/3 write paths (issue-first intake, queue/fire dispatch) are NOT built in this iteration —
    the prototype is read-only. The `park`/`queue`/`fire` verbs exist only as gated not-yet-built notices."
  - "Rebalance is read-only in HQ's direction, always (mirrors #96 / rebalance-OS#102 seam discipline)."
  - "No fuzzy/alias resolution yet — Phase 1 matches exact repo names or a project's repo-part; the
    fuzzy rung + operator-confirm loop is Phase 1.x / future."
---

# HQ — multi-repo command-center skill

The front door for one-utterance, multi-repo tasking: **"For project Acme, do this and that"** →
resolve *Acme* to a real repo on this device → read its governance state → (later) land the request
on *that repo's* PDDA rails with explicit-verb-only dispatch. Issue [#128].

**Companion system diagram:** interactive [GH-128-HQ-system-diagram.html](GH-128-HQ-system-diagram.html)
(16 nodes, 19 typed edges), built from its [JSON spec](GH-128-HQ-system-diagram.json).

## Status

| What was just completed | What's next |
|---|---|
| **Phases 0–2 built and verified — the first runnable end-to-end prototype.** Phase 0 (registry discovery, written back below) + Phase 1 (read-only resolver + project card: `skills/hq/SKILL.md`, `utils/hq/hq.sh`, `utils/hq/hq-lib.sh`, `test/hq.sh` 18/18) + **Phase 2 (`park` intake writer)**: `hq.sh park [--create] <project> <request>` resolves the target, then **previews by default** (writes nothing) or, with `--create`, files the real GitHub issue → writes the PDDA `PROJECT/1-INBOX/GH-<n>-<SLUG>.md` capture → inserts the `ROADMAP.md` queue pointer → runs the target's own `pdda.sh frontmatter`. Dup-guard + Tier-C-is-plain-issue-only + `HQ_GH_BIN` stub seam. Hermetic `test/hq-park.sh` (19/19, in `validate.sh`); `gh`-stubbed `--create` proven to write correct frontmatter and a Queue-placed pointer. Preview proven live against `sleuth-app` (Tier A). | **Phase 3 (dispatch):** `queue` (append a rated lane to the target's Marathon Plan) + `fire` (`swarm-preflight --target-root → marathon-drive`), with the `risk >= 3` gate. **Phase 1.x:** fuzzy/alias resolution. Firing a **real** `park --create` against a live repo awaits a concrete operator request. |

## Table of contents

- [Phase 0 — Discovery: registry schemas, coverage & resolution order](#phase-0--discovery-registry-schemas-coverage--resolution-order) ✅
- [Phase 1 — Read-only resolver + `hq status` project card](#phase-1--read-only-resolver--hq-status-project-card) ✅ (prototype)
- [Phase 2 — Intake writer (issue → capture → roadmap parking)](#phase-2--intake-writer-issue--capture--roadmap-parking) ✅ (`park`)
- [Phase 3 — Dispatch (`queue` / `fire`)](#phase-3--dispatch-queue--fire) ⏳
- [Phase 4 — Deferred: user-level skill + Rebalance-priority promotion](#phase-4--deferred-user-level-skill--rebalance-priority-promotion)

## Capability tiers (what HQ may do per repo)

- **Tier A** — PDDA + vendored XYZ: full flow, dispatch allowed (Phase 3).
- **Tier B** — PDDA only: issue + capture doc + roadmap parking; no dispatch.
- **Tier C** — bare repo: plain GH issue; offer a PDDA install as the remedy.

## Safety rails (inherited, not invented)

- `park` (intake only) is the default intent; `queue`/`fire` require the explicit verb.
- PDDA triage `risk` is a gate, not an addend: `risk >= 3` never auto-fires.
- Cross-repo writes only through the containment-correct `--target-root` path (GH-51 fix).
- `fire` refuses on Tier B/C repos and when `xyz-sync check` reports drift.
- HQ never writes Rebalance state; the seam stays read-only in that direction.

---

## Phase 0 — Discovery: registry schemas, coverage & resolution order

**Investigated:** the three registries HQ resolves against, their live schemas, their coverage on
this device, and — the load-bearing question — which one carries a usable *local path*.

**Found (verified live 2026-07-04):**

| Registry | Location | Schema | Carries a path? | Coverage seen |
|---|---|---|---|---|
| **Rebalance `project_registry`** | `rebalance-OS/rebalance.db` (sqlite) | `name` (PK, `owner/repo`) · `status` · `summary` · `value_level` · `priority_tier` · `risk_level` · `repos_json` · `tags_json` · `custom_fields_json` | **No** | 15 projects (semantic catalog) |
| **XYZ install registry** | `~/.config/xyz/registry.tsv` | `install_dir` · `last_install_utc` · `tick_version` · `source_commit` · `coordinated_repo` | **Yes** (`coordinated_repo` is absolute) | 5 rows (XYZ-installed repos) |
| **Git Pulse PDDA registry** | `~/git-pulse-sync/pdda/registry-<device>.tsv` | `repo` · `last_install_utc` · `mode` · `source_commit` · `startup_docs` | **No** (paths deliberately omitted) | 2 devices × 2 repos each |

**What it changes (the resolution order the later phases build on):**

1. The **human project name** ("Acme") lives only in Rebalance `project_registry.name` (as `owner/repo`)
   with its `repos_json` repo list + `priority_tier` — so **Rebalance is the semantic entry rung**, but
   it cannot give a path.
2. Only the **XYZ registry** reliably carries an absolute path (`coordinated_repo`) — so it is the
   **path resolver**, but only for XYZ-installed repos.
3. The **Git Pulse registry** is the PDDA-governance rung (mode + startup_docs), device-partitioned but
   all device files are readable from the sync repo — so HQ scans *every* `registry-*.tsv`, not just
   this device's.
4. **Gap → a filesystem `find` fallback is mandatory**, because no registry covers every repo's path.
   This is the recipe the git-pulse registry header already documents; HQ implements it as rung 4.

Final ladder: **Rebalance NAME → repo → XYZ path (else filesystem find) → PDDA governance overlay.**
This is encoded in `hq_resolve()` (`utils/hq/hq-lib.sh`) and mirrored in the companion diagram.

### QA gate — Phase 0

- [x] All three registries' live schemas captured with a repo-relative pointer to each source.
- [x] Coverage on this device recorded (counts per registry).
- [x] The path-availability gap identified and the canonical resolution order decided.
- [x] Findings written back into this doc (this section) — the PDDA discovery contract.

---

## Phase 1 — Read-only resolver + `hq status` project card

**Goal:** the first use case — resolve a project by name and print an accurate project card — with
**zero writes**. Independently useful (answers "which repo is this and what shape is it in?").

**Built:**

- `skills/hq/SKILL.md` — the `/hq` front door (read-only: `status` / `resolve` / `registries`;
  write verbs explained as Phase 2/3).
- `utils/hq/hq-lib.sh` — the 4-rung resolution ladder + `hq_inspect_repo` + `hq_tier`, each rung
  degrading gracefully to empty when its source is missing (offline-tolerant, like PDDA). Env seams:
  `HQ_PDDA_REGISTRY_DIR`, `HQ_XYZ_REGISTRY`, `HQ_REBALANCE_DB`, `HQ_SEARCH_ROOTS`. SQL input is
  sanitized before interpolation; the reserved name `PATH` is avoided (uses `REPO_PATH`).
- `utils/hq/hq.sh` — dispatcher: `resolve` (machine-readable `KEY=value`), `status` (the card),
  `registries` (Phase-0 introspection). `park`/`queue`/`fire` are gated not-yet-built notices (rc=3).
- `test/hq.sh` — hermetic fixture test (builds fake registries + a repo tree under a temp dir, points
  the env seams at them), **18/18**, registered in `validate.sh`.

**Proof — first use case, live on this device:**

```text
$ bash utils/hq/hq.sh status sleuth-app
HQ · project card
  query:        sleuth-app
  repo:         sleuth-app
  path:         .../sleuth-app  (via xyz-registry)
  capability:   Tier A — PDDA + XYZ (dispatch-eligible)

  Rebalance:    NeochromeTeam/sleuth-app · priority tier 3 · value –
  PDDA rails:   mode observe · startup_docs yes · (git-pulse: noels-mac-studio)
  local mode:   observe
  startup docs: ROUTER ✓  AGENTS ✓  ROADMAP ✓
  active docs:  8 in PROJECT/2-WORKING
  marathon:     MARATHON-PLAN-2026-07-03.md
  XYZ install:  yes · tick 0.2.0 · harness commit c60ec66
```

All three registries fed one card. Cross-device resolution confirmed (`rebalance-OS`, registered in
the *mbp* git-pulse file, resolves from mac-studio); unresolved names return rc=1 with the find recipe.

### QA gate — Phase 1

- [x] `hq status <project>` resolves ≥1 real repo through the full ladder and prints an accurate card
      (verified: `sleuth-app` and `rebalance-OS`, both Tier A).
- [x] Resolution degrades correctly: filesystem fallback (source=`filesystem`), unresolved → rc=1 with
      an actionable recipe, PDDA-only-known-but-no-path → rc=1 (no crash). All covered by `test/hq.sh`.
- [x] Capability tier (A/B/C) derived from PDDA + XYZ presence and shown on the card.
- [x] `test/hq.sh` hermetic (no live-registry dependency) and green in `validate.sh` (18/18).
- [x] No writes anywhere; Rebalance read-only.

---

## Phase 2 — Intake writer (issue → capture → roadmap parking)

**Goal:** the first write path — the first *runnable* end-to-end use case. Given a resolved Tier A/B
repo + a request, land it on *that repo's* rails: `gh issue create` →
`PROJECT/1-INBOX/GH-<n>-<SLUG>.md` capture (PDDA frontmatter) → one-line `ROADMAP.md` queue pointer →
run the target's own `pdda.sh frontmatter`. Dup-guard against the target's existing open issues.

**Design decision — preview-first (refines "park by default").** `park` is the first outward-facing
write (a GitHub issue can be closed but not un-created), so it **previews by default and only writes
with `--create`**. This keeps the prototype fully runnable/demonstrable without firing an irreversible
action, and makes the exact artifacts reviewable before they exist. Reversibility: **Easy** in preview
(no-op); **Costly** on `--create` (an outward issue) — hence the explicit flag. `queue`/`fire` (Phase 3)
stay gated notices.

**Built:**

- `utils/hq/hq.sh` `park` subcommand + helpers in `hq-lib.sh` (`hq_slug`, `hq_issue_title`,
  `hq_render_capture`, `hq_roadmap_line`, `hq_roadmap_insert`, `hq_target_slug`).
- **Preview** (default): prints the would-be issue title, capture-doc path + full rendered content, and
  ROADMAP line. Writes nothing.
- **`--create`**: dup-guard (`gh issue list --search`) → `gh issue create` → write the capture doc →
  insert the ROADMAP pointer under the target's `### Queue` heading → run the target `pdda.sh
  frontmatter` on the new doc. Files are **written but not committed** (operator reviews, then commits).
- **Tier C** repos get a plain issue only (no partial doc structure) + a PDDA-install suggestion.
- `HQ_GH_BIN` seam lets the test stub `gh` (no network / no real issue).
- **`--title` (added from first-use feedback):** `park [--title "…"]` sets a clean issue + capture-doc
  title (and drives the filename slug) while the full request stays the issue body — the derived title
  truncated the raw request awkwardly on the first real run.

**Proof:** hermetic `test/hq-park.sh` (**23/23**, in `validate.sh`) exercises preview-writes-nothing,
`--create` writing correct frontmatter (`gh_issue`, `source`, `status`) + a Queue-placed pointer,
`--title` override, stopword-aware slugging, dup-guard abort, Tier C, and unresolved.

**First live run — 2026-07-04 (first real end-to-end HQ intake).** Operator request "for rebalance-OS,
fix the focus5 refresh button for removed worktrees + shrink repo names 20%" → filed as **two** issues
into `rebalance-OS` (Tier A), each landing a GH issue + a PDDA capture doc + a ROADMAP Queue pointer,
both passing `rebalance-OS`'s own `pdda.sh frontmatter`:
- [#109](https://github.com/Hypercart-Dev-Tools/rebalance-OS/issues/109) — focus5 refresh button does not drop Git Worktrees removed from disk.
- [#110](https://github.com/Hypercart-Dev-Tools/rebalance-OS/issues/110) — focus5: shrink repo-name font size by 20%.
Surfaced the fuzzy-resolution gap (needed canonical `rebalance-OS`, not "rebalanceOS") — Phase 1.x.

### QA gate — Phase 2

- [x] Produces, in the *target* repo (via `--create`): a GH issue, a correctly named capture doc whose
      frontmatter passes `pdda.sh frontmatter`, and a `ROADMAP.md` queue pointer (placed under `### Queue`).
- [x] Dup-guard: an open issue matching the title aborts `--create` without writing (rc=1).
- [x] Tier C yields a plain issue + a suggested PDDA-install path, never a partial doc structure.
- [x] Preview writes nothing (verified: 1-INBOX + ROADMAP unchanged); `--create` writes only inside the
      resolved target repo and reports a receipt per artifact.
- [x] `test/hq-park.sh` hermetic (stubbed `gh`, fixture repos) and green in `validate.sh`.
- [x] **Fired for real:** a genuine `park --create` filed rebalance-OS #109 + #110 end-to-end
      (issue + capture doc + ROADMAP pointer, validated by rebalance-OS's own PDDA). First live intake.

## Phase 3 — Dispatch (`queue` / `fire`)

**Goal:** `queue` appends a rated lane to the target's current Marathon Plan (honoring its collision
map + the GH-45 queue-commitment contract); `fire` drives a contained lane via
`swarm-preflight --target-root <repo> → marathon-drive`. Park-by-default preserved.

### QA gate — Phase 3

- [ ] `queue` appends a lane without violating the plan's collision map.
- [ ] `fire` refuses when `risk >= 3`, on Tier B/C repos, or when `xyz-sync check` reports drift.
- [ ] Every dispatch is traceable to its intake issue.

## Phase 4 — Deferred: user-level skill + Rebalance-priority promotion

Promote `/hq` to user level (usable from any repo's session) and use Rebalance `priority_tier` to
*suggest* which parked HQ intake to promote next. Deferred until Phases 2–3 prove out.

### QA gate — Phase 4

- [ ] `/hq` resolves + reports from a session in a non-HQ repo.
- [ ] Promotion suggestions rank by Rebalance priority without auto-acting.
