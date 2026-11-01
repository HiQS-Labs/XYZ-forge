---
Goal: Final QA for GH-1309 (skills-army-hq --migrate-legacy)
Date: 2026-11-01
---

NEXT: codex
STATUS: In review

# Context

Review the committed change for https://github.com/HiQS-Labs/XYZ-forge/issues/1309 against its approved plan (PROJECT/2-WORKING/GH-1309-SA-MIGRATE-LEGACY.md; plan QA Approved in relay-system/2026-11-01/gh1309-plan-qa.md). Diff: `git diff cb1bf933..HEAD -- skills CHANGELOG.md TESTS-RESULTS`. Evidence: TESTS-RESULTS/2026-11-01+GH-1309/ (manual-check.md has the full matrix output and the script text; provenance.jsonl).

Operational envelope: a small, opt-in change to the Skills Army HQ scripts. Grade against the stated requirement and commensurate complexity. No new test file or registry entry (GH-831). The tool states it is not a security boundary against a hostile process with the same user's write access. Review only: edit nothing except this relay file. No network calls.

Producer notes: plan QA asked for the overlap check to be specific to retirement and for the docs to say an older manager cannot replay the new pending receipts; both are in. During verification a redundant name comparison was found (skill_info already enforces folder/name) and removed (commit 190be352).

Questions:

1. Does the code satisfy the plan and issue #1309? Cite file:line for: the new flag and flag-combination errors (sync.py main), retire_legacy and the reconcile changes, the retire-directory apply change and replay rule, and the validate_receipt widening with the overlap check (intake.py).
2. Ordering and failure behaviour: is the retire-directory action always emitted immediately before its link action? What happens if archive() or the staging mkdir fails after planning other keys, or if reconcile later errors for the same key? Is any partial state left that a repeat run cannot handle?
3. Did anything slip in beyond the plan (a second writer, changed semantics of --adopt, --migrate, --migrate-from or --retire-trinity, unrelated edits)?
4. Does the evidence support the claims: 36 of 36 matrix checks including red controls A (base rejects the flag), B and C (forged receipts), replay, and the existing 33-test suite? Is any promised case missing? Is the docs text (recovery.md, SKILL.md) accurate against the code?
5. Is the persisted rating (45/30/50/60) still consistent? Is the Costly reversibility claim stated honestly in the CHANGELOG?

Each `[Blocker]` or `[Should]` must carry `Observed input:`, `Affected scope:` and `Falsifier:` lines. Cite file:line.

Write your verdict below. Set STATUS to Approved if the change can ship as committed (minor notes allowed). Otherwise hand back with changes requested.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

