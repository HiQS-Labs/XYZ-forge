---
title: build_queue --daily-goals admits #N from prose, not just checklist items
status: Planning
created: 2026-11-23
updated: 2026-11-23
owner: noelsaw1
gh_issue: 1569
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1569
goal: When a daily-goals issue body has a task list, admit only the lead #N of each unchecked checklist line
---

# GH-1569 — `--daily-goals` admits only unchecked checklist items

Refs #1541 (KS-14 / KS-17). Follow-up to GH-1558 (shipped in PR #1563).

## Problem (observed, base `2ac998d130d9`)

`parse_daily_goals_refs()` (`skills/1-hourly/kickstart/scripts/build_queue.py:259`) takes every `#N` on
every non-`[x]` line of the daily-goals body. #1568's original body
(`Out of scope: #1400, #1418, #1480–#1483, #1537 …`) therefore queued #1480 and #1483 and put #1537 in
Needs-the-operator, although the issue excluded them. Red replay:
`TESTS-RESULTS/2026-11-23+GH-1569/outputs/red-base-original-body.md`.

## Recon

- The daily-goals body is read in exactly one place: `parse_daily_goals_refs` (called once, `main()` ~line 455).
  Everything else reads other issues' bodies (`issue_hold_reason`, `classify_issues` AFTER) or PR bodies
  (`closing_refs`); none admits numbers from the daily-goals body. The goals issue is never in
  `scoped_issues`, so its own text is not hold-scanned for selection.
- `CHECKED_LINE` (line 97) is used only by that function. `ATOMIC_REF` already consumes `owner/repo#N`
  atomically; `GH-N` text never matches (no `#`), so `(GH-…)` nesting is already inert.
- Docs: `skills/1-hourly/kickstart/SKILL.md:302-308` (Daily-Goals Queue Scoping) describes the current rule.
- No existing test suite covers `build_queue.py` (`rg build_queue test/` empty); the GH-1558 precedent
  verified by a manual check under `TESTS-RESULTS/`. GH-831: no new suite.

## Decision: no-task-list bodies keep today's behaviour (not fail-closed)

Both options were offered in the issue. Chosen: **unchanged behaviour** for a body with no checkbox line.
Why it is the smaller one: it adds no new refusal path, no new error text and no doc'd exit code, and
GH-1558's prose-only controls stay valid; fail-closed would need a new `sys.exit` branch plus doc.
Proof: the no-task-list branch is the existing loop body untouched; replay a prose-only body on base and
on the change and diff the outputs byte-for-byte.

## Plan (one file of code, one doc paragraph)

1. `build_queue.py`: replace `CHECKED_LINE` with `CHECKBOX = ^\s*(?:[-*+]|\d+\.)\s*\[([ xX])\]` (captures the
   state). In `parse_daily_goals_refs`: after sanitising, `has_tasklist = any(CHECKBOX.match(l) ...)`.
   - no task list → current loop, unchanged (prose admitted, `[x]` skip is moot).
   - task list → per line: skip unless CHECKBOX matches with a blank state; admit only the FIRST
     `ATOMIC_REF` match on the line. If that lead is foreign-repo or the goals issue itself, the line
     yields nothing (later refs on the line are references, never promoted). Dedup stays.
2. `SKILL.md:302-308`: update the first bullet to the new rule (+ one line: a no-checklist body keeps the
   prose rule).
3. Manual red/green under `TESTS-RESULTS/2026-11-23+GH-1569/` with `provenance.jsonl`. No test file/suite.

Non-goals: no change to PR/issue resolution, holds, `--since-days`, exit codes; no new flag; no
new-suite; no handling of non-GitHub task syntaxes beyond `-`, `*`, `+`, `N.` bullets.

## Acceptance (falsifiable)

| # | Input | Base | Change |
|---|---|---|---|
| R/G | #1568 ORIGINAL body (GraphQL `userContentEdits`, editedAt 2026-11-20T17:07:07Z) | #1480, #1483 queued; #1537 Needs-operator (red, captured) | none of the three appears anywhere; 7 checklist items + nothing from prose |
| 2 | #1568 CURRENT body | 7 items | same 7 items (byte-identical Queue section) |
| 3 | checklist line with `(GH-1700)` / `after #1601` / second `#N` | later refs admitted (base) | only the lead `#N` admitted |
| 4 | `- [x] #N` and prose `#N` in a body that has a task list | prose admitted | neither admitted |
| 5 | body with no checkbox line | prose admitted | byte-identical output to base |
| 6 | task list where every line is `[x]` | n/a | still fails closed through the existing "selected zero" exit |
| 7 | `other/repo#9 then #10` lead foreign | #10 admitted | line yields nothing |

`mypy --allow-untyped-defs --allow-incomplete-defs` on the script; route via `utils/ci-route.sh`.

## Rating (RELEASES, 2026-11-23)

pri 60 / sev 45 / appeal 50 (neutral) / effort 90. Consequence: a live kickstart run queued three
operator-excluded items (caught by the operator, work-around: rewrite refs as `GH-N`). Recurrence: 1
observed incident (run 2, 2026-11-20); trend unknown. Cheap: one function.

## Lessons Learned

NO_ENTRY (pending final).
