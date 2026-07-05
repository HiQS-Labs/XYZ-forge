---
gh_issue: 128
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/128
title: "HQ — multi-repo command-center skill: one utterance → registry-resolved repo → PDDA-compliant intake → marathon queue/dispatch"
status: Proposed (1-INBOX — not yet active)
created: 2026-07-04
owner: noel
doc_type: project
effort: 3
complexity: 3
risk: 2
phases: 4
related:
  - PROJECT/PDDA.md
  - PROJECT/3-COMPLETED/GH-96-XYZ-REBALANCE-SYNC-CHECK.md
  - PROJECT/3-COMPLETED/GH-62-XYZ-INSTALL-REGISTRY.md
  - PROJECT/2-WORKING/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md
  - utils/marathon-plan.sh
  - relay-automation/xyz-sync.sh
---

# HQ — multi-repo command-center skill (capture)

Capture of issue #128. The live issue is the discussion surface; this doc is the in-repo
back-reference and the seed of the eventual `2-WORKING` plan.

## The ask

From a Claude Code session in this repo, the operator says **"For project Acme, do this and do
that"** and HQ:

1. resolves *Acme* to a real repo on this device,
2. reads that repo's governance state (PDDA mode, startup docs, roadmap, open marathon plans),
3. lands the request on **that repo's own PDDA rails** — GitHub issue → `PROJECT/1-INBOX/GH-<n>-*.md`
   capture → `ROADMAP.md` parking — and,
4. only on an explicit verb, dispatches: appends a rated lane to the target's Marathon Plan queue
   (`queue`) or fires a driven lane (`fire`) via the existing
   `swarm-preflight --target-root → marathon-drive` path.

HQ is the routing layer between "what I said" and "which repo's contract executes it." Every
downstream mechanism already ships in this repo; the front door is the missing piece.

## Resolution ladder (the metadata HQ reads)

- **Git Pulse PDDA registry** — the Git Pulse sync repo (checked out at `~/git-pulse-sync`,
  symlinked from the rebalance-OS repo) carries `pdda/registry-<device>.tsv` with schema
  `repo · last_install_utc · mode · source_commit · startup_docs`. This is the per-device index of
  which repos are on PDDA rails, and HQ's primary name→repo resolver. It deliberately omits
  absolute paths and documents its own find-by-name recipe in its header comment.
- **XYZ install registry** (GH-62; `registry.tsv`:
  `install_dir · last_install_utc · tick_version · source_commit · coordinated_repo`) — which repos
  can *run* driven lanes; `relay-automation/xyz-sync.sh check` (GH-96 Seam #2) reports harness drift.
- **Rebalance registry** — the rebalance-OS live DB (`rebalance.db`, repos table) supplies aliases
  and priority/attention metadata. Read-only in that direction, mirroring the #96 / rebalance-OS#102
  seam discipline: HQ never writes Rebalance state; the pulse collector observes the resulting
  issues/commits on its own.
- Fuzzy match → operator confirmation as the last rung.

## Capability tiers (what HQ may do per repo)

- **Tier A** — PDDA + vendored XYZ: full flow, dispatch allowed.
- **Tier B** — PDDA only: issue + capture doc + roadmap parking; no dispatch.
- **Tier C** — bare repo: plain GH issue; offer a PDDA install as the remedy, never a partial doc
  structure.

## Safety rails (inherited, not invented)

- `park` (intake only) is the default intent; `queue`/`fire` require the explicit verb.
- PDDA triage `risk` is a gate, not an addend: `risk >= 3` never auto-fires.
- Cross-repo writes only through the containment-correct `--target-root` path (GH-51 fix).
- `fire` refuses on Tier B/C repos and when `xyz-sync check` reports drift.
- Queue-commitment contract (GH-45) applies to anything HQ appends to a marathon plan.

## Proposed phases

- **Phase 0 — Discovery/spike:** enumerate the three registries' live schemas + device coverage;
  decide canonical resolution order + alias strategy; findings written back (PDDA discovery
  contract).
- **Phase 1 — `hq status` / `hq resolve` (read-only):** skill + resolver printing a project card
  (repo path, PDDA mode, startup docs, active docs, open marathon plan, harness drift). No writes;
  independently useful.
- **Phase 2 — Intake writer:** issue + 1-INBOX capture + ROADMAP parking in the *target* repo,
  honoring the target's PDDA contract, with a dup-guard against its existing queue.
- **Phase 3 — Dispatch:** `queue` and `fire`, park-by-default preserved.
- **Phase 4 (deferred):** promote the skill user-level (any repo's session) + use Rebalance
  priority to *suggest* which parked HQ intake to promote next.

## Acceptance criteria (from the issue)

- `/hq status <project>` resolves ≥3 real repos by name through the ladder and prints an accurate
  project card.
- `/hq <project> <request>` (default `park`) produces in the target repo: a GH issue, a correctly
  named capture doc passing the target's `pdda.sh frontmatter`, and a `ROADMAP.md` queue pointer
  passing `roadmap-coverage`.
- `queue` appends a lane without violating the plan's collision map.
- `fire` refuses on `risk >= 3`, Tier B/C, or harness drift.
- Tier C yields a plain issue + suggested PDDA-install command.
