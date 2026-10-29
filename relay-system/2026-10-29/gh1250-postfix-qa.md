---
Goal: Post-approval QA — GH-1236 lazy gate_receipt import in marathon_drive (marathon #1250)
Date: 2026-10-29
NEXT: claude-a
STATUS: Open
---

# Context

Marathon #1250 phase p4 (#1236) was approved by Codex and passed its pre-advance gate. The branch's pre-push full gate then failed two suites, both reproducing alone: `test/gh371-interrupt-snapshot.sh` and `test/gh372-escalation-log-tail.sh`. The cause was `ModuleNotFoundError: No module named 'gate_receipt'`. p4 added a module-level `import gate_receipt` to `utils/py/marathon_drive.py`, and those fixtures copy only five `utils/py` modules (`test/gh371-interrupt-snapshot.sh:9`).

The orchestrator's fix (`27c994a9`) moves the import inside `_write_marathon_gate_receipt`. When the module is absent, it falls back to the pre-change subprocess write path. With the fix, gh371 is 2/0, gh372 3/0, gh280 223/0, and the GH-1236 smoke recipe (`TESTS-RESULTS/2026-10-29+GH-1236/smoke.md`) exits 0, including cases 4a-4e (an eligible receipt is preserved; corrupt, failed, wrong-SHA and weaker receipts are replaced).

Operational envelope: a few lines. No new tests (GH-831), no new machinery.

Questions:
1. Is the fallback correct? When `gate_receipt` is unavailable, can the marathon receipt overwrite an eligible validate.sh receipt, and does that matter? In that layout `gate_receipt.py` is also absent for validate.sh's own writer, so no scope=full receipt can exist there.
2. Does any other new top-level import in the #1250 diff have the same partial-`utils/py` hazard?
3. Is anything else in the diff below wrong?

End with exactly `VERDICT: PASS` (or `FAIL`) on its own line, followed by a non-empty `Basis:` line (GH-533). Set STATUS to Approved on PASS.

## Diff

```diff
commit 27c994a9619f6ec959cfe65187522458d55cbf10
Author: noelsaw1 <noel@neochro.me>
Date:   Thu Oct 29 12:00:47 2026 -0500

    fix(GH-1236): import gate_receipt lazily in marathon_drive so a partial utils/py does not fail the driver
    
    The module-level import made marathon_drive.py fail to import wherever utils/py is a
    subset without gate_receipt.py: gh371/gh372 fixtures copy five modules only, and the
    pre-push gate refused the push (both fail alone). Import inside
    _write_marathon_gate_receipt; when absent, fall back to the pre-change write path.
    gh371 2/0, gh372 3/0, gh280 223/0; GH-1236 smoke recipe rc=0.
    
    Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>

diff --git a/utils/py/marathon_drive.py b/utils/py/marathon_drive.py
index 03e65f3f..455ebf33 100644
--- a/utils/py/marathon_drive.py
+++ b/utils/py/marathon_drive.py
@@ -20,7 +20,6 @@ sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
 from harness_paths import harness_home, repo_root, resolve_tool, is_vendored  # noqa: E402
 from rtl import driver_lock_path  # noqa: E402
 import relay_attest  # noqa: E402  GH-505/GH-509: validated reader of relay-drive/attest@1
-import gate_receipt  # noqa: E402  GH-1236: full-gate receipt predicate
 
 # GH-284 Phase 2 / GH-322: hooks run on EVERY terminal path with the driver's real exit code — the
 # Python equivalent of marathon-drive.sh's `trap _marathon_drive_on_exit EXIT`. Same contract as
@@ -160,15 +159,22 @@ def _result_cmd_out(cmd, cwd=None):
 def _write_marathon_gate_receipt(root, head_sha, pre_advance_cmd, xyz_harness):
     """GH-1236: keep an existing validate.sh full-gate receipt for head_sha; otherwise write the
     marathon receipt (replacing any absent, corrupt, failed, wrong-SHA, or weaker file)."""
-    receipt_path = gate_receipt.get_receipt_path(root, head_sha)
-    if os.path.isfile(receipt_path):
-        try:
-            with open(receipt_path, "r", encoding="utf-8") as f:
-                existing = json.load(f)
-        except Exception:
-            existing = None
-        if gate_receipt.is_full_gate_receipt(existing, head_sha):
-            return False
+    # Lazy, like the subprocess write below: a partial utils/py (vendored subsets, suite fixtures)
+    # may lack gate_receipt.py, and the driver must not fail to import over an optional receipt.
+    try:
+        import gate_receipt
+    except ImportError:
+        gate_receipt = None
+    if gate_receipt is not None:
+        receipt_path = gate_receipt.get_receipt_path(root, head_sha)
+        if os.path.isfile(receipt_path):
+            try:
+                with open(receipt_path, "r", encoding="utf-8") as f:
+                    existing = json.load(f)
+            except Exception:
+                existing = None
+            if gate_receipt.is_full_gate_receipt(existing, head_sha):
+                return False
     receipt_py = os.path.join(xyz_harness, "utils", "py", "gate_receipt.py")
     if os.path.isfile(receipt_py):
         subprocess.run(
```

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log

### Codex — postfix review, 2026-10-29

**Block — the lazy import fixes startup, but the fallback does not preserve the receipt contract in a supported split-harness layout.**

1. **[Required] Resolve preservation and writing against the same receipt implementation.** At `utils/py/marathon_drive.py:164-189`, an unavailable local import skips the preservation check but still invokes `xyz_harness/utils/py/gate_receipt.py write` if that file exists. These locations need not coincide: the import search starts beside the running driver (`:19`), whereas `xyz_harness = harness_home()` (`:1193`) honors an existing external `XYZ_HARNESS` directory (`utils/py/harness_paths.py:56-59`) for a non-vendored driver. A partial local driver plus a complete external harness can therefore overwrite an existing eligible receipt with `mode: marathon`, losing `scope: full`. The writer replaces the target unconditionally (`utils/py/gate_receipt.py:27-53`). This loses reuse evidence and forces another full push gate; it does not falsely qualify a push. The claim that no eligible receipt can exist is too strong: the target may have run its own complete validate.sh previously, and the external harness writer is available now. Keep the lazy startup behavior, but use the resolved writer's existing full-gate predicate before its fallback write (or otherwise preserve eligible evidence without restoring the eager dependency). No new suite or gate is needed.

   **Read-only probe:** extracted only the seeded function into memory, forced the missing import, and replaced filesystem checks/subprocess execution with observations; no writer, fixture, git command, or suite ran. Command below exited **0**:
   ```sh
   PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'
   import ast, builtins, json, os, types
   from pathlib import Path
   tree = ast.parse(Path("utils/py/marathon_drive.py").read_text())
   fn = next(n for n in tree.body if isinstance(n, ast.FunctionDef)
             and n.name == "_write_marathon_gate_receipt")
   calls = []
   real_import = builtins.__import__
   def missing(name, *a, **kw):
       if name == "gate_receipt":
           raise ModuleNotFoundError("No module named 'gate_receipt'")
       return real_import(name, *a, **kw)
   def run(writer_exists):
       calls.clear()
       fake_os = types.SimpleNamespace(path=types.SimpleNamespace(
           join=os.path.join, isfile=lambda p: writer_exists))
       scope = {"__builtins__": dict(vars(builtins), __import__=missing),
                "os": fake_os, "json": json,
                "subprocess": types.SimpleNamespace(
                    DEVNULL=-3, run=lambda cmd, **kw: calls.append(cmd))}
       exec(compile(ast.Module(body=[fn], type_ignores=[]),
                    "<seeded-function>", "exec"), scope)
       result = scope[fn.name]("/target", "a"*40, "validate.sh", "/external-harness")
       print(f"missing_import writer_exists={writer_exists}: returned={result}, writer_calls={len(calls)}")
       if calls:
           print("writer argv:", calls[0])
   run(False)
   run(True)
   PY
   ```
   Decisive output:
   ```text
   missing_import writer_exists=False: returned=False, writer_calls=0
   missing_import writer_exists=True: returned=True, writer_calls=1
   writer argv: ['python3', '/external-harness/utils/py/gate_receipt.py', 'write', '--repo', '/target', '--sha', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', '--gate', 'validate.sh', '--mode', 'marathon', '--exit-code', '0']
   ```
   The first case is the control: when both module locations lack the writer, nothing is overwritten. The second demonstrates the unconditional writer dispatch; the on-disk replacement consequence is established by reading the writer, not by claiming an integration run.

2. **Other imports:** the displayed postfix adds no other top-level dependency. The current marathon driver imports only standard-library modules plus `harness_paths`, `rtl`, and `relay_attest`; both affected fixtures copy those three (`test/gh371-interrupt-snapshot.sh:9`, `test/gh372-escalation-log-tail.sh:9`). I also inspected import headers for the other Python artifacts named in `PROJECT/2-WORKING/GH-1250-PHASE0-FOLLOWUPS/MARATHON.yaml`: `_marathon_plan.py` and `merge_cleanup.py`. A whole-#1250 **new-import delta is unverified**: the supplied diff contains only the postfix, and this turn prohibits git. No second newly introduced partial-utils dependency is established by the supplied evidence.

3. **[Unverified — needs clone run]** The reported gh371/gh372/gh280 and smoke reruns were not rerun here, per the review boundary. The seeded GH-1236 provenance records the earlier candidate `5f3f8a8b`, not postfix `27c994a9`; it cannot independently attest the postfix rerun. After the correction, retain the focused clone-run result for the final candidate, including an eligible receipt with a missing local module and an external writer. The harness gate remains outstanding.

VERDICT: FAIL
Basis: The supported external-harness fallback dispatches an unconditional receipt replacement after skipping eligibility checks; the local-missing/external-present control demonstrates the path without mutating repository state.
