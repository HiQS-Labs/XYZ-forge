---
Goal: Final QA — GH-1269 B1 CHANGELOG union keeps the integration side verbatim
Date: 2026-10-30
NEXT: Producer
STATUS: Approved
---

# Context

Issue https://github.com/HiQS-Labs/XYZ-forge/issues/1269. Plan approved in `relay-system/2026-10-30/gh1269-plan-qa.md` (Codex, VERDICT PASS). Canonical plan: `PROJECT/2-WORKING/GH-1269-B1-CHANGELOG-REORDER.md`. Evidence: `TESTS-RESULTS/2026-10-30+GH-1269/` (`smoke.md`, `smoke.py`, `red-control-prefix.log`, `smoke-candidate.log`, `gh789-matrix-candidate.log`, `gh789-matrix-baseline.log`, `provenance.jsonl`).

Operational envelope: one-function assembly change in a local merge helper; no new tests or registry entries (GH-831), no new machinery. Grade against the issue goal/non-goals and the approved plan.

Acceptance map:
- Goal: B1 prepends the PR's new sections and keeps development's history byte-for-byte including same-date order → smoke main path.
- A `resolved` repair passes B1's own history check next attempt → smoke adjacent (a), (b).
- Non-goals kept: refusals, fenced/HTML handoff, same-heading-different-body handoff, repair budget unchanged → smoke guard + GH-789 `ChangelogUnitCases` all ok.

Note on the GH-789 matrix: 8/27 end-to-end `run_main` cases fail identically on the pre-fix file in the same disposable clone (baseline log), i.e. pre-existing exit-code drift unrelated to this diff; the full pre-push gate (registered suites) will run once on the final commit after this review.

Questions:
1. Does the diff implement exactly the approved assembly (PR blocks in own order minus blocks present on the integration side, then `theirs[len(preamble):]`) with every validation kept and run before assembly?
2. Is the "drop PR blocks byte-identical to an integration addition" filter correct (list membership by string equality; a same-heading different-body pair still raises earlier)?
3. Do the receipts substantiate the claims, including the red control, the baseline comparison and the provenance rows? Is the matrix-drift disposition sound?
4. Is the rating `65/60/50/85` still right? Any new test file/registry entry or duplicate writer in the diff (would be a finding)?

End with exactly `VERDICT: PASS` (or `FAIL`) on its own line, followed by a non-empty `Basis:` line (GH-533). Set STATUS to Approved on PASS.

## Diff (5f328f1f..HEAD, excluding relay threads and releases.db)

