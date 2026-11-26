#!/usr/bin/env python3
"""GH-1633 review-r1 blocker probe: `_jog_lane_exhausted` must not accept a STALE cap receipt.

usage: python3 predicate-probe.py <repo-root> [--mutate drive-exit|fresh]
Calls the real predicate with the real receipt loader/identity check; only the ledger lookups are
patched to return synthetic state. Prints one `PROBE name expect=... got=... OK|FAIL` line per case and
exits 1 on any FAIL. --mutate removes one guard from a COPY of the predicate source so the matching case
must FAIL (red control for the probe itself)."""
import json, os, sys, tempfile
repo = sys.argv[1]
mutate = sys.argv[sys.argv.index("--mutate") + 1] if "--mutate" in sys.argv else None
sys.path.insert(0, os.path.join(repo, "utils", "py"))
import jog_run
if mutate:
    import inspect, textwrap
    src = inspect.getsource(jog_run._jog_lane_exhausted)
    if mutate == "drive-exit":
        src = src.replace('latest.get("drive_exit") != 8 or ', "")
    elif mutate == "fresh":
        src = src.replace(" or finished < started", "")
    assert src != inspect.getsource(jog_run._jog_lane_exhausted), "mutation did not apply"
    exec(compile(src, "mutated", "exec"), jog_run.__dict__)

work = tempfile.mkdtemp(prefix="gh1633-probe.")
target = os.path.join(work, "exec"); os.makedirs(target)
def receipt(finished="2026-11-26T18:00:05Z", exit_code=8, count=2, cap=2, issue="901", eid="gh901-exec1"):
    return {"schema": "marathon-drive/result@1", "execution_id": eid, "outcome": "parked",
            "reason": "lane parked at the attempt cap", "exit_code": exit_code, "approval_preserved": False,
            "issue": issue, "attempt": {"count": count, "max": cap}, "gate": {"result": "not-run", "exit": None},
            "pr": {"number": None}, "target_repo": {"path": target},
            "timestamps": {"started_at": finished, "finished_at": finished}}
def run(name, expect, rec, **record):
    path = os.path.join(work, name + ".json"); json.dump(rec, open(path, "w"))
    latest = {"execution_id": "gh901-exec1", "status": "projected-parked", "outcome": "parked",
              "result_path": path, "started_at": "2026-11-26T18:00:00Z", "drive_exit": 8}
    latest.update(record)
    jog_run.jog_load_state = lambda root, gid: {"executions": [latest]}
    jog_run._ledger_abs_path = lambda root, gid, p: p
    jog_run.load_marathon_result = lambda p: json.load(open(p))
    got = jog_run._jog_lane_exhausted(work, target, "901", "gid", 0)
    ok = (got is not None) == expect
    print(f"PROBE {name} expect={'accept' if expect else 'refuse'} got={'accept' if got else 'refuse'} {'OK' if ok else 'FAIL'}")
    return ok
res = [
    run("fresh-native-cap", True, receipt()),
    run("stale-receipt-process-exit-2", False, receipt(finished="2026-11-26T17:00:00Z"), drive_exit=2),
    run("stale-receipt-process-killed", False, receipt(finished="2026-11-26T17:00:00Z"), drive_exit=-9),
    run("stale-receipt-even-with-exit-8", False, receipt(finished="2026-11-26T17:00:00Z")),
    run("fresh-receipt-wrong-process-exit", False, receipt(), drive_exit=2),
    run("other-execution-receipt", False, receipt(eid="gh901-exec9")),
    run("other-issue-receipt", False, receipt(issue="902")),
    run("below-cap", False, receipt(count=1, cap=2)),
    run("zero-cap-native-refusal", True, receipt(count=2, cap=0)),
]
sys.exit(0 if all(res) else 1)
