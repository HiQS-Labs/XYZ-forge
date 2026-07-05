---
name: hq
description: HQ — the multi-repo command center. Turn a single utterance ("For project Acme, do X") into governance-aware action across every repo on this device. Resolves a project name (fuzzily) to a real repo via the registry ladder (Rebalance project_registry → XYZ install registry → Git Pulse PDDA registry → filesystem), reports its governance state as a project card, lands the request on that repo's own PDDA rails (issue → 1-INBOX capture → ROADMAP parking), and prepares dispatch (queue a lane / gated fire). Trigger when the user says "/hq", "HQ status of <project>", "which repo is <project>", "for project X do Y", "resolve <project>", "park/queue/fire this for <project>", or asks for a cross-repo project card / capability tier. Read paths are safe; write paths (park/queue) PREVIEW by default and act only with --create; fire never drives the harness itself. Tracks GH-128.
---

# /hq — multi-repo command center

HQ is the front door for one-utterance, multi-repo tasking: resolve a project name to a real repo,
report its governance state, land the request on that repo's own PDDA rails, and prepare dispatch.
**Read paths are safe; every write path previews by default.**

## What it does now

The skill drives `utils/hq/hq.sh`:

- `hq.sh status <project|repo>` — the **project card**: resolved repo + path (with a fuzzy-match note
  if the name was loose), capability tier (A/B/C), Rebalance priority, PDDA mode + startup docs,
  active-doc count, open marathon plan, XYZ install/drift stamps.
- `hq.sh resolve <project|repo>` — machine-readable `KEY=value` resolution (adds `RESOLVED_VIA`
  exact|fuzzy; ambiguous names return rc=2 with `CANDIDATES`).
- `hq.sh registries` — introspection: what each registry knows and its coverage.
- `hq.sh park [--create] [--title T] <project> <request…>` — **issue-first intake** in the target
  repo (GH issue → `1-INBOX` capture → ROADMAP parking → target `pdda.sh`). Previews unless `--create`.
- `hq.sh queue [--create] [--gh-issue N] <project> <request…>` — append an **HQ-queued lane** to the
  target's newest Marathon Plan (non-destructive appendix). Previews unless `--create`.
- `hq.sh fire --gh-issue N [--risk 1-5] <project>` — **gated prepare-and-hand-off**: resolve + gate
  (Tier A, `risk < 3`) + emit the `swarm-preflight` command. HQ never drives the harness itself — the
  operator runs it and drives via the relay-xyz skill (GUIDING-PRINCIPLES §8).

## When the user invokes /hq

1. Name given → `bash utils/hq/hq.sh status "<name>"`; relay the card. On **UNRESOLVED**, show the
   find-recipe and ask; on **AMBIGUOUS**, show the candidates and ask which — never guess a path.
2. "For project X, do Y" → `hq.sh park "<X>" "<Y>"` (preview), show the exact issue/doc/roadmap, then
   `--create` on the operator's go (creating a GH issue is outward-facing — confirm first).
3. "queue it" / "fire it" → the corresponding verb. `fire` stops at the gated hand-off: relay the
   emitted command and hand to the relay-xyz skill; do not auto-drive a marathon.
4. "what can HQ see" / "list projects" → `hq.sh registries`.

## Resolution ladder (how a name becomes a repo)

1. **Rebalance `project_registry`** (`rebalance-OS/rebalance.db`) — the semantic catalog: human project
   NAME (`owner/repo`) → repo list + `priority_tier`/`value_level`. No local path.
2. **XYZ install registry** (`~/.config/xyz/registry.tsv`) — repo → **absolute path** + runnable/drift
   stamps. The path resolver; only covers XYZ-installed repos.
3. **Git Pulse PDDA registry** (`~/git-pulse-sync/pdda/registry-<device>.tsv`) — repo → PDDA `mode` +
   `startup_docs`, across all devices. No path.
4. **Filesystem `find`** — fallback when no registry knows the path.

Override any source for tests / non-default installs via `HQ_PDDA_REGISTRY_DIR`, `HQ_XYZ_REGISTRY`,
`HQ_REBALANCE_DB`, `HQ_SEARCH_ROOTS` (see `utils/hq/hq-lib.sh`).

## Capability tiers

- **Tier A** — PDDA + XYZ install → dispatch-eligible (Phase 3).
- **Tier B** — PDDA only → intake only, no dispatch.
- **Tier C** — bare repo → plain issue only; offer a PDDA install.

## Guardrails (inherited from GH-128)

- Read-only in this phase. Rebalance is always read-only (mirrors the #96 seam discipline).
- Never fabricate a repo path — an UNRESOLVED result is a question for the operator, not a guess.
- Later dispatch will be park-by-default with a hard `risk >= 3` gate; do not simulate it now.
