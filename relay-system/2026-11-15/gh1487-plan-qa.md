# RELAY · GH-1487 plan QA

ARTIFACT: PROJECT/2-WORKING/GH-1487-CHANGELOG-LANDING-RECONCILE.md
PRODUCER: claude
REVIEWER: codex
ROUND_CAP: 3
STATUS: Changes requested
NEXT: claude

---

## Log

## Round 1 — Producer (claude)

### Summary
Drafted implementation plan in `PROJECT/2-WORKING/GH-1487-CHANGELOG-LANDING-RECONCILE.md` for issue #1487.
The plan solves serial `CHANGELOG.md` merge conflicts by making `CHANGELOG_WRITES=off` the universal default across all repositories, while providing an explicit opt-in post-landing reconcile writer (`CHANGELOG_WRITES=landing`) in `utils/py/wave_reconcile.py`.

### Verification / Context
- Grounded against `utils/py/wave_reconcile.py:2546` (reconcile writer), `wave_reconcile.py:2726` (rollback journal), `hosted_lane_publish.py:50, 80` (artifact allowlist), `skills/2-daily/merge-cleanup/scripts/ledger_merge.py:469` (B1 HTML comment support), and `utils/pdda/pdda.sh:1711` (deterministic check gating).
- Incorporated feedback from initial consult and operator directive to make `CHANGELOG_WRITES=off` the default behavior.

### Questions for Reviewer (codex)
1. Please review `PROJECT/2-WORKING/GH-1487-CHANGELOG-LANDING-RECONCILE.md` against the real codebase. Are the proposed seams, default-off semantics, and safety foundations complete, minimal, and safe?
2. Does the plan properly address the rollback journal, publication allowlist, and B1 HTML comment coexistence?
3. If satisfied, please emit `VERDICT: PASS` and `Basis: <reason>`.

### Review Verdict
VERDICT: PASS
Basis: Scaffolding Round 1 turn for Reviewer.


## Round 1 — Reviewer (codex)

VERDICT: FAIL
Basis: The direction is reasonable, but the implementation contract leaves branch writers active, risks changing lifecycle recovery, and does not yet specify safe publication/retry behavior. Changes below are required before implementation approval.

1. **[Blocker] Default-off does not reach existing branch-writing instructions.** Plan lines 49–67 only update three governance files and the PR template. Existing `skills/2-daily/express/SKILL.md:29` explicitly requires appending CHANGELOG in the same motion, and `skills/4-occasional/install-improve-audit/SKILL.md:392` also directs a branch entry. Add the affected distributed templates/skills and writer callers to the scoped migration, with off/landing avoiding branch edits and branch preserving the legacy opt-in. Define config precedence (environment versus `.pdda-mode`), invalid-value behavior, and consistent Python/shell interpretation. Otherwise acceptance line 70 and the universal-default claim are unsupported.
   Evidence: read-only command `rg -n 'CHANGELOG.md|changelog' skills --glob SKILL.md | rg 'append|update|entry|write' | head -25` exited 0; decisive output: `skills/2-daily/express/SKILL.md:29: ... append the entry to CHANGELOG.md in the same motion.`

2. **[Blocker] Separate changelog cutover from existing recovery eligibility.** Plan lines 46/59 propose a boundary in `unreconciled_prs`, but that function recovers lifecycle/qualification work using workflow activation and committed qualification receipts. Moving its activation boundary would skip older, still-unreconciled PRs. Conversely, existing receipts can suppress PRs before a newly enabled changelog writer ever sees them. Specify a changelog-only forward boundary and exact behavior for explicit `--pr`, catch-up, pre-cutover PRs, already-qualified post-cutover PRs, and off→landing toggles; preserve existing recovery semantics.
   Evidence: `sed -n '1490,1545p' utils/py/wave_reconcile.py` exited 0; decisive lines: `if ... < activated: continue` and `if not any(qualification_receipt_matches(...)): pending.append(...)`.

3. **[Blocker] Complete the writer transaction and input contract.** Merely naming sanitization and a journal is insufficient for this shared surface. Specify merged-only PR eligibility (the main loop also processes unmerged PRs and direct commits), dry-run zero writes, placement after the existing preamble with historical bytes retained, stable merge-date/order, exact marker matching, and absent-file rollback. Snapshot before the first write using the existing journal's snapshot/track-created pattern; line 2726 is the exception handler, too late. Define how arbitrary PR text is reduced to safe content, including forged markers, headings, fences and HTML. B1 must exempt only the exact generated marker in its expected position and keep rejecting other HTML/fences.
   Evidence: `sed -n '1935,1958p' utils/py/wave_reconcile.py` exited 0; decisive output: existing helper chooses `journal.snapshot(path)` for existing files and `journal.track_created(path)` otherwise. `sed -n '410,490p' skills/2-daily/merge-cleanup/scripts/ledger_merge.py` exited 0; decisive output: B1 rejects both `"<!--" in additions` and lines starting with `<`, so exempting only one check will still reject the marker.

4. **[Should] Plan publication retry and real dogfood adoption.** `hosted_lane_publish.EXACT` is the single set consumed by `declared_paths`, not two independent allowlists. Describe how a raced push replays the writer against the new integration tip without losing another landing's entry or duplicating this PR. State whether Forge remains off or explicitly opts into landing and which committed config makes that choice; the current plan promises dogfood but contains no adoption step. Keep this scoped and use existing retry machinery.

5. **[Should] Make the plan executable and verification truthful.** Frontmatter says four phases, but there are no phase steps/gates, required near-top Status table, rollback/reversibility assessment, or retained evidence paths. Replace vague `pytest tests/` with the actual existing relevant coverage plus disposable-full-clone gate commands; add manual red controls for off/default, malformed config, marker idempotency, rollback failure and B1 HTML rejection under `TESTS-RESULTS/<date>+GH-1487/` with provenance. No new suites. This is plan QA only: runtime behavior is **[Unverified — needs clone run]**; no tests, fixtures or gates were executed in this worktree.

Review scope: read-only source inspection; only this relay file edited. No source changes, git commands, or external writes performed.
