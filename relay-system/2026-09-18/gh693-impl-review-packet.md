# GH-693 implementation review packet — landed commit 989f5549 on `development`

Goal: adjudicate the LANDED implementation of GH-693 (Lessons Learned demoted from a promotion gate to a
highly-recommended, WARN-only section) against its QA'd plan (`relay-system/2026-09-18/gh693-plan.md`,
agy PASS in `gh693-plan-qa.md`) and against the repo's rules (AGENTS.md, SOP.md, GUIDING-PRINCIPLES.md).

Operational envelope: a single-repo governance script (`utils/py/wave_reconcile.py`, ~2100 lines) run by
the hosted `wave-reconcile.yml` lane and by `/express` / `/merge-cleanup` locally. Machinery and tests must
stay commensurate; do not ask for new flags, new modules, or enterprise fail-safes. Non-goals: un-ignoring
anything, changing frontmatter validation, touching `.github/workflows/`, `utils/py/hosted_lane_report.py`
or `utils/py/express.py`.

The worktree you are in is `development` at or after 7f76674b, so every file below is the landed state —
read the real files, not only this diff. The full diff of the landed commit (minus ledger artifacts) is at
the end of this packet.

Files to read in full:
- utils/py/wave_reconcile.py — `validate_lessons_learned` (~L931), `warn_lessons_learned` + `WARN_MARKER`
  (~L958), `validate_and_update_doc` (~L1010), the `--pre-merge` block (~L1790), the catch-up block (~L2040)
- test/gh693-lessons-learned-advisory.sh (new, registered in validate.sh)
- test/wave-reconcile.sh (Test 4 flipped), test/gh496-phase2-reconciliation-views.sh (Case B flipped),
  test/gh421-auto-wave-reconcile.sh (three GH-684 tests rewritten, ~L283-345)
- PROJECT/PDDA.md (rule 8 → "Highly recommended"), HOW-TO-USE.md ~L26, skills/express/SKILL.md ~L117,
  sentinel-overlay/pr-emit.sh ~L36

Questions (answer each; cite file:line):

1. Correctness of the three call sites: is there ANY remaining path in wave_reconcile.py where a missing or
   placeholder Lessons Learned section causes a non-zero exit, a `die`, a `SKIPPED` line, or a skipped
   lifecycle write? (`rg -n "validate_lessons_learned|warn_lessons_learned|SKIP_MARKER" utils/py/wave_reconcile.py`)