```diff
diff --git a/CHANGELOG.md b/CHANGELOG.md
index 33d241d7..0181f434 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -1,5 +1,9 @@
 # Changelog
 
+## 2026-10-30 — GH-1269 merge-cleanup B1 CHANGELOG repair keeps development's history byte-for-byte
+
+- B1's additive CHANGELOG resolution used to re-sort every new section from both sides by heading, so development's own same-date sections were reordered. The next B1 attempt then refused that output ("changelog preamble or existing history changed") and spent the PR's second repair slot (LTVera PR #874). It now prepends the PR's new sections in their own order, drops any already on development, and copies development's text verbatim after the preamble. Every existing refusal is unchanged. Evidence: `TESTS-RESULTS/2026-10-30+GH-1269/smoke.md`. Reversibility: Easy.
+
 ## 2026-10-30 — GH-1261 outer loop drafts unregistered issues and resolves bare file names
 
 - `harness.py factory-primitive init --from-prs --unregistered N` adds N open issues that have no ledger row, read once at init. `plan-draft` gives them a planner-shaped record, and every seeded unregistered issue is visible to dependency lookup, so a dependent waits for its prerequisite.
diff --git a/PROJECT/1-INBOX/GH-1269-B1-CHANGELOG-REORDER.md b/PROJECT/1-INBOX/GH-1269-B1-CHANGELOG-REORDER.md
deleted file mode 100644
index 5177ec1c..00000000
--- a/PROJECT/1-INBOX/GH-1269-B1-CHANGELOG-REORDER.md
+++ /dev/null
@@ -1,79 +0,0 @@
----
-title: merge-cleanup B1 CHANGELOG repair reorders existing same-date sections
-status: Proposed (1-INBOX — not yet active)
-created: 2026-10-30
-owner: noelsaw1
-gh_issue: 1269
-source: https://github.com/HiQS-Labs/XYZ-forge/issues/1269
-doc_type: bugfix
-complexity: 2
-risk: 3
-effort: 2
-phases: 1
-ratings_provisional: true
-reported_from: LTVera-Pandas
-harness_commit: e305cbf3
-non_goals:
-  - Changing the GH-789 two-repair budget or the history-preservation refusal itself
-  - Resolving genuinely divergent same-heading additions (those still hand off)
-related:
-  - GH-789 (bounded repairs and the additive changelog boundary)
-goal: >
-  A B1 additive CHANGELOG resolution prepends the PR's new dated sections and keeps the
-  integration branch's existing history byte-for-byte, including the order of same-date
-  sections, so a repair recorded `resolved` passes B1's own history check on the next attempt.
----
-
-# GH-1269 — merge-cleanup B1 CHANGELOG repair reorders existing same-date sections
-
-> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
-> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
-> (`PROJECT/PDDA.md` → GitHub issue intake).
-
-## Symptom
-
-The B1 additive CHANGELOG resolution reorders the integration branch's existing same-date
-sections and records the repair `resolved`. The next B1 attempt refuses that output ("changelog
-preamble or existing history changed") and hands off, which uses up the PR's two-repair budget.
-
-## Environment
-- **Observed from:** `LTVera-Pandas` (vendored `.xyz/` at `017b1425`; `merge_cleanup.py` from the deployed Skills Army copy)
-- **Harness commit:** `e305cbf3` (intake repo at report time)
-- **Worker/CLI:** merge-cleanup (`merge_cleanup.py --execute`, B1 rung)
-- **Runtime:** Python — matches the `runtime:python` issue label
-- **Sandbox:** off
-
-## Reproduction
-1. LTVera PR #874 (one new 2026-10-30 section) conflicts with `development` `3c936bea`, whose `CHANGELOG.md` holds six 2026-10-29 sections added by three parallel PRs.
-2. `merge_cleanup.py --primary <landing clone> --prs 870,874 --execute`: B1 attempt 1 on head `f57f2540` resolves and pushes merge commit `497ca1e8`, recorded `resolved`.
-3. On the next run, B1 attempt 2 on head `497ca1e8` hands off.
-
-**Expected:** `497ca1e8`'s CHANGELOG = the GH-818 section + development's history unchanged.
-**Observed:** the six 2026-10-29 sections are reordered (development order 867-QA, 867, 866-typing, 866, 866-resumed, 776 → output order 776, 866, 867, 866-typing, 866-resumed, 867-QA); bodies intact. Attempt 2: `outcome: handoff`, `reason: CHANGELOG handoff: changelog preamble or existing history changed`.
-**Frequency:** once so far; expected to be deterministic for multi-section same-date history.
-
-```text
-attempts[0]: rung=B1 head=f57f2540 outcome=resolved commit=497ca1e8
-attempts[1]: rung=B1 head=497ca1e8 outcome=handoff reason="CHANGELOG handoff: changelog preamble or existing history changed"
-conflict_files: CHANGELOG.md, RELEASES-PREVIEW.html, releases.db, releases.sql
-```
-
-## Impact
-LTVera PR #874 needs an operator-approved third, CHANGELOG-only repair. Any batch landing with
-several same-date CHANGELOG sections from parallel PRs is exposed. No data loss: bodies are kept
-and the handoff stopped the reordered history from landing.
-
-## Phase 0 — Diagnose & scope
-> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
-> (`PROJECT/PDDA.md` → Discovery & spike phases).
-
-### Checklist
-- [ ] Reproduce it in the intake repo (not just in the reporting repo)
-- [ ] Locate the responsible script/path — name the concrete write-set (likely the additive-section merge under `skills/2-daily/merge-cleanup/scripts/`)
-- [ ] Decide fix vs. guard-and-document; reuse an existing code path before adding one (`/ponytail`)
-- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real
-
-### QA checklist — Phase 0
-- [ ] The repro is confirmed from the report, not assumed
-- [ ] An existing suite, or a recorded manual check, covers the failure path before the fix lands (no new test suites: `AGENTS.md` *No new tests*, GH-831)
-- [ ] The fix composes with the existing harness rather than adding a parallel path
diff --git a/PROJECT/2-WORKING/GH-1269-B1-CHANGELOG-REORDER.md b/PROJECT/2-WORKING/GH-1269-B1-CHANGELOG-REORDER.md
new file mode 100644
index 00000000..1855d8a2
--- /dev/null
+++ b/PROJECT/2-WORKING/GH-1269-B1-CHANGELOG-REORDER.md
@@ -0,0 +1,136 @@
+---
+title: merge-cleanup B1 CHANGELOG repair reorders existing same-date sections
+status: Active (2-WORKING)
+created: 2026-10-30
+owner: noelsaw1
+gh_issue: 1269
+source: https://github.com/HiQS-Labs/XYZ-forge/issues/1269
+doc_type: bugfix
+complexity: 2
+risk: 3
+effort: 2
+phases: 1
+reported_from: LTVera-Pandas
+harness_commit: e305cbf3
+non_goals:
+  - Changing the GH-789 two-repair budget or the history-preservation refusal itself
+  - Resolving genuinely divergent same-heading additions (those still hand off)
+related:
+  - GH-789 (bounded repairs and the additive changelog boundary)
+goal: >
+  A B1 additive CHANGELOG resolution prepends the PR's new dated sections and keeps the
+  integration branch's existing history byte-for-byte, including the order of same-date
+  sections, so a repair recorded `resolved` passes B1's own history check on the next attempt.
+---
+
+# GH-1269 — merge-cleanup B1 CHANGELOG repair reorders existing same-date sections
+
+## Status
+
+| What was just completed | What's next |
+|---|---|
+| Plan QA Approved (`relay-system/2026-10-30/gh1269-plan-qa.md`); fix 72be48e2; smoke 5/5, red control 4 FAIL; GH-789 matrix no regression (`TESTS-RESULTS/2026-10-30+GH-1269/smoke.md`) | Final Codex QA, full gate, PR |
+
+## Symptom
+
+The B1 additive CHANGELOG resolution reorders the integration branch's existing same-date
+sections and records the repair `resolved`. The next B1 attempt refuses that output ("changelog
+preamble or existing history changed") and hands off, which uses up the PR's two-repair budget.
+
+## Environment
+- **Observed from:** `LTVera-Pandas` (vendored `.xyz/` at `017b1425`; `merge_cleanup.py` from the deployed Skills Army copy)
+- **Harness commit:** `e305cbf3` (intake repo at report time)
+- **Worker/CLI:** merge-cleanup (`merge_cleanup.py --execute`, B1 rung)
+- **Runtime:** Python — matches the `runtime:python` issue label
+- **Sandbox:** off
+
+## Reproduction
+1. LTVera PR #874 (one new 2026-10-30 section) conflicts with `development` `3c936bea`, whose `CHANGELOG.md` holds six 2026-10-29 sections added by three parallel PRs.
+2. `merge_cleanup.py --primary <landing clone> --prs 870,874 --execute`: B1 attempt 1 on head `f57f2540` resolves and pushes merge commit `497ca1e8`, recorded `resolved`.
+3. On the next run, B1 attempt 2 on head `497ca1e8` hands off.
+
+**Expected:** `497ca1e8`'s CHANGELOG = the GH-818 section + development's history unchanged.
+**Observed:** the six 2026-10-29 sections are reordered (development order 867-QA, 867, 866-typing, 866, 866-resumed, 776 → output order 776, 866, 867, 866-typing, 866-resumed, 867-QA); bodies intact. Attempt 2: `outcome: handoff`, `reason: CHANGELOG handoff: changelog preamble or existing history changed`.
+**Frequency:** once so far; expected to be deterministic for multi-section same-date history.
+
+```text
+attempts[0]: rung=B1 head=f57f2540 outcome=resolved commit=497ca1e8
+attempts[1]: rung=B1 head=497ca1e8 outcome=handoff reason="CHANGELOG handoff: changelog preamble or existing history changed"
+conflict_files: CHANGELOG.md, RELEASES-PREVIEW.html, releases.db, releases.sql
+```
+
+## Impact
+LTVera PR #874 needs an operator-approved third, CHANGELOG-only repair. Any batch landing with
+several same-date CHANGELOG sections from parallel PRs is exposed. No data loss: bodies are kept
+and the handoff stopped the reordered history from landing.
+
+## Phase 0 — Diagnose & scope
+> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
+> (`PROJECT/PDDA.md` → Discovery & spike phases).
+
+### Checklist
+- [x] Reproduce it in the intake repo (not just in the reporting repo)
+- [x] Locate the responsible script/path — name the concrete write-set (likely the additive-section merge under `skills/2-daily/merge-cleanup/scripts/`)
+- [x] Decide fix vs. guard-and-document; reuse an existing code path before adding one (`/ponytail`)
+- [x] Set/correct the triage ratings; clear `ratings_provisional` once real
+
+### QA checklist — Phase 0
+- [x] The repro is confirmed from the report, not assumed
+- [x] An existing suite, or a recorded manual check, covers the failure path before the fix lands (no new test suites: `AGENTS.md` *No new tests*, GH-831)
+- [x] The fix composes with the existing harness rather than adding a parallel path
+
+## Rating (2026-10-30)
+
+`rated 65/60/50/85`. Severity 60: a resolved B1 repair produces history its own next attempt refuses,
+burning the GH-789 two-repair budget and forcing an operator-approved manual repair; recoverable, no
+data loss (the refusal stops the reordered history from landing). Priority 65: severity-led;
+deterministic whenever parallel PRs add several same-date sections, which batch landings do routinely.
+Appeal 50 (neutral, no operator preference). Effort 85: one function's assembly line plus a manual
+smoke. Recurrence: 1 incident (LTVera #874, 2026-10-30) in the last 14 days, 0 in the prior 14;
+no other open or closed issue reports it (search "changelog B1"). Trend: unknown beyond one incident.
+
+## Plan (GH-1269)
+
+### Recon (base: origin/development, see Status)
+
+- Landing merge runs inside the PR clone: `merge_cleanup.py:553` `git merge --no-ff --no-commit origin/<integration>`.
+  So in B1, `HEAD` = PR head (ours) and `MERGE_HEAD` = integration tip (theirs).
+- `ledger_merge.py::read_changelog_union` reads `CHANGELOG.md` at (merge-base, HEAD, MERGE_HEAD) and calls
+  `union_changelog(base, ours, theirs)`; its only caller is `resolve_ledger_conflict` (B1).
+- `union_changelog` validates that both sides are `preamble + additions + history`, collects every
+  addition block from **both** sides into one dict, and emits
+  `preamble + sorted(blocks, reverse=True) + history`. Sorting by heading text reorders the integration
+  side's own additions whenever they are not already in descending heading order (LTVera #874: six
+  2026-10-29 sections 867-QA, 867, 866-typing, 866, 866-resumed, 776 → 776, 866, 867, ...).
+- On the next attempt the merge base is the integration tip, so its whole post-preamble text becomes
+  `history`; the reordered output fails `text.endswith(history)` → "changelog preamble or existing
+  history changed" → handoff, second repair slot burned.
+- Coverage: no registered suite exercises `union_changelog`; GH-789's unregistered
+  `TESTS-RESULTS/2026-10-05+GH-789/manual_matrix.py` (ChangelogUnitCases, ChangelogMergeCases) does.
+
+### Fix (one function, one file)
+
+`skills/2-daily/merge-cleanup/scripts/ledger_merge.py::union_changelog`: keep every existing validation;
+change only the assembly. Output = `preamble + <PR-side (ours) addition blocks, in their own order,
+skipping any block byte-identical to an integration-side addition> + theirs[len(preamble):]`.
+The integration side's text after the preamble is copied verbatim, so the next B1 attempt's history
+check passes by construction. Docstring names the ours=PR / theirs=integration contract.
+
+Non-goals: no change to the two-repair budget, the refusal rules, fenced/HTML refusal, or
+same-heading-different-body handoff; no date re-sorting of PR blocks against integration blocks
+(the PR's sections are prepended, as the capture's goal states); no new suite (GH-831).
+
+Risk / rollback: single-function revert. A PR whose new section is dated older than an integration
+addition now lands above it (prepend) instead of being date-sorted; acceptable per goal, and B1 history
+stays byte-for-byte.
+
+### Verification
+
+1. Smoke (GH-1088), `TESTS-RESULTS/2026-10-30+GH-1269/`: main path = LTVera-shaped fixture (base; theirs
+   adds six same-date sections in non-sorted order; ours adds one newer section) → output equals
+   `preamble + ours block + theirs-after-preamble`; red control on the pre-fix function shows the
+   reorder. Adjacent path = feed the output back as the next attempt's (base=theirs, ours=output,
+   theirs=theirs + nothing new / plus one more section) → no "history changed" refusal.
+2. Re-run `TESTS-RESULTS/2026-10-05+GH-789/manual_matrix.py` in a disposable full clone (all cases green).
+3. Full gate via the pre-push hook (merge-cleanup scripts route to the full tier), run once on the
+   final commit.
diff --git a/TESTS-RESULTS/2026-10-30+GH-1269/provenance.jsonl b/TESTS-RESULTS/2026-10-30+GH-1269/provenance.jsonl
new file mode 100644
index 00000000..712a834e
--- /dev/null
+++ b/TESTS-RESULTS/2026-10-30+GH-1269/provenance.jsonl
@@ -0,0 +1,4 @@
+{"timestamp": "2026-10-30T18:00:00Z", "issue": 1269, "gate": "manual-check", "commit": "9812a7a4fa354c9ab4f6b2bb17d55b907657fe13", "case": "red-control-prefix-smoke", "command": "python3 TESTS-RESULTS/2026-10-30+GH-1269/smoke.py", "rc": 1, "result": "pass-red-control", "log": "red-control-prefix.log", "environment": "task clone, pre-fix ledger_merge.py (in tree before 72be48e2); 4 FAIL incl. attempt-2 'existing history changed' refusal, guard PASS"}
+{"timestamp": "2026-10-30T18:00:00Z", "issue": 1269, "gate": "manual-check", "commit": "72be48e2ed2d3d48cf5069907487820414691d6d", "case": "candidate-smoke-main-and-adjacent", "command": "python3 TESTS-RESULTS/2026-10-30+GH-1269/smoke.py", "rc": 0, "result": "pass", "log": "smoke-candidate.log", "environment": "task clone at fix commit; pure function, no repo writes; 5/5 PASS"}
+{"timestamp": "2026-10-30T18:00:00Z", "issue": 1269, "gate": "manual-check", "commit": "72be48e2ed2d3d48cf5069907487820414691d6d", "case": "gh789-manual-matrix-candidate", "command": "python3 TESTS-RESULTS/2026-10-05+GH-789/manual_matrix.py", "rc": 1, "result": "pass-no-regression", "log": "gh789-matrix-candidate.log", "environment": "disposable full clone XYZ-forge-gh1269-...-verify at 72be48e2 (identity unchanged before/after, clean); 19/27 ok; the same 8 end-to-end run_main exit-code cases fail identically on baseline"}
+{"timestamp": "2026-10-30T18:00:00Z", "issue": 1269, "gate": "manual-check", "commit": "72be48e2ed2d3d48cf5069907487820414691d6d", "case": "gh789-manual-matrix-baseline", "command": "python3 TESTS-RESULTS/2026-10-05+GH-789/manual_matrix.py (ledger_merge.py checked out from HEAD~1)", "rc": 1, "result": "baseline", "log": "gh789-matrix-baseline.log", "environment": "same verify clone, pre-fix ledger_merge.py; identical 8 failures (DraftCases x5, ChangelogMergeCases run_main x3): pre-existing exit-code drift since GH-944/merge-policy, unrelated to union_changelog"}
diff --git a/TESTS-RESULTS/2026-10-30+GH-1269/red-control-prefix.log b/TESTS-RESULTS/2026-10-30+GH-1269/red-control-prefix.log
new file mode 100644
index 00000000..98418a71
--- /dev/null
+++ b/TESTS-RESULTS/2026-10-30+GH-1269/red-control-prefix.log
@@ -0,0 +1,12 @@
+[FAIL] main: LTVera #874 shape keeps development's same-date order
+       integration same-date order in output: ['GH-867 heartbeat', 'GH-867 QA follow-up', 'GH-866 typing', 'GH-866 store', 'GH-866 resumed', 'GH-776 klaviyo']
+[FAIL] adjacent: attempt 2 on the repaired head does not refuse its own output
+       raised ValueError: changelog preamble or existing history changed
+[FAIL] adjacent: attempt 2 after development gained a section
+       raised ValueError: changelog preamble or existing history changed
+[FAIL] adjacent: block already present on both sides is kept once
+       no duplicate blocks
+[PASS] guard: different bodies under one heading still hand off
+       ValueError: different additions share the same heading
+loaded: skills/2-daily/merge-cleanup/scripts/ledger_merge.py
+result: FAIL (4)
diff --git a/TESTS-RESULTS/2026-10-30+GH-1269/smoke-candidate.log b/TESTS-RESULTS/2026-10-30+GH-1269/smoke-candidate.log
new file mode 100644
index 00000000..ab06bba2
--- /dev/null
+++ b/TESTS-RESULTS/2026-10-30+GH-1269/smoke-candidate.log
@@ -0,0 +1,12 @@
+[PASS] main: LTVera #874 shape keeps development's same-date order
+       integration same-date order in output: ['GH-867 QA follow-up', 'GH-867 heartbeat', 'GH-866 typing', 'GH-866 store', 'GH-866 resumed', 'GH-776 klaviyo']
+[PASS] adjacent: attempt 2 on the repaired head does not refuse its own output
+       re-resolving the repaired head against the same tip is a no-op
+[PASS] adjacent: attempt 2 after development gained a section
+       PR block prepended; new integration text verbatim
+[PASS] adjacent: block already present on both sides is kept once
+       no duplicate blocks
+[PASS] guard: different bodies under one heading still hand off
+       ValueError: different additions share the same heading
+loaded: skills/2-daily/merge-cleanup/scripts/ledger_merge.py
+result: PASS
diff --git a/TESTS-RESULTS/2026-10-30+GH-1269/smoke.md b/TESTS-RESULTS/2026-10-30+GH-1269/smoke.md
new file mode 100644
index 00000000..e2ba609a
--- /dev/null
+++ b/TESTS-RESULTS/2026-10-30+GH-1269/smoke.md
@@ -0,0 +1,20 @@
+# GH-1269 smoke and verification (manual check; no new suite — GH-831)
+
+| Check | Revision | Result | Log |
+|---|---|---|---|
+| Red control: `smoke.py` on pre-fix `ledger_merge.py` | before 72be48e2 | 4 FAIL / 1 PASS: same-date order rewritten; attempt 2 refuses with "changelog preamble or existing history changed" (the LTVera #874 handoff) | `red-control-prefix.log` |
+| Smoke main path (LTVera #874 shape) + 3 adjacent paths + guard | 72be48e2 | 5/5 PASS | `smoke-candidate.log` |
+| GH-789 manual matrix, disposable full clone | 72be48e2 | 19/27 ok; all `ChangelogUnitCases` and the clone-level B1 cases (`test_ledger_plus_changelog_resolves_without_loss`, `test_changelog_only_conflict_and_dry_run`, `test_base_edit_hands_off_before_any_writer_or_file_change`) pass | `gh789-matrix-candidate.log` |
+| GH-789 matrix baseline (pre-fix `ledger_merge.py`, same clone) | HEAD~1 file | identical 8 failures | `gh789-matrix-baseline.log` |
+
+**Main path:** base has history; development adds six 2026-10-29 sections in non-sorted heading order;
+the PR adds one 2026-10-30 section. Output = preamble + PR section + development's text verbatim.
+
+**Adjacent paths:** (a) attempt 2 on the repaired head against the same tip is a no-op instead of a
+refusal; (b) attempt 2 after development gained a section prepends the PR block and keeps the new tip
+verbatim; (c) a block present on both sides (an earlier sync) is kept once.
+
+**Limit:** the matrix's 8 end-to-end `run_main` cases fail identically before and after this change
+(exit-code drift from later features: batch QA exit 4, merge-policy output). They are an unregistered
+GH-789 evidence script, not a gate; this change does not touch `run_main`. The end-to-end landing is
+covered by the full pre-push gate's registered merge-cleanup suites.
diff --git a/TESTS-RESULTS/2026-10-30+GH-1269/smoke.py b/TESTS-RESULTS/2026-10-30+GH-1269/smoke.py
new file mode 100644
index 00000000..78741be2
--- /dev/null
+++ b/TESTS-RESULTS/2026-10-30+GH-1269/smoke.py
@@ -0,0 +1,105 @@
+"""GH-1269 manual smoke (GH-1088; evidence script, NOT a registered suite — GH-831).
+
+Usage: python3 smoke.py [<ledger_merge.py to load>]   (default: this checkout's copy)
+
+Drives ledger_merge.union_changelog the way B1 calls it (base = merge base, ours = PR head,
+theirs = integration tip; merge_cleanup.py merges origin/<integration> into the PR clone).
+The fixture mirrors LTVera PR #874: the integration side added six same-date sections in an
+order that is not descending by heading text; the PR added one newer section.
+Exit 0 only when every case passes.
+"""
+import importlib.util
+import os
+import sys
+
+HERE = os.path.dirname(os.path.abspath(__file__))
+REPO = os.path.dirname(os.path.dirname(HERE))
+path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
+    REPO, "skills", "2-daily", "merge-cleanup", "scripts", "ledger_merge.py")
+sys.path.insert(0, os.path.dirname(os.path.abspath(path)))
+spec = importlib.util.spec_from_file_location("ledger_merge_under_test", path)
+lm = importlib.util.module_from_spec(spec)
+spec.loader.exec_module(lm)
+
+PRE = "# Changelog\n\nIntro line.\n\n"
+OLD = "## 2026-10-28 — older entry\n\nOlder bytes stay exact.\n"
+
+
+def sec(heading, body):
+    return f"## {heading}\n\n{body}\n\n"
+
+
+# Integration (development 3c936bea) order, copied from the #1269 heading table shape.
+DEV_ADDS = "".join([
+    sec("2026-10-29 — GH-867 QA follow-up", "867 QA."),
+    sec("2026-10-29 — GH-867 heartbeat", "867."),
+    sec("2026-10-29 — GH-866 typing", "866 typing."),
+    sec("2026-10-29 — GH-866 store", "866."),
+    sec("2026-10-29 — GH-866 resumed", "866 resumed."),
+    sec("2026-10-29 — GH-776 klaviyo", "776."),
+])
+PR_ADD = sec("2026-10-30 — GH-818 landing", "818.")
+
+base = PRE + OLD
+theirs = PRE + DEV_ADDS + OLD
+ours = PRE + PR_ADD + OLD
+expected = PRE + PR_ADD + DEV_ADDS + OLD
+
+failures = 0
+
+
+def case(label, fn):
+    global failures
+    try:
+        ok, detail = fn()
+    except Exception as exc:  # a refusal is a result to report, not a crash
+        ok, detail = False, f"raised {type(exc).__name__}: {exc}"
+    failures += 0 if ok else 1
+    print(f"[{'PASS' if ok else 'FAIL'}] {label}\n       {detail}")
+
+
+def main_path():
+    out = lm.union_changelog(base, ours, theirs)
+    heads = [l[3:].split(" — ")[1] for l in out.splitlines() if l.startswith("## 2026-10-29")]
+    return out == expected, f"integration same-date order in output: {heads}"
+
+
+def next_attempt():
+    # Attempt 2: the merge base is now the integration tip; theirs is unchanged.
+    first = lm.union_changelog(base, ours, theirs)
+    again = lm.union_changelog(theirs, first, theirs)
+    return again == first, "re-resolving the repaired head against the same tip is a no-op"
+
+
+def next_attempt_with_new_integration_section():
+    # Adjacent: integration moved on with one more section before attempt 2.
+    first = lm.union_changelog(base, ours, theirs)
+    theirs2 = PRE + sec("2026-10-30 — GH-880 later", "880.") + DEV_ADDS + OLD
+    out = lm.union_changelog(theirs, first, theirs2)
+    return out == PRE + PR_ADD + theirs2[len(PRE):], "PR block prepended; new integration text verbatim"
+
+
+def identical_on_both_sides():
+    # The PR already carries an integration addition byte-for-byte (an earlier sync): not duplicated.
+    ours_synced = PRE + PR_ADD + DEV_ADDS + OLD
+    out = lm.union_changelog(base, ours_synced, theirs)
+    return out == expected and out.count("818.") == 1 and out.count("776.") == 1, "no duplicate blocks"
+
+
+def divergent_same_heading_still_hands_off():
+    ours_bad = PRE + sec("2026-10-29 — GH-776 klaviyo", "different body.") + OLD
+    try:
+        lm.union_changelog(base, ours_bad, theirs)
+    except ValueError as exc:
+        return "same heading" in str(exc), f"ValueError: {exc}"
+    return False, "no refusal"
+
+
+case("main: LTVera #874 shape keeps development's same-date order", main_path)
+case("adjacent: attempt 2 on the repaired head does not refuse its own output", next_attempt)
+case("adjacent: attempt 2 after development gained a section", next_attempt_with_new_integration_section)
+case("adjacent: block already present on both sides is kept once", identical_on_both_sides)
+case("guard: different bodies under one heading still hand off", divergent_same_heading_still_hands_off)
+print(f"loaded: {os.path.relpath(path, REPO) if path.startswith(REPO) else path}")
+print(f"result: {'PASS' if failures == 0 else f'FAIL ({failures})'}")
+sys.exit(1 if failures else 0)
diff --git a/releases.sql b/releases.sql
index 5f50a5ed..75fd86f3 100644
--- a/releases.sql
+++ b/releases.sql
@@ -1,6 +1,6 @@
 -- releases-app canonical dump (GH-32 grammar: GID-keyed rows, natural keys elsewhere,
 -- no integer PKs/FKs as values; rebuild renumbers deterministically)
--- generation: 2146
+-- generation: 2149
 -- table: schema_migrations
 INSERT INTO schema_migrations(version, applied_at) VALUES('1', '2026-08-19T01:32:22Z');
 INSERT INTO schema_migrations(version, applied_at) VALUES('2', '2026-08-19T18:55:40Z');
@@ -13,7 +13,7 @@ INSERT INTO schema_migrations(version, applied_at) VALUES('8', '2026-09-12T16:07
 INSERT INTO schema_migrations(version, applied_at) VALUES('9', '2026-09-23T01:01:18Z');
 -- table: settings
 INSERT INTO settings(key, value, updated_at) VALUES('enforcement', 'lenient', '2026-09-08T05:45:05Z');
-INSERT INTO settings(key, value, updated_at) VALUES('generation', '2146', '2026-10-30T17:34:22Z');
+INSERT INTO settings(key, value, updated_at) VALUES('generation', '2149', '2026-10-30T17:41:18Z');
 INSERT INTO settings(key, value, updated_at) VALUES('repo_slug', 'XYZ-forge', '2026-09-08T05:45:05Z');
 -- table: repos
 INSERT INTO repos(global_id, slug, updated_at) VALUES('repo-01M0BTBRJ0PZF51EK6PCRJ20FS', 'XYZ-forge', '2026-09-08T05:45:05Z');
@@ -935,7 +935,7 @@ INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, positi
 INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M66VDQ621XQAJSECT2WG83WN', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '1265', 'consult: add the installed kimi and cmd seats so a degraded pair can be re-fired without API keys', 'Queue / parked intake', '136', '🆕', NULL, NULL, NULL, 'PROJECT/1-INBOX/GH-1265-CONSULT-INSTALLED-KIMI-CMD.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/1265', '- **GH-1265 · consult: add the installed kimi and cmd seats so a degraded pair can be re-fired without API keys** 🆕 **captured 2026-10-30 via HQ** — [GH-1265-CONSULT-INSTALLED-KIMI-CMD.md](PROJECT/1-INBOX/GH-1265-CONSULT-INSTALLED-KIMI-CMD.md) · [#1265](https://github.com/HiQS-Labs/XYZ-forge/issues/1265) (rated 50/40/50/70)', '2026-10-30T16:48:53Z', '2026-10-30T16:48:54Z', '50', '40', '50', '70', NULL, NULL);
 INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M66VDWSN7AA86YJ53T6DKQEH', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '1266', 'ARCHITECTURE.md Skills Index drift: weekly-planner has no row and the hand-typed tier counts are stale', 'Queue / parked intake', '137', '🆕', NULL, NULL, NULL, 'PROJECT/1-INBOX/GH-1266-ARCHITECTURE-MD-SKILLS-INDEX.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/1266', '- **GH-1266 · ARCHITECTURE.md Skills Index drift: weekly-planner has no row and the hand-typed tier counts are stale** 🆕 **captured 2026-10-30 via HQ** — [GH-1266-ARCHITECTURE-MD-SKILLS-INDEX.md](PROJECT/1-INBOX/GH-1266-ARCHITECTURE-MD-SKILLS-INDEX.md) · [#1266](https://github.com/HiQS-Labs/XYZ-forge/issues/1266) (rated 30/20/50/95)', '2026-10-30T16:48:59Z', '2026-10-30T16:49:00Z', '30', '20', '50', '95', NULL, NULL);
 INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M66VJBQ80DYFWWDER0SEZJXP', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '1267', 'hq park --gh-issue: register an already-filed issue (capture + ledger row) without creating a new one', 'Queue / parked intake', '138', '🆕', NULL, NULL, NULL, 'PROJECT/1-INBOX/GH-1267-HQ-PARK-GH-ISSUE.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/1267', '- **GH-1267 · hq park --gh-issue: register an already-filed issue (capture + ledger row) without creating a new one** 🆕 **captured 2026-10-30 via HQ** — [GH-1267-HQ-PARK-GH-ISSUE.md](PROJECT/1-INBOX/GH-1267-HQ-PARK-GH-ISSUE.md) · [#1267](https://github.com/HiQS-Labs/XYZ-forge/issues/1267) (rated 70/50/50/75)', '2026-10-30T16:51:26Z', '2026-10-30T16:51:26Z', '70', '50', '50', '75', NULL, NULL);
-INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M66X29J6REH7QEQ90GFVWW26', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '1269', 'merge-cleanup B1 CHANGELOG repair reorders existing same-date sections', 'Queue / parked intake', '139', '🆕', NULL, NULL, NULL, 'PROJECT/1-INBOX/GH-1269-B1-CHANGELOG-REORDER.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/1269', '- **GH-1269 — merge-cleanup B1 CHANGELOG repair reorders existing same-date sections** (2026-10-30) - a resolved B1 repair reorders development''s same-date CHANGELOG sections, then the next B1 refuses its own output and burns the two-repair budget. Bug filed via /file-xyz-bug from `LTVera-Pandas`. Issue [#1269](https://github.com/HiQS-Labs/XYZ-forge/issues/1269). -> [PROJECT/1-INBOX/GH-1269-B1-CHANGELOG-REORDER.md](PROJECT/1-INBOX/GH-1269-B1-CHANGELOG-REORDER.md)', '2026-10-30T17:17:36Z', '2026-10-30T17:17:36Z', NULL, NULL, NULL, NULL, NULL, NULL);
+INSERT INTO roadmap_items(global_id, repo_gid, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at, rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr, status_label) VALUES('rmi-01M66X29J6REH7QEQ90GFVWW26', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '1269', 'merge-cleanup B1 CHANGELOG repair reorders existing same-date sections', 'In progress', '139', '🚧', NULL, NULL, NULL, 'PROJECT/2-WORKING/GH-1269-B1-CHANGELOG-REORDER.md', 'https://github.com/HiQS-Labs/XYZ-forge/issues/1269', '- **GH-1269 — merge-cleanup B1 CHANGELOG repair reorders existing same-date sections** (2026-10-30) - a resolved B1 repair reorders development''s same-date CHANGELOG sections, then the next B1 refuses its own output and burns the two-repair budget. Bug filed via /file-xyz-bug from `LTVera-Pandas`. Issue [#1269](https://github.com/HiQS-Labs/XYZ-forge/issues/1269). -> [PROJECT/2-WORKING/GH-1269-B1-CHANGELOG-REORDER.md](PROJECT/2-WORKING/GH-1269-B1-CHANGELOG-REORDER.md) (rated 65/60/50/85)', '2026-10-30T17:17:36Z', '2026-10-30T17:41:18Z', '65', '60', '50', '85', NULL, 'in-progress');
 -- table: jog_queue
 INSERT INTO jog_queue(global_id, repo_gid, gh_number, position, status, created_at, updated_at, attempt_count, lease_pid, failure_reason) VALUES('jog-01M122D1G6F8AWEKQHKFPCFD37', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '275', '1', 'completed', '2026-08-27T16:56:10Z', '2026-08-27T18:11:04Z', '5', NULL, 'preflight: already-landed');
 INSERT INTO jog_queue(global_id, repo_gid, gh_number, position, status, created_at, updated_at, attempt_count, lease_pid, failure_reason) VALUES('jog-01M122D1WM4Z659A8N591AR0H8', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '269', '1', 'failed', '2026-08-27T16:56:10Z', '2026-08-27T18:39:22Z', '3', NULL, 'drive failed (exit 7)');
@@ -3360,6 +3360,9 @@ INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_bef
 INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-repoint', 'rmi-01M66JN1MEY3HQ6GE9XGX5NZQZ', '2026-10-30T17:20:06Z', '756690c078764b88b513e6329de1dd71', 'default', '7aef307b9f70fc9e3d41791c76ecc0f3d8630cb9df12800c8180f7f77915eb75', 'd308001ad8550ef05f6d6f4f473debd8e1a1ef7530405af651e84cadeeedf730');
 INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-update', 'rmi-01M66JN1MEY3HQ6GE9XGX5NZQZ', '2026-10-30T17:20:06Z', 'fd54cfc73e8146a0bebed3e4241eb03a', 'default', 'd308001ad8550ef05f6d6f4f473debd8e1a1ef7530405af651e84cadeeedf730', '3f83327c18cf0444f1aae3cd2e9b9d5699207275b811c4356b33676c67a3b76a');
 INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('merge-rebuild', 'reanchor:243', '2026-10-30T17:34:22Z', '6a4563041bc246cc9c6c51381cb5effc', 'default', 'd221373ea41512e96c5b869f3d991af173f54789a17d34de3ae5b9cc021edfee', 'cb8d2ef78a1aed8666d0bb0a78401db28d559ca01ffc61e06ff57dd19a9f4ba7');
+INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-repoint', 'rmi-01M66X29J6REH7QEQ90GFVWW26', '2026-10-30T17:37:37Z', 'eb2854209bf846efbbf007300f741b67', 'default', 'cb8d2ef78a1aed8666d0bb0a78401db28d559ca01ffc61e06ff57dd19a9f4ba7', '4a29a9efb8e2f53081833ed2c7591eda6fe432fad9d017d2142e6e5914a9b4a7');
+INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-rate', 'rmi-01M66X29J6REH7QEQ90GFVWW26', '2026-10-30T17:37:37Z', 'febbfc0b2ce744f4877877c1e9145b96', 'default', '4a29a9efb8e2f53081833ed2c7591eda6fe432fad9d017d2142e6e5914a9b4a7', '5c06d70199f0eddaa23f886aa34f767fe9028c464ee4c2e3629d13001c15e586');
+INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id, state_digest_before, state_digest_after) VALUES('roadmap-update', 'rmi-01M66X29J6REH7QEQ90GFVWW26', '2026-10-30T17:41:18Z', 'e9719a93fe3f4446b7060a2d33dbcd53', 'default', '5c06d70199f0eddaa23f886aa34f767fe9028c464ee4c2e3629d13001c15e586', '4e552448b2c95f4ae9fe37f886b560eae72abcdd467c29e0993265ecb982b073');
 -- table: work_events
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M2CBC3C2HSWRSBY81TAZHYY0', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '568', 'df2ee890077d486dbe23311c5dd74d82', 'updated', '{"marker": "\u2705", "section": "Completed"}', '2026-09-13T03:01:02Z');
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M2CGH1A7Z979TG5DQJHN8DX6', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '591', '6d3d7a7619c247b5a85a039ea98756bd', 'parked', '{"section": "Queue / parked intake"}', '2026-09-13T04:31:07Z');
@@ -4510,3 +4513,5 @@ INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload,
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M66X29JQWR88GQYTBFP07JVX', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '1269', '0735066df5804d63b1867adacf3160aa', 'parked', '{"section": "Queue / parked intake"}', '2026-10-30T17:17:36Z');
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M66X6VY5B13EC1JCBX9MBYFG', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '1257', '136b27fc1fff4c728c7c21b4e0ba6c16', 'completed', '{"marker": "\u2705", "section": "Completed", "source": "roadmap-update", "transition": true}', '2026-10-30T17:20:06Z');
 INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M66X6W8NQXCC06APW1QBYBXD', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '1261', 'fd54cfc73e8146a0bebed3e4241eb03a', 'completed', '{"marker": "\u2705", "section": "Completed", "source": "roadmap-update", "transition": true}', '2026-10-30T17:20:06Z');
+INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M66Y6Y989RY5GVM4G9VS6B0W', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '1269', 'febbfc0b2ce744f4877877c1e9145b96', 'rated', '{"rated": "65/60/50/85"}', '2026-10-30T17:37:37Z');
+INSERT INTO work_events(global_id, repo_gid, gh_number, txn_id, event, payload, at) VALUES('wev-01M66YDNMJ66E0YS6JXERAZKZ9', 'repo-01M0BTBRJ0PZF51EK6PCRJ20FS', '1269', 'e9719a93fe3f4446b7060a2d33dbcd53', 'in_flight', '{"accepted_start": true, "marker": "\ud83d\udea7", "section": "In progress", "source": "roadmap-update", "transition": true}', '2026-10-30T17:41:18Z');
diff --git a/skills/2-daily/merge-cleanup/scripts/ledger_merge.py b/skills/2-daily/merge-cleanup/scripts/ledger_merge.py
index 0614af3f..7da34b68 100644
--- a/skills/2-daily/merge-cleanup/scripts/ledger_merge.py
+++ b/skills/2-daily/merge-cleanup/scripts/ledger_merge.py
@@ -447,7 +447,11 @@ def ledger_semantic_check(clone: Path, integration_branch: str = "development")
 
 
 def union_changelog(base: str, ours: str, theirs: str) -> str:
-    """Resolve only complete prepended dated blocks; historical bytes are never rewritten."""
+    """Resolve only complete prepended dated blocks; historical bytes are never rewritten.
+
+    ours is the PR head and theirs the integration tip (the landing merges origin/<integration>
+    into the PR clone). The PR's new blocks are prepended in their own order and theirs is kept
+    verbatim after the preamble, so the next attempt's history check accepts this output (GH-1269)."""
     if not all((base, ours, theirs)) or any(re.search(r"(?m)^(?:<{7}|={7}|>{7}|\|{7})(?: |$)", t)
                                           for t in (base, ours, theirs)):
         raise ValueError("empty changelog or conflict markers")
@@ -457,6 +461,7 @@ def union_changelog(base: str, ours: str, theirs: str) -> str:
     preamble, history = base[:first.start()], base[first.start():]
     historical_headings = set(re.findall(r"(?m)^## [^\r\n]+", history))
     blocks = {}
+    ordered = []
     for text in (ours, theirs):
         if not text.startswith(preamble) or not text.endswith(history):
             raise ValueError("changelog preamble or existing history changed")
@@ -469,6 +474,7 @@ def union_changelog(base: str, ours: str, theirs: str) -> str:
         if additions and (not starts or starts[0].start() != 0):
             raise ValueError("additions are not complete sections")
         seen = set()
+        ordered.append([])
         for i, match in enumerate(starts):
             block = additions[match.start():starts[i + 1].start() if i + 1 < len(starts) else len(additions)]
             heading, newline, body = block.partition("\n")
@@ -485,9 +491,10 @@ def union_changelog(base: str, ours: str, theirs: str) -> str:
             if heading in blocks and blocks[heading] != block:
                 raise ValueError("different additions share the same heading")
             blocks[heading] = block
+            ordered[-1].append(block)
     if not blocks:
         raise ValueError("no additive sections extracted")
-    return preamble + "".join(blocks[h] for h in sorted(blocks, reverse=True)) + history
+    return preamble + "".join(b for b in ordered[0] if b not in ordered[1]) + theirs[len(preamble):]
 
 
 def read_changelog_union(clone: Path) -> str:
```

