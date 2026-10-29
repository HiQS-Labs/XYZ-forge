---
Goal: Plan QA — GH-722 merge-cleanup sibling safe root for the default scan and Phase 6
Date: 2026-10-29
NEXT: codex
STATUS: Pending
---

# Context

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/722. The plan is the `## Plan (2026-10-29, /start-task)` section at the end of `PROJECT/2-WORKING/GH-722-MERGE-CLEANUP-SAFE-ROOTS-PARENT.md` (commit f8b1440b; base 0628da70). Read the issue's Ask, the doc's Acceptance list and the plan, then check them against the source:

- `skills/2-daily/merge-cleanup/scripts/scan_clones.py` (`DEFAULT_SAFE_ROOTS` :26, `DEFAULT_NEVER_DELETE`, `published_retirement_roots` :53, `is_safe_deletable_path` :74, `_normalize_remote` :387, `inspect_checkout` safe-root check :945-948 and disposition ladder :1036-1130, `scan_directories` :1133, `main` :1421)
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (`refresh_for_teardown` :999, `teardown_checkout` :1018, `retire_published_checkouts` :1683-1725, `main` search roots :1818, Phase 1 header :1946, Phase 6 teardown :2178)
- `test/gh436-merge-cleanup.py:711`, `test/gh534_phase_a_tests.py:123-129` (parity pin)
- `WORKTREE-SAFETY.md` §16.1 (:790-830), `skills/2-daily/merge-cleanup/SKILL.md` :200 and :584
- Prior fix #1198 (GH-1193, `PROJECT/3-COMPLETED/GH-1193-RETIRE-SIBLING-ROOTS.md`) covered retire mode only.

Live motivating case: three LTVera-Pandas clones beside the primary in `~/Documents/GitHub Repos`; two have PR branches deleted on merge, one is a landing clone with no PR, so retire mode cannot take them and the default teardown refuses them as outside SAFE_ROOTS.

Repo rules: `AGENTS.md` *No new tests* (GH-831): verification uses existing suites or a manual check under `TESTS-RESULTS/`; editing an existing assertion to keep it truthful is allowed.

Operational envelope: a single-operator local cleanup tool on a Mac. Grade against the issue, the acceptance list and data-loss safety, not hypothetical multi-tenant threat models.

Questions:
1. Are the plan's claims grounded in the cited lines? Is anything the issue asks for missing?
2. Is the same-origin gate on the parent root sufficient and placed correctly to stop a foreign project's clean, landed checkout from becoming SAFE_REMOVE_CLONE, in the default scan, `--root` scans, refresh_for_teardown and Phase 6? Any path where the widened roots reach teardown without that gate?
3. Does the plan extend the existing helpers (`published_retirement_roots`, `_normalize_remote`, `is_safe_deletable_path`) rather than adding a parallel mechanism? Is the rename safe for every caller?
4. Is skipping foreign-origin entries of the derived root during the scan correct, and does it leave explicit `--root` behaviour unchanged?
5. Are the verification steps (existing suites, smoke with red control, NEVER_DELETE skip via a temp HOME) falsifiable and sufficient without a new test?
6. Anything simpler that meets the acceptance list?

Cite file:line. Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`. Do not edit source files; write only to this thread.

**Required output format:** append one block under `## Log` containing a line `VERDICT: PASS` or `VERDICT: FAIL` (exactly), a one-line `Basis:` line, then your findings. Set STATUS to Approved on PASS.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log
