---
title: Consolidate release workflows into one releases router skill
status: Active
created: 2026-08-14
updated: 2026-08-14
owner: Noel Saw
goal: Replace the split release and release-plan entry points with one repo-owned Claude Code releases skill that reads, diagnoses, cleans, authors, and publishes through explicit routed subroutines.
effort: 2
complexity: 2
risk: 2
phases: 2
context_tags: [skills, releases, pdda, claude-code]
issue_pending: GitHub DNS unavailable; operator explicitly authorized local work before issue creation.
roadmap_exempt: true
---

# Releases skill consolidation

## Status

| What was just completed | What's next |
|---|---|
| **Built and focused-verified.** `skills/releases/` is the single read-first router; the installer migrated Claude Code to the plural symlink and retired both aliases; focused suite 26/26 plus skill and targeted PDDA checks are green. | Run the full repository gates and reconcile the deferred GitHub issue/name once DNS returns. |

## Table of contents

- [Phase 1 — Consolidate the skill](#phase-1--consolidate-the-skill)
- [Phase 2 — Reconcile governance and verify](#phase-2--reconcile-governance-and-verify)
- [Acceptance criteria](#acceptance-criteria)

## Decision

`skills/releases/` is the single source for Claude Code. Its default invocation is read-only and
synthesizes `RELEASES.md`; explicit routes handle cleanup, disciplined authoring, and GitHub
publication. It conditionally recommends `/radar` for strategic recalibration and `/finish-line`
for a frozen path to a selected checkpoint, without copying either workflow.

The consolidation must not create or edit a Codex skill. The Claude installer owns migration from
the legacy `release` and `release-plan` symlinks.

## Phase 1 — Consolidate the skill

- Rename `skills/release/` to `skills/releases/` and change its frontmatter name and invocation.
- Replace the publisher-only body with a read-first router covering inspect, clean, plan/update,
  publish, Radar handoff, and Finish Line handoff.
- Preserve strict evidence rules: merged PRs and reachable commits count; closed-only PRs and
  pushes do not prove shipment.
- Keep every mutation previewed and confirmation-gated.
- Migrate Claude Code's legacy symlinks without touching Codex paths.

### Phase 1 QA gate

- The skill validator accepts `skills/releases/`.
- A hermetic installer test proves one `releases` symlink remains and legacy aliases are removed.
- The skill text contains the required routes and guardrails without duplicating Radar or Finish
  Line internals.

## Phase 2 — Reconcile governance and verify

- Update `ROUTER.md` and the `PROJECT/PDDA.md` release-ledger contract to name the consolidated
  skill and its boundaries.
- Add focused validation coverage and register it in the repository gate if appropriate.
- Install the repo-owned skill into Claude Code and confirm the symlink target.
- Create the GitHub issue when DNS returns, rename this document to its `GH-<number>` form, add
  `gh_issue` and `source`, and update the roadmap pointer.

### Phase 2 QA gate

- Focused skill and installer tests pass.
- `utils/pdda/pdda.sh run` reports no new findings from this change.
- `./validate.sh` passes, or any failure is reported with exact attribution.

## Acceptance criteria

- A user can invoke `/releases` without remembering a second release skill.
- The initial response synthesizes the current ledger and makes no writes.
- Staleness findings are evidence-backed and distinguish plan drift from valid optionality.
- Description and manifest ambition warnings are advisory and explain their evidence.
- Cleanup and authoring touch only confirmed blocks and preserve concurrent edits.
- Publication remains previewed, explicitly confirmed, and writes `GH_URL` plus `Status: Shipped`
  only after GitHub succeeds.
- Radar and Finish Line are recommended only when their distinct goal matches the observed state.
- No Codex skill or Codex install path is created or modified.