# Turns


## Codex reviewer — 2026-10-30

Ship within this final-QA scope. No blocking findings. Reversibility: **Easy**, a single-function assembly revert; no persisted-format or repair-budget change.

- **[Pass] Assembly and call contract.** merge_cleanup.py:548-553 checks out the PR head and merges origin/integration into it; ledger_merge.py:500-511 supplies (merge-base, HEAD, MERGE_HEAD). At ledger_merge.py:449-497, both inputs undergo every existing validation before assembly. The added lists retain parsed blocks in encounter order. The return prepends PR blocks absent by exact string equality from integration additions, then copies theirs[len(preamble):] verbatim. The cross-side heading/body check still rejects divergent bodies before deduplication.
- **[Unverified — no citation] Root cause and retry.** Root cause: sorting both sides' additions rewrote integration history; fix site: union_changelog assembly; why not upstream/downstream: the input revisions and history refusal are correct, while this resolver produced the invalid ordering. The probe below preserves multiple PR blocks, shared blocks, UTF-8/CRLF history, unchanged-tip retries, and advanced-tip retries. Restoring the old assembly in memory reproduces the changed suffix and next-attempt refusal. All 12 invalid inputs reject with identical exception messages under both assemblies.
- **[Unverified — no citation] Evidence and matrix disposition.** All seven evidence files are nonempty. Four provenance rows parse and reference nonempty logs. Smoke receipts record pre-fix exit 1 (four failures; divergence guard passes) and candidate exit 0 (five passes). The paired matrix logs each record 27 cases and eight failures; provenance records exit 1 for each. Extracted failing names and assertion messages match exactly: five DraftCases, three ChangelogMergeCases, no ChangelogUnitCases failures. This supports **no observed regression**, not a green matrix or proof that every landing path succeeds. The matrix logs and provenance are present in the seeded index (direct read of v2 entries; no git command).
- **[Unverified — no citation] Scope and rating.** The supplied diff extends the existing resolver without a duplicate writer, new test/ file, registered suite, registry entry, or gate machinery. The TESTS-RESULTS smoke script is permitted recorded manual evidence. Rating **65/60/50/85** remains proportionate to a recoverable landing interruption consuming the two-repair budget and a small fix. Issue-search recurrence counts were not independently established this turn.

