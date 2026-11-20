import json, os, subprocess, sys, tempfile, glob, hashlib
sys.path.insert(0, sys.argv[1] + "/utils/py")
import rtl, relay_attest, gate_receipt
def sh(*a, cwd=None): return subprocess.check_output(a, cwd=cwd, text=True).strip()
root = tempfile.mkdtemp(prefix="chk.")
sh("git","init","-q","-b","task1",root); sh("git","-C",root,"config","user.email","t@t"); sh("git","-C",root,"config","user.name","t")
open(root+"/f","w").write("1"); sh("git","-C",root,"add","-A"); sh("git","-C",root,"commit","-qm","c1")
head = sh("git","-C",root,"rev-parse","HEAD")

# --- #7: failed row cannot be overwritten; completed same-candidate retry ok
n, ctx = rtl.lane_attempt_reserve(root, "lane7", root, cap=5, kind="lane")
rtl.lane_attempt_finish(ctx, "failed", head)
try: rtl.lane_attempt_finish(ctx, "completed", head); print("7a FAIL: failed row overwritten")
except ValueError as e: print("7a ok refused:", e)
n, ctx2 = rtl.lane_attempt_reserve(root, "lane7b", root, cap=5, kind="lane")
rtl.lane_attempt_finish(ctx2, "completed", head)
rtl.lane_attempt_finish(ctx2, "completed", head); print("7b ok same-candidate completed retry accepted")
try: rtl.lane_attempt_finish(ctx2, "completed", "b"*40); print("7c FAIL")
except ValueError as e: print("7c ok different candidate refused:", e)

# --- #8: approval update retry after archive move
n, ctx3 = rtl.lane_attempt_reserve(root, "lane8", root, cap=5, kind="lane")
live = ctx3["record"]
rec = {"schema": relay_attest.SCHEMA, "task":"lane8-tok", "target_repo": root, "reviewed_head": head}
apath = relay_attest.path_for("lane8-tok", root)
ctx3 = dict(ctx3, attestation=apath)
rec["attempt_context"] = ctx3
relay_attest.write(rec)
rtl.lane_attempt_finish(ctx3, "active", head, attestation=apath)
os.environ[rtl.ATTEMPT_CONTEXT_ENV] = json.dumps(ctx3)
before = open(live,"rb").read()
orig_write = relay_attest.write
def boom(r): raise OSError("simulated write failure")
relay_attest.write = boom
try: rtl.archive_lane_attempts(live); print("8a FAIL no error")
except OSError as e: print("8a ok first attempt failed after rename:", e, "| live gone:", not os.path.exists(live))
relay_attest.write = orig_write
arch = glob.glob(os.path.dirname(os.path.dirname(live)) + "/attempt-history/lane8-*/attempts")
assert len(arch)==1; archbytes = open(arch[0],"rb").read()
print("8b approval still points at live path:", json.load(open(apath))["attempt_context"]["record"] == live)
# fresh process view: env holds the approval's (live-path) context
os.environ[rtl.ATTEMPT_CONTEXT_ENV] = json.dumps(json.load(open(apath))["attempt_context"])
res = rtl.lane_attempt_reset if False else rtl.archive_lane_attempts(live)
print("8c retry returned archive:", res == arch[0])
print("8d approval now archived:", json.load(open(apath))["attempt_context"]["record"] == arch[0], json.load(open(apath))["attempt_context"]["archived"])
print("8e archive bytes unchanged:", open(arch[0],"rb").read() == archbytes, "| env updated:", json.loads(os.environ[rtl.ATTEMPT_CONTEXT_ENV])["record"] == arch[0])
# pre-rename validation: mismatched approval id refuses with live file intact
n, ctx4 = rtl.lane_attempt_reserve(root, "lane8c", root, cap=5, kind="lane")
bad = dict(rec, attempt_context=dict(ctx4, id="0"*32)); relay_attest.write(bad)
os.environ[rtl.ATTEMPT_CONTEXT_ENV] = json.dumps(dict(ctx4, attestation=apath))
try: rtl.archive_lane_attempts(ctx4["record"]); print("8f FAIL")
except ValueError as e: print("8f ok refused before rename:", e, "| live kept:", os.path.exists(ctx4["record"]))
