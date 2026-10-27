---
Goal: Final QA — GH-1232 jog promotion reads the Preflight Contract's JSON fix_probes
Date: 2026-10-27
NEXT: codex
STATUS: Open
---

# Context

Final QA on the implementation of https://github.com/HiQS-Labs/XYZ-forge/issues/1232 against its approved plan (`PROJECT/2-WORKING/GH-1232-JOG-PROMOTION-PROBE-SCHEMA.md`; plan QA in `relay-system/2026-10-27/gh1232-plan-qa.md`, attested r3). Base `5cab70c8`.

Operational envelope: the same as the plan. Grade against the plan's requirements and commensurate complexity; no new tests (AGENTS.md *No new tests*, GH-831). A new test file or registry entry in the diff is a finding.

Evidence:
- Manual smoke receipt: `TESTS-RESULTS/2026-10-27+GH-1232/smoke.md` (main path + base red control + four adjacent cases, disposable clone).
- Focused suites in the disposable clone at `5e52e19d`: `test/gh280-jog-marathon-adapter.sh` 223 pass / 0 fail; `pytest test/test_python_layer.py` 21 passed. The full gate runs once on push (pre-push hook).

Questions:
1. Does the code implement each requirement (1–4) and plan step (1–3) exactly? Is anything missing or extra?
2. Is any probe executed at promotion? Is any failure path (unreadable doc, import failure, parse failure, malformed entry) able to raise instead of parking unattended?
3. Did a duplicate subsystem, writer or schema slip in?
4. Do the smoke receipt and suites substantiate the claims? Is the rating still accurate?

Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`, citing file:line. End your final block with exactly `VERDICT: PASS` (or `FAIL`) on its own line, followed by a non-empty `Basis:` line (GH-533). Set STATUS to Approved on PASS.

## Diff (code + skill doc, 5cab70c8..HEAD)

```diff
diff --git a/skills/2-daily/jog/SKILL.md b/skills/2-daily/jog/SKILL.md
index 14ab803e..2837d344 100644
--- a/skills/2-daily/jog/SKILL.md
+++ b/skills/2-daily/jog/SKILL.md
@@ -91,6 +91,7 @@ releases jog run --target-root <disposable-full-clone> [--executor relay|maratho
    If a task's capture doc is in `PROJECT/1-INBOX/`, `jog run` promotes it to `PROJECT/2-WORKING/`, formats the status table, and lints its `fix_probes`:
    - Rejects trivial or dummy probe patterns (e.g. `exit 0`, `true`).
    - Requires referenced probe scripts/globs to resolve to actual files.
+   - With no frontmatter `fix_probes`, accepts the `## Swarm Preflight Contract` JSON `fix_probes` when every entry is well-formed (known `type`; non-empty `path`, grep `pattern`, or a `command` `cmd` that passes the same lint). Promotion evaluates no probe: preflight judges "unfixed" next, in its ref-pinned worktree (GH-1232).
    - In interactive mode, prompts operator to approve drafted probes before running preflight.
    - In unattended mode, unreviewed auto-scaffolding without verified probes is parked with `unreviewed-probe-contract` to prevent false-green runs.
 
diff --git a/utils/py/jog_run.py b/utils/py/jog_run.py
index 7b5f1f5f..5f026d6e 100755
--- a/utils/py/jog_run.py
+++ b/utils/py/jog_run.py
@@ -1376,6 +1376,59 @@ def extract_probes_from_doc(doc_path):
     return probes
 
 
+_CONTRACT_PROBE_TYPES = ("path_absent", "path_present", "grep_present", "grep_absent", "command")
+
+
+def contract_probes_from_doc(root, doc_path):
+    """GH-1232: the Preflight Contract's JSON fix_probes, checked for shape only.
+
+    Returns (labels, reason). Nothing is evaluated: whether a probe still reads "unfixed" is
+    preflight's verdict, made next in its ref-pinned worktree. Running the probes here would judge
+    the mutable checkout instead and execute shell `command` probes twice (plan QA round 1).
+    """
+    try:
+        with open(doc_path, "r", encoding="utf-8") as f:
+            text = f.read()
+    except OSError:
+        return [], None
+    # extract_contract sys.exit(3)s on a doc without the heading; check first (marathon_drive idiom).
+    if not re.search(r'^#{1,6}\s+.*preflight\s+contract', text, re.IGNORECASE | re.MULTILINE):
+        return [], None
+    try:
+        from swarm_preflight import extract_contract
+    except Exception as e:
+        return [], f"could not load the preflight contract parser ({e})"
+    try:
+        contract = extract_contract(doc_path)
+    except SystemExit:
+        return [], "contract did not parse"
+    labels = []
+    for n, p in enumerate(contract.get("fix_probes") or [], 1):
+        if not isinstance(p, dict):
+            return [], f"contract probe {n} malformed: not an object"
+        ptype = p.get("type")
+        if ptype not in _CONTRACT_PROBE_TYPES:
+            return [], f"contract probe {n} malformed: unknown type {ptype!r}"
+        if ptype == "command":
+            cmd = p.get("cmd")
+            if not isinstance(cmd, str) or not cmd.strip():
+                return [], f"contract probe {n} malformed: command needs a non-empty cmd"
+            ok, why = lint_probe(root, cmd)
+            if not ok:
+                return [], f"contract probe {n}: {why}"
+            labels.append(f"command:{cmd}")
+            continue
+        path = p.get("path")
+        if not isinstance(path, str) or not path.strip():
+            return [], f"contract probe {n} malformed: {ptype} needs a non-empty path"
+        if ptype.startswith("grep_"):
+            pattern = p.get("pattern")
+            if not isinstance(pattern, str) or not pattern:
+                return [], f"contract probe {n} malformed: {ptype} needs a non-empty pattern"
+        labels.append(f"{ptype}:{path}")
+    return labels, None
+
+
 def promote_contract_to_working(root, gh_num, doc_path, interactive=True, primary=None):
     """Promote a 1-INBOX doc to 2-WORKING/ with verified status table and probes."""
     _require_jog_primary(primary or root)
@@ -1425,9 +1478,14 @@ def promote_contract_to_working(root, gh_num, doc_path, interactive=True, primar
         if ok:
             valid_probes.append(p)
 
+    contract_reason = None
+    if not valid_probes:
+        valid_probes, contract_reason = contract_probes_from_doc(root, doc_path)
+
     if not valid_probes:
         if not interactive:
-            return None, "unreviewed-probe-contract (no valid probes in unattended mode)"
+            detail = f"; {contract_reason}" if contract_reason else ""
+            return None, f"unreviewed-probe-contract (no valid probes in unattended mode{detail})"
 
     if interactive and sys.stdin.isatty():
         print(f"\n[jog] Auto-promoted contract for GH-{gh_num}:")
```

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log