**[Unverified — needs clone run]** The final committed-state full gate and required doc checks remain for the enclosing harness. The plan's “all cases green” matrix expectation was not achieved; the paired baseline disposition above explicitly limits the verification claim. No validate.sh, test/*.sh, pytest, executable fixture, or git command was run here.

### Pure-function probe receipt

Command (exit **0**): export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 "$TMPDIR/gh1269-review-probe.py"

The scratch script was exactly:

```python
import ast
import re
from datetime import date
from pathlib import Path
p = Path("skills/2-daily/merge-cleanup/scripts/ledger_merge.py")
tree = ast.parse(p.read_text())
node = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "union_changelog")
source = ast.get_source_segment(p.read_text(), node)
env = {"re": re, "date": date}
exec(compile(ast.Module(body=[node], type_ignores=[]), str(p), "exec"), env)
u = env["union_changelog"]
old = source.replace("    ordered = []\n", "").replace("        ordered.append([])\n", "").replace("            ordered[-1].append(block)\n", "").replace('return preamble + "".join(b for b in ordered[0] if b not in ordered[1]) + theirs[len(preamble):]', 'return preamble + "".join(blocks[h] for h in sorted(blocks, reverse=True)) + history')
old_env = {"re": re, "date": date}
exec(old, old_env)
pre = "# Changelog\n\nIntro.\n\n"
hist = "## 2026-10-28 — history\r\n\r\nExact café bytes.\r\n"
def sec(name, body="body"):
    return f"## 2026-10-29 — {name}\n\n{body}\n\n"
a, z, pr, pr2 = map(sec, ("A", "Z", "PR", "PR2"))
base = pre + hist
ours = pre + pr + pr2 + a + hist
theirs = pre + a + z + hist
expected = pre + pr + pr2 + a + z + hist
assert all((base, ours, theirs))
out = u(base, ours, theirs)
assert out.encode() == expected.encode()
assert out.endswith(theirs[len(pre):])
assert u(theirs, out, theirs) == out
theirs2 = pre + sec("NEW") + a + z + hist
assert u(theirs, out, theirs2) == pre + pr + pr2 + theirs2[len(pre):]
assert u(base, base, theirs) == theirs
assert u(base, pre + pr + hist, base) == pre + pr + hist
assert u(base, pre + z + a + hist, theirs) == theirs
print("candidate: PR order, integration UTF-8/CRLF bytes, dedup, retry, advanced-tip retry, one-sided additions PASS")
old_out = old_env["union_changelog"](base, ours, theirs)
assert old_out != expected and not old_out.endswith(theirs[len(pre):])
try:
    old_env["union_changelog"](theirs, old_out, theirs)
except ValueError as e:
    assert str(e) == "changelog preamble or existing history changed"
    print("red control (old sorted assembly): changed integration suffix; retry refused:", e)
else:
    raise AssertionError("red control did not refuse")
bad = [
    ("empty", "", ours, theirs),
    ("marker", base, pre + "<<<<<<< ours\n" + hist, theirs),
    ("history-edit", base, ours.replace("Exact", "Changed"), theirs),
    ("preamble-edit", base, ours.replace("Intro.", "Changed."), theirs),
    ("fence", base, pre + sec("F", "```\n## fake\n```") + hist, theirs),
    ("html", base, pre + sec("H", "<!-- hidden -->") + hist, theirs),
    ("incomplete", base, pre + "loose\n" + pr + hist, theirs),
    ("bad-date", base, pre + pr.replace("2026-10-29", "2026-02-30") + hist, theirs),
    ("duplicate", base, pre + pr + pr + hist, theirs),
    ("same-heading-different-body", base, pre + sec("A", "changed") + hist, theirs),
    ("historical-heading", base, pre + hist + hist, theirs),
    ("no-additions", base, base, base),
]
for label, b, o, t in bad:
    messages = []
    for fn in (u, old_env["union_changelog"]):
        try:
            fn(b, o, t)
        except ValueError as e:
            messages.append(str(e))
        else:
            raise AssertionError(label + " was accepted")
    assert messages[0] == messages[1], (label, messages)
