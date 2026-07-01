---
title: Optional vendored local copy of harness scripts (WIP-decoupled fallback for foreign repos)
status: Active (2-WORKING)
created: 2026-06-29
updated: 2026-06-30
owner: noel
gh_issue: 49
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/49
doc_type: feature
goal: >
  Let a foreign repo run relays self-contained against a pinned, git-ignored `.xyz/`
  snapshot of the harness, so relays no longer couple to a live (possibly mid-WIP or
  unavailable) harness clone. Opt-in, additive, byte-for-byte unchanged when unused.
complexity: 3
risk: 3
effort: 3
non_goals:
  - Not changing default (no-`.xyz/`) locator behavior — must stay byte-for-byte identical
  - Not auto-vendoring — the vendor command is always explicit/opt-in
  - Not a cross-machine sync — `.xyz/` is per-repo, git-ignored, single-clone
related:
  - PROJECT/3-COMPLETED/GH-62-XYZ-INSTALL-REGISTRY.md   # the registry this reuses
  - skills/relay-automation/make-pkg.sh                 # the 16-file relay-pkg manifest
  - skills/relay-xyz/find-harness.sh                    # the locator this extends
  - decisions/2026-06-30-vendored-harness-locator.md    # the containment decision record
roadmap_exempt: false
---

## Status

