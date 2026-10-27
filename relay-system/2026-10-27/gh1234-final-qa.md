---
Goal: Final QA — GH-1234 marathon lane PR body carries Closes #<issue>
Date: 2026-10-27
NEXT: codex
STATUS: Approved
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

### Codex final QA — 2026-10-27

[Pass] **Ship.** The implementation meets requirements 1–4 and plan steps 1–3.  Jog appends the
opt-in flag once only when its structured `issue` value is present
(`utils/py/jog_run.py:484-510`); the driver parses that flag beside the established branch-safety
control (`utils/py/marathon_drive.py:1101-1105`).  The sole lane-PR publisher passes the exact
derived issue and parsed flag to the body builder (`utils/py/marathon_drive.py:2680-2704`), so a
flagged Jog lane produces `Closes #N`, an ordinary wave/direct invocation produces `Refs #N`, and
an underivable issue preserves the original body (`utils/py/marathon_drive.py:137-144`).  No
`marathon-closeout.sh` behavior changed, and the frozen Bash fallback remains untouched.

[Pass] There is no implicit closing path: `lane_pr_notes()` selects `Closes` only for a truthy
`closes_issue` argument and a derivable issue (`utils/py/marathon_drive.py:141-144`).  A direct
operator may explicitly supply the public driver flag, as accepted in plan QA round 2; that is an
intentional override rather than an automatic direct-drive closure.  The lane-PR attempt remains
after durable success recording and green publication (`utils/py/marathon_drive.py:2815-2834`), so
a nonzero closeout result is logged without reversing phase approval
(`utils/py/marathon_drive.py:2704-2714`).

[Pass] The module-level `lane_pr_notes()` extraction is behavior-preserving for the former body
literal and makes the exact builder independently observable without introducing a second body
owner (`utils/py/marathon_drive.py:137-144,2699-2703`).  Its only added behavior is the planned
issue suffix.

[Pass] The manual receipt substantiates the required sensitivity: it drives the exact body helper
through closeout dry-run, reports the flagged `Closes #416` path, unflagged `Refs #648`, unchanged
no-issue body, Jog's add/none/no-duplicate cases, and the base red control
(`TESTS-RESULTS/2026-10-27+GH-1234/smoke.md:3-10,14-27,29-53`).  The listed disposable-clone
focused-suite results are consistent with the changed adapter and lane-PR surfaces; the scheduled
full gate remains the final broader check.  Read-only syntax probe:
`PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 - <<'PY' ... ast.parse(...) ... PY`
exited `0`; decisive output: `ast=ok jog_run.py marathon_drive.py`.

VERDICT: PASS
Basis: The one explicit Jog policy flag is the sole automatic selector for `Closes`; all default lanes are non-closing, the no-issue body is unchanged, and the recorded smoke observes the body at the closeout boundary with a base red control.

### Attestation · relay-drive — 2026-10-27T15:36:09Z
task: RELAY-gh1234-final-qa
reviewer: codex
status: Approved
reviewed-head: c387d9a2d1cbb90ddd266ef321d6ef280ae0f416
added-range: 5585+2634
added-sha256: ef2733ca1aeeda33e1299dcd57a90d7068338825d5b2f7594ff7f0f828e34edd
