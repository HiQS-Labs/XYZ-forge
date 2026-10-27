---
Goal: Plan QA — GH-1234 marathon lane PR body carries Closes #<issue>
Date: 2026-10-27
NEXT: codex
STATUS: Open
---

# Context

Review the plan in `PROJECT/1-INBOX/GH-1234-CLOSEOUT-CLOSES-KEYWORD.md` (issue https://github.com/HiQS-Labs/XYZ-forge/issues/1234) before implementation. Base `5cab70c8`.

Requirement: a merged Marathon/Jog lane PR must close its issue, so post-merge reconcile completes the doc and ledger row without a hand edit. A multi-phase umbrella must not close early. Observed on PR #1225 (#416) in GH-1175 Phase 0.

Operational envelope: a few lines in `open_lane_pr()` plus a no-op extraction of an existing three-key predicate. Do not ask for new tests (AGENTS.md *No new tests*, GH-831), new suites, flags or machinery. Grade against the stated requirements and commensurate complexity.

Read:
- the plan doc in full
- `utils/py/marathon_drive.py` lines 120–135 (`_derive_issue_number`), 1575–1585 (`lane_issue_number`), 2620–2640 (the lazy-import idiom), and 2667–2700 (`open_lane_pr`)
- `utils/py/wave_reconcile.py` lines 1070–1105 (`find_active_doc_for_issue`, `parse_doc_frontmatter`), 2375–2395 and 2460–2475 (the inline multiphase checks)
- `relay-automation/marathon-closeout.sh` lines 1–60 and 110–200 (how `--notes` becomes the PR body)
- `test/gh402-branch-enforcement.sh` around line 292

Questions:

1. Is `open_lane_pr()` the only automated path that opens a lane PR without a closing keyword? Is `lane_issue_number()` reachable and correct in its scope, given the #416 lane names (`gh-416-…` phase id, `MARATHON-GH-416-…-TURN` token)? Note that the regex is case-sensitive.
2. Is the frontmatter umbrella/multiphase declaration the right test for "this lane does not finish the issue"? Is there a better existing signal, such as a MARATHON.yaml with several phases for one issue? Cite it if so.
3. Is the fallback "lookup fails → `Refs`, never `Closes`" right? And does `wave_reconcile` importing cleanly from `marathon_drive` (lazy, inside try) risk cycles or vendored breakage?
4. Is extracting `doc_declares_multiphase` a safe no-op for both wave_reconcile call sites?
5. Are the rating (65/55/50/85) and its rationale grounded?
6. Are the verification (gh232, gh202, gh402, routed gate, and a stub-`gh` smoke with red control plus two adjacent cases) sufficient and commensurate?

Flag anything wrong, missing, or over/under-scoped, citing file:line. Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`. Write your verdict below and set STATUS to Approved if the plan can proceed.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log
