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
| Agy approved rating policy; canonical score persisted; global links refreshed | Update PR #440; await merge |

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

## Verification and deployment

Final Codex relay returned Approved / PASS, driver exit 0, textual-only basis against the committed skill. Targeted PDDA checks passed; RELEASES reported zero failures and eight existing migration warnings. Malformed-frontmatter and wrong/missing-link negative controls were rejected. All six discovery links (four apps plus shared Codex/ZCode and Agy CLI locations) resolve to the primary clone source with identical content. App refresh was not observed. Receipts: `TESTS-RESULTS/2026-09-04+GH-439/provenance.jsonl`; review: `relay-system/2026-09-04/gh439-skill-qa.md`. No runtime code changed; no full runtime suite claimed.

## Rating amendment (2026-09-04)

Operator requires task severity/impact/appeal assessment, with priority driven by severity and user input, recurrence-aware severity, high severity for crashes/corruption/work blocking, neutral appeal unless overridden, and Agy QA after the edit. Recon: RELEASES-DB-FAQS.md specifies four 1–100 axes (`pri/sev/appeal/effort`), not three levels or a separate impact field. CLI `roadmap rate --help` confirms that interface. `utils/py/releases_app.py::cmd_roadmap_rate` writes through `parse_rating` and `perform_write`; its default refuses already-rated rows, and re-rating without `--ovr` clears that override. PDDA planning metadata remains documented independently of the retired ledger rating vocabulary. Graph discovery did not return in time; inspected the exact CLI handler after the documented interface.

Amendment plan: add one rating policy to the existing skill, link it into intake/recon/both QA stages and dependency-safe ordering, preserve the existing scoring schema and write path, then have Agy review the revised skill. Verify scenarios for a single crash without history, repeated incidents versus duplicated reports, user appeal/priority/rank overrides, grouped issues and legacy PDDA vocabulary. Re-deploy the identical reviewed source through existing links and update the same PR. No runtime/schema change.


Task GH-439 rating (2026-09-04): **80/35/50/85** (priority/severity/appeal/cheapness), persisted through `roadmap rate` and read back. Priority reflects the operator's explicit importance; severity is moderate workflow misprioritization risk, with no observed crash or corruption; appeal is neutral; cheapness reflects a localized documentation extension. Recurrence recon searched skill-related issues created since 2026-08-08 (87 broad matches, not 87 incidents), including workflow sibling #436 and canonical rating issue #108. These do not establish repeated incidents of this omission; incident velocity remains unknown. No operator rank override was present. The windows for future incident assessment are the most recent 14 days versus the preceding 14 days, with dated evidence required.

Rating amendment QA: Agy Approved / PASS with textual-only basis, driver exit 0; thread `relay-system/2026-09-04/gh439-ratings-agy-qa.md`. Validator passed; canonical CLI rejected a three-value rating and preserved an explicit rank override in dry-run. All global links read the revised source. Receipts appended to the existing provenance file.