2. Dead machinery: the GH-684 skip-and-report shape (`SKIP_MARKER`, `skipped_issues`, `explicit_items`,
   the end-of-run "backlog item(s) skipped" summary, `hosted_lane_report.py`'s SKIPPED parsing) now has no
   trigger. The producer kept it deliberately (capture doc, Lessons Learned bullet 3). Is keeping it the
   right call under GUIDING-PRINCIPLES (durable/reversible/DRY) and /ponytail, or should it be removed in a
   follow-up? If removed, what would break (`test/gh684-hosted-lane-report.sh`, the hosted lane's issue
   #691 self-close contract)? Recommend one, with the falsifier.
3. Ownership semantics change: a lessons-less backlog doc is now IN the reconciler's ownership set, so its
   planner drift is attributable and fatal (`test_planner_drift_for_a_lessons_less_issue_is_owned`, exit 6,
   rolled back). Is that the correct consequence, or does it re-create the #691 shape (a doc that reds the
   lane every run for a reason unrelated to the merge)? Observed input to consider: the four #691 docs
   (GH-505/509/609/642) also appeared in the run's "pre-existing unrelated drift" list.
4. Test quality: does `test/gh693-lessons-learned-advisory.sh` actually fail on the parent commit (which
   assertion, and is that enough — it fails at A's first assertion and `fail` exits the suite, so B–F are
   never proven red)? Are the flipped tests weaker than what they replaced anywhere (e.g. wave-reconcile.sh
   Test 4 now uses `--dry-run`)? Is Case C in the new suite (`--pre-merge`) a real pin given the receipt
   commit shape?
5. Wording: do PDDA.md, HOW-TO-USE.md, express SKILL.md and pr-emit.sh now say the same thing? Any other doc
   in the tree still calls the section mandatory/required? (`rg -n "Lessons Learned" --glob '!PROJECT/**'
   --glob '!relay-system/**' --glob '!marathon-system/**' --glob '!CHANGELOG.md'`)
6. Commensurate complexity: is anything here over- or under-built for a WARN-only advisory? Flag any
   speculative abstraction.

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with file:line or a quoted span;
`swept file: yes|no`; a VERDICT (PASS/FAIL/PARKED) with Basis. `[Blocker]`/`[Should]` behaviour changes carry
`Observed input:`, `Affected scope:`, `Falsifier:` (GH-681).

---

## Landed diff (989f5549, code/tests/docs only)

```diff
commit 989f55496ea5d36f144d63fc937169b372b68ff1
Author: Noel Saw <56978803+noelsaw1@users.noreply.github.com>
Date:   Fri Sep 18 07:55:57 2026 -0700

    fix(GH-693): Lessons Learned: make the capture-doc section optional (highly recommended), not a promotion gate [express]
    
    Express lane (GH-267): fix + suite + born-complete doc + CHANGELOG in one motion.
    
    Closes #693

diff --git a/HOW-TO-USE.md b/HOW-TO-USE.md
index 8788d06b..71eb6dd4 100644
--- a/HOW-TO-USE.md
+++ b/HOW-TO-USE.md
@@ -23,9 +23,10 @@ never duplicating either's state by hand, and letting each oracle catch the othe
   shipping evidence was deferred — the op_receipts audit trail is only as good as its timeliness.
 - **Never hand-edit `ROADMAP.md` ledger rows, `releases.sql`, or the DB.** Every hand edit breaks
   the DB↔dump↔generated triangle that `releases check` guards. Verbs only.
-- **At merge time**, the rhythm is mechanized (`wave_reconcile.py --pr N`) — remember the two
-  gates: capture docs need their Lessons Learned section *before* merge, and PR bodies citing a
-  foreign tracker need an offline `issues[]` manifest.
+- **At merge time**, the rhythm is mechanized (`wave_reconcile.py --pr N`) — remember the gate:
+  PR bodies citing a foreign tracker need an offline `issues[]` manifest. A capture doc's
+  `## Lessons Learned (For Future Agents)` section is *highly recommended* (the reconciler warns
+  when it is missing or a placeholder) but never blocks promotion (GH-693).
 - **For the immediate "run today" queue**, use jog once landed (GH-259 Phase 1): `jog GH-<n>`
   queues without wave-planning ceremony; full contracts are owed at fire time, not capture time.
 
