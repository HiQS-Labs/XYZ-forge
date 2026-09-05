---
title: Start-task governed workflow skill
gh_issue: 439
source: https://github.com/HiQS-Labs/XYZ-forge/issues/439
status: active
created: 2026-09-04
updated: 2026-09-04
owner: Codex
goal: Carry one or more issues from grounded intake to reviewed PRs using existing workflows.
doc_type: project
effort: 2
complexity: 2
risk: 2
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Recon and intake recorded | Codex plan QA, then author the skill |

## Scope

Create skills/start-task/SKILL.md and register it in the Skills Index. Deploy global symlinks for Codex, Claude Code, Agy and ZCode. No runtime changes, new executor, parallel ledger, automatic merges or cleanup.

## Recon

The operator's prompt history repeatedly requests clone → issue/PDDA/RELEASES → execution → relay QA → PR, including multi-issue tasks. skills/workhorse/SKILL.md owns diagnosis/design/consult, while skills/merge-cleanup/SKILL.md owns landing and teardown. skills/relay-xyz/SKILL.md owns reviewer containment and the driver; SOP.md §4 owns fresh full clones and development PRs; PROJECT/PDDA.md owns tracking. Existing global workhorse links target the primary repo's skills directory. ZCode's installed configuration guide identifies ~/.zcode/skills and ~/.agents/skills as user locations (local installation evidence only, no portable path assumption).

This is a documentation workflow: no runtime codepaths change. The affected path is skill discovery → instructions → existing governance CLI and relay driver. The new skill must direct all writes through those existing paths.

## Design bet

Easy to reverse: additive skill and removable symlinks. A thin coordinating skill should eliminate repeated prompting without duplicating execution machinery. Failure would be inventing new commands or closing governance before merge. Alternatives: expand workhorse (conflates diagnosis and lifecycle), extend merge-cleanup (conflates startup and teardown), or add an executor (unnecessary code). Keep one small skill.

## Plan

1. Review this plan through Codex relay; adjudicate findings before authoring the skill.
2. Write a portable skill with per-issue dependency/status mapping, surgical recon-grounded planning, mandatory plan QA beyond simple edits, bounded final QA and ready PR boundary. Honor explicit debug-mantra and ponytail tags, and user reviewer overrides. Route complex diagnosis to workhorse without forcing its full ladder on routine work.
3. Validate frontmatter and local doc governance; inspect scenarios for independent issues, dependent issues, unavailable reviewer, failed tests and an existing PR. Failure controls: missing reviewer or failing gate cannot produce a ready claim; unresolved dependency cannot execute; already tracked issue cannot create duplicate intake. Record concrete review results here.
4. Commit the final skill, run Codex implementation relay QA and resolve blockers, then open the development PR. Copy only the reviewed new skill into the primary skills folder and create non-overwriting global symlinks; verify exact resolution and content. Preserve the task clone while the PR is unmerged.

## Acceptance

The skill exists in the repository and all requested global skill directories resolve to it. It requires both plan QA for non-simple work and final QA, preserves a per-issue outcome, uses repo governance, and does not claim merge/closure at PR creation. Existing deterministic validator rejects malformed frontmatter; validate a disposable malformed fixture before trusting the positive. Symlink verification must reject a missing/wrong target, with no overwrites of existing installs.
