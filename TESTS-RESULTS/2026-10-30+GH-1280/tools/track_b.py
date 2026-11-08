#!/usr/bin/env python3
"""GH-1280 smoke step 5 (Track B): stateful checks in the disposable control clone.

B1 replays the 17 GH-1248 checkpoint2 controls with relocated argv and compares exit codes,
final status and the two recorded ledger queries against the recorded logs. B2 checks a
repeated completed tick leaves the state rows unchanged. B3 checks crash-act recovery.
Usage: track_b.py DEADLINE_EPOCH. Writes ev/05-track-b.json. Campaign tooling only.
"""
import json, os, re, shlex, sqlite3, subprocess, sys, time

SP = os.path.dirname(os.path.realpath(__file__))
TASK = "/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30"
CLONE = os.path.join(SP, "sb-ctl", "clone")
FPROOT = os.path.realpath(os.path.join(CLONE, "temp", "factory-primitive"))
PY = "/opt/homebrew/bin/python3"
SRC = os.path.join(TASK, "TESTS-RESULTS", "2026-10-28+GH-1248")
DEADLINE = float(sys.argv[1])
Q1 = "SELECT tick_id,status FROM receipts ORDER BY tick_id"
Q2 = "SELECT tick_id,tool,status FROM tool_runs NATURAL JOIN intents"