| What was just completed | What's next |
|---|---|
| **Phase 1 — vendor command shipped (swarm-produced).** `relay-automation/xyz-vendor.sh` built by **codex** and reviewed by **agy → Approved** (cross-model relay [gh49-phase1-vendor.md](../../relay-system/2026-06-30/gh49-phase1-vendor.md)), then **independently verified by execution** (GUIDING #12): vendored into a scratch repo → 16 relay files + `bin/tick` + 12/12 `src/*.js` with subpaths intact, 3-field `VERSION` (tick_version 0.2.0), idempotent `.gitignore` + registry (3 runs → 1 row), `--no-register`/`-h` correct, manifest single-sourced from `make-pkg.sh`. (Phase 0 before: promote + decision record + ROADMAP In-progress.) | **Phase 2 — locator preference** in `find-harness.sh` (containment-critical; I author + swarm-review, every edit independently verified). |

## Table of Contents

- [Status](#status)
- [Background](#background)
- [Design decisions (locked)](#design-decisions-locked)
- [Phase 1 — the `vendor` command](#phase-1--the-vendor-command)
- [Phase 2 — locator preference chain](#phase-2--locator-preference-chain-containment-critical)
- [Phase 3 — staleness gate](#phase-3--staleness-gate-warn-loudly-continue)
- [Phase 4 — `xyz-sync` update/delete](#phase-4--xyz-sync-updatedelete)
- [Phase 5 — session-end reminder hook](#phase-5--session-end-reminder-hook)
- [Phase 6 — tests + dogfood acceptance](#phase-6--tests--dogfood-acceptance)
- [Dogfood plan (why GH-49 self-hosts)](#dogfood-plan-why-gh-49-self-hosts)

## Background

Driving a foreign repo today (`--target-root`) depends on a **live harness clone** — its
`relay-automation/*`, `bin/tick`, and the `relay-turn-lib.sh` containment kernel. That couples every
foreign-repo relay to the harness clone's current state, so the operator **holds off running relays**
when the harness is **mid-WIP** (uncommitted/half-edited scripts) or **unavailable** (another machine
/ not checked out). GH-49 adds an **opt-in vendored mode**: snapshot the curated harness script set
into a **git-ignored** `.xyz/` in the foreign repo, pinned to a known-good harness commit, so relays
run self-contained against a stable copy regardless of the harness clone's live state.

Reuses two things already shipped:

- **Packaging** — `skills/relay-automation/make-pkg.sh` + `test/skill-extract.sh` enumerate + bundle
  the curated **16-file** relay set into `relay-pkg.tar.gz`. The vendor command unpacks that pinned
  snapshot (plus `bin/tick` + `src/*.js`, which the *runtime* needs beyond the relay scripts) into
  `.xyz/`.
- **Registry** — GH-62's `~/.config/xyz/registry.tsv` (machine-local, `$HOME`, never committed). A
  vendored copy registers a row (marked as a vendored install) so `xyz-sync` can find/update/delete it.

## Design decisions (locked)

Two operator decisions (2026-06-30) shape the build:

1. **Staleness posture = warn loudly, continue.** When a vendored `.xyz/` is *provably behind a
   reachable* harness, the locator prints a prominent multi-line banner but **never blocks** the run.
   When no harness is reachable (the WIP/offline case GH-49 exists for), it runs from `.xyz/` silently.
   Rationale + tradeoff recorded in the decision doc. This favors the "run when the harness is
   unavailable" purpose over a hard containment stop (GUIDING #8 operator-decides; the copy is opt-in
   and explicitly labeled a fallback).
2. **Build = swarm-produced from the start.** Each code phase runs as a `relay-xyz` round under the
   harness's own containment (allowlist + worktree isolation + no-push) — a dogfood of the containment.
   **Guardrail:** the containment-critical file (`find-harness.sh`, Phase 2/3) has every swarm-authored
   edit independently verified before it lands (GUIDING #12).

## Phase 1 — the `vendor` command

**Shipped as `relay-automation/xyz-vendor.sh` (codex-produced, agy-approved, execution-verified).**

- [x] Add an opt-in `vendor` entry point — `relay-automation/xyz-vendor.sh <target-repo> [--no-register]
      [-h]` — that materializes into `<repo>/.xyz/`: the 16-file relay set (list parsed from
      `make-pkg.sh`'s `tar` args — **single source of truth**, not re-listed) + `bin/tick` + `src/*.js`.
- [x] Write `<repo>/.xyz/VERSION` stamping: `source_commit` (harness HEAD SHA), `tick_version`
      (`SCHEMA_VERSION` from `src/events.js`), `vendored_utc`.
- [x] Add `.xyz/` to the foreign repo's `.gitignore` (idempotent via `grep -Fqx`; creates it if absent).
- [x] Register the install in the GH-62 registry (`~/.config/xyz/registry.tsv`), keyed on the `.xyz/`
      path, `coordinated_repo=<target>` marking it vendored — atomic tmp+mv, dedup latest-wins,
      **fail-open** (a registry failure prints a note and returns 0). `--no-register` opts out.
- [x] `-h` usage; bash 3.2-safe; `set -euo pipefail`; symlink-safe self-location.

### QA checklist — Phase 1

- [x] `vendor <scratch-repo>` writes a complete `.xyz/` — verified: 16 relay files (10 relay-automation
      + 6 test) + `bin/tick` (exec) + **12/12** `src/*.js` with subpaths intact + a 3-field `VERSION`.
- [x] Re-running updates in place — verified: 3 runs → 1 `.gitignore` line, 1 registry row.
- [x] The snapshot's manifest is derived from `make-pkg.sh` (awk-parsed), not a second hardcoded list.
- [x] `--no-register` writes no registry; `-h` prints usage (both smoke-verified).

## Phase 2 — locator preference chain (containment-critical)

- [ ] Extend `find-harness.sh` resolution order to: **env override → local `.xyz/` (vendored) →
      current git-repo harness → script-relative**. The vendored copy wins when present in the repo you
      are standing in, so a foreign repo with `.xyz/` resolves to its own snapshot.
- [ ] The default path (no `.xyz/`) must stay **byte-for-byte unchanged** — the vendored branch is only
      taken when `<cwd-repo>/.xyz/relay-automation/relay-drive.sh` exists.
- [ ] `_has_harness` must accept a `.xyz/`-rooted layout (relay scripts + `bin/tick` present).

### QA checklist — Phase 2

- [ ] Foreign repo with `.xyz/` present → locator resolves to `.xyz/`.
- [ ] No `.xyz/` → resolution identical to today (regression-proven).
- [ ] `XYZ_HARNESS` override still wins over a present `.xyz/`.

## Phase 3 — staleness gate (warn loudly, continue)

- [ ] When resolved to `.xyz/` **and** a live harness is reachable (env/git/script-relative), compare
      `.xyz/VERSION`'s source commit to the reachable harness; if the snapshot is behind, print a loud
      multi-line staleness banner to stderr (name the vendored SHA, the live SHA, and the
      `xyz-sync --update` remedy).
- [ ] **Never block** — the relay proceeds from `.xyz/` regardless (locked decision #1).
- [ ] No reachable harness → no banner (can't compare; expected WIP/offline case).
- [ ] Surface the same signal in `find-harness.sh --check`.

### QA checklist — Phase 3

- [ ] `.xyz/` behind a reachable harness → banner fires, run still proceeds.
- [ ] `.xyz/` current with the harness → no banner.
- [ ] `.xyz/` present, no harness reachable → no banner, resolves to `.xyz/`.

## Phase 4 — `xyz-sync` update/delete

- [ ] `xyz-sync` reads the registry and, for a chosen (or all) vendored copy: **update** =
      re-materialize the snapshot from the current harness (Phase 1 path) + restamp `VERSION`.
- [ ] **delete** = remove `<repo>/.xyz/` + drop its registry row (atomic tmp+mv, matching GH-62).
- [ ] Also closes the GH-62 follow-on ("an `xyz-sync` push tool that re-materializes stale copies").
- [ ] Dry-run/confirm before deleting (never delete without an explicit act; GUIDING #8).

### QA checklist — Phase 4

- [ ] `xyz-sync --update <dir>` refreshes a stale `.xyz/` and clears the staleness banner.
- [ ] `xyz-sync --delete <dir>` removes `.xyz/` + the registry row; re-run is a clean no-op.
- [ ] A missing/moved dir is handled fail-open (prune the stale row, don't crash).

## Phase 5 — session-end reminder hook

- [ ] A Stop/SessionEnd hook that, when `.xyz/` copies exist (per the registry), emits a
      **non-blocking** reminder: "vendored `.xyz/` copies exist — `xyz-sync --delete <dir>` to remove."
- [ ] **Cannot** auto-delete and **cannot** truly block for an interactive yes/no — a hook can only
      emit a notice (GUIDING #8). The reminder is honest about that; the registry is what makes
      later update/delete possible.
- [ ] Opt-out env so a long-lived intentional vendored copy doesn't nag every session.

### QA checklist — Phase 5

- [ ] With a vendored copy registered → the notice prints at session end.
- [ ] With none → silent.
- [ ] The hook never blocks or deletes.

## Phase 6 — tests + dogfood acceptance

- [ ] Unit: a `test/xyz-vendor.sh` (vendor into scratch → assert complete `.xyz/`, locator prefers it,
      staleness banner fires when behind, `xyz-sync --delete` cleans up).
- [ ] `./validate.sh` green (new test wired in); `utils/pdda/pdda.sh run` clean.
- [ ] **Dogfood (Level 2):** vendor into a scratch foreign repo, hide the live harness clone, drive a
      real `relay-xyz` review turn that resolves *only* from `.xyz/` — proving the harness self-hosts
      from its own snapshot.

## Dogfood plan (why GH-49 self-hosts)

GH-49's deliverable *is* the harness, so dogfooding is the acceptance test, not a bolt-on:

- **Level 1 — build through the swarm.** Each code phase is produced/reviewed via `relay-xyz`
  (Producer + agy/codex reviewer, headless) under containment — QAs the diff and dogfoods the review loop.
- **Level 2 — the deliverable dogfoods itself (marquee).** `vendor` into a scratch repo → hide the live
  harness → run `relay-xyz` resolving only from `.xyz/`. If the swarm completes a turn from the vendored
  copy with no live harness on PATH, GH-49 works. Self-hosting.
- **Level 3 — the original trigger.** Vendor into **rebalance-OS** (the marathon-queue repo that
  surfaced this) and run the marathon there against the pinned `.xyz/` while xyz-3-agents-swarm is
  mid-edit — the exact WIP scenario GH-49 was filed for.

## Provenance

Filed 2026-06-29: the operator holds off relays on WIP repos because they couple to a live,
possibly-mid-edit harness clone. Relates to GH-11 (`--target-root`), the relay-xyz durability/locator
work, the `relay-pkg`/`skill-extract` packaging, GH-62 (the registry this reuses), and GH-30 (archive).
Promoted to 2-WORKING 2026-06-30 with the two locked decisions above.
