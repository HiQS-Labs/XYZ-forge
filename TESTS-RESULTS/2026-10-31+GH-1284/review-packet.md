# GH-1284 final QA packet

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1284 (found by GH-1280 ATE campaign, D1).
Branch: `fix/XYZ-forge-gh1284-status-creates-state-2026-10-31`, base `origin/development` b78df4b9.
Simple change (local, reversible, no design decision), so plan QA was skipped; plan is in
`PROJECT/1-INBOX/GH-1284-STATUS-CREATES-STATE.md`.

## Requirement (from the issue)
- `status` must not create instance state. On a root with no instance it reports "not initialized"
  (rc 0 or a documented refusal) and opens nothing for writing.
- `init` works on any root that `status` has only queried.
- Acceptance: `status` then `init` on a fresh run root → `init` exits 0 and no `state.db` exists after
  `status` alone. No new tests (GH-831).

## Operational envelope
Experimental single-operator CLI (`utils/py/harness.py factory-primitive`), runtime under gitignored
`temp/factory-primitive/`. Grade against the requirement and commensurate complexity; no
multi-tenant or race threat model was requested.

## Scope decision to review
The same `connect()`-creates-the-file pattern exists in `make_packet()` and `run_tick()`. Both are
guarded too, because each would equally leave a `state.db` that makes a later `init` refuse. Init
paths (`init_instance`, `init_from_prs`) are unchanged.

## Diff (code)
```diff
diff --git a/utils/py/harness.py b/utils/py/harness.py
index 38d183aa..6db76a3b 100755
--- a/utils/py/harness.py
+++ b/utils/py/harness.py
@@ -97,6 +97,12 @@ def connect(path: Path):
     return conn
 
 
+def _require_instance(instance: Path) -> None:
+    """GH-1284: connect() creates state.db, so only init may open a root that has none."""
+    if not (instance / "state.db").is_file():
+        raise ValueError("instance not initialized; run init first")
+
+
 def emit(conn, instance: Path, tick_id: str | None, stage: str, status: str, **fields) -> None:
     record = {"ts": utcnow(), "tick_id": tick_id, "stage": stage, "status": status, **fields}
     payload = canonical(record)
@@ -996,6 +1002,7 @@ def make_packet(instance: Path, wave: int, reviewer: str) -> dict:
     import contextlib
     from marathon_yaml_emit import EmitError, Lane, Packet, render
     out = instance / "out" / "plan-draft"
+    _require_instance(instance)
     conn = connect(instance / "state.db")
     try:
         receipt = next((json.loads(row["json"]) for row in conn.execute(
@@ -1113,6 +1120,7 @@ def _verify_output(instance: Path, tick_id: str, tool: str) -> tuple[Path, str]:
 
 def run_tick(instance: Path, slot: int, fault: str = "") -> str:
     tick_id = f"slot_{slot:03d}"
+    _require_instance(instance)
     instance.mkdir(parents=True, exist_ok=True)
     with (instance / "lock").open("a+") as lock:
         try:
@@ -1266,6 +1274,7 @@ def run_tick(instance: Path, slot: int, fault: str = "") -> str:
 
 
 def status(instance: Path) -> dict:
+    _require_instance(instance)
     conn = connect(instance / "state.db")
     try:
         counts = {row["status"]: row["n"] for row in conn.execute("SELECT status,COUNT(*) n FROM ticks GROUP BY status")}
```

## Evidence
- `TESTS-RESULTS/2026-10-31+GH-1284/smoke.txt` (output), `smoke.sh` (script), `SUMMARY.md`,
  `provenance.jsonl`. Includes a red control on the unpatched harness.
- Other branch changes are governance only: CHANGELOG entry, three 1-INBOX capture docs (1284, 1287,
  1288) and their ledger rows (`releases.db`/`releases.sql`, written by `releases_app.py roadmap add`).

## Questions for the reviewer
1. Does the guard meet the requirement and acceptance check?
2. Is guarding `make_packet()`/`run_tick()` in scope, or scope creep?
3. Any caller (driver, Track B controls, tests) that legitimately runs `tick`/`status`/`packet` before
   `init` and would now break? Sweep `utils/py/harness.py` for other `connect(instance / "state.db")`
   callers.
4. Is the smoke evidence sufficient (main path, adjacent path, red control)?
