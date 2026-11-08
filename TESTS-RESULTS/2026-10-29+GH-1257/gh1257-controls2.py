"""GH-1257 manual controls that call harness functions directly. Run from the -verify clone root."""
import copy
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, "utils/py")
import harness as h  # noqa: E402

pilot = Path("temp/factory-primitive/pilot-2/instances/C")

# 1. _validate rejects an unknown id and an already-consumed id.
snap = {"inbox": [{"id": "gh-1-aaaaaaaaaaaa", "kind": "plan-request", "target": "1"}], "recent": [], "probe_targets": []}
dec = lambda i: {"tool": "plan-draft", "args": {"inbox_id": i}, "reason": "control", "confidence": 1.0}
print("CONTROL validate-unknown-id |", h._validate(dec("gh-999999-000000000000"), snap))
consumed = json.loads((pilot / "out/plan-draft/slot_003.json").read_text())["request_id"]
print("CONTROL validate-consumed-id |", consumed, "->", h._validate(dec(consumed), {**snap, "inbox": []}))
print("CONTROL validate-extra-args |", h._validate({**dec("gh-1-aaaaaaaaaaaa"), "args": {"inbox_id": "gh-1-aaaaaaaaaaaa", "x": 1}}, snap))

# 2. Cited paths: traversal, absolute and symlink-out are never admitted; a real file is.
link = Path("utils/py/gh1257-escape-link")
os.symlink("/etc/hosts", link)
try:
    text = "see ../etc/passwd and /etc/hosts and utils/../../outside.txt and utils/py/gh1257-escape-link and utils/py/harness.py"
    print("CONTROL path-escape |", [e["path"] for e in h._cited_paths(text, "control")])
finally:
    link.unlink()

# 3. Network inside the tool sandbox fails closed (same profile as _run_tool).
out = pilot / "out" / "plan-draft"
tmp = pilot / "tmp" / "plan-draft"
profile = ("(version 1)(deny default)(allow process*)(allow file-read*)(allow sysctl-read)(allow mach-lookup)"
           f"(allow file-write* (subpath \"{out.resolve()}\")(subpath \"{tmp.resolve()}\"))")
probe = "import socket; s=socket.create_connection(('api.github.com',443),timeout=5); print('CONNECTED')"
r = subprocess.run(["sandbox-exec", "-p", profile, sys.executable, "-c", probe], capture_output=True, text=True)
print("CONTROL network-in-sandbox | rc=%d %s" % (r.returncode, (r.stdout + r.stderr).strip().splitlines()[-1][:120]))

# 4. Missing scope holds a draft; the same cited path with sourced scope stays eligible.
root = Path("temp/factory-primitive/ctl-scope/instances/C")
shutil.rmtree(root.parent.parent, ignore_errors=True)
(root / "out/plan-draft").mkdir(parents=True)
shutil.copytree(pilot / "backlog", root / "backlog")
manifest = json.loads((root / "backlog/manifest.json").read_text())
issues = json.loads((root / "backlog/issues.json").read_text())
rid, req = next((k, v) for k, v in manifest["requests"].items() if v["planner_state"] == "needs-contract")
bodies = {"with-scope": "## Scope\n\nChange the loop in utils/py/harness.py.\n",
          "no-scope": "## Notes\n\nChange the loop in utils/py/harness.py.\n"}
for name, body in bodies.items():
    issues[str(req["issue"])]["body"] = body
    req2 = {**req, "doc_path": None, "doc_sha256": None}
    (root / "backlog/issues.json").write_text(json.dumps(issues))
    (root / "backlog/manifest.json").write_text(json.dumps({**manifest, "requests": {rid: req2}}))
    tick = f"slot_{name}"
    h.plan_draft(tick, root / "out/plan-draft", {"inbox_id": rid}, [], "")
    b = json.loads((root / f"out/plan-draft/{tick}.json").read_text())
    p = json.loads((root / "out/plan-draft/wave-proposal.json").read_text())
    in_prov = any(l["issue"] == req["issue"] for w in p["provisional"]["waves"] for l in w)
    held = [x["reason"] for x in p["held"] if x["issue"] == req["issue"]]
    print(f"CONTROL scope-{name} | #{req['issue']} draft_status={b['draft_status']} write_set={[w['path'] for w in b['write_set']]} "
          f"in_provisional_wave={in_prov} held={held}")
