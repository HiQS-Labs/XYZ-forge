---
title: build_queue --daily-goals admits #N from prose, not just checklist items
status: Complete
created: 2026-11-23
updated: 2026-11-24
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

- The daily-goals body has two readers, with different jobs (plan QA R1):
  1. **Queue-admission parser** `parse_daily_goals_refs` (called once, `main()` ~line 455): the ONLY code
     that turns the body into selected numbers. This is the one that changes.
  2. **Safety/hold reader**, unchanged and deliberately left alone: `main()` copies every fetched issue into
     `safety_issues` (~432); when the goals issue is among them (it is in `issues` when created inside the
     window, or fetched as an admitted PR's closing target ~495-504) `parked_issues` (~517 -> 214-222) runs
     `issue_hold_reason` (187-200) on its body. A goals line like `- [ ] #10 after #11` therefore parks
     #1568 itself (not #11), which holds a PR that closes #1568 (`classify_prs` 242-243). It admits nothing to
     the queue. Checklist selection is NOT applied here; hold evidence stays fail-closed (SKILL.md:307).
  Other body readers (`classify_issues` AFTER, `closing_refs`) read selected issues' / PRs' own bodies.
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

"Discriminator" rows differ between base and change (each fails on base, the observed rejection of an unfixed
script); "control" rows are identical on both and only guard regressions. Success of the CLI (rc 0) is never
acceptance; each row compares parsed refs / Queue text.

| # | Kind | Input | Base | Change |
|---|---|---|---|---|
| 1 | discriminator | #1568 ORIGINAL body (GraphQL `userContentEdits`, editedAt 2026-11-20T17:07:07Z) via `--daily-goals-json` | #1480, #1483 queued; #1537 Needs-operator (captured red) | none of the three appears; Queue = exactly the 7 checklist items (#1417 #1467 #1471 #1497 #1500 #1530 #1551), no prose ref |
| 2 | control | #1568 CURRENT body | 7 items | same 7 items; Queue section byte-identical to base |
| 3 | discriminator | `- [ ] #10 after #1601` and `- [ ] #11 and also #12` | `[10, 1601]`, `[11, 12]` | `[10]`, `[11]` (lead only) |
| 3b | control | `- [ ] #10 (GH-1700)` | `[10]` | `[10]` (`GH-N` has no `#`) |
| 4 | discriminator | `- [ ] #11` + `- [x] #9` + prose line `see #10` | `[11, 10]` | `[11]` |
| 5 | control | body with no checkbox line (`prose #10`) | `[10]` | `[10]`, full CLI output byte-identical to base |
| 6 | control | task list whose every line is `[x]` | `[]` -> existing "selected zero" exit | same exit (fails closed) |
| 7 | discriminator | `- [ ] other/repo#9 then #10` | `[10]` | `[]` |
| 8 | control | safety reader: `parked_issues` on a goals issue whose body is `- [ ] #10 after #11` | `{1568}` | `{1568}` (unchanged) |

`mypy --allow-untyped-defs --allow-incomplete-defs` on the script; route via `utils/ci-route.sh`.

## Rating (RELEASES, 2026-11-23)

pri 60 / sev 45 / appeal 50 (neutral) / effort 90. Consequence: a live kickstart run queued three
operator-excluded items (caught by the operator, work-around: rewrite refs as `GH-N`). Recurrence: 1
observed incident (run 2, 2026-11-20); trend unknown. Cheap: one function.

## Lessons Learned

NO_ENTRY (pending final).
