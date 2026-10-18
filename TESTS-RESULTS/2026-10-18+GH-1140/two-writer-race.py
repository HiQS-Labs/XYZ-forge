#!/usr/bin/env python3
"""GH-1140 manual check: two real processes write outcomes to one batch record concurrently.
RED CONTROL: with the pre-GH-1140 whole-file save, one writer's row is lost."""
import json, subprocess, sys, tempfile, os
from pathlib import Path
sys.path.insert(0, "skills/2-daily/merge-cleanup/scripts")
import batch_record

tmp = tempfile.mkdtemp(prefix="gh1140-race-")
rec_dir = batch_record._dir(Path(tmp), "ex/ample"); rec_dir.mkdir(parents=True)
path = rec_dir / "batch-20261018T000000Z-1.json"
base = {"schema": 1, "repo": "ex/ample", "integration": "development", "created": "t",
        "issue": None, "issue_url": "", "issue_error": "",
        "planned": [{"pos": i, "pr": n, "title": f"pr{n}", "files": [f"f{n}"], "hard": [], "soft": {}}
                    for i, n in enumerate((1, 2), 1)],
        "outcomes": {"1": {"status": "unattempted"}, "2": {"status": "unattempted"}},
        "landed_order": [], "sweep_inputs": {}, "verdict": None, "path": str(path)}
batch_record.save(base)

child = '''
import sys, json, time
from pathlib import Path
sys.path.insert(0, "skills/2-daily/merge-cleanup/scripts")
import batch_record
n, oid, gate = int(sys.argv[1]), sys.argv[2], sys.argv[3]
rec = json.loads(open(sys.argv[4]).read())
Path(gate + str(n)).touch()              # each reader reports its load
while not Path(gate + ".both").exists(): # ...before either writes (barrier)
    time.sleep(0.01)
batch_record.set_outcome(rec, n, status="merged", merge_oid=oid)
'''
gate = str(Path(tmp) / "loaded")
script = Path(tmp) / "child.py"; script.write_text(child)
procs = [subprocess.Popen([sys.executable, str(script), str(n), oid, gate, str(path)],
                          cwd=os.getcwd(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
         for n, oid in ((1, "a" * 40), (2, "b" * 40))]
import time as _t
deadline = _t.time() + 15
while not (Path(gate + "1").exists() and Path(gate + "2").exists()) and _t.time() < deadline:
    # wait until BOTH children report their load (gate for each; second writes gate+"2")
    _t.sleep(0.05)
Path(gate + ".both").touch()
for p in procs: p.wait()

disk = json.loads(path.read_text())
ok = (disk["outcomes"]["1"].get("status") == "merged" and disk["outcomes"]["1"].get("merge_oid") == "a" * 40
      and disk["outcomes"]["2"].get("status") == "merged" and disk["outcomes"]["2"].get("merge_oid") == "b" * 40
      and set(disk["landed_order"]) == {1, 2})
print("outcomes:", {k: v.get("status") for k, v in disk["outcomes"].items()},
      "oids:", {k: (v.get("merge_oid") or "")[:6] for k, v in disk["outcomes"].items()},
      "landed_order:", disk["landed_order"])
print("VERDICT:", "PASS — both writers survived" if ok else "FAIL — a writer was erased")
sys.exit(0 if ok else 1)