def run(argv, timeout=120):
    r = subprocess.run(argv, cwd=CLONE, capture_output=True, text=True, timeout=timeout,
                       env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"))
    return {"argv": argv, "rc": r.returncode, "stdout": r.stdout, "stderr": r.stderr[-800:]}


def query(db, q):
    c = sqlite3.connect("file:%s?mode=ro" % db, uri=True)
    c.row_factory = sqlite3.Row
    rows = [dict(r) for r in c.execute(q)]
    c.close()
    return rows


def parse_log(path):
    text = open(path).read()
    rcs = [int(x) for x in re.findall(r"^exit_code=(-?\d+)$", text, re.M)]
    outs = re.findall(r"^stdout:\n(.*?)\nstderr:", text, re.M | re.S)
    queries = {}
    for q, line in re.findall(r"^query=(.*)\n(.*)$", text, re.M):
        queries[q] = json.loads(line)
    return rcs, outs, queries


def adapt(cmd, case, new_root):
    argv = shlex.split(cmd)
    old_root = "temp/factory-primitive/evidence/checkpoint2/" + case
    out = []
    for i, tok in enumerate(argv):
        if i == 0 and tok.endswith("python3"):
            tok = PY
        elif old_root in tok:
            tail = tok.split(old_root, 1)[1]
            tok = new_root + tail if not os.path.isabs(tok) else os.path.join(CLONE, new_root) + tail
        out.append(tok)
    for tok in out:  # every mutable path must resolve inside the clone's run root
        if "factory-primitive/" in tok and not tok.startswith("utils/") and "--" != tok[:2]:
            p = os.path.realpath(tok if os.path.isabs(tok) else os.path.join(CLONE, tok))
            if not p.startswith(FPROOT + os.sep):
                raise ValueError("unrelocatable path %r -> %s" % (tok, p))
    return out


results = {"B1": [], "B2": None, "B3": None}
for line in open(os.path.join(SRC, "controls-checkpoint2.jsonl")):
    if time.time() >= DEADLINE:
        results["B1"].append({"held": "discovery deadline reached"})
        break
    d = json.loads(line)
    case, new_root = d["case"], "temp/factory-primitive/gh1280/b1/" + d["case"]
    rec_rcs, rec_outs, rec_q = parse_log(os.path.join(SRC, d["log"]))
    try:
        cmds = [adapt(c, case, new_root) for c in d["commands"]]
    except ValueError as exc:
        results["B1"].append({"case": case, "held": str(exc)})
        continue
    steps = [run(a) for a in cmds]
    rcs = [s["rc"] for s in steps]
    db = os.path.join(CLONE, new_root, "instances", "C", "state.db")
    got_q = {q: query(db, q) for q in rec_q} if os.path.exists(db) else {}
    status_match = None
    if steps and "status" in cmds[-1]:
        try:
            # GH-1257 later added heartbeat/last_receipt/lock/quarantined_ids; compare the recorded keys
            got, rec = json.loads(steps[-1]["stdout"]), json.loads(rec_outs[-1])
            status_match = {k: got.get(k) for k in rec} == rec
        except (ValueError, IndexError):
            status_match = False
    def norm(q):  # wall-clock "ts" inside stored event JSON differs by run; drop it
        f = lambda row: {k: ({x: y for x, y in json.loads(v).items() if x != "ts"} if k == "json" else v) for k, v in row.items()}
        return {k: [f(r) for r in rows] for k, rows in q.items()}
    ok = rcs == rec_rcs and norm(got_q) == norm(rec_q) and status_match is not False
    results["B1"].append({"case": case, "pass": ok, "rcs": rcs, "recorded_rcs": rec_rcs, "status_match": status_match,
                          "queries_match": norm(got_q) == norm(rec_q), "queries": got_q, "recorded_queries": rec_q,
                          "adapted_argv": cmds, "stderr_tails": [s["stderr"] for s in steps if s["stderr"]],
                          "recorded_detail": d.get("detail")})
    print(("PASS " if ok else "FAIL ") + "B1 " + case, flush=True)

# B2: repeated completed tick leaves rows unchanged (the oracle digest check ran in control c)
root = "temp/factory-primitive/gh1280/b2"
s = [run([PY, "utils/py/harness.py", "factory-primitive", "--run-root", root, "init", "--daily-cap", "1", "--max-call-cost", "0"]),
     run([PY, "utils/py/harness.py", "factory-primitive", "--run-root", root, "tick", "--slot", "1"])]
db = os.path.join(CLONE, root, "instances", "C", "state.db")
tables = ["receipts", "decisions", "intents", "tool_runs"]
before = {t: query(db, "SELECT count(*) n FROM %s" % t)[0]["n"] for t in tables}
s += [run([PY, "utils/py/harness.py", "factory-primitive", "--run-root", root, "tick", "--slot", "1"]) for _ in range(3)]
after = {t: query(db, "SELECT count(*) n FROM %s" % t)[0]["n"] for t in tables}
ok = all(x["rc"] == 0 for x in s) and before == after and len({x["stdout"] for x in s[2:]}) == 1
results["B2"] = {"pass": ok, "rows_before": before, "rows_after": after, "repeat_stdout": [x["stdout"] for x in s[1:]]}
print(("PASS " if ok else "FAIL ") + "B2 repeated tick", flush=True)

# B3: crash-act, recovery tick, status
root = "temp/factory-primitive/gh1280/b3"
H = [PY, "utils/py/harness.py", "factory-primitive", "--run-root", root]
s = [run(H + ["init", "--daily-cap", "1", "--max-call-cost", "0"]), run(H + ["tick", "--slot", "1", "--fault", "crash-act"])]
inst = os.path.join(CLONE, root, "instances", "C")
db = os.path.join(inst, "state.db")
runs_before = query(db, "SELECT count(*) n FROM tool_runs NATURAL JOIN intents WHERE tick_id='slot_001'")[0]["n"]
s += [run(H + ["tick", "--slot", "2"]), run(H + ["status"])]
receipts = query(db, Q1)
runs_after = query(db, "SELECT count(*) n FROM tool_runs NATURAL JOIN intents WHERE tick_id='slot_001'")[0]["n"]
out_hits = [os.path.join(dp, f) for dp, _, fs in os.walk(os.path.join(inst, "out")) for f in fs
            if "slot_001" in f or "slot_001" in dp]
status = json.loads(s[-1]["stdout"]) if s[-1]["rc"] == 0 else {}
live = subprocess.run(["/usr/bin/pgrep", "-f", root], capture_output=True, text=True).stdout.split()
ok = (s[1]["rc"] == 70 and s[2]["rc"] == 0 and {"tick_id": "slot_001", "status": "uncertain"} in receipts
      and status.get("quarantined") == 1 and runs_before == 0 and runs_after == 0 and not out_hits and not live)
results["B3"] = {"pass": ok, "rcs": [x["rc"] for x in s], "receipts": receipts, "status": status,
                 "slot1_tool_runs_before_recovery": runs_before, "slot1_tool_runs_after_recovery": runs_after,
                 "slot1_output_files": out_hits, "surviving_pids": live}
print(("PASS " if ok else "FAIL ") + "B3 crash-act recovery", flush=True)

json.dump(results, open(os.path.join(SP, "ev", "05-track-b.json"), "w"), indent=1)
allok = all(r.get("pass") for r in results["B1"]) and results["B2"]["pass"] and results["B3"]["pass"]
print("TRACK B " + ("PASS" if allok else "NOT ALL PASS"))
