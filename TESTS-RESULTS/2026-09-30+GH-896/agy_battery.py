"""Agy adapter probes: mirror pins, safety fixes, A3 red control."""
import json, os, shutil, sqlite3, sys, importlib.util, hashlib

FIX = "/tmp/ts-probes/agy-fixture"
FIX2 = "/tmp/ts-probes/agy-malformed"
import os as _os
_ROOT = _os.path.abspath(_os.path.join(_os.path.dirname(__file__), "..", ".."))
UNIFIED = _os.path.join(_ROOT, "skills", "3-weekly", "task-sync", "scripts")
ORIG = "/Users/noelsaw/Documents/GH Repos/XYZ-forge/utils/skills/agy-task-sync/scripts/agy_task_sync.py"

def build_fixture(root, app_storage_raw=None):
    if os.path.exists(root): shutil.rmtree(root)
    os.makedirs(f"{root}/annotations"); os.makedirs(f"{root}/brain/conv-a/.system_generated/logs")
    conn = sqlite3.connect(f"{root}/conversation_summaries.db")
    conn.execute("CREATE TABLE conversation_summaries (conversation_id TEXT PRIMARY KEY,"
                 " title TEXT, preview TEXT, status TEXT, last_modified_time TEXT)")
    # UTC texts: 2026-09-29 23:19:00 UTC -> local 09-29 16:19 (UTC-7); 09-30 02:00 UTC -> local 09-29 19:00
    conn.executemany("INSERT INTO conversation_summaries VALUES (?,?,?,?,?)", [
        ("conv-a", "09-28 old title a", "old preview a", "active", "2026-09-29 23:19:00.047628+00:00"),
        ("conv-b", "conv b title",      "old preview b", "active", "2026-09-30 02:00:00.931256+00:00"),
    ])
    conn.commit(); conn.close()
    if app_storage_raw is None:
        app_storage_raw = json.dumps({"pinned_conversations_order": json.dumps(["conv-a"])})
    open(f"{root}/app_storage.json", "w").write(app_storage_raw)
    open(f"{root}/annotations/conv-a.pbtxt", "w").write('title:"09-28 old title a" last_user_view_time:"x" pinned:true\n')
    open(f"{root}/annotations/conv-b.pbtxt", "w").write('title:"conv b title" pinned:true\n')
    open(f"{root}/brain/conv-a/.system_generated/logs/transcript.jsonl", "w").write(
        '{"type":"USER_INPUT","content":"run the checks"}\n'
        '{"tool_calls":[{"name":"bash","args":{"toolSummary":"validate.sh run"}}]}\n')