print("refusals: 12/12 reject identically under candidate and old assembly")
```

Decisive output:

```text
candidate: PR order, integration UTF-8/CRLF bytes, dedup, retry, advanced-tip retry, one-sided additions PASS
red control (old sorted assembly): changed integration suffix; retry refused: changelog preamble or existing history changed
refusals: 12/12 reject identically under candidate and old assembly
```

### Receipt-comparison probe

The following narrow extraction was run with PYTHONDONTWRITEBYTECODE=1 (exit **0**); it reads the two existing logs and JSONL only:

```python
from pathlib import Path
import re, json
d=Path('TESTS-RESULTS/2026-10-30+GH-1269')
print('artifact_sizes:', {p.name:p.stat().st_size for p in sorted(d.iterdir()) if p.is_file()})
failures=[]
for side in ('candidate','baseline'):
    s=(d/f'gh789-matrix-{side}.log').read_text()
    names=re.findall(r'^FAIL: (.+)$',s,re.M)
    assertions=re.findall(r'^AssertionError: (.+)$',s,re.M)
    print(side, 'failures=',len(names), 'summary=',re.findall(r'^(?:Ran \d+ tests.*|FAILED.*)$',s,re.M))
    print(side, 'names=',names)
    print(side, 'assertions=',assertions)
    failures.append((names,assertions))
print('identical_failure_names_and_assertions:',failures[0]==failures[1])
rows=[json.loads(l) for l in (d/'provenance.jsonl').read_text().splitlines()]
print('provenance:',[(r['case'],r['rc'],(d/r['log']).is_file()) for r in rows])
print('provenance_rows_nonempty:',len(rows)==4 and all((d/r['log']).stat().st_size for r in rows))
```

Command: python3 - <<'PY' followed by the snippet above and its PY terminator. Decisive output:

```text
candidate failures= 8 summary= ['Ran 27 tests in 39.541s', 'FAILED (failures=8)']
baseline failures= 8 summary= ['Ran 27 tests in 37.992s', 'FAILED (failures=8)']
identical_failure_names_and_assertions: True
provenance_rows_nonempty: True
```

VERDICT: PASS
Basis: Source trace, isolated-function execution, the witnessed old-assembly red control, unchanged refusals, and retained paired receipts substantiate the approved assembly fix. Matrix drift is disclosed; final committed-state clone gates remain outstanding.
