---
Goal: Final QA — GH-1234 marathon lane PR body carries Closes #<issue>
Date: 2026-10-27
NEXT: codex
STATUS: Open
---

# Context

Final QA on the implementation of https://github.com/HiQS-Labs/XYZ-forge/issues/1234 against its approved plan (`PROJECT/2-WORKING/GH-1234-CLOSEOUT-CLOSES-KEYWORD.md`; plan QA in `relay-system/2026-10-27/gh1234-plan-qa.md`, attested r2). Base `5cab70c8`.

Operational envelope: the same as the plan. Grade against the plan's requirements and commensurate complexity; no new tests (AGENTS.md *No new tests*, GH-831). A new test file or registry entry in the diff is a finding.

There is one deviation from the plan text, made for verifiability. The body builder was moved into a module-level `lane_pr_notes(phase_id, issue, closes_issue)` (commit `9bb3cb49`), which `open_lane_pr()` calls. The text and behaviour are the same as the inline version in `b7c3a227`. It exists so the smoke can drive the exact builder.

Evidence:
- Manual smoke receipt: `TESTS-RESULTS/2026-10-27+GH-1234/smoke.md`.
  - Bodies are rendered through `marathon-closeout.sh --dry-run` to the exact `gh pr create --body`.
  - Covers the main path, the base red control, Refs, no-issue, and Jog argv add/none/no-duplicate.
- Focused suites in a disposable clone at `86f7c7d0`:
  - `test/gh280-jog-marathon-adapter.sh`: 223 pass / 0 fail;
  - `test/gh402-branch-enforcement.sh`: 20 passed / 0 failed;
  - `pytest test/test_python_layer.py`: 21 passed.
- The full gate runs once on push.

Questions:
1. Does the code implement requirements 1–4 and plan steps 1–3 exactly? Is anything missing or extra?
2. Can any path write `Closes` without Jog's flag, or fail the phase? (`open_lane_pr` is best-effort.)
3. Is the `lane_pr_notes` extraction behaviour-preserving, and acceptable as a deviation?
4. Do the smoke receipt and suites substantiate the claims?

Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`, citing file:line. End your final block with exactly `VERDICT: PASS` (or `FAIL`) on its own line, followed by a non-empty `Basis:` line (GH-533). Set STATUS to Approved on PASS.

## Diff (code, 5cab70c8..HEAD)

```diff
diff --git a/utils/py/jog_run.py b/utils/py/jog_run.py
index 7b5f1f5f..3f0eb4f0 100755
--- a/utils/py/jog_run.py
+++ b/utils/py/jog_run.py
@@ -504,6 +504,9 @@ def _marathon_argv_from_invocation(invocation, builder, reviewer):
         argv.remove("--require-clean")
     if "--phase-id" not in argv and invocation.get("phase"):
         argv += ["--phase-id", invocation["phase"]]
+    # GH-1234: a Jog item is one issue in one phase, so its lane PR closes the issue.
+    if invocation.get("issue") and "--lane-closes-issue" not in argv:
+        argv.append("--lane-closes-issue")
     return argv
 
 
diff --git a/utils/py/marathon_drive.py b/utils/py/marathon_drive.py
index e0012770..fd5d2b66 100644
--- a/utils/py/marathon_drive.py
+++ b/utils/py/marathon_drive.py
@@ -134,6 +134,16 @@ def _derive_issue_number(lane, task, brief_name):
     return None
 
 
+def lane_pr_notes(phase_id, issue, closes_issue):
+    """The lane PR body (GH-561). GH-1234: only a caller that knows this lane finishes the issue
+    (Jog: one issue, one phase) may close it; a wave phase of a multi-phase umbrella only
+    references it. No derivable issue leaves the body as it was."""
+    notes = f"Automated marathon closeout for phase `{phase_id}` (GH-561)."
+    if issue:
+        notes += f"\n\nCloses #{issue}" if closes_issue else f"\n\nRefs #{issue}"
+    return notes
+
+
 def _result_cmd_out(cmd, cwd=None):
     """Best-effort stdout capture for the receipt's git/gh probes; failure yields None."""
     try:
@@ -1090,6 +1100,9 @@ def main():
     # land on main, which is the kind of coupling that is obvious only after it happens.
     parser.add_argument("--allow-trunk-commit", dest="allow_trunk_commit", action="store_true",
                         help="permit committing to the receiving repo's trunk/default branch (GH-402)")
+    parser.add_argument("--lane-closes-issue", dest="lane_closes_issue", action="store_true",
+                        help="this lane finishes its issue: the lane PR body says Closes #N, not Refs #N "
+                             "(passed by Jog, one issue = one phase; GH-1234)")
     parser.add_argument("--dry-run", dest="dry_run", action="store_true")
     parser.add_argument("--log-github", dest="log_github", action="store_true")  # GH-284 P2 / GH-322
     # GH-280: opt-in durable terminal-result receipt for supervisors. No behavior change when unset.
@@ -2683,10 +2696,11 @@ relay-file: {rel_relay}
         # --no-commit is the load-bearing flag: closeout's default is `git add -A` + commit, which in
         # an automated call would sweep every unrelated dirty file in the target into the PR. The
         # driver has already committed everything this phase produced.
+        notes = lane_pr_notes(args.phase_id, lane_issue_number(), args.lane_closes_issue)
         cmd = [closeout, "--repo", repo, "--head", head, "--base", base,
                "--open-only", "--no-commit",
                "--title", f"Marathon lane {args.phase_id}",
-               "--notes", f"Automated marathon closeout for phase `{args.phase_id}` (GH-561)."]
+               "--notes", notes]
         res = subprocess.run(cmd, capture_output=True, text=True)
         for line in (res.stdout or "").splitlines() + (res.stderr or "").splitlines():
             if line.strip():
```

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log