def digest(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()

def load_orig():
    spec = importlib.util.spec_from_file_location("agy_orig", ORIG)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m

checks = []
def check(name, ok):
    checks.append((name, ok))

# -- fixture 1: healthy store ------------------------------------------------
build_fixture(FIX)
sys.path.insert(0, UNIFIED)
import core
from adapters import antigravity

not_running = lambda: False
ad = antigravity.AntigravityAdapter(agy_root=FIX, apply=True, app_running_fn=not_running)
doc = ad.doctor()
check("doctor green on healthy fixture (app closed)", doc["ok"] is True and doc["app_running"] is False)
before_b = open(f"{FIX}/annotations/conv-b.pbtxt","rb").read()
r = ad.sweep()
check("dry... apply sweep: stamp from UTC last_modified -> LOCAL 09-29 (not 09-30, not 09-28)",
      any(x["new"] == "09-29 old title a" for x in r["renamed"]))
check("preview extracted from transcript [Tool] line",
      any(p["conversation_id"]=="conv-a" and p["last_action"]=="[Tool] validate.sh run" for p in r["previews"]))
conn = sqlite3.connect(f"{FIX}/conversation_summaries.db")
t = conn.execute("SELECT title, preview FROM conversation_summaries WHERE conversation_id='conv-a'").fetchone()
conn.close()
check("DB title updated with last-activity stamp", t[0] == "09-29 old title a")
check("DB preview updated", t[1] == "[Tool] validate.sh run")
after_b = open(f"{FIX}/annotations/conv-b.pbtxt","rb").read()
check("mirror: conv-b pin stripped (not in authoritative list)", before_b != after_b and "pinned" not in after_b.decode())
check("mirror: conv-a pin kept", "pinned:true" in open(f"{FIX}/annotations/conv-a.pbtxt").read())

# idempotency
r2 = ad.sweep()
check("second sweep: zero renames (idempotent)", len(r2["renamed"]) == 0)

# set-title + auto-pin
r3 = ad.set_title("conv-b", "Reviewed fixture title", auto_pin=True)
check("set-title stamps from row's own UTC last_modified (09-29)",
      r3["renamed"][0]["new"] == "09-29 Reviewed fixture title")
store = json.load(open(f"{FIX}/app_storage.json"))
pinlist = json.loads(store["pinned_conversations_order"])
check("auto-pin appended conv-b to app_storage (opt-in derived write)", set(pinlist) == {"conv-a", "conv-b"})
check("auto-pin left a .bak backup", any(f.startswith("app_storage.json.bak-") for f in os.listdir(FIX)))
check("auto-pin annotation pinned:true", "pinned:true" in open(f"{FIX}/annotations/conv-b.pbtxt").read())

# -- fixture 2: malformed electron store (A3) --------------------------------
build_fixture(FIX2, app_storage_raw='{"pinned_conversations_order": [broken')
pb_before = {p: digest(f"{FIX2}/annotations/{p}.pbtxt") for p in ("conv-a", "conv-b")}
db_before = digest(f"{FIX2}/conversation_summaries.db")
ad2 = antigravity.AntigravityAdapter(agy_root=FIX2, apply=True, app_running_fn=not_running)
try:
    ad2.sweep()
    check("A3 unified: malformed read -> AdapterError (no silent proceed)", False)
except core.AdapterError as e:
    check("A3 unified: malformed read -> AdapterError (no silent proceed)", "refusing to infer pin state" in str(e))
pb_after = {p: digest(f"{FIX2}/annotations/{p}.pbtxt") for p in ("conv-a", "conv-b")}
check("A3 unified: annotations byte-identical after abort", pb_before == pb_after)
check("A3 unified: DB untouched after abort", db_before == digest(f"{FIX2}/conversation_summaries.db"))

# -- A3 red control: ORIGINAL strips pins on the same fault ------------------
m = load_orig()
import pathlib
m.ELECTRON_STORAGE_PATH = pathlib.Path(f"{FIX2}/app_storage.json")
m.DB_PATH = pathlib.Path(f"{FIX2}/conversation_summaries.db")
m.ANNOTATIONS_DIR = pathlib.Path(f"{FIX2}/annotations")
m.BRAIN_DIR = pathlib.Path(f"{FIX2}/brain")
res = m.sync_conversations(only_pinned=True, apply=True)
pb_after_orig = {p: digest(f"{FIX2}/annotations/{p}.pbtxt") for p in ("conv-a", "conv-b")}
check("A3 RED CONTROL: original strips pins on the same fault (witnessed)",
      pb_after_orig != pb_before)

# -- app-running gate --------------------------------------------------------
ad3 = antigravity.AntigravityAdapter(agy_root=FIX, apply=True, app_running_fn=lambda: True)
try:
    ad3.sweep()
    check("app-running gate: apply refused while app 'running'", False)
except core.AdapterError as e:
    check("app-running gate: apply refused while app 'running'", "writes are gated" in str(e))

# -- doctor faults -----------------------------------------------------------
ad4 = antigravity.AntigravityAdapter(agy_root="/tmp/ts-probes/nonexistent", apply=False, app_running_fn=not_running)
d4 = ad4.doctor()
check("doctor fault: missing root -> red", d4["ok"] is False)
import shutil as _sh
if os.path.exists(f"{FIX}/../agy-nocol"): _sh.rmtree(f"{FIX}/../agy-nocol")
os.makedirs(f"{FIX}/../agy-nocol")
conn = sqlite3.connect(f"{FIX}/../agy-nocol/conversation_summaries.db")
conn.execute("CREATE TABLE conversation_summaries (conversation_id TEXT, title TEXT, preview TEXT, status TEXT)")
conn.commit(); conn.close()
ad5 = antigravity.AntigravityAdapter(agy_root=f"{FIX}/../agy-nocol", apply=False, app_running_fn=not_running)
d5 = ad5.doctor()
check("doctor fault: dropped column -> red with clear message", d5["ok"] is False and "missing expected columns" in d5["reds"][0])

# -- r2 falsifiers (agy round-2) ---------------------------------------------
from datetime import datetime as _dt
import core as _core
_d = _core.utc_text_to_local_dt("2026-06-19 01:31:58.720731+00:00")
check("r2 Blocker falsifier: real-format timestamp parses (not None)", _d is not None)
check("r2 Blocker falsifier: aware UTC input converts to a LOCAL-aware datetime",
      _d is not None and _d.tzinfo is not None and _d.utcoffset() is not None)
_d2 = _core.utc_text_to_local_dt("2026-09-29 23:19:00")
check("plain-format timestamp still parses (fallback chain)", _d2 is not None)
_d3 = _core.utc_text_to_local_dt("garbage")
check("garbage still returns None (skip, not crash)", _d3 is None)

# -- app_storage.json as a JSON ARRAY (r2 Should falsifier) -------------------
build_fixture(f"{FIX}/../agy-array", app_storage_raw='[]')
ad6 = antigravity.AntigravityAdapter(agy_root=f"{FIX}/../agy-array", apply=True, app_running_fn=not_running)
try:
    ad6.sweep()
    check("r2 Should falsifier: JSON-array store -> AdapterError (not AttributeError)", False)
except core.AdapterError as e:
    check("r2 Should falsifier: JSON-array store -> AdapterError (not AttributeError)", "not an object" in str(e))
except AttributeError:
    check("r2 Should falsifier: JSON-array store -> AdapterError (not AttributeError)", False)

fails = sum(0 if ok else 1 for _, ok in checks)
for name, ok in checks: print(("PASS" if ok else "FAIL"), "-", name)
sys.exit(1 if fails else 0)
