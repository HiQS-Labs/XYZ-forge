---
Goal: Final QA — GH-722 merge-cleanup same-origin sibling root (default scan + Phase 6)
Date: 2026-10-29
NEXT: codex
STATUS: Pending
---

# Context

Review the implementation of the plan you approved in `relay-system/2026-10-29/gh722-plan-qa.md` (plan section at the end of `PROJECT/2-WORKING/GH-722-MERGE-CLEANUP-SAFE-ROOTS-PARENT.md`). Diff to review: `git diff b6add0c9..HEAD` (code commit 0518aeb4, docs 3f5820f3, receipts f4dc7e51 and the focused-suite receipt).

Changed source: `skills/2-daily/merge-cleanup/scripts/scan_clones.py` (`sibling_root`, `primary_safe_roots`, `default_scan_roots`, `same_origin`, `inspect_checkout` safe-root check, `scan_directories` `sibling_root` filter, `main` header), `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (imports, `teardown_checkout` docstring, `main` roots/header, Phase 6 call), `test/gh436-merge-cleanup.py:711`, `test/gh534_phase_a_tests.py:569`, `WORKTREE-SAFETY.md` §16.1 prose, `skills/2-daily/merge-cleanup/SKILL.md`, `CHANGELOG.md`.

Evidence: `TESTS-RESULTS/2026-10-29+GH-722/` — `SUMMARY.md`, per-case outputs, `provenance.jsonl`, `focused-suites-0518aeb4.txt` (gh436 incl. gh534 A/B/C: 201 OK; gh645: 8 OK; gh674: 6 OK). Smoke covers main path, explicit-root adjacent path, fail-closed origin, NEVER_DELETE skip, and red controls (base 0628da70; origin condition removed). The full gate (tier 3, test/* changed) runs once via the pre-push hook on the final commit.

Operational envelope: single-operator local cleanup tool. Grade against the approved plan, the acceptance list and data-loss safety.

Questions:
1. Does the code match the approved plan steps 1–6 exactly? Anything missing or extra?
2. Can the parent folder ever make a foreign-origin or unreadable-origin checkout removable, on any path (default scan, explicit `--root`, refresh, Phase 6, retire mode)?
3. Is the `scan_directories` filter correct (resolved paths vs `root == sibling_root` comparison, primary itself, `seen` set) and does `--root` behaviour stay unchanged?
4. Are the two test edits truthful adaptations, not weakened assertions? Any leftover reference to `published_retirement_roots` or now-unused import?
5. Do the docs, CHANGELOG and receipts match the code? Are the smoke red controls falsifying the right things?

Cite file:line. Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`. Do not edit source files; write only to this thread.

**Required output format:** append one block under `## Log` containing a line `VERDICT: PASS` or `VERDICT: FAIL` (exactly), a one-line `Basis:` line, then your findings. Set STATUS to Approved on PASS.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log
