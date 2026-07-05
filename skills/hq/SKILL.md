---
name: hq
description: HQ — the multi-repo command center. Turn a single utterance ("For project Acme, do X") into governance-aware action across every repo on this device. Resolves a project name to a real repo via the registry ladder (Rebalance project_registry → XYZ install registry → Git Pulse PDDA registry → filesystem), reports its governance state as a project card, and — in later phases — lands the request on that repo's own PDDA rails (issue → 1-INBOX capture → ROADMAP parking) with explicit-verb-only dispatch. Trigger when the user says "/hq", "HQ status of <project>", "which repo is <project>", "for project X do Y", "resolve <project>", or asks for a cross-repo project card / capability tier. Phase 1 (this build) is READ-ONLY: resolve + status + registries. Tracks GH-128.
---

# /hq — multi-repo command center (Phase 1: read-only)

HQ is the front door for one-utterance, multi-repo tasking. This phase answers the first question
every such request needs: **which repo is this, and what shape is it in?** Writing intake and firing
lanes are Phase 2/3 and are intentionally not wired yet.

## What it does now

The skill drives `utils/hq/hq.sh` (read-only; no writes, no network beyond local `gh`-free lookups):

- `hq.sh status <project|repo>` — the **project card**: resolved repo + path, capability tier
  (A/B/C), Rebalance priority, PDDA mode + startup docs, active-doc count, open marathon plan, and
  XYZ install/drift stamps.
- `hq.sh resolve <project|repo>` — the same resolution as machine-readable `KEY=value` lines, for
  scripting.
- `hq.sh registries` — Phase-0 introspection: what each registry knows and its coverage.

## When the user invokes /hq

1. If they gave a project/repo name, run:
   ```bash
   bash utils/hq/hq.sh status "<name>"
   ```
   Relay the card. If it resolves **UNRESOLVED**, show the candidates/find-recipe the tool prints and
   ask the user to confirm the repo name or clone location — do not guess a path.
2. If they asked "what can HQ see" / "list projects", run `hq.sh registries`.
3. If they used a **write verb** ("park this", "queue it", "fire a lane"), explain those are Phase 2/3
   (issue-first intake + dispatch) — not built yet — and that the plan of record is
   [PROJECT/2-WORKING/GH-128-HQ-COMMAND-CENTER.md](../../PROJECT/2-WORKING/GH-128-HQ-COMMAND-CENTER.md).
   Offer to run `status` so the groundwork is visible.

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
