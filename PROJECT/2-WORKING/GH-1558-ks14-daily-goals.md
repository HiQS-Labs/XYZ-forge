---
gh_issue: 1558
title: "kickstart(KS-14): build_queue.py --daily-goals <issue> scopes run to daily-goals issue"
status: active
roadmap_id: rmi-01M7WV7C6MVMYPZ1C61BVYQBEQ
parent_arc: 1541
milestone: KS-14
owner: antigravity
goal: "Add --daily-goals <issue> to build_queue.py so run-2 scope comes from a daily-goals issue, ignoring --since-days for referenced issues and lifting the Daily goals* out-of-scope rule for that input, with paired red/green checks."
created: 2026-11-20
updated: 2026-11-20
---

# GH-1558 (KS-14) — Daily-Goals Issue Scope (`build_queue.py --daily-goals <issue>`)

## Status

| What was just completed | What's next |
|---|---|
| Folded Plan QA R1 blockers (Major 1: preserve safety/hold evidence for all closing targets of admitted PRs before applying queue scope + park on unresolved safety metadata; Major 2: atomic same-repo ref parsing, explicit issue-vs-PR resolution, offline replay fail-closed on missing refs, post-resolution empty-selection check, and `build_queue.py:377-379` folded old-issue bypass). | Complete Codex Plan QA R2 approval, implement `--daily-goals <issue>` in `build_queue.py` and document in `kickstart/SKILL.md`, run paired red/green checks + mypy + PDDA under `TESTS-RESULTS/2026-11-20+GH-1558/`, and pass Final QA. |

## Objective
Implement issue #1541 milestone KS-14 (OL-17): add `--daily-goals <issue>` to `skills/1-hourly/kickstart/scripts/build_queue.py` so a kickstart run can take its scope directly from a daily-goals GitHub issue (ignoring `--since-days` for issues referenced by that daily-goals issue, lifting the `Daily goals*` out-of-scope rule for that selected input, while preserving KS-02/U15 holds, `--other-session`, `--needs-operator`, and replay determinism). No new test suite (GH-831).

## Grounded Recon
- `skills/1-hourly/kickstart/scripts/build_queue.py:86` (and line 288): `OUT_OF_SCOPE` currently matches `Daily goals*` titles and routes them to `skipped` (Not queued).
- `skills/1-hourly/kickstart/scripts/build_queue.py:258-292`: `classify_issues()` skips every issue whose `createdAt[:10] < cutoff` (`--since-days`), and skips `OUT_OF_SCOPE` titles.
- `skills/1-hourly/kickstart/scripts/build_queue.py:340-386`: `main()` accepts `--prs-json`, `--pr-meta-json`, `--issues-json`, `--since-days`, `--as-of`, `--owner`, `--other-session`, `--needs-operator`. Live mode fetches open issues with `created:>={cutoff}`.
- `PROJECT/PDDA.md:462-465`: honor configured `CHANGELOG_WRITES` mode (no task-branch `CHANGELOG.md` edit).

