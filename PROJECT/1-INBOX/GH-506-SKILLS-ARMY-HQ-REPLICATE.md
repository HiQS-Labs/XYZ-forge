---
gh_issue: 506
source: https://github.com/HiQS-Labs/XYZ-forge/issues/506
title: "skills-army-hq: replicate a collection to a second device, migrate-from name mismatch, and status exit-code semantics"
status: Proposed (1-INBOX — not yet active)
created: 2026-09-08
owner: unassigned
doc_type: feedback
complexity: 2
risk: 1
effort: 3
phases: 1
ratings_provisional: true
non_goals:
  - Remote downloads; installing skill runtime dependencies; Windows locking.
related:
  - GH-484
goal: >
  TODO: one-paragraph statement of what "done" looks like for this idea.
---

## Key concepts

- collection replication, migrate-from name mismatch, exit-code semantics

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# skills-army-hq: replicate a collection to a second device, migrate-from name mismatch, and status exit-code semantics

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

Feedback from a real second-device install of Skills Army HQ (source: the Mac Studio's Documents/Deployed Skills over SMB, 15 skills, 5 targets).

1. No replicate/clone path between collections. Recreating the collection on a second Mac required hand-reading .deploy-skills.json for the skill list and source paths, mapping the remote source paths to local repo checkouts (different folder names: 'GH Repos' vs 'GitHub-Repos'), re-typing all 8 prerequisite strings, and re-entering all 5 targets. Proposal: 'intake.py init --from /path/to/other-collection' (or 'export' + 'import') that copies targets.json (re-homed to the local user), prerequisites, and a source manifest, then reports which sources resolve locally and which need '--source' overrides.

2. '--migrate-from SKILL=LOCAL_SOURCE' refuses when the source folder name differs from the skill name ('Folder/name mismatch: ponytail-refined != ponytail'). The foreign link at ~/.claude/skills/ponytail pointed to giant-brains-claude-skills/04-build/ponytail-refined; the only way through was a manual rm + ln -s followed by '--adopt ponytail', i.e. the documented recovery exception. Migration should key on the link's basename (the deployed skill name), not the source folder's basename.

3. Exit code 2 and the 'errors' array conflate real failures with 'Foreign link preserved; review before explicit migration'. A clean sync with foreign links present exits 2, so scripted callers cannot distinguish 'needs review' from 'broken'. Proposal: report preserved foreign links under a separate 'warnings' key (or exit 1) and reserve exit 2 / 'errors' for validation failures and conflicts.

4. Minor: when a sync is interrupted mid-transaction (here: a sandbox denied writes under ~/.claude/skills after ~/.agents/skills succeeded), 'sync.py --status' prints a plain-text one-liner ('Interrupted operation: run intake.py recover --apply') instead of JSON, which breaks JSON consumers of --status. Emit the same message as a JSON error object.

Verification: after applying 1-3, replicating a collection should be: init --from <share>, review the resolved-sources report, sync --apply, and a --status that exits 0 with foreign links listed as warnings.

## Why

Replicating an existing HQ collection onto a second Mac from a real deployment (SMB share) took ~15 manual steps that the manager could own.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
