#!/usr/bin/env python3
"""GH-1633 review blocker probe: `_jog_lane_exhausted` must not accept a STALE cap receipt.

usage: python3 predicate-probe.py <repo-root> [--mutate drive-exit|fresh|set-aside]
Calls the real predicate with the PRODUCTION receipt loader (`load_marathon_result`, so each synthetic
receipt must be a complete marathon-drive/result@1 document) and the real identity check; only the two
ledger lookups are patched to return synthetic state. Receipt age is set with os.utime. Prints one
`PROBE name expect=... got=... OK|FAIL` line per case and exits 1 on any FAIL. --mutate removes one guard
from a COPY of the predicate source so the matching case must FAIL (red control for the probe itself)."""
import json, os, sys, tempfile, time
repo = sys.argv[1]
mutate = sys.argv[sys.argv.index("--mutate") + 1] if "--mutate" in sys.argv else None
sys.path.insert(0, os.path.join(repo, "utils", "py"))
import jog_run
if mutate:
    import inspect
    orig = inspect.getsource(jog_run._jog_lane_exhausted)
    src = orig
    if mutate == "drive-exit":
        src = src.replace('latest.get("drive_exit") != 8 or ', "")
    elif mutate == "set-aside":
        pass
    elif mutate == "fresh":
        src = src.replace(" or written < dispatched", "")
    if mutate == "set-aside":   # red control: the helper becomes a no-op
        jog_run._jog_set_aside_stale_result = lambda path: None
    else:
        assert src != orig, "mutation did not apply"
        exec(compile(src, "mutated", "exec"), jog_run.__dict__)

work = tempfile.mkdtemp(prefix="gh1633-probe.")
target = os.path.join(work, "exec"); os.makedirs(target)
T = "2026-11-26T18:00:00Z"
def receipt(exit_code=8, count=2, cap=2, issue="901", eid="gh901-exec1"):
    return {"schema": "marathon-drive/result@1", "execution_id": eid, "generated_at": T, "outcome": "parked",
            "reason": "lane parked at the attempt cap", "exit_code": exit_code, "approval_preserved": False,
            "issue": issue, "phase": "gh-901-fixture-lane", "lane": "gh-901-fixture-lane",
            "token": "MARATHON-GH-901-FIXTURE-LANE-TURN", "attempt": {"count": count, "max": cap},
            "builder": "codex", "reviewer": "agy", "target_repo": {"path": target, "origin_url": "https://example.invalid/x.git"},
            "base_branch": None, "head_branch": "development", "head_sha": "0" * 40, "reviewed_candidate": None,
            "reviewed_head": None, "added_sha256": None, "attest_path": None, "branch_redirect": False,
            "gate": {"cmd": "bash test/fixture-gate.sh", "result": "not-run", "exit": None, "receipt_path": None},
            "acceptance": None, "pr": {"number": None, "url": None, "state": None}, "pr_note": None,
            "relay_status": None, "timestamps": {"started_at": T, "finished_at": T}}
def run(name, expect, rec, written_offset=1.0, **record):
    """written_offset: receipt file mtime relative to the recorded dispatch instant (negative = older)."""
    path = os.path.join(work, name + ".json"); json.dump(rec, open(path, "w"))
    dispatched = time.time()
    os.utime(path, (dispatched + written_offset, dispatched + written_offset))
    latest = {"execution_id": "gh901-exec1", "status": "projected-parked", "outcome": "parked",
              "result_path": path, "started_at": T, "dispatched_epoch": dispatched, "drive_exit": 8}
    latest.update(record)
    jog_run.jog_load_state = lambda root, gid: {"executions": [latest]}
    jog_run._ledger_abs_path = lambda root, gid, p: p
    got = jog_run._jog_lane_exhausted(work, target, "901", "gid", 0)
    ok = (got is not None) == expect
    print(f"PROBE {name} expect={'accept' if expect else 'refuse'} got={'accept' if got else 'refuse'} {'OK' if ok else 'FAIL'}")
    return ok
res = [
    run("fresh-native-cap", True, receipt()),
    run("stale-receipt-process-exit-2", False, receipt(), written_offset=-5, drive_exit=2),
    run("stale-receipt-process-killed", False, receipt(), written_offset=-5, drive_exit=-9),
    run("stale-same-second-receipt-write-failed-exit-8", False, receipt(), written_offset=-0.2),
    run("fresh-receipt-wrong-process-exit", False, receipt(), drive_exit=2),
    run("other-execution-receipt", False, receipt(eid="gh901-exec9")),
    run("other-issue-receipt", False, receipt(issue="902")),
    run("below-cap", False, receipt(count=1, cap=2)),
    run("zero-cap-native-refusal", True, receipt(count=2, cap=0)),
]
# review r3: a staged stale receipt, even with a FUTURE mtime, must be set aside (kept, renamed) before dispatch
# so that nothing at the result path can predate the drive; without the helper the file would still be there.
stale = os.path.join(work, "staged-stale.json"); json.dump(receipt(), open(stale, "w"))
os.utime(stale, (time.time() + 3600, time.time() + 3600))
jog_run._jog_set_aside_stale_result(stale)
kept = [f for f in os.listdir(work) if f.startswith("staged-stale.json.prior-")]
ok = (not os.path.exists(stale)) and len(kept) == 1 and json.load(open(os.path.join(work, kept[0])))["execution_id"] == "gh901-exec1"
print(f"PROBE staged-future-mtime-stale-receipt-set-aside-before-dispatch expect=gone-and-kept got={'gone-and-kept' if ok else 'present-or-lost'} {'OK' if ok else 'FAIL'}")
res.append(ok)
sys.exit(0 if all(res) else 1)
