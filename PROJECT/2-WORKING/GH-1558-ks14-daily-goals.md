---
issue: 1558
title: "kickstart(KS-14): build_queue.py --daily-goals <issue> scopes run to daily-goals issue"
status: active
roadmap_id: rmi-01M7W542W35G5JCV8M0WX2YA9A
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
| Created fresh clone off reconciled `origin/development` (post KS-02), registered `rmi-01M7W542W35G5JCV8M0WX2YA9A`, and completed grounded recon of `skills/1-hourly/kickstart/scripts/build_queue.py` and `skills/1-hourly/kickstart/SKILL.md`. | Complete Codex Plan QA, implement `--daily-goals <issue>` in `build_queue.py` and document in `kickstart/SKILL.md`, run paired red/green checks + mypy + PDDA under `TESTS-RESULTS/2026-11-20+GH-1558/`, and pass Final QA. |

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
   - Parse selected issue/PR references from the daily-goals issue body:
     - Sanitize fenced code blocks and wholly quoted inline spans (reusing `_sanitize_body` so example/code snippets do not create false references), extract referenced `#N` (and same-repo `OWNER/REPO#N`) numbers (excluding the daily-goals issue number itself and closed/checked-off `- [x]` list items so completed checklist entries are NOT re-queued).
     - Fail closed with a clear non-zero exit if `--daily-goals <N>` cannot be found, is closed, or contains zero open/unchecked issue/PR references.
   - Scope filtering when `--daily-goals <N>` is given:
     - Lift the `Daily goals*` out-of-scope skip for that selected daily-goals input (do NOT put the daily-goals issue itself into `Not queued` as a dropped item, and record `daily-goals #<N>` in the rendered header comment).
     - **Ignore `--since-days` for referenced issues:** in live mode, fetch any referenced open issue missing from the `created:>={cutoff}` list via `gh issue view <num> --json number,title,labels,body,createdAt,comments,state` (skipping closed issues); in `classify_issues()`, pass `include_ids: set[int] | None` so referenced issues bypass the `createdAt < cutoff` skip while still honoring every safety rule (KS-02 `operator_decision`, U15 `issue_hold_reason`, `--other-session`, `--needs-operator`, folded PRs).
     - Scope the queue to the selected daily-goals references (plus open PRs explicitly referenced by the daily-goals issue OR closing/referencing a selected issue), rather than pulling unrelated repo backlog outside the daily-goals issue. Unselected issues/PRs stay out of the daily-goals queue.
     - Keep default behavior (when `--daily-goals` is NOT passed) 100% unchanged!
   - Verify `mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/build_queue.py`.
2. **`skills/1-hourly/kickstart/SKILL.md`:**
   - Document `build_queue.py --daily-goals <issue>` in the kickoff/queue-building instructions (ignores `--since-days` for referenced issues, lifts `Daily goals*` out-of-scope for that one input, honors all holds/decisions).
3. **Paired Red/Green Checks (`TESTS-RESULTS/2026-11-20+GH-1558/`, no new test suite GH-831):**
   - **Pre-Change Red Control:** run pre-change `build_queue.py` on a realistic fixture containing a `Daily goals — 2026-11-20` issue referencing an older open bug issue (created 30 days ago, outside `--since-days 14`) + a held issue + a checked-off `- [x]` item -> prove pre-change skips the daily-goals issue into `Not queued`, drops the >14-day referenced issue, and has no `--daily-goals` flag (exit 2).
   - **Changed Green Controls:**
     - Control 1: `build_queue.py --daily-goals <N>` includes the >14-day referenced open issue in the execution queue, omits checked-off `- [x]` items and unrelated backlog, does NOT put the daily-goals issue in `Not queued`, and still parks U15-held / `--other-session` referenced issues cleanly.
     - Control 2: Default invocation without `--daily-goals` preserves exact legacy behavior (daily-goals issue still routed to `Not queued`, >14-day issue filtered by `--since-days`).
     - Control 3: Fail-closed error when `--daily-goals` targets a missing/closed/empty-selection issue (non-zero exit).
   - Run `mypy`, `ci-route.sh`, `./utils/pdda/pdda.sh run` (0 errors), and generate `provenance.jsonl`.

## Acceptance Criteria
- `build_queue.py --daily-goals <issue>` scopes the run queue to that daily-goals issue's selected items, ignores `--since-days` for referenced issues, lifts the `Daily goals*` out-of-scope rule for that one input, preserves KS-02/U15 holds and checked-off exclusions, and leaves default mode unchanged.
- Paired red/green checks, mypy (0 issues), PDDA (0 errors), and `provenance.jsonl` retained under `TESTS-RESULTS/2026-11-20+GH-1558/`.