diff --git a/PROJECT/PDDA.md b/PROJECT/PDDA.md
index b12f7d7c..0a0e58d6 100644
--- a/PROJECT/PDDA.md
+++ b/PROJECT/PDDA.md
@@ -66,7 +66,11 @@ Every doc in `PROJECT/2-WORKING` should have:
 6. for any discovery or spike phase, its findings written **back into this doc** before its QA gate can
    pass (see [Discovery & spike phases (Memory Injection)](#discovery--spike-phases-memory-injection))
 7. repo-relative paths only; no hardcoded absolute local paths
-8. before moving to `PROJECT/3-COMPLETED`, a `## Lessons Learned (For Future Agents)` section appended to capture quirks and gotchas
+
+**Highly recommended** (not a gate since GH-693): before moving to `PROJECT/3-COMPLETED`, a
+`## Lessons Learned (For Future Agents)` section capturing quirks and gotchas. `wave_reconcile.py`
+warns when it is missing or a placeholder and promotes the doc anyway — the warning is in every
+hosted-lane log, so a doc without one is visible, never blocked.
 
 Recommended fields when relevant:
 
diff --git a/sentinel-overlay/pr-emit.sh b/sentinel-overlay/pr-emit.sh
index 1ca67633..130fdfb6 100755
--- a/sentinel-overlay/pr-emit.sh
+++ b/sentinel-overlay/pr-emit.sh
@@ -33,5 +33,5 @@ sentinel_gh pr create --base "$BASE" --head "$BRANCH" --title "$title" \
 if [ -n "$DOC" ] && [ -f "$DOC" ]; then
   mkdir -p PROJECT/3-COMPLETED
   git mv "$DOC" "PROJECT/3-COMPLETED/$(basename "$DOC")" 2>/dev/null || mv "$DOC" "PROJECT/3-COMPLETED/$(basename "$DOC")"
-  echo "pr-emit: moved $(basename "$DOC") → 3-COMPLETED (add a ## Lessons Learned before completion)"
+  echo "pr-emit: moved $(basename "$DOC") → 3-COMPLETED (a ## Lessons Learned section is highly recommended)"
 fi
diff --git a/skills/express/SKILL.md b/skills/express/SKILL.md
index 854ceede..165b1508 100644
--- a/skills/express/SKILL.md
+++ b/skills/express/SKILL.md
@@ -118,7 +118,8 @@ What each phase asserts (all refusals and fired runs write `.tick/events/*` and
    `validate.sh` TESTS. A hotfix without its suite is a claim, not a fix.
 5. **Docs born complete** — capture doc scaffolded in `2-WORKING` with Status,
    Acceptance, Merge evidence, and `## Lessons Learned (For Future Agents)`
-   present from birth (the 08-26 reconcile gate refuses promotion otherwise),
+   present from birth (highly recommended — since GH-693 the reconciler warns
+   rather than refuses promotion when it is missing; fill it in anyway),
    plus the CHANGELOG entry appended in the same motion.
 6. **Ledger** — `roadmap add` if the issue is unparked, then `manifest dial-in`
    against the active release (`releases next`) with an express reason. The
diff --git a/test/gh421-auto-wave-reconcile.sh b/test/gh421-auto-wave-reconcile.sh
index 5d049273..93c696b7 100755
--- a/test/gh421-auto-wave-reconcile.sh
+++ b/test/gh421-auto-wave-reconcile.sh
@@ -302,42 +302,40 @@ class ReconcileTests(unittest.TestCase):
     def manifest_states(self):
         return [row['state'] for row in self.rows('SELECT state FROM manifest_items ORDER BY id')]
 
-    def test_catch_up_skips_defective_backlog_doc_reports_it_and_retries(self):
+    # GH-693: Lessons Learned is advisory. The GH-684 skip-and-report shape stays in the code for the next
+    # real backlog-doc defect, but its one trigger is gone: a doc without the section now promotes with a
+    # WARN on the catch-up path and on an explicit landing alike.
+    def test_catch_up_promotes_a_lessons_less_backlog_doc_with_a_warning(self):
         doc = self.add_backlog_issue(lessons=False)
-        out = self.apply('--catch-up')                       # exits normally: the rest of the batch lands
-        self.assertEqual(out.count('wave-reconcile: ' + wave.SKIP_MARKER), 1)
-        self.assertIn('wave-reconcile: ' + wave.SKIP_MARKER + 'GH-422 — Doc GH-422-fixture.md is missing', out)
-        self.assertIn('1 backlog item(s) skipped — GH-422', out)
-        self.assertEqual(self.manifest_states(), ['shipped', 'dialed_in'])     # 421 shipped, 422 untouched
-        self.assertTrue((self.root / 'PROJECT/3-COMPLETED/GH-421-fixture.md').exists())
-        self.assertTrue((self.root / doc).exists())                            # still active, no lifecycle write
-        # Retry source intact — with the receipt present — until the doc is repaired.
-        self.assertEqual(wave.catch_up_prs(str(self.root), 'test/repo', self.offline), ['43'])
-        self.assertIn(wave.SKIP_MARKER + 'GH-422', self.apply('--catch-up'))
-        (self.root / doc).write_text('---\nstatus: 2-WORKING\nupdated: 2026-09-01\n---\n' + self.LESSONS)
         out = self.apply('--catch-up')
         self.assertNotIn(wave.SKIP_MARKER, out)
-        self.assertEqual(self.manifest_states(), ['shipped', 'shipped'])
+        self.assertIn('wave-reconcile: ' + wave.WARN_MARKER + 'Doc GH-422-fixture.md has no', out)
+        self.assertIn('Highly recommended, not required (GH-693)', out)
+        self.assertEqual(self.manifest_states(), ['shipped', 'shipped'])      # both landed
         self.assertTrue((self.root / 'PROJECT/3-COMPLETED/GH-422-fixture.md').exists())
+        self.assertFalse((self.root / doc).exists())
         self.assertEqual(wave.catch_up_prs(str(self.root), 'test/repo', self.offline), [])
 
-    def test_explicit_landing_with_defective_doc_still_fails_closed(self):
-        # Preservation pin: naming the landing on the command line keeps the fail-closed exit 5.
-        self.add_backlog_issue(lessons=False)
-        before = self.snapshot()
-        with self.assertRaises(SystemExit) as stopped:
-            self.apply(targets=['--pr', '43'])
-        self.assertEqual(stopped.exception.code, 5)
-        self.assertEqual(before, self.snapshot())
+    def test_explicit_landing_with_a_lessons_less_doc_warns_and_lands(self):
+        # Was the GH-684 preservation pin for exit 5; the explicit path now warns and lands too.
+        doc = self.add_backlog_issue(lessons=False)
+        out = self.apply(targets=['--pr', '43'])
+        self.assertIn('wave-reconcile: ' + wave.WARN_MARKER + 'Doc GH-422-fixture.md has no', out)
+        self.assertTrue((self.root / 'PROJECT/3-COMPLETED/GH-422-fixture.md').exists())
+        self.assertFalse((self.root / doc).exists())
 
-    def test_planner_drift_for_a_skipped_issue_is_unrelated(self):
+    def test_planner_drift_for_a_lessons_less_issue_is_owned(self):
+        # GH-693: a lessons-less backlog doc is reconciled like any other, so it is IN the ownership
+        # set — its own planner drift is attributable and fatal (exit 6, rolled back), no longer
+        # "pre-existing unrelated" as it was while GH-684 skipped it.
         doc = self.add_backlog_issue(lessons=False)
         self.planner_finding = {"check": "marathon-plan/already-closed", "file": doc,
                                 "message": 'issue #422 is CLOSED but the ledger lists it under "In progress"'}
-        out = self.apply('--catch-up')                       # the skipped issue left the ownership set
-        self.assertIn(wave.SKIP_MARKER + 'GH-422', out)
-        self.assertIn('pre-existing unrelated drift', out)
-        self.assertEqual(self.manifest_states(), ['shipped', 'dialed_in'])
+        before = self.snapshot()
+        with self.assertRaises(SystemExit) as stopped:
+            self.apply('--catch-up')
+        self.assertEqual(stopped.exception.code, 6)
+        self.assertEqual(before, self.snapshot())
 
     def test_planner_drift_for_a_reconciled_issue_stays_fatal(self):
         # Red control for the ownership exclusion: the same finding naming the issue this run DID
diff --git a/test/gh496-phase2-reconciliation-views.sh b/test/gh496-phase2-reconciliation-views.sh
index ca26de97..c48a6442 100755
--- a/test/gh496-phase2-reconciliation-views.sh
+++ b/test/gh496-phase2-reconciliation-views.sh
@@ -302,7 +302,9 @@ else
   fail "Pre-merge did not output PASSED confirmation: $out"
 fi
 
-# Case B: Red Control 1 - Empty/placeholder lessons learned -> exit 5
+# Case B: Empty/placeholder lessons learned -> WARN, never the doc-contract exit 5 (GH-693; was a red control
+# from GH-496 to GH-693). The commit below moves HEAD off the committed receipt, so the run still fails on
+# receipts (exit 6) — which is the point: the doc contract passed, only the receipt check is red.
 cat << 'DOC_LL' > "$REPO/PROJECT/2-WORKING/GH-999-TEST.md"
 ---
 title: Test Task
@@ -322,11 +324,15 @@ DOC_LL
 git -C "$REPO" add "$REPO/PROJECT/2-WORKING/GH-999-TEST.md"
 git -C "$REPO" commit -q -m "fix: closes #999 with empty lessons learned"
 rc=0; out="$(python3 "$RECONCILE_PY" --root "$REPO" --pre-merge 2>&1)" || rc=$?
-assert_eq "Placeholder lessons learned is rejected (exit 5)" "$rc" "5"
-if grep -q "empty/placeholder '## Lessons Learned'" <<< "$out"; then
-  pass "Error message cites empty/placeholder lessons learned"
+if [ "$rc" != "5" ]; then
+  pass "Placeholder lessons learned is not a doc-contract failure (exit $rc, not 5)"
 else
-  fail "Error message missing placeholder explanation: $out"
+  fail "Placeholder lessons learned still exits 5 (doc contract): $out"
+fi
+if grep -q "wave-reconcile: WARN — Doc GH-999-TEST.md has empty/placeholder '## Lessons Learned'" <<< "$out"; then
+  pass "WARN cites empty/placeholder lessons learned"
+else
+  fail "WARN missing placeholder explanation: $out"
 fi
 
 # Case C: Red Control 2 - Missing required frontmatter field -> exit 5
diff --git a/test/wave-reconcile.sh b/test/wave-reconcile.sh
index 34b15775..0671fd4c 100755
--- a/test/wave-reconcile.sh
+++ b/test/wave-reconcile.sh
@@ -235,7 +235,9 @@ else
   fail "Direct-commit reconciliation preserves commit identity" "$out" "Processing commit c0ffee123456"
 fi
 
-# Test 4: Missing ## Lessons Learned rejection
+# Test 4: Missing ## Lessons Learned is advisory (GH-693) — WARN, promotion proceeds, exit 0.
+# (Was a fail-closed exit 5 from GH-165 to GH-693.) --dry-run keeps the fixture in 2-WORKING for Test 5;
+# test/gh693-lessons-learned-advisory.sh proves the real move.
 cat << 'EOF' > "$REPO/PROJECT/2-WORKING/GH-999-TEST.md"
 ---
 gh_issue: 999
@@ -248,10 +250,20 @@ EOF
 git -C "$REPO" add -A && git -C "$REPO" commit -q -m "missing lessons"
 
 set +e
-out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 1001 --offline "$REPO/manifest.json" --skip-pull 2>&1)"
+out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 1001 --offline "$REPO/manifest.json" --skip-pull --dry-run 2>&1)"
 rc=$?
 set -e
-assert_eq "Missing lessons learned is rejected (exit 5)" "$rc" "5"
+assert_eq "Missing lessons learned is a WARN, not a refusal (exit 0)" "$rc" "0"
+if grep -q "wave-reconcile: WARN — Doc GH-999-TEST.md has no '## Lessons Learned" <<< "$out"; then
+  pass "WARN names the doc and the missing section"
+else
+  fail "WARN names the doc and the missing section" "$out" "wave-reconcile: WARN — Doc GH-999-TEST.md has no '## Lessons Learned"
+fi
+if grep -q "Moved -> GH-999-TEST.md" <<< "$out"; then
+  pass "promotion proceeds past the WARN"
+else
+  fail "promotion proceeds past the WARN" "$out" "Moved -> GH-999-TEST.md"
+fi
 
 # Restore valid doc
 cat << 'EOF' > "$REPO/PROJECT/2-WORKING/GH-999-TEST.md"
diff --git a/utils/py/wave_reconcile.py b/utils/py/wave_reconcile.py
index 5d0c8ce8..1cfde054 100755
--- a/utils/py/wave_reconcile.py
+++ b/utils/py/wave_reconcile.py
@@ -929,10 +929,13 @@ def parse_doc_frontmatter(doc_path):
 
 
 def validate_lessons_learned(content, doc_name):
-    """Assert ## Lessons Learned section exists and contains substantive content (GH-496)."""
+    """Detect a missing or placeholder ## Lessons Learned section (GH-496). Returns the finding or None.
+
+    GH-693: the section is highly recommended, never a promotion gate. Every caller routes the
+    finding through warn_lessons_learned() — nothing dies, skips, or exits non-zero on it."""
     m = re.search(r"##\s+Lessons\s+Learned.*?(?=\n##\s+(?!#)|\Z)", content, re.IGNORECASE | re.DOTALL)
     if not m:
-        return f"Doc {doc_name} is missing mandatory '## Lessons Learned (For Future Agents)' section."
+        return f"Doc {doc_name} has no '## Lessons Learned (For Future Agents)' section."
 
     section_text = m.group(0)
     lines = section_text.splitlines()
@@ -952,10 +955,23 @@ def validate_lessons_learned(content, doc_name):
         substantive_lines.append(trimmed)
 
     if not substantive_lines:
-        return f"Doc {doc_name} has empty/placeholder '## Lessons Learned' section. Substantive reflections are required before closeout."
+        return f"Doc {doc_name} has empty/placeholder '## Lessons Learned' section."
     return None
 
 
+# GH-693: the one advisory emitter. The operator demoted Lessons Learned from a mandatory section
+# (enforced since GH-165, tightened in GH-496, skip-and-report since GH-684) to a highly recommended
+# one: a reflection field the reconciler cannot evaluate must not block lifecycle writes or red a
+# hosted lane (#691). It is said loudly in every log and the promotion proceeds.
+WARN_MARKER = "WARN — "
+
+
+def warn_lessons_learned(content, doc_name):
+    finding = validate_lessons_learned(content, doc_name)
+    if finding:
+        log(f"{WARN_MARKER}{finding} Highly recommended, not required (GH-693) — promotion proceeds.")
+
+
 def validate_frontmatter_schema(doc_path):
     """Validate YAML frontmatter against required PDDA schema (GH-496)."""
     doc_name = os.path.basename(doc_path)
@@ -1021,10 +1037,8 @@ def validate_and_update_doc(doc_path, pr_meta, is_merged=True, dry_run=False, jo
         ship_date = datetime.now().strftime("%Y-%m-%d")
 
     if is_merged:
-        # Assert lessons learned section exists and has substantive content for merged docs (GH-496)
-        ll_err = validate_lessons_learned(content, os.path.basename(doc_path))
-        if ll_err:
-            die(ll_err, code=5)
+        # Lessons Learned is advisory (GH-693): report, never die.
+        warn_lessons_learned(content, os.path.basename(doc_path))
 
         new_status = "Complete"
         dest_folder = "3-COMPLETED"
@@ -1791,11 +1805,8 @@ def run_pre_merge(repo_root, args):
             errors.append(fm_err)
             doc_contract_failed = True
 
-        # 2. Lessons Learned
-        ll_err = validate_lessons_learned(content, doc_name)
-        if ll_err:
-            errors.append(ll_err)
-            doc_contract_failed = True
+        # 2. Lessons Learned — advisory (GH-693); frontmatter above stays the doc contract.
+        warn_lessons_learned(content, doc_name)
 
     # 3. Test receipts
     receipt_err = validate_pre_merge_receipts(repo_root, head_sha, pr_num)
@@ -2039,22 +2050,12 @@ def main():
                         record_merge_evidence(doc_path, pr_meta, dry_run=args.dry_run, journal=journal)
                         log(f"  Issue #{issue_num} is OPEN — preserving active ROADMAP.md entry (skipping move to Completed)")
                     elif doc_path:
-                        if is_merged and (landing_kind, landing_id) not in explicit_items:
-                            # GH-684: a defective BACKLOG doc stops only itself. Check hygiene before
-                            # this issue's first lifecycle write (manifest ship, doc move, roadmap
-                            # update) and leave it for the next run — catch_up_prs re-finds it from
-                            # the doc still in 2-WORKING and the row still not Completed. Explicit
-                            # landings keep the fail-closed die() in validate_and_update_doc. The
-                            # issue also leaves the planner-ownership set, so its own retained
-                            # already-closed drift is reported as unrelated instead of fatal.
-                            with open(doc_path, "r", encoding="utf-8", errors="replace") as f:
-                                ll_err = validate_lessons_learned(f.read(), os.path.basename(doc_path))
-                            if ll_err:
-                                log(f"{SKIP_MARKER}GH-{issue_num} — {ll_err} "
-                                    "(backlog item recovered by --catch-up; fix the doc and the next run retries)")
-                                reconciled_issues.discard(issue_num)
-                                skipped_issues.add(issue_num)
-                                continue
+                        # GH-684 kept the shape "a defective BACKLOG doc stops only itself" (log
+                        # `SKIP_MARKER`, discard from reconciled_issues, add to skipped_issues,
+                        # continue) for a hygiene check run before this issue's first lifecycle
+                        # write. Its only check was Lessons Learned, which GH-693 made advisory —
+                        # validate_and_update_doc now warns instead — so no backlog item is skipped
+                        # for it any more; the marker and skipped_issues stay for the next real defect.
                         if is_merged:
                             ship_manifest_items(repo_root, issue_num, pr_meta, repo_slug, args.dry_run, journal)
                         log(f"  Found active doc: {os.path.basename(doc_path)}")
diff --git a/validate.sh b/validate.sh
index 3caac658..a19aced8 100755
--- a/validate.sh
+++ b/validate.sh
@@ -620,6 +620,7 @@ TESTS=(
   "relay-uncited-findings.sh"       # GH-173 B3 (rtl_check_uncited_findings downgrades uncited review claims)
   "wave-reconcile.sh"               # GH-165 (canonical post-merge reconciler behavior)
   "gh496-phase2-reconciliation-views.sh" # GH-496 (hosted reconciler in-flight collision detection, pre-merge checks, marathon plan fingerprinting)
+  "gh693-lessons-learned-advisory.sh" # GH-693 (Lessons Learned is a WARN, never a promotion gate: explicit, --pre-merge, catch-up; frontmatter control)
   "gh306-registry-bidirectional.sh" # GH-306 (exists→registered registry half; self-demonstrating — see the suite header)
   "gh298-ate-gen4-ci-smoke.sh"      # GH-298 (ATE Gen 4 CI smoke — fuzz/oracle wiring against the real runner)
   "gh-gen4-phase1-domain-oracles.sh" # GH-299 Phase 1 (Gen 4 semantic domain oracles: zero-state, containment, idempotence, crash-recovery; +/- controls)
```
