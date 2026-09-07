---
title: Deploy Skills — Recon Map
status: In progress
created: 2026-09-07
updated: 2026-09-07
owner: Codex
goal: Bound the existing skill installation and copied-skill runtime seams.
roadmap_exempt: true
---

# Recon Map — deploy-skills

## Status

| What was just completed | What's next |
|---|---|
| Read-only installation and payload dependency trace | Agy review of the parent plan |

Commit: `2e4f8d48831b2265a29eeaca8ce93a61bc39e386` (fresh origin/development clone).
Mode: graph leads plus direct source; Verify tier; lanes A/C and B/D in two read-only agents, governance/intake in parent.

## Subject and authority

New local deployment collection and its existing app/skill consumers. Source-of-truth class, explicitly requested by the operator: copied folders determine desired global skills. Original repositories remain authoring sources; catalog is a read projection, changelog is audit-only. No replacement of XYZ's runtime, RELEASES, or app configuration authority.

## Seams

| Seam | Location | Crosses | Breaks if |
|---|---|---|---|
| Existing installers | `skills/relay-xyz/install.sh:31`, `skills/consult/install.sh:18` | Source folders to app discovery paths | Imported installer replaces an unrelated symlink or moves a real folder |
| Harness locator | `skills/relay-xyz/find-harness.sh:94`, `:122`, `:169` | Skill physical location to runtime repo | A copied skill relies on its former grandparent directory |
| Consult runtime | `skills/consult/SKILL.md:45` | Caller repo or vendored harness | User treats copied instructions as a bundled harness |
| Scaffold tool | `skills/skills-sync-trinity/SKILL.md:29`, `scripts/sync_trinity.py:102` | Repo docs and helper generation | Scaffolding is mistaken for global deployment management |
| Existing inventory | `skills/skills-sync-trinity/scripts/export_skills_sync_trinity.py:13`, `:48`, `:99`, `:244` | App folder snapshots | Historical defaults count as verified support; recursive link traversal cycles |
| Cleanup | `skills/merge-cleanup/scripts/merge_cleanup.py:192` | Dangling global links | A desired link is removed externally and sync cannot recreate it |
| Start-task instructions | `skills/start-task/SKILL.md:224` | Global links to maintained primary clone | Its installation advice conflicts with the new approved copy-based option |
| Gate discovery | `validate.sh:1195`, `:1268`, `:1340` | Bash suite registry plus named Python suite | A new Python test is assumed to run automatically |

## Call paths and state today

User/agent -> per-skill install.sh -> install_one -> mkdir / unlink old symlink or move collision / create directory symlink. Inspected installers have no managed-link ledger. They are not called by generic intake. `skills-sync-trinity` -> repo scaffold and optional inventory export; it explicitly excludes this requested external sync role. Root install.sh installs tick runtime (`install.sh:4–30`), so extending it would couple unrelated deployment concerns.

App discovery reads SKILL.md through links. Payload instructions invoke sibling resources or repository runtime tools. The standalone merge-cleanup Python bundle uses sibling imports (`scripts/merge_cleanup.py:21–33`) but intentionally resolves reconciliation tools in the operated-on repo (`:73–96`). The locator's existing explicit environment overrides and caller/.xyz resolution survive copying; its self-relative fallback does not. No new global-runtime resolver is needed for the proposed alpha.

External writers include users, per-skill installers, and merge-cleanup's dangling-link pruning. The new sync must tolerate removed links and preserve entries retargeted by those writers. Runtime state will be separate from committed distribution files.

## Alpha source inventory

XYZ Forge `skills/`: relay-xyz, consult, marathon-triage, marathon-cleanup, swe, ponytail, recon, workhorse, merge-cleanup, start-task, debug-mantra. Include the new deploy-skills itself. The marathon interpretation is the two existing marathon-named skill folders; harness scripts are prerequisites, not additional skill folders.

`unstuck`: sibling task clone's `skills/unstuck/`, clean at observation; skill commit `ca8645c`; tracked by [PR #479](https://github.com/HiQS-Labs/XYZ-forge/pull/479). Revalidate local availability, dirty state and imported SHA at alpha time; do not merge that PR to satisfy this feature.

`daily`: rebalanceOS `.agents/skills/daily/` (the installed Codex daily link confirms that source). Its SKILL.md:18–28,37–51 and scripts/scan_unclosed_loops.py:23–37,270 contain personal paths and Rebalance runtime dependencies. These are private alpha inputs, never committed payloads of deploy-skills. Generic intake cannot make an arbitrary skill device-agnostic by copying it.

## Failure and rollback today

Existing consult installer aggregates failures across targets (`install.sh:45–53`), but replacement policy is too broad for managed sync. Existing cleanup tests (`test/gh436-merge-cleanup.py:173–212`) cover dangling links, healthy links and refusing a symlinked root. Reuse those scenarios, not the broad pruning function. Per-skill source-relative documentation and untracked runtime state do not provide a transaction or catalog recovery mechanism today.

## Probe ledger and evidence limits

2026-09-07: origin is HiQS-Labs/XYZ-forge; no deploy-skills-title issue found before opening #484. Open PRs included #479 and #483. Graph `XYZ-forge` reported generation 2026-09-01T15:54:30Z; metadata changed/missing for locator/start-task; skills-sync-trinity/scripts excluded. Search `skill symlink install` returned 20 of 40 broad BM25 hits; narrowed reads above are bounded evidence, not an exhaustive absence claim. Coverage checked candidate installer, locator and scaffold paths; source fallback used for stale/excluded material. Source claims from agents are live direct reads. Fresh clone base pinned above; re-read affected paths if implementation base changes.

## Unknowns

| Unknown | Why it matters | Settlement |
|---|---|---|
| Current app discovery and symlink support | Filesystem placement cannot prove app recognition | Official current docs/local app help plus discovery smoke test per consumer in Phase 3 |
| Optional transitive skill references | Imported workflow may require unselected skills | Read each alpha SKILL.md/resources; show missing requirements without auto-import |
| Unstuck at implementation time | PR/source may move | Resolve existing on-disk folder and read Git status/HEAD again |
| Documents redirection and symlink privileges on other OSes | Portable paths do not prove platform behavior | Overrideable root; test alternate homes; report unsupported symlink capability explicitly |

## Current-state radius

Existing global discovery directories, selected skill instructions and their XYZ/rebalanceOS runtimes, per-skill installers, and merge-cleanup's dangling-link pruning. This plan adds a private copied collection, two Python command entry points, local metadata/history/backups, and owned app links; it does not modify the coordination kernel.