## Plan
1. **`skills/1-hourly/kickstart/scripts/build_queue.py`:**
   - Add CLI flag `--daily-goals <issue_number>` (optional int, plus optional `--daily-goals-json <file>` for deterministic offline replay of a saved `gh issue view <N> --json number,title,body,labels,state,comments` payload; when `--issues-json` is supplied and the daily-goals issue is already inside `--issues-json`, resolve it directly from `--issues-json` without network calls).
   - **Atomic reference parsing from the daily-goals issue body:**
     - Sanitize fenced code blocks and wholly quoted inline spans (reusing `_sanitize_body`), skip checked-off checklist lines (`- [x]` / `* [x]`), and parse references atomically using a single token regex matching `(?:([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+))?#(\d+)` anchored so `other/repo#123` is parsed as foreign-repo and NEVER falls back to bare `#123`! Keep only bare `#N` and same-repo `slug#N` (excluding the daily-goals issue number itself).
   - **Complete issue-vs-PR resolution & offline fail-closed contract:**
     - Determine offline/replay mode whenever any of `--prs-json`, `--pr-meta-json`, `--issues-json`, or `--daily-goals-json` is provided (zero network calls in replay mode!).
     - For every referenced number `num` in the daily-goals body:
       - If `num` is in open PR metadata (`meta`) AND in `pr_minder` rows -> classify as selected open PR. If `num` is in `meta` (open PR) but absent from `pr_minder` rows (or vice versa) -> fail closed with a clear non-zero exit naming the incomplete PR input (never silently drop!).
       - Else if `num` is in `issues` -> classify as selected issue (skip if `state` is explicitly `"CLOSED"`).
       - Else in **live mode**: resolve via `gh issue view <num> --json number,title,labels,body,createdAt,comments,state` (and if it is a PR or closed, handle explicitly: open PR absent from open PR lists fails closed; closed issue/PR is skipped; unresolvable/API error fails closed).
       - Else in **offline replay mode**: fail closed with a non-zero exit naming the missing referenced `#num` (NEVER silently drop a missing replay reference and NEVER call `gh`!).
     - **Post-resolution empty-selection check:** after resolving open/closed state, if `--daily-goals <N>` itself is missing or closed, OR zero open selected issues/PRs remain (e.g., all referenced items are closed), fail closed with a clear non-zero exit.
   - **Preserve safety/hold evidence BEFORE applying queue scope (Major 1):**
     - Scope limits *emitted work*, NEVER safety evidence:
       1. Identify candidate admitted PRs: open PRs explicitly selected by `--daily-goals` OR closing a selected issue.
       2. Collect EVERY closing target `#target` of every candidate admitted PR (including unselected or older issues beyond `--since-days`).
       3. Resolve any missing `#target` issue metadata (`labels`, `body`, `comments`, `state`, `title`, `createdAt`) before building `parked_issues(...)`: in live mode via `gh issue view`; if any closing target's safety metadata cannot be resolved (offline missing or API failure), treat that target as **parked** (fail closed so the PR cannot merge and close an uninspected issue!).
       4. Build `parked_issues(...)` over the FULL safety issue set (including unselected/older closing targets with their comments/labels/body) BEFORE scoping `classify_prs(...)` and `classify_issues(...)`.
   - **Scope filtering & old-issue bypass (including `build_queue.py:377-379`):**
     - Lift `Daily goals*` out-of-scope for `--daily-goals <N>` (do NOT emit `<N>` into `Not queued`; record `daily-goals #<N>` in the header comment).
     - Ignore `--since-days` for selected issues in BOTH `classify_issues(...)` (`include_ids=selected_issue_ids`) AND the folded-annotation filter at `build_queue.py:377-379` (`open_issues = {i["number"] for i in issues if i["createdAt"][:10] >= cutoff or i["number"] in selected_issue_ids}`), so a selected old issue folded into an admitted PR remains visible in `(closes #...)`.
     - Emit only selected issues and admitted PRs; unselected backlog stays out of the daily-goals queue. Default mode (without `--daily-goals`) remains 100% unchanged.
   - Verify `mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/build_queue.py`.
2. **`skills/1-hourly/kickstart/SKILL.md`:**
   - Document `build_queue.py --daily-goals <issue>` in the kickoff/queue-building instructions (ignores `--since-days` for referenced issues, lifts `Daily goals*` out-of-scope for that one input, honors all holds/decisions).
3. **Paired Red/Green Checks (`TESTS-RESULTS/2026-11-20+GH-1558/`, no new test suite GH-831):**
   - **Pre-Change Red Control:** run pre-change `build_queue.py` on a realistic fixture containing a `Daily goals — 2026-11-20` issue referencing an older open bug issue (created 30 days ago, outside `--since-days 14`) + a held issue + a checked-off `- [x]` item -> prove pre-change skips the daily-goals issue into `Not queued`, drops the >14-day referenced issue, and has no `--daily-goals` flag (exit 2).
   - **Changed Green Controls:**
     - Control 1: `build_queue.py --daily-goals <N>` includes the >14-day referenced open issue in the execution queue, omits checked-off `- [x]` items and unrelated backlog, does NOT put the daily-goals issue in `Not queued`, and still parks U15-held / `--other-session` referenced issues cleanly.
     - Control 2: Default invocation without `--daily-goals` preserves exact legacy behavior (daily-goals issue still routed to `Not queued`, >14-day issue filtered by `--since-days`).
     - Control 3: Fail-closed errors (non-zero exit) for: (a) missing/closed daily-goals issue, (b) all-closed references (post-resolution empty selection), (c) missing reference in offline replay mode (zero network calls), (d) incomplete PR input (selected open PR missing from `pr_minder` rows).
     - Control 4 (Safety preservation & foreign-repo atomicity): (a) admitted PR closing selected issue #10 AND unselected older held issue #30 (`status:held` / operator hold) -> #30's hold is preserved and PR is parked rather than queued; (b) KS-02 latest-owner `hold` vs `proceed` comment on a selected issue; (c) explicit open PR selection (`#PR`) in daily-goals body; (d) foreign-repo reference `other/repo#123` is ignored cleanly and does NOT match local `#123`; (e) selected old issue folded into an admitted PR still displays `(closes #<old>)` (`build_queue.py:377-379` bypass).
   - Run `mypy`, `ci-route.sh`, `./utils/pdda/pdda.sh run` (0 errors), and generate `provenance.jsonl`.

## Acceptance Criteria
- `build_queue.py --daily-goals <issue>` scopes the run queue to that daily-goals issue's selected items, ignores `--since-days` for referenced issues, lifts the `Daily goals*` out-of-scope rule for that one input, preserves KS-02/U15 holds and checked-off exclusions, and leaves default mode unchanged.
- Paired red/green checks, mypy (0 issues), PDDA (0 errors), and `provenance.jsonl` retained under `TESTS-RESULTS/2026-11-20+GH-1558/`.
