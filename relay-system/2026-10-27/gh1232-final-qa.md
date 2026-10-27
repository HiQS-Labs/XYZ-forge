---
Goal: Final QA — GH-1232 jog promotion reads the Preflight Contract's JSON fix_probes
Date: 2026-10-27
NEXT: codex
STATUS: Approved
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

### codex — Final QA (2026-10-27)

[Blocker] `utils/py/jog_run.py:1404-1406` catches only `SystemExit` from
`extract_contract`, then assumes `contract` has `.get`. A syntactically valid JSON
contract whose top-level value is `[]` makes `swarm_preflight.extract_contract`
raise `AttributeError` while validating `target` (`utils/py/swarm_preflight.py:84-86`);
the exception escapes promotion rather than parking unattended as a malformed/parse
failure. Narrow probe (scratch only): `python3 - <non-object JSON contract>` exited
0 after the wrapper printed `ESCAPED AttributeError: 'list' object has no attribute
'get'`. The manual smoke receipt covers a non-object *probe*, not a non-object
contract, so it does not substantiate this failure path. Catch the parser failure
without masking unrelated promotion failures (or make `extract_contract` return its
normal exit-3 contract error for non-object JSON), then retain the specified parked
reason.

[Pass] `utils/py/jog_run.py:1379-1428` otherwise follows plan steps 1–2: it reuses
the preflight parser lazily, validates the five evaluator types and required fields,
lints only command `cmd`, and does not invoke `eval_probes`. Frontmatter remains the
preferred additional source at `utils/py/jog_run.py:1470-1484`; no duplicate schema
or writer appears in the supplied diff. `skills/2-daily/jog/SKILL.md:94` documents
the shape-only, no-execution boundary. The supplied smoke receipt and listed focused
suites substantiate their covered main and adjacent cases, but not the blocker above.

[Pass] Static syntax probe: `python3` AST-parsed `utils/py/jog_run.py` and
`utils/py/swarm_preflight.py`, exit 0, output `AST_OK` for both files.

VERDICT: FAIL
Basis: A valid JSON value with an invalid top-level contract shape raises instead of returning the required unattended parking result.

## Author response — round 1 (claude-a)

- **Blocker (a non-object JSON contract raises): Accepted, fixed in `37cd5f12`.** The parse is now
  wrapped in `except (SystemExit, Exception)`, followed by an `isinstance(contract, dict)` check,
  so it parks with `contract did not parse`. The `try` covers only the `extract_contract` call, so
  unrelated promotion failures are not masked. The smoke receipt adds case 9006 (top-level `[]`):
  PARKED with the reason.
- Focused suites are unaffected (a parse-guard change only). The full gate runs once on push.

Updated `jog_run.py` diff (5cab70c8..HEAD):

```diff
diff --git a/utils/py/jog_run.py b/utils/py/jog_run.py
index 7b5f1f5f..aef43fdb 100755
--- a/utils/py/jog_run.py
+++ b/utils/py/jog_run.py
@@ -1376,6 +1376,62 @@ def extract_probes_from_doc(doc_path):
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
+    except (SystemExit, Exception):
+        # SystemExit(3) on a contract error; a non-object JSON value raises inside its validation.
+        contract = None
+    if not isinstance(contract, dict):
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
@@ -1425,9 +1481,14 @@ def promote_contract_to_working(root, gh_num, doc_path, interactive=True, primar
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

Round 2: end your final block with exactly `VERDICT: PASS` (or `FAIL`) and a non-empty `Basis:` line.

### codex — Final QA, round 2 (2026-10-27)

[Pass] `utils/py/jog_run.py:1401-1407` now contains the parser call within the
failure boundary and normalizes both `SystemExit` and the parser's non-object JSON
exception to `([], "contract did not parse")`; `:1484-1491` retains the required
unattended `unreviewed-probe-contract` parking prefix and appends that reason. This
fixes r1's sole blocker without masking failures outside the parser call.

[Pass] `utils/py/jog_run.py:1379-1432` implements plan step 1 exactly: it lazily
reuses the existing parser, admits only the five evaluator types, checks each
required field, applies existing static `lint_probe` only to command `cmd`, and
returns labels rather than evaluating probes. `:1477-1486` preserves frontmatter
as the first, additional source and consults the contract only when it provides no
valid probe. No duplicate writer, schema, evaluator, or test/registry addition is
present in the provided scope. `skills/2-daily/jog/SKILL.md:90-96` accurately
states the shape-only promotion boundary.

[Pass] Narrow scratch-only confirmation of the repaired failure path (no suite or
fixture): `PYTHONPATH="$PWD/utils/py" python3 - <<'PY' ...
contract_probes_from_doc(".", ".relay-scratch/tmp/non-object-contract.md") ... PY`
where the temporary document contained a `## Swarm Preflight Contract` fenced JSON
top-level `[]`; exit `0`, decisive output `labels=[]` and
`reason='contract did not parse'`. The recorded smoke receipt
`TESTS-RESULTS/2026-10-27+GH-1232/smoke.md:11-19` independently covers this as
case 9006, the main/base control, malformed entry, lint rejection, and no-command
execution; the stated focused-suite evidence is commensurate. The plan's
`rated 70/60/50/80` remains accurate.

VERDICT: PASS
Basis: All four requirements and plan steps are implemented; promotion does static shape validation only, and every reviewed parser/contract failure path parks rather than raising.
