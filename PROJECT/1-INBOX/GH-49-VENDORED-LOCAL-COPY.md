---
gh_issue: 49
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/49
title: Optional vendored local copy of harness scripts (WIP-decoupled fallback for foreign repos)
status: Proposed (1-INBOX — not yet active)
created: 2026-06-29
doc_type: feedback
---

> **Inbox capture.** Per PDDA, a `1-INBOX/GH-*.md` doc carries no `## Status` table while it sits
> here; it is the capture, not the active-work doc. Promote to `2-WORKING/` (keeping the `GH-49`
> prefix + adding the exact status table) when execution starts.

## Problem

Driving a foreign repo today (`--target-root`) depends on a **live harness clone** — its
`relay-automation/*`, `bin/tick`, and the `relay-turn-lib.sh` containment kernel. That couples every
foreign-repo relay to the harness clone's current state, so the operator **holds off running relays**
when the harness is **mid-WIP** (uncommitted/half-edited scripts — e.g. an active dev session) or
**unavailable** (another machine / not checked out).

## Proposed mode (opt-in, additive)

A **local fallback / vendored mode**: snapshot the curated harness script set into a **git-ignored**
folder in the foreign repo (e.g. `.xyz/`), pinned to a known-good harness commit, so relays run
self-contained against a stable copy regardless of the harness clone's live state.

- **Reuse existing packaging:** `skill-extract.sh` + `make-pkg.sh` already enumerate + bundle the
  curated file set into `relay-pkg.tar.gz` (16 files). A `vendor`/`sync` command unpacks that pinned
  snapshot into `.xyz/`.
- **Locator preference chain:** env override → local `.xyz/` (vendored) → installed symlink →
  discovered harness clone. The vendored copy wins when present.
- **Version stamp:** record the harness commit the snapshot came from, so staleness is visible.
- **.gitignore** the vendored dir; default OFF (no behavior change when unused).

## Effort & risk

- **Effort: Medium.** Packaging + locator chain mostly exist; new = the vendor/sync command, locator
  preference, version stamp, gitignore, tests.
- **Risk: Medium — staleness/governance, not blast radius.** A vendored copy **forks the containment
  kernel** (`relay-turn-lib.sh`), whose safety rests on a single source of truth. A foreign repo could
  run an **old, buggy kernel** (e.g. the 2026-06-29 #14 fix) after the harness fixed it. Mitigate:
  version-stamp + warn/refuse when the snapshot is behind a reachable harness + label it a fallback.
- **Reversibility: Easy** — additive, opt-in, git-ignored, deletable.

## Acceptance (when worked)

- An opt-in `vendor` command writes a pinned, git-ignored snapshot into a foreign repo; relays run
  from it with no live harness clone present.
- The locator prefers the vendored copy; default (no `.xyz/`) behavior is byte-for-byte unchanged.
- A staleness signal fires when the vendored snapshot is behind a reachable harness.

## Provenance

Filed 2026-06-29: the operator holds off relays on WIP repos because they couple to a live,
possibly-mid-edit harness clone. Relates to GH-11 (`--target-root`), the relay-xyz durability/locator
work, the `relay-pkg`/`skill-extract` packaging, and GH-30 (archive). Parked in the ROADMAP queue
(not in progress).
